# Maintainer validation

This guide defines the validation evidence expected before publishing
`xelis-wallet-flutter`. Create a release tag only after reviewing the evidence
for the exact candidate commit.

## Local checks

After changing the Rust bridge surface, regenerate bindings before running the
package checks:

```text
flutter pub get
dart tool/generate_bindings.dart
dart format --output=none --set-exit-if-changed lib test tool bin hook
dart analyze
dart tool/test_native.dart
cd rust
cargo fmt --check
cargo check --locked
cargo test --locked
```

`dart tool/generate_bindings.dart` is the supported generation path. It avoids
running Native Asset hooks against stale or missing generated Rust bindings.
Install the matching generator with
`cargo install flutter_rust_bridge_codegen --version 2.13.0 --locked`.
Never edit `lib/src/generated/rust_bridge/**` or
`rust/src/frb_generated.rs` manually.

`dart tool/test_native.dart` runs `flutter test`, including a host smoke that
initializes and calls the Rust library. On Linux it sets
`FRB_DART_LOAD_EXTERNAL_LIBRARY_NATIVE_LIB_DIR` to the absolute
`build/native_assets/linux` directory populated by Flutter's build hook. It
does not run a second Cargo build or use `rust/target/release`. Windows and
macOS retain their existing loading environment. Run the script directly with
`dart`, not `dart run`, to avoid an extra hook invocation before Flutter starts.
Use the default Flutter build directory for this package test command.

Test arguments are forwarded, so the focused loading check is:

```text
dart tool/test_native.dart test/native_library_smoke_test.dart
```

This launcher is for host package tests, not Web or device integration tests.
Consumer builds keep their normal bundled-library loading. A passing host smoke
is the lightweight pull-request boundary, not proof for every supported
platform.

Native builds use `--locked` and require an up-to-date `rust/Cargo.lock`.

## Real XSWD transport tests

Two Rust tests intentionally use production Argon2 work and real loopback
WebSocket transports. They remain ignored in the fast Rust suite and are run
serially by the Linux job in the manual consumer workflow:

```text
cd rust
cargo test --locked --lib api::xswd::imp::tests::network::real_local_close_emits_cancel_and_disconnect_before_cleanup -- --ignored --exact --test-threads=1
cargo test --locked --lib api::xswd::imp::tests::network::real_relayer_close_stops_transport_while_disconnect_callback_is_pending -- --ignored --exact --test-threads=1
```

Each invocation must report exactly one passing test. A successful command
that selected zero tests is not evidence. Run them in series because the local
test uses the production XSWD port.

## Generated consumer matrix

`tool/consumer_smoke.dart` creates a clean Flutter application under the
system temporary directory and depends on the current package through a local
path. It deletes only its own direct temporary child unless `--keep` is set.

```text
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform linux --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform windows --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform macos --mode run
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform android --mode build
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform ios --mode build
dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform web --mode run
```

`run` is supported for Linux, macOS, Windows, and Web. Mobile targets use a
release build. Validate each native platform on an appropriate host.

The Web run builds the resolved package's Rust/WASM bundle, builds a release
Flutter consumer, and launches headless Chrome. It verifies bridge
initialization and an integrated-address round trip containing `2^53 + 1` and
`u64::MAX`. It does not exercise the XSWD relay, permission review, decision
callbacks, durable browser storage, or network broadcast.

GitHub Actions runs the complete consumer matrix only on an explicit manual
dispatch of **Consumer validation** with `platform: all`. Select one platform
for development checks. Ordinary pull requests and tags do not rebuild this
matrix.

## Android 16 KB pages

An Android release is accepted only when every supported 64-bit ABI has both
16 KB ZIP alignment and 16 KB ELF segment alignment.

XWF's `rust/build.rs` explicitly sets 16 KB maximum and common page sizes when
linking its ARM64 and x86_64 Android shared library. This applies to Native
Assets consumers as well as direct Cargo builds; it does not rely on a
consumer's working directory or NDK defaults. Other targets are unchanged.
The Rust suite includes `android_build_contract` to protect target selection.
The APK checks below still verify the actual result, including other bundled
libraries; compiler configuration alone is not release evidence.

```text
dart tool/test_android_16k.dart
bash tool/check_android_16k.sh <release.apk>
```

Run the checker on Linux, macOS, or Git Bash with `ANDROID_HOME` set. It must
reject unreadable and malformed ELF output as well as unaligned libraries.
ARM64 and x86_64 are 16 KB targets; ARMv7 remains a 4 KB runtime target and is
not a 64-bit alignment failure.

Passing the artifact checks does not replace installing and launching the
release consumer on a real or emulated 16 KB Android environment.

## Release evidence

Before creating a release tag, record the result of:

- Dart analysis, Flutter tests, and locked Rust checks;
- both real XSWD transport-close tests with one selected test each;
- Linux, Windows, macOS, Android, iOS, and Web consumer jobs;
- Android artifact alignment and 16 KB execution;
- Web release smoke under the hosting conditions in [the Web guide](web.md).

Successful commands prove only the paths they execute. Record skipped hosts,
unverified browser engines, unrelated failures, and residual upstream gaps.

## Publishing sequence

1. Commit the release documentation and verify that `pubspec.yaml`,
   `rust/Cargo.toml`, the changelog, and the README installation reference agree
   on the release version.
2. Push the reviewed branch and run **Pull request validation** and
   **Consumer validation** manually on that branch, selecting `all` for the
   consumer matrix. Verify that both runs tested the intended commit.
3. Review the results and the separate Android 16 KB execution evidence.
   The Android CI job builds and checks alignment; it does not launch an
   emulator. Resolve failed or missing required checks before tagging.
4. Run **Release evidence** manually on the same branch and confirm its SHA.
   This lightweight preflight reads existing results without rebuilding.
5. Create the annotated tag on that validated commit:
   `git tag -a vX.Y.Z <validated-commit> -m "Release X.Y.Z"`.
6. Push that tag explicitly with `git push origin vX.Y.Z`. The tag triggers
   only **Release evidence**; inspect its result before announcing release.

Tags are the Git installation boundary; this package is not published to
pub.dev (`publish_to: none`). Do not move an already published release tag.

## Lightweight release gate

**Release evidence** uses read-only Actions access and no Flutter/Rust setup.
It checks the resolved commit (including annotated tags), not the latest green
run on the branch. Both validation workflows must have a completed successful
manual run for that exact SHA in this repository. The newest manual run of each
workflow is authoritative; older successes cannot hide a newer failure or an
in-progress run. All six consumer jobs must be present and successful in that
run; skipped platforms do not count. Finish with `platform: all`, not a targeted
run, before the preflight. A new commit requires new validation evidence.

Missing, deleted, inaccessible, or failed evidence fails the gate without
launching builds. Complete the missing validation, then rerun the gate. Its
summary links the accepted runs. Android 16 KB execution remains a separate
manual release requirement, not a guarantee of this automated check.

A tag-triggered failure does not undo or prevent the Git tag push. Use the
manual preflight before tagging; this workflow is an evidence check, not a
repository tag-protection rule. Evidence is checked at execution time, so review
any subsequent reruns before announcing the release.

The checker uses Node's built-in test runner, with no npm dependencies:
`node --test tool/ci/release_evidence.test.cjs`. These tests run in PR validation
and the lightweight gate. For local CI/docs-only validation, run these tests
and lint the workflows; no wallet rebuild is needed.
