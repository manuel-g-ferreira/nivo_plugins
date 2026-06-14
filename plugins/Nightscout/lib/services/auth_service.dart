import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nightscout_plugin/endpoints/entries_endpoint.dart';
import 'package:nightscout_plugin/endpoints/status_endpoint.dart';
import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/session_factory.dart';
import 'package:nightscout_plugin/transport/nightscout_http.dart';

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

    final hasSecret = apiSecret != null && apiSecret.isNotEmpty;
    final hasToken = accessToken != null && accessToken.isNotEmpty;
    if (!hasSecret && !hasToken) {
      throw NightscoutException('API secret or access token is required');
    }

    final http = NightscoutHttp(
      baseUrl: normalized,
      apiSecretHash: hasSecret ? sha1ApiSecret(apiSecret) : null,
      accessToken: hasToken ? accessToken : null,
    );

    NightscoutException? probeError;
    var verified = false;
    try {
      await StatusEndpoint(http).fetch();
      verified = true;
    } on NightscoutException catch (e) {
      probeError = e;
    }
    if (!verified) {
      try {
        await EntriesEndpoint(http).fetchLatest(count: 1);
      } on NightscoutException catch (e) {
        throw probeError ?? e;
      }
    }

    return AuthResult(
      authToken: hasSecret ? http.apiSecretHash! : 'token:$accessToken',
      userId: normalized,
      defaultDataSourceId: EntryMapper.defaultDataSourceId,
      sessionOptions: {
        'baseUrl': normalized,
        if (hasSecret) 'apiSecretHash': http.apiSecretHash!,
        if (hasToken) 'accessToken': accessToken,
      },
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.authToken,
    required this.userId,
    required this.defaultDataSourceId,
    required this.sessionOptions,
  });

  final String authToken;
  final String userId;
  final String defaultDataSourceId;
  final Map<String, String> sessionOptions;
}
