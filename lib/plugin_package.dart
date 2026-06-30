import 'dart:io';

const String nivoPluginExtension = '.nivo';

/// Uniform type identifier for macOS file picker / UTI registration.
const String nivoPluginUti = 'com.gluco.nivo.plugin';

String pluginPackageFileName(String identifier) =>
    '$identifier$nivoPluginExtension';

bool isPluginPackageFile(String path) {
  if (FileSystemEntity.typeSync(path) != FileSystemEntityType.file) {
    return false;
  }
  return path.toLowerCase().endsWith(nivoPluginExtension);
}
