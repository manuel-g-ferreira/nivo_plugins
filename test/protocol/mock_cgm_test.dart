import 'dart:convert';
import 'dart:io';

import 'package:nivo_plugins/plugin_process.dart';
import 'package:test/test.dart';

import '../helpers/mock_plugin_executable.dart';

void main() {
  late String executablePath;

  setUpAll(() async {
    executablePath = await ensureMockPluginExecutable();
  });

  test('getPluginInfo matches golden', () async {
    final golden =
        jsonDecode(
              await File(
                'test/fixtures/mock_get_plugin_info.json',
              ).readAsString(),
            )
            as Map<String, dynamic>;

    final process = PluginProcess(executablePath);
    await process.start();
    addTearDown(process.terminate);

    final response = await process.send({
      'command': 'getPluginInfo',
    }, timeout: const Duration(seconds: 3));

    expect(response['success'], true);
    expect(response['identifier'], golden['identifier']);
    expect(response['capabilities'], golden['capabilities']);
  });

  test('authenticate and getCurrentReading', () async {
    final process = PluginProcess(executablePath);
    await process.start();
    addTearDown(process.terminate);

    final auth = await process.send({
      'command': 'authenticate',
      'username': 'a',
      'password': 'b',
    }, timeout: const Duration(seconds: 3));
    expect(auth['success'], true);

    final reading = await process.send({
      'command': 'getCurrentReading',
      'authToken': auth['authToken'],
      'userId': auth['userId'],
      'dataSourceId': auth['defaultDataSourceId'],
    }, timeout: const Duration(seconds: 10));

    expect(reading['success'], true);
    final value = reading['value'] as int;
    expect(value, inInclusiveRange(50, 280));
    expect(
      reading['trend'],
      isIn([
        'notComputable',
        'singleDown',
        'fortyFiveDown',
        'flat',
        'fortyFiveUp',
        'singleUp',
        'doubleDown',
        'doubleUp',
      ]),
    );
    expect(reading['timestamp'], isNotEmpty);
  });

  test('getHistory returns 5-minute spaced points', () async {
    final process = PluginProcess(executablePath);
    await process.start();
    addTearDown(process.terminate);

    final auth = await process.send({'command': 'authenticate'});
    final history = await process.send({
      'command': 'getHistory',
      'authToken': auth['authToken'],
      'userId': auth['userId'],
      'dataSourceId': auth['defaultDataSourceId'],
      'hours': 3,
    }, timeout: const Duration(seconds: 30));

    expect(history['success'], true);
    final readings = history['readings'] as List<dynamic>;
    expect(readings.length, greaterThan(10));
    final first = DateTime.parse(readings.first['timestamp'] as String);
    final second = DateTime.parse(readings[1]['timestamp'] as String);
    expect(second.difference(first).inMinutes, 5);
  });

  test('fetchReadings returns current and history', () async {
    final process = PluginProcess(executablePath);
    await process.start();
    addTearDown(process.terminate);

    final auth = await process.send({'command': 'authenticate'});
    final snapshot = await process.send({
      'command': 'fetchReadings',
      'authToken': auth['authToken'],
      'userId': auth['userId'],
      'dataSourceId': auth['defaultDataSourceId'],
      'hours': 3,
    }, timeout: const Duration(seconds: 30));

    expect(snapshot['success'], true);
    expect(snapshot['current'], isA<Map<String, dynamic>>());
    final history = snapshot['history'] as List<dynamic>;
    expect(history.length, greaterThan(10));
  });
}
