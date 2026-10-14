// harbor_test's rename transforms (harbor_test/lib/fix_data.yaml, 0.4.0): sea trials became trials.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_test/harbor_test.dart';

Future<void> trials(WidgetTester tester) async {
  final HarborSeaTrial trial = await tester.pumpSeaTrial(const SizedBox(), device: HarborTrialDevice.iPhoneSE, tideIn: true);
  await HarborSeaTrials(tester).pumpSeaTrial(const SizedBox());
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
