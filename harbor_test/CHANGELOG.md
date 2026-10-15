## 0.4.1

Needs harbor 0.10.0. Nothing in harbor_test's API changes. Its `dart fix` data now migrates a bare `pumpSeaTrial(...)` (and every other renamed extension member) called through implicit `this` inside an extension on `WidgetTester`, which 0.4.0's fix turned into a call that did not compile (#143).

## 0.4.0

Needs harbor 0.9.0, which renamed its API (#120); harbor_test's names follow it. Sea trials are trials.

* `HarborSeaTrials` is `HarborTrials`, and `tester.pumpSeaTrial(tideIn:)` is `tester.pumpHarborTrial(keyboardShown:)`.
* `HarborSeaTrial` is `HarborTrial`: `raiseTide` and `lowerTide` are `showKeyboard` and `hideKeyboard`, `setTide(tideIn:)` is `setKeyboard(shown:)`, `tideIn` is `keyboardShown`, `waterline` is `keyboardTop`, `clearWaterAround` is `roomAround`, and `docksAround` is `barsAround`.
* `isInClearWater` is `isInRoom`.
* **Breaking:** `HarborTrialDevice(coast:, tideHeight:, reportsCoastUnderTide:)` is `HarborTrialDevice(systemEdges:, keyboardHeight:, reportsSystemEdgesUnderKeyboard:)`, in `copyWith` too. The class keeps its name, so its constructor and `copyWith` take only the new names, which stay `required`; `dart fix` renames the old ones in a call. The old getters (`coast`, `tideHeight`, `reportsCoastUnderTide`) still read, deprecated. `coastWhen(tideIn:)` is `systemEdgesWhen(keyboardShown:)`.
* Every other 0.3 name still works, deprecated, until 1.0. `HarborSeaTrials` stays an extension of its own, holding only `pumpSeaTrial`, since an extension cannot be aliased.
* **Migrating:** `dart fix --apply` (harbor_test ships its own fix data), then `dart format`. It rewrites `tester.pumpSeaTrial(...)` and `HarborSeaTrials(tester).pumpSeaTrial(...)` alike.

## 0.3.1

Needs harbor 0.8.0. Nothing in harbor_test changes.

## 0.3.0

Needs harbor 0.7.0.

* `HarborTrialDevice.androidThreeButtonLandscape` and `androidGestureLandscape`: the Android phones on their side, turned the usual way (`ROTATION_90`). Both are 915 × 412 at 2.625 with the status bar's 24 on top, as AOSP keeps it in landscape. With three buttons the navigation bar moves to the right, 48 wide (`navigation_bar_width`); with gestures it stays at the bottom, 24 high, and the camera's cutout moves to the left (24, an estimate). Their 200-point keyboards are estimates too.
* **Breaking:** `HarborTrialDevice.all` now includes both, after `iPhone17Landscape`, so a test run over `all` gains two cases. `phones` is unchanged.

## 0.2.4

Needs harbor 0.6.0. Nothing in harbor_test changes.

## 0.2.3

Needs harbor 0.5.0, whose docks keep off a hinge. Nothing in harbor_test changes.

## 0.2.2

Needs harbor 0.4.0, whose side docks own the corners. Nothing in harbor_test changes.

## 0.2.1

Needs harbor 0.3.2.

* The package's tests cover `HarborTideSource` under `pumpSeaTrial`, which arrived in harbor 0.3.2, so the `harbor:` constraint is raised to `^0.3.2`. `lib/` is unchanged.
* Docs: "A dock of a given reach" shows how to build a dock that reaches a given distance from the edge, coast included, with no helper. ([#68](https://github.com/SupposedlySam/harbor/issues/68))

## 0.2.0

Needs harbor 0.3.0.

* `clearWaterAround` and `docksAround` read `HarborChart.nearest`, harbor's public chart, instead of the harbor's internals, which harbor now keeps to itself. What they return is unchanged.
* **Breaking:** each device preset now carries a `devicePixelRatio` (3.0 for `iPhone17` and `iPhone17Landscape`, 2.0 for `iPhoneSE`, 2.625 for the Android phones, the foldable and the cover screen, 2.5 for `dualScreenOpen`, 1.0 for `television`), and `pumpSeaTrial` puts it on the view with the size, coast and tide in physical pixels. Logical sizes and insets are unchanged. A test that writes `tester.view` itself after `pumpSeaTrial` (its `viewInsets`, `padding` or `physicalSize`) must write physical pixels, multiplying by `tester.view.devicePixelRatio`, as anywhere in `flutter_test`; and a golden taken in a trial is now rendered at the device's ratio. `device.copyWith(devicePixelRatio: 1.0)` keeps the old ratio.
* **Breaking:** `HarborTrialDevice.all` now includes `dualScreenOpen`, so a test run over `all` gains a case.
* `pumpSeaTrial(textScaleFactor:)` sets the text scale the platform reports, and clears it when the test ends.
* `HarborTrialDevice.copyWith`.
* `clearWaterAround` fails the test with a `TestFailure` when no harbor is around the finder, instead of throwing a `StateError`.
* `raiseTide`, `lowerTide` and `setTide` take `pumpFor:`, how long to pump after the keyboard moves (600 ms when not given, as before). `pumpFor: Duration.zero` pumps one frame, so a test can check the first frame after the keyboard arrives, or run its own timers from there.

## 0.1.0

The first sea trials, moved here from `package:harbor/testing.dart` so that harbor no longer depends on `flutter_test`.

* `pumpSeaTrial` and `HarborSeaTrial`: a harbor on a device, with a tide to raise and lower.
* `HarborTrialDevice` presets, with the `phones` and `all` lists.
* `HarborTrialDevice.displayFeatures`, applied to the view: `foldableOpen` declares its flat fold and `dualScreenOpen` (new) a 34-wide hinge, so a trial can check that nothing lands across it.
* `isInClearWater`, `clearWaterAround` and `docksAround`.
