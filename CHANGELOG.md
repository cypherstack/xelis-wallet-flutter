# Changelog

## 0.4.0

- Added source-bound semantic XSWD permission and prefetch projections while
  retaining the original lossless payload for compatible consumers.
- Added optional selective XSWD prefetch decisions. Native validation applies
  only an exact requested subset and leaves omitted permissions unchanged;
  legacy prefetch callbacks keep their previous all-or-none behavior.
- **Breaking for `XelisWallet` implementers:** Added targeted XSWD permission
  edits that return a fresh application projection while preserving other
  policies, plus optional bounded post-decision state observations that do not
  delay decision callbacks. Implementers must provide
  `updateXswdApplicationPermission`.

## 0.3.0

- Fixed Android ARM64 and x86_64 Rust shared-library linking to explicitly
  require 16 KB ELF alignment for Native Assets consumers.

- Fixed connection-timeout cleanup retaining worker acknowledgements while
  awaiting shutdown. Timeout releases both acknowledgements before joining the
  worker, preventing a late connection result from blocking cancellation.

- **Breaking:** XSWD session close and permission updates now require the exact
  live `XelisXswdApplication` capability instead of an application ID. Opaque
  session references remain stable across callbacks and state reads, reject
  stale/reconstructed/cross-wallet use, and distinguish simultaneous local and
  relayed applications that share an ID.
- XSWD decision handling is now bounded and cancellation-aware: exact
  cancellation/disconnect events preempt pending Dart decisions, late results
  cannot authorize requests, relayer close shuts down the client transport,
  and local close preserves upstream cancel/disconnect cleanup.
- XSWD cancellation now completes internally before acknowledging upstream,
  independently of Flutter notification failures. Slow notifications no longer
  stop event reception; the bounded deferred queue has explicit overload and
  channel-close behavior without claiming to bound upstream traffic.
- XSWD admission proposals stay non-operable until a fresh state read confirms
  upstream insertion. State-read generations and disconnect tombstones prevent
  delayed native snapshots from reviving stopped or disconnected sessions.
  Cancelled admissions cannot regain authority through late replies or reads;
  cancelling an ordinary request preserves its still-active session.
- Relayer session close now drives cancellation and client shutdown
  concurrently, so transport teardown does not wait for a blocked disconnect
  notification. Concurrent same-ID admission and close calls fail closed;
  frames already selected by the pinned upstream client remain in-flight until
  its pre-dispatch closing gate is addressed upstream.

- **Breaking:** Replaced `XelisXswdRequest.payloadJson` with the typed,
  deeply immutable `XelisXswdValue` projection for XWF 0.3.0. Native `i64` and
  `u64` request values now cross Web as exact Dart `BigInt`s, payload projection
  is resource-bounded and fail-closed, and all authored payload `toString()`
  output remains redacted.
- **Breaking:** XSWD decision callback failures now return static technical errors;
  `XelisXswdDecision.reject` is reserved for explicit consumer decisions.
  Projection limits are configurable per handler under documented XWF
  ceilings, and callback timeouts must be positive.
- **Breaking:** Expanded `XelisWalletFeePolicy` to automatic, exact fixed, tip,
  and arbitrary positive basis-point multiplier modes. Policy values are
  lossless `BigInt`s and the former 10x application-policy ceiling is removed.
- Added per-subscription redacted, metadata, and detailed business-event
  extra-data disclosure. The default preserves the XWF 0.2 redacted behavior,
  and the upstream shared encryption key is never exposed.
- **Breaking:** Wallet history, pending, and hash-detail bridge methods now
  transport `XelisWalletExtraDataDisclosure` as a three-way contract instead
  of collapsing it to a payload boolean. Explicit `redacted` reads now omit
  both payload and top-level payload kind as documented.
- **Breaking:** Replaced logger `diagnosticMode` with
  `XelisNativeLogScope`. Raw `xelis_wallet` and `xelis_common` records require
  the explicitly unsafe local-diagnostic scope. Migrate `diagnosticMode: false`
  to `scope: standard` and `diagnosticMode: true` to
  `scope: packageDiagnostic`; the unsafe upstream scope has no 0.2 equivalent.
- Added `XelisWalletConnectionOptions` with a configurable positive timeout
  and opt-in experimental upstream-managed reconnection. Application-managed
  reconnection and a 20-second connect timeout remain the defaults. The timeout
  applies only to connection establishment; offline and close always await
  native handler shutdown.
- **Build:** Updated the pinned Rust toolchain from 1.93.1 to 1.94.1 while
  retaining the same declared components and supported native targets.
- **Build:** Changed the supported binding-generation command to
  `dart tool/generate_bindings.dart`. Direct script execution prevents stale or
  missing generated Rust bindings from triggering Native Asset hooks before
  the generator can start.

## 0.2.0

- **Breaking:** Raised the minimum toolchain to Dart 3.13 and Flutter 3.47
  while migrating the private generated boundary to Freezed 4 and
  `flutter_rust_bridge` 2.13.0. Authored Dart APIs, wallet storage, and
  consumer source contracts remain unchanged.
- **Build:** Replaced the vendored Cargokit FFI-plugin integration with Flutter
  Native Assets using `flutter_rust_bridge_hooks` 2.13.0. Native consumers now
  build the pinned Rust 1.93.1 toolchain through Rustup; authored APIs, wallet
  storage, XELIS revisions, and the separate Web build remain unchanged.
- Web cancellation of the process-global native log and progress streams now
  completes after initiating the FRB listener detachment. Pull-driven wallet
  event subscriptions keep their existing fully awaited cancellation order.
- Updated `xelis_wallet` and `xelis_common` atomically to the pinned
  `b149b57aaeec42a27b0e1516a2e8ed8e00c6f394` development revision for the
  upcoming XELIS 1.25 release, including `xelis-vm` 1.3.0. Existing wallet
  storage remains compatible and requires no migration or resynchronization.
- Native hexadecimal decoding now rejects trailing bytes for private keys,
  hashes, signatures, and multisig envelopes while preserving the existing
  structured public error identifiers.
- **Breaking:** XSWD application and relayer permission names now use only the
  upstream unprefixed form, such as `get_balance`. Flutter inputs containing
  `wallet.*` fail with `input.invalid / XSWD_PERMISSION_NAME_INVALID` before
  the native call. Consumers must remove the `wallet.` prefix from permission
  constants; no wallet-storage migration is involved.
- Fixed Android native builds with the Gradle 9 toolchain generated by Flutter
  3.47.
- Aligned the undeployed Apple platform baselines with Flutter's supported
  deployment range: iOS 13 and macOS 10.15.

## 0.1.2

- Added the `xelis_wallet_flutter:build_web` executable so consumers can build
  the shared-memory Web package from the XWF revision resolved by Pub.

## 0.1.1

- Updated the native XELIS crates to a pinned 1.24.0 development revision,
  including post-release WebSocket session fixes.
- No public Dart API changes.

## 0.1.0

Initial development release of the shared Flutter integration for the native
XELIS wallet runtime.

- Authored Dart façade for runtime initialization, wallet creation, recovery,
  opening, authentication, network lifecycle, rescan, and deterministic
  close/dispose handling.
- Lossless address parsing and integrated-address creation with typed
  `DataElement` values, exact unsigned integers, ordered fields, and immutable
  blobs.
- Destination-first address book with canonical integrated destinations,
  deterministic identities, exact/base/ambiguous matching, and non-destructive
  migration of existing entries.
- Typed wallet reads and pull-driven runtime and business-event subscriptions
  for balances, assets, history, pending transactions, synchronization, and
  lifecycle changes.
- Capability-bound ordinary and multisig transaction preparation, inspection,
  signing, cancellation, and broadcast with atomic `BigInt` amounts and typed
  prepared-slot outcomes.
- Versioned structured failure contract with stable operations, codes, support
  identifiers, audited native discriminants, preserved stack traces, and
  privileged diagnostics separated from UI and standard logs.
- Package-owned native logging and XSWD contracts with explicit lifecycle,
  callback, relayer, redaction, and standard/diagnostic policies.
- Native packaging for Android, iOS, Linux, macOS, and Windows, plus a
  dedicated shared-memory Web build pipeline.
