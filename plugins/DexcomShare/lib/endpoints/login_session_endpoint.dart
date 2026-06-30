import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class LoginSessionEndpoint {
  const LoginSessionEndpoint(this._http);

  final DexcomHttp _http;

  Future<String> login({
    required String accountId,
    required String password,
  }) {
    return _http.postQuotedString(
      '/General/LoginPublisherAccountById',
      {
        'accountId': accountId,
        'password': password,
        'applicationId': _http.applicationId,
      },
    );
  }
}
