import 'package:nightscout_plugin/transport/nightscout_http.dart';

/// `GET /api/v1/entries.json` — CGM entries (sgv) only.
class EntriesEndpoint {
  const EntriesEndpoint(this._http);

  final NightscoutHttp _http;

  Future<List<Map<String, dynamic>>> fetchSince(DateTime sinceUtc) async {
    final ms = sinceUtc.toUtc().millisecondsSinceEpoch;
    final list = await _http.getJsonList(
      '/api/v1/entries.json?find[date][\$gte]=$ms&count=2000',
    );
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
  }

  Future<List<Map<String, dynamic>>> fetchLatest({int count = 1}) async {
    final list = await _http.getJsonList('/api/v1/entries.json?count=$count');
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) item,
    ];
  }
}
