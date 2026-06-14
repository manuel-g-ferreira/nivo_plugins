import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/services/auth_service.dart';
import 'package:nightscout_plugin/session_factory.dart';

const pluginIdentifier = 'nightscout';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': pluginIdentifier,
      'displayName': 'Nightscout',
      'version': '1.0.0',
      'author': 'Nivo',
      'requiresLogin': true,
      'iconName': 'nightscout',
      'capabilities': {
        'supportsMultipleDataSources': false,
        'supportsHistory': true,
        'maxHistoryHours': 24,
        'supportsSpecialValues': true,
        'requiresRegionSelection': false,
        'supportsCombinedFetch': true,
        'authKind': 'urlSecret',
        'apiVersion': '1',
      },
    };
  }

  static Future<Map<String, dynamic>> dispatch(
    Map<String, dynamic> request,
  ) async {
    return switch (request['command'] as String?) {
      'getPluginInfo' => getPluginInfo(),
      'authenticate' => _authenticate(request),
      'getDataSources' => _getDataSources(request),
      'getCurrentReading' => _getCurrentReading(request),
      'getHistory' => _getHistory(request),
      'fetchReadings' => _fetchReadings(request),
      _ => {'success': false, 'error': 'Unknown command'},
    };
  }

  static Future<Map<String, dynamic>> _authenticate(
    Map<String, dynamic> request,
  ) async {
    final creds = SessionFactory.credentialsFrom(request);
    try {
      final result = await AuthService().authenticate(
        baseUrl: creds.baseUrl,
        apiSecret: creds.apiSecret,
        accessToken: creds.accessToken,
      );
      return {
        'success': true,
        'authToken': result.authToken,
        'userId': result.userId,
        'defaultDataSourceId': result.defaultDataSourceId,
        'sessionOptions': result.sessionOptions,
      };
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Map<String, dynamic> _getDataSources(Map<String, dynamic> request) {
    final http = SessionFactory.httpFromRequest(request);
    if (http == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    return {
      'success': true,
      'dataSources': [
        {
          'id': EntryMapper.defaultDataSourceId,
          'name': EntryMapper.siteDisplayName(http.baseUrl),
        },
      ],
    };
  }

  static Future<Map<String, dynamic>> _getCurrentReading(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.entriesServiceFromRequest(request);
    if (service == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    try {
      final reading = await service.currentReading();
      return {'success': true, ...reading};
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _getHistory(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.entriesServiceFromRequest(request);
    if (service == null) {
      return {'success': false, 'error': 'Not authenticated'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
    try {
      final readings = await service.history(hours: hours);
      return {'success': true, 'readings': readings};
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _fetchReadings(
    Map<String, dynamic> request,
  ) async {
    final service = SessionFactory.entriesServiceFromRequest(request);
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
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
