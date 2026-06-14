import 'package:nightscout_plugin/endpoints/entries_endpoint.dart';
import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/transport/nightscout_http.dart';

class EntriesService {
  EntriesService(this._http);

  final NightscoutHttp _http;

  Future<Map<String, dynamic>> currentReading() async {
    final entries = await EntriesEndpoint(_http).fetchLatest(count: 32);
    final sgv = EntryMapper.filterSgv(entries);
    if (sgv.isEmpty) {
      throw NightscoutException('No glucose entries on Nightscout site');
    }
    sgv.sort((a, b) {
      final ad = a['date'] as num? ?? 0;
      final bd = b['date'] as num? ?? 0;
      return ad.compareTo(bd);
    });
    final reading = EntryMapper.toProtocolReading(sgv.last);
    if (reading == null) {
      throw NightscoutException('No valid glucose entry');
    }
    return reading;
  }

  Future<List<Map<String, dynamic>>> history({required int hours}) async {
    final clamped = hours.clamp(1, 24);
    final since = DateTime.now().toUtc().subtract(Duration(hours: clamped));
    final raw = await EntriesEndpoint(_http).fetchSince(since);
    return EntryMapper.toProtocolReadings(raw, sinceUtc: since);
  }

  Future<FetchReadingsResult> fetchReadings({required int hours}) async {
    final clamped = hours.clamp(1, 24);
    final since = DateTime.now().toUtc().subtract(Duration(hours: clamped));
    final raw = await EntriesEndpoint(_http).fetchSince(since);
    final history = EntryMapper.toProtocolReadings(raw, sinceUtc: since);
    if (history.isEmpty) {
      throw NightscoutException(
        'No glucose entries in the last $clamped hours',
      );
    }
    return FetchReadingsResult(current: history.last, history: history);
  }
}

class FetchReadingsResult {
  const FetchReadingsResult({required this.current, required this.history});

  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> history;
}
