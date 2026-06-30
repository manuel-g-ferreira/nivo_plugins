import 'package:librelink_plugin/transport/llu_http.dart';

/// `GET /llu/connections` only.
class ConnectionsEndpoint {
  const ConnectionsEndpoint(this._http);

  final LluHttp _http;

  Future<List<Map<String, dynamic>>> list() async {
    final body = await _http.get('/llu/connections', authenticated: true);
    final list = body['data'];
    if (list is! List) {
      return [];
    }
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
  }
}
