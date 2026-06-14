import 'package:librelink_plugin/endpoints/graph_endpoint.dart';
import 'package:librelink_plugin/glucose_mapper.dart';
import 'package:librelink_plugin/llu_exception.dart';
import 'package:librelink_plugin/transport/llu_http.dart';

/// One vendor graph fetch → current + filtered history (protocol shapes).
class GraphService {
  GraphService(this._http);

  final LluHttp _http;
  final _cache = <String, _CachedGraph>{};
  static const _cacheTtl = Duration(seconds: 30);

  Future<Map<String, dynamic>> _loadGraph(String patientId) async {
    final cacheKey = '${_http.authToken}:$patientId';
    final cached = _cache[cacheKey];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.fetchedAt) < _cacheTtl) {
      return cached.data;
    }
    final data = await GraphEndpoint(_http).fetch(patientId);
    _cache[cacheKey] = _CachedGraph(data: data, fetchedAt: now);
    return data;
  }

  Future<Map<String, dynamic>> currentReading(String patientId) async {
    final graph = await _loadGraph(patientId);
    final connection = graph['connection'];
    Map<String, dynamic>? measurement;
    if (connection is Map<String, dynamic>) {
      measurement = connection['glucoseMeasurement'] as Map<String, dynamic>?;
      measurement ??= connection['glucoseItem'] as Map<String, dynamic>?;
    }
    final reading = GlucoseMapper.toProtocolReading(measurement);
    if (reading == null) {
      throw LluException('No current glucose reading');
    }
    return reading;
  }

  Future<List<Map<String, dynamic>>> history(
    String patientId, {
    required int hours,
  }) async {
    final graph = await _loadGraph(patientId);
    return GlucoseMapper.historyFromGraph(graph, hours: hours);
  }

  Future<FetchReadingsResult> fetchReadings(
    String patientId, {
    required int hours,
  }) async {
    final graph = await _loadGraph(patientId);
    return GlucoseMapper.snapshotFromGraph(graph, hours: hours);
  }
}

class FetchReadingsResult {
  const FetchReadingsResult({required this.current, required this.history});

  final Map<String, dynamic> current;
  final List<Map<String, dynamic>> history;
}

class _CachedGraph {
  const _CachedGraph({required this.data, required this.fetchedAt});
  final Map<String, dynamic> data;
  final DateTime fetchedAt;
}
