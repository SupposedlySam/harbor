// The README's recipe for a bar of a given reach (#68): no helper is needed, and these pin the
// two forms it shows.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _page(final HarborBar bar) => HarborRoot(
  child: HarborFrame(
    bottom: <HarborBar>[bar],
    body: const SizedBox.expand(key: ValueKey<String>('body')),
  ),
);

/// How far the bar's ground reaches up from the bottom of the screen.
double _reach(final HarborTrial trial, final HarborTrialDevice device) {
  final Rect bar = trial.barsAround(find.byKey(const ValueKey<String>('body'))).single.rect;
  expect(bar.bottom, device.size.height);
  return bar.height;
}

void main() {
  const HarborTrialDevice phone = HarborTrialDevice.iPhone17; // a 34 home indicator
  const HarborTrialDevice homeButton = HarborTrialDevice.iPhoneSE; // none

  testWidgets('a solid bar with minimum: reach and an empty child reaches max(system edge, reach)', (
    final tester,
  ) async {
    for (final (HarborTrialDevice device, double reach, double expected) in <(HarborTrialDevice, double, double)>[
      (phone, 94, 94),
      (phone, 20, 34),
      (homeButton, 94, 94),
      (homeButton, 0, 0),
    ]) {
      final HarborTrial trial = await tester.pumpHarborTrial(
        _page(HarborBar.solid(minimum: reach, child: const SizedBox.shrink())),
        device: device,
      );
      expect(_reach(trial, device), expected, reason: '${device.name}, reach $reach');
    }
  });

  testWidgets('a solid bar with no system edge and a child of height reach reaches exactly reach', (
    final tester,
  ) async {
    for (final (HarborTrialDevice device, double reach) in <(HarborTrialDevice, double)>[
      (phone, 94),
      (phone, 20),
      (homeButton, 94),
    ]) {
      final HarborTrial trial = await tester.pumpHarborTrial(
        _page(
          HarborBar.solid(
            systemEdges: HarborSystemEdgeStance.none,
            child: SizedBox(height: reach),
          ),
        ),
        device: device,
      );
      expect(_reach(trial, device), reach, reason: '${device.name}, reach $reach');
      // The body still keeps clear of the home indicator that a short bar leaves uncovered.
      final double clear = trial.roomAround(find.byKey(const ValueKey<String>('body'))).bottom;
      expect(device.size.height - clear, reach > device.systemEdges.bottom ? reach : device.systemEdges.bottom);
    }
  });
}
