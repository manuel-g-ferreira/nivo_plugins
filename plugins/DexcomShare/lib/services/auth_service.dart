import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/endpoints/authenticate_account_endpoint.dart';
import 'package:dexcomshare_plugin/endpoints/login_session_endpoint.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/session_factory.dart';
import 'package:dexcomshare_plugin/transport/dexcom_http.dart';
import 'package:nivo_plugins/protocol_dtos.dart';

class AuthService {
  AuthService(this._http);

  final DexcomHttp _http;

  Future<AuthResult> authenticate({
    required String email,
    required String password,
  }) async {
    final accountName = email.trim();
    if (accountName.isEmpty || password.isEmpty) {
      throw DexcomException('Email and password required');
    }

    final accountId = await AuthenticateAccountEndpoint(
      _http,
    ).authenticate(accountName: accountName, password: password);
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
