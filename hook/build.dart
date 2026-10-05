import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

// TODO: Remove once our native_toolchain_rust version respects targetNdkApi.
// https://github.com/GregoryConrad/native_toolchain_rust/issues/113
Map<String, String> androidCargoEnvironment(CodeConfig config) {
  if (config.targetOS != OS.android) return const {};
  final compiler = config.cCompiler;
  if (compiler == null) {
    throw StateError('Android native builds require an NDK compiler.');
  }
  final (rustTarget, ndkTarget) = switch (config.targetArchitecture) {
    Architecture.arm => ('armv7-linux-androideabi', 'armv7a-linux-androideabi'),
    Architecture.arm64 => ('aarch64-linux-android', 'aarch64-linux-android'),
    Architecture.x64 => ('x86_64-linux-android', 'x86_64-linux-android'),
    final architecture => throw UnsupportedError(
      'Android architecture: $architecture',
    ),
  };
  final target = rustTarget.replaceAll('-', '_');
  final prefix = '$ndkTarget${config.android.targetNdkApi}';
  final suffix = Platform.isWindows ? '.cmd' : '';
  String binary(String name) => compiler.compiler.resolve(name).toFilePath();
  final clang = binary('$prefix-clang$suffix');
  return {
    'CC_$target': clang,
    'CXX_$target': binary('$prefix-clang++$suffix'),
    'CARGO_TARGET_${target.toUpperCase()}_LINKER': clang,
  };
}

void main(List<String> args) async {
  await build(args, (input, output) async {
    await FlutterRustBridgeNativeAssetsBuilder(
      cratePath: 'rust',
      extraCargoBuildArgs: const ['--locked'],
      extraCargoEnvironmentVariables: input.config.buildCodeAssets
          ? androidCargoEnvironment(input.config.code)
          : const {},
    ).run(input: input, output: output);
  });
}
