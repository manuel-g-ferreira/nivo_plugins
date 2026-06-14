import 'package:nivo_plugins/plugin_install_manifest.dart';
import 'package:nivo_plugins/plugin_process.dart';

/// Runs [getPluginInfo] on a built plugin binary (build-time validation).
Future<PluginInstallManifest> probePluginManifest(String executablePath) async {
  const timeout = Duration(seconds: 5);
  final process = PluginProcess(executablePath);
  try {
    await process.start();
    final response = await process.send({
      'command': 'getPluginInfo',
    }, timeout: timeout);
    if (response['success'] != true) {
      throw StateError(
        'getPluginInfo failed: ${response['error'] ?? 'unknown'}',
      );
    }
    return PluginInstallManifest.fromGetPluginInfoResponse(response);
  } finally {
    await process.terminate();
  }
}
