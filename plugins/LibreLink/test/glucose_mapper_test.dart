import 'package:librelink_plugin/glucose_mapper.dart';
import 'package:test/test.dart';

String _factoryTimestamp(DateTime utc) {
  final hour = utc.hour % 12 == 0 ? 12 : utc.hour % 12;
  final ampm = utc.hour >= 12 ? 'PM' : 'AM';
  return '${utc.month}/${utc.day}/${utc.year} '
      '$hour:${utc.minute.toString().padLeft(2, '0')}:'
      '${utc.second.toString().padLeft(2, '0')} $ampm';
}

void main() {
  test('maps live LibreLink glucoseMeasurement sample', () {
    final reading = GlucoseMapper.toProtocolReading({
      'FactoryTimestamp': '6/14/2026 6:13:13 PM',
      'Timestamp': '6/14/2026 7:13:13 PM',
      'type': 1,
      'ValueInMgPerDl': 229,
      'TrendArrow': 3,
      'isHigh': false,
      'isLow': false,
    });

    expect(reading, isNotNull);
    expect(reading!['value'], 229);
    expect(reading['specialValue'], isNull);
    expect(reading['trend'], 'flat');
    expect(reading['timestamp'], isNotEmpty);
  });

  test('maps graphData history points', () {
    final graphTime = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
    final history = GlucoseMapper.historyFromGraph(
      {
        'graphData': [
          {
            'FactoryTimestamp': _factoryTimestamp(graphTime),
            'Timestamp': _factoryTimestamp(graphTime),
            'type': 0,
            'ValueInMgPerDl': 260,
            'isHigh': false,
            'isLow': false,
          },
        ],
      },
      hours: 3,
    );

    expect(history, hasLength(1));
    expect(history.first['value'], 260);
  });
}
