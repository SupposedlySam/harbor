// harbor_test's rename transforms (harbor_test/lib/fix_data.yaml, 0.4.0): sea trials became trials.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_test/harbor_test.dart';

Future<void> trials(WidgetTester tester) async {
  final HarborSeaTrial trial = await tester.pumpSeaTrial(const SizedBox(), device: HarborTrialDevice.iPhoneSE, tideIn: true);
  await trial.raiseTide(settle: true);
  await trial.lowerTide(pumpFor: Duration.zero);
  await trial.setTide(tideIn: true);
  final bool up = trial.tideIn;
  final double top = trial.waterline;
  final Rect room = trial.clearWaterAround(find.byType(SizedBox));
  final List<Object> bars = trial.docksAround(find.byType(SizedBox));
  expect(find.byType(SizedBox), isInClearWater(room));
  expect(find.byType(SizedBox), isInClearWater(room, tolerance: 1));
  <Object?>[up, top, bars];
}

void devices() {
  const HarborTrialDevice device = HarborTrialDevice(name: 'tv', size: Size(1200, 675), coast: EdgeInsets.zero, tideHeight: 0, reportsCoastUnderTide: true);
  final HarborTrialDevice copy = device.copyWith(coast: EdgeInsets.zero, tideHeight: 100, reportsCoastUnderTide: false);
  <Object?>[device.coast, device.tideHeight, device.reportsCoastUnderTide, copy.coastWhen(tideIn: true)];
}

// The same calls through implicit `this`, inside an extension on each type (#143). A bare
// pumpSeaTrial() matches the HarborSeaTrials extension rename as well as its own, and once became
// the extension override `HarborTrials(...)`, which does not compile.
extension PumpOnDevice on WidgetTester {
  Future<HarborSeaTrial> pumpOnDevice(Widget child) async {
    final HarborSeaTrial trial = await pumpSeaTrial(child, tideIn: false);
    await pumpSeaTrial(child, device: HarborTrialDevice.iPhoneSE);
    return trial;
  }
}

// Through implicit `this`: against 1.0 the methods are renamed and the getters (tideIn, waterline,
// and the device's below) are left as they are, as in rename_members.dart.
extension ImplicitTrial on HarborSeaTrial {
  Future<void> moves() async {
    await raiseTide(settle: true);
    await lowerTide(pumpFor: Duration.zero);
    await setTide(tideIn: true);
    final bool up = tideIn;
    final double top = waterline;
    final Rect room = clearWaterAround(find.byType(SizedBox));
    final List<Object> bars = docksAround(find.byType(SizedBox));
    <Object?>[up, top, room, bars];
  }
}

extension ImplicitDevice on HarborTrialDevice {
  List<Object?> get reads => <Object?>[coast, tideHeight, reportsCoastUnderTide, coastWhen(tideIn: true), copyWith(coast: EdgeInsets.zero, tideHeight: 100, reportsCoastUnderTide: false)];
}
