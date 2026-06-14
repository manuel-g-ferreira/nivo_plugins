import 'dart:io';

import 'package:path/path.dart' as p;

const String nivoPluginExtension = '.nivoplugin';

/// Uniform type identifier for macOS file picker / UTI registration.
const String nivoPluginUti = 'com.gluco.nivo.nivoplugin';

String pluginPackageFileName(String identifier) =>
    '$identifier$nivoPluginExtension';

bool isPluginPackageFile(String path) {
  if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
    return false;
  }
  return path.toLowerCase().endsWith(nivoPluginExtension);
}
