import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:librelink_plugin/endpoints/auth_login_endpoint.dart';
import 'package:librelink_plugin/endpoints/connections_endpoint.dart';
import 'package:librelink_plugin/endpoints/country_config_endpoint.dart';
import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/transport/llu_http.dart';
import 'package:nivo_plugins/protocol_dtos.dart';

/// Orchestrates login + optional region redirect + connection prefetch.
class AuthService {
  AuthService(this._http);

  final LluHttp _http;

  static String hashAccountId(String userId) {
    return sha256.convert(utf8.encode(userId)).toString();
  }

  Future<AuthResult> authenticate({
    required String email,
    required String password,
  }) async {
    final login = AuthLoginEndpoint(_http);
    final data = await login.login(email: email, password: password);

    if (data['redirect'] == true) {
      final region = (data['region'] as String?)?.toLowerCase();
      if (region == null || region.isEmpty) {
        throw LluException('Login redirect without region');
      }
      _http.apiBaseUrl = await CountryConfigEndpoint(
        _http,
      ).resolveRegionalBase(region);
      return authenticate(email: email, password: password);
    }

    final user = data['user'] as Map<String, dynamic>;
    final userId = user['id'] as String;
    final token = _http.authToken!;

    String? defaultDataSourceId;
    try {
      final connections = await ConnectionsEndpoint(_http).list();
      if (connections.isNotEmpty) {
        defaultDataSourceId = connections.first['patientId'] as String?;
      }
    } on Object {
      // Optional prefetch.
    }

    return AuthResult(
      authToken: token,
      userId: userId,
      defaultDataSourceId: defaultDataSourceId,
      sessionOptions: {
        'apiBaseUrl': _http.apiBaseUrl,
        'accountIdHash': hashAccountId(userId),
        'clientVersion': _http.clientVersion,
      },
    );
  }
}
