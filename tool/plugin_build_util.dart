import 'dart:io';

import 'package:nivo_plugins/platform_id.dart';
import 'package:path/path.dart' as p;

import 'plugin_package_util.dart';

/// Compiles the plugin entry Dart file for the current host platform.
Future<void> buildPlugin(
  Directory pluginRoot, {
  required String entryRelativePath,
  required String binaryBaseName,
  bool package = true,
}) async {
  final entryFile = File(p.join(pluginRoot.path, entryRelativePath));
  if (!await entryFile.exists()) {
    throw StateError('Entry not found: ${entryFile.path}');
  }

  if (File(p.join(pluginRoot.path, 'pubspec.yaml')).existsSync()) {
    final pubGet = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: pluginRoot.path);
    if (pubGet.exitCode != 0) {
      stderr.writeln(pubGet.stderr);
      stderr.writeln(pubGet.stdout);
      throw StateError('dart pub get failed');
    }
  }

  final root = pluginRoot.absolute;
  final platformId = resolvePlatformId();
  final outName = Platform.isWindows ? '$binaryBaseName.exe' : binaryBaseName;
  final outRelative = p.join('bin', platformId, outName);
  await Directory(p.join(root.path, 'bin', platformId)).create(recursive: true);

  final result = await Process.run('dart', [
    'compile',
    'exe',
    '-o',
    outRelative,
    entryRelativePath,
  ], workingDirectory: root.path);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    stderr.writeln(result.stdout);
    throw StateError('dart compile exe failed');
  }
  final outPath = p.join(root.path, outRelative);
  if (!Platform.isWindows) {
    await Process.run('chmod', ['+x', outPath]);
  }
  stdout.writeln('Built $outPath ($platformId)');

  if (package) {
    final bundle = await packagePluginForDistribution(root);
    stdout.writeln('Packaged ${bundle.path}');
  }
}

/// Finds `bin/*_plugin.dart` entry source.
String? findPluginEntryRelativePath(Directory pluginRoot) {
  final binDir = Directory(p.join(pluginRoot.path, 'bin'));
  if (!binDir.existsSync()) {
    return null;
  }
  for (final entity in binDir.listSync()) {
    if (entity is File && entity.path.endsWith('_plugin.dart')) {
      return p.relative(entity.path, from: pluginRoot.path);
    }
  }
  return null;
}
