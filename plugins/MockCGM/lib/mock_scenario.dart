/// Test glucose patterns for [MockGlucose].
enum MockScenario {
  /// Repeating ~4 h curve through in-range, high, low, and urgent low.
  cycle,

  /// Steady in-range (~110 mg/dL).
  stable,

  /// Sustained high (~195 mg/dL).
  high,

  /// Sustained low (~65 mg/dL).
  low,

  /// Sustained urgent low (~52 mg/dL).
  urgentLow,

  /// Sustained urgent high (~265 mg/dL).
  urgentHigh;

  static MockScenario parse(String? raw) {
    final key = (raw ?? '').trim().toLowerCase().replaceAll('-', '_');
    return switch (key) {
      '' || 'cycle' || 'default' || 'demo' => MockScenario.cycle,
      'stable' || 'flat' || 'inrange' || 'in_range' => MockScenario.stable,
      'high' => MockScenario.high,
      'low' => MockScenario.low,
      'urgentlow' || 'urgent_low' || 'urgent' => MockScenario.urgentLow,
      'urgenthigh' || 'urgent_high' => MockScenario.urgentHigh,
      _ => MockScenario.cycle,
    };
  }

  String get sessionValue => name;

  String get displayLabel => switch (this) {
    MockScenario.cycle => 'Full cycle (highs & lows)',
    MockScenario.stable => 'Stable in range',
    MockScenario.high => 'Sustained high',
    MockScenario.low => 'Sustained low',
    MockScenario.urgentLow => 'Sustained urgent low',
    MockScenario.urgentHigh => 'Sustained urgent high',
  };
}
