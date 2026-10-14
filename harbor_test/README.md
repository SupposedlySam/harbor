# harbor_test

Widget-test helpers for [harbor](https://pub.dev/packages/harbor): put a widget test on a
pretend device, show and hide its keyboard, and check that things sit in the room
(what the system edges, the bars and the keyboard leave).

A package of its own so that `flutter_test` stays out of your app's dependencies.
Add it as a dev dependency, next to harbor:

```sh
flutter pub add harbor dev:harbor_test
```

```dart
import 'package:harbor_test/harbor_test.dart';

testWidgets('the composer rides the keyboard', (tester) async {
  final trial = await tester.pumpHarborTrial(app, device: HarborTrialDevice.androidThreeButton);
  await trial.showKeyboard();
  expect(tester.getRect(find.byType(Composer)).bottom, trial.keyboardTop);
});
```

`showKeyboard()` and `hideKeyboard()` move the keyboard and pump 600 ms, long enough
for the frame to follow. `pumpFor: Duration.zero` stops at the first frame drawn
after the keyboard moves, for a test that checks that frame or pumps on its
own; `settle: true` pumps until nothing is animating.

Devices: `iPhone17`, `iPhoneSE`, `androidThreeButton`, `androidGesture`,
`iPhone17Landscape`, `androidThreeButtonLandscape`, `androidGestureLandscape`,
`foldableOpen` (a flat fold), `dualScreenOpen` (a hinge),
`dualScreenCover`, `television`, plus the `phones` and `all` lists. Each goes on
the test view at its own `devicePixelRatio`; `device.copyWith(devicePixelRatio: 1.0)`
tries one at another. A device of your own takes its screen, its system edges and
its keyboard's height:

```dart
const tablet = HarborTrialDevice(
  name: 'tablet',
  size: Size(820, 1180),
  systemEdges: EdgeInsets.only(top: 24, bottom: 20),
  keyboardHeight: 400,
);
```

`pumpHarborTrial(textScaleFactor: 2.0)` reports a larger
system text size, as `tester.platformDispatcher.textScaleFactorTestValue` does,
so a bar is measured at the size its text grew to. Both are reset when the test
ends. `trial.roomAround(finder)` and `isInRoom`
assert where something sits relative to everything in the way, not to a number.
`trial.barsAround(finder)` lists the bars of the frame around it.

## A bar of a given reach

A test that wants "a 94 pt bottom bar on a phone with a 34 pt home indicator"
needs no arithmetic. A bar adds the system edge to its child, and its `minimum` is a
floor on that padding, so a bar with an empty child reaches from the screen's
edge to the larger of the system edge and `minimum`:

```dart
HarborBar.solid(minimum: reach, child: const SizedBox.shrink()) // reaches max(system edge, reach)
```

To reach exactly `reach` whatever the system edge, take the system edge out and give the
child the height:

```dart
HarborBar.solid(systemEdges: HarborSystemEdgeStance.none, child: SizedBox(height: reach)) // reaches exactly reach
```

The body still keeps clear of whatever system edge a shorter bar leaves uncovered,
so with a 20 pt bar over a 34 pt home indicator, content rests 34 pt up.

MIT licensed.
