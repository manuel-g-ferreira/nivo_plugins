import 'dart:convert';
import 'dart:io';

import 'package:nightscout_plugin/nightscout_exception.dart';

/// HTTP to a single Nightscout site base URL.
class NightscoutHttp {
  NightscoutHttp({
    required this.baseUrl,
    this.apiSecretHash,
    this.accessToken,
    this.bearerToken,
  });

  final String baseUrl;
  final String? apiSecretHash;
  final String? accessToken;
  final String? bearerToken;

  Uri uri(String pathAndQuery) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (pathAndQuery.startsWith('/')) {
      return Uri.parse('$base$pathAndQuery');
    }
    return Uri.parse('$base/$pathAndQuery');
  }

  Map<String, String> headers() {
    final map = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    if (apiSecretHash != null && apiSecretHash!.isNotEmpty) {
      map['api-secret'] = apiSecretHash!;
    }
    if (bearerToken != null && bearerToken!.isNotEmpty) {
      map['authorization'] = 'Bearer $bearerToken';
    }
    return map;
  }

  Uri _withToken(Uri uri) {
    if (accessToken == null || accessToken!.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'token': accessToken!},
    );
  }

  Future<List<dynamic>> getJsonList(String pathAndQuery) async {
    final body = await get(pathAndQuery);
    if (body is List) {
      return body;
    }
    throw NightscoutException('Expected JSON array from Nightscout');
  }

  Future<Map<String, dynamic>> getJsonObject(String pathAndQuery) async {
    final body = await get(pathAndQuery);
    if (body is Map<String, dynamic>) {
      return body;
    }
    throw NightscoutException('Expected JSON object from Nightscout');
  }

  Future<Object?> get(String pathAndQuery) async {
    final client = HttpClient();
    try {
      final target = _withToken(uri(pathAndQuery));
      final request = await client.getUrl(target);
      headers().forEach(request.headers.set);
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw NightscoutException(
          'Invalid Nightscout URL, API secret, or access token',
        );
      }
      if (response.statusCode >= 400) {
        throw NightscoutException('HTTP ${response.statusCode}: $text');
      }
      if (text.trim().isEmpty) {
        return null;
      }
      return jsonDecode(text);
    } on SocketException catch (e) {
      throw NightscoutException('Network error: $e');
    } finally {
      client.close(force: true);
    }
  }
}
