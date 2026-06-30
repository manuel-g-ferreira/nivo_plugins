import 'dart:convert';
import 'dart:io';

import 'package:nivo_plugins/platform_id.dart';
import 'package:nivo_plugins/plugin_install_manifest.dart';
import 'package:nivo_plugins/plugin_package.dart';
import 'package:nivo_plugins/repository_root.dart';
import 'package:path/path.dart' as p;

import 'macos_codesign_util.dart';
import 'plugin_probe_util.dart';

/// Builds `dist/<id>.nivo` — one signed executable per platform.
Future<File> packagePluginForDistribution(Directory sourceRoot) async {
  final manifestFile = File(p.join(sourceRoot.path, 'plugin.json'));
  if (!await manifestFile.exists()) {
    throw StateError('plugin.json missing in ${sourceRoot.path}');
  }
  final manifestJson =
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
  final identifier = manifestJson['identifier'] as String;
  final packageName = pluginPackageFileName(identifier);
  final platformId = resolvePlatformId();
  final entry = (manifestJson['entry'] as Map<String, dynamic>?)?[platformId];
  if (entry is! String || entry.isEmpty) {
    throw StateError('plugin.json has no entry for $platformId');
  }

  final built = File(p.join(sourceRoot.path, entry));
  if (!built.existsSync()) {
    throw StateError('Built binary missing at ${built.path} — run build first');
  }

  final meta = PluginInstallManifest.fromJson(manifestJson);

  if (Platform.isMacOS) {
    await codesignPluginBinary(
      built.path,
      repoRoot: findRepositoryRoot()?.path,
    );
  }

  await _warnIfProbeMismatch(built.path, meta);

  final distDir = Directory(p.join(sourceRoot.path, 'dist'));
  await distDir.create(recursive: true);
  for (final entity in distDir.listSync()) {
    await entity.delete(recursive: true);
  }

  final packageFile = File(p.join(distDir.path, packageName));
  await built.copy(packageFile.path);

  if (!Platform.isWindows) {
    await Process.run('chmod', ['+x', packageFile.path]);
    if (Platform.isMacOS) {
      await codesignPluginBinary(
        packageFile.path,
        repoRoot: findRepositoryRoot()?.path,
      );
      PluginInstallManifest.attachForInstall(packageFile.path, meta);
    } else {
      PluginInstallManifest.attachForInstall(packageFile.path, meta);
    }
  } else {
    PluginInstallManifest.attachForInstall(packageFile.path, meta);
  }

  return packageFile;
}

Future<void> _warnIfProbeMismatch(
  String executablePath,
  PluginInstallManifest manifest,
) async {
  try {
    final probed = await probePluginManifest(executablePath);
    if (probed.identifier != manifest.identifier) {
      stderr.writeln(
        'Warning: plugin.json identifier "${manifest.identifier}" '
        'does not match getPluginInfo "${probed.identifier}"',
      );
    }
  } on Object catch (e) {
    stderr.writeln('Warning: getPluginInfo probe failed: $e');
  }
}
