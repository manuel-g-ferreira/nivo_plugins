import 'dart:io';

/// Signs a plugin binary so the (unsandboxed) Nivo host can spawn it.
///
/// IMPORTANT: plugins must NOT be signed with `com.apple.security.app-sandbox`
/// or `com.apple.security.inherit`. Those entitlements make the binary trap on
/// launch ("Process is not in an inherited sandbox") unless a sandboxed parent
/// launches it — and the host app is not sandboxed. An ad-hoc signature with no
/// entitlements is all Apple Silicon requires to execute a Mach-O.
Future<void> codesignPluginBinary(String path, {String? repoRoot}) async {
  if (!Platform.isMacOS) {
    return;
  }

  await Process.run('chmod', ['+x', path]);
  await Process.run('xattr', ['-d', 'com.apple.quarantine', path]);

  final identity = Platform.environment['CODESIGN_IDENTITY'] ?? '-';

  final result = await Process.run('codesign', [
    '--force',
    '--sign',
    identity,
    '--timestamp=none',
    path,
  ]);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    stderr.writeln(result.stdout);
    throw StateError('codesign failed for $path');
  }
}
