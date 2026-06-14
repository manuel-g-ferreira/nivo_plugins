import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/endpoints/glucose_values_endpoint.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/transport/dexcom_http.dart';

class GlucoseService {
  GlucoseService(this._http, {required this.sessionId});

  final DexcomHttp _http;
  final String sessionId;

  Future<Map<String, dynamic>> currentReading({required int hours}) async {
    final snapshot = await fetchReadings(hours: hours);
    return snapshot.current;
  }

  Future<List<Map<String, dynamic>>> history({required int hours}) async {
    final snapshot = await fetchReadings(hours: hours);
    return snapshot.history;
  }

  Future<FetchReadingsResult> fetchReadings({required int hours}) async {
    final clamped = hours.clamp(1, 24);
    try {
      final entries = await GlucoseValuesEndpoint(_http).fetchLatest(
        sessionId: sessionId,
        minutes: clamped * 60,
      );
      return GlucoseMapper.snapshotFromEntries(entries, hours: clamped);
    } on DexcomException catch (e) {
      final message = e.message;
      if (message.contains('SessionIdNotFound') ||
          message.contains('SessionNotValid')) {
        throw DexcomException('Session expired — sign in again');
      }
      rethrow;
    }
  }
}

class FetchReadingsResult {
  const FetchReadingsResult({required this.current, required this.history});

  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> history;
}
