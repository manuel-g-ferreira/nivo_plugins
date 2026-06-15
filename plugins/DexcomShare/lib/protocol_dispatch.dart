import 'package:dexcomshare_plugin/dexcom_exception.dart';
import 'package:dexcomshare_plugin/mappers/glucose_mapper.dart';
import 'package:dexcomshare_plugin/services/auth_service.dart';
import 'package:dexcomshare_plugin/session_factory.dart';

const pluginIdentifier = 'dexcomshare';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': pluginIdentifier,
      'displayName': 'Dexcom',
      'version': '1.0.0',
      'author': 'Nivo',
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
      _ => {'success': false, 'error': 'Unknown command'},
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
      return {
        'success': true,
        'authToken': result.authToken,
        'userId': result.userId,
        'defaultDataSourceId': result.defaultDataSourceId,
        'sessionOptions': result.sessionOptions,
      };
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
    try {
      final snapshot = await service.fetchReadings(hours: hours);
      return {
        'success': true,
        'current': snapshot.current,
        'history': snapshot.history,
      };
    } on DexcomException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
