import 'package:mock_cgm_plugin/mock_glucose.dart';

const pluginIdentifier = 'mockcgm';
const mockUserId = 'mock-user';
const mockToken = 'mock-token';
const mockDataSourceId = 'mock-sensor-1';
const mockDataSourceName = 'Mock Sensor';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> dispatch(Map<String, dynamic> request) {
    return switch (request['command'] as String?) {
      'getPluginInfo' => getPluginInfo(),
      'authenticate' => authenticate(),
      'getDataSources' => getDataSources(),
      'getCurrentReading' => getCurrentReading(),
      'getHistory' => getHistory(request),
      'fetchReadings' => fetchReadings(request),
      final command => {'success': false, 'error': 'Unknown command: $command'},
    };
  }

  static Map<String, dynamic> getPluginInfo() => {
    'success': true,
    'identifier': pluginIdentifier,
    'displayName': 'Mock CGM',
    'version': '1.0.0',
    'author': 'Nivo',
    'requiresLogin': false,
    'iconName': 'mock',
    'capabilities': {
      'supportsMultipleDataSources': false,
      'supportsHistory': true,
      'maxHistoryHours': MockGlucose.maxHistoryHours,
      'supportsSpecialValues': false,
      'requiresRegionSelection': false,
      'supportsCombinedFetch': true,
      'apiVersion': '1',
    },
  };

  static Map<String, dynamic> authenticate() => {
    'success': true,
    'authToken': mockToken,
    'userId': mockUserId,
    'defaultDataSourceId': mockDataSourceId,
  };

  static Map<String, dynamic> getDataSources() => {
    'success': true,
    'dataSources': [
      {'id': mockDataSourceId, 'name': mockDataSourceName},
    ],
  };

  static Map<String, dynamic> getCurrentReading() {
    final now = DateTime.now().toUtc();
    return {'success': true, ...MockGlucose.readingAt(now)};
  }

  static Map<String, dynamic> getHistory(Map<String, dynamic> request) {
    final hours = MockGlucose.parseHours(request['hours']);
    return {'success': true, 'readings': MockGlucose.historyReadings(hours)};
  }

  static Map<String, dynamic> fetchReadings(Map<String, dynamic> request) {
    final hours = MockGlucose.parseHours(request['hours']);
    final now = DateTime.now().toUtc();
    return {
      'success': true,
      'current': MockGlucose.readingAt(now),
      'history': MockGlucose.historyReadings(hours),
    };
  }
}
