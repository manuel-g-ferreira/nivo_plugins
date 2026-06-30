import 'dart:io';

import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/platform_id.dart';
import 'package:path/path.dart' as p;

import 'plugin_build_util.dart';
import 'plugin_package_util.dart';
import 'plugin_scaffold.dart';

/// Nivo plugin authoring CLI.
///
/// ```bash
/// dart run tool/glucose_plugin.dart create --id mycgm --name "My CGM"
/// dart run tool/glucose_plugin.dart build plugins/MyCgm
/// dart run tool/glucose_plugin.dart package plugins/MyCgm
/// ```
Future<void> main(List<String> args) async {
  if (args.isEmpty || args.first == 'help' || args.contains('-h')) {
    _printUsage();
    exit(args.isEmpty ? 1 : 0);
  }

  final command = args.first;
  final rest = args.sublist(1);

  try {
    switch (command) {
      case 'create':
        await _cmdCreate(rest);
      case 'build':
        await _cmdBuild(rest);
      case 'package':
        await _cmdPackage(rest);
      case 'platform-id':
        stdout.writeln(resolvePlatformId());
        exit(0);
      default:
        stderr.writeln('Unknown command: $command\n');
        _printUsage();
        exit(1);
    }
  } on ArgumentError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}

Future<void> _cmdCreate(List<String> args) async {
  final parsed = _parseFlags(args);
  final id = parsed.flags['id'];
  final name = parsed.flags['name'];
  if (id == null || name == null) {
    throw ArgumentError('create requires --id and --name');
  }

  final options = parseScaffoldOptions(
    identifier: id,
    displayName: name,
    author: parsed.flags['author'] ?? 'Nivo',
    directoryName: parsed.flags['dir'],
  );

  final repoRoot = Directory.current;
  final pluginRoot = await createPluginScaffold(
    repoRoot: repoRoot,
    options: options,
    force: parsed.flags.containsKey('force'),
  );

  stdout.writeln('Created plugin at ${pluginRoot.path}');
  stdout.writeln('');
  stdout.writeln('Next:');
  stdout.writeln(
    '  dart run tool/glucose_plugin.dart build plugins/${options.directoryName}',
  );
}

Future<void> _cmdBuild(List<String> args) async {
  final parsed = _parseFlags(args);
  final pluginRoot = _resolvePluginRoot(parsed.positional);
  final packageAfterBuild = !parsed.flags.containsKey('no-package');
  final entry = findPluginEntryRelativePath(pluginRoot);
  if (entry == null) {
    throw StateError('No bin/*_plugin.dart entry found in ${pluginRoot.path}');
  }

  final binaryBaseName = _binaryBaseNameFromManifest(pluginRoot);
  await buildPlugin(
    pluginRoot,
    entryRelativePath: entry,
    binaryBaseName: binaryBaseName,
    package: packageAfterBuild,
  );
}

Future<void> _cmdPackage(List<String> args) async {
  final pluginRoot = _resolvePluginRoot(args);
  final bundle = await packagePluginForDistribution(pluginRoot);
  stdout.writeln('Packaged ${bundle.path}');
}

Directory _resolvePluginRoot(List<String> args) {
  final parsed = _parseFlags(args);
  final path = parsed.positional.isNotEmpty
      ? parsed.positional.first
      : parsed.flags['path'];
  if (path == null) {
    throw ArgumentError('Pass a plugin path (e.g. plugins/MyCgm)');
  }
  final dir = Directory(path);
  if (!dir.existsSync()) {
    throw StateError('Not found: ${dir.path}');
  }
  if (!File(p.join(dir.path, 'plugin.json')).existsSync()) {
    throw StateError('plugin.json missing in ${dir.path}');
  }
  return dir;
}

String _binaryBaseNameFromManifest(Directory pluginRoot) {
  final manifest = PluginManifest.fromFile(
    File(p.join(pluginRoot.path, 'plugin.json')),
  );
  final exec = manifest.resolveExecutablePath(pluginRoot.path);
  if (exec == null) {
    throw StateError('No entry for ${resolvePlatformId()} in plugin.json');
  }
  var name = p.basename(exec);
  if (name.toLowerCase().endsWith('.exe')) {
    name = p.basenameWithoutExtension(name);
  }
  return name;
}

const _booleanFlags = {'force', 'no-package'};

({Map<String, String> flags, List<String> positional}) _parseFlags(
  List<String> args,
) {
  final flags = <String, String>{};
  final positional = <String>[];
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--')) {
      final key = arg.substring(2);
      if (_booleanFlags.contains(key) ||
          i + 1 >= args.length ||
          args[i + 1].startsWith('--')) {
        flags[key] = 'true';
      } else {
        flags[key] = args[++i];
      }
      continue;
    }
    positional.add(arg);
  }
  return (flags: flags, positional: positional);
}

void _printUsage() {
  stdout.writeln('''
Nivo plugin CLI

Usage:
  dart run tool/glucose_plugin.dart <command> [options]

Commands:
  create       Scaffold a new plugin under plugins/
  build        Compile, sign (macOS), write dist/<id>.nivo (--no-package to skip)
  package      Build dist/<id>.nivo (after compile)
  platform-id  Print Nivo platform key for this host (e.g. darwin-arm64)

Install .nivo files via **Settings → Plugins** in the Nivo app.

Examples:
  dart run tool/glucose_plugin.dart create \\
    --id mycgm --name "My CGM" --author "You"

  dart run tool/glucose_plugin.dart build plugins/MyCgm
''');
}
