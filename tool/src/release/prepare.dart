import 'dart:convert';
import 'dart:io';

import 'changelog.dart';
import 'process_runner.dart';
import 'version.dart';

Future<void> preparePluginsRelease({
  required ReleaseChannel channel,
  required BumpKind bump,
  required String rootDir,
  bool skipTag = false,
}) async {
  final previousDir = Directory.current;
  Directory.current = rootDir;

  try {
    final newVersion = await computeNextVersion(
      channel: channel,
      bump: bump,
      pubspecPath: 'pubspec.yaml',
    );

    final tag = 'v$newVersion';
    await _ensureTagAbsent(tag);

    final notes = await _collectReleaseNotes();
    final date = _today();

    updateChangelog(version: newVersion, date: date, notes: notes);
    _syncPluginVersions(newVersion);

    await runProcess('git', [
      'add',
      'CHANGELOG.md',
      'pubspec.yaml',
      'plugins/',
    ]);
    await runProcess('git', ['commit', '-m', 'Release $newVersion.']);
    if (!skipTag) {
      await runProcess('git', ['tag', '-a', tag, '-m', 'Release $newVersion']);
    }

    stdout.writeln('Prepared release $newVersion (${channel.name})');
    stdout.writeln('Tag: $tag');
    if (skipTag) {
      stdout.writeln(
        'Tag not created (--no-tag). Merge the release PR to tag.',
      );
    }
    _writeGithubOutput(version: newVersion, tag: tag);
  } finally {
    Directory.current = previousDir;
  }
}

void _syncPluginVersions(String version) {
  final pubspec = File('pubspec.yaml');
  var text = pubspec.readAsStringSync();
  final updated = text.replaceFirst(
    RegExp(r'^version:\s*\S+', multiLine: true),
    'version: $version',
  );
  if (updated == text) {
    throw StateError('Failed to update pubspec.yaml version');
  }
  pubspec.writeAsStringSync(updated);

  final pluginsDir = Directory('plugins');
  if (!pluginsDir.existsSync()) {
    throw StateError('plugins/ directory not found');
  }

  for (final pluginJson in _sortedGlob('plugins/*/plugin.json')) {
    final data =
        jsonDecode(pluginJson.readAsStringSync()) as Map<String, dynamic>;
    data['version'] = version;
    const encoder = JsonEncoder.withIndent('  ');
    pluginJson.writeAsStringSync('${encoder.convert(data)}\n');
  }

  for (final pluginPubspec in _sortedGlob('plugins/*/pubspec.yaml')) {
    var pluginText = pluginPubspec.readAsStringSync();
    final pluginUpdated = pluginText.replaceFirst(
      RegExp(r'^version:\s*\S+', multiLine: true),
      'version: $version',
    );
    if (pluginUpdated == pluginText) {
      throw StateError('Failed to update ${pluginPubspec.path} version');
    }
    pluginPubspec.writeAsStringSync(pluginUpdated);
  }

  for (final dispatch in _sortedGlob('plugins/*/lib/protocol_dispatch.dart')) {
    var dispatchText = dispatch.readAsStringSync();
    final dispatchUpdated = dispatchText.replaceFirst(
      RegExp(r"('version':\s*')[^']+(')"),
      "'version': '$version'",
    );
    if (dispatchUpdated == dispatchText) {
      throw StateError(
        'Failed to update getPluginInfo version in ${dispatch.path}',
      );
    }
    dispatch.writeAsStringSync(dispatchUpdated);
  }
}

List<File> _sortedGlob(String pattern) {
  final parts = pattern.split('/');
  final base = parts.first;
  final rest = parts.sublist(1).join('/');

  final dir = Directory(base);
  if (!dir.existsSync()) return [];

  final results = <File>[];
  for (final entity in dir.listSync()) {
    if (entity is! Directory) continue;
    final candidate = File('${entity.path}${Platform.pathSeparator}$rest');
    if (candidate.existsSync()) {
      results.add(candidate);
    }
  }
  results.sort((a, b) => a.path.compareTo(b.path));
  return results;
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

Future<String> _collectReleaseNotes() async {
  var range = 'HEAD';
  final describe = await Process.run('git', [
    'describe',
    '--tags',
    '--abbrev=0',
  ], runInShell: false);
  if (describe.exitCode == 0) {
    final lastTag = describe.stdout.toString().trim();
    range = '$lastTag..HEAD';
  }

  final log = await runProcessOutput('git', [
    'log',
    range,
    '--pretty=format:- %s (%h)',
    '--no-merges',
  ]);

  final buffer = StringBuffer('### Changed\n');
  if (log.isNotEmpty) {
    buffer.writeln(log);
  } else {
    buffer.writeln('- Maintenance release');
  }
  return buffer.toString().trimRight();
}

String _today() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
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
