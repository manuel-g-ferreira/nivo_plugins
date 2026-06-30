import 'package:librelink_plugin/llu_exception.dart';
import 'package:nivo_plugins/protocol_dtos.dart';

/// Maps LibreLink `GlucoseItem` JSON to Nivo plugin protocol fields.
abstract final class GlucoseMapper {
  static FetchReadingsResult snapshotFromGraph(
    Map<String, dynamic> graph, {
    required int hours,
  }) {
    final current = currentFromGraph(graph);
    if (current == null) {
      throw LluException('No current glucose reading');
    }
    return FetchReadingsResult(
      current: current,
      history: historyFromGraph(graph, hours: hours),
    );
  }

  static Map<String, dynamic>? currentFromGraph(Map<String, dynamic> graph) {
    final connection = graph['connection'];
    Map<String, dynamic>? measurement;
    if (connection is Map<String, dynamic>) {
      measurement = connection['glucoseMeasurement'] as Map<String, dynamic>?;
      measurement ??= connection['glucoseItem'] as Map<String, dynamic>?;
    }
    return toProtocolReading(measurement);
  }

  static List<Map<String, dynamic>> historyFromGraph(
    Map<String, dynamic> graph, {
    required int hours,
  }) {
    final graphData = graph['graphData'];
    if (graphData is! List) {
      return [];
    }
    final clampedHours = hours.clamp(1, 24);
    final cutoff = DateTime.now().toUtc().subtract(
          Duration(hours: clampedHours),
        );
    final readings = <Map<String, dynamic>>[];
    for (final item in graphData) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final mapped = toProtocolReading(item);
      if (mapped == null) {
        continue;
      }
      final ts = DateTime.parse(mapped['timestamp'] as String);
      if (ts.isBefore(cutoff)) {
        continue;
      }
      readings.add(mapped);
    }
    readings.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return readings;
  }

  static Map<String, dynamic>? toProtocolReading(Map<String, dynamic>? item) {
    if (item == null) {
      return null;
    }
    final special = _specialValue(item);
    final mgdl = item['ValueInMgPerDl'];
    if (special == null && mgdl is! num) {
      return null;
    }
    final timestamp = _parseTimestamp(item);
    if (timestamp == null) {
      return null;
    }
    return {
      'value': special == null ? (mgdl as num).round() : 0,
      'trend': _mapTrend(item['TrendArrow']),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'specialValue': special,
    };
  }

  static String? _specialValue(Map<String, dynamic> item) {
    if (item['isHigh'] == true) {
      return 'HI';
    }
    if (item['isLow'] == true) {
      return 'LO';
    }
    final value = item['ValueInMgPerDl'];
    if (value is num) {
      if (value <= 0) {
        return 'LO';
      }
      if (value >= 501) {
        return 'HI';
      }
    }
    return null;
  }

  static DateTime? _parseTimestamp(Map<String, dynamic> item) {
    final factory = item['FactoryTimestamp'];
    if (factory is String && factory.isNotEmpty) {
      final parsed = _parseLibreLinkTimestamp(factory, assumeUtc: true);
      if (parsed != null) {
        return parsed;
      }
    }
    final display = item['Timestamp'];
    if (display is String && display.isNotEmpty) {
      return _parseLibreLinkTimestamp(display, assumeUtc: false);
    }
    return null;
  }

  /// Parses LibreLink `M/d/yyyy h:mm:ss a` timestamps.
  ///
  /// Factory timestamps are UTC wall time (DiaKEM: `FactoryTimestamp + ' UTC'`).
  /// Display [Timestamp] values are local wall time.
  static DateTime? _parseLibreLinkTimestamp(
    String raw, {
    required bool assumeUtc,
  }) {
    final trimmed = raw.trim();
    if (trimmed.contains('T') || trimmed.endsWith('Z')) {
      try {
        return DateTime.parse(trimmed).toUtc();
      } on Object {
        return null;
      }
    }

    final hasUtcSuffix = trimmed.toUpperCase().endsWith(' UTC');
    final withoutUtc = hasUtcSuffix
        ? trimmed.substring(0, trimmed.length - 4).trimRight()
        : trimmed;
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) (AM|PM)$',
      caseSensitive: false,
    ).firstMatch(withoutUtc);
    if (match == null) {
      return null;
    }

    var hour = int.parse(match.group(4)!);
    final ampm = match.group(7)!.toUpperCase();
    if (ampm == 'PM' && hour != 12) {
      hour += 12;
    }
    if (ampm == 'AM' && hour == 12) {
      hour = 0;
    }

    final year = int.parse(match.group(3)!);
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final minute = int.parse(match.group(5)!);
    final second = int.parse(match.group(6)!);

    if (assumeUtc || hasUtcSuffix) {
      return DateTime.utc(year, month, day, hour, minute, second);
    }
    return DateTime(year, month, day, hour, minute, second).toUtc();
  }

  static String _mapTrend(Object? arrow) {
    return switch (arrow) {
      1 => 'singleDown',
      2 => 'fortyFiveDown',
      3 => 'flat',
      4 => 'fortyFiveUp',
      5 => 'singleUp',
      _ => 'notComputable',
    };
  }
}
