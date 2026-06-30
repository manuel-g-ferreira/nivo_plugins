import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/endpoints/glucose_values_endpoint.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/transport/dexcom_http.dart';
import 'package:nivo_plugins/protocol_dtos.dart';
import 'package:nivo_plugins/protocol_reading.dart';

class GlucoseService {
  GlucoseService(this._http, {required this.sessionId});

  final DexcomHttp _http;
  final String sessionId;
  _CachedFetch? _cache;
  static const _cacheTtl = Duration(seconds: 30);

  Future<Map<String, dynamic>> currentReading({required int hours}) async {
    final snapshot = await fetchReadings(hours: hours);
    return snapshot.current;
  }

  Future<List<Map<String, dynamic>>> history({required int hours}) async {
    final snapshot = await fetchReadings(hours: hours);
    return snapshot.history;
  }

  Future<FetchReadingsResult> fetchReadings({
    required int hours,
    DateTime? historySince,
  }) async {
    final clamped = hours.clamp(1, 24);
    final now = DateTime.now();
    final cached = _cache;
    if (cached != null &&
        cached.hours == clamped &&
        historySince == null &&
        now.difference(cached.fetchedAt) < _cacheTtl) {
      return cached.result;
    }
    try {
      final minutes = historySince == null
          ? clamped * 60
          : now.difference(historySince).inMinutes.clamp(5, clamped * 60);
      final entries = await GlucoseValuesEndpoint(_http).fetchLatest(
        sessionId: sessionId,
        minutes: minutes,
      );
      var result = GlucoseMapper.snapshotFromEntries(entries, hours: clamped);
      if (historySince != null) {
        result = FetchReadingsResult(
          current: result.current,
          history: ProtocolReading.filterStrictlyAfter(
            result.history,
            historySince,
          ),
        );
      }
      if (historySince == null) {
        _cache = _CachedFetch(result: result, hours: clamped, fetchedAt: now);
      }
      return result;
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

class _CachedFetch {
  const _CachedFetch({
    required this.result,
    required this.hours,
    required this.fetchedAt,
  });

  final FetchReadingsResult result;
  final int hours;
  final DateTime fetchedAt;
}
