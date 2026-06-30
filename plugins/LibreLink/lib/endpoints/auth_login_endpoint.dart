import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/transport/llu_http.dart';

/// `POST /llu/auth/login` only.
class AuthLoginEndpoint {
  const AuthLoginEndpoint(this._http);

  final LluHttp _http;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final body = await _http.post(
        '/llu/auth/login',
        {
          'email': email,
          'password': password,
        },
        authenticated: false);
    final status = body['status'];
    if (status == 2) {
      throw LluException('Invalid credentials');
    }
    if (status == 4) {
      throw LluException(
        'LibreLink requires an extra step in the mobile app (2FA or onboarding). '
        'Complete setup in LibreLink Up, then try again.',
      );
    }
    final data = body['data'];
    if (data is Map<String, dynamic> && data['redirect'] == true) {
      return data;
    }
    if (data is! Map<String, dynamic>) {
      throw LluException('Unexpected login response');
    }
    final ticket = data['authTicket'];
    if (ticket is! Map<String, dynamic>) {
      throw LluException('Missing auth ticket');
    }
    final token = ticket['token'] as String?;
    final user = data['user'];
    if (token == null || user is! Map<String, dynamic>) {
      throw LluException('Incomplete login payload');
    }
    _http.authToken = token;
    return data;
  }
}
