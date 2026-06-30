import 'package:librelink_plugin/endpoints/connections_endpoint.dart';
import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/services/auth_service.dart';
import 'package:librelink_plugin/session_factory.dart';
import 'package:nivo_plugins/plugin_manifest.dart';
import 'package:nivo_plugins/protocol_helpers.dart';

const pluginIdentifier = 'librelink';

/// Nivo JSON-line protocol → LibreLink services.
abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': PluginManifest.runtimeIdentifier(fallback: pluginIdentifier),
      'displayName': PluginManifest.runtimeDisplayName(fallback: 'LibreLink Up'),
      'version': PluginManifest.runtimeVersion(fallback: '1.0.0'),
      'author': PluginManifest.runtimeAuthor(fallback: 'Nivo'),
      'requiresLogin': true,
      'iconName': 'librelink',
      'capabilities': {
        'supportsMultipleDataSources': true,
        'supportsHistory': true,
        'maxHistoryHours': 24,
        'supportsSpecialValues': true,
        'requiresRegionSelection': true,
        'supportsCombinedFetch': true,
        'authKind': 'emailPassword',
        'apiVersion': '1',
      },
      'signIn': {
        'fields': [
          {
            'key': 'region',
            'type': 'select',
            'label': 'Region',
            'options': [
              {'value': 'us', 'label': 'United States'},
              {'value': 'eu', 'label': 'Europe'},
              {'value': 'de', 'label': 'Germany'},
              {'value': 'fr', 'label': 'France'},
              {'value': 'jp', 'label': 'Japan'},
              {'value': 'au', 'label': 'Australia'},
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
    final username = request['username'] as String? ?? '';
    final password = request['password'] as String? ?? '';
    if (username.isEmpty || password.isEmpty) {
      return {'success': false, 'error': 'Email and password required'};
    }
    final options = SessionFactory.optionsMap(request['options']);
    final http = SessionFactory.httpFromOptions(options);
    final result = await AuthService(
      http,
    ).authenticate(email: username, password: password);
    return result.toAuthenticateResponse();
  }

  static Future<Map<String, dynamic>> _getDataSources(
    Map<String, dynamic> request,
  ) async {
    final http = SessionFactory.httpFromRequest(request);
    if (http == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    try {
      final connections = await ConnectionsEndpoint(http).list();
      if (connections.isEmpty) {
        return {
          'success': false,
          'error': 'No followed patients on this LibreLink Up account',
        };
      }
      return {
        'success': true,
        'dataSources': [
          for (final c in connections)
            {'id': c['patientId'] as String, 'name': connectionDisplayName(c)},
        ],
      };
    } on LluException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _getCurrentReading(
    Map<String, dynamic> request,
  ) async {
    final graph = SessionFactory.graphServiceFromRequest(request);
    if (graph == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return ProtocolHelpers.missingDataSourceId();
    }
    try {
      final reading = await graph.currentReading(patientId);
      return {'success': true, ...reading};
    } on LluException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _getHistory(
    Map<String, dynamic> request,
  ) async {
    final graph = SessionFactory.graphServiceFromRequest(request);
    if (graph == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return ProtocolHelpers.missingDataSourceId();
    }
    final hours = ProtocolHelpers.historyHours(request);
    try {
      final readings = await graph.history(patientId, hours: hours);
      return {'success': true, 'readings': readings};
    } on LluException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }

  static Future<Map<String, dynamic>> _fetchReadings(
    Map<String, dynamic> request,
  ) async {
    final graph = SessionFactory.graphServiceFromRequest(request);
    if (graph == null) {
      return ProtocolHelpers.notAuthenticated();
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return ProtocolHelpers.missingDataSourceId();
    }
    final hours = ProtocolHelpers.historyHours(request);
    final historySince = ProtocolHelpers.historySince(request);
    try {
      final snapshot = await graph.fetchReadings(
        patientId,
        hours: hours,
        historySince: historySince,
      );
      return snapshot.toFetchReadingsResponse();
    } on LluException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
