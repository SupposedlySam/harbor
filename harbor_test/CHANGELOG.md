## Unreleased

* `raiseTide`, `lowerTide` and `setTide` take `pumpFor:`, how long to pump after the keyboard moves (600 ms when not given, as before). `pumpFor: Duration.zero` pumps one frame, so a test can check the first frame after the keyboard arrives, or run its own timers from there.

## 0.1.0

The first sea trials, moved here from `package:harbor/testing.dart` so that harbor no longer depends on `flutter_test`.

* `pumpSeaTrial` and `HarborSeaTrial`: a harbor on a device, with a tide to raise and lower.
* `HarborTrialDevice` presets, with the `phones` and `all` lists.
* `HarborTrialDevice.displayFeatures`, applied to the view: `foldableOpen` declares its flat fold and `dualScreenOpen` (new) a 34-wide hinge, so a trial can check that nothing lands across it.
* `isInClearWater`, `clearWaterAround` and `docksAround`.
