import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:nivo_plugins/plugin_package.dart';

void writeChecksums(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) {
    throw StateError('Directory not found: $dir');
  }

  for (final entity in directory.listSync()) {
    if (entity is! File) continue;
    if (entity.path.endsWith('.sha256')) continue;

    final sidecar = File('${entity.path}.sha256');
    if (sidecar.existsSync()) continue;

    final digest = sha256.convert(entity.readAsBytesSync());
    sidecar.writeAsStringSync('${digest.toString()}\n');
  }
}

void stageReleaseAssets({required String distDir, required String outputDir}) {
  final dist = Directory(distDir);
  if (!dist.existsSync()) {
    throw StateError('Dist directory not found: $distDir');
  }

  final output = Directory(outputDir);
  output.createSync(recursive: true);

  final copied = <File>[];

  for (final entity in dist.listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith(nivoPluginExtension)) continue;

    final name = entity.uri.pathSegments.last;
    final dest = File('${output.path}${Platform.pathSeparator}$name');
    entity.copySync(dest.path);
    copied.add(dest);
  }

  if (copied.isEmpty) {
    stderr.writeln('No $nivoPluginExtension files found in $distDir');
    for (final entity in dist.listSync(recursive: true)) {
      stderr.writeln(entity.path);
    }
    throw StateError('No $nivoPluginExtension files found in downloaded artifacts');
  }

  writeChecksums(output.path);
}
