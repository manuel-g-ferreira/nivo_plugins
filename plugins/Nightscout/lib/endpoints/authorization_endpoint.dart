import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/transport/nightscout_http.dart';

/// `GET /api/v2/authorization/request/{token}` — JWT for readable access tokens.
class AuthorizationEndpoint {
  const AuthorizationEndpoint(this._http);

  final NightscoutHttp _http;

  Future<String> requestBearer(String accessToken) async {
    final encoded = Uri.encodeComponent(accessToken);
    final body = await _http.getJsonObject(
      '/api/v2/authorization/request/$encoded',
    );
    final token = body['token'] as String?;
    if (token == null || token.isEmpty) {
      throw NightscoutException('Nightscout did not return an authorization token');
    }
    return token;
  }
}
