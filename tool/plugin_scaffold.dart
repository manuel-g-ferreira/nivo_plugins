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
  nivo_plugins:
    path: ../..
''');

  await File(p.join(pluginRoot.path, 'README.md')).writeAsString('''
# ${options.displayName}

Nivo CGM plugin (`${options.identifier}`).

## Develop

```bash
dart run tool/glucose_plugin.dart build plugins/${options.directoryName}
```

Drag `dist/${options.identifier}.nivo` into **Settings → Plugins**.

Protocol: [PLUGIN-PROTOCOL-V1](../../docs/PLUGIN-PROTOCOL-V1.md).
Manifest: [PLUGIN-MANIFEST.md](../../docs/PLUGIN-MANIFEST.md).
''');

  await File(p.join(libDir.path, 'protocol_dispatch.dart')).writeAsString('''
import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/protocol_dtos.dart';
import 'package:nivo_plugins/protocol_helpers.dart';
import 'package:nivo_plugins/protocol_reading.dart';

/// Protocol v1 command router — replace stubs with vendor logic.
abstract final class ProtocolDispatch {
  static const _fallbackIdentifier = '${options.identifier}';
  static const _fallbackDisplayName = '${options.displayName}';
  static const _fallbackAuthor = '${options.author}';

  static Future<Map<String, dynamic>> dispatch(
    Map<String, dynamic> request,
  ) async {
    return switch (request['command'] as String?) {
      'getPluginInfo' => _getPluginInfo(),
      'authenticate' => _authenticate(request),
      'getDataSources' => _getDataSources(request),
      'getCurrentReading' => _getCurrentReading(request),
      'getHistory' => _getHistory(request),
      'fetchReadings' => _fetchReadings(request),
      _ => ProtocolHelpers.unknownCommand(),
    };
  }

  static Map<String, dynamic> _getPluginInfo() => {
        'success': true,
        'identifier': PluginManifest.runtimeIdentifier(
          fallback: _fallbackIdentifier,
        ),
        'displayName': PluginManifest.runtimeDisplayName(
          fallback: _fallbackDisplayName,
        ),
        'version': PluginManifest.runtimeVersion(fallback: '0.1.0'),
        'author': PluginManifest.runtimeAuthor(fallback: _fallbackAuthor),
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
    // TODO: call vendor API; return [AuthResult.toAuthenticateResponse].
    return AuthResult(
      authToken: 'replace-me',
      userId: 'replace-me',
      sessionOptions: const {},
    ).toAuthenticateResponse();
  }

  static Map<String, dynamic> _getDataSources(Map<String, dynamic> request) {
    return {
      'success': true,
      'dataSources': [
        {
          'id': 'default',
          'name': PluginManifest.runtimeDisplayName(
            fallback: _fallbackDisplayName,
          ),
        },
      ],
    };
  }

  static Map<String, dynamic> _getCurrentReading(Map<String, dynamic> request) {
    return {'success': true, ..._stubReading()};
  }

  static Map<String, dynamic> _getHistory(Map<String, dynamic> request) {
    final hours = ProtocolHelpers.historyHours(request);
    final reading = _stubReading();
    return {
      'success': true,
      'readings': List.generate(hours.clamp(1, 3), (_) => reading),
    };
  }

  static Map<String, dynamic> _fetchReadings(Map<String, dynamic> request) {
    final hours = ProtocolHelpers.historyHours(request);
    final reading = _stubReading();
    var history = List.generate(hours.clamp(1, 3), (_) => reading);
    final historySince = ProtocolHelpers.historySince(request);
    if (historySince != null) {
      history = ProtocolReading.filterStrictlyAfter(history, historySince);
    }
    return FetchReadingsResult(
      current: reading,
      history: history,
    ).toFetchReadingsResponse();
  }

  static Map<String, dynamic> _stubReading() => {
        'value': 100,
        'trend': 'flat',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'specialValue': null,
      };
}
''');

  await File(p.join(binDir.path, options.entryFileName)).writeAsString('''
// ${options.displayName} — JSON line protocol v1.
// Build: dart run tool/glucose_plugin.dart build plugins/${options.directoryName}
import 'package:${options.packageName}/protocol_dispatch.dart';
import 'package:nivo_plugins/plugin_stdio_runner.dart';

Future<void> main() async {
  await runPluginStdio(ProtocolDispatch.dispatch);
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
