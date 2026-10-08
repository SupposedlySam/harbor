# harbor

A harbor for your widgets.

Every screen is a rectangle, and something is always pushing in from its
edges: the status bar, the home indicator, a notch, a TV's overscan, the
keyboard, and your own headers, tab bars and composers. `harbor` gives each of
them a place and a rule, so your content stops doing inset arithmetic.

> **Docks claim the edges. Everything else moors clear of them, sails under
> them, or is open water. The tide (the keyboard) rises over whatever doesn't
> float.**

[![An illustrated harbor beside a phone running harbor. A pier is the header rows scroll under, and a quay is the tab bar the list stops at.](https://raw.githubusercontent.com/SupposedlySam/harbor/main/doc/media/showcase.gif)](https://github.com/SupposedlySam/harbor/blob/main/doc/media/showcase.mp4)

*Left, a harbor. Right, a phone running the real package, driven by the same
clock. The GIF is the opening; [the narrated video](https://github.com/SupposedlySam/harbor/blob/main/doc/media/showcase.mp4)
(four minutes) tours everything in the package, from the coast to sea trials.*

Depends on the Flutter SDK only. Sea trials for widget tests come in a package
of their own, `harbor_test`, so the test framework stays out of your app's
dependencies.

## Installing

```sh
flutter pub add harbor
flutter pub add dev:harbor_test   # sea trials, for widget tests
```

MIT licensed.

## The one rule

A harbor has layers: the **body** (your content) at the bottom, **docks** above
it, **buoys** above those, and the **coast and tide** (the system's insets and
the keyboard) above everything.

**Something on the same layer takes space. Something on a higher layer becomes
padding for everything beneath it.**

- A **quay** (pronounced "key") is a dock built on the shore. It takes its ground, and the body
  starts where it ends, like a `Column`.
- A **pier** is a dock built out over the water. The body runs under it and is
  told, through `MediaQuery.padding`, how far it reaches.

That's the whole difference between a header your list scrolls under and a
header your list starts below.

## Glossary

| Harbor | What it is | API |
|---|---|---|
| **Sea** | The root every harbor floats on | `HarborSea` |
| **Harbor** | A frame with docked edges: a page, a tab, a sheet | `Harbor` |
| **New port** | A harbor that starts fresh: a route, a sheet, a dialog | `Harbor(newPort: true)` |
| **Coast** | What the platform takes: status bar, home indicator, cutouts, TV title-safe | `HarborCoast` |
| **Tide** | The keyboard | `HarborTide` |
| **Dock** | Something built against an edge, measured, never declared | `HarborDock.pier` / `.quay` |
| **Wake** | The fade where content passes under a dock | `HarborWake` |
| **Moored** | Content kept clear of everything in its way | `HarborMoored` |
| **Mooring line** | The page margin, applied by the content that asks for it | `Harbor(margin:)`, `HarborMooringLine` |
| **Fairway** | A scroll view that runs under the docks and rests clear of them | `HarborFairway` |
| **Open water** | Content that ignores the docks: backgrounds, maps, heroes | `HarborOpenWater` |
| **Float / pilings / dry dock** | How a dock meets the tide | `HarborTideStance` |
| **Make way** | Content asking a dock to go dark or withdraw | `HarborMakeWay` |
| **Pontoon** | A dock moored from deep in the tree | `HarborPontoon` |
| **Buoy** | Something afloat in the clear water: a menu, a bubble | `HarborBuoy` |
| **Portal buoy** | A buoy opened from anywhere: a row's menu, a button's popover | `HarborPortalBuoy` |
| **Signal** | A transient buoy: a toast | `HarborSignals.raise` |
| **Breakwater** | A sheet reporting how much of the page it covers | `showHarborSheet(breakwater: true)` |
| **Lighthouse** | Keeps things in sight: reveal, lift, coverage | `HarborLighthouse`, `HarborBeacon` |
| **Scale model** | A fixed reference screen scaled to fit (TV) | `HarborScaleModel` |
| **Chart** | Who holds which edge, at which layer | `HarborChart`, `HarborChartOverlay` |
| **Sea trials** | Widget-test devices and tide control (`harbor_test`) | `pumpSeaTrial` |

**Pronouncing them:** a **quay** is pronounced "key", as harbours have always said it.
A **buoy** is pronounced "BOO-ee" in American English and "boy" in British; both are right.

## Getting started

Mount the sea once, above your `Navigator`:

```dart
MaterialApp(
  builder: (context, child) => HarborSea(
    margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
    child: child!,
  ),
  home: const InboxPage(),
);
```

Build a page from a harbor:

```dart
Harbor(
  top: [
    HarborDock.pier(
      wake: const HarborWake.fade(length: 12, blurSigma: 20),
      child: const InboxHeader(),
    ),
  ],
  bottom: [HarborDock.quay(child: const TabBar())],
  body: HarborFairway(
    slivers: [
      SliverList.builder(
        itemCount: 40,
        itemBuilder: (context, i) => HarborMooringLine(child: MessageRow(i)),
      ),
    ],
  ),
)
```

What each piece does:

- **The header** is a pier. It pads itself below the status bar and frosts the
  water beneath it.
- **The tab bar** is a quay. It pads itself above the home indicator, and the body
  ends at its top.
- **The fairway** runs the full height of the body, under the header. Its first
  row comes to rest past the header's wake, and its last row rests clear of the
  tab bar. Whatever sizes the header and the tab bar laid out at, nobody declared
  a height.
- **The rows** keep the mooring line, the 16 margin plus any side cutout. The list
  itself still runs to the frame's edge, so a carousel inside it can too.

## Docks

```dart
HarborDock.pier(child: header)          // content sails under it
HarborDock.quay(child: tabBar)          // content starts where it ends
```

Docks on one edge are listed in reading order (`top` and `bottom` top to
bottom, `start` and `end` in reading order) and stack. Docks on the same
layer add up; a pier over a quay reaches past it. Quays are always nearer the
edge than piers.

A dock **absorbs the coast** on its own edge: a top dock pads its child below the
status bar, and a bottom dock pads it above the home indicator. Its `backdrop` is
painted under the whole of its ground, coast included. The insets across it (a
top dock's sides) stay in the child's `MediaQuery` for the child to handle.

A dock sizes its child **the way a `Row` or `Column` does**: the child spans the
edge and picks its own depth. A `NavigationRail` in a `start` dock is as wide as
it is in a `Row`, and an `AppBar` in a `top` dock is as tall as its toolbar.
Something that fills whatever it is given, like a `ListView`, needs a size, just
as it would in a `Row`.

| Option | Use it for |
|---|---|
| `wake: HarborWake.fade(length:, blurSigma:, restsAt:)` | Content fades as it passes under; it rests past the fade (`HarborRest.wakeEnd`) or at the dock (`.dockEdge`) |
| `wake: HarborWake.hairline()` | A line on the dock's inner face, for a bar content scrolls up to |
| `tide: HarborTideStance.float` | Rides up on the keyboard: a composer, a sheet's footer. It sits on the home indicator until the keyboard is taller than it, so it never dips |
| `tide: HarborTideStance.pilings` | Stays put while the keyboard covers it: a tab bar (the default) |
| `tide: HarborTideStance.dryDock` | Keeps the keyboard's ground at high-water height either way, so its child's `HarborDryDock` fills that ground when the keyboard is down. It runs to the screen's edge: no coast, no minimum |
| `state: HarborDockState.dark` | Not drawn and not tappable, but it keeps its ground |
| `state: HarborDockState.withdrawn` | Slides out and gives its ground back |
| `extentPolicy:` | How a withdrawing dock gives its ground back: `hold` (once it's gone, the default), `follow`, `release` |
| `withdrawsAtHighTide: true` | Leaves while the keyboard is up: a tool strip |
| `restingExtent:` | The size to hold at rest for a dock that grows, like a rail that opens on focus |
| `minimum: 16` | At least this much room on the edge, coast or not |
| `hitTestBehavior:` | Opaque by default, so taps on the header never reach rows under it |

## Content

| Stance | Widget | Use it for |
|---|---|---|
| Moored | `HarborMoored(edges:, clear:, follow:, tide:, mooringLine:, minimum:, extra:)` | Forms, fixed buttons, static blocks |
| Moored to one edge | `HarborMoored(edges: {HarborEdge.bottom})` | A form footer under a page header: it clears the coast and the keyboard at the bottom, and leaves the header to the rest of the page |
| Mooring line | `HarborMooringLine(child:)` | A row that lines up with the page margin |
| Fairway | `HarborFairway(slivers:, minimum:)` / `HarborFairway.box(child:)` | Lists, grids, carousels (`scrollDirection: Axis.horizontal`) |
| One sliver | `HarborFairwaySliver(sliver:, minimum:)` | A sliver in your own `CustomScrollView` |
| Pinned header | `HarborSliverDock(child:)` | A header or tab strip inside the scroll that pins at the docks' face and stacks |
| Sticky | `HarborSticky(child:)` | A pill that rides with its item, then sticks below the docks and pinned headers |
| Centered | `HarborCenter(overlapBudget:)` | Controls centered in the frame that may overlap the docks by at most a budget |
| Open water | `HarborOpenWater(builder: (context, waters) => ...)` | Backgrounds, heroes; `waters.coast`, `.docks`, `.wakes`, `.frameSize` |

Each one **casts off** what it cleared, so nothing beneath clears it again.
`HarborCastOff` does the same for a layer you pad by hand, and
`HarborFairway.paddingOf` gives a third-party list the right scroll padding.

`HarborMoored(clear: HarborClear.coast)` keeps clear of the coast alone: a hero
title under a translucent header that must not touch the status bar.
`follow: HarborFollow.resting` holds still while a dock grows over it.
`HarborFairway(startsInOpenWater: true)` starts its first sliver at the frame's
edge, under the docks, for a hero that runs under a translucent header.
`minimum:` on a fairway or a fairway sliver is a floor on each end, as on
`SafeArea`: the end rests clear of whatever is in the way or the minimum,
whichever is larger, so a phone with a home button still keeps 16 under the last row.
`HarborFairway.box` given no bound across the scroll, as a horizontal one is in
a `Column`, is as thick as its child: a row of chips as tall as the chips, its
ends still clear.

`clear: HarborClear.coast` keeps clear of the coast alone, without the keyboard.
To keep clear of the coast and the keyboard but not a header, moor the bottom
edge alone: the header is on the top edge, so it is left to the page.

Fairways also draw the wake: their content fades as it sails under a dock with
a fade wake, while open water (a background, a hero) is left as it is. Give a
`Harbor` a `wakePainter` to wake its whole body instead
(`wakePainter: HarborWakeMask.alphaWake`), or to paint the wake your own way (a
progressive blur shader).

Fairways widen every reveal by what covers their trailing edge. A focused
field, `Scrollable.ensureVisible` and focus traversal all bring a row clear of
the docks and the keyboard with no extra code.

## The tide

```dart
Harbor(bodyClearsTide: true, ...)   // default: the body ends at the waterline
Harbor(bodyClearsTide: false, ...)  // the body runs under; content reads it
HarborTide.of(context)              // height, remaining, highWater, phase
HarborTide.isInOf(context)          // whether it is in, rebuilding only when that flips
```

`MediaQuery.padding` never carries the keyboard. That stays in `viewInsets`,
as Flutter has it, and harbor widgets add it where they keep clear of the
bottom. `HarborTide.of(context).height` is still readable after a harbor
has moved out of the keyboard's way: for information, never for layout.
`highWater` is the last settled keyboard height in this orientation, and it
falls as well as rises.

Readers rebuild only for what they read. `HarborTide.of` follows every frame
of the keyboard moving; `HarborTide.isInOf` hears it come and go, and
`HarborWaters.of(context, aspect: HarborWatersAspect.docks)` holds still while
it moves, and so does the `coast` aspect, on a phone with a home indicator too.
Harbor's own content reads the same way: a mooring line, a horizontal fairway,
open water or a dry dock in a page the keyboard runs under is not rebuilt as it
rises. Only what lays out against it is.

`HarborWaters.steadyCoastOf(context, HarborEdge.bottom)` is the home
indicator's height, held while the keyboard is up, as `viewPadding` is in
Flutter: for a footer that keeps its size while the keyboard animates. A body
that clears the tide has no `viewPadding` left at the bottom while the keyboard
is up, so read it here. It rebuilds its reader when the view padding changes,
as `MediaQuery.viewPaddingOf` does, but not on every frame of the keyboard. It
is zero below a quay that absorbed the coast, and below anything that cast the
edge off.

## Harbor and Scaffold

A harbor does what a `Scaffold` does for the edges, so a page built from a harbor does not need
one. Keep a `Scaffold` only where Material needs it, for its surface or to host `SnackBar`s, and
then give it the harbor as its body and **turn off its resizing**:

```dart
Scaffold(
  resizeToAvoidBottomInset: false, // the harbor handles the keyboard
  body: Harbor(top: [...], bottom: [...], body: ...),
)
```

A resizing `Scaffold` shrinks the harbor before the harbor ever sees the keyboard. Nothing is
counted twice, but every dock then rides up above the keyboard: a tab bar on pilings is lifted
instead of covered, and `bodyClearsTide: false` has nothing to run under. Leave the Scaffold's
`appBar`, `bottomNavigationBar` and `floatingActionButton` empty and use docks and buoys instead.

## Accessibility

What harbor hides is hidden from everyone: a dark or withdrawn dock is skipped
by keyboard focus and by screen readers, not only by taps. Signals are live
regions, so screen readers announce them, with a dismiss action that lowers
them, as a `SnackBar` is. A signal whose widget is already its own live region
(a `SnackBar`-like widget from your design library) is raised with
`liveRegion: false`, so harbor adds no second, unlabelled one around it. Sheets and signals keep the themes of
the page they came from, and so do dialogs. With reduced motion
(`MediaQuery.disableAnimations`) docks, signals, sheets and dialogs appear and
leave without moving, and the lighthouse's reveals and lifts jump into place. On iOS a tap on the
status bar scrolls a harbor page to the top, as it does under a `Scaffold`, and
as there only the page whose status bar band is on top at the screen's top left:
a page under a route in an outer navigator, under an overlay, or in the
right-hand pane of a split stays where it is.

## Talking to the harbor

```dart
HarborMakeWay(edge: HarborEdge.bottom, mode: HarborYield.withdraw, child: panel)
HarborPontoon(edge: HarborEdge.bottom, dock: HarborDock.pier(child: unsavedBar), child: form)
HarborController.of(context).makeWay(HarborEdge.top, mode: HarborYield.dark) // returns a claim; release() it
```

Claims are counted and go to the nearest harbor that has a dock on that edge.
A pontoon joins the harbor's docks on the next frame.
`HarborController.of` throws a `FlutterError` when there is no harbor above the
context, in release builds too, as `Scaffold.of` does; `HarborController.maybeOf`
returns null instead.

## Buoys and signals

```dart
Harbor(
  buoys: [
    HarborBuoy(alignment: AlignmentDirectional.bottomEnd, child: fab),
    HarborBuoy.anchored(anchor: launchAnchor, side: HarborBuoySide.above, overlap: 6, child: bubble),
    HarborBuoy(modal: true, onDismiss: closeQuickActions, child: quickActions), // a barrier over the page
  ],
  bottom: [HarborDock.quay(child: TabBar(launch: HarborAnchorPoint(anchor: launchAnchor, child: launchButton)))],
  body: ...,
)

HarborSignals.raise(context, slot: HarborSignalSlot.low, builder: (_) => Toast('Saved'));
HarborSignals.raise(context, alignment: const Alignment(0, -0.8), builder: (_) => Toast('Saved'));
HarborSignals.raise(
  context,
  transitionBuilder: (context, animation, child) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
    child: child,
  ),
  builder: (_) => Toast('Saved'),
);
```

Buoys float in the **clear water**: the rectangle no coast, dock or tide covers.
An anchored buoy sits on its `side` of its anchor; `before` and `after` are in
reading order, so `before` is on the right under right-to-left. While its
anchor is not in the tree, an anchored buoy is not shown and takes no taps.
A `HarborAnchor` refers to one `HarborAnchorPoint`, so give each row of a list
its own; in debug builds two points left on one anchor are reported after the
frame, as two leaders on one `LayerLink` are.
`alignment` and `margin` take directional values, so `AlignmentDirectional.bottomEnd`
puts a button where a right-to-left reader expects it.
A `modal` buoy is modal: a barrier (clear unless you give it a `barrierColor`)
keeps taps off the page and its docks and tells screen readers to leave them
alone, a tap beside the buoy or back calls its `onDismiss`, and the buoys listed
before it are hidden while it is up. Unlike a route, it does not trap keyboard
focus.
A signal is raised at a slot (`top`, `high`, `middle`, `low`) or at an exact
`alignment`, placed as a buoy at that alignment would be. An
`AlignmentDirectional` follows the reading direction of the page that raised it.
It fades and scales in over `animationStyle` (220 ms each way by default).
A `transitionBuilder` brings your own entrance and exit, run on harbor's
animation, and `AnimationStyle.noAnimation` shows a widget that animates
itself as it is, as `showSnackBar(snackBarAnimationStyle:)` does. A lowered
signal stays at least 300 ms, so its own exit can run.
A signal goes to the port on top (a sheet over a page over the sea), so a `low`
signal clears that sheet's footer, and it also stays clear of the docks of the
harbor it was raised from (a tab's own header). If its harbor leaves, the
signal moves to the one now on top.

A signal raised with no harbor above it (a widget test that pumps a bare
`MaterialApp`, a preview, a screen not yet built from a harbor) still shows: it
goes to the nearest `Overlay`, at its slot and clear of `MediaQuery.padding` and
`viewInsets`. With no overlay either, it is reported through
`FlutterError.reportError`, in release builds too. A signal's timers stop when it
is lowered or when nothing is left to show it, so a test that ends with one up
has no timer pending.

```dart
final menu = OverlayPortalController();

HarborPortalBuoy(                       // in a list row, anywhere below a harbor
  controller: menu,
  side: HarborBuoySide.below,
  buoyBuilder: (context) => const RowMenu(),
  child: GestureDetector(onTap: menu.toggle, child: row),
)
```

A **portal buoy** is an anchored buoy opened from where it is used rather than
listed in `Harbor.buoys`: a menu from a list row, a popover from a button in
another package. It is an `OverlayPortal`, so its buoy builds with the row's
themes and floats in the nearest `Overlay`, placed in the clear water of the
harbor around the row by its `child` (or by an `anchor`). When its `side` has
no room, it `flips` to the other side of the anchor, so a menu from a row just
above the tab bar or the keyboard opens above the row; when neither side has
room, it is held inside the clear water.

## Sheets and dialogs

```dart
showHarborSheet(context, builder: (_) => HarborSheet(header: title, footer: actions, body: form));
showHarborSheet(context, builder: (_) => HarborSheet.draggable(
  header: title,
  builder: (context, controller) => HarborFairway(controller: controller, slivers: [...]),
));
showHarborSheet(context, breakwater: true, barrier: HarborSheetBarrier.none, builder: ...);
showHarborDialog(context, inheritClearWater: true, builder: ...);
```

A sheet is a new port. It takes the themes and text style of the page that
opened it, and stops short of the status bar. Its header is a pier with a wake
(on a draggable sheet, also a drag handle), and its footer is a quay that
floats on the tide and keeps 16 off the edge. It keeps the home
indicator in its coast, so its footer clears it exactly once. A draggable
sheet's heights are fractions of the space between the status bar and the
keyboard. A **breakwater**
sheet reports how far it covers the page that opened it, and that page's
content keeps clear of it while it's up: in the same frame as the sheet is
drawn, as it slides in and out and as it is dragged.

On a dual-screen device, sheets and dialogs keep to one screen, as Material's do,
and signals and buoys keep to the screen that holds them, never across the hinge.
A flat fold, which has no width, may still be spanned.

A sheet with `barrier: HarborSheetBarrier.none` is not a route of its own, so
it is tied to the page that opened it: back (and a pop) closes it before the
page, the iOS back swipe stands aside while it is up, it hides while another
page is on top (from the first frame of that page's push until its pop has
finished, since the sheet is drawn above every page rather than inside its
own), and it leaves when its page is replaced or removed. A
`PopScope` inside such a sheet has no route to register with; put it around
the page instead.

```dart
final HarborSheetController nowPlaying = HarborSheetController();

showHarborSheet(context, barrier: HarborSheetBarrier.none, controller: nowPlaying, builder: ...);
nowPlaying.close();   // from a button on the page: it slides out
nowPlaying.remove();  // it goes at once
```

A `HarborSheetController` closes a sheet from outside it, as a
`PersistentBottomSheetController` closes `Scaffold.showBottomSheet`'s: `close()`,
a `closed` future, `setState` to rebuild it, and its slide as `animation`.
`remove()` takes it away with no slide, as `removeCurrentSnackBar` does a snack
bar. It is attached while its sheet is up (`isAttached`) and tells its listeners
when that changes, so a button can show whether it opens or closes. It works
for a sheet with a barrier too. `transitionAnimationController:` slides the
sheet by a controller of your own in place of its 280 ms slide, as on
`showModalBottomSheet`; you dispose it.

```dart
final Folder? folder = await showHarborSheet<Folder>(
  context,
  builder: (context) => HarborSheet(
    body: FolderList(onPick: (folder) => HarborSheet.close(context, folder)),
  ),
);
```

`HarborSheet.close(context, result)` closes the sheet `context` is in and
completes the future that opened it with `result`, as `Navigator.pop(context,
result)` does for a modal bottom sheet. It works whatever the barrier, and on a
sheet opened by `showModalBottomSheet` or `showGeneralDialog`, where it pops that
route. A sheet with no barrier is not a route, so back and `Navigator.pop` close
it with no result: it returns its value only through `HarborSheet.close`.

A sheet with a barrier is a route, as a modal bottom sheet is. `routeSettings:` reach your
navigator observers and route-name analytics, and `barrierLabel:` is what a
screen reader announces for the barrier ('Close sheet' when none is given), with
`barrierOnTapHint:` saying what tapping it does. Like a modal bottom sheet, the
sheet is a semantics scope of its own, and screen readers announce its
`semanticLabel:` as it opens. It spans the screen unless you give it a `maxWidth`.

A dialog is a popup route, as one from `showDialog` is: a `Hero` does not fly
into it, an observer of page routes does not count it as a screen, a draggable sheet
inside it closes it, and its content is a route of its own for screen readers, named by `semanticLabel:`. It
takes `showDialog`'s route options: `routeSettings:`, `barrierLabel:` ('Close
dialog' when none is given), `anchorPoint:` (which screen of a dual-screen
device it opens on), `traversalEdgeBehavior:`, `requestFocus:` and
`animationStyle:` (its fade, 180 ms by default).

Three more options are named and behave as `showModalBottomSheet`'s. `isDismissible: false`
makes a sheet the user has to answer: a tap on the barrier does nothing, and
back still closes it. `requestFocus: false` leaves focus in the page.
`anchorPoint:` picks which screen of a dual-screen device it opens on.

harbor imports no design library: it sits on Flutter's widgets layer, and since
Flutter 3.47 Material and Cupertino are packages of their own. So a Material app
passes Material's pieces in, the lines that `showModalBottomSheet` would have
filled in for it:

```dart
final MaterialLocalizations localizations = MaterialLocalizations.of(context);
showHarborSheet(
  context,
  routeSettings: const RouteSettings(name: 'reply'),
  barrierLabel: localizations.modalBarrierDismissLabel,
  barrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
  semanticLabel: localizations.dialogLabel,          // on iOS Material leaves it unnamed: pass null there
  maxWidth: Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640,
  builder: (_) => HarborSheet(
    contentBuilder: (context, content) => Material( // text fields and ink work in it
      type: MaterialType.transparency,
      textStyle: DefaultTextStyle.of(context).style,
      child: content,
    ),
    clip: const RoundedRectangleBorder(             // a photo at the top keeps the corners
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    dragToClose: true,                              // drag it down to close
    surface: const ColoredBox(color: Colors.white),
    body: composer,
  ),
);
```

`dragToClose:` is off by default, where `showModalBottomSheet`'s `enableDrag` is
on, so a Material app that wants its sheets to follow a downward drag turns it on,
as above. With it on, a content-sized sheet follows the
finger down by any part that doesn't scroll, and closes on a fling or when let
go under half shown. A draggable sheet closes at its floor, and its
`HarborSheetExtent(snapSizes:)` are the heights it snaps to (by default its
rest and its ceiling). A fling down on its header from its lowest height goes
to the floor and closes it, as a fling on its list does. `HarborSheetExtent(shouldCloseOnMinExtent: false)` rests at the floor
instead. A draggable sheet opened some other way, by `showModalBottomSheet` or
`showGeneralDialog`, closes that route instead; in a modal bottom sheet give it
`expand: false`, as you would a `DraggableScrollableSheet`, so a tap above it
reaches the barrier.

A draggable sheet takes a `DraggableScrollableController`, so the page or the
sheet's own content can read and move it:

```dart
final DraggableScrollableController comments = DraggableScrollableController();

HarborSheet.draggable(controller: comments, header: title, builder: ...);
comments.animateTo(0.88, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic); // its field took focus
```

Rebuilt with a new `rest` before it is dragged, a sheet moves there, as a
`DraggableScrollableSheet` does with a new `initialChildSize`; after a drag,
move it with the controller.

`sheetAnimationStyle:` takes an `AnimationStyle`, as `showModalBottomSheet`
does: its `duration` and `curve` set how the sheet opens, `reverseDuration` and
`reverseCurve` how it closes, and `AnimationStyle.noAnimation` opens and closes
it at once. A dragged sheet stays under the finger whatever the curve, and
reduced motion still wins.

## The lighthouse

```dart
HarborBeacon(onObscured: (covered) => titleOpacity.value = covered, child: heroTitle);
HarborBeacon(keepInSight: true, child: field);            // re-reveals as the keyboard rises or focus moves in
HarborLighthouseRegion(child: canvas)                     // + HarborBeacon(lift: true, clearance: 80)
HarborLighthouse.reveal(context, clearance: 24);
```

A focused field reveals its own caret, as `EditableText` does. A beacon kept in
sight reveals all of itself: when the keyboard rises, and when focus moves into
it from outside, by a tap or the keyboard's next action. So a field and the
button under it come up together, `clearance` clear of the keyboard.
`onlyWhileFocused: true` keeps the rest of a form's beacons still.

## TV

```dart
MaterialApp(
  builder: (context, child) => HarborScaleModel(
    referenceSize: const Size(1200, 675),
    coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
    child: HarborSea(child: child!),
  ),
);
```

A scale model lays out on a reference screen and scales to fit, re-basing the
real insets into its coordinates. Title-safe is part of the coast, so docks
absorb it and moored content keeps clear of it like any other inset. A rail is
a start dock with a `restingExtent`, and pages choose `HarborFollow.live` (move
with it) or `.resting` (let it open over them).

## The chart

`HarborChartOverlay(child:)` (around `HarborSea` in `MaterialApp.builder`, or
anywhere below it) draws every dock's ground, each harbor's clear
water and the tide. Each dock is labelled with its extent; `labelStyle:` sets
the labels' font, so they read in widget tests and goldens rather than as
`flutter_test`'s boxes. `HarborChart.snapshot(context)` returns the same as data.
In debug and profile builds the `ext.harbor.chart` VM-service extension serves
it as JSON, for tools that drive the app.

The widget inspector and `debugDumpApp` show each harbor widget's settings, as
they do a `SafeArea`'s or a `ListView`'s, leaving out the ones at their
defaults: a `Harbor` lists its docks and buoys, and a dock reads as
`HarborDock.pier(tide: float, debugLabel: "composer")`. The values (`HarborDock`,
`HarborBuoy`, `HarborWake`, `HarborCoast`, `HarborTitleSafe`, `HarborSheetExtent`)
are `Diagnosticable`, so they print the same way in a test failure or a log.

Two fields are reserved and not yet read: `HarborCoastFeature.hinge` (sheets,
dialogs, signals and buoys keep off a hinge through `MediaQuery.displayFeatures`,
not through the coast) and `HarborController.isPort` (signals find their port by
route instead).

## Sea trials

Sea trials are in `harbor_test`, a dev dependency beside harbor
(`flutter pub add dev:harbor_test`). It brings `flutter_test`, which harbor
itself does not depend on.

```dart
import 'package:harbor_test/harbor_test.dart';

testWidgets('the composer rides the keyboard', (tester) async {
  final trial = await tester.pumpSeaTrial(app, device: HarborTrialDevice.androidThreeButton);
  await trial.raiseTide();
  expect(tester.getRect(find.byType(Composer)).bottom, trial.waterline);
});
```

`raiseTide()` pumps 600 ms, long enough for the harbor to follow;
`raiseTide(pumpFor: Duration.zero)` stops at the first frame after the keyboard
arrives, and `settle: true` pumps until nothing is animating.

Devices: `iPhone17`, `iPhoneSE`, `androidThreeButton`, `androidGesture`,
`iPhone17Landscape`, `foldableOpen` (a flat fold), `dualScreenCover`,
`dualScreenOpen` (a hinge), `television`, plus the `phones` and `all` lists.
`device.displayFeatures` puts a device's folds and hinges on the view. `trial.clearWaterAround(finder)` and `isInClearWater`
assert where something sits relative to everything in the way, not to a number.

`package:harbor/testing.dart`, where sea trials used to be, is now empty and
deprecated: importing it points to `harbor_test`. It will be removed in a later release.

## Example

`example/` is a small harbor game that exercises every pattern above. Toggle
the chart in its Harbor Office to see the layers.

The video at the top of this page is `example/lib/showcase/`: run it with
`fvm flutter run -t lib/showcase_main.dart`. `example/tool/render_showcase.sh`
records it frame by frame on the test clock, so it comes out the same every
time, and `example/test/showcase_test.dart` checks each caption against the
real page on the phone.

The video is narrated. `example/tool/narrate.py` voices each line of
`example/lib/showcase/narration.tsv`, times every word, and checks that each
clip says what the script says. The showcase's timeline is built from those
timings, so the keyboard rises as "comes in" is spoken. Chapters the
panorama was not drawn for show the Field Guide's drawing of the real thing,
and each runs a real harbor page on the phone: sheets, dialogs and signals open
on the phone's own navigator as the narrator names them. Narration: the Kokoro-82M
voice `am_liam`, generated on device by Kass.

The **Harbor Field Guide** (the book button on the game's first page, or
`fvm flutter run -t lib/field_guide_main.dart`) has a page for every class,
named as it is in code, with a drawing of the real thing it's named after and a
pretend phone to try it on: its own status bar, home indicator and keyboard, a
tide gauge to drag the keyboard in and out, the class's options, live readings
of `MediaQuery` and the waters, and the code for what's on the phone.

`example/integration_test/play_through_test.dart` plays through every scene on
a real device or simulator, with real insets and the real software keyboard,
taking a screenshot at each step and checking where everything landed:

```sh
cd example
PLAY_SHOTS=build/play fvm flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/play_through_test.dart -d <simulator id>
```

To run it on a phone, copy `example/ios/Flutter/Local.xcconfig.example` to
`Local.xcconfig` (it isn't checked in) and fill in your own team and a bundle ID
you own: the example ships as `com.example.harborExample`, which Apple won't sign.

Turn off the simulator's hardware keyboard first (I/O ▸ Keyboard ▸ Connect
Hardware Keyboard) so the software keyboard comes up. Screenshots show Flutter's
own surface, so the keyboard itself is not in them.

The field guide's pages are checked by widget tests (`example/test/field_guide_*_test.dart`):
each page's options are set one by one and where things land is measured on its pretend phone.
