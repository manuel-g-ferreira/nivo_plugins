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
      if (mapped == null) {
        continue;
      }
      final ts = DateTime.parse(mapped['timestamp'] as String);
      if (ts.isBefore(sinceUtc)) {
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
    final sgv = entry['sgv'];
    if (sgv is! num) {
      return null;
    }
    final timestamp = _parseTimestamp(entry);
    if (timestamp == null) {
      return null;
    }
    final special = _specialValue(sgv.toInt());
    return {
      'value': special == null ? sgv.round() : 0,
      'trend': _mapDirection(entry['direction']),
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

  static String? _specialValue(int sgv) {
    if (sgv <= 0) {
      return 'LO';
    }
    if (sgv >= 401) {
      return 'HI';
    }
    return null;
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

  static String _mapDirection(Object? direction) {
    final d = direction?.toString() ?? '';
    return switch (d) {
      'DoubleUp' => 'doubleUp',
      'SingleUp' => 'singleUp',
      'FortyUp' => 'fortyFiveUp',
      'Flat' => 'flat',
      'FortyDown' => 'fortyFiveDown',
      'SingleDown' => 'singleDown',
      'DoubleDown' => 'doubleDown',
      'NONE' || 'NOT COMPUTABLE' || 'NOT_COMPUTABLE' => 'notComputable',
      _ => 'notComputable',
    };
  }

  static String siteDisplayName(String baseUrl) {
    try {
      return Uri.parse(baseUrl).host;
    } on Object {
      return 'Nightscout';
    }
  }
}
