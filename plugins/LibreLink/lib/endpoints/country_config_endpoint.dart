import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/transport/llu_http.dart';

/// `GET /llu/config/country?country=XX` only.
class CountryConfigEndpoint {
  const CountryConfigEndpoint(this._http);

  final LluHttp _http;

  Future<String> resolveRegionalBase(String region) async {
    final countryCode = region.length >= 2
        ? region.substring(0, 2).toUpperCase()
        : region.toUpperCase();
    final config = await _http.get(
      '/llu/config/country?country=$countryCode',
      authenticated: false,
    );
    final regionalMap = config['data']?['regionalMap'];
    if (regionalMap is! Map<String, dynamic>) {
      throw LluException('Country config missing regionalMap');
    }
    final entry = regionalMap[region] ?? regionalMap[region.toLowerCase()];
    if (entry is! Map<String, dynamic>) {
      throw LluException('Unknown region: $region');
    }
    final lslApi = entry['lslApi'] as String?;
    if (lslApi == null || lslApi.isEmpty) {
      throw LluException('Regional API URL missing for $region');
    }
    return lslApi;
  }
}
