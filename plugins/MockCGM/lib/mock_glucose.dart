import 'dart:math';

/// Synthetic sine-wave glucose for dev and CI.
abstract final class MockGlucose {
  static const baseline = 110.0;
  static const amplitude = 35.0;
  static const periodMinutes = 30.0;
  static const minValue = 50;
  static const maxValue = 280;
  static const historyIntervalMinutes = 5;
  static const maxHistoryHours = 24;

  static int parseHours(Object? raw) {
    final hours = raw is int ? raw : int.tryParse('$raw') ?? 1;
    return hours.clamp(1, maxHistoryHours);
  }

  static Map<String, dynamic> readingAt(DateTime time) => {
    'value': valueAt(time).round(),
    'trend': trendAt(time),
    'timestamp': time.toUtc().toIso8601String(),
    'specialValue': null,
  };

  static List<Map<String, dynamic>> historyReadings(int hours) {
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
      readings.add(readingAt(time));
      time = time.add(const Duration(minutes: historyIntervalMinutes));
    }
    return readings;
  }

  static double valueAt(DateTime time) {
    final phase =
        2 * pi * time.millisecondsSinceEpoch / (periodMinutes * 60 * 1000);
    final raw = baseline + amplitude * sin(phase);
    return raw.clamp(minValue.toDouble(), maxValue.toDouble());
  }

  static double ratePerMinuteAt(DateTime time) {
    final phase =
        2 * pi * time.millisecondsSinceEpoch / (periodMinutes * 60 * 1000);
    final omega = 2 * pi / periodMinutes;
    return amplitude * omega * cos(phase);
  }

  static String trendAt(DateTime time) {
    final rate = ratePerMinuteAt(time);
    if (rate > 4) return 'doubleUp';
    if (rate > 2) return 'singleUp';
    if (rate > 0.6) return 'fortyFiveUp';
    if (rate > -0.6) return 'flat';
    if (rate > -2) return 'fortyFiveDown';
    if (rate > -4) return 'singleDown';
    return 'doubleDown';
  }
}
