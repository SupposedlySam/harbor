## Unreleased

The first sea trials, moved here from `package:harbor/testing.dart` so that harbor no longer depends on `flutter_test`.

* `pumpSeaTrial` and `HarborSeaTrial`: a harbor on a device, with a tide to raise and lower.
* `HarborTrialDevice` presets, with the `phones` and `all` lists.
* `HarborTrialDevice.displayFeatures`, applied to the view: `foldableOpen` declares its flat fold and `dualScreenOpen` (new) a 34-wide hinge, so a trial can check that nothing lands across it.
* `isInClearWater`, `clearWaterAround` and `docksAround`.
