import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/release/catalog.dart';

void main() {
  test('writePluginCatalogFromPlugins builds download URLs from manifests', () {
    final root = Directory.systemTemp.createTempSync('catalog_plugins_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    final plugins = Directory('${root.path}/plugins')..createSync();
    final pluginDir = Directory('${plugins.path}/MockCGM')..createSync();
    File('${pluginDir.path}/plugin.json').writeAsStringSync('''
{
  "identifier": "mockcgm",
  "displayName": "Mock CGM",
  "version": "1.2.0",
  "apiVersion": "1",
  "description": "Test plugin",
  "entry": {
    "darwin-arm64": "bin/darwin-arm64/mock-cgm",
    "linux-x64": "bin/linux-x64/mock-cgm"
  }
}
''');

    final output = '${root.path}/catalog.json';
    writePluginCatalogFromPlugins(
      pluginsRoot: plugins.path,
      publicRepo: 'owner/nivo-plugin-catalog',
      outputPath: output,
      platformIds: const ['darwin-arm64', 'linux-x64'],
    );

    final catalog =
        jsonDecode(File(output).readAsStringSync()) as Map<String, dynamic>;
    expect(catalog['plugins'], hasLength(1));
    final downloads =
        (catalog['plugins'] as List).first['downloads'] as Map<String, dynamic>;
    expect(
      downloads['linux-x64'],
      'https://raw.githubusercontent.com/owner/nivo-plugin-catalog/main/dist/mockcgm-linux-x64.nivo',
    );
  });

  test('writePluginCatalog groups assets and reads plugin metadata', () {
    final root = Directory.systemTemp.createTempSync('catalog_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    final assets = Directory('${root.path}/assets')..createSync();
    final plugins = Directory('${root.path}/plugins')..createSync();
    final pluginDir = Directory('${plugins.path}/MockCGM')..createSync();
    File('${pluginDir.path}/plugin.json').writeAsStringSync('''
{
  "identifier": "mockcgm",
  "displayName": "Mock CGM",
  "version": "1.2.0",
  "apiVersion": "1",
  "description": "Test plugin",
  "entry": { "linux-x64": "bin/linux-x64/mock-cgm" }
}
''');

    File('${assets.path}/mockcgm-linux-x64.nivo').writeAsStringSync('x');
    File('${assets.path}/mockcgm-darwin-arm64.nivo').writeAsStringSync('x');

    final output = '${root.path}/catalog.json';
    writePluginCatalog(
      assetsDir: assets.path,
      pluginsRoot: plugins.path,
      publicRepo: 'owner/nivo-plugin-catalog',
      outputPath: output,
    );

    final catalog =
        jsonDecode(File(output).readAsStringSync()) as Map<String, dynamic>;
    expect(catalog['version'], 1);
    expect(catalog['plugins'], hasLength(1));

    final plugin = (catalog['plugins'] as List).single as Map<String, dynamic>;
    expect(plugin['id'], 'mockcgm');
    expect(plugin['name'], 'Mock CGM');
    expect(plugin['version'], '1.2.0');
    expect(plugin['description'], 'Test plugin');
    expect(plugin['verified'], isTrue);

    final downloads = plugin['downloads'] as Map<String, dynamic>;
    expect(
      downloads['linux-x64'],
      'https://raw.githubusercontent.com/owner/nivo-plugin-catalog/main/dist/mockcgm-linux-x64.nivo',
    );
    expect(
      downloads['darwin-arm64'],
      'https://raw.githubusercontent.com/owner/nivo-plugin-catalog/main/dist/mockcgm-darwin-arm64.nivo',
    );
  });
}
