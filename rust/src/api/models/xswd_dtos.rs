use std::{collections::HashMap, error::Error, fmt};

use flutter_rust_bridge::frb;
use serde::Serialize;
use serde_json::Value;

pub(crate) const DEFAULT_XSWD_PAYLOAD_DEPTH: u32 = 64;
pub(crate) const DEFAULT_XSWD_PAYLOAD_TOKENS: u32 = 65_536;
pub(crate) const DEFAULT_XSWD_CONTAINER_MEMBERS: u32 = 4_096;
pub(crate) const DEFAULT_XSWD_TEXT_BYTES: u32 = 4 * 1024 * 1024;
pub(crate) const DEFAULT_XSWD_TOTAL_TEXT_BYTES: u32 = 8 * 1024 * 1024;

const TECHNICAL_MAX_XSWD_PAYLOAD_DEPTH: u32 = 128;
const TECHNICAL_MAX_XSWD_PAYLOAD_TOKENS: u32 = 262_144;
const TECHNICAL_MAX_XSWD_CONTAINER_MEMBERS: u32 = 65_536;
const TECHNICAL_MAX_XSWD_TEXT_BYTES: u32 = 8 * 1024 * 1024;
const TECHNICAL_MAX_XSWD_TOTAL_TEXT_BYTES: u32 = 16 * 1024 * 1024;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct NativeXswdProjectionLimits {
    pub max_depth: u32,
    pub max_tokens: u32,
    pub max_container_members: u32,
    pub max_text_bytes: u32,
    pub max_total_text_bytes: u32,
}

impl Default for NativeXswdProjectionLimits {
    fn default() -> Self {
        Self {
            max_depth: DEFAULT_XSWD_PAYLOAD_DEPTH,
            max_tokens: DEFAULT_XSWD_PAYLOAD_TOKENS,
            max_container_members: DEFAULT_XSWD_CONTAINER_MEMBERS,
            max_text_bytes: DEFAULT_XSWD_TEXT_BYTES,
            max_total_text_bytes: DEFAULT_XSWD_TOTAL_TEXT_BYTES,
        }
    }
}

impl NativeXswdProjectionLimits {
    pub(crate) fn validate(self) -> Result<Self, XswdProjectionLimitsError> {
        if self.max_depth == 0 || self.max_depth > TECHNICAL_MAX_XSWD_PAYLOAD_DEPTH {
            return Err(XswdProjectionLimitsError::Depth);
        }
        if self.max_tokens == 0 || self.max_tokens > TECHNICAL_MAX_XSWD_PAYLOAD_TOKENS {
            return Err(XswdProjectionLimitsError::Tokens);
        }
        if self.max_container_members == 0
            || self.max_container_members > TECHNICAL_MAX_XSWD_CONTAINER_MEMBERS
        {
            return Err(XswdProjectionLimitsError::ContainerMembers);
        }
        if self.max_text_bytes == 0 || self.max_text_bytes > TECHNICAL_MAX_XSWD_TEXT_BYTES {
            return Err(XswdProjectionLimitsError::TextBytes);
        }
        if self.max_total_text_bytes == 0
            || self.max_total_text_bytes > TECHNICAL_MAX_XSWD_TOTAL_TEXT_BYTES
            || self.max_total_text_bytes < self.max_text_bytes
        {
            return Err(XswdProjectionLimitsError::TotalTextBytes);
        }
        Ok(self)
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum XswdProjectionLimitsError {
    Depth,
    Tokens,
    ContainerMembers,
    TextBytes,
    TotalTextBytes,
}

impl XswdProjectionLimitsError {
    pub(crate) fn code(self) -> &'static str {
        match self {
            Self::Depth => "XSWD_LIMIT_MAX_DEPTH_INVALID",
            Self::Tokens => "XSWD_LIMIT_MAX_TOKENS_INVALID",
            Self::ContainerMembers => "XSWD_LIMIT_MAX_CONTAINER_MEMBERS_INVALID",
            Self::TextBytes => "XSWD_LIMIT_MAX_TEXT_BYTES_INVALID",
            Self::TotalTextBytes => "XSWD_LIMIT_MAX_TOTAL_TEXT_BYTES_INVALID",
        }
    }
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct XswdRequestSummary {
    pub event_type: XswdRequestType,
    pub application_info: AppInfo,
}

impl XswdRequestSummary {
    #[frb(ignore)]
    pub fn new(event_type: XswdRequestType, application_info: AppInfo) -> Self {
        Self {
            event_type,
            application_info,
        }
    }

    #[frb(sync)]
    pub fn is_cancel_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::CancelRequest)
    }

    #[frb(sync)]
    pub fn is_application_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::Application)
    }

    #[frb(sync)]
    pub fn is_permission_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::Permission(_))
    }

    #[frb(sync)]
    pub fn is_prefetch_permissions_request(&self) -> bool {
        matches!(self.event_type, XswdRequestType::PrefetchPermissions(_))
    }

    #[frb(sync)]
    pub fn is_app_disconnect(&self) -> bool {
        matches!(self.event_type, XswdRequestType::AppDisconnect)
    }
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct AppInfo {
    /// Private bridge reference to this exact live XSWD session.
    pub session_ref: u64,
    pub id: String,
    pub name: String,
    pub description: String,
    pub url: Option<String>,
    pub permissions: HashMap<String, PermissionPolicy>,
    pub is_relayer: bool,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum XswdRequestType {
    Application,
    Permission(NativeXswdPayload),
    PrefetchPermissions(NativeXswdPayload),
    CancelRequest,
    AppDisconnect,
}

/// Private, lossless token stream used only by the generated bridge adapter.
///
/// A flat stream avoids recursive generated types and lets native code enforce
/// all resource limits before any payload data crosses FRB.
#[derive(Clone)]
pub struct NativeXswdPayload {
    pub tokens: Vec<NativeXswdPayloadToken>,
}

impl fmt::Debug for NativeXswdPayload {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeXswdPayload")
            .field("token_count", &self.tokens.len())
            .finish()
    }
}

impl NativeXswdPayload {
    #[frb(ignore)]
    pub(crate) fn project<T: Serialize>(
        value: &T,
        limits: NativeXswdProjectionLimits,
    ) -> Result<Self, XswdPayloadProjectionError> {
        let value =
            serde_json::to_value(value).map_err(|_| XswdPayloadProjectionError::Serialization)?;
        if !value.is_object() {
            return Err(XswdPayloadProjectionError::RootNotObject);
        }

        let mut projection = PayloadProjection::new(limits);
        projection.project_value(&value, 1)?;
        Ok(Self {
            tokens: projection.tokens,
        })
    }
}

#[derive(Clone, Copy, Debug)]
pub enum NativeXswdPayloadTokenKind {
    Null,
    Bool,
    StringValue,
    Integer,
    Float,
    ArrayStart,
    ObjectStart,
    ObjectKey,
}

/// Private token whose generated Dart `toString` cannot expose scalar data.
#[derive(Clone)]
pub struct NativeXswdPayloadToken {
    pub kind: NativeXswdPayloadTokenKind,
    pub bool_value: Option<bool>,
    pub text_value: Option<String>,
    pub float_value: Option<f64>,
    pub length: Option<u32>,
}

impl fmt::Debug for NativeXswdPayloadToken {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("NativeXswdPayloadToken")
            .field("kind", &self.kind)
            .finish()
    }
}

impl NativeXswdPayloadToken {
    fn null() -> Self {
        Self::with_kind(NativeXswdPayloadTokenKind::Null)
    }

    fn bool(value: bool) -> Self {
        Self {
            bool_value: Some(value),
            ..Self::with_kind(NativeXswdPayloadTokenKind::Bool)
        }
    }

    fn string(value: String) -> Self {
        Self {
            text_value: Some(value),
            ..Self::with_kind(NativeXswdPayloadTokenKind::StringValue)
        }
    }

    fn integer(decimal_value: String) -> Self {
        Self {
            text_value: Some(decimal_value),
            ..Self::with_kind(NativeXswdPayloadTokenKind::Integer)
        }
    }

    fn float(value: f64) -> Self {
        Self {
            float_value: Some(value),
            ..Self::with_kind(NativeXswdPayloadTokenKind::Float)
        }
    }

    fn array_start(length: u32) -> Self {
        Self {
            length: Some(length),
            ..Self::with_kind(NativeXswdPayloadTokenKind::ArrayStart)
        }
    }

    fn object_start(length: u32) -> Self {
        Self {
            length: Some(length),
            ..Self::with_kind(NativeXswdPayloadTokenKind::ObjectStart)
        }
    }

    fn object_key(value: String) -> Self {
        Self {
            text_value: Some(value),
            ..Self::with_kind(NativeXswdPayloadTokenKind::ObjectKey)
        }
    }

    fn with_kind(kind: NativeXswdPayloadTokenKind) -> Self {
        Self {
            kind,
            bool_value: None,
            text_value: None,
            float_value: None,
            length: None,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum XswdPayloadProjectionError {
    Serialization,
    RootNotObject,
    DepthLimit,
    TokenLimit,
    ContainerLimit,
    TextLimit,
    TotalTextLimit,
    UnsupportedNumber,
}

impl XswdPayloadProjectionError {
    pub(crate) fn code(self) -> &'static str {
        match self {
            Self::Serialization => "serialization",
            Self::RootNotObject => "root_not_object",
            Self::DepthLimit => "depth_limit",
            Self::TokenLimit => "token_limit",
            Self::ContainerLimit => "container_limit",
            Self::TextLimit => "text_limit",
            Self::TotalTextLimit => "total_text_limit",
            Self::UnsupportedNumber => "unsupported_number",
        }
    }
}

impl fmt::Display for XswdPayloadProjectionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.code())
    }
}

impl Error for XswdPayloadProjectionError {}

#[frb(ignore)]
struct PayloadProjection {
    limits: NativeXswdProjectionLimits,
    tokens: Vec<NativeXswdPayloadToken>,
    total_text_bytes: usize,
}

impl PayloadProjection {
    fn new(limits: NativeXswdProjectionLimits) -> Self {
        Self {
            limits,
            tokens: Vec::new(),
            total_text_bytes: 0,
        }
    }

    fn project_value(
        &mut self,
        value: &Value,
        depth: usize,
    ) -> Result<(), XswdPayloadProjectionError> {
        if depth > self.limits.max_depth as usize {
            return Err(XswdPayloadProjectionError::DepthLimit);
        }

        match value {
            Value::Null => self.push(NativeXswdPayloadToken::null()),
            Value::Bool(value) => self.push(NativeXswdPayloadToken::bool(*value)),
            Value::String(value) => {
                self.add_text(value)?;
                self.push(NativeXswdPayloadToken::string(value.clone()))
            }
            Value::Number(value) => {
                let decimal_value = if let Some(value) = value.as_i64() {
                    value.to_string()
                } else if let Some(value) = value.as_u64() {
                    value.to_string()
                } else if let Some(value) = value.as_f64() {
                    return self.push(NativeXswdPayloadToken::float(value));
                } else {
                    return Err(XswdPayloadProjectionError::UnsupportedNumber);
                };

                self.push(NativeXswdPayloadToken::integer(decimal_value))
            }
            Value::Array(values) => {
                self.validate_container_length(values.len())?;
                self.push(NativeXswdPayloadToken::array_start(values.len() as u32))?;
                for value in values {
                    self.project_value(value, depth + 1)?;
                }
                Ok(())
            }
            Value::Object(fields) => {
                self.validate_container_length(fields.len())?;
                self.push(NativeXswdPayloadToken::object_start(fields.len() as u32))?;
                for (key, value) in fields {
                    self.add_text(key)?;
                    self.push(NativeXswdPayloadToken::object_key(key.clone()))?;
                    self.project_value(value, depth + 1)?;
                }
                Ok(())
            }
        }
    }

    fn push(&mut self, token: NativeXswdPayloadToken) -> Result<(), XswdPayloadProjectionError> {
        if self.tokens.len() >= self.limits.max_tokens as usize {
            return Err(XswdPayloadProjectionError::TokenLimit);
        }
        self.tokens.push(token);
        Ok(())
    }

    fn validate_container_length(&self, length: usize) -> Result<(), XswdPayloadProjectionError> {
        if length > self.limits.max_container_members as usize {
            return Err(XswdPayloadProjectionError::ContainerLimit);
        }
        Ok(())
    }

    fn add_text(&mut self, value: &str) -> Result<(), XswdPayloadProjectionError> {
        let length = value.len();
        if length > self.limits.max_text_bytes as usize {
            return Err(XswdPayloadProjectionError::TextLimit);
        }
        self.total_text_bytes = self
            .total_text_bytes
            .checked_add(length)
            .ok_or(XswdPayloadProjectionError::TotalTextLimit)?;
        if self.total_text_bytes > self.limits.max_total_text_bytes as usize {
            return Err(XswdPayloadProjectionError::TotalTextLimit);
        }
        Ok(())
    }
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum PermissionPolicy {
    Ask,
    Accept,
    Reject,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[frb(dart_metadata=("freezed"))]
pub enum UserPermissionDecision {
    Accept,
    Reject,
    AlwaysAccept,
    AlwaysReject,
}

#[derive(Clone, Debug)]
pub enum XswdDecisionCallbackOutcome {
    Accept,
    Reject,
    AlwaysAccept,
    AlwaysReject,
    PrefetchNoChange,
    PrefetchGrant { permissions: Vec<String> },
    InvalidPayload,
    Timeout,
    Exception,
}

#[derive(Clone, Copy, Debug)]
pub enum XswdNotificationCallbackOutcome {
    Completed,
    InvalidPayload,
    Timeout,
    Exception,
}

// Relay-specific types for XSWD client mode
#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub struct ApplicationDataRelayer {
    pub id: String,
    pub name: String,
    pub description: String,
    pub url: Option<String>,
    pub permissions: Vec<String>,
    pub relayer: String,
    pub encryption_mode: Option<EncryptionMode>,
}

#[derive(Clone, Debug)]
#[frb(dart_metadata=("freezed"))]
pub enum EncryptionMode {
    Aes { key: Vec<u8> },
    Chacha20Poly1305 { key: Vec<u8> },
}

#[cfg(test)]
mod tests;
