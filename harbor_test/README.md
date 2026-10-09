# harbor_test

Sea trials for [harbor](https://pub.dev/packages/harbor): put a widget test on a
pretend device, bring its keyboard in and out, and check that things sit in clear
water.

A package of its own so that `flutter_test` stays out of your app's dependencies.
Add it as a dev dependency, next to harbor:

```sh
flutter pub add harbor dev:harbor_test
```

```dart
import 'package:harbor_test/harbor_test.dart';

testWidgets('the composer rides the keyboard', (tester) async {
  final trial = await tester.pumpSeaTrial(app, device: HarborTrialDevice.androidThreeButton);
  await trial.raiseTide();
  expect(tester.getRect(find.byType(Composer)).bottom, trial.waterline);
});
```

`raiseTide()` and `lowerTide()` move the keyboard and pump 600 ms, long enough
for the harbor to follow. `pumpFor: Duration.zero` stops at the first frame
after the keyboard moves, for a test that checks that frame or pumps on its
own; `settle: true` pumps until nothing is animating.

Devices: `iPhone17`, `iPhoneSE`, `androidThreeButton`, `androidGesture`,
`iPhone17Landscape`, `foldableOpen` (a flat fold), `dualScreenOpen` (a hinge),
`dualScreenCover`, `television`, plus the `phones` and `all` lists. Each goes on
the test view at its own `devicePixelRatio`; `device.copyWith(devicePixelRatio: 1.0)`
trials one at another. `pumpSeaTrial(textScaleFactor: 2.0)` reports a larger
system text size, as `tester.platformDispatcher.textScaleFactorTestValue` does,
so a dock is measured at the size its text grew to. Both are reset when the test
ends. `trial.clearWaterAround(finder)` and `isInClearWater`
assert where something sits relative to everything in the way, not to a number.
`trial.docksAround(finder)` lists the docks of the harbor around it.

## A dock of a given reach

A test that wants "a 94 pt bottom bar on a phone with a 34 pt home indicator"
needs no arithmetic. A dock adds the coast to its child, and its `minimum` is a
floor on that padding, so a dock with an empty child reaches from the screen's
edge to the larger of the coast and `minimum`:

```dart
HarborDock.quay(minimum: reach, child: const SizedBox.shrink()) // reaches max(coast, reach)
```

To reach exactly `reach` whatever the coast, take the coast out and give the
child the height:

```dart
HarborDock.quay(coast: HarborCoastStance.none, child: SizedBox(height: reach)) // reaches exactly reach
```

The body still keeps clear of whatever coast a shorter dock leaves uncovered,
so with a 20 pt dock over a 34 pt home indicator, content rests 34 pt up.

MIT licensed.
