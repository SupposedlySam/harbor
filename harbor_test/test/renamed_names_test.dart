// harbor_test 0.4.0 renamed sea trials to trials; the 0.3 names stay as deprecated forwarders until
// 1.0. ../test_fixes/rename_trials.dart checks what `dart fix` makes of them.

// Every use below is the deprecated spelling on purpose.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

void main() {
  // Breaks if: an old name is accepted and does something other than its new one.
  testWidgets('the 0.3 names forward to the new ones', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      const HarborFrame(
        body: HarborClear(child: SizedBox.expand(key: ValueKey<String>('body'))),
      ),
      tideIn: true,
    );
    expect(trial.tideIn, isTrue);
    expect(trial.keyboardShown, isTrue);
    expect(trial.waterline, trial.keyboardTop);
    expect(trial.waterline, 874 - 336, reason: 'positive control: the keyboard is up');
    await trial.lowerTide();
    expect(trial.keyboardShown, isFalse);
    await trial.setTide(tideIn: true);
    expect(trial.keyboardShown, isTrue);
    await trial.raiseTide();
    final Finder body = find.byKey(const ValueKey<String>('body'));
    expect(trial.clearWaterAround(body), trial.roomAround(body));
    expect(trial.docksAround(body), trial.barsAround(body));
    expect(body, isInClearWater(trial.roomAround(body)));

    const HarborTrialDevice device = HarborTrialDevice(
      name: 'old',
      size: Size(400, 800),
      coast: EdgeInsets.only(bottom: 20),
      tideHeight: 300,
    );
    expect(device.systemEdges, device.coast);
    expect(device.keyboardHeight, 300);
    expect(device.coastWhen(tideIn: true), device.systemEdgesWhen(keyboardShown: true));
    expect(device.copyWith(tideHeight: 200).keyboardHeight, 200);
  });
}
