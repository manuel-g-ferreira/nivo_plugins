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
      File(p.join(root.path, 'lib', 'protocol_dispatch.dart')).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        p.join(root.path, 'bin'),
      ).listSync().any((e) => e.path.endsWith('_plugin.dart')),
      isTrue,
    );
  });
}
