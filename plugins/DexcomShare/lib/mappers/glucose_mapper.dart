import 'package:dexcomshare_plugin/services/glucose_service.dart';

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
      final ts = DateTime.parse(mapped['timestamp'] as String);
      if (ts.isBefore(cutoff)) {
        continue;
      }
      readings.add(mapped);
    }
    readings.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return readings;
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
    final special = _specialValue(valueRaw.toInt());
    return {
      'value': special == null ? valueRaw.round() : 0,
      'trend': _mapTrend(entry['Trend']?.toString()),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'specialValue': special,
    };
  }

  static String? _specialValue(int value) {
    if (value <= 39) {
      return 'LO';
    }
    if (value >= 401) {
      return 'HI';
    }
    return null;
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

  static String _mapTrend(String? trend) {
    return switch (trend?.trim()) {
      'DoubleUp' => 'doubleUp',
      'SingleUp' => 'singleUp',
      'FortyFiveUp' => 'fortyFiveUp',
      'Flat' => 'flat',
      'FortyFiveDown' => 'fortyFiveDown',
      'SingleDown' => 'singleDown',
      'DoubleDown' => 'doubleDown',
      '' || null => 'notComputable',
      _ => 'notComputable',
    };
  }
}
