import 'package:mock_cgm_plugin/mock_glucose.dart';
import 'package:mock_cgm_plugin/mock_scenario.dart';
import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/protocol_dtos.dart';
import 'package:nivo_plugins/protocol_helpers.dart';
import 'package:nivo_plugins/protocol_reading.dart';

const pluginIdentifier = 'mockcgm';
const mockUserId = 'mock-user';
const mockToken = 'mock-token';
const mockDataSourceId = 'mock-sensor-1';
const mockDataSourceName = 'Mock Sensor';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> dispatch(Map<String, dynamic> request) {
    return switch (request['command'] as String?) {
      'getPluginInfo' => getPluginInfo(),
      'authenticate' => authenticate(request),
      'getDataSources' => getDataSources(),
      'getCurrentReading' => getCurrentReading(request),
      'getHistory' => getHistory(request),
      'fetchReadings' => fetchReadings(request),
      final command => {'success': false, 'error': 'Unknown command: $command'},
    };
  }

  static Map<String, dynamic> getPluginInfo() => {
    'success': true,
    'identifier': PluginManifest.runtimeIdentifier(fallback: pluginIdentifier),
    'displayName': PluginManifest.runtimeDisplayName(fallback: 'Mock CGM'),
    'version': PluginManifest.runtimeVersion(fallback: '1.0.0'),
    'author': PluginManifest.runtimeAuthor(fallback: 'Nivo'),
    'requiresLogin': false,
    'iconName': 'mock',
    'signIn': {
      'hint':
          'Pick a glucose pattern to test alerts and range colors. Password can be anything.',
      'fields': [
        {
          'key': 'username',
          'type': 'select',
          'label': 'Scenario',
          'options': [
            for (final scenario in MockScenario.values)
              {'value': scenario.name, 'label': scenario.displayLabel},
          ],
        },
        {
          'key': 'password',
          'type': 'secret',
          'label': 'Password (any)',
        },
      ],
    },
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

  static Map<String, dynamic> authenticate(Map<String, dynamic> request) {
    final scenario = MockScenario.parse(request['username'] as String?);
    return AuthResult(
      authToken: mockToken,
      userId: mockUserId,
      defaultDataSourceId: mockDataSourceId,
      sessionOptions: {'mockScenario': scenario.sessionValue},
    ).toAuthenticateResponse();
  }

  static Map<String, dynamic> getDataSources() => {
    'success': true,
    'dataSources': [
      {'id': mockDataSourceId, 'name': mockDataSourceName},
    ],
  };

  static Map<String, dynamic> getCurrentReading(Map<String, dynamic> request) {
    final scenario = MockGlucose.scenarioFromRequest(request);
    final now = DateTime.now().toUtc();
    return {'success': true, ...MockGlucose.readingAt(now, scenario: scenario)};
  }

  static Map<String, dynamic> getHistory(Map<String, dynamic> request) {
    final scenario = MockGlucose.scenarioFromRequest(request);
    final hours = MockGlucose.parseHours(request['hours']);
    return {
      'success': true,
      'readings': MockGlucose.historyReadings(hours, scenario: scenario),
    };
  }

  static Map<String, dynamic> fetchReadings(Map<String, dynamic> request) {
    final scenario = MockGlucose.scenarioFromRequest(request);
    final hours = MockGlucose.parseHours(request['hours']);
    final now = DateTime.now().toUtc();
    var history = MockGlucose.historyReadings(hours, scenario: scenario);
    final historySince = ProtocolHelpers.historySince(request);
    if (historySince != null) {
      history = ProtocolReading.filterStrictlyAfter(history, historySince);
    }
    return FetchReadingsResult(
      current: MockGlucose.readingAt(now, scenario: scenario),
      history: history,
    ).toFetchReadingsResponse();
  }
}
