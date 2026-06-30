import 'mock_scenario.dart';

/// Synthetic CGM readings for dev, CI, and alert/threshold testing.
abstract final class MockGlucose {
  static const historyIntervalMinutes = 5;
  static const maxHistoryHours = 24;
  static const minValue = 40;
  static const maxValue = 300;

  /// One full scenario loop (minutes).
  static const cycleDurationMinutes = 240;

  static const _cycleWaypoints = <(double minute, double mgdl)>[
    (0, 112),
    (30, 108),
    (50, 118),
    (70, 155),
    (85, 192),
    (95, 208),
    (110, 198),
    (125, 168),
    (140, 132),
    (155, 115),
    (170, 105),
    (185, 82),
    (200, 66),
    (212, 52),
    (225, 56),
    (235, 92),
    (240, 112),
  ];

  static int parseHours(Object? raw) {
    final hours = raw is int ? raw : int.tryParse('$raw') ?? 1;
    return hours.clamp(1, maxHistoryHours);
  }

  static MockScenario scenarioFromRequest(Map<String, dynamic> request) {
    final options = request['options'];
    if (options is Map) {
      final fromOptions = options['mockScenario'] ?? options['scenario'];
      if (fromOptions != null) {
        return MockScenario.parse('$fromOptions');
      }
    }
    return MockScenario.cycle;
  }

  static Map<String, dynamic> readingAt(
    DateTime time, {
    required MockScenario scenario,
  }) =>
      _readingMap(time, scenario);

  static List<Map<String, dynamic>> historyReadings(
    int hours, {
    required MockScenario scenario,
  }) {
    final now = DateTime.now().toUtc();
    final start = now.subtract(Duration(hours: hours));
    final alignedStart = DateTime.utc(
      start.year,
      start.month,
      start.day,
      start.hour,
      (start.minute ~/ historyIntervalMinutes) * historyIntervalMinutes,
    );

    final readings = <Map<String, dynamic>>[];
    var time = alignedStart;
    while (!time.isAfter(now)) {
      readings.add(_readingMap(time, scenario));
      time = time.add(const Duration(minutes: historyIntervalMinutes));
    }
    return readings;
  }

  static Map<String, dynamic> _readingMap(DateTime time, MockScenario scenario) {
    final utc = time.toUtc();
    final value = valueAt(utc, scenario: scenario);
    final prior = valueAt(
      utc.subtract(const Duration(minutes: historyIntervalMinutes)),
      scenario: scenario,
    );
    return {
      'value': value.round(),
      'trend': trendFor(value, prior),
      'timestamp': utc.toIso8601String(),
      'specialValue': null,
    };
  }

  static double valueAt(
    DateTime time, {
    required MockScenario scenario,
  }) {
    final base = switch (scenario) {
      MockScenario.cycle => _cycleValue(_minuteInCycle(time)),
      MockScenario.stable => 110,
      MockScenario.high => 195,
      MockScenario.low => 65,
      MockScenario.urgentLow => 52,
      MockScenario.urgentHigh => 265,
    };
    return (base + _noise(time)).clamp(minValue.toDouble(), maxValue.toDouble());
  }

  static double _minuteInCycle(DateTime time) {
    final totalMinutes = time.millisecondsSinceEpoch / 60000.0;
    return totalMinutes % cycleDurationMinutes;
  }

  static double _cycleValue(double minuteInCycle) {
    final points = _cycleWaypoints;
    for (var i = 0; i < points.length - 1; i++) {
      final (m0, v0) = points[i];
      final (m1, v1) = points[i + 1];
      if (minuteInCycle >= m0 && minuteInCycle <= m1) {
        final t = (minuteInCycle - m0) / (m1 - m0);
        return _lerp(v0, v1, _smoothStep(t));
      }
    }
    return points.last.$2;
  }

  static double _smoothStep(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Deterministic ±2 mg/dL sensor noise per 5-minute bucket.
  static double _noise(DateTime time) {
    final bucket = time.millisecondsSinceEpoch ~/ (historyIntervalMinutes * 60000);
    final hash = (bucket * 1103515245 + 12345) & 0x7fffffff;
    return (hash % 5) - 2;
  }

  static String trendFor(double current, double fiveMinutesAgo) {
    final rate = (current - fiveMinutesAgo) / historyIntervalMinutes;
    if (rate > 4) return 'doubleUp';
    if (rate > 2) return 'singleUp';
    if (rate > 0.6) return 'fortyFiveUp';
    if (rate > -0.6) return 'flat';
    if (rate > -2) return 'fortyFiveDown';
    if (rate > -4) return 'singleDown';
    return 'doubleDown';
  }

  /// Rough cycle position label for debugging in plugin info.
  static String cyclePhaseLabel(DateTime time) {
    final m = _minuteInCycle(time.toUtc());
    if (m < 50) return 'in-range baseline';
    if (m < 110) return 'rising to high';
    if (m < 140) return 'falling from high';
    if (m < 180) return 'in-range';
    if (m < 212) return 'falling to low';
    if (m < 225) return 'urgent low';
    return 'recovering';
  }
}
