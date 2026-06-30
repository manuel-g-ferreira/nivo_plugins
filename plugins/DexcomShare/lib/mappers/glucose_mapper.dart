import 'package:nivo_plugins/protocol_dtos.dart';
import 'package:nivo_plugins/protocol_reading.dart';

/// Maps Dexcom Share glucose JSON to Nivo plugin protocol fields.
abstract final class GlucoseMapper {
  static const defaultDataSourceId = 'default';

  static FetchReadingsResult snapshotFromEntries(
    List<Map<String, dynamic>> entries, {
    required int hours,
  }) {
    final readings = toProtocolReadings(entries, hours: hours);
    if (readings.isEmpty) {
      throw StateError('No glucose readings from Dexcom');
    }
    return FetchReadingsResult(
      current: readings.last,
      history: readings,
    );
  }

  static List<Map<String, dynamic>> toProtocolReadings(
    List<Map<String, dynamic>> entries, {
    required int hours,
  }) {
    final clampedHours = hours.clamp(1, 24);
    final cutoff = DateTime.now().toUtc().subtract(
      Duration(hours: clampedHours),
    );
    final readings = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final mapped = toProtocolReading(entry);
      if (mapped == null) {
        continue;
      }
      readings.add(mapped);
    }
    return ProtocolReading.filterSince(readings, cutoff);
  }

  static Map<String, dynamic>? toProtocolReading(Map<String, dynamic> entry) {
    final timestamp = _parseTimestamp(entry['WT']);
    if (timestamp == null) {
      return null;
    }
    final valueRaw = entry['Value'];
    if (valueRaw is! num) {
      return null;
    }
    final special = ProtocolReading.specialValueFromMgdl(valueRaw.toInt());
    return {
      'value': special == null ? valueRaw.round() : 0,
      'trend': ProtocolReading.mapDexcomTrend(entry['Trend']?.toString()),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'specialValue': special,
    };
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    var text = raw.trim();
    if (text.startsWith('Date(') && text.endsWith(')')) {
      text = text.substring(5, text.length - 1);
    }
    final ms = num.tryParse(text);
    if (ms == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);
  }
}
