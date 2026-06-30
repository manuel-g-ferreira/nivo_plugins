import 'dart:io';

/// Runs [executable] with [args] and throws [ProcessException] on non-zero exit.
Future<ProcessResult> runProcess(
  String executable,
  List<String> args, {
  String? workingDirectory,
  bool inheritStdio = false,
}) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDirectory,
    runInShell: false,
  );

  if (result.exitCode != 0) {
    final stderr = result.stderr.toString().trim();
    final stdout = result.stdout.toString().trim();
    final detail = stderr.isNotEmpty
        ? stderr
        : stdout.isNotEmpty
        ? stdout
        : 'exit code ${result.exitCode}';
    throw ProcessException(executable, args, detail, result.exitCode);
  }

  if (inheritStdio) {
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  return result;
}

Future<String> runProcessOutput(
  String executable,
  List<String> args, {
  String? workingDirectory,
}) async {
  final result = await runProcess(
    executable,
    args,
    workingDirectory: workingDirectory,
  );
  return result.stdout.toString().trim();
}
