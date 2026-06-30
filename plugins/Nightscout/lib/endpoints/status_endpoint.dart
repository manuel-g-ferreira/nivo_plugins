import 'package:nightscout_plugin/transport/nightscout_http.dart';

/// `GET /api/v1/status.json` — site reachability and auth check.
class StatusEndpoint {
  const StatusEndpoint(this._http);

  final NightscoutHttp _http;

  Future<Map<String, dynamic>> fetch() async {
    return _http.getJsonObject('/api/v1/status.json');
  }
}
