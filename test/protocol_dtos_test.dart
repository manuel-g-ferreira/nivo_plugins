import 'package:nivo_plugins/protocol_dtos.dart';
import 'package:test/test.dart';

void main() {
  group('AuthResult', () {
    test('toAuthenticateResponse omits null defaultDataSourceId', () {
      final response = AuthResult(
        authToken: 'tok',
        userId: 'uid',
        sessionOptions: const {'region': 'us'},
      ).toAuthenticateResponse();

      expect(response, {
        'success': true,
        'authToken': 'tok',
        'userId': 'uid',
        'sessionOptions': {'region': 'us'},
      });
      expect(response.containsKey('defaultDataSourceId'), isFalse);
    });

    test('toAuthenticateResponse includes defaultDataSourceId when set', () {
      final response = AuthResult(
        authToken: 'tok',
        userId: 'uid',
        defaultDataSourceId: 'patient-1',
        sessionOptions: const {},
      ).toAuthenticateResponse();

      expect(response['defaultDataSourceId'], 'patient-1');
    });
  });

  group('FetchReadingsResult', () {
    test('toFetchReadingsResponse wraps current and history', () {
      final reading = {
        'value': 100,
        'trend': 'flat',
        'timestamp': '2026-01-01T00:00:00.000Z',
        'specialValue': null,
      };
      final response = FetchReadingsResult(
        current: reading,
        history: [reading],
      ).toFetchReadingsResponse();

      expect(response['success'], true);
      expect(response['current'], reading);
      expect(response['history'], [reading]);
    });
  });
}
