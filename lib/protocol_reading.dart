/// Shared glucose reading normalization for vendor mappers.
abstract final class ProtocolReading {
  static String? specialValueFromMgdl(
    int mgdl, {
    int lo = 39,
    int hi = 401,
  }) {
    if (mgdl <= lo) {
      return 'LO';
    }
    if (mgdl >= hi) {
      return 'HI';
    }
    return null;
  }

  static String mapDexcomTrend(String? trend) {
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

  static String mapNightscoutDirection(Object? direction) {
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

  static List<Map<String, dynamic>> filterSince(
    Iterable<Map<String, dynamic>> readings,
    DateTime sinceUtc,
  ) {
    final filtered = <Map<String, dynamic>>[];
    for (final reading in readings) {
      final ts = DateTime.parse(reading['timestamp'] as String);
      if (ts.isBefore(sinceUtc)) {
        continue;
      }
      filtered.add(reading);
    }
    filtered.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return filtered;
  }

  /// Readings strictly after [afterUtc] (delta fetch responses).
  static List<Map<String, dynamic>> filterStrictlyAfter(
    Iterable<Map<String, dynamic>> readings,
    DateTime afterUtc,
  ) {
    final filtered = <Map<String, dynamic>>[];
    for (final reading in readings) {
      final ts = DateTime.parse(reading['timestamp'] as String).toUtc();
      if (!ts.isAfter(afterUtc)) {
        continue;
      }
      filtered.add(reading);
    }
    filtered.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return filtered;
  }
}
