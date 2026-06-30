import 'dart:convert';
import 'dart:io';

import 'package:nivo_plugins/platform_id.dart';
import 'package:path/path.dart' as p;

class PluginManifest {
  const PluginManifest({
    required this.identifier,
    required this.displayName,
    required this.version,
    required this.apiVersion,
    required this.entry,
    this.author = '',
    this.description,
  });

  factory PluginManifest.fromFile(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return PluginManifest(
      identifier: json['identifier'] as String,
      displayName: json['displayName'] as String,
      version: json['version'] as String,
      apiVersion: json['apiVersion'] as String,
      author: json['author'] as String? ?? '',
      description: json['description'] as String?,
      entry: (json['entry'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      ),
    );
  }

  final String identifier;
  final String displayName;
  final String version;
  final String apiVersion;
  final String author;
  final String? description;
  final Map<String, String> entry;

  String? resolveExecutablePath(String bundleRoot) {
    final platformId = resolvePlatformId();
    final relative = entry[platformId];
    if (relative == null) {
      return null;
    }
    return '$bundleRoot/$relative';
  }

  static PluginManifest? _runtimeCache;
  static bool _runtimeLookupDone = false;

  /// Loads `plugin.json` from the plugin bundle directory at runtime.
  ///
  /// Resolves relative to a compiled binary (`bin/<platform>/…`) or a Dart
  /// entry script (`bin/*_plugin.dart`) when running under `dart run`.
  static PluginManifest? loadNearRuntime() {
    if (_runtimeLookupDone) {
      return _runtimeCache;
    }
    _runtimeLookupDone = true;
    final file = resolvePluginManifestFile();
    if (file == null) {
      return null;
    }
    try {
      _runtimeCache = PluginManifest.fromFile(file);
    } on Object {
      _runtimeCache = null;
    }
    return _runtimeCache;
  }

  static String runtimeVersion({String fallback = '0.0.0'}) {
    return loadNearRuntime()?.version ?? fallback;
  }

  static String runtimeAuthor({String fallback = ''}) {
    return loadNearRuntime()?.author ?? fallback;
  }

  static String runtimeIdentifier({required String fallback}) {
    return loadNearRuntime()?.identifier ?? fallback;
  }

  static String runtimeDisplayName({required String fallback}) {
    return loadNearRuntime()?.displayName ?? fallback;
  }
}

/// Locates `plugin.json` next to the plugin root (`plugins/<Name>/plugin.json`).
File? resolvePluginManifestFile() {
  if (Platform.resolvedExecutable.isNotEmpty) {
    final exeDir = File(Platform.resolvedExecutable).parent;
    final fromBinary = File(p.join(exeDir.parent.parent.path, 'plugin.json'));
    if (fromBinary.existsSync()) {
      return fromBinary;
    }
  }

  final script = Platform.script;
  if (script.scheme == 'file') {
    final fromScript = File(
      p.join(File.fromUri(script).parent.parent.path, 'plugin.json'),
    );
    if (fromScript.existsSync()) {
      return fromScript;
    }
  }

  return null;
}
