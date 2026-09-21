# xelis-wallet-flutter

Shared Flutter integration for the native XELIS wallet runtime.

The package owns the consumer-independent Rust and Dart boundary used by
Flutter wallet applications. Application state management, presentation,
localized messages, retry policy, and diagnostic retention remain the
responsibility of the consuming application.

The repository is licensed under GPL-3.0-only.

## Add the package

Add the package to your application's `pubspec.yaml`:

```yaml
dependencies:
  xelis_wallet_flutter:
    git:
      url: https://github.com/xelis-project/xelis-wallet-flutter.git
      ref: v0.4.0
```

Then run `flutter pub get`.

### Requirements

Consumers need Dart 3.13 or later, Flutter 3.47 or later, and Rustup. Native
targets compile the bundled Rust runtime through Flutter Native Assets. The
package pins Rust 1.94.1 and its supported targets in
`rust/rust-toolchain.toml`.

| Target | Additional requirement |
| --- | --- |
| Android | `minSdk` 24, AGP 8.5.1 or later, and NDK r28 or later |
| iOS | iOS 13 or later and the normal Xcode toolchain |
| Linux, macOS, Windows | Normal Flutter desktop toolchain; macOS 10.15 or later |
| Web | Separate Rust/WASM build, `wasm-pack`, Rust `nightly`, and cross-origin-isolated hosting |

Import only the root library:

```dart
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';
```

The generated Flutter Rust Bridge surface under `lib/src/generated` is
private. The root library exports authored Dart contracts and the stable
`XelisWalletFlutter` façade only.

## Initialize the runtime

Runtime, logging, XELIS configuration, and the optional crypto provider are
explicit so applications control their startup order:

```dart
Future<void> initializeXelisWallet() async {
  await XelisWalletFlutter.initialize();
  await XelisWalletFlutter.initializeConfiguration();

  // Optional, once per process:
  // await XelisWalletFlutter.initializeRustLogger();

  // Enable only when required by the application:
  // await XelisWalletFlutter.initializeCryptoProvider();
}
```

Initialization is idempotent and concurrent calls are shared. Native log and
progress streams each replace one process-global sink, so retain at most one
subscription of each kind.

## Open and close a wallet

Wallet creation, recovery, and opening return an authored `XelisWallet`
handle. Passwords, seeds, and private keys pass directly to Rust and are not
persisted or logged by the Dart façade.

```dart
XelisWallet? wallet;
try {
  wallet = await XelisWalletFlutter.openWallet(
    walletPath: walletPath,
    password: password,
    network: XelisNetwork.mainnet,
    precomputedTableType: const XelisPrecomputedTableType.l1Low(),
  );

  await wallet.setOnline(daemonAddress: daemonAddress);
  final balance = await wallet.getXelisBalance();
  // Project `balance` in application state.
} finally {
  final handle = wallet;
  if (handle != null) {
    try {
      await handle.close();
    } finally {
      handle.dispose();
    }
  }
}
```

`close()` is terminal, idempotent, and coalesces concurrent calls. `dispose()`
releases the local opaque handle after the close attempt; it does not dispose
the process-wide runtime. Create runtime subscriptions before `setOnline()` and
keep business subscriptions for the whole wallet session.

## Guides

| Topic | Guide |
| --- | --- |
| Structured failures and support IDs | [`docs/error-handling.md`](docs/error-handling.md) |
| Standard and integrated addresses | [`docs/address-api.md`](docs/address-api.md) |
| Destination-first address book | [`docs/address-book-api.md`](docs/address-book-api.md) |
| Balances, assets, history, and explicit extra-data reads | [`docs/wallet-read-api.md`](docs/wallet-read-api.md) |
| Transaction preparation, review, cancellation, and broadcast | [`docs/prepared-transactions.md`](docs/prepared-transactions.md) |
| Runtime and business events | [`docs/runtime-events.md`](docs/runtime-events.md) |
| Native logging | [`docs/logging.md`](docs/logging.md) |
| Multisig wire protocol | [`docs/multisig-signing-protocol.md`](docs/multisig-signing-protocol.md) |
| XSWD lifecycle, relayers, and redaction | [`docs/xswd-api.md`](docs/xswd-api.md) |
| Web build, hosting, storage, and limits | [`docs/web.md`](docs/web.md) |
| Maintainer and release validation | [`docs/validation.md`](docs/validation.md) |
| Alignment with the locked XELIS core | [`docs/upstream-compatibility.md`](docs/upstream-compatibility.md) |

Every Rust `u64` exposed by package-owned models uses Dart `BigInt`, including
on Web. Stable failures use `XelisWalletException`; applications should map its
structured code to localized copy and never display or parse its diagnostic
message.

## Web quick start

Web uses Flutter's default JavaScript build together with the wallet Rust code
compiled separately to shared-memory WebAssembly:

```text
dart run xelis_wallet_flutter:build_web --output web/pkg
flutter build web
```

The host must return `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`. Flutter's separate `--wasm` mode
is not currently validated with the pinned bridge version. See
[`docs/web.md`](docs/web.md) before deploying or relying on browser storage.

## Maintainer validation

Pull-request checks, release evidence, platform consumer tests, and bridge
generation are documented in [`docs/validation.md`](docs/validation.md).
