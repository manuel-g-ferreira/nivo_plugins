import 'package:nightscout_plugin/services/entries_service.dart';
import 'package:nightscout_plugin/transport/nightscout_http.dart';
import 'package:nivo_plugins/protocol_helpers.dart';

abstract final class SessionFactory {
  static const defaultDataSourceId = 'default';

  static Map<String, String> optionsMap(Object? raw) =>
      ProtocolHelpers.optionsMap(raw);

  /// Normalizes user-entered site URL (Nivo username field).
  static String? normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (url.isEmpty) {
      return null;
    }
    if (!url.contains('://')) {
      url = 'https://$url';
    }
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      return null;
    }
    final scheme = parsed.scheme == 'http' || parsed.scheme == 'https'
        ? parsed.scheme
        : 'https';
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    return '$scheme://${parsed.host}$port';
  }

  static NightscoutHttp? httpFromRequest(Map<String, dynamic> request) {
    final options = optionsMap(request['options']);
    final baseUrl = options['baseUrl'] ?? request['userId'] as String?;
    if (baseUrl == null || baseUrl.isEmpty) {
      return null;
    }
    final normalized = normalizeBaseUrl(baseUrl);
    if (normalized == null) {
      return null;
    }
    final token = options['accessToken'];
    final hash = options['apiSecretHash'];
    final bearer = options['bearerToken'];
    if ((hash == null || hash.isEmpty) &&
        (token == null || token.isEmpty) &&
        (bearer == null || bearer.isEmpty)) {
      return null;
    }
    return NightscoutHttp(
      baseUrl: normalized,
      apiSecretHash: hash,
      accessToken: token,
      bearerToken: bearer,
    );
  }

  static EntriesService? entriesServiceFromRequest(
    Map<String, dynamic> request,
  ) {
    final http = httpFromRequest(request);
    if (http == null) {
      return null;
    }
    return EntriesService(http);
  }

  /// Sign-in: URL in [username], API secret in [password], optional token in options.
  static ({String baseUrl, String? apiSecret, String? accessToken})
      credentialsFrom(Map<String, dynamic> request) {
    final options = optionsMap(request['options']);
    final baseUrl = request['username'] as String? ?? options['baseUrl'] ?? '';
    final apiSecret =
        request['password'] as String? ?? options['apiSecret'] ?? '';
    final token = options['accessToken'];
    return (
      baseUrl: baseUrl,
      apiSecret: apiSecret.isEmpty ? null : apiSecret,
      accessToken: token != null && token.isNotEmpty ? token : null,
    );
  }
}
