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

MIT licensed.
