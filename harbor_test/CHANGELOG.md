## Unreleased

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
