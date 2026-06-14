import 'dart:convert';
import 'dart:io';

import 'package:nivo_plugins/platform_id.dart';

class PluginManifest {
  const PluginManifest({
    required this.identifier,
    required this.displayName,
    required this.version,
    required this.apiVersion,
    required this.entry,
    this.author = '',
  });

  factory PluginManifest.fromFile(File file) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return PluginManifest(
      identifier: json['identifier'] as String,
      displayName: json['displayName'] as String,
      version: json['version'] as String,
      apiVersion: json['apiVersion'] as String,
      author: json['author'] as String? ?? '',
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
  final Map<String, String> entry;

  String? resolveExecutablePath(String bundleRoot) {
    final platformId = resolvePlatformId();
    final relative = entry[platformId];
    if (relative == null) {
      return null;
    }
    return '$bundleRoot/$relative';
  }
}
