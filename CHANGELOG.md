## Unreleased

* **Breaking:** `HarborFairway.keyboardDismissBehavior` is nullable and unset by default, as on a `ScrollView`: it follows the fairway's `scrollBehavior`, or else the inherited `ScrollConfiguration`. Before, it was always `manual`, which overrode an app-wide `ScrollBehavior` that dismisses the keyboard on drag. Pass `ScrollViewKeyboardDismissBehavior.manual` to keep the old behaviour under such a behaviour.
* `HarborFairway` takes the rest of `CustomScrollView`'s parameters, with the same defaults: `scrollBehavior`, `center`, `anchor`, `paintOrder`, `dragStartBehavior`, `restorationId` and `hitTestBehavior`. `HarborFairway.box` takes those a `SingleChildScrollView` has. With a `center`, both ends of the scroll rest clear of the docks, the center sliver rests clear of the leading docks, sliver docks after it pin at the docks' face, and reveals on either side of it keep clear. `anchor` is a fraction of the water between the docks, so `anchor: 1` follows the keyboard, and reveals account for it.
* Keyed slivers in a fairway keep their state when they move, as in a `CustomScrollView`.

* Misuse is reported as a `FlutterError` that says what to do, as Flutter's own errors are. `HarborController.of` with no harbor above throws one in release builds too (before, a bare null-check error), and points to `HarborController.maybeOf`. A harbor given unbounded constraints, a quay listed inside a pier and `HarborSheet(dragToClose: true)` outside `showHarborSheet` name the harbor's `debugLabel` and the fix in debug builds, instead of failing a plain assert.
* In debug builds, two `HarborAnchorPoint`s that stay attached to one `HarborAnchor` past the end of a frame are reported. Before, the buoy silently moved to whichever laid out last.
* `showHarborSheet(sheetAnimationStyle:)`: an `AnimationStyle`, as on `showModalBottomSheet`, sets how a sheet opens and closes, with or without a barrier: `duration` and `curve` going in, `reverseDuration` and `reverseCurve` going out, and `AnimationStyle.noAnimation` for none. A dragged sheet follows the finger with no curve and goes on along the curve when let go, so it stays under the finger with any curve, one that overshoots included. Reduced motion still wins.
* `HarborSheetController`, given to `showHarborSheet(controller:)`: closes a sheet from outside it (`close()`, `remove()` with no slide), completes `closed` when it has left, rebuilds it (`setState`) and reads its slide (`animation`). It is a `ChangeNotifier` that tells its listeners when a sheet attaches and leaves. For a sheet with no barrier, which `closeHarborSheet` could only close from inside, and for one with a barrier.
* `showHarborSheet(transitionAnimationController:)`, as on `showModalBottomSheet`: the sheet slides by the caller's controller in place of its own, and the caller disposes it.
* `HarborSheet.draggable(controller:)` takes a `DraggableScrollableController`, so a draggable sheet can be read and moved from outside it: fitted to content measured after layout, or raised to its ceiling when a field takes focus.
* `HarborSheet.draggable(expand:)`, as on `DraggableScrollableSheet`: `false` in a route that sizes the sheet to its content (`showModalBottomSheet`), so a tap above the visible sheet reaches the barrier and closes it. Before, the sheet filled the modal bottom sheet's surface and swallowed those taps.
* `HarborSheetExtent(shouldCloseOnMinExtent:)`, as on `DraggableScrollableSheet`: off, a draggable sheet rests at its floor instead of closing.
* A fling down on a draggable sheet's header from its lowest height goes to its floor and closes it, as a fling on its list does. Before, the header sprang back to its rest unless flung faster than 1200. A slow release still goes to the nearest of its heights.
* `HarborSheet.close(context, [result])` closes the sheet `context` is in and completes the future that opened it with `result`, as `Navigator.pop(context, result)` does for a modal bottom sheet. A sheet with no barrier can now return a value: before, its future always completed with null. Back and `Navigator.pop` still close it with null, since it is not a route.
* `closeHarborSheet` is deprecated in favour of `HarborSheet.close`, and `harborAlphaWake` in favour of `HarborWakeMask.alphaWake`. Both old names still work.
* `showHarborSheet(isDismissible:, requestFocus:, anchorPoint:)`, as `showModalBottomSheet` has them. With `isDismissible: false` a tap on the barrier (dimmed or clear) does nothing and back still closes the sheet; before, every barrier closed its sheet on a tap. `requestFocus` is passed to the sheet's route, and `anchorPoint` picks the screen a sheet opens on beside a hinge.

* Fixed: under a body that clears the tide, on a phone with a home indicator, `HarborMoored(clear: HarborClear.coast)` and every reader of `HarborWaters.of(context, aspect: HarborWatersAspect.coast)` rebuilt on every frame of the keyboard, and so did a reader of `HarborWaters.steadyCoastOf`. A coast reader now rebuilds only when the coast changes, and `steadyCoastOf` when the view padding does, as `MediaQuery.viewPaddingOf` would. `HarborWaters.of(aspect: HarborWatersAspect.coast).coastSteady` is filled in without subscribing, as the docks aspect already did; read it with `steadyCoastOf` to follow it. Values are unchanged.
* A tap on the iOS status bar scrolls only the page a `Scaffold` would: the one whose status bar band a tap at the screen's top left reaches. A page in a nested navigator no longer scrolls once a route covers that navigator (it scrolled to the top when uncovered), nor does a page under a full-screen overlay entry or the right-hand pane of a split view. A harbor with no top inset, and one inside a sheet that stops short of the status bar, no longer scrolls either, as a `Scaffold` does not. Nor does a harbor whose `coast` drops the top inset: the band is as tall as the top coast the harbor keeps.
* **Breaking:** `showHarborDialog` pushes a popup route (a `RawDialogRoute`, as `showGeneralDialog` does) instead of a page route. A `Hero` no longer flies into a harbor dialog, a `RouteObserver<PageRoute>` (and analytics observers that count page routes as screens) no longer sees one as a page, a `HarborSheet.draggable` inside one closes it when flung below its floor, and its content is a route scope for screen readers. The API is unchanged; code that checked `route is PageRoute` for a harbor dialog no longer matches. To migrate: check `route is PopupRoute` (or `RawDialogRoute`); name the dialog with `routeSettings` for screen analytics; for a `Hero` into a dialog, push a `PageRoute` of your own.
* `showHarborDialog` takes `showDialog`'s route options: `routeSettings:`, `barrierLabel:` (`'Close dialog'` when none is given; a Material app passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`), `semanticLabel:` (the name screen readers announce for the dialog), `anchorPoint:`, `traversalEdgeBehavior:`, `requestFocus:` and `animationStyle:`.
* `showHarborDialog` moved from `scale_model.dart` to `dialog.dart`. It is still exported from `package:harbor/harbor.dart`.
* A `HarborBeacon(keepInSight: true)` also brings itself into sight when focus moves into it, as `EditableText` does for its caret. In a form with the keyboard up, tapping the next field or pressing the keyboard's next action now reveals the whole beacon (the field and the button under it, `clearance` clear) rather than only the field's caret line. Before, a beacon re-revealed only when the keyboard rose or what covers the bottom grew. This applies with the keyboard down too. Every beacon now holds a `Focus` node of its own, so `Focus.of(context)` inside a beacon returns the beacon's node.
* `HarborSignals.raise(animationStyle:, transitionBuilder:)`: a signal's entrance and exit, as `showSnackBar(snackBarAnimationStyle:)` and `showGeneralDialog(transitionBuilder:)` take them. `AnimationStyle.noAnimation` shows a widget that brings its own entrance as it is, instead of fading and scaling it in on top; a `transitionBuilder` builds the entrance and exit from harbor's animation. A lowered signal stays for its whole exit, and never less than the 300 ms it stayed before.
* A signal's live region has a dismiss action, as a `SnackBar`'s does, so a screen reader can lower it. `HarborSignals.raise(liveRegion: false)` leaves the semantics to a widget that is its own live region: before, harbor wrapped it in a second live region with no label.
* `HarborSignalEntry` gains `animationStyle`, `transitionBuilder`, `liveRegion` and `lingers`, the time a lowered signal stays in the tree; `HarborSignalTransitionBuilder` is exported.
* `HarborSignals.raise(alignment:)`: raises a signal at an exact point in the clear water instead of a slot, placed as a buoy at that alignment would be, and in the nearest overlay's padded water when there is no harbor. An `AlignmentDirectional` is resolved in the reading direction of the page that raised it. `slot` is now nullable and still defaults to `high`; give one or the other. A tear-off of `raise` stored in a variable typed with a non-nullable `slot` needs its type updated.
* A sheet with a barrier is a semantics scope of its own, as a modal bottom sheet is: it scopes and names its route (`scopesRoute`, `namesRoute`, `explicitChildNodes`), so screen readers keep to the sheet and announce it as it opens. `showHarborSheet(semanticLabel:)` is the name they announce. A semantics-tree snapshot of an open sheet gains this node. A sheet with no barrier is not a route and is unchanged.
* `showHarborSheet(barrierOnTapHint:)`: what tapping the barrier does, read as 'Double tap to …', as on `ModalBottomSheetRoute`. A Material app passes `localizations.scrimOnTapHint(localizations.bottomSheetLabel)`.
* An anchored buoy whose anchor is not in the tree takes no taps. It was already not painted, but it was still hit-tested where it last sat (at first, the top-left corner), so an invisible buoy could swallow taps meant for the page. A portal buoy already behaved this way.
* **Breaking:** a sheet with no barrier comes back after a page pushed over its own has finished popping, not as the pop starts. Before, it was painted and tappable over the leaving page for the whole transition.

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
