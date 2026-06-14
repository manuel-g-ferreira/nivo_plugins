import 'dart:convert';
import 'dart:io';

import 'package:dexcomshare_plugin/dexcom_exception.dart';

/// HTTP client for Dexcom Share (unofficial REST API).
class DexcomHttp {
  DexcomHttp({required this.baseUrl});

  static const applicationId = 'd89443d2-327c-4a6f-89e5-496bbb0317db';

  static String baseUrlForRegion(String region) {
    return switch (region.trim().toLowerCase()) {
      'ous' => 'https://shareous1.dexcom.com/ShareWebServices/Services',
      _ => 'https://share2.dexcom.com/ShareWebServices/Services',
    };
  }

  final String baseUrl;

  Uri uri(String path) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$base$path');
  }

  Future<String> postQuotedString(
    String path,
    Map<String, dynamic> body,
  ) async {
    final text = await _postRaw(path, body);
    return _decodeQuotedString(text);
  }

  Future<List<Map<String, dynamic>>> postJsonList(
    String path,
    Map<String, dynamic> body,
  ) async {
    final text = await _postRaw(path, body);
    final decoded = jsonDecode(text);
    if (decoded is! List) {
      throw DexcomException('Expected JSON array from Dexcom Share');
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<String> _postRaw(String path, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri(path));
      request.headers.set('accept', 'application/json');
      request.headers.set('content-type', 'application/json');
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        throw _errorFromResponse(response.statusCode, text);
      }
      return text;
    } on SocketException catch (e) {
      throw DexcomException('Network error: $e');
    } finally {
      client.close(force: true);
    }
  }

  DexcomException _errorFromResponse(int statusCode, String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['Code']?.toString() ?? 'HTTP$statusCode';
        final message = decoded['Message']?.toString() ?? text;
        return DexcomException('$code: $message');
      }
    } on Object {
      // Fall through to generic error.
    }
    return DexcomException('HTTP $statusCode: $text');
  }

  static String _decodeQuotedString(String body) {
    final trimmed = body.trim();
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return jsonDecode(trimmed) as String;
    }
    return trimmed.replaceAll('"', '');
  }
}
