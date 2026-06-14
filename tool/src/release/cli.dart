import 'dart:io';

import 'package:args/args.dart';

import 'changelog.dart';
import 'prepare.dart';
import 'publish.dart';
import 'tag.dart';
import 'version.dart';

Future<int> runReleaseCli(
  List<String> arguments, {
  required String rootDir,
}) async {
  final parser = ArgParser()
    ..addCommand('prepare', _prepareParser())
    ..addCommand('tag', ArgParser())
    ..addCommand('changelog', _changelogParser())
    ..addCommand('publish', _publishParser());

  late final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    _printUsage();
    return 64;
  }

  if (results.command == null) {
    _printUsage();
    return 64;
  }

  try {
    return await _runCommand(results.command!, rootDir: rootDir);
  } on StateError catch (e) {
    stderr.writeln(e.message);
    return 1;
  } on ProcessException catch (e) {
    stderr.writeln('$e');
    return e.errorCode;
  } catch (e) {
    stderr.writeln('$e');
    return 1;
  }
}

ArgParser _prepareParser() {
  return ArgParser()
    ..addOption('channel', mandatory: true, allowed: ['stable', 'beta'])
    ..addOption(
      'bump',
      defaultsTo: 'patch',
      allowed: ['patch', 'minor', 'major'],
    )
    ..addFlag(
      'no-tag',
      help: 'Commit version/changelog only; tag after the release PR merges.',
    );
}

ArgParser _changelogParser() {
  return ArgParser()
    ..addCommand(
      'extract',
      ArgParser()..addOption('file', defaultsTo: 'CHANGELOG.md'),
    );
}

ArgParser _publishParser() {
  return ArgParser()
    ..addCommand('checksums', ArgParser()..addOption('dir', mandatory: true))
    ..addCommand(
      'stage',
      ArgParser()
        ..addOption('dist', mandatory: true)
        ..addOption('output', mandatory: true),
    );
}

Future<int> _runCommand(ArgResults command, {required String rootDir}) async {
  switch (command.name) {
    case 'prepare':
      await preparePluginsRelease(
        channel: parseChannel(command['channel'] as String),
        bump: parseBump(command['bump'] as String),
        rootDir: rootDir,
        skipTag: command['no-tag'] as bool,
      );
      return 0;

    case 'tag':
      await tagPluginsRelease(rootDir: rootDir);
      return 0;

    case 'changelog':
      return _runChangelog(command, rootDir: rootDir);

    case 'publish':
      return _runPublish(command, rootDir: rootDir);

    default:
      _printUsage();
      return 64;
  }
}

Future<int> _runChangelog(ArgResults command, {required String rootDir}) async {
  final sub = command.command;
  if (sub == null || sub.name != 'extract') {
    stderr.writeln(
      'Usage: dart run tool/release.dart changelog extract VERSION [--file CHANGELOG.md]',
    );
    return 64;
  }

  final positional = sub.rest;
  if (positional.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/release.dart changelog extract VERSION [--file CHANGELOG.md]',
    );
    return 64;
  }

  final version = positional.first;
  final file = sub['file'] as String;
  final body = extractChangelog(version, filePath: _resolve(rootDir, file));
  stdout.write(body.isEmpty ? '' : '$body\n');
  return 0;
}

Future<int> _runPublish(ArgResults command, {required String rootDir}) async {
  final sub = command.command;
  if (sub == null) {
    stderr.writeln(
      'Usage: dart run tool/release.dart publish checksums|stage ...',
    );
    return 64;
  }

  switch (sub.name) {
    case 'checksums':
      writeChecksums(_resolve(rootDir, sub['dir'] as String));
      return 0;
    case 'stage':
      stageReleaseAssets(
        distDir: _resolve(rootDir, sub['dist'] as String),
        outputDir: _resolve(rootDir, sub['output'] as String),
      );
      return 0;
    default:
      stderr.writeln(
        'Usage: dart run tool/release.dart publish checksums|stage ...',
      );
      return 64;
  }
}

String _resolve(String rootDir, String path) {
  if (path.startsWith('/')) return path;
  if (RegExp(r'^[A-Za-z]:\\').hasMatch(path)) return path;
  return '$rootDir${Platform.pathSeparator}$path';
}

void _printUsage() {
  stdout.writeln('''
Nivo Plugins release tooling

Usage:
  dart run tool/release.dart prepare --channel stable|beta [--bump patch|minor|major] [--no-tag]
  dart run tool/release.dart tag
  dart run tool/release.dart changelog extract VERSION [--file CHANGELOG.md]
  dart run tool/release.dart publish checksums --dir DIR
  dart run tool/release.dart publish stage --dist DIR --output DIR
''');
}
