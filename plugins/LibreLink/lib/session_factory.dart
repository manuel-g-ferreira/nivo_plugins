import 'package:librelink_plugin/services/auth_service.dart';
import 'package:librelink_plugin/services/graph_service.dart';
import 'package:librelink_plugin/transport/llu_http.dart';
import 'package:nivo_plugins/protocol_helpers.dart';

/// Builds [LluHttp] + services from a Nivo protocol request.
class SessionFactory {
  static const defaultUsBase = 'https://api-us.libreview.io';
  static const defaultClientVersion = '4.16.0';

  static Map<String, String> optionsMap(Object? raw) =>
      ProtocolHelpers.optionsMap(raw);

  static LluHttp httpFromOptions(Map<String, String> options) {
    var base = options['apiBaseUrl'] ?? defaultUsBase;
    final region = options['region']?.trim().toLowerCase();
    if (region != null &&
        region.isNotEmpty &&
        !options.containsKey('apiBaseUrl')) {
      base = _regionToDefaultBase(region) ?? base;
    }
    return LluHttp(
      apiBaseUrl: base,
      clientVersion: options['clientVersion'] ?? defaultClientVersion,
      accountIdHash: options['accountIdHash'] ?? '',
      authToken: options['authToken'],
    );
  }

  static LluHttp? httpFromRequest(Map<String, dynamic> request) {
    final token = request['authToken'] as String?;
    final userId = request['userId'] as String?;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }
    final options = optionsMap(request['options']);
    final accountIdHash =
        options['accountIdHash'] ?? AuthService.hashAccountId(userId);
    return LluHttp(
      apiBaseUrl: options['apiBaseUrl'] ?? defaultUsBase,
      clientVersion: options['clientVersion'] ?? defaultClientVersion,
      accountIdHash: accountIdHash,
      authToken: token,
    );
  }

  static GraphService? graphServiceFromRequest(Map<String, dynamic> request) {
    final http = httpFromRequest(request);
    if (http == null) {
      return null;
    }
    return GraphService(http);
  }

  static String? _regionToDefaultBase(String region) {
    return switch (region) {
      'us' => 'https://api-us.libreview.io',
      'eu' => 'https://api-eu.libreview.io',
      'de' => 'https://api-de.libreview.io',
      'fr' => 'https://api-fr.libreview.io',
      'jp' => 'https://api-jp.libreview.io',
      'au' => 'https://api-au.libreview.io',
      _ => null,
    };
  }
}

String connectionDisplayName(Map<String, dynamic> connection) {
  final first = (connection['firstName'] as String?)?.trim() ?? '';
  final last = (connection['lastName'] as String?)?.trim() ?? '';
  final name = '$first $last'.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return connection['patientId'] as String? ?? 'Patient';
}
