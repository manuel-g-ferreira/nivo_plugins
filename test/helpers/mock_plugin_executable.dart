import 'dart:io';

import 'package:nivo_plugins/platform_id.dart';
import 'package:path/path.dart' as p;

/// Builds or returns path to mock-cgm executable (same repo).
Future<String> ensureMockPluginExecutable() async {
  final platformId = resolvePlatformId();
  final outName = Platform.isWindows ? 'mock-cgm.exe' : 'mock-cgm';
  final mockRoot = p.join('plugins', 'MockCGM');
  final outRelative = p.join('bin', platformId, outName);
  final outFile = File(p.join(mockRoot, outRelative));

  if (!await outFile.exists()) {
    await outFile.parent.create(recursive: true);
    final pubGet = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: mockRoot);
    if (pubGet.exitCode != 0) {
      throw StateError(
        'Failed to resolve mock plugin deps: ${pubGet.stderr}\n${pubGet.stdout}',
      );
    }
    final result = await Process.run('dart', [
      'compile',
      'exe',
      '-o',
      outRelative,
      p.join('bin', 'mock_cgm_plugin.dart'),
    ], workingDirectory: mockRoot);
    if (result.exitCode != 0) {
      throw StateError(
        'Failed to compile mock plugin: ${result.stderr}\n${result.stdout}',
      );
    }
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', outRelative], workingDirectory: mockRoot);
    }
  }
  return outFile.absolute.path;
}
