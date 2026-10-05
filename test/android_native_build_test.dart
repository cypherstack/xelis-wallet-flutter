import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../hook/build.dart';

void main() {
  final root = Directory.systemTemp.uri.resolve('xwf ndk test/');
  CodeConfig config(OS os, Architecture architecture, {int api = 24}) {
    final input = BuildInputBuilder()
      ..setupShared(
        packageRoot: root,
        packageName: 'test',
        outputDirectoryShared: root.resolve('out/'),
        outputFile: root.resolve('output.json'),
      )
      ..addExtension(
        CodeAssetExtension(
          targetOS: os,
          targetArchitecture: architecture,
          linkModePreference: LinkModePreference.dynamic,
          android: os == OS.android
              ? AndroidCodeConfig(targetNdkApi: api)
              : null,
          cCompiler: os == OS.android
              ? CCompilerConfig(
                  compiler: root.resolve('bin/clang'),
                  archiver: root.resolve('bin/llvm-ar'),
                  linker: root.resolve('bin/ld'),
                )
              : null,
        ),
      );
    input.config.setupBuild(linkingEnabled: false);
    return input.build().config.code;
  }

  for (final (architecture, rustTarget, ndkTarget) in [
    (Architecture.arm, 'armv7_linux_androideabi', 'armv7a-linux-androideabi'),
    (Architecture.arm64, 'aarch64_linux_android', 'aarch64-linux-android'),
    (Architecture.x64, 'x86_64_linux_android', 'x86_64-linux-android'),
  ]) {
    for (final api in [24, 28, 35]) {
      test(
        'Android $architecture targets API $api for C, C++ and Rust linking',
        () {
          final environment = androidCargoEnvironment(
            config(OS.android, architecture, api: api),
          );
          final suffix = Platform.isWindows ? '.cmd' : '';
          final clang = root
              .resolve('bin/$ndkTarget$api-clang$suffix')
              .toFilePath();
          expect(environment, {
            'CC_$rustTarget': clang,
            'CXX_$rustTarget': root
                .resolve('bin/$ndkTarget$api-clang++$suffix')
                .toFilePath(),
            'CARGO_TARGET_${rustTarget.toUpperCase()}_LINKER': clang,
          });
        },
      );
    }
  }

  test('other platforms need no Android compiler overrides', () {
    for (final os in [OS.windows, OS.linux, OS.macOS, OS.iOS]) {
      expect(androidCargoEnvironment(config(os, Architecture.arm64)), isEmpty);
    }
  });
}
