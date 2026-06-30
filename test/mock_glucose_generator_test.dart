import '../plugins/MockCGM/lib/mock_glucose.dart';
import '../plugins/MockCGM/lib/mock_scenario.dart';
import 'package:test/test.dart';

DateTime _atCycleMinute(double minute) =>
    DateTime.fromMillisecondsSinceEpoch((minute * 60000).round(), isUtc: true);

void main() {
  test('cycle reaches high and urgent low zones', () {
    final high = MockGlucose.valueAt(
      _atCycleMinute(95),
      scenario: MockScenario.cycle,
    );
    final urgentLow = MockGlucose.valueAt(
      _atCycleMinute(212),
      scenario: MockScenario.cycle,
    );
    final baseline = MockGlucose.valueAt(
      _atCycleMinute(30),
      scenario: MockScenario.cycle,
    );

    expect(high, greaterThan(180));
    expect(urgentLow, lessThan(55));
    expect(baseline, inInclusiveRange(90, 130));
  });

  test('fixed scenarios stay in expected bands', () {
    final now = DateTime.now().toUtc();
    expect(
      MockGlucose.valueAt(now, scenario: MockScenario.high),
      inInclusiveRange(190, 200),
    );
    expect(
      MockGlucose.valueAt(now, scenario: MockScenario.low),
      inInclusiveRange(60, 70),
    );
    expect(
      MockGlucose.valueAt(now, scenario: MockScenario.urgentLow),
      inInclusiveRange(48, 56),
    );
    expect(
      MockGlucose.valueAt(now, scenario: MockScenario.urgentHigh),
      inInclusiveRange(260, 270),
    );
  });

  test('scenario parses sign-in username aliases', () {
    expect(MockScenario.parse('high'), MockScenario.high);
    expect(MockScenario.parse('urgent_low'), MockScenario.urgentLow);
    expect(MockScenario.parse('urgentLow'), MockScenario.urgentLow);
    expect(MockScenario.parse(null), MockScenario.cycle);
  });

  test('history uses 5-minute spacing', () {
    final readings = MockGlucose.historyReadings(
      1,
      scenario: MockScenario.stable,
    );
    expect(readings.length, greaterThan(6));
    final first = DateTime.parse(readings.first['timestamp'] as String);
    final second = DateTime.parse(readings[1]['timestamp'] as String);
    expect(second.difference(first).inMinutes, 5);
  });
}
