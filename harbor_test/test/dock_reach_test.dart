// The README's recipe for a dock of a given reach (#68): no helper is needed, and these pin the
// two forms it shows.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _page(final HarborDock dock) => HarborSea(
  child: Harbor(bottom: <HarborDock>[dock], body: const SizedBox.expand(key: ValueKey<String>('body'))),
);

/// How far the dock's ground reaches up from the bottom of the screen.
double _reach(final HarborSeaTrial trial, final HarborTrialDevice device) {
  final Rect dock = trial.docksAround(find.byKey(const ValueKey<String>('body'))).single.rect;
  expect(dock.bottom, device.size.height);
  return dock.height;
}

void main() {
  const HarborTrialDevice phone = HarborTrialDevice.iPhone17; // a 34 home indicator
  const HarborTrialDevice homeButton = HarborTrialDevice.iPhoneSE; // none

  testWidgets('a quay with minimum: reach and an empty child reaches max(coast, reach)', (final tester) async {
    for (final (HarborTrialDevice device, double reach, double expected) in <(HarborTrialDevice, double, double)>[
      (phone, 94, 94),
      (phone, 20, 34),
      (homeButton, 94, 94),
      (homeButton, 0, 0),
    ]) {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _page(HarborDock.quay(minimum: reach, child: const SizedBox.shrink())),
        device: device,
      );
      expect(_reach(trial, device), expected, reason: '${device.name}, reach $reach');
    }
  });

  testWidgets('a quay with no coast and a child of height reach reaches exactly reach', (final tester) async {
    for (final (HarborTrialDevice device, double reach) in <(HarborTrialDevice, double)>[
      (phone, 94),
      (phone, 20),
      (homeButton, 94),
    ]) {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _page(HarborDock.quay(coast: HarborCoastStance.none, child: SizedBox(height: reach))),
        device: device,
      );
      expect(_reach(trial, device), reach, reason: '${device.name}, reach $reach');
      // The body still keeps clear of the home indicator that a short dock leaves uncovered.
      final double clear = trial.clearWaterAround(find.byKey(const ValueKey<String>('body'))).bottom;
      expect(device.size.height - clear, reach > device.coast.bottom ? reach : device.coast.bottom);
    }
  });
}
