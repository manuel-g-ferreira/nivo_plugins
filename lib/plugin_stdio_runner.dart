import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef ProtocolDispatchFn =
    FutureOr<Map<String, dynamic>> Function(Map<String, dynamic> request);

/// JSON-line stdin/stdout loop shared by all plugin binaries.
Future<void> runPluginStdio(ProtocolDispatchFn dispatch) async {
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) {
      continue;
    }
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = await dispatch(request);
      stdout.writeln(jsonEncode(response));
      await stdout.flush();
    } on Object catch (e) {
      stdout.writeln(jsonEncode({'success': false, 'error': e.toString()}));
      await stdout.flush();
    }
  }
}
