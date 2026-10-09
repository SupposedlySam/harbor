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

- A **quay** (pronounced "key"): the body stops at it, as at `Scaffold.appBar`. It is a dock
  built on the shore. It takes its ground, and the body starts where it ends, like a `Column`.
- A **pier**: the body runs under it, as under an app bar with `extendBodyBehindAppBar`. It is a
  dock built out over the water, and the body is told, through `MediaQuery.padding`, how far it
  reaches.

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
| **Float / pilings / dry dock** | How a dock meets the keyboard: rides up on it, stays under it, or keeps its space | `HarborTideStance` |
| **Make way** | Content asking a dock to go dark or withdraw | `HarborMakeWay` |
| **Pontoon** | A dock moored from deep in the tree | `HarborPontoon` |
| **Buoy** | Something afloat in the clear water: a menu, a bubble | `HarborBuoy` |
| **Portal buoy** | A buoy opened from anywhere: a row's menu, a button's popover | `HarborPortalBuoy` |
| **Flare** | A transient buoy: a toast | `HarborFlares.raise` |
| **Breakwater** | A sheet reporting how much of the page it covers | `showHarborSheet(breakwater: true)` |
| **Lighthouse** | Keeps things in sight: reveal, lift, coverage | `HarborLighthouse`, `HarborBeacon` |
| **Scale model** | A fixed reference screen scaled to fit (TV) | `HarborScaleModel` |
| **Chart** | Who holds which edge, at which layer | `HarborChart`, `HarborChartOverlay` |
| **Sea trials** | Widget-test devices and tide control (`harbor_test`) | `pumpSeaTrial` |

### In Flutter's terms

If you know the Flutter widget, this is where to look in harbor, and what is different.

| Harbor | Closest Flutter concept | The difference that matters |
|---|---|---|
| **Sea** | `MaterialApp.builder`: one per app, above the `Navigator`, inside the `ScaffoldMessenger` that `MaterialApp` wraps around the builder's output | It holds the coast, the tide gauge and the flares every route shares. It moves nothing out of the keyboard's way itself |
| **Harbor** | `Scaffold` | Any number of docks on all four edges, each measured. A `Scaffold` has one app bar, capped at its `preferredSize`, and one bottom bar |
| **New port** | A route, which reads the `MediaQuery` from above the `Navigator` | A harbor that is not a new port takes the docks of the harbor around it as part of its coast |
| **Coast** | `MediaQuery.padding` and `viewPadding` | The same insets, read from `MediaQuery`, plus a TV's title-safe band (`HarborCoast.titleSafe`) or a fixed coast (`HarborCoast.fixed`, and `HarborCoast.none` for goldens) |
| **Tide** | `MediaQuery.viewInsets.bottom`; `Scaffold.resizeToAvoidBottomInset` | It adds a phase, a high-water mark, and how much of it still reaches this point (`remaining`). A resizing `Scaffold` moves the whole body; here each dock decides. The keyboard stays in `viewInsets`, never in `padding` |
| **Quay** (`HarborDock.quay`) | `Scaffold.appBar` and `bottomNavigationBar`: the body starts where they end | Measured, never declared, and on any edge: a start dock holds a `NavigationRail` as a `Row` would. Several stack |
| **Pier** (`HarborDock.pier`) | An app bar under `Scaffold(extendBodyBehindAppBar: true)`, a bottom bar under `extendBody: true` | The same mechanism: the body runs under it and its `MediaQuery.padding` says how far. A pier does it on any edge, and for a stack of docks |
| **Wake** | A `ShaderMask` fade, with a `BackdropFilter` frost under the bar | The fade's length counts toward where content rests, so the band and the first row's resting line never drift apart |
| **Moored** | `SafeArea` | `SafeArea` reads `MediaQuery.padding` alone, so it misses the keyboard. A moored widget keeps clear of it at the bottom too, can clear the coast alone (`clear:`) or the docks at rest (`follow:`), and takes directional edges. Both cast off what they cleared, and `minimum:` is a floor on both |
| **Mooring line** | Horizontal page padding: a `Padding` on each row | It adds whatever is in the way on the sides (a side cutout, a rail) to the harbor's margin, and only the rows that ask get it, so the list itself still runs to the frame's edge |
| **Fairway** | `ListView`, `CustomScrollView` | A `ListView` with no `padding` pads its ends by `MediaQuery.padding` but not by the keyboard, and a `CustomScrollView` pads nothing. A fairway clears both ends, keyboard included, and widens every reveal by what covers its edges. `HarborFairwaySliver` is the `SliverSafeArea` of a scroll view you build yourself |
| **Pinned header** (`HarborSliverDock`) | `PinnedHeaderSliver`, `SliverAppBar(pinned: true)` | It pins at the docks' face rather than the viewport's edge, several stack, and reveals keep clear of it |
| **Open water** | Content outside any `SafeArea` that reads `MediaQuery.padding` itself | `waters` splits each edge into coast and docks, which `MediaQuery.padding` adds together |
| **Cast off** (`HarborCastOff`) | `MediaQuery.removePadding` | `removePadding` lowers `viewPadding` only by the padding it removes; a cast-off zeroes it, and with `tide:` the keyboard, and zeroes harbor's own waters, so harbor widgets beneath read zero too |
| **Float / pilings** | Float: the bottom of a resizing `Scaffold`'s body. Pilings: `Scaffold.bottomNavigationBar`, which the keyboard covers | Chosen per dock, so a composer can float while the tab bar under it stays on pilings |
| **Dry dock** | None | It reserves the keyboard's height whether the keyboard is up or not, so a panel can trade places with it and nothing moves |
| **Make way** | Rebuilding the `Scaffold` without its `bottomNavigationBar` | Asked for from deep in the page and counted. `HarborYield.dark` keeps the dock's ground as `Visibility(maintainSize: true)` does; `HarborYield.withdraw` slides it out and gives the ground back |
| **Pontoon** | `ScaffoldState.showBottomSheet`, which puts a widget into an ancestor's frame from deep in the tree | A pontoon is a dock: it takes its ground (or the body sails under it), and leaves with the widget that added it |
| **Buoy** | `Scaffold.floatingActionButton`; a `Stack` with `Positioned` | It sits in the clear water, so it clears the coast, every dock and the keyboard. A `modal` buoy has a barrier, as `ModalBarrier` does, but it is not a route, so keyboard focus is not trapped |
| **Portal buoy** | `OverlayPortal` (it is one), as `MenuAnchor` and `RawMenuAnchor` use | Placement only: it keeps the buoy in the clear water and flips it when its side has no room. It brings no menu semantics, keyboard navigation or tap-outside dismissal; your `controller` opens and closes it |
| **Flare** | `SnackBar`, through `ScaffoldMessenger.showSnackBar` | Flares at one slot take turns, as snack bars do, and a flare's time counts only while it is in sight; flares at different slots show together. It builds any widget, at one of four heights (`HarborFlareSlot`), clear of the docks of the page that raised it. Both are live regions |
| **Sheet** (`showHarborSheet`) | `showModalBottomSheet`; `HarborSheet.draggable` is built on `DraggableScrollableSheet`; `barrier: HarborSheetBarrier.none` is `showBottomSheet` | Its header and footer are docks, so the body sails under the header and the footer floats on the keyboard. harbor imports no Material, so a Material app passes in its theme's pieces ([Sheets and dialogs](#sheets-and-dialogs)) |
| **Breakwater** | None | A `Scaffold` lifts its floating action button over a bottom sheet but leaves the body under it. A breakwater sheet tells the page that opened it how far it covers, and the page's content keeps clear |
| **Lighthouse** | `Scrollable.ensureVisible`, `RenderObject.showOnScreen`, `TextField.scrollPadding` | A reveal clears the docks and the keyboard of every fairway it passes through. `HarborBeacon(onObscured:)`, how much of a widget the header covers, and `HarborLighthouseRegion`, lifting content that does not scroll, have no Flutter equivalent |
| **Scale model** | A `FittedBox` around a `MediaQuery` with a fixed `size` | The real screen's insets are re-based into the model's coordinates. Under a bare `FittedBox`, content still reads the real screen's `MediaQuery` |
| **Chart** | `debugPaintSizeEnabled` | It draws who holds each edge, at which layer, and the clear water, and serves the same as data (`HarborChart.snapshot`) |
| **Sea trials** | `tester.view.padding`, `viewPadding` and `viewInsets`, set with `FakeViewPadding` | Devices come with their status bar, home indicator, keyboard height and folds already set, and assertions are about the clear water, not numbers |

Two names end in *State* without being a `State`: `HarborTideState` is an immutable snapshot
of the keyboard, as `MediaQueryData` is, and `HarborDockState` is an enum, as `AnimationStatus` is.

**Pronouncing them:** a **quay** is pronounced "key", as harbours have always said it.
A **buoy** is pronounced "BOO-ee" in American English and "boy" in British; both are right.

## Getting started

Mount the sea once, above your `Navigator`:

```dart
MaterialApp(
  builder: (context, child) => HarborSea(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: child!,
  ),
  home: const InboxPage(),
);
```

Every inset harbor takes (a margin, a minimum, a fairway's padding, a fixed
coast) is an `EdgeInsetsGeometry`, as `Padding`'s is: `EdgeInsets` keeps to the
side it names, and `EdgeInsetsDirectional` follows the reading direction.

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
HarborDock.pier(child: header)          // the body runs under it (extendBodyBehindAppBar)
HarborDock.quay(child: tabBar)          // the body stops at it (Scaffold.appBar)
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
| `tide: HarborTideStance.float` | Rides up on the keyboard, staying on top of it: a composer, a sheet's footer. It sits on the home indicator until the keyboard is taller than it, so it never dips |
| `tide: HarborTideStance.pilings` | Stays put; the keyboard covers it: a tab bar (the default) |
| `tide: HarborTideStance.dryDock` | Keeps the keyboard's space whether the keyboard is up or down, so nothing moves: a styling panel. It holds that ground at high-water height either way, so its child's `HarborDryDock` fills that ground when the keyboard is down. It runs to the screen's edge: no coast, no minimum |
| `state: HarborDockState.dark` | Not drawn and not tappable, but it keeps its ground |
| `state: HarborDockState.withdrawn` | Slides out and gives its ground back |
| `extentPolicy:` | How a withdrawing dock gives its ground back: `hold` (once it's gone, the default), `follow`, `release` |
| `animationStyle:` | How it moves, as `AnimationStyle` sets it on Flutter's routes: `duration` and `curve` to return or light up, `reverseDuration` and `reverseCurve` to withdraw or go dark, `AnimationStyle.noAnimation` for none. It overrides `duration:` and `curve:` |
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

A fairway takes the rest of a `CustomScrollView`'s parameters, with the same
names and defaults (the box form those of a `SingleChildScrollView`):
`restorationId:` brings its scroll position back after the app is restarted, and
`keyboardDismissBehavior:` left unset follows the app's `ScrollBehavior`. With a
`center:`, both ends of the scroll still rest clear of the docks, and the center
sliver starts clear of the leading ones. `anchor:` is the one that reads
differently: it is a fraction of the water between the docks, not of the
viewport that runs under them, so `anchor: 1` puts the center on a composer's
face and lifts it with the keyboard.

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
by keyboard focus and by screen readers, not only by taps, and a buoy whose
anchor is not in the tree is not read out. Flares are live
regions, so screen readers announce them, with a dismiss action that lowers
them, as a `SnackBar` is. A flare whose widget is already its own live region
(a `SnackBar`-like widget from your design library) is raised with
`liveRegion: false`, so harbor adds no second, unlabelled one around it. A
flare with a button is raised with `persist: true`, as a `SnackBar` with an
action persists, so it is still there when a screen reader reaches it. Sheets and flares keep the themes of
the page they came from, and so do dialogs. With reduced motion
(`MediaQuery.disableAnimations`) docks, flares, sheets and dialogs appear and
leave without moving, and the lighthouse's reveals and lifts jump into place. On iOS a tap on the
status bar scrolls a harbor page to the top, as it does under a `Scaffold`, and
as there only the page whose status bar band is on top at the screen's top left:
a page under a route in an outer navigator, under an overlay, or in the
right-hand pane of a split stays where it is.

## Talking to the harbor

```dart
HarborMakeWay(edge: HarborEdge.bottom, mode: HarborYield.withdraw, child: panel)
HarborPontoon(edge: HarborEdge.bottom, dock: HarborDock.pier(child: unsavedBar), child: form)
Harbor.of(context).makeWay(HarborEdge.top, mode: HarborYield.dark) // returns a claim; release() it
```

`Harbor.of(context)` is the nearest harbor's handle, as `Scaffold.of` is the
nearest `ScaffoldState`. It throws a `FlutterError` when there is no harbor
above the context, in release builds too, as `Scaffold.of` does;
`Harbor.maybeOf` returns null instead. The harbor makes its handle and runs
its lifecycle, so the handle carries only what content asks of it: claims,
pontoons, breakwaters and the clear water. Claims are counted and go to the
nearest harbor that has a dock on that edge. A pontoon joins the harbor's
docks on the next frame; one added by hand with `addPontoon` returns a
`HarborPontoonHandle` to update or remove it by.

## Buoys and flares

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

HarborFlares.raise(context, slot: HarborFlareSlot.low, builder: (_) => Toast('Saved'));
HarborFlares.raise(context, alignment: const Alignment(0, -0.8), builder: (_) => Toast('Saved'));
final undo = HarborFlares.raise(context, persist: true, builder: (_) => UndoToast(onUndo: restore));
final HarborFlareClosedReason why = await undo.closed;    // lower, dismiss, timeout or remove
HarborFlares.raise(
  context,
  transitionBuilder: (context, animation, child) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
    child: child,
  ),
  builder: (_) => Toast('Saved'),
);
```

Buoys float in the **clear water**: the rectangle no coast, dock or tide covers.
An anchored buoy sits on its `side` of its anchor; `start` and `end` are in
reading order, as in `AlignmentDirectional`, so `start` is on the right under
right-to-left. (`before` and `after`, their names until 0.2.0, still work and are
deprecated.) Across that side it is centred on its anchor unless its
`crossAlignment` says `start` or `end`, the anchor's edges in reading order (or
its top and bottom beside it), as a dropdown lines up under its button's leading
edge; `crossOffset` moves it on from there, toward the reading end. While its
anchor is not in the tree, an anchored buoy is not shown, takes no taps and is
not read out by screen readers. It is placed again in every frame that is drawn,
so it moves with its anchor in the same frame, a row scrolling under an open
menu included. A `HarborAnchor` refers to one `HarborAnchorPoint`, so give each
row of a list its own; in debug builds two points left on one anchor are
reported after the frame, as two leaders on one `LayerLink` are.
`alignment` and `margin` take directional values, so `AlignmentDirectional.bottomEnd`
puts a button where a right-to-left reader expects it.
A `modal` buoy is modal: a barrier (clear unless you give it a `barrierColor`)
keeps taps off the page and its docks and tells screen readers to leave them
alone, a tap beside the buoy, back or Escape calls its `onDismiss`, and the buoys
listed before it are hidden while it is up. Its `barrierLabel` ('Dismiss' when
none is given) is what a screen reader announces for the barrier; a Material app
passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`. It holds
keyboard focus as a dialog does: it takes focus when it opens, Tab goes round
inside it and the arrow keys (a TV remote's D-pad) stop at its edges, and focus
goes back to where it was when it closes. `requestFocus: false` leaves focus on
the page, as it does for a route; Escape from there still closes the buoy, unless
focus is on a page of a `Navigator` nested in the harbor's body, whose route
answers Escape before the harbor does.
A flare is raised at a slot (`top`, `high`, `middle`, `low`) or at an exact
`alignment`, placed as a buoy at that alignment would be. An
`AlignmentDirectional` follows the reading direction of the page that raised it.
It fades and scales in over `animationStyle` (220 ms each way by default).
A `transitionBuilder` brings your own entrance and exit, run on harbor's
animation, and `AnimationStyle.noAnimation` shows a widget that animates
itself as it is, as `showSnackBar(snackBarAnimationStyle:)` does. A lowered
flare stays at least 300 ms, so its own exit can run.
A flare goes to the port on top (a sheet over a page over the sea), so a `low`
flare clears that sheet's footer, and it also stays clear of the docks of the
harbor it was raised from (a tab's own header). If its harbor leaves, the
flare moves to the one now on top.

Flares raised at the same slot or alignment of one port take turns, as a
`ScaffoldMessenger` shows its snack bars: the next comes in once the one before
it has run its exit, so "Copied" tapped twice is never drawn over itself. To
replace the flare that is up, `lower()` it; one lowered while it waits leaves
without being shown. Flares at different slots show together. `closed`
completes once a flare has left, with why.

A flare stays 4 s, as a `SnackBar` does, and its `duration` counts only while it
is in sight: from the end of its entrance, and not while another route covers
its page (the time starts over when that route leaves). `persist: true` keeps it
up until it is lowered, as `SnackBar(persist:)` does. Give it to a flare with a
button, an Undo: a screen-reader user moving through the page needs longer than
4 s to reach it.

A flare raised with no harbor above it (a widget test that pumps a bare
`MaterialApp`, a preview, a screen not yet built from a harbor) still shows: it
goes to the nearest `Overlay`, at its slot and clear of `MediaQuery.padding` and
`viewInsets`. With no overlay either, it is reported through
`FlutterError.reportError`, in release builds too. A flare's timers stop when it
is lowered or when nothing is left to show it, so a test that ends with one up
has no timer pending.

Flares were called signals until 0.3.0. The old names (`HarborSignals`,
`HarborSignalSlot`, `HarborSignalEntry` and the rest) still work and are
deprecated; they go at 1.0.

```dart
final menu = OverlayPortalController();

HarborPortalBuoy(                       // in a list row, anywhere below a harbor
  controller: menu,
  side: HarborBuoySide.below,
  crossAlignment: HarborBuoyCrossAlignment.start, // under the row's leading edge
  onDismiss: menu.hide,                   // a tap outside, Escape or back
  consumeOutsideTaps: true,               // and that tap presses nothing else
  buoyBuilder: (context) => const RowMenu(),
  child: GestureDetector(onTap: menu.toggle, child: row),
)
```

A **portal buoy** is an anchored buoy opened from where it is used rather than
listed in `Harbor.buoys`: a menu from a list row, a popover from a button in
another package. It is an `OverlayPortal`, so its buoy builds with the row's
themes and floats in the nearest `Overlay`, placed in the clear water of the
harbor around the row by its `child` (or by an `anchor`). Until that anchor is
in the tree, it is not shown, takes no taps and is not read out. When its `side` has
no room, it `flips` to the other side of the anchor, so a menu from a row just
above the tab bar or the keyboard opens above the row; when neither side has
room, it is held inside the clear water. `HarborPortalBuoy.sideOf(context)` in
the buoy is the side it landed on, so a popover can point its arrow at the
anchor after a flip. The buoy is placed as it paints, so it hears of a flip on
the next frame.

With an `onDismiss`, a portal buoy closes as a `MenuAnchor` does: its buoy and
its `child` are one `TapRegion` group, so a tap outside both calls `onDismiss`
while a tap on the row that opened it is left to the row, and so do Escape with
focus in either and back (before it reaches the page). The tap goes on to what
is under it, as a `MenuAnchor`'s does, unless `consumeOutsideTaps` is set. It
puts up no barrier and leaves the page to screen readers, as a menu does. So in
a modal buoy, a tap on the barrier while the portal buoy is open calls both
`onDismiss`es, and in a dialog it calls the portal buoy's and closes the
dialog, as it does with a `MenuAnchor` open in a dialog.

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
and flares and buoys keep to the screen that holds them, never across the hinge.
A flat fold, which has no width, may still be spanned.

A sheet with `barrier: HarborSheetBarrier.none` is not a route of its own, so
it is tied to the page that opened it: back (and a pop) closes it before the
page, the iOS back swipe stands aside while it is up, it hides while another
page is on top (from the first frame of that page's push until its pop has
finished, since the sheet is drawn above every page rather than inside its
own), and it leaves when its page is replaced or removed. Escape closes it as
back does, from focus in the sheet or in a harbor on its page, and is left to
the widgets above while no such sheet is up. It is not modal, as a persistent
bottom sheet is not: it is a focus scope of its own, as a route is, so Tab goes
through the sheet in order and then on to the page, and it leaves focus where it
was when it opens unless you pass `requestFocus: true`. Then focus goes back to
the page when it closes. A
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
screen reader announces for the barrier ('Dismiss' when none is given), with
`barrierOnTapHint:` saying what tapping it does. Like a modal bottom sheet, the
sheet is a semantics scope of its own, and screen readers announce its
`semanticLabel:` as it opens. The barrier's semantics end at the sheet's top, as
a modal bottom sheet's do, and follow it as it slides or is dragged, so touch
exploration over the sheet finds its content rather than the barrier. It spans
the screen unless you give it a `maxWidth`.

A dialog is a popup route, as one from `showDialog` is: a `Hero` does not fly
into it, an observer of page routes does not count it as a screen, a draggable sheet
inside it closes it, and its content is a route of its own for screen readers, named by `semanticLabel:`. It
takes `showDialog`'s route options: `routeSettings:`, `barrierLabel:` ('Dismiss'
when none is given), `anchorPoint:` (which screen of a dual-screen
device it opens on), `traversalEdgeBehavior:`, `requestFocus:` and
`animationStyle:` (its fade, 180 ms by default).

Three more options are named and behave as `showModalBottomSheet`'s. `isDismissible: false`
makes a sheet the user has to answer: a tap on the barrier does nothing, and
back still closes it. `requestFocus: false` leaves focus in the page.
`anchorPoint:` picks which screen of a dual-screen device it opens on.

What harbor draws on its own is drawn as the widgets layer draws it, with no
theme: sheet and dialog barriers are `showGeneralDialog`'s half-black
(`0x80000000`), and a hairline wake is a translucent black (`0x1F000000`), a
shade of whatever bar it is on, as `BorderSide`'s default is black; a dark bar
passes its own `color:`. Every barrier harbor puts up is announced with the
label it is given and otherwise with 'Dismiss', the English that Material and
Cupertino fall back to, since `WidgetsLocalizations` has none to offer.

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

A region lifts over 280 ms and settles back the same way. Give it an
`animationStyle:` to change that: its `duration` and `curve` are for the lift,
its `reverseDuration` and `reverseCurve` for settling back, and
`AnimationStyle.noAnimation` moves the content at once.

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
`flutter_test`'s boxes. `HarborChart.snapshot(context)` returns the same as data,
and `HarborChart.nearest(context)` the nearest harbor alone: its frame, body,
clear water and docks in global coordinates, the way a test or a tool reads a
harbor without reaching into it.
In debug and profile builds the `ext.harbor.chart` VM-service extension serves
it as JSON, for tools that drive the app.

The widget inspector and `debugDumpApp` show each harbor widget's settings, as
they do a `SafeArea`'s or a `ListView`'s, leaving out the ones at their
defaults: a `Harbor` lists its docks and buoys, and a dock reads as
`HarborDock.pier(tide: float, debugLabel: "composer")`. The values (`HarborDock`,
`HarborBuoy`, `HarborWake`, `HarborCoast`, `HarborTitleSafe`, `HarborSheetExtent`)
are `Diagnosticable`, so they print the same way in a test failure or a log.

Two fields are reserved and not yet read: `HarborCoastFeature.hinge` (sheets,
dialogs, flares and buoys keep off a hinge through `MediaQuery.displayFeatures`,
not through the coast) and `HarborController.isPort` (flares find their port by
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
Each device goes on the view at its own `devicePixelRatio`, and
`device.displayFeatures` puts its folds and hinges there.
`pumpSeaTrial(textScaleFactor:)` grows the system text size, so docks are
measured at the size their text grew to. `trial.clearWaterAround(finder)` and `isInClearWater`
assert where something sits relative to everything in the way, not to a number.
`trial.docksAround(finder)` lists the docks of the harbor around a widget. Both
read `HarborChart.nearest`, so a test of your own can too.

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
and each runs a real harbor page on the phone: sheets, dialogs and flares open
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
