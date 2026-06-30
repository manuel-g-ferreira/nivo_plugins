import 'package:dexcomshare_plugin/transport/dexcom_http.dart';
import 'package:test/test.dart';

void main() {
  test('maps regions to expected servers and application IDs', () {
    expect(
      DexcomHttp.forRegion('us').applicationId,
      DexcomHttp.usApplicationId,
    );
    expect(
      DexcomHttp.forRegion('jp').applicationId,
      DexcomHttp.jpApplicationId,
    );
    expect(
      DexcomHttp.forRegion('ous').baseUrl,
      contains('shareous1'),
    );
    expect(
      DexcomHttp.forRegion('jp').baseUrl,
      contains('share.dexcom.jp'),
    );
  });
}
