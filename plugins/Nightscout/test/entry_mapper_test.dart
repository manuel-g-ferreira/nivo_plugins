import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:test/test.dart';

void main() {
  group('EntryMapper', () {
    test('maps sgv with Nightscout direction', () {
      final reading = EntryMapper.toProtocolReading({
        'sgv': 120,
        'direction': 'Flat',
        'date': 1700000000000,
      });
      expect(reading, isNotNull);
      expect(reading!['value'], 120);
      expect(reading['trend'], 'flat');
      expect(reading['specialValue'], isNull);
    });

    test('maps LO for zero sgv', () {
      final reading = EntryMapper.toProtocolReading({
        'sgv': 0,
        'direction': 'Flat',
        'date': 1700000000000,
      });
      expect(reading, isNotNull);
      expect(reading!['specialValue'], 'LO');
    });
  });
}
