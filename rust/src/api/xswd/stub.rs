use std::collections::HashMap;

use anyhow::{anyhow, Error, Result};
pub use flutter_rust_bridge::DartFnFuture;
pub use xelis_common::tokio::sync::mpsc::UnboundedReceiver;
pub use xelis_common::tokio::sync::oneshot::Sender;

#[derive(Default, Debug, Clone)]
pub struct AppState;

#[derive(Debug, Clone)]
pub enum PermissionResult {
    Accept,
    Reject,
    AlwaysAccept,
    AlwaysReject,
}

#[derive(Debug, Clone)]
pub enum XSWDEvent {
    CancelRequest,
    RequestApplication,
    RequestPermission,
    PrefetchPermissions,
    AppDisconnect,
}

use crate::api::{
    error::NativeXelisError,
    models::xswd_dtos::{
        AppInfo, ApplicationDataRelayer, NativeXswdProjectionLimits, PermissionPolicy,
        UserPermissionDecision, XswdDecisionCallbackOutcome, XswdNotificationCallbackOutcome,
        XswdRequestSummary, XswdRequestType,
    },
    wallet::XelisWallet,
};

#[derive(Default)]
#[flutter_rust_bridge::frb(ignore)]
pub(crate) struct XswdSessionRegistry;

#[allow(async_fn_in_trait)]
pub trait XSWD {
    async fn start_xswd(
        &self,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()>;

    async fn stop_xswd(&self) -> Result<()>;

    async fn is_xswd_running(&self) -> bool;

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>>;

    async fn modify_application_permissions(
        &self,
        session_ref: u64,
        permissions: HashMap<String, PermissionPolicy>,
    ) -> std::result::Result<(), NativeXelisError>;

    async fn modify_application_permission(
        &self,
        session_ref: u64,
        permission: String,
        policy: PermissionPolicy,
    ) -> std::result::Result<AppInfo, NativeXelisError>;

    async fn close_application_session(
        &self,
        session_ref: u64,
    ) -> std::result::Result<(), NativeXelisError>;

    async fn add_xswd_relayer(
        &self,
        app_data: ApplicationDataRelayer,
        projection_limits: NativeXswdProjectionLimits,
        cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()>;
}

impl XSWD for XelisWallet {
    async fn start_xswd(
        &self,
        _projection_limits: NativeXswdProjectionLimits,
        _cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        xswd_unavailable()
    }

    async fn stop_xswd(&self) -> Result<()> {
        Ok(())
    }

    async fn is_xswd_running(&self) -> bool {
        false
    }

    async fn get_application_permissions(&self) -> Result<Vec<AppInfo>> {
        Ok(Vec::new())
    }

    async fn modify_application_permissions(
        &self,
        _session_ref: u64,
        _permissions: HashMap<String, PermissionPolicy>,
    ) -> std::result::Result<(), NativeXelisError> {
        Err(xswd_native_unavailable())
    }

    async fn modify_application_permission(
        &self,
        _session_ref: u64,
        _permission: String,
        _policy: PermissionPolicy,
    ) -> std::result::Result<AppInfo, NativeXelisError> {
        Err(xswd_native_unavailable())
    }

    async fn close_application_session(
        &self,
        _session_ref: u64,
    ) -> std::result::Result<(), NativeXelisError> {
        Err(xswd_native_unavailable())
    }

    async fn add_xswd_relayer(
        &self,
        _app_data: ApplicationDataRelayer,
        _projection_limits: NativeXswdProjectionLimits,
        _cancel_request_dart_callback: impl Fn(XswdRequestSummary, bool) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_application_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_permission_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _request_prefetch_permissions_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdDecisionCallbackOutcome>
            + Send
            + Sync
            + 'static,
        _app_disconnect_dart_callback: impl Fn(XswdRequestSummary) -> DartFnFuture<XswdNotificationCallbackOutcome>
            + Send
            + Sync
            + 'static,
    ) -> Result<()> {
        xswd_unavailable()
    }
}

fn xswd_unavailable<T>() -> Result<T> {
    Err(anyhow!("XSWD support is not enabled in this build"))
}

fn xswd_native_unavailable() -> NativeXelisError {
    NativeXelisError::xelis_wallet_flutter(
        crate::api::error::NativeXelisErrorCode::Unsupported,
        "XSWD_SUPPORT_UNAVAILABLE",
        "XSWD support is not enabled in this build",
    )
}

#[flutter_rust_bridge::frb(ignore)]
pub async fn xswd_handler(
    mut _receiver: UnboundedReceiver<XSWDEvent>,
    _projection_limits: NativeXswdProjectionLimits,
    _cancel_request_dart_callback: impl Fn(
        XswdRequestSummary,
        bool,
    ) -> DartFnFuture<XswdNotificationCallbackOutcome>,
    _request_application_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    _request_permission_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdDecisionCallbackOutcome>,
    _request_prefetch_permissions_dart_callback: impl Fn(
        XswdRequestSummary,
    )
        -> DartFnFuture<XswdDecisionCallbackOutcome>,
    _app_disconnect_dart_callback: impl Fn(
        XswdRequestSummary,
    ) -> DartFnFuture<XswdNotificationCallbackOutcome>,
) {
    // no-op w/o network_handler
}

pub async fn create_event_summary(
    state: &AppState,
    event_type: XswdRequestType,
) -> XswdRequestSummary {
    let application_info = create_app_info(state).await;
    XswdRequestSummary::new(event_type, application_info)
}

pub async fn create_app_info(_state: &AppState) -> AppInfo {
    AppInfo {
        session_ref: 0,
        id: String::new(),
        name: String::new(),
        description: String::new(),
        url: None,
        permissions: HashMap::new(),
        is_relayer: false,
    }
}

pub fn handle_permission_decision(
    decision: UserPermissionDecision,
    callback: Sender<Result<PermissionResult, Error>>,
) {
    let result = match decision {
        UserPermissionDecision::Accept => PermissionResult::Accept,
        UserPermissionDecision::Reject => PermissionResult::Reject,
        UserPermissionDecision::AlwaysAccept => PermissionResult::AlwaysAccept,
        UserPermissionDecision::AlwaysReject => PermissionResult::AlwaysReject,
    };

    let _ = callback.send(Ok(result));
}

pub fn xswd_event_name(event: &XSWDEvent) -> &'static str {
    match event {
        XSWDEvent::CancelRequest => "CancelRequest",
        XSWDEvent::RequestApplication => "RequestApplication",
        XSWDEvent::RequestPermission => "RequestPermission",
        XSWDEvent::PrefetchPermissions => "PrefetchPermissions",
        XSWDEvent::AppDisconnect => "AppDisconnect",
    }
}

#[cfg(test)]
#[path = "stub/tests.rs"]
mod tests;
