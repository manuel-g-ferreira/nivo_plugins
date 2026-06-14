import 'dart:io';

import 'src/release/cli.dart';

Future<void> main(List<String> arguments) async {
  final rootDir = Directory.current.path;
  exit(await runReleaseCli(arguments, rootDir: rootDir));
}
