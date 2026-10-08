## Unreleased

* `HarborPortalBuoy`: an anchored buoy opened from anywhere in the tree (a menu from a list row, a popover from a button), built on `OverlayPortal`. It is placed in the nearest harbor's clear water by its child or a `HarborAnchor`, flips to the other side of its anchor when its side has no room, and is held inside the clear water otherwise.
* `HarborBuoySide.before` and `.after` are in reading order: under right-to-left, an anchored buoy `before` its anchor sits on its right. They were placed as if left-to-right.

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
