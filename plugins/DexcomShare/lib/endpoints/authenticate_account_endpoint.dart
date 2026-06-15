import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class AuthenticateAccountEndpoint {
  const AuthenticateAccountEndpoint(this._http);

  final DexcomHttp _http;

  Future<String> authenticate({
    required String accountName,
    required String password,
  }) {
    return _http.postQuotedString(
      '/General/AuthenticatePublisherAccount',
      {
        'accountName': accountName,
        'password': password,
        'applicationId': _http.applicationId,
      },
    );
  }
}
