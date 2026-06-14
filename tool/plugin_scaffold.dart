import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

class PluginScaffoldOptions {
  const PluginScaffoldOptions({
    required this.identifier,
    required this.displayName,
    required this.author,
    required this.directoryName,
    required this.packageName,
    required this.binaryBaseName,
    required this.entryFileName,
  });

  final String identifier;
  final String displayName;
  final String author;
  final String directoryName;
  final String packageName;
  final String binaryBaseName;
  final String entryFileName;
}

PluginScaffoldOptions parseScaffoldOptions({
  required String identifier,
  required String displayName,
  String author = 'Nivo',
  String? directoryName,
}) {
  if (!RegExp(r'^[a-z][a-z0-9-]+$').hasMatch(identifier)) {
    throw ArgumentError(
      'identifier must be a lowercase slug (e.g. librelink, my-cgm)',
    );
  }

  final dirName = directoryName ?? _pascalCaseFromWords(displayName);
  final slug = _vendorSlugFromDisplayName(displayName);
  final binaryBaseName = '$slug-plugin';
  final packageName = '${_snakeCase(slug)}_plugin';

  return PluginScaffoldOptions(
    identifier: identifier,
    displayName: displayName,
    author: author,
    directoryName: dirName,
    packageName: packageName,
    binaryBaseName: binaryBaseName,
    entryFileName: '${slug.replaceAll('-', '_')}_plugin.dart',
  );
}

Future<Directory> createPluginScaffold({
  required Directory repoRoot,
  required PluginScaffoldOptions options,
  bool force = false,
}) async {
  final pluginRoot = Directory(
    p.join(repoRoot.path, 'plugins', options.directoryName),
  );
  if (await pluginRoot.exists()) {
    if (!force) {
      throw StateError('Already exists: ${pluginRoot.path} (use --force)');
    }
    await pluginRoot.delete(recursive: true);
  }

  final binDir = Directory(p.join(pluginRoot.path, 'bin'));
  final libDir = Directory(p.join(pluginRoot.path, 'lib'));
  await binDir.create(recursive: true);
  await libDir.create(recursive: true);

  final manifest = {
    'identifier': options.identifier,
    'displayName': options.displayName,
    'version': '0.1.0',
    'apiVersion': '1',
    'author': options.author,
    'entry': {
      'darwin-arm64': 'bin/darwin-arm64/${options.binaryBaseName}',
      'darwin-x64': 'bin/darwin-x64/${options.binaryBaseName}',
      'windows-x64': 'bin/windows-x64/${options.binaryBaseName}.exe',
      'linux-x64': 'bin/linux-x64/${options.binaryBaseName}',
    },
  };

  await File(
    p.join(pluginRoot.path, 'plugin.json'),
  ).writeAsString('${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  await File(p.join(pluginRoot.path, 'pubspec.yaml')).writeAsString('''
name: ${options.packageName}
description: ${options.displayName} CGM plugin for Nivo (JSON line protocol v1).
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
''');

  await File(p.join(pluginRoot.path, 'README.md')).writeAsString('''
# ${options.displayName}

Nivo CGM plugin (`${options.identifier}`).

## Develop

```bash
dart run tool/glucose_plugin.dart build plugins/${options.directoryName}
```

Drag `dist/${options.identifier}.nivoplugin` into **Settings → Plugins**.

Protocol: [PLUGIN-PROTOCOL-V1](../../docs/plugins/PLUGIN-PROTOCOL-V1.md).
''');

  await File(p.join(libDir.path, 'plugin_config.dart')).writeAsString('''
/// Generated plugin metadata — keep in sync with [plugin.json].
class PluginConfig {
  static const identifier = '${options.identifier}';
  static const displayName = '${options.displayName}';
  static const version = '0.1.0';
  static const author = '${options.author}';
}
''');

  await File(p.join(libDir.path, 'protocol_dispatch.dart')).writeAsString('''
import 'plugin_config.dart';

/// Protocol v1 command router — replace stubs with vendor logic.
class ProtocolDispatch {
  static Future<Map<String, dynamic>> dispatch(
    Map<String, dynamic> request,
  ) async {
    final command = request['command'] as String?;
    return switch (command) {
      'getPluginInfo' => _getPluginInfo(),
      'authenticate' => _authenticate(request),
      'getDataSources' => _getDataSources(request),
      'getCurrentReading' => _getCurrentReading(request),
      'getHistory' => _getHistory(request),
      'fetchReadings' => _fetchReadings(request),
      _ => {'success': false, 'error': 'Unknown command: \$command'},
    };
  }

  static Map<String, dynamic> _getPluginInfo() => {
        'success': true,
        'identifier': PluginConfig.identifier,
        'displayName': PluginConfig.displayName,
        'version': PluginConfig.version,
        'author': PluginConfig.author,
        'requiresLogin': true,
        'iconName': 'cgm',
        'capabilities': {
          'supportsMultipleDataSources': false,
          'supportsHistory': true,
          'maxHistoryHours': 24,
          'supportsSpecialValues': false,
          'requiresRegionSelection': false,
          'supportsCombinedFetch': true,
          'apiVersion': '1',
        },
      };

  static Map<String, dynamic> _authenticate(Map<String, dynamic> request) {
    // TODO: call vendor API; return authToken + userId (+ sessionOptions).
    return {
      'success': true,
      'authToken': 'replace-me',
      'userId': 'replace-me',
    };
  }

  static Map<String, dynamic> _getDataSources(Map<String, dynamic> request) {
    return {
      'success': true,
      'dataSources': [
        {
          'id': 'default',
          'displayName': PluginConfig.displayName,
        },
      ],
    };
  }

  static Map<String, dynamic> _getCurrentReading(Map<String, dynamic> request) {
    return {
      'success': true,
      'reading': _stubReading(),
    };
  }

  static Map<String, dynamic> _getHistory(Map<String, dynamic> request) {
    final reading = _stubReading();
    return {
      'success': true,
      'readings': [reading],
    };
  }

  static Map<String, dynamic> _fetchReadings(Map<String, dynamic> request) {
    final reading = _stubReading();
    return {
      'success': true,
      'current': reading,
      'history': [reading],
    };
  }

  static Map<String, dynamic> _stubReading() => {
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'valueMgdl': 100,
        'trend': 'flat',
        'isHigh': false,
        'isLow': false,
      };
}
''');

  await File(p.join(binDir.path, options.entryFileName)).writeAsString('''
// ${options.displayName} — JSON line protocol v1.
// Build: dart run tool/glucose_plugin.dart build plugins/${options.directoryName}
import 'dart:convert';
import 'dart:io';

import 'package:${options.packageName}/protocol_dispatch.dart';

void main() {
  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) async {
    if (line.trim().isEmpty) {
      return;
    }
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = await ProtocolDispatch.dispatch(request);
      stdout.writeln(jsonEncode(response));
    } on Object catch (e) {
      stdout.writeln(jsonEncode({'success': false, 'error': e.toString()}));
    }
  });
}
''');

  return pluginRoot;
}

String _pascalCaseFromWords(String input) {
  final parts = input
      .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty);
  return parts.map((w) => w[0].toUpperCase() + w.substring(1)).join();
}

String _vendorSlugFromDisplayName(String input) {
  final parts = input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isNotEmpty && parts.last == 'plugin') {
    parts.removeLast();
  }
  if (parts.isEmpty) {
    throw ArgumentError('display name must contain at least one word');
  }
  return parts.join('-');
}

String _snakeCase(String kebab) => kebab.replaceAll('-', '_');
