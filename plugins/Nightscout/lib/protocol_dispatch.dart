import 'package:nightscout_plugin/mappers/entry_mapper.dart';
import 'package:nightscout_plugin/nightscout_exception.dart';
import 'package:nightscout_plugin/services/auth_service.dart';
import 'package:nightscout_plugin/session_factory.dart';
import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/protocol_helpers.dart';
import 'package:nivo_plugins/protocol_helpers.dart';

const pluginIdentifier = 'nightscout';

abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': PluginManifest.runtimeIdentifier(fallback: pluginIdentifier),
      'displayName': PluginManifest.runtimeDisplayName(fallback: 'Nightscout'),
      'version': PluginManifest.runtimeVersion(fallback: '1.0.0'),
      'author': PluginManifest.runtimeAuthor(fallback: 'Nivo'),
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
      'signIn': {
        'fields': [
          {
            'key': 'username',
            'type': 'text',
            'label': 'Site URL',
            'textInput': 'url',
          },
          {'key': 'password', 'type': 'secret', 'label': 'API Secret'},
          {
            'key': 'accessToken',
            'type': 'secret',
            'label': 'Access token (optional)',
          },
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
      'getDataSources' => _getDataSources(request),
      'getCurrentReading' => _getCurrentReading(request),
      'getHistory' => _getHistory(request),
      'fetchReadings' => _fetchReadings(request),
      _ => ProtocolHelpers.unknownCommand(),
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
      return result.toAuthenticateResponse();
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Map<String, dynamic> _getDataSources(Map<String, dynamic> request) {
    final http = SessionFactory.httpFromRequest(request);
    if (http == null) {
      return ProtocolHelpers.notAuthenticated();
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
      return ProtocolHelpers.notAuthenticated();
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
      return ProtocolHelpers.notAuthenticated();
    }
    final hours = ProtocolHelpers.historyHours(request);
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
    } on NightscoutException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
