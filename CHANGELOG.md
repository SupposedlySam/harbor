## Unreleased

* `HarborSheet.draggable(controller:)` takes a `DraggableScrollableController`, so a draggable sheet can be read and moved from outside it: fitted to content measured after layout, or raised to its ceiling when a field takes focus.
* `HarborSheet.draggable(expand:)`, as on `DraggableScrollableSheet`: `false` in a route that sizes the sheet to its content (`showModalBottomSheet`), so a tap above the visible sheet reaches the barrier and closes it. Before, the sheet filled the modal bottom sheet's surface and swallowed those taps.
* `HarborSheetExtent(shouldCloseOnMinExtent:)`, as on `DraggableScrollableSheet`: off, a draggable sheet rests at its floor instead of closing.
* A fling down on a draggable sheet's header from its lowest height goes to its floor and closes it, as a fling on its list does. Before, the header sprang back to its rest unless flung faster than 1200. A slow release still goes to the nearest of its heights.

## 0.2.0

### Breaking changes

* **Sea trials moved to `harbor_test`.** harbor no longer depends on `flutter_test`. Run `flutter pub add dev:harbor_test` and import `package:harbor_test/harbor_test.dart`; `package:harbor/testing.dart` is now empty and deprecated.
* **`HarborBuoy(modal: true)` is modal** and needs `onDismiss`: a barrier keeps taps off the page, and a tap beside the buoy or back calls `onDismiss`.
* **`HarborBuoy.alignment` is an `AlignmentGeometry` and `HarborBuoy.margin` an `EdgeInsetsGeometry`.** Passing `Alignment` and `EdgeInsets` still compiles; reading the fields as the physical types needs `resolve(textDirection)`.
* **Behaviour that moves things:** an anchored buoy's `before` and `after` follow reading order under right-to-left; a sheet with no barrier closes on back before its page; on a dual-screen device, sheets, dialogs, signals and buoys keep off the hinge; a signal raised with no harbor above it shows in the nearest overlay instead of asserting.

### Everything in this release

* **Breaking:** `HarborBuoy(modal: true)` is modal. It puts a barrier over the page and its docks (`barrierColor`, clear by default), a tap beside it or back calls the new `onDismiss`, and screen readers leave the page alone while it is up; it still hides the buoys listed before it. `onDismiss` is required with `modal: true`. Before, a modal buoy only hid the buoys before it, and taps and back reached the page.

* Sheets, dialogs, signals and buoys keep off a foldable's hinge, as Material's dialogs and bottom sheets do: each is kept to one screen. A flat fold, which has no width, may still be spanned. `HarborTrialDevice` gains `displayFeatures`; `foldableOpen` declares its fold, and the new `dualScreenOpen` a hinge.
* A dialog's builder sees the opener's themes, and a dialog appears without fading under reduced motion, as sheets and signals already do.

* A sheet with no barrier is tied to the page that opened it: back closes it before the page, the iOS back swipe stands aside while it is up, it hides while another page is on top, and it leaves when its page is replaced. Before, back popped the page from under it, and opened from above the page's harbor it could outlive the page.

* After a turn or a foldable opening, a page under a breakwater sheet is no longer laid out for one frame against the cover the sheet had in the old shape (it could overflow), and a signal follows the clear water of the harbor that raised it instead of staying boxed into the old screen.

* `HarborSignals.raise` with no harbor above the context shows the signal in the nearest `Overlay`, clear of `MediaQuery.padding` and `viewInsets`, instead of asserting in debug and showing nothing in release. With no overlay either, it reports a `FlutterError`.
* A signal's timers are cancelled when it is lowered or its harbor leaves with nowhere to move it, so a widget test that removes the tree with a signal up no longer fails with a pending timer.
* Readers rebuild only for what they read. `HarborWaters.of` depends on `MediaQuery`'s padding (and, outside a harbor, its size) rather than all of it, and only where its `aspect` needs them. `HarborTide.isInOf` rebuilds when the keyboard comes or goes, not on every frame it moves. `HarborMoored`, `HarborMooringLine`, `HarborOpenWater`, `HarborDryDock` and a horizontal `HarborFairway` no longer rebuild while the keyboard animates. Layout is unchanged.
* `HarborWaters.steadyCoastOf(context, edge)` and `HarborWatersData.coastSteady`: the coast as it is with the keyboard down, so a footer keeps the home indicator's height while the keyboard is up.
* `HarborFairway(minimum:)`, `HarborFairwaySliver(minimum:)` and `HarborFairway.paddingOf(minimum:)`: a floor on each end's clearance, as on `SafeArea`.
* `HarborFairway.box` takes its child's size across the scroll when that axis is unbounded, so a horizontal row in a `Column` is as tall as its content instead of throwing.
* Docs: mooring the bottom edge alone clears the coast and the keyboard but not a header; `HarborCoastFeature.hinge` and `HarborController.isPort` are reserved and not yet read.
* `showHarborSheet(routeSettings:)`: the sheet's route carries its settings, so navigator observers and route-name analytics see it.
* `showHarborSheet(barrierLabel:)`: what a screen reader announces for the barrier, `'Close sheet'` when none is given. A Material app passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`.
* `HarborSheet(contentBuilder:)`: wraps the header, body and footer above the surface. A Material app wraps them in a transparent `Material` so text fields and ink work (the README has the recipe, with the bottom sheet theme's width).
* harbor's core imports no design library, and a test keeps it that way: Flutter 3.47 moved Material and Cupertino into `material_ui` and `cupertino_ui`.
* `HarborSheet(clip:)`: clips the sheet to a shape, so an edge-to-edge body follows the surface's rounded top.
* `HarborSheet(dragToClose: true)`: a content-sized sheet can be dragged down to close. Off by default.
* `HarborSheetExtent(snapSizes:)`: the heights a draggable sheet snaps to. A fling on its header goes to the next one its way, as a fling on its list does.
* Fixed: a draggable sheet in a route `showHarborSheet` did not open (`showModalBottomSheet`, `showGeneralDialog`) did nothing when dragged below its floor; it now closes that route.
* `HarborPortalBuoy`: an anchored buoy opened from anywhere in the tree (a menu from a list row, a popover from a button), built on `OverlayPortal`. It is placed in the nearest harbor's clear water by its child or a `HarborAnchor`, flips to the other side of its anchor when its side has no room, and is held inside the clear water otherwise.
* `HarborBuoySide.before` and `.after` are in reading order: under right-to-left, an anchored buoy `before` its anchor sits on its right. They were placed as if left-to-right.
Accessibility and Flutter's conventions for custom widgets.

* A dock that is dark or withdrawn is skipped by keyboard focus and by screen readers. Before, Tab still reached a dark dock's controls, and a withdrawn dock was still read out and focusable.
* A signal is a live region, so screen readers announce it as it appears.
* A signal keeps the themes of the place that raised it, as a sheet does.
* A sheet's builder sees the opener's themes in its own `context`. Before, they reached only the widgets below what the builder returned.
* Docks, signals and sheets honour `MediaQuery.disableAnimations`: with reduced motion they appear and leave without moving.
* On iOS, a tap on the status bar scrolls a harbor page's primary scroll view to the top, as it does under a `Scaffold`.
* **Breaking:** `HarborBuoy.alignment` is an `AlignmentGeometry`, and `HarborBuoy.margin` and `HarborPortalBuoy.margin` are `EdgeInsetsGeometry`, so `AlignmentDirectional.bottomEnd` places a buoy by reading direction. Code passing `Alignment` and `EdgeInsets` still compiles; code reading `.alignment` or `.margin` as the physical types needs a `resolve(textDirection)`.
* **Breaking:** sea trials moved to their own package, `harbor_test`, so harbor no longer depends on `flutter_test` and an app that depends on harbor no longer gets the test framework in its own dependencies. Add `harbor_test` as a `dev_dependency` and import `package:harbor_test/harbor_test.dart` in place of `package:harbor/testing.dart`. `pumpSeaTrial`, `HarborTrialDevice` and `isInClearWater` are unchanged.
* `package:harbor/testing.dart` is now empty and deprecated: the analyzer reports where it is imported, with a pointer to `harbor_test`. It is removed in the next release.

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
