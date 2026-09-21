# Upstream compatibility

XWF adapts the locked `xelis-wallet` and `xelis-common` revisions for a stable
Flutter API. It protects implicit boundaries, but does not remove a valid core
capability merely to enforce an application policy.

| Domain | Status | XWF contract |
| --- | --- | --- |
| XSWD request values | exact | Effective `i64`/`u64` values are Dart `BigInt`; strings and real floats keep their types. |
| XSWD permission envelopes | adapted | Permission and prefetch envelopes are structurally validated and exposed as source-bound authored projections; method-specific parameters remain uninterpreted. |
| XSWD prefetch decisions | adapted | Consumers may grant an exact requested subset or leave policy unchanged; native validation rejects duplicate, out-of-request, and stale results atomically. |
| XSWD permission reconciliation | adapted | A targeted edit preserves other native policies and returns a fresh projection; optional post-decision reads report observed, stale, timed-out, or failed state without blocking the decision callback. |
| XSWD explicit signers | exact | Preserved without method- or field-name filtering. Payload access is explicit and implicit string rendering is redacted. |
| XSWD resource budgets | adapted | Configurable projection budgets protect FRB and Dart under documented technical ceilings; they are not protocol limits. |
| XSWD callback failures | adapted | Exceptions, timeouts, and invalid projections are technical errors. Only an explicit callback decision is a user rejection. |
| Transaction fee modes | exact | Automatic, fixed, tip, and fixed-point multiplier modes map to the corresponding core capability with checked arithmetic. |
| Wallet extra data | opt-in | Reads and business subscriptions preserve redacted, metadata, or detailed disclosure. The upstream shared key is always omitted. |
| Native logs | opt-in | Safe scopes contain package-authored targets. Selected raw upstream targets require the explicitly unsafe local-diagnostic scope. |
| Daemon reconnection | opt-in | Application-managed reconnect remains the default; upstream auto-reconnect is experimental and explicitly supervised. |
| URL credentials and arbitrary RPC paths | intentionally unsupported | Daemon input remains a credential-free origin; XWF appends `/json_rpc`. Future authentication must use a structured contract. |
| Original JSON number lexemes | intentionally unsupported | Projection starts from the effective parsed request and does not preserve arbitrary source spelling. |
| Pre-parse relayer message limits | gap | This belongs upstream of XWF's parsed-request projection and is outside the package boundary. |
| Relayer remote-close detection | gap | Upstream waits for the active message handler before reading the next socket frame. Peer-only closure may wait for the callback timeout; explicit wallet-side close is preemptive. See [XSWD lifecycle](xswd-api.md#callback-boundary). |
| Relayer pre-dispatch closing gate | gap | A frame already selected when close begins can remain in flight, including upstream `node.*` and `xswd.*` dispatch. Strict rejection requires an upstream closing-state gate. See [XSWD lifecycle](xswd-api.md#callback-boundary). |

## Status vocabulary

- **exact**: the relevant core value or capability is preserved without a
  policy restriction.
- **adapted**: XWF changes representation or failure handling to make it safe
  and stable across Flutter platforms.
- **opt-in**: the capability exists but requires an explicit choice because it
  increases disclosure or lifecycle complexity.
- **intentionally unsupported**: XWF deliberately exposes a narrower stable
  boundary for a documented architectural reason.
- **gap**: a useful upstream capability or protection is not currently owned by
  XWF.

This matrix describes the current package contract, not a promise that every
future upstream API will be forwarded automatically. Each dependency update
still requires an atomic upstream diff audit.
