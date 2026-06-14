import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/endpoints/authenticate_account_endpoint.dart';
import 'package:dexcomshare_plugin/endpoints/login_session_endpoint.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/session_factory.dart';
import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class AuthService {
  AuthService(this._http);

  final DexcomHttp _http;

  Future<AuthResult> authenticate({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      throw DexcomException('Email and password required');
    }

    final accountId = await AuthenticateAccountEndpoint(
      _http,
    ).authenticate(accountName: email, password: password);
    if (accountId.isEmpty) {
      throw DexcomException('Dexcom did not return an account ID');
    }

    final sessionId = await LoginSessionEndpoint(
      _http,
    ).login(accountId: accountId, password: password);
    if (sessionId.isEmpty) {
      throw DexcomException('Dexcom did not return a session ID');
    }

    return AuthResult(
      authToken: sessionId,
      userId: accountId,
      defaultDataSourceId: GlucoseMapper.defaultDataSourceId,
      sessionOptions: {
        'region': SessionFactory.regionFromHttp(_http),
        'accountId': accountId,
        'sessionId': sessionId,
      },
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.authToken,
    required this.userId,
    required this.defaultDataSourceId,
    required this.sessionOptions,
  });

  final String authToken;
  final String userId;
  final String defaultDataSourceId;
  final Map<String, String> sessionOptions;
}
