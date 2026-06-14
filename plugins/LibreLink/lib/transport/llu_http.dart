import 'dart:convert';
import 'dart:io';

import 'package:librelink_plugin/llu_exception.dart';

/// Low-level HTTP to regional LibreLink Up hosts — no business logic.
class LluHttp {
  LluHttp({
    required this.apiBaseUrl,
    required this.clientVersion,
    required this.accountIdHash,
    this.authToken,
  });

  String apiBaseUrl;
  final String clientVersion;
  final String accountIdHash;
  String? authToken;

  Uri uri(String path) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return Uri.parse('$base$path');
  }

  Map<String, String> headers({bool authenticated = false}) {
    final map = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
      'product': 'llu.android',
      'version': clientVersion,
    };
    if (authenticated && authToken != null) {
      map['authorization'] = 'Bearer $authToken';
      map['account-id'] = accountIdHash;
    }
    return map;
  }

  Future<Map<String, dynamic>> get(
    String path, {
    required bool authenticated,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri(path));
      headers(authenticated: authenticated).forEach(request.headers.set);
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        if (response.statusCode == 429) {
          throw LluException('Too many requests — try again later');
        }
        throw LluException('HTTP ${response.statusCode}: $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw LluException('Network error: $e');
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    required bool authenticated,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri(path));
      headers(authenticated: authenticated).forEach(request.headers.set);
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        if (response.statusCode == 429) {
          throw LluException('Too many requests — try again later');
        }
        throw LluException('HTTP ${response.statusCode}: $text');
      }
      return jsonDecode(text) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw LluException('Network error: $e');
    } finally {
      client.close(force: true);
    }
  }
}
