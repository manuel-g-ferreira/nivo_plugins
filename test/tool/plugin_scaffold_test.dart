import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../../tool/plugin_scaffold.dart';

void main() {
  test('parseScaffoldOptions builds stable names', () {
    final o = parseScaffoldOptions(
      identifier: 'mycgm',
      displayName: 'My CGM Plugin',
      author: 'Test Author',
    );
    expect(o.directoryName, 'MyCGMPlugin');
    expect(o.binaryBaseName, 'my-cgm-plugin');
    expect(o.packageName, 'my_cgm_plugin');
  });

  test('createPluginScaffold writes expected tree', () async {
    final repo = await Directory.systemTemp.createTemp('gb_scaffold_');
    addTearDown(() => repo.delete(recursive: true));

    final options = parseScaffoldOptions(
      identifier: 'scaffoldtest',
      displayName: 'Scaffold Test',
    );
    final root = await createPluginScaffold(repoRoot: repo, options: options);

    expect(File(p.join(root.path, 'plugin.json')).existsSync(), isTrue);
    expect(File(p.join(root.path, 'pubspec.yaml')).existsSync(), isTrue);
    expect(
      File(p.join(root.path, 'pubspec.yaml')).readAsStringSync(),
      contains('nivo_plugins'),
    );
    expect(
      File(p.join(root.path, 'lib', 'protocol_dispatch.dart')).readAsStringSync(),
      allOf(contains('ProtocolHelpers'), contains('PluginManifest')),
    );
    expect(File(p.join(root.path, 'lib', 'plugin_config.dart')).existsSync(), isFalse);
    expect(
      File(p.join(root.path, 'lib', 'protocol_dispatch.dart')).existsSync(),
      isTrue,
    );
    final binEntry = Directory(p.join(root.path, 'bin'))
        .listSync()
        .whereType<File>()
        .firstWhere((f) => f.path.endsWith('_plugin.dart'));
    expect(binEntry.readAsStringSync(), contains('runPluginStdio'));
  });
}
