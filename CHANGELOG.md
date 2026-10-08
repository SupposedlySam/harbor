## Unreleased

* `showHarborSheet(routeSettings:)`: the sheet's route carries its settings, so navigator observers and route-name analytics see it.
* `showHarborSheet(barrierLabel:)`: the barrier reads Material's dismiss label when the app has Material localizations, `'Close sheet'` otherwise, or the label given.
* `showHarborSheet(maxWidthFromTheme: true)`: the sheet's width comes from `BottomSheetThemeData.constraints`, or Material 3's 640 when the theme sets none. Without it, a sheet still spans the screen.
* `HarborSheet(material: true)`: a transparent `Material` over the surface, so text fields and ink work in a sheet. It keeps the opener's text style.
* `HarborSheet(clip:)`: clips the sheet to a shape, so an edge-to-edge body follows the surface's rounded top.
* `HarborSheet(dragToClose: true)`: a content-sized sheet can be dragged down to close. Off by default.
* `HarborSheetExtent(snapSizes:)`: the heights a draggable sheet snaps to. A fling on its header goes to the next one its way, as a fling on its list does.
* Fixed: a draggable sheet in a route `showHarborSheet` did not open (`showModalBottomSheet`, `showGeneralDialog`) did nothing when dragged below its floor; it now closes that route.

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
