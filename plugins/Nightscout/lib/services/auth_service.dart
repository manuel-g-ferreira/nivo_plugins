import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nightscout_plugin/endpoints/authorization_endpoint.dart';
import 'package:nightscout_plugin/endpoints/entries_endpoint.dart';
import 'package:nightscout_plugin/endpoints/status_endpoint.dart';
import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/session_factory.dart';
import 'package:nightscout_plugin/transport/nightscout_http.dart';
import 'package:nivo_plugins/protocol_dtos.dart';

class AuthService {
  /// Nightscout expects SHA1 of API_SECRET (lowercase hex).
  static String sha1ApiSecret(String secret) {
    return sha1.convert(utf8.encode(secret)).toString();
  }

  Future<AuthResult> authenticate({
    required String baseUrl,
    String? apiSecret,
    String? accessToken,
  }) async {
    final normalized = SessionFactory.normalizeBaseUrl(baseUrl);
    if (normalized == null) {
      throw NightscoutException('Nightscout site URL is required');
    }

    final secret = apiSecret?.trim();
    final token = accessToken?.trim();
    final hasSecret = secret != null && secret.isNotEmpty;
    final hasToken = token != null && token.isNotEmpty;

    if (!hasSecret && !hasToken) {
      throw NightscoutException('API secret or access token is required');
    }

    if (hasSecret) {
      final http = NightscoutHttp(
        baseUrl: normalized,
        apiSecretHash: sha1ApiSecret(secret),
        accessToken: hasToken ? token : null,
      );
      if (await _probe(http)) {
        return _secretResult(http, normalized, secret: secret, token: token);
      }
    }

    final tokenCandidate = hasToken ? token : secret!;
    final bearerHttp = NightscoutHttp(baseUrl: normalized);
    final bearer = await AuthorizationEndpoint(
      bearerHttp,
    ).requestBearer(tokenCandidate);
    final jwtHttp = NightscoutHttp(
      baseUrl: normalized,
      bearerToken: bearer,
    );
    await EntriesEndpoint(jwtHttp).fetchLatest(count: 1);

    return AuthResult(
      authToken: 'jwt:$bearer',
      userId: normalized,
      defaultDataSourceId: EntryMapper.defaultDataSourceId,
      sessionOptions: {
        'baseUrl': normalized,
        'bearerToken': bearer,
        if (hasSecret) 'apiSecretHash': sha1ApiSecret(secret),
        'accessToken': tokenCandidate,
      },
    );
  }

  Future<bool> _probe(NightscoutHttp http) async {
    try {
      await StatusEndpoint(http).fetch();
      return true;
    } on NightscoutException {
      try {
        await EntriesEndpoint(http).fetchLatest(count: 1);
        return true;
      } on NightscoutException {
        return false;
      }
    }
  }

  AuthResult _secretResult(
    NightscoutHttp http,
    String normalized, {
    required String secret,
    String? token,
  }) {
    return AuthResult(
      authToken: http.apiSecretHash!,
      userId: normalized,
      defaultDataSourceId: EntryMapper.defaultDataSourceId,
      sessionOptions: {
        'baseUrl': normalized,
        'apiSecretHash': http.apiSecretHash!,
        if (token != null && token.isNotEmpty) 'accessToken': token,
      },
    );
  }
}
