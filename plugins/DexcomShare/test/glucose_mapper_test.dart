import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:test/test.dart';

void main() {
  test('maps Dexcom Share entry to protocol reading', () {
    final reading = GlucoseMapper.toProtocolReading({
      'WT': 'Date(1710000000000)',
      'Value': 120,
      'Trend': 'Flat',
    });
    expect(reading, isNotNull);
    expect(reading!['value'], 120);
    expect(reading['trend'], 'flat');
    expect(reading['specialValue'], isNull);
  });

  test('maps low and high special values', () {
    expect(
      GlucoseMapper.toProtocolReading({
        'WT': 'Date(1710000000000)',
        'Value': 39,
        'Trend': 'Flat',
      })!['specialValue'],
      'LO',
    );
    expect(
      GlucoseMapper.toProtocolReading({
        'WT': 'Date(1710000000000)',
        'Value': 401,
        'Trend': 'Flat',
      })!['specialValue'],
      'HI',
    );
  });
}
