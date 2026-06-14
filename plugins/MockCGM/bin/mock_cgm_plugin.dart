import 'dart:convert';
import 'dart:io';

import 'package:mock_cgm_plugin/protocol_dispatch.dart';

/// Mock CGM plugin entry — JSON line protocol v1.
Future<void> main() async {
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) {
      continue;
    }
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = ProtocolDispatch.dispatch(request);
      stdout.writeln(jsonEncode(response));
      await stdout.flush();
    } on Object catch (e) {
      stdout.writeln(jsonEncode({'success': false, 'error': e.toString()}));
      await stdout.flush();
    }
  }
}
