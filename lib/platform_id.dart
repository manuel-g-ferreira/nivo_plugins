import 'dart:io';

/// Host platform key for [plugin.json] `entry` map.
String resolvePlatformId() {
  if (Platform.isWindows) {
    return 'windows-x64';
  }
  if (Platform.isLinux) {
    return 'linux-x64';
  }
  if (Platform.isMacOS) {
    final result = Process.runSync('uname', ['-m']);
    final machine = (result.stdout as String).trim();
    if (machine == 'arm64') {
      return 'darwin-arm64';
    }
    return 'darwin-x64';
  }
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}
