# XSWD API

This guide is for Flutter applications integrating XSWD through the authored
`XelisXswd*` contract exported by the root library. Generated Flutter Rust
Bridge request, application, permission, decision, and relayer types remain
private implementation details.

## Lifecycle and ownership

One opened `XelisWallet` owns its local XSWD server and relayer sessions.

- `startXswd` starts the local server and is idempotent while it is running.
- `addXswdRelayer` adds a parsed relay session and works independently of local
  server availability.
- `getXswdState` returns the current running flag and connected applications.
- `closeXswdApplicationSession` closes exactly the live session represented by
  the supplied `XelisXswdApplication` projection.
- `updateXswdApplicationPermissions` updates supplied policies for that exact
  live application projection.
- `updateXswdApplicationPermission` updates one policy, preserves every other
  entry, and returns a fresh projection of the same native session.
- `stopXswd` stops both the local server and relay sessions and is idempotent
  while stopped.

Start and stop are mutually exclusive with application admission and close.
A conflicting call fails before FFI with `state.conflict /
XSWD_APPLICATION_OPERATION_IN_PROGRESS`; the consumer must settle or reject
the active admission/close and retry stop. Stop does not implicitly preempt an
in-progress application operation.

Each callback and state-list projection carries an opaque
`XelisXswdSessionReference`. Repeated projections of the same native
application-state instance compare equal, including between callbacks and
state reads. The initial application-request projection is not operational
while admission is still pending: close and permission update fail before FFI
until a fresh native state read confirms that exact instance was admitted.
`getXswdState` performs such a read; an observed-state callback can also return
the resulting fresh projection. That projection retains the same opaque
reference. A different local or relayed
instance remains distinct even when it uses the same application ID.
Reconstructed applications, detached route placeholders, stale sessions, and
projections owned by another wallet handle cannot authorize close or
permission-update operations. The application ID is descriptive and persisted
application metadata, not live session authority. The reference's native token
is never exposed by the authored API or its `toString()` output.

Consumers own orchestration across wallet-session replacement. Stop XSWD and
await completion before closing or disposing the wallet handle.

## Permission identifiers

`XelisXswdApplication.permissions`, permission updates, and relayer permission
lists use unprefixed wallet RPC method names, for example `get_balance`.

A permission name beginning with `wallet.` is invalid and fails before the
native call with `input.invalid / XSWD_PERMISSION_NAME_INVALID`. Permission
names are never ignored or normalized silently.

## Callback boundary

`XelisXswdCallbacks` is an authored callback bundle. The package privately
converts generated requests before invoking it and converts decisions back to
the bridge contract. A decision callback exception or timeout never crosses
into Rust as an arbitrary Dart exception: XWF returns a static technical XSWD
error. `XelisXswdDecision.reject` is reserved for an explicit consumer decision.
Cancellation and disconnect notifications are diagnostic-only: their
exception, timeout, or projection failure never delays or reverses native
cleanup or the upstream cancellation acknowledgement.

Only one native XSWD event handler exists at a time. The call that creates it
fixes callbacks, timeout, and projection limits until `stopXswd()`. Relayers
added later use that same handler configuration.

`onPrefetchPermissionsReview`, when supplied, replaces the legacy prefetch
decision callback. It receives the typed source-bound prefetch projection and
returns either `XelisXswdPrefetchDecision.noChange()` or
`XelisXswdPrefetchDecision.grant(...)`. Rust accepts a grant only when its
bounded list contains no duplicates and is an exact subset of the permission
names in that active request. Validation is atomic: an invalid result changes
no permission, and omitted permissions remain unchanged. Without the optional
callback, the legacy accept/reject behavior is preserved: accept grants every
requested permission and reject changes none. XWF does not decide which wallet
methods an application should allow or preauthorize.

`onApplicationStateObservation` is an optional advisory callback. After an
accepted admission or a decision that can retain permission policies, XWF
returns the decision first, then performs spaced native reads for at most two
seconds. It reports exactly one of `XelisXswdApplicationStateObserved`,
`XelisXswdApplicationStateStale`, `XelisXswdApplicationStateTimedOut`, or
`XelisXswdApplicationStateFailed`. A newer observation for the same exact
session replaces the older one. Stop, disconnect, replacement, and disposal
make pending observations stale. No polling runs when the callback is absent,
and no polling remains after an outcome. The observed result describes state
seen after the decision; it is not an atomic protocol acknowledgement.
Each outcome carries a wallet-local `sequence`; consumers can ignore an older
sequence for the same opaque session reference. It is correlation metadata,
not native authority, and is not stable across handles or restarts.

Only one callback, decision or notification, is tracked as active at a time,
and later callbacks remain ordered behind it. The dispatcher continues to
receive lifecycle events while a notification is slow. A
`CancelRequest` or `AppDisconnect` for that exact upstream application-state
instance preempts the active decision: XWF rejects its upstream response with
the static `XSWD_REQUEST_CANCELLED` technical failure, drops the pending Dart
future, and ignores any later decision from it. Requests already queued for
the same instance are rejected without being presented. A cancellation from a
replaced instance that happens to reuse the same application ID cannot cancel
or clear the current review.

Cancelling an application admission tombstones that exact native session
before acknowledging upstream. The later private notification projection
marks the matching Dart identity non-operable, so neither a late decision nor
a stale state read can reactivate it. Cancelling a permission or prefetch
request on an already admitted session does not revoke the rest of that
session. A disconnect always invalidates native authority before notification
projection; that projection retains the same opaque identity only as
non-operable metadata.

The handler retains at most 64 deferred events in total. Further decisions fail
with the static `XSWD_REQUEST_QUEUE_FULL` technical failure and are never
presented. `CancelRequest` performs internal cancellation and upstream
acknowledgement directly; its consumer notification can wait in the bounded
queue behind an unrelated active callback or be abandoned at capacity.
Repeated deferred disconnects for the same state instance are coalesced. A new
disconnect at capacity displaces and rejects one deferred decision. If the
queue contains only notifications, XWF abandons the active callback with the
static `XSWD_HANDLER_OVERLOADED` diagnostic (or fails its decision response),
advances the oldest queued notification, and keeps the new disconnect within
the bound. An abandoned admission cannot regain native authority.

Dropping the Rust wait cannot stop Dart
code that has already started, so consumers must scope every late side effect
to the exact opaque session identity. The 64-event bound applies only to XWF's
deferred dispatcher queue; upstream channel buffering and parsing before XWF
are outside that guarantee.

Lifecycle reception remains responsive: XWF consumes at most 16 events with
receiver priority before giving a ready callback, decision or notification,
priority. Thus a cancellation observed during that bounded receive burst wins
over a simultaneously ready callback without allowing sustained input to
starve it forever. If the upstream event channel closes, active and queued
decisions fail closed with static `XSWD_HANDLER_CLOSED`; notification waits are
abandoned instead of delaying shutdown until their Dart timeout. Only exact
states observed by that dispatcher are invalidated, preserving independent
sessions owned by another dispatcher.

This preemption begins once upstream emits the lifecycle event. The pinned
upstream relayer currently waits for `on_message` to finish before it reads the
next WebSocket frame, so a peer-only remote socket close may not be observed
until the active callback completes or reaches its configured timeout. An
explicit wallet-side session close does emit the cancellation independently
and is preemptive. Consumers should therefore keep callback timeouts finite;
full remote-close preemption requires an upstream relayer change.

For relayed sessions, wallet-side close drives exact application removal and
client transport shutdown concurrently. This both cancels an active decision
without waiting for its timeout and lets the socket task terminate while an
application-disconnect callback is pending. The wallet-level relayer lock is
not held while callbacks run. Concurrent authored relayer admission and close
calls for the same application ID are rejected until the first operation
settles, preventing a replacement instance from satisfying the pinned upstream
provider's ID-only membership check for the old transport. Frames already
selected by the pinned upstream client at the instant close begins remain
in-flight; in particular upstream `node.*` and `xswd.*` dispatch do not consult
relayer membership. The close
future waits for the client task and for the disconnect event to be enqueued;
the consumer notification may finish asynchronously afterward. A strict
pre-dispatch closing-state gate requires an upstream relayer change. For local
sessions, the WebSocket server owns map removal and its `on_close` path emits
cancellation and disconnect. Native invalidation does not wait for the
consumer's notification to complete.

The initial application-request callback cannot reliably determine local
versus relayed origin because the pinned upstream event does not carry that
provenance before insertion. `isRelayer` is authoritative in later live state
reads; consumers must not treat its initial callback value as a transport
security boundary.

## Typed RPC payload

`XelisXswdRequest.payload` is the only authoritative callback projection. It is
an `XelisXswdObjectValue` for permission and prefetch-permission requests and is
absent for lifecycle notifications. XWF does not expose an intermediate JSON
string and does not define daemon or wallet RPC DTOs.

Permission callbacks also expose a semantic envelope through
`request.permissionRequest`: the exact method name, optional parameters, and
the originating `XelisXswdRequest`. Parameters preserve either the named
object or positional array form; an omitted or explicit JSON null is `null`.
Prefetch callbacks similarly expose
`request.prefetchPermissionsRequest`, containing the optional reason, the exact
ordered permission names, and its source request. XWF validates these envelope
shapes before invoking the consumer. It does not normalize method names or
interpret method-specific parameters; those decisions belong to the consumer.
The original `payload` remains available for compatible consumers and is the
value from which both semantic projections are derived.

The sealed `XelisXswdValue` variants preserve nulls, booleans, strings,
floating-point values, arrays, objects, and integers. Native `i64` and `u64`
values cross the private bridge as canonical decimal strings and are exposed as
`XelisXswdIntegerValue.value` `BigInt`s. They never cross a JavaScript `Number`.
Genuine upstream `f64` values remain `XelisXswdFloatValue` `double`s, and
numeric primitives already encoded as strings remain strings.

The projection preserves values in the effective `RpcRequest` received by XWF;
it does not promise to recover the original JSON lexeme of a raw number larger
than `u64::MAX` if an upstream parser already represented that number as a
floating-point value.

Inspect only the fields required for the decision and reject unexpected value
kinds. For example:

```dart
final payload = request.payload;
if (payload is! XelisXswdObjectValue) {
  return XelisXswdDecision.reject;
}
final amount = payload.fields['amount'];
if (amount is! XelisXswdIntegerValue) {
  return XelisXswdDecision.reject;
}
// Review amount.value as a BigInt inside this callback only.
```

RPC payloads are active, untrusted, and potentially sensitive. Protocol-valid
requests may include explicit signer private keys. XWF projects those fields
faithfully but never includes scalar values or object keys in authored
`toString()` output. This redaction is protection against implicit rendering,
not a security barrier after code reads `.value`, `.values`, or `.fields`. An
explicit consent UI may display the exact fields needed for a decision.
Consumers must not log, retain automatically, attach to support references,
send to analytics, or include complete payloads in crash reports or toasts.

## Projection resource limits

The default `XelisXswdProjectionLimits` budget is:

- 64 levels of nesting;
- 65,536 private projection tokens;
- 4,096 members in one array or object;
- 4 MiB of UTF-8 in one string or object key;
- 8 MiB of cumulative UTF-8 string and key data.

Applications may choose other positive values up to the XWF technical ceilings:
depth 128, 262,144 tokens, 65,536 members, 8 MiB per text, and 16 MiB cumulative
text. The cumulative budget must be at least the per-text budget.

A projection failure sends no partial data to Dart, does not invoke the
consumer callback, and produces a static technical error. Only an explicit
prefetch rejection returns an empty permission table. These limits protect
projection, FRB and Dart from amplifying an already parsed payload; they do not
limit WebSocket reception, decryption, or upstream `RpcRequest` construction.

## Errors and diagnostics

Every façade operation maps bridge failures to `XelisWalletException` with its
exact `wallet.xswd.*` operation. Typed native failures keep their structured
classification. Untyped native failures use the documented conservative
`operation.failed` adapter fallback without parsing exception prose.

Invalid relayer encryption keys fail before the native call as structured
`input.invalid` errors. Consumers must make recovery and presentation decisions
from structured fields and must never show `diagnosticMessage` or caught
exception text. Follow [`error-handling.md`](error-handling.md) for exception
handling and [`logging.md`](logging.md) for diagnostic retention.

An invalid, detached, stale, disconnected, or other-wallet session projection
fails before the native call with `state.conflict /
XSWD_SESSION_REFERENCE_INVALID`. Native lookup uses the same classification if
the exact registry entry is no longer active. A conflicting lifecycle call or
a same-ID admission/close attempt made while the other operation is active fails before FFI with
`state.conflict / XSWD_APPLICATION_OPERATION_IN_PROGRESS`; retry only after the
first future settles. Permission mutation and close failures use
`XSWD_PERMISSION_UPDATE_FAILED` and
`XSWD_SESSION_CLOSE_FAILED`; their diagnostic text is not a control-flow
contract.
