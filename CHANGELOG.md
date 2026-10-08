## Unreleased

Accessibility and Flutter's conventions for custom widgets.

* A dock that is dark or withdrawn is skipped by keyboard focus and by screen readers. Before, Tab still reached a dark dock's controls, and a withdrawn dock was still read out and focusable.
* A signal is a live region, so screen readers announce it as it appears.
* A signal keeps the themes of the place that raised it, as a sheet does.
* A sheet's builder sees the opener's themes in its own `context`. Before, they reached only the widgets below what the builder returned.
* Docks, signals and sheets honour `MediaQuery.disableAnimations`: with reduced motion they appear and leave without moving.
* On iOS, a tap on the status bar scrolls a harbor page's primary scroll view to the top, as it does under a `Scaffold`.
* **Breaking:** `HarborBuoy.alignment` is an `AlignmentGeometry` and `HarborBuoy.margin` an `EdgeInsetsGeometry`, so `AlignmentDirectional.bottomEnd` places a buoy by reading direction. Code passing `Alignment` and `EdgeInsets` still compiles; code reading `.alignment` or `.margin` as the physical types needs a `resolve(textDirection)`.

## 0.1.0

The first harbor.

* `Harbor`, `HarborSea`: frames whose edges docks are built against, laid out in one pass (docks, then the body, then the buoys).
* `HarborDock.pier` / `.quay`: measured docks that content sails under or starts beyond; wakes (`HarborWake.fade`, `.hairline`), tide stances (float, pilings, dry dock), states (open, dark, withdrawn) with extent policies, resting extents, minimums.
* `HarborCoast`: the platform's insets, fixed coasts, `HarborCoast.none`, and TV title-safe.
* `HarborTide`, `HarborDryDock`: the keyboard's height after it is consumed, its phase and its high-water mark.
* Content: `HarborMoored`, `HarborMooringLine`, `HarborFairway` (vertical and horizontal, reveals widened by what covers the edge), `HarborFairwaySliver`, `HarborSliverDock`, `HarborOpenWater`, `HarborCastOff`, and the `HarborWaters` breakdown.
* `HarborMakeWay`, `HarborPontoon`, `HarborController`: claims on an edge and docks moored from deep in the tree.
* `HarborBuoy` (aligned, anchored, modal), `HarborAnchor`, `HarborSignals`.
* `showHarborSheet`, `HarborSheet` (content-sized and draggable), breakwaters, `showHarborDialog`.
* `HarborLighthouse`, `HarborBeacon`, `HarborLighthouseRegion`: reveal, keep in sight, lift, and coverage.
* `HarborScaleModel`: a reference screen scaled to fit, with insets re-based.
* `HarborChart`, `HarborChartOverlay`, and the `ext.harbor.chart` VM-service extension.
* `package:harbor/testing.dart`: `pumpSeaTrial`, `HarborTrialDevice` presets and `isInClearWater`.
