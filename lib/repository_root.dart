import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates the nivo-plugins repository root (Dart package name: `nivo_plugins`).
Directory? findRepositoryRoot({Directory? start}) {
  var dir = start ?? Directory.current;
  for (var i = 0; i < 24; i++) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync() && _pubspecName(pubspec) == 'nivo_plugins') {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      break;
    }
    dir = parent;
  }
  return null;
}

String? _pubspecName(File pubspec) {
  for (final line in pubspec.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('name:')) {
      return trimmed.substring('name:'.length).trim();
    }
  }
  return null;
}
