import 'package:nivo_plugins/protocol_reading.dart';

/// Nightscout entry documents → Nivo protocol readings.
abstract final class EntryMapper {
  static const defaultDataSourceId = 'default';

  static List<Map<String, dynamic>> filterSgv(
    Iterable<Map<String, dynamic>> entries,
  ) {
    return [
      for (final entry in entries)
        if (_isSgv(entry)) entry,
    ];
  }

  static List<Map<String, dynamic>> toProtocolReadings(
    List<Map<String, dynamic>> entries, {
    required DateTime sinceUtc,
  }) {
    final readings = <Map<String, dynamic>>[];
    for (final entry in filterSgv(entries)) {
      final mapped = toProtocolReading(entry);
      if (mapped != null) {
        readings.add(mapped);
      }
    }
    return ProtocolReading.filterSince(readings, sinceUtc);
  }

  static Map<String, dynamic>? toProtocolReading(Map<String, dynamic> entry) {
    final sgv = entry['sgv'];
    if (sgv is! num) {
      return null;
    }
    final timestamp = _parseTimestamp(entry);
    if (timestamp == null) {
      return null;
    }
    final special = ProtocolReading.specialValueFromMgdl(sgv.toInt(), lo: 0);
    return {
      'value': special == null ? sgv.round() : 0,
      'trend': ProtocolReading.mapNightscoutDirection(entry['direction']),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'specialValue': special,
    };
  }

  static bool _isSgv(Map<String, dynamic> entry) {
    final type = entry['type'];
    if (type == 'sgv') {
      return true;
    }
    return entry['sgv'] is num;
  }

  static DateTime? _parseTimestamp(Map<String, dynamic> entry) {
    final date = entry['date'];
    if (date is num) {
      return DateTime.fromMillisecondsSinceEpoch(date.toInt(), isUtc: true);
    }
    final dateString = entry['dateString'];
    if (dateString is String && dateString.isNotEmpty) {
      try {
        return DateTime.parse(dateString).toUtc();
      } on Object {
        return null;
      }
    }
    return null;
  }

  static String siteDisplayName(String baseUrl) {
    try {
      return Uri.parse(baseUrl).host;
    } on Object {
      return 'Nightscout';
    }
  }
}
