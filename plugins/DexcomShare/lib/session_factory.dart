import 'package:dexcomshare_plugin/services/auth_service.dart';
import 'package:dexcomshare_plugin/services/glucose_service.dart';
import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class SessionFactory {
  static Map<String, String> optionsMap(Object? raw) {
    if (raw is! Map) {
      return {};
    }
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static DexcomHttp httpFromOptions(Map<String, String> options) {
    final region = options['region']?.trim().toLowerCase() ?? 'us';
    return DexcomHttp.forRegion(region);
  }

  static String regionFromHttp(DexcomHttp http) {
    if (http.baseUrl.contains('share.dexcom.jp')) {
      return 'jp';
    }
    if (http.baseUrl.contains('shareous1')) {
      return 'ous';
    }
    return 'us';
  }

  static DexcomHttp? httpFromRequest(Map<String, dynamic> request) {
    final options = optionsMap(request['options']);
    final region = options['region']?.trim();
    if (region == null || region.isEmpty) {
      return null;
    }
    return httpFromOptions(options);
  }

  static GlucoseService? glucoseServiceFromRequest(
      Map<String, dynamic> request) {
    final http = httpFromRequest(request);
    final sessionId = request['authToken'] as String? ??
        optionsMap(request['options'])['sessionId'];
    if (http == null || sessionId == null || sessionId.isEmpty) {
      return null;
    }
    return GlucoseService(http, sessionId: sessionId);
  }
}
