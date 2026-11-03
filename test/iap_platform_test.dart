import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexasort/services/iap_service.dart';

void main() {
  test('iOS maps to the single Gold Star product', () {
    expect(HexaStore.productIdsFor(TargetPlatform.iOS), {'hexasortstar'});
    expect(HexaStore.starId, 'hexasortstar');
  });
  test('Android maps to coffee + chocolate', () {
    expect(HexaStore.productIdsFor(TargetPlatform.android),
        {'hexasortcoffee', 'hexasortchocolate'});
  });
  test('iOS and Android product sets do not overlap', () {
    expect(HexaStore.productIdsFor(TargetPlatform.iOS)
        .intersection(HexaStore.productIdsFor(TargetPlatform.android)), isEmpty);
  });
}
