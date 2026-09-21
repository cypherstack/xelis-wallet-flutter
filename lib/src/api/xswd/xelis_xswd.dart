import 'dart:async';
import 'dart:collection';

import '../errors/xelis_wallet_exception.dart';

/// Policy retained for one permission of an active XSWD application.
enum XelisXswdPermissionPolicy { ask, accept, reject }

/// Decision returned to an external XSWD application.
enum XelisXswdDecision { accept, reject, alwaysAccept, alwaysReject }

/// Stable kind of request delivered through [XelisXswdCallbacks].
enum XelisXswdRequestKind {
  application,
  permission,
  prefetchPermissions,
  cancel,
  applicationDisconnect,
}

/// Lossless authored value from the effective RPC request delivered by XSWD.
///
/// Values may contain active secrets supplied by the requesting application,
/// including explicit signer private keys. Inspect them only inside the
/// callback that received them, and never log, retain, or display an entire
/// payload. Every [toString] implementation is deliberately redacted.
sealed class XelisXswdValue {
  const XelisXswdValue();
}

/// Resource budget used while projecting one parsed XSWD request to Dart.
///
/// These limits protect the Rust/FRB/Dart boundary. They are not XELIS
/// protocol limits. Custom values may be stricter or more permissive than the
/// defaults but cannot exceed the package-owned technical ceilings.
final class XelisXswdProjectionLimits {
  const XelisXswdProjectionLimits({
    this.maxDepth = defaultMaxDepth,
    this.maxTokens = defaultMaxTokens,
    this.maxContainerMembers = defaultMaxContainerMembers,
    this.maxTextBytes = defaultMaxTextBytes,
    this.maxTotalTextBytes = defaultMaxTotalTextBytes,
  });

  static const defaultMaxDepth = 64;
  static const defaultMaxTokens = 65536;
  static const defaultMaxContainerMembers = 4096;
  static const defaultMaxTextBytes = 4 * 1024 * 1024;
  static const defaultMaxTotalTextBytes = 8 * 1024 * 1024;

  static const technicalMaxDepth = 128;
  static const technicalMaxTokens = 262144;
  static const technicalMaxContainerMembers = 65536;
  static const technicalMaxTextBytes = 8 * 1024 * 1024;
  static const technicalMaxTotalTextBytes = 16 * 1024 * 1024;

  final int maxDepth;
  final int maxTokens;
  final int maxContainerMembers;
  final int maxTextBytes;
  final int maxTotalTextBytes;

  @override
  String toString() =>
      'XelisXswdProjectionLimits(maxDepth=$maxDepth, '
      'maxTokens=$maxTokens, maxContainerMembers=$maxContainerMembers, '
      'maxTextBytes=$maxTextBytes, maxTotalTextBytes=$maxTotalTextBytes)';
}

/// Authored JSON null value.
final class XelisXswdNullValue extends XelisXswdValue {
  const XelisXswdNullValue();

  @override
  String toString() => 'XelisXswdNullValue(redacted)';
}

/// Authored JSON boolean value.
final class XelisXswdBoolValue extends XelisXswdValue {
  const XelisXswdBoolValue(this.value);

  final bool value;

  @override
  String toString() => 'XelisXswdBoolValue(redacted)';
}

/// Authored JSON string value.
final class XelisXswdStringValue extends XelisXswdValue {
  const XelisXswdStringValue(this.value);

  final String value;

  @override
  String toString() => 'XelisXswdStringValue(redacted)';
}

/// Exact authored JSON integer value.
///
/// Native `i64` and `u64` values cross the private bridge as canonical decimal
/// strings and are reconstructed as [BigInt], including on Web.
final class XelisXswdIntegerValue extends XelisXswdValue {
  const XelisXswdIntegerValue(this.value);

  final BigInt value;

  @override
  String toString() => 'XelisXswdIntegerValue(redacted)';
}

/// Authored JSON floating-point value.
///
/// This represents a genuine upstream `f64`, not an integer transport. A
/// consumer expecting an integer authority field must reject this variant.
final class XelisXswdFloatValue extends XelisXswdValue {
  const XelisXswdFloatValue(this.value);

  final double value;

  @override
  String toString() => 'XelisXswdFloatValue(redacted)';
}

/// Deeply immutable authored JSON array.
final class XelisXswdArrayValue extends XelisXswdValue {
  XelisXswdArrayValue(List<XelisXswdValue> values)
    : values = List.unmodifiable(values);

  final List<XelisXswdValue> values;

  @override
  String toString() => 'XelisXswdArrayValue(length=${values.length})';
}

/// Deeply immutable authored JSON object.
final class XelisXswdObjectValue extends XelisXswdValue {
  XelisXswdObjectValue(Map<String, XelisXswdValue> fields)
    : fields = UnmodifiableMapView(Map.of(fields));

  final Map<String, XelisXswdValue> fields;

  @override
  String toString() => 'XelisXswdObjectValue(fieldCount=${fields.length})';
}

/// Authored projection of one application connected through XSWD.
///
/// [sessionReference] is an opaque, wallet-owned capability. Only application
/// projections returned by a live wallet state read or callback can authorize
/// permission updates and session closure. Constructed applications and
/// detached references are descriptive values only.
final class XelisXswdApplication {
  XelisXswdApplication({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required Map<String, XelisXswdPermissionPolicy> permissions,
    required this.isRelayer,
  }) : sessionReference = XelisXswdSessionReference.detached(),
       permissions = UnmodifiableMapView(Map.of(permissions));

  XelisXswdApplication._live({
    required this.sessionReference,
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required Map<String, XelisXswdPermissionPolicy> permissions,
    required this.isRelayer,
  }) : permissions = UnmodifiableMapView(Map.of(permissions));

  final XelisXswdSessionReference sessionReference;
  final String id;
  final String name;
  final String description;
  final String? url;

  /// Wallet RPC policies keyed by unprefixed method identifiers.
  ///
  /// For example, the balance method is represented as `get_balance`.
  final Map<String, XelisXswdPermissionPolicy> permissions;
  final bool isRelayer;

  @override
  String toString() =>
      'XelisXswdApplication(permissionCount=${permissions.length}, '
      'isRelayer=$isRelayer)';
}

/// Opaque identity of one live XSWD application session.
///
/// The value deliberately exposes neither its native token nor application
/// metadata. A detached reference is suitable for non-restorable routing
/// placeholders, but never authorizes a native operation.
final class XelisXswdSessionReference {
  XelisXswdSessionReference._(this._identity);

  factory XelisXswdSessionReference.detached() =>
      XelisXswdSessionReference._(Object());

  final Object _identity;

  @override
  bool operator ==(Object other) =>
      other is XelisXswdSessionReference &&
      identical(_identity, other._identity);

  @override
  int get hashCode => identityHashCode(_identity);

  @override
  String toString() => 'XelisXswdSessionReference(<opaque>)';
}

/// Package-internal live projection constructor.
///
/// Hidden from the package root export: consumers cannot manufacture the
/// identity object used by the native wallet adapter.
XelisXswdApplication xelisXswdApplicationWithSessionIdentity({
  required Object sessionIdentity,
  required String id,
  required String name,
  required String description,
  required String? url,
  required Map<String, XelisXswdPermissionPolicy> permissions,
  required bool isRelayer,
}) => XelisXswdApplication._live(
  sessionReference: XelisXswdSessionReference._(sessionIdentity),
  id: id,
  name: name,
  description: description,
  url: url,
  permissions: permissions,
  isRelayer: isRelayer,
);

/// Snapshot of the process state owned by one wallet's XSWD integration.
final class XelisXswdState {
  XelisXswdState({
    required this.isRunning,
    required List<XelisXswdApplication> applications,
  }) : applications = List.unmodifiable(applications);

  final bool isRunning;
  final List<XelisXswdApplication> applications;

  @override
  String toString() =>
      'XelisXswdState(isRunning=$isRunning, '
      'applicationCount=${applications.length})';
}

/// Result of a bounded native-state observation started after an XSWD
/// decision that may change admission or retained permissions.
///
/// The observation is informational: the decision callback has already
/// returned to the native wallet before XWF starts reading state. Consumers
/// must not interpret it as an atomic protocol acknowledgement.
sealed class XelisXswdApplicationStateObservation {
  const XelisXswdApplicationStateObservation(this.application, this.sequence);

  /// Application projection associated with the observation.
  ///
  /// Only [XelisXswdApplicationStateObserved.application] is guaranteed to be
  /// a fresh native-state projection. Other outcomes retain the source
  /// projection for correlation and may no longer authorize operations.
  final XelisXswdApplication application;

  /// Wallet-local ordering value for this observation.
  ///
  /// Consumers may discard an outcome whose sequence is older than the latest
  /// one handled for the same opaque session reference. This number carries no
  /// native authority and is not stable across wallet handles or restarts.
  final int sequence;
}

/// The expected application admission or permission policies were observed.
final class XelisXswdApplicationStateObserved
    extends XelisXswdApplicationStateObservation {
  const XelisXswdApplicationStateObserved(super.application, super.sequence);

  @override
  String toString() => 'XelisXswdApplicationStateObserved()';
}

/// The observation was replaced or its exact session stopped being current.
final class XelisXswdApplicationStateStale
    extends XelisXswdApplicationStateObservation {
  const XelisXswdApplicationStateStale(super.application, super.sequence);

  @override
  String toString() => 'XelisXswdApplicationStateStale()';
}

/// Native state did not reflect the expected result within the bounded wait.
final class XelisXswdApplicationStateTimedOut
    extends XelisXswdApplicationStateObservation {
  const XelisXswdApplicationStateTimedOut(super.application, super.sequence);

  @override
  String toString() => 'XelisXswdApplicationStateTimedOut()';
}

/// Reading the native application state failed.
final class XelisXswdApplicationStateFailed
    extends XelisXswdApplicationStateObservation {
  const XelisXswdApplicationStateFailed(
    super.application,
    super.sequence,
    this.error,
  );

  /// Structured authored failure from the state-read boundary.
  final XelisWalletException error;

  @override
  String toString() => 'XelisXswdApplicationStateFailed()';
}

/// Authored XSWD request delivered to a consumer callback.
///
/// [payload] is an object for permission and prefetch-permission requests and
/// is absent for lifecycle notifications. It may contain sensitive request
/// data and must not enter logs, support references, analytics, or toasts.
/// A deliberate permission-review UI may inspect and render the fields needed
/// for informed consent. Redacted [toString] output is only a safe implicit
/// representation: accessing [XelisXswdObjectValue.fields], collection values,
/// or scalar values transfers responsibility to the consumer.
final class XelisXswdRequest {
  const XelisXswdRequest({
    required this.kind,
    required this.application,
    this.payload,
  });

  final XelisXswdRequestKind kind;
  final XelisXswdApplication application;
  final XelisXswdValue? payload;

  /// Typed view of a permission request, bound to this exact [XelisXswdRequest].
  ///
  /// The JSON-RPC method is preserved exactly. [XelisXswdPermissionRequest.parameters]
  /// remains an authored XSWD value tree: XWF validates the envelope shape but
  /// leaves method-specific interpretation to the consumer.
  XelisXswdPermissionRequest? get permissionRequest =>
      _permissionRequestFor(this);

  /// Typed view of a prefetch request, bound to this exact [XelisXswdRequest].
  ///
  /// Permission names are preserved exactly and are not normalized or filtered
  /// by XWF.
  XelisXswdPrefetchPermissionsRequest? get prefetchPermissionsRequest =>
      _prefetchPermissionsRequestFor(this);

  bool get isApplicationRequest => kind == XelisXswdRequestKind.application;
  bool get isPermissionRequest => kind == XelisXswdRequestKind.permission;
  bool get isPrefetchPermissionsRequest =>
      kind == XelisXswdRequestKind.prefetchPermissions;
  bool get isCancelRequest => kind == XelisXswdRequestKind.cancel;
  bool get isApplicationDisconnect =>
      kind == XelisXswdRequestKind.applicationDisconnect;

  @override
  String toString() =>
      'XelisXswdRequest(kind=$kind, hasPayload=${payload != null})';
}

/// Typed XSWD JSON-RPC permission request.
///
/// Instances can only be obtained from [XelisXswdRequest.permissionRequest].
/// [source] lets consumers prove that a validated projection belongs to the
/// request currently being decided.
final class XelisXswdPermissionRequest {
  XelisXswdPermissionRequest._({
    required this.source,
    required this.method,
    required this.parameters,
  });

  final XelisXswdRequest source;
  final String method;

  /// Named or positional JSON-RPC parameters. An omitted or explicit JSON null
  /// is represented as `null`.
  final XelisXswdValue? parameters;

  @override
  String toString() =>
      'XelisXswdPermissionRequest(hasParameters=${parameters != null})';
}

/// Typed XSWD request for a batch of wallet permissions.
///
/// Instances can only be obtained from
/// [XelisXswdRequest.prefetchPermissionsRequest]. Permission identifiers and
/// [reason] may be controlled by an external application and are omitted from
/// [toString].
final class XelisXswdPrefetchPermissionsRequest {
  XelisXswdPrefetchPermissionsRequest._({
    required this.source,
    required this.reason,
    required List<String> permissions,
  }) : permissions = List.unmodifiable(permissions);

  final XelisXswdRequest source;
  final String? reason;
  final List<String> permissions;

  @override
  String toString() =>
      'XelisXswdPrefetchPermissionsRequest('
      'permissionCount=${permissions.length}, hasReason=${reason != null})';
}

final Expando<XelisXswdPermissionRequest> _permissionRequests =
    Expando<XelisXswdPermissionRequest>('xelis-xswd-permission-request');
final Expando<XelisXswdPrefetchPermissionsRequest> _prefetchRequests =
    Expando<XelisXswdPrefetchPermissionsRequest>(
      'xelis-xswd-prefetch-permissions-request',
    );

XelisXswdPermissionRequest? _permissionRequestFor(XelisXswdRequest source) {
  if (!source.isPermissionRequest) return null;
  final cached = _permissionRequests[source];
  if (cached != null) return cached;
  final payload = _requireXswdObjectPayload(source);
  final version = payload.fields['jsonrpc'];
  final method = payload.fields['method'];
  final rawParameters = payload.fields['params'];
  if (version is! XelisXswdStringValue ||
      version.value != '2.0' ||
      method is! XelisXswdStringValue ||
      method.value.isEmpty) {
    throw const FormatException('Invalid XSWD permission request envelope.');
  }
  final request = XelisXswdPermissionRequest._(
    source: source,
    method: method.value,
    parameters: rawParameters is XelisXswdNullValue ? null : rawParameters,
  );
  _permissionRequests[source] = request;
  return request;
}

XelisXswdPrefetchPermissionsRequest? _prefetchPermissionsRequestFor(
  XelisXswdRequest source,
) {
  if (!source.isPrefetchPermissionsRequest) return null;
  final cached = _prefetchRequests[source];
  if (cached != null) return cached;
  final payload = _requireXswdObjectPayload(source);
  final rawReason = payload.fields['reason'];
  final rawPermissions = payload.fields['permissions'];
  if ((rawReason != null &&
          rawReason is! XelisXswdStringValue &&
          rawReason is! XelisXswdNullValue) ||
      rawPermissions is! XelisXswdArrayValue) {
    throw const FormatException('Invalid XSWD prefetch request envelope.');
  }
  final permissions = <String>[];
  for (final value in rawPermissions.values) {
    if (value is! XelisXswdStringValue) {
      throw const FormatException('Invalid XSWD prefetch permission name.');
    }
    permissions.add(value.value);
  }
  final request = XelisXswdPrefetchPermissionsRequest._(
    source: source,
    reason: rawReason is XelisXswdStringValue ? rawReason.value : null,
    permissions: permissions,
  );
  _prefetchRequests[source] = request;
  return request;
}

XelisXswdObjectValue _requireXswdObjectPayload(XelisXswdRequest source) {
  final payload = source.payload;
  if (payload is! XelisXswdObjectValue) {
    throw const FormatException('Missing XSWD request payload.');
  }
  return payload;
}

/// Supported encryption algorithms for one relayed XSWD session.
enum XelisXswdEncryptionAlgorithm { aes, chacha20Poly1305 }

/// Encryption configuration for one relayed XSWD session.
///
/// The key is copied into an immutable list and deliberately omitted from
/// [toString]. Native validation still requires exactly 32 bytes.
final class XelisXswdEncryption {
  XelisXswdEncryption({required this.algorithm, required List<int> key})
    : key = List.unmodifiable(key);

  final XelisXswdEncryptionAlgorithm algorithm;
  final List<int> key;

  @override
  String toString() => 'XelisXswdEncryption(algorithm=$algorithm, redacted)';
}

/// Authored input used to add one relayed XSWD application.
///
/// This value may originate from a QR code, paste, or deep link. Consumers
/// must parse it as untrusted input and never log the complete source payload.
final class XelisXswdRelayer {
  XelisXswdRelayer({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required List<String> permissions,
    required this.relayer,
    this.encryption,
  }) : permissions = List.unmodifiable(permissions);

  final String id;
  final String name;
  final String description;
  final String? url;

  /// Requested wallet RPC methods in their unprefixed form.
  ///
  /// A prefixed identifier such as `wallet.get_balance` is invalid.
  final List<String> permissions;
  final String relayer;
  final XelisXswdEncryption? encryption;

  @override
  String toString() =>
      'XelisXswdRelayer(permissionCount=${permissions.length}, '
      'encrypted=${encryption != null})';
}

typedef XelisXswdNotificationCallback = FutureOr<void> Function(
  XelisXswdRequest request,
);

/// Optional notification for bounded post-decision native-state observation.
typedef XelisXswdApplicationStateObservationCallback = FutureOr<void> Function(
  XelisXswdApplicationStateObservation observation,
);
typedef XelisXswdDecisionCallback = FutureOr<XelisXswdDecision> Function(
  XelisXswdRequest request,
);
typedef XelisXswdPrefetchDecisionCallback =
    FutureOr<XelisXswdPrefetchDecision> Function(
      XelisXswdPrefetchPermissionsRequest request,
    );

/// Decision for one XSWD prefetch request.
///
/// A prefetch decision updates only explicitly granted methods. XWF validates
/// the selected names as an exact subset of the originating request before the
/// native wallet observes any change.
sealed class XelisXswdPrefetchDecision {
  const XelisXswdPrefetchDecision._();

  const factory XelisXswdPrefetchDecision.noChange() =
      XelisXswdPrefetchNoChange;

  factory XelisXswdPrefetchDecision.grant(Iterable<String> permissions) =
      XelisXswdPrefetchGrant;
}

/// Leaves every retained permission policy unchanged.
final class XelisXswdPrefetchNoChange extends XelisXswdPrefetchDecision {
  const XelisXswdPrefetchNoChange() : super._();

  @override
  String toString() => 'XelisXswdPrefetchDecision.noChange()';
}

/// Grants exactly [permissions] from the current prefetch request.
final class XelisXswdPrefetchGrant extends XelisXswdPrefetchDecision {
  XelisXswdPrefetchGrant(Iterable<String> permissions)
    : permissions = List.unmodifiable(permissions),
      super._();

  final List<String> permissions;

  @override
  String toString() =>
      'XelisXswdPrefetchDecision.grant(permissionCount=${permissions.length})';
}

/// Consumer callbacks used by the local XSWD server and relayer handler.
///
/// Generated bridge callback types remain private behind the package adapter.
/// Callback exceptions and timeouts never cross into Rust as arbitrary Dart
/// errors. They become static technical XSWD failures. Only an explicit
/// [XelisXswdDecision.reject] is represented as a user rejection.
///
/// XWF runs one decision callback at a time. Cancellation or disconnection of
/// the exact upstream application-state instance preempts its active decision;
/// a later result from that decision is not returned to the wallet.
final class XelisXswdCallbacks {
  const XelisXswdCallbacks({
    required this.onCancelRequest,
    required this.onApplicationRequest,
    required this.onPermissionRequest,
    required this.onPrefetchPermissionsRequest,
    required this.onApplicationDisconnect,
    this.onPrefetchPermissionsReview,
    this.onApplicationStateObservation,
    this.timeout = const Duration(minutes: 1),
    this.projectionLimits = const XelisXswdProjectionLimits(),
  });

  final XelisXswdNotificationCallback onCancelRequest;
  final XelisXswdDecisionCallback onApplicationRequest;
  final XelisXswdDecisionCallback onPermissionRequest;
  final XelisXswdDecisionCallback onPrefetchPermissionsRequest;

  /// Optional selective prefetch callback.
  ///
  /// When present, this callback replaces [onPrefetchPermissionsRequest] for
  /// prefetch events. The legacy callback remains required so existing
  /// consumers retain source compatibility and unchanged behavior.
  final XelisXswdPrefetchDecisionCallback? onPrefetchPermissionsReview;
  final XelisXswdNotificationCallback onApplicationDisconnect;

  /// Optional result notification for bounded native-state reconciliation.
  ///
  /// XWF performs no observation work when this callback is absent. Callback
  /// completion is never awaited by the original XSWD decision.
  final XelisXswdApplicationStateObservationCallback?
  onApplicationStateObservation;

  /// Maximum time an individual XSWD callback future may remain pending.
  final Duration timeout;

  /// Resource budget fixed when these callbacks create the native handler.
  final XelisXswdProjectionLimits projectionLimits;
}
