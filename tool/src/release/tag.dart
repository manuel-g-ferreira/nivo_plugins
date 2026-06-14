import 'dart:io';

import 'process_runner.dart';

/// Creates an annotated tag `v{pubspec-base}` on the current commit.
Future<void> tagPluginsRelease({required String rootDir}) async {
  final previousDir = Directory.current;
  Directory.current = rootDir;

  try {
    final version = readPubspecBaseVersion('pubspec.yaml');
    final tag = 'v$version';
    await _ensureTagAbsent(tag);
    await runProcess('git', ['tag', '-a', tag, '-m', 'Release $version.']);
    stdout.writeln('Tagged $tag');
    _writeGithubOutput(version: version, tag: tag);
  } finally {
    Directory.current = previousDir;
  }
}

String readPubspecBaseVersion(String pubspecPath) {
  final text = File(pubspecPath).readAsStringSync();
  final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(text);
  if (match == null) {
    throw StateError('pubspec.yaml missing version:');
  }
  return match.group(1)!.split('+').first;
}

Future<void> _ensureTagAbsent(String tag) async {
  final result = await Process.run('git', [
    'rev-parse',
    tag,
  ], runInShell: false);
  if (result.exitCode == 0) {
    throw StateError('Tag $tag already exists');
  }
}

void _writeGithubOutput({required String version, required String tag}) {
  final outputPath = Platform.environment['GITHUB_OUTPUT'];
  if (outputPath == null || outputPath.isEmpty) return;

  File(outputPath).writeAsStringSync(
    'version=$version\n'
    'tag=$tag\n',
    mode: FileMode.append,
  );
}
