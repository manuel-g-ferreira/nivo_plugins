import 'package:nightscout_plugin/transport/nightscout_http.dart';

/// `GET /api/v1/entries.json` — CGM entries (sgv) only.
class EntriesEndpoint {
  const EntriesEndpoint(this._http);

  final NightscoutHttp _http;

  Future<List<Map<String, dynamic>>> fetchSince(DateTime sinceUtc) async {
    final ms = sinceUtc.toUtc().millisecondsSinceEpoch;
    if (_http.bearerToken != null && _http.bearerToken!.isNotEmpty) {
      final list = await _http.getJsonList(
        '/api/v3/entries?sort\$desc=date&fields=sgv,trend,direction,date,identifier&limit=2000&find[date][\$gte]=$ms',
      );
      return _normalizeV3Entries(list);
    }
    final list = await _http.getJsonList(
      '/api/v1/entries.json?find[date][\$gte]=$ms&count=2000',
    );
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<List<Map<String, dynamic>>> fetchLatest({int count = 1}) async {
    if (_http.bearerToken != null && _http.bearerToken!.isNotEmpty) {
      final list = await _http.getJsonList(
        '/api/v3/entries?sort\$desc=date&fields=sgv,trend,direction,date,identifier&limit=$count',
      );
      return _normalizeV3Entries(list);
    }
    final list = await _http.getJsonList('/api/v1/entries.json?count=$count');
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
  }

  List<Map<String, dynamic>> _normalizeV3Entries(List<dynamic> list) {
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          {
            'sgv': item['sgv'],
            'date': item['date'],
            'direction': item['direction'] ?? item['trend'],
          },
    ];
  }
}
