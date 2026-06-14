import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Metadata embedded in a shipped plugin binary (no separate sidecar).
class PluginInstallManifest {
  const PluginInstallManifest({
    required this.identifier,
    required this.displayName,
    required this.version,
    required this.author,
    required this.apiVersion,
    this.requiresLogin = true,
  });

  factory PluginInstallManifest.fromJson(Map<String, dynamic> json) {
    final caps = json['capabilities'] as Map<String, dynamic>?;
    return PluginInstallManifest(
      identifier: json['identifier'] as String,
      displayName: json['displayName'] as String,
      version: json['version'] as String? ?? '0.0.0',
      author: json['author'] as String? ?? '',
      apiVersion:
          caps?['apiVersion'] as String? ??
          json['apiVersion'] as String? ??
          '1',
      requiresLogin: json['requiresLogin'] as bool? ?? true,
    );
  }

  factory PluginInstallManifest.fromGetPluginInfoResponse(
    Map<String, dynamic> response,
  ) {
    return PluginInstallManifest.fromJson(response);
  }

  static const String embeddedMagic = 'NIVO_PLUGIN_V1';
  /// Legacy trailer magic from the GlucoseBar era; still accepted when reading installs.
  static const String _legacyEmbeddedMagic = 'GLUCOBAR_PLUGIN_V1';
  static const String installXattrKey = 'com.nivo.plugin.install';
  static const String _legacyInstallXattrKey = 'com.glucosebar.plugin.install';

  final String identifier;
  final String displayName;
  final String version;
  final String author;
  final String apiVersion;
  final bool requiresLogin;

  Map<String, dynamic> toPayload() => {
    'identifier': identifier,
    'displayName': displayName,
    'version': version,
    'author': author,
    'apiVersion': apiVersion,
    'requiresLogin': requiresLogin,
    'capabilities': {'apiVersion': apiVersion},
  };

  Map<String, dynamic> toPluginJson(String platformId, String entryRelative) {
    return {
      'identifier': identifier,
      'displayName': displayName,
      'version': version,
      'apiVersion': apiVersion,
      'author': author,
      'requiresLogin': requiresLogin,
      'entry': {platformId: entryRelative},
    };
  }

  /// Attaches metadata (macOS: xattr after codesign; Linux/Windows: trailer).
  static void attachForInstall(String executablePath, PluginInstallManifest m) {
    if (Platform.isMacOS) {
      writeXattr(executablePath, m);
      return;
    }
    embedInExecutable(executablePath, m);
  }

  /// Reads metadata without spawning the plugin.
  static PluginInstallManifest? resolveForInstall(File source) {
    return readXattr(source.path) ?? readEmbedded(source);
  }
  /// Trailer: `[json][u32 length][magic]` (non-macOS only).
  static void embedInExecutable(
    String executablePath,
    PluginInstallManifest m,
  ) {
    final magic = utf8.encode(embeddedMagic);
    final jsonBytes = utf8.encode(jsonEncode(m.toPayload()));
    final lengthBytes = ByteData(4)
      ..setUint32(0, jsonBytes.length, Endian.little);
    final file = File(executablePath);
    file.writeAsBytesSync([
      ...file.readAsBytesSync(),
      ...jsonBytes,
      ...lengthBytes.buffer.asUint8List(),
      ...magic,
    ]);
  }

  static PluginInstallManifest? readEmbedded(File executable) {
    if (!executable.existsSync()) {
      return null;
    }
    for (final magicString in [embeddedMagic, _legacyEmbeddedMagic]) {
      final manifest = _readEmbeddedWithMagic(executable, magicString);
      if (manifest != null) {
        return manifest;
      }
    }
    return null;
  }

  static PluginInstallManifest? _readEmbeddedWithMagic(
    File executable,
    String magicString,
  ) {
    if (!executable.existsSync()) {
      return null;
    }
    final length = executable.lengthSync();
    if (length < magicString.length + 4) {
      return null;
    }
    final magic = utf8.encode(magicString);
    final scanSize = min(length, 65536);
    final start = length - scanSize;
    final chunk = executable.readAsBytesSync().sublist(start);
    for (var i = chunk.length - magic.length; i >= 0; i--) {
      if (!_bytesEqual(chunk.sublist(i, i + magic.length), magic)) {
        continue;
      }
      final magicPosInFile = start + i;
      final lengthPos = magicPosInFile - 4;
      if (lengthPos < 0) {
        return null;
      }
      final jsonLength = _readUint32Le(executable, lengthPos);
      if (jsonLength <= 0 || jsonLength > 1 << 20) {
        return null;
      }
      final jsonStart = lengthPos - jsonLength;
      if (jsonStart < 0) {
        return null;
      }
      try {
        final jsonBytes = executable.readAsBytesSync().sublist(
          jsonStart,
          lengthPos,
        );
        final json = jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
        return PluginInstallManifest.fromJson(json);
      } on Object {
        return null;
      }
    }
    return null;
  }

  static void writeXattr(String executablePath, PluginInstallManifest m) {
    if (!Platform.isMacOS) {
      return;
    }
    final payload = jsonEncode(m.toPayload());
    Process.runSync('xattr', ['-w', installXattrKey, payload, executablePath]);
  }

  static PluginInstallManifest? readXattr(String executablePath) {
    if (!Platform.isMacOS) {
      return null;
    }
    for (final key in [installXattrKey, _legacyInstallXattrKey]) {
      final result = Process.runSync('xattr', ['-p', key, executablePath]);
      if (result.exitCode != 0) {
        continue;
      }
      try {
        final json =
            jsonDecode('${result.stdout}'.trim()) as Map<String, dynamic>;
        return PluginInstallManifest.fromJson(json);
      } on Object {
        continue;
      }
    }
    return null;
  }

  static int _readUint32Le(File file, int offset) {
    final bytes = file.readAsBytesSync().sublist(offset, offset + 4);
    return ByteData.sublistView(
      Uint8List.fromList(bytes),
    ).getUint32(0, Endian.little);
  }

  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
