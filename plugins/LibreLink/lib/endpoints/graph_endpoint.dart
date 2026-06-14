import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/transport/llu_http.dart';

/// `GET /llu/connections/{patientId}/graph` only.
class GraphEndpoint {
  const GraphEndpoint(this._http);

  final LluHttp _http;

  Future<Map<String, dynamic>> fetch(String patientId) async {
    final body = await _http.get(
      '/llu/connections/$patientId/graph',
      authenticated: true,
    );
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw LluException('Graph response missing data');
    }
    return data;
  }
}
