// Dexcom Share — JSON line protocol v1.
// Build: dart run tool/glucose_plugin.dart build plugins/DexcomShare
import 'dart:convert';
import 'dart:io';

import 'package:dexcomshare_plugin/protocol_dispatch.dart';

Future<void> main() async {
  await for (final line
      in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) {
      continue;
    }
    try {
      final request = jsonDecode(line) as Map<String, dynamic>;
      final response = await ProtocolDispatch.dispatch(request);
      stdout.writeln(jsonEncode(response));
      await stdout.flush();
    } on Object catch (e) {
      stdout.writeln(jsonEncode({'success': false, 'error': e.toString()}));
      await stdout.flush();
    }
  }
}
