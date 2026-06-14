import 'dart:io';

import 'package:nivo_plugins/repository_root.dart';

import 'plugin_build_util.dart';

/// Compiles Nightscout plugin to `plugins/Nightscout/bin/<platform-id>/`.
Future<void> main(List<String> args) async {
  final repoRoot = findRepositoryRoot() ?? Directory.current;
  final pluginRoot = Directory('${repoRoot.path}/plugins/Nightscout');
  if (!await pluginRoot.exists()) {
    stderr.writeln('Missing ${pluginRoot.path}');
    exit(1);
  }

  try {
    await buildPlugin(
      pluginRoot,
      entryRelativePath: 'bin/nightscout_plugin.dart',
      binaryBaseName: 'nightscout-plugin',
    );
  } on StateError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}
