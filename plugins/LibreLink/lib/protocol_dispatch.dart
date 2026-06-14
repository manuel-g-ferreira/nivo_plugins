import 'package:librelink_plugin/endpoints/connections_endpoint.dart';
import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/services/auth_service.dart';
import 'package:librelink_plugin/session_factory.dart';

const pluginIdentifier = 'librelink';

/// Nivo JSON-line protocol → LibreLink services.
abstract final class ProtocolDispatch {
  static Map<String, dynamic> getPluginInfo() {
    return {
      'success': true,
      'identifier': pluginIdentifier,
      'displayName': 'LibreLink Up',
      'version': '1.0.0',
      'author': 'Nivo',
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
    return {
      'success': true,
      'authToken': result.authToken,
      'userId': result.userId,
      if (result.defaultDataSourceId != null)
        'defaultDataSourceId': result.defaultDataSourceId,
      'sessionOptions': result.sessionOptions,
    };
  }

  static Future<Map<String, dynamic>> _getDataSources(
    Map<String, dynamic> request,
  ) async {
    final http = SessionFactory.httpFromRequest(request);
    if (http == null) {
      return {'success': false, 'error': 'Not authenticated'};
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return {'success': false, 'error': 'dataSourceId required'};
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return {'success': false, 'error': 'dataSourceId required'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
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
      return {'success': false, 'error': 'Not authenticated'};
    }
    final patientId = request['dataSourceId'] as String?;
    if (patientId == null || patientId.isEmpty) {
      return {'success': false, 'error': 'dataSourceId required'};
    }
    final hours = ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
    try {
      final snapshot = await graph.fetchReadings(patientId, hours: hours);
      return {
        'success': true,
        'current': snapshot.current,
        'history': snapshot.history,
      };
    } on LluException catch (e) {
      return {'success': false, 'error': e.message};
    }
  }
}
