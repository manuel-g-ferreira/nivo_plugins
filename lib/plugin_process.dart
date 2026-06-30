import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Subprocess JSON line protocol for build-time plugin probing.
class PluginProcess {
  PluginProcess(this.executablePath);

  final String executablePath;
  Process? _process;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  final _lineQueue = <String>[];
  final _lineWaiters = <Completer<String>>[];
  final _stderrLines = <String>[];

  Future<void> start() async {
    if (_process != null) {
      return;
    }
    final path = File(executablePath).absolute.path;
    _process = await Process.start(path, [], runInShell: false);
    _stdoutSub = _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onStdoutLine);
    _stderrSub = _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_stderrLines.add);
  }

  void _onStdoutLine(String line) {
    if (_lineWaiters.isNotEmpty) {
      _lineWaiters.removeAt(0).complete(line);
      return;
    }
    _lineQueue.add(line);
  }

  Future<String> _readLine(Duration timeout) async {
    if (_lineQueue.isNotEmpty) {
      return _lineQueue.removeAt(0);
    }
    final waiter = Completer<String>();
    _lineWaiters.add(waiter);
    return waiter.future.timeout(timeout);
  }

  Future<Map<String, dynamic>> send(
    Map<String, dynamic> request, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final process = _process;
    if (process == null) {
      throw StateError('PluginProcess not started');
    }
    process.stdin.writeln(jsonEncode(request));
    await process.stdin.flush();
    late final String line;
    try {
      line = await _readLine(timeout);
    } on TimeoutException {
      final detail = _stderrLines.isEmpty
          ? 'no plugin response'
          : _stderrLines.join('\n');
      throw TimeoutException(
        'Plugin did not respond to ${request['command']}: $detail',
        timeout,
      );
    }
    return jsonDecode(line) as Map<String, dynamic>;
  }

  Future<void> terminate() async {
    await _stdoutSub?.cancel();
    await _stderrSub?.cancel();
    _stdoutSub = null;
    _stderrSub = null;
    _lineQueue.clear();
    _stderrLines.clear();
    for (final waiter in _lineWaiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(StateError('PluginProcess terminated'));
      }
    }
    _lineWaiters.clear();
    final process = _process;
    _process = null;
    if (process == null) {
      return;
    }
    process.kill(ProcessSignal.sigterm);
    await process.exitCode.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  }
}
