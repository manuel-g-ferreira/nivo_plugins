/// Shared helpers for Nivo plugin JSON-line protocol handlers.
abstract final class ProtocolHelpers {
  /// Host-provided delta hint on `fetchReadings` (not persisted in credentials).
  static const historySinceOptionKey = 'historySince';

  static Map<String, String> optionsMap(Object? raw) {
    if (raw is! Map) {
      return {};
    }
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  static DateTime? historySince(Map<String, dynamic> request) {
    final raw = optionsMap(request['options'])[historySinceOptionKey];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.parse(raw).toUtc();
  }

  static int historyHours(Map<String, dynamic> request) {
    return ((request['hours'] as num?)?.toInt() ?? 3).clamp(1, 24);
  }

  static Map<String, dynamic> notAuthenticated() {
    return {'success': false, 'error': 'Not authenticated'};
  }

  static Map<String, dynamic> missingDataSourceId() {
    return {'success': false, 'error': 'dataSourceId required'};
  }

  static Map<String, dynamic> unknownCommand() {
    return {'success': false, 'error': 'Unknown command'};
  }
}
