import 'dart:convert';
import 'dart:io';

import 'package:dexcomshare_plugin/dexcom_exception.dart';

/// HTTP client for Dexcom Share (unofficial REST API).
class DexcomHttp {
  DexcomHttp({required this.baseUrl, required this.applicationId});

  static const defaultUuid = '00000000-0000-0000-0000-000000000000';

  static const usApplicationId = 'd89443d2-327c-4a6f-89e5-496bbb0317db';
  static const jpApplicationId = 'd8665ade-9673-4e27-9ff6-92db4ce13d13';

  static String applicationIdForRegion(String region) {
    return switch (region.trim().toLowerCase()) {
      'jp' => jpApplicationId,
      _ => usApplicationId,
    };
  }

  static String baseUrlForRegion(String region) {
    return switch (region.trim().toLowerCase()) {
      'ous' => 'https://shareous1.dexcom.com/ShareWebServices/Services',
      'jp' => 'https://share.dexcom.jp/ShareWebServices/Services',
      _ => 'https://share2.dexcom.com/ShareWebServices/Services',
    };
  }

  static DexcomHttp forRegion(String region) {
    final normalized = region.trim().toLowerCase();
    return DexcomHttp(
      baseUrl: baseUrlForRegion(normalized),
      applicationId: applicationIdForRegion(normalized),
    );
  }

  final String baseUrl;
  final String applicationId;

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
    final text = await _postRaw(path, body: body);
    final decoded = _decodeQuotedString(text);
    _rejectDefaultUuid(decoded, 'login response');
    return decoded;
  }

  Future<List<Map<String, dynamic>>> postJsonList(
    String path,
    Map<String, dynamic> body,
  ) async {
    final text = await _postRaw(path, body: body);
    return _decodeJsonList(text);
  }

  /// Matches pydexcom / DiaKEM: POST with `{}` body and query parameters.
  Future<List<Map<String, dynamic>>> postJsonListWithQuery(
    String path,
    Map<String, String> query,
  ) async {
    final text = await _postRaw(path, query: query, body: const {});
    return _decodeJsonList(text);
  }

  List<Map<String, dynamic>> _decodeJsonList(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(trimmed);
    if (decoded is! List) {
      throw DexcomException('Expected JSON array from Dexcom Share');
    }
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<String> _postRaw(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final client = HttpClient();
    try {
      var target = uri(path);
      if (query != null && query.isNotEmpty) {
        target = target.replace(queryParameters: query);
      }
      final request = await client.postUrl(target);
      request.headers.set('accept', 'application/json');
      request.headers.set('content-type', 'application/json');
      request.write(jsonEncode(body ?? const {}));
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

  static void _rejectDefaultUuid(String value, String label) {
    if (value.trim().toLowerCase() == defaultUuid) {
      throw DexcomException('Dexcom rejected login ($label)');
    }
  }
}
