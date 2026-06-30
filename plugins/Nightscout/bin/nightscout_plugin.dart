import 'package:nightscout_plugin/protocol_dispatch.dart';
import 'package:nivo_plugins/plugin_stdio_runner.dart';

Future<void> main() async {
  await runPluginStdio(ProtocolDispatch.dispatch);
}
