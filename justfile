[windows]
set shell := ["powershell.exe", "-c"]

default:
    @just --list

alias gen := generate
alias validate := verify

# Fetch Dart and Flutter dependencies.
get:
    flutter pub get

# Regenerate FRB and Freezed outputs through the supported repository script.
generate:
    dart tool/generate_bindings.dart

# Apply formatting to authored Rust and Dart sources.
format:
    cargo fmt --manifest-path rust/Cargo.toml
    dart format lib test tool bin hook

# Fail when authored Rust or Dart sources need formatting.
format-check:
    cargo fmt --manifest-path rust/Cargo.toml --check
    dart format --output=none --set-exit-if-changed lib test tool bin hook

# Fast Rust-only validation.
rust-check:
    cargo check --manifest-path rust/Cargo.toml --locked

rust-test:
    cargo test --manifest-path rust/Cargo.toml --locked

# Static analysis of the Flutter package.
analyze:
    dart analyze

# Fast cross-language validation without running tests.
check:
    just format-check
    just rust-check
    just analyze

# Run the default Rust and Flutter test suites; slow Rust tests remain opt-in.
test:
    just rust-test
    dart tool/test_native.dart

# Test the Android APK alignment checker without building an APK.
test-android-16k:
    dart tool/test_android_16k.dart

# Test the release evidence checker without accessing GitHub.
test-release-evidence:
    node --test tool/ci/release_evidence.test.cjs

# Load and call the Rust library through the host Flutter test runner.
smoke-host:
    dart tool/test_native.dart test/native_library_smoke_test.dart

# Generate an isolated consumer and run or build it for one supported platform.
consumer-smoke platform mode="run":
    dart --packages=.dart_tool/package_config.json tool/consumer_smoke.dart --platform {{platform}} --mode {{mode}}

# Local checks; slow tests and the consumer matrix remain separate (docs/validation.md).
verify:
    just check
    just test
    just test-android-16k
    just diff-check

# Ensure the working tree has no whitespace errors.
diff-check:
    git diff --check

# Show the current branch and any local changes.
status:
    git status --short --branch

# Remove Flutter build outputs and generated local tool state.
clean:
    flutter clean

# Remove Rust build outputs (rust/target).
clean-rust:
    cargo clean --manifest-path rust/Cargo.toml

# Remove both Flutter and Rust build outputs.
clean-all:
    just clean
    just clean-rust

# Build the intentionally uncommitted Web package for a consuming application.
build-web:
    dart run tool/build_web.dart --output web/pkg
