import 'dart:convert';
import 'dart:io';

import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:path/path.dart' as p;

import 'catalog_target.dart';

final _platformSuffixPattern = RegExp(
  r'^(.+)-(darwin-arm64|darwin-x64|linux-x64|windows-x64)\.nivo$',
);

/// Writes [catalog.json] from [pluginsRoot] manifests and expected release platforms.
///
/// Used on release PRs before binaries exist; download URLs target [publicRepo]/dist/.
void writePluginCatalogFromPlugins({
  required String pluginsRoot,
  required String publicRepo,
  required String outputPath,
  String catalogName = 'Nivo plugins',
  String branch = defaultCatalogBranch,
  String distDir = defaultCatalogDistDir,
  List<String> platformIds = releasePlatformIds,
}) {
  final manifests = _loadManifestsByIdentifier(pluginsRoot);
  if (manifests.isEmpty) {
    throw StateError('No plugins with plugin.json in $pluginsRoot');
  }

  final plugins = <Map<String, dynamic>>[];
  for (final manifest in manifests.values.toList()
    ..sort((a, b) => a.identifier.compareTo(b.identifier))) {
    final downloads = <String, String>{};
    for (final platformId in platformIds) {
      if (!manifest.entry.containsKey(platformId)) {
        continue;
      }
      final fileName = '${manifest.identifier}-$platformId.nivo';
      downloads[platformId] = _distDownloadUrl(
        publicRepo: publicRepo,
        branch: branch,
        distDir: distDir,
        fileName: fileName,
      );
    }
    if (downloads.isEmpty) {
      throw StateError(
        'Plugin ${manifest.identifier} has no downloads for release platforms',
      );
    }
    plugins.add(_pluginCatalogEntry(manifest, downloads));
  }

  _writeCatalogJson(
    outputPath: outputPath,
    catalogName: catalogName,
    plugins: plugins,
  );
}

/// Writes Nivo-compatible [catalog.json] from staged `{id}-{platform}.nivo` assets.
void writePluginCatalog({
  required String assetsDir,
  required String pluginsRoot,
  required String publicRepo,
  required String outputPath,
  String catalogName = 'Nivo plugins',
  String branch = defaultCatalogBranch,
  String distDir = defaultCatalogDistDir,
}) {
  final assets = Directory(assetsDir);
  if (!assets.existsSync()) {
    throw StateError('Assets directory not found: $assetsDir');
  }

  final downloadsByPlugin = <String, Map<String, String>>{};
  for (final entity in assets.listSync()) {
    if (entity is! File || !entity.path.endsWith('.nivo')) {
      continue;
    }
    final name = p.basename(entity.path);
    final match = _platformSuffixPattern.firstMatch(name);
    if (match == null) {
      stderr.writeln('Skipping non-catalog asset name: $name');
      continue;
    }
    final id = match.group(1)!;
    final platformId = match.group(2)!;
    downloadsByPlugin.putIfAbsent(id, () => {});
    downloadsByPlugin[id]![platformId] = _distDownloadUrl(
      publicRepo: publicRepo,
      branch: branch,
      distDir: distDir,
      fileName: name,
    );
  }

  if (downloadsByPlugin.isEmpty) {
    throw StateError('No catalog assets matching {id}-{platform}.nivo in $assetsDir');
  }

  final manifestsById = _loadManifestsByIdentifier(pluginsRoot);
  final plugins = <Map<String, dynamic>>[];

  for (final entry in downloadsByPlugin.entries) {
    final manifest = manifestsById[entry.key];
    if (manifest == null) {
      throw StateError('No plugin.json for identifier "${entry.key}"');
    }
    plugins.add(_pluginCatalogEntry(manifest, entry.value));
  }

  _writeCatalogJson(
    outputPath: outputPath,
    catalogName: catalogName,
    plugins: plugins,
  );
}

Map<String, dynamic> _pluginCatalogEntry(
  PluginManifest manifest,
  Map<String, String> downloads,
) {
  return {
    'id': manifest.identifier,
    'name': manifest.displayName,
    if (manifest.description != null && manifest.description!.isNotEmpty)
      'description': manifest.description,
    'version': manifest.version,
    'verified': true,
    'downloads': downloads,
  };
}

void _writeCatalogJson({
  required String outputPath,
  required String catalogName,
  required List<Map<String, dynamic>> plugins,
}) {
  final catalog = {
    'version': 1,
    'name': catalogName,
    'plugins': plugins,
  };

  final out = File(outputPath);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(catalog)}\n');
  stdout.writeln('Wrote catalog (${plugins.length} plugins) → ${out.path}');
}

Map<String, PluginManifest> _loadManifestsByIdentifier(String pluginsRoot) {
  final root = Directory(pluginsRoot);
  if (!root.existsSync()) {
    throw StateError('Plugins root not found: $pluginsRoot');
  }

  final byId = <String, PluginManifest>{};
  for (final entity in root.listSync()) {
    if (entity is! Directory) {
      continue;
    }
    final manifestFile = File(p.join(entity.path, 'plugin.json'));
    if (!manifestFile.existsSync()) {
      continue;
    }
    final manifest = PluginManifest.fromFile(manifestFile);
    byId[manifest.identifier] = manifest;
  }
  return byId;
}

String _distDownloadUrl({
  required String publicRepo,
  required String branch,
  required String distDir,
  required String fileName,
}) {
  return 'https://raw.githubusercontent.com/$publicRepo/$branch/$distDir/$fileName';
}

/// Pushes [catalog.json] to the public repo default branch and uploads release assets.
Future<void> publishPublicCatalog({
  required String catalogPath,
  required String assetsDir,
  required String publicRepo,
  required String releaseTag,
  required String releaseTitle,
  required String releaseNotesPath,
  required bool prerelease,
}) async {
  final catalog = File(catalogPath);
  if (!catalog.existsSync()) {
    throw StateError('Catalog not found: $catalogPath');
  }

  final assets = Directory(assetsDir);
  if (!assets.existsSync()) {
    throw StateError('Assets directory not found: $assetsDir');
  }

  final tag = releaseTag.startsWith('v') ? releaseTag : 'v$releaseTag';
  final assetFiles = assets
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.nivo'))
      .toList();
  if (assetFiles.isEmpty) {
    throw StateError('No .nivo assets in $assetsDir');
  }

  final assetPaths = [
    for (final file in assetFiles) file.path,
    for (final file in assetFiles)
      if (File('${file.path}.sha256').existsSync()) '${file.path}.sha256',
  ];

  final releaseArgs = <String>[
    'release',
    'create',
    tag,
    ...assetPaths,
    '--repo',
    publicRepo,
    '--title',
    releaseTitle,
    '--notes-file',
    releaseNotesPath,
  ];
  if (prerelease) {
    releaseArgs.add('--prerelease');
  }

  final releaseResult = await Process.run('gh', releaseArgs);
  if (releaseResult.exitCode != 0) {
    final uploadArgs = <String>[
      'release',
      'upload',
      tag,
      ...assetPaths,
      '--repo',
      publicRepo,
      '--clobber',
    ];
    final uploadResult = await Process.run('gh', uploadArgs);
    if (uploadResult.exitCode != 0) {
      stderr.writeln(releaseResult.stderr);
      stderr.writeln(releaseResult.stdout);
      stderr.writeln(uploadResult.stderr);
      stderr.writeln(uploadResult.stdout);
      throw StateError('Failed to publish release to $publicRepo');
    }
  }

  final workDir = Directory.systemTemp.createTempSync('nivo-plugins-catalog-');
  try {
    final token =
        Platform.environment['GH_TOKEN'] ??
        Platform.environment['NIVO_PLUGINS_PUBLIC_TOKEN'];
    final cloneUrl = token != null && token.isNotEmpty
        ? 'https://x-access-token:$token@github.com/$publicRepo.git'
        : 'https://github.com/$publicRepo.git';

    final clone = await Process.run('git', [
      'clone',
      '--depth',
      '1',
      cloneUrl,
      workDir.path,
    ]);
    if (clone.exitCode != 0) {
      stderr.writeln(clone.stderr);
      throw StateError(
        'Failed to clone $publicRepo — create the public repo first',
      );
    }

    catalog.copySync(p.join(workDir.path, 'catalog.json'));

    final distPath = p.join(workDir.path, 'dist');
    final distDirectory = Directory(distPath);
    if (distDirectory.existsSync()) {
      distDirectory.deleteSync(recursive: true);
    }
    distDirectory.createSync(recursive: true);

    for (final entity in assets.listSync()) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      if (!name.endsWith('.nivo') && !name.endsWith('.sha256')) {
        continue;
      }
      entity.copySync(p.join(distPath, name));
    }

    await Process.run('git', [
      '-C',
      workDir.path,
      'config',
      'user.name',
      'github-actions[bot]',
    ]);
    await Process.run('git', [
      '-C',
      workDir.path,
      'config',
      'user.email',
      '41898282+github-actions[bot]@users.noreply.github.com',
    ]);

    await Process.run('git', ['-C', workDir.path, 'add', 'catalog.json', 'dist']);

    final push = await Process.run('git', [
      '-C',
      workDir.path,
      'commit',
      '-m',
      'Update catalog and dist for $tag',
    ]);
    if (push.exitCode != 0) {
      final status = await Process.run('git', [
        '-C',
        workDir.path,
        'status',
        '--porcelain',
      ]);
      if (status.stdout.toString().trim().isEmpty) {
        stdout.writeln('Catalog unchanged on $publicRepo');
        return;
      }
      stderr.writeln(push.stderr);
      throw StateError('Failed to commit catalog to $publicRepo');
    }

    if (token != null && token.isNotEmpty) {
      await Process.run('git', [
        '-C',
        workDir.path,
        'remote',
        'set-url',
        'origin',
        'https://x-access-token:$token@github.com/$publicRepo.git',
      ]);
    }

    final remote = await Process.run('git', [
      '-C',
      workDir.path,
      'push',
      'origin',
      'HEAD',
    ]);
    if (remote.exitCode != 0) {
      stderr.writeln(remote.stderr);
      throw StateError('Failed to push catalog to $publicRepo');
    }
    stdout.writeln('Updated catalog.json and dist/ on $publicRepo');
  } finally {
    workDir.deleteSync(recursive: true);
  }
}
