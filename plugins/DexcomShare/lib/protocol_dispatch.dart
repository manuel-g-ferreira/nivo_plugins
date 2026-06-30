import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/services/auth_service.dart';
import 'package:dexcomshare_plugin/session_factory.dart';
import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/protocol_helpers.dart';

const pluginIdentifier = 'dexcomshare';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': PluginManifest.runtimeIdentifier(fallback: pluginIdentifier),
      'displayName': PluginManifest.runtimeDisplayName(fallback: 'Dexcom'),
      'version': PluginManifest.runtimeVersion(fallback: '1.0.0'),
      'author': PluginManifest.runtimeAuthor(fallback: 'Nivo'),
      'requiresLogin': true,
      'iconName': 'dexcom',
      'capabilities': {
        'supportsMultipleDataSources': false,
        'supportsHistory': true,
        'maxHistoryHours': 24,
        'supportsSpecialValues': true,
        'requiresRegionSelection': true,
        'supportsCombinedFetch': true,
        'authKind': 'emailPassword',
        'apiVersion': '1',
      },
      'signIn': {
        'hint':
            'Requires Dexcom Share enabled and at least one follower in the Dexcom app.',
        'fields': [
          {
            'key': 'region',
            'type': 'select',
            'label': 'Region',
            'options': [
              {'value': 'us', 'label': 'United States'},
              {'value': 'ous', 'label': 'Outside US'},
              {'value': 'jp', 'label': 'Japan'},
            ],
          },
          {
            'key': 'username',
            'type': 'text',
            'label': 'Email',
            'textInput': 'email',
          },
          {'key': 'password', 'type': 'secret', 'label': 'Password'},
        ],
      },
    };
  }

  static Future<Map<String, dynamic>> dispatch(
    Map<String, dynamic> request,
  ) async {
    return switch (request['command'] as String?) {
      'getPluginInfo' => getPluginInfo(),
      'authenticate' => _authenticate(request),
      'getDataSources' => _getDataSources(),
      'getCurrentReading' => _getCurrentReading(request),
      'getHistory' => _getHistory(request),
      'fetchReadings' => _fetchReadings(request),
      _ => ProtocolHelpers.unknownCommand(),
    };
  }

  static Future<Map<String, dynamic>> _authenticate(
    Map<String, dynamic> request,
  ) async {
    final username = request['username'] as String? ?? '';
    final password = request['password'] as String? ?? '';
    final options = SessionFactory.optionsMap(request['options']);
    final http = SessionFactory.httpFromOptions(options);
    try {
      final result = await AuthService(http).authenticate(
        email: username,
        password: password,
      );
      return result.toAuthenticateResponse();
    } on DexcomException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Map<String, dynamic> _getDataSources() {
    return {
      'success': true,
      'dataSources': [
        {
          'id': GlucoseMapper.defaultDataSourceId,
          'name': 'Dexcom',
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> _getCurrentReading(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.glucoseServiceFromRequest(request);
    if (service == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final hours = ProtocolHelpers.historyHours(request);
    try {
      final reading = await service.currentReading(hours: hours);
      return {'success': true, ...reading};
    } on DexcomException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _getHistory(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.glucoseServiceFromRequest(request);
    if (service == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final hours = ProtocolHelpers.historyHours(request);
    try {
      final readings = await service.history(hours: hours);
      return {'success': true, 'readings': readings};
    } on DexcomException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _fetchReadings(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.glucoseServiceFromRequest(request);
    if (service == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final hours = ProtocolHelpers.historyHours(request);
    final historySince = ProtocolHelpers.historySince(request);
    try {
      final snapshot = await service.fetchReadings(
        hours: hours,
        historySince: historySince,
      );
      return snapshot.toFetchReadingsResponse();
    } on DexcomException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
