import 'dart:io';

import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('PluginManifest.fromFile reads version and metadata', () async {
    final root = await Directory.systemTemp.createTemp('manifest_read_');
    addTearDown(() => root.delete(recursive: true));

    final pluginRoot = Directory(p.join(root.path, 'MyPlugin'));
    final binDir = Directory(p.join(pluginRoot.path, 'bin'));
    await binDir.create(recursive: true);

    await File(p.join(pluginRoot.path, 'plugin.json')).writeAsString('''
{
  "identifier": "myplugin",
  "displayName": "My Plugin",
  "version": "2.3.4",
  "apiVersion": "1",
  "author": "Test",
  "entry": {
    "linux-x64": "bin/linux-x64/my-plugin"
  }
}
''');

    final entry = File(p.join(binDir.path, 'my_plugin.dart'));
    await entry.writeAsString('void main() {}');

    final manifestFile = File(p.join(entry.parent.parent.path, 'plugin.json'));
    expect(manifestFile.existsSync(), isTrue);

    final loaded = PluginManifest.fromFile(manifestFile);
    expect(loaded.identifier, 'myplugin');
    expect(loaded.version, '2.3.4');
    expect(loaded.displayName, 'My Plugin');
    expect(loaded.author, 'Test');
  });
}
