import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class GlucoseValuesEndpoint {
  const GlucoseValuesEndpoint(this._http);

  final DexcomHttp _http;

  Future<List<Map<String, dynamic>>> fetchLatest({
    required String sessionId,
    required int minutes,
    int maxCount = 288,
  }) {
    return _http.postJsonListWithQuery(
      '/Publisher/ReadPublisherLatestGlucoseValues',
      {
        'sessionId': sessionId,
        'minutes': minutes.toString(),
        'maxCount': maxCount.toString(),
      },
    );
  }
}
