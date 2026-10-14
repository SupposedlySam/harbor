# harbor

Every edge of the screen, claimed once.

Every screen is a rectangle, and something is always pushing in from its
edges: the status bar, the home indicator, a notch, a TV's overscan, the
keyboard, and your own headers, tab bars and composers. `harbor` gives each of
them a place and a rule, so your content stops doing inset arithmetic.

> **Every edge of the screen is claimed once, by the layer that owns it, and
> everything inside gets what is left.** The platform claims the system edges
> and the keyboard, your bars claim theirs, and your content gets the room.

[![The harbour illustration beside a phone running harbor. An overlay bar, drawn as a pier, is the header rows scroll under; a solid bar, drawn as a quay, is the tab bar the list stops at.](https://raw.githubusercontent.com/SupposedlySam/harbor/main/doc/media/showcase.gif)](https://cdn.jsdelivr.net/gh/SupposedlySam/harbor@main/doc/media/showcase.mp4)

*Left, the harbour illustration. Right, a phone running the real package, driven by the same
clock. The GIF is the opening; [the narrated video](https://cdn.jsdelivr.net/gh/SupposedlySam/harbor@main/doc/media/showcase.mp4)
(three and a half minutes) tours everything in the package on a phone, from the system edges to
widget-test trials.
[The wide-format video](https://cdn.jsdelivr.net/gh/SupposedlySam/harbor@main/doc/media/showcase_wide.mp4)
(one minute) shows what changes on other screens: a rail on a tablet, right-to-left, a
phone on its side, a dual-screen hinge, and a television's title-safe band.*

**[Try every class in your browser](https://supposedlysam.github.io/harbor/):** the Harbor
Field Guide, with a pretend phone for each class, its options, and a gauge to bring the
keyboard in and out.

Depends on the Flutter SDK only. Trials for widget tests come in a package
of their own, `harbor_test`, so the test framework stays out of your app's
dependencies.

## Installing

```sh
flutter pub add harbor
flutter pub add dev:harbor_test   # trials, for widget tests
```

MIT licensed.

## Renamed in 0.9

0.9 renames the API after the model above; the 0.8 names still work, deprecated until 1.0, and
`dart fix --apply` followed by `dart format` migrates your code. The main renames:

| 0.8 | 0.9 |
|---|---|
| `HarborSea` | `HarborRoot` |
| `Harbor` | `HarborFrame` |
| `Harbor(newPort: true)` | `HarborFrame(isPage: true)`, which `dart fix` writes; `HarborFrame.page(...)` says the same and reads better |
| `HarborDock.pier` / `.quay` / `.reserve` | `HarborBar.overlay` / `.solid` / `.reserve` |
| `HarborDockState`, `HarborDockKind.pier` / `.quay` | `HarborBarState`, `HarborBarKind.overlay` / `.solid` |
| `HarborCoast`, `coast:` | `HarborSystemEdges`, `systemEdges:` |
| `HarborCoastStance` | `HarborSystemEdgeStance` |
| `HarborTide.of` / `.isInOf` | `HarborKeyboard.of` / `.isShownOf` |
| `HarborTideState.highWater` / `.isIn` | `HarborKeyboardState.settledHeight` / `.isShown` |
| `HarborTideStance.float` / `.pilings` / `.dryDock`, a bar's `tide:` | `HarborKeyboardStance.rides` / `.stays` / `.reserves`, a bar's `keyboard:` |
| `tide:` on `HarborMoored`, `HarborFairway`, `HarborFairwaySliver`, `HarborCastOff`, `paddingOf` | `clearsKeyboard:` |
| `bars:` (0.8.0) on the same, and `HarborCastOff(docks:)` | `clearsBars:` |
| `HarborDryDock(showsChildAtHighTide:)`, `HarborTideSource` | `HarborKeyboardSpace(showsChildWithKeyboard:)`, `HarborKeyboardSource` |
| `bodyClearsTide:` | `bodyClearsKeyboard:` |
| `HarborWake`, `wake:` | `HarborEdgeEffect`, `edgeEffect:` (`edgeEffects:` on a scroll view) |
| `HarborWakeMask(wakes:)`, `.alphaWake`, `wakePainter:` | `HarborFadeMask(bands:)`, `.alphaFade`, `edgeEffectPainter:` |
| `HarborWatersData.wakes` / `.wakeOf`, `HarborWakeBand` | `HarborRoomData.fadeBands` / `.fadeBandOf`, `HarborFadeBand` |
| `HarborController.clearWater` | `HarborController.room` |
| `HarborWaters`, `HarborWatersData` | `HarborRoom`, `HarborRoomData` |
| `HarborWaters.dockFaceOf` / `.steadyCoastOf` | `HarborRoom.barFaceOf` / `.steadySystemEdgeOf` |
| `HarborMoored` | `HarborClear` |
| `HarborMooringLine`, `mooringLine:` | `HarborClear.rowInsets(child:)`, `rowInsets:` |
| `HarborCastOff` | `HarborHandled` |
| `HarborFairway(startsInOpenWater:)`, `HarborFairwaySliver` | `HarborScrollView(startsUnderBars:)`, `HarborSliverClear` |
| `HarborSliverDock` | `HarborSliverBar` |
| `HarborOpenWater(builder:)` | a `Builder` and `HarborRoom.of(context)` |
| `HarborMakeWay`, `makeWay` | `HarborHideBar`, `hideBar` |
| `HarborPontoon(dock:)`, `addPontoon` | `HarborAttachedBar(bar:)`, `attachBar` |
| `HarborBuoy`, `buoys:` | `HarborFloat`, `floats:` |
| `HarborPortalBuoy(buoyBuilder:)` | `HarborPopover(popoverBuilder:)` |
| `HarborFlares.raise`, `entry.lower()` | `HarborToasts.show`, `entry.hide()` |
| `HarborFlareSlot`, `HarborFlareEntry`, `HarborFlareTarget.sea` | `HarborToastSlot`, `HarborToastEntry`, `HarborToastTarget.root` |
| `showHarborSheet(breakwater:, keepsTopCoast:)` | `showHarborSheet(coversPage:, reachesTop:)` |
| `showHarborDialog(inheritClearWater:)` | `showHarborDialog(inheritRoom:)` |
| `HarborBeacon`, `HarborLighthouse`, `HarborLighthouseRegion` | `HarborKeepInSight`, `HarborKeepInSightRegion` |
| `HarborChart`, `HarborChartOverlay` | `HarborInspector`, `HarborInspectorOverlay` |
| `HarborFleet`, `HarborFleetObserver`, `controller.fleet` | `HarborFrameRegistry`, `HarborFrameObserver`, `controller.registry` |
| `HarborScaleModel` | `HarborScaledScreen` |
| `pumpSeaTrial`, `raiseTide()`, `waterline`, `isInClearWater` | `pumpHarborTrial`, `showKeyboard()`, `keyboardTop`, `isInRoom` |

`HarborOpenWater` is retired rather than renamed, and has no automatic fix. The `HarborClear`
enum is removed so the widget can take its name: `clear: HarborClear.coast` is
`clearsBars: false`, and `HarborClear.everything` was the default. `HarborMooringLine(child:)`
becomes `HarborClear.rowInsets(child:)`, which builds a `HarborClear`, so a test that found rows
with `find.byType(HarborMooringLine)` finds none after the fix: give the row a `Key`, or find it
with `find.byWidgetPredicate((w) => w is HarborClear && w.rowInsets)`. The complete table, every
member and parameter, is [`doc/design/naming.md`](doc/design/naming.md); the CHANGELOG lists the
names not renamed yet.

## The one rule

A frame has layers: the **body** (your content) at the bottom, **bars** above it, **floats,
popovers and toasts** above those, and the **edges** (the system edges and the keyboard) above
everything. A system edge is an inset *at* an edge of the frame (the status bar at the top);
`HarborEdge` is the side of the frame itself.

**Something on the same layer takes space. Something on a higher layer becomes
padding for everything beneath it.**

- A **solid bar** (`HarborBar.solid`): the body stops at it, as at `Scaffold.appBar`. It sits
  beside the body rather than over it, so it takes its space and the body starts where it ends,
  like a `Column`.
- An **overlay bar** (`HarborBar.overlay`): the body runs under it, as under an app bar with
  `extendBodyBehindAppBar`, and the body is told, through `MediaQuery.padding`, how far it
  reaches.

That's the whole difference between a header your list scrolls under and a
header your list starts below. What no edge and no bar covers is the **room**.
`HarborRoom.of(context)` describes what bounds the room at a point in the tree: how far the
system edges, the bars and their fades reach in on each edge, and the margin.

### In Flutter's terms

Where harbor resembles a Flutter widget, this is what is different.

| harbor | Closest Flutter concept | The difference that matters |
|---|---|---|
| `HarborRoot` | `MaterialApp.builder`: one per app, above the `Navigator`, inside the `ScaffoldMessenger` that `MaterialApp` wraps around the builder's output | It holds the system edges, the keyboard reading and the toasts every route shares. It moves nothing out of the keyboard's way itself |
| `HarborFrame` | `Scaffold` | Any number of bars on all four edges, each measured. A `Scaffold` has one app bar, capped at its `preferredSize`, and one bottom bar |
| `HarborFrame.page` | A route, which reads the `MediaQuery` from above the `Navigator` | A frame that does not start a page takes the bars of the frame around it as part of its system edges |
| `HarborSystemEdges` | `MediaQuery.padding` and `viewPadding` | The same insets, read from `MediaQuery`, plus a TV's title-safe band (`HarborSystemEdges.titleSafe`) or fixed edges (`HarborSystemEdges.fixed`, and `HarborSystemEdges.none` for goldens) |
| `HarborKeyboard` | `MediaQuery.viewInsets.bottom`; `Scaffold.resizeToAvoidBottomInset` | It adds a phase, a settled height, and how much of it still reaches this point (`remaining`). A resizing `Scaffold` moves the whole body; here each bar decides. The keyboard stays in `viewInsets`, never in `padding` |
| `HarborBar.solid` | `Scaffold.appBar` and `bottomNavigationBar`: the body starts where they end | Measured rather than declared, and on any edge: a start bar holds a `NavigationRail` as a `Row` would. Several stack |
| `HarborBar.overlay` | An app bar under `Scaffold(extendBodyBehindAppBar: true)`, a bottom bar under `extendBody: true` | The same mechanism: the body runs under it and its `MediaQuery.padding` says how far. An overlay bar does it on any edge, and for a stack of bars |
| `HarborEdgeEffect` | A `ShaderMask` fade, with a `BackdropFilter` frost under the bar | The fade's length counts toward where content rests, so the band and the first row's resting line never drift apart |
| `HarborClear` | `SafeArea` | `SafeArea` reads `MediaQuery.padding` alone, so it misses the keyboard. `HarborClear` keeps clear of it at the bottom too, can clear the system edges alone (`clearsBars: false`) or the bars at rest (`follow:`), and takes directional edges. Both mark what they cleared as handled, and `minimum:` is a floor on both |
| `HarborClear.rowInsets` | Horizontal page padding: a `Padding` on each row | It adds whatever is in the way on the sides (a side cutout, a rail) to the frame's margin, and only the rows that ask get it, so the list itself still runs to the frame's edge |
| `HarborScrollView` | `ListView`, `CustomScrollView` | A `ListView` with no `padding` pads its ends by `MediaQuery.padding` but not by the keyboard, and a `CustomScrollView` pads nothing. A `HarborScrollView` clears both ends, keyboard included (unless `clearsKeyboard: false`), and widens every reveal by what covers its edges. `HarborSliverClear` is the `SliverSafeArea` of a scroll view you build yourself |
| `HarborSliverBar` | `PinnedHeaderSliver`, `SliverAppBar(pinned: true)` | It pins at the bars' face rather than the viewport's edge, several stack, and reveals keep clear of it |
| `HarborRoom.of(context)` | Content outside any `SafeArea` that reads `MediaQuery.padding` itself | The room data splits each edge into system edges and bars, which `MediaQuery.padding` adds together |
| `HarborHandled` | `MediaQuery.removePadding` | `removePadding` lowers `viewPadding` only by the padding it removes; `HarborHandled` zeroes it, and with `clearsKeyboard:` the keyboard, and zeroes harbor's own room data, so harbor widgets beneath read zero too. `clearsBars: false` handles the system edges alone and leaves the bars, which `removePadding` cannot tell apart |
| `HarborKeyboardStance.rides` / `.stays` | Rides: the bottom of a resizing `Scaffold`'s body. Stays: `Scaffold.bottomNavigationBar`, which the keyboard covers | Chosen per bar, so a composer can ride the keyboard while the tab bar under it stays |
| `HarborKeyboardStance.reserves` | None | It reserves the keyboard's height whether the keyboard is up or not, so a panel can trade places with it and nothing moves |
| `HarborHideBar` | Rebuilding the `Scaffold` without its `bottomNavigationBar` | Asked for from deep in the page and counted. `HarborYield.dark` keeps the bar's space as `Visibility(maintainSize: true)` does; `HarborYield.withdraw` slides it out and gives the space back |
| `HarborAttachedBar` | `ScaffoldState.showBottomSheet`, which puts a widget into an ancestor's frame from deep in the tree | An attached bar is a bar: it takes its space (or the body runs under it), and leaves with the widget that added it |
| `HarborFloat` | `Scaffold.floatingActionButton`; a `Stack` with `Positioned` | It sits in the room, so it clears the system edges, every bar and the keyboard. A `modal` float has a barrier, as `ModalBarrier` does, but it is not a route, so keyboard focus is not trapped |
| `HarborPopover` | `OverlayPortal` (it is one), as `MenuAnchor` and `RawMenuAnchor` use | Placement only: it keeps the popover in the room and flips it when its side has no room. It brings no menu semantics, keyboard navigation or tap-outside dismissal; your `controller` opens and closes it |
| `HarborToasts.show` | `SnackBar`, through `ScaffoldMessenger.showSnackBar` | Toasts at one slot take turns, as snack bars do, and a toast's time counts only while it is in sight; toasts at different slots show together. It builds any widget, at one of four heights (`HarborToastSlot`), clear of the bars of the page that showed it. Both are live regions |
| `showHarborSheet` | `showModalBottomSheet`; `HarborSheet.draggable` is built on `DraggableScrollableSheet`; `barrier: HarborSheetBarrier.none` is `showBottomSheet` | Its header and footer are bars, so the body runs under the header and the footer rides the keyboard. harbor imports no Material, so a Material app passes in its theme's pieces ([Sheets and dialogs](#sheets-and-dialogs)) |
| `showHarborSheet(coversPage: true)` | None | A `Scaffold` lifts its floating action button over a bottom sheet but leaves the body under it. A sheet that covers the page tells the page that opened it how far it covers, and the page's content keeps clear |
| `HarborKeepInSight` | `Scrollable.ensureVisible`, `RenderObject.showOnScreen`, `TextField.scrollPadding` | A reveal clears the bars and the keyboard of every `HarborScrollView` it passes through. `HarborKeepInSight(onObscured:)`, how much of a widget the header covers, and `HarborKeepInSightRegion`, lifting content that does not scroll, have no Flutter equivalent |
| `HarborScaledScreen` | A `FittedBox` around a `MediaQuery` with a fixed `size` | The real screen's insets are re-based into the reference screen's coordinates. Under a bare `FittedBox`, content still reads the real screen's `MediaQuery` |
| `HarborInspector` | `debugPaintSizeEnabled` | It draws who holds each edge, at which layer, and the room, and serves the same as data (`HarborInspector.snapshot`) |
| `pumpHarborTrial` | `tester.view.padding`, `viewPadding` and `viewInsets`, set with `FakeViewPadding` | Devices come with their status bar, home indicator, keyboard height and folds already set, and assertions are about the room, not numbers |

Two names end in *State* without being a `State`: `HarborKeyboardState` is an immutable snapshot
of the keyboard, as `MediaQueryData` is, and `HarborBarState` is an enum, as `AnimationStatus` is.

## Getting started

Mount the root once, above your `Navigator`:

```dart
import 'package:harbor/harbor.dart';

MaterialApp(
  builder: (context, child) => HarborRoot(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    child: child!,
  ),
  home: const InboxPage(),
);
```

Every inset harbor takes on more than one edge (a frame's margin and minimum,
a scroll view's padding, fixed system edges, a toast's margin) is an `EdgeInsetsGeometry`,
as `Padding`'s is: `EdgeInsets` keeps to the side it names, and
`EdgeInsetsDirectional` follows the reading direction. A bar's `minimum`, for
its one edge, is a number.

Build a page from a frame:

```dart
HarborFrame(
  top: [
    HarborBar.overlay(
      edgeEffect: const HarborEdgeEffect.fade(length: 12, blurSigma: 20),
      child: const InboxHeader(),
    ),
  ],
  bottom: [HarborBar.solid(child: const InboxTabs())],
  body: HarborScrollView(
    slivers: [
      SliverList.builder(
        itemCount: 40,
        itemBuilder: (context, i) => HarborClear.rowInsets(child: MessageRow(i)),
      ),
    ],
  ),
)
```

What each piece does:

- **The header** is an overlay bar. It pads itself below the status bar and frosts the
  content beneath it.
- **The tab bar** is a solid bar. It pads itself above the home indicator, and the body
  ends at its top.
- **The scroll view** runs the full height of the body, under the header. Its first
  row comes to rest past the header's fade, and its last row rests clear of the
  tab bar. Whatever sizes the header and the tab bar laid out at, nobody declared
  a height.
- **The rows** keep the row insets, the 16 margin plus any side cutout. The list
  itself still runs to the frame's edge, so a carousel inside it can too.

## Bars

```dart
HarborBar.overlay(child: header)        // the body runs under it (extendBodyBehindAppBar)
HarborBar.solid(child: tabBar)          // the body stops at it (Scaffold.appBar)
```

Bars on one edge are listed in reading order (`top` and `bottom` top to
bottom, `start` and `end` in reading order) and stack, so the first top bar
and the last bottom bar are the ones against the edge. Bars on the same
layer add up; an overlay bar over a solid bar reaches past it. List solid bars nearer the edge
than overlay bars: a solid bar listed inside an overlay bar is reported as an error in debug
builds.

A bar **takes the system edge** on its own side: a top bar pads its child below the
status bar, and a bottom bar pads it above the home indicator. Its `backdrop` is
painted under the whole of its space, system edge included. The insets across it (a
top bar's sides) stay in the child's `MediaQuery` for the child to handle,
except on a side a `start` or `end` bar holds: that bar took the system edge there.

A bar sizes its child **the way a `Row` or `Column` does**: the child spans its
edge (for a top or bottom bar, the part between any side bars) and picks its
own depth. A `NavigationRail` in a `start` bar is as wide as
it is in a `Row`, and an `AppBar` in a `top` bar is as tall as its toolbar.
Something that fills whatever it is given, like a `ListView`, needs a size, just
as it would in a `Row`.

`HarborBar.reserve(extent: 80)` holds an edge for something drawn elsewhere
(a footer in an overlay, a bar a parent paints): it reaches 80 in from the
edge, system edge included, or 80 past the bars outside it, paints nothing and takes
no taps. It is an overlay bar by default (`kind: HarborBarKind.solid` stops the body
at it) and takes a `keyboard:` like any bar.

A `HarborFrame` fills the space it is given, as a page does. `sizing: HarborSizing.hugBody`
makes it as tall as its body and bars, as a content-sized sheet is, and
`maxExtentFraction:` caps that at a share of the space above the keyboard (of the
whole height when `bodyClearsKeyboard` is false). `systemEdges:` replaces the system edges a frame
reads from `MediaQuery` (`HarborSystemEdges.fixed(...)`, `HarborSystemEdges.none` for goldens,
`HarborSystemEdges.titleSafe(...)` on a TV), on a `HarborRoot` or any `HarborFrame`, and
`minimum:` is a floor under what its body keeps clear of on each edge.

**The side bars own the corners.** A `start` or `end` bar runs the frame's
full height, and a `top` or `bottom` bar runs between them, as a tablet's
`NavigationRail` sits beside its `AppBar`. A header beside a rail starts where
the rail ends: its title lines up with the rows below, and it is not handed the
system edge the rail took, only the system edge on the side no rail holds. A rail that
withdraws gives its corners back as it goes; one that widens over the page on
focus (`restingExtent:`) holds the header at its resting width.

| Option | Use it for |
|---|---|
| `edgeEffect: HarborEdgeEffect.fade(length:, blurSigma:, restsAt:)` | Content fades as it passes under; it rests past the fade (`HarborRest.fadeEnd`) or at the bar (`.barFace`) |
| `edgeEffect: HarborEdgeEffect.fade(faceOpacity:, curve:)` | The fade's ramp: how opaque content is at the bar's face (a quarter by default) and the curve out to the fade's end (a straight line). `faceOpacity: 1` is a band that counts toward where content rests but fades nothing past the bar. A fade is an alpha mask, so it takes no colour: tint the background or the bar's `backdrop`, or paint a scrim with `HarborFrame(edgeEffectPainter:)` |
| `edgeEffect: HarborEdgeEffect.hairline()` | A line on the bar's inner face, for a bar content scrolls up to |
| `keyboard: HarborKeyboardStance.rides` | Rides up on the keyboard, staying on top of it: a composer, a sheet's footer. It sits on the home indicator until the keyboard is taller than it, so it never dips |
| `keyboard: HarborKeyboardStance.stays` | Stays put; the keyboard covers it: a tab bar (the default) |
| `keyboard: HarborKeyboardStance.reserves` | Keeps the keyboard's space whether the keyboard is up or down, so nothing moves: a styling panel. It holds that space at the settled keyboard height either way, so its child's `HarborKeyboardSpace` fills that space when the keyboard is down. It runs to the screen's edge: no system edge, no minimum |
| `state: HarborBarState.dark` | Not drawn and not tappable, but it keeps its space |
| `state: HarborBarState.withdrawn` | Slides out and gives its space back |
| `extentPolicy:` | How a withdrawing bar gives its space back: `hold` (once it's gone, the default), `follow`, `release` |
| `animationStyle:` | How it moves, as `AnimationStyle` sets it on Flutter's routes: `duration` and `curve` to return or light up, `reverseDuration` and `reverseCurve` to withdraw or go dark, `AnimationStyle.noAnimation` for none. It overrides `duration:` and `curve:` |
| `withdrawsAtHighTide: true` | Leaves while the keyboard is up: a tool strip. Its name is unchanged in 0.9 |
| `restingExtent:` | The size to hold at rest for a bar that grows, like a rail that opens on focus |
| `minimum: 16` | At least this much room on the edge, system edge or not, for the bar outermost on its edge (the one that takes the system edge) |
| `systemEdges: HarborSystemEdgeStance.live` / `.steady` / `.none` | How it takes the system edge on its side: as it is now (gone at the bottom while the keyboard is up; the default for a bar that rides the keyboard), as it is with the keyboard down (the default for one that stays), or not at all (the default for one that reserves) |
| `hitTestBehavior:` | Opaque by default, so taps on the header never reach rows under it |

## Content

| Role | Widget | Use it for |
|---|---|---|
| Keeps clear | `HarborClear(edges:, bars:, follow:, keyboard:, rowInsets:, minimum:, padding:)` | Forms, fixed buttons, static blocks |
| Keeps clear of one edge | `HarborClear(edges: {HarborEdge.bottom})` | A form footer under a page header: it clears the system edge and the keyboard at the bottom, and leaves the header to the rest of the page |
| Row insets | `HarborClear.rowInsets(child:)` | A row that lines up with the page margin |
| Scroll view | `HarborScrollView(slivers:, minimum:, bars:, keyboard:)` / `HarborScrollView.box(child:)` | Lists, grids, carousels (`scrollDirection: Axis.horizontal`) |
| One sliver | `HarborSliverClear(sliver:, minimum:, bars:, keyboard:)` | A sliver in your own `CustomScrollView` |
| Pinned header | `HarborSliverBar(child:)` | A header or tab strip inside the scroll that pins at the bars' face and stacks |
| Sticky | `HarborSticky(child:)` | A pill that rides with its item, then sticks below the bars and pinned headers |
| Centered | `HarborCenter(overlapBudget:)` | Controls centered in the frame that may overlap the bars by at most a budget |
| Ignores the bars | `Builder(builder: (context) { final room = HarborRoom.of(context); ... })` | Backgrounds, heroes; `room.systemEdges`, `.bars`, `.fadeBands`, `.frameSize` |

Each one marks what it cleared as **handled**, so nothing beneath clears it again.
`HarborHandled` does the same for a layer you pad by hand, and
`HarborScrollView.paddingOf` gives a third-party list the right scroll padding.

A third-party list that reads only `MediaQuery.padding` (a chat list, a feed)
already gets, in a frame's body, the larger of the system edges and the bars on every
edge. What it misses is the fade, reveal widening, the row insets, `minimum`
and, under `bodyClearsKeyboard: false`, the keyboard. Give it
`HarborScrollView.paddingOf(context)` if it takes a padding; otherwise rewrite
`MediaQuery` around it yourself, with `MediaQuery.of(context).copyWith(padding: ...)`.
That rewrites Flutter's `MediaQuery`, not harbor's room data, so nothing drifts from
harbor's measurements. harbor itself never puts the keyboard into `padding`.

A scroll view under a header it does not own, which already cleared the top, goes
in `HarborHandled(edges: {HarborEdge.top})`: on that edge `MediaQuery` and the
room data read zero, so the scroll view's first row, the cover its pinned sliver bars
pin at and its reveals all leave the top alone, as a `Scaffold`'s body does
under its app bar. `{HarborEdge.bottom}` does the same for a list that stops
short of the bottom of the screen. To start the first sliver under the header
instead, use `startsUnderBars` (below).

A layer that pads by the system edges alone (a page's safe-area margin, read from
`HarborRoom.of(context).systemEdges`) handles the system edges and keeps the bars with
`HarborHandled(edges: {HarborEdge.bottom}, clearsBars: false)`. A list inside it
still rests on a frosted tab bar: beneath, the bars, their fades and
`MediaQuery.padding` are measured from the layer's edge. A scroll view needs no
such option across its scroll: it handles only its own ends, so a carousel's
items are handed the bars above and below it as they are.

`HarborScrollView(clearsBars: false)` rests its ends clear of the system edges alone, not the
bars: a list that keeps its last row off the home indicator but scrolls on
under a frosted tab bar, or a carousel that runs under a rail. Its ends handle
the system edges alone, as `HarborHandled(clearsBars: false)` does, so its rows still read
how far the bars reach, measured from the scroll view's edge, and can pad
themselves under them. Pinned sliver bars still pin at the bars' face, reveals
still bring a row clear of the bars, and the bottom end still keeps clear of
the keyboard while `keyboard` is true. `HarborSliverClear` and
`HarborScrollView.paddingOf` take the same `clearsBars:`.

`HarborScrollView(clearsKeyboard: false)` leaves the keyboard to someone else, as
`HarborClear(clearsKeyboard: false)` does: a list in a host whose body already ends at
the keyboard, or one that stays put while a keyboard opens over it. Its bottom
end and its reveals leave the keyboard out, and it does not mark the keyboard
handled, so a `HarborClear` block inside can still keep clear of it, and the scroll view
holds still while the keyboard moves. The sliver and `paddingOf` take it too.

`HarborRoom.barFaceOf(context, HarborEdge.top)` is how far the header
reaches, to its inner face, whether or not it has an edge effect: for artwork that
lines up under a frosted header. It holds still while the keyboard moves. It
reads zero inside a scroll view, which has handled its ends; start the scroll view
under the bars to lay artwork under the header.

`HarborClear(clearsBars: false)` keeps clear of the system edges alone, without the bars
and, unlike a scroll view, without the keyboard whatever its `keyboard`: a hero title
under a translucent header that must not touch the
status bar. To keep clear of the system edges and the keyboard but not a header, keep clear
of the bottom edge alone: the header is on the top edge, so it is left to the page.
`follow: HarborFollow.resting` holds still while a bar grows over it.
`HarborScrollView(startsUnderBars: true)` starts its first sliver at the frame's
edge, under the bars, for a hero that runs under a translucent header. That
sliver is handed back the leading end alone; the trailing end and the keyboard
stay handled.
`minimum:` on a scroll view or a `HarborSliverClear` is a floor on each end, as on
`SafeArea`: the end rests clear of whatever is in the way or the minimum,
whichever is larger, so a phone with a home button still keeps 16 under the last row.
`HarborScrollView.box` given no bound across the scroll, as a horizontal one is in
a `Column`, is as thick as its child: a row of chips as tall as the chips, its
ends still clear.

A `HarborScrollView` takes the rest of a `CustomScrollView`'s parameters, with the same
names and defaults (the box form those of a `SingleChildScrollView`):
`restorationId:` brings its scroll position back after the app is restarted, and
`keyboardDismissBehavior:` left unset follows the app's `ScrollBehavior`. With a
`center:`, both ends of the scroll still rest clear of the bars, and the center
sliver starts clear of the leading ones. `anchor:` is the one that reads
differently: it is a fraction of the room between the bars, not of the
viewport that runs under them, so `anchor: 1` puts the center on a composer's
face and lifts it with the keyboard.

Scroll views also draw the edge effect: their content fades as it passes under a bar with
a fade, while content that ignores the bars (a background, a hero) is left as it is. Give a
`HarborFrame` an `edgeEffectPainter` to fade its whole body instead
(`edgeEffectPainter: HarborFadeMask.alphaFade`), or to paint the edge effect your own way (a
progressive blur shader).

Scroll views widen every reveal by what covers their trailing edge. A focused
field, `Scrollable.ensureVisible` and focus traversal all bring a row clear of
the bars and the keyboard with no extra code.

## The keyboard

```dart
HarborFrame(bodyClearsKeyboard: true, ...)   // default: the body ends at the keyboard's top
HarborFrame(bodyClearsKeyboard: false, ...)  // the body runs under; content reads it
HarborKeyboard.of(context)                   // height, remaining, settledHeight, phase
HarborKeyboard.isShownOf(context)            // whether it is shown, rebuilding only when that flips
```

`MediaQuery.padding` never carries the keyboard. That stays in `viewInsets`,
as Flutter has it, and harbor widgets add it where they keep clear of the
bottom. `HarborKeyboard.of(context).height` is still readable after a frame
has moved out of the keyboard's way: for information, never for layout.
`settledHeight` is the last settled keyboard height in this orientation, and it
falls as well as rises. Its `phase` is `hidden`, `opening`, `shown` or `closing`.

Readers rebuild only for what they read. `HarborKeyboard.of` follows every frame drawn
while the keyboard moves; `HarborKeyboard.isShownOf` hears it come and go, and
`HarborRoom.of(context, aspect: HarborRoomAspect.bars)` holds still while
it moves, and so does the `systemEdges` aspect, on a phone with a home indicator too.
harbor's own content reads the same way: row insets, a horizontal scroll view,
a `HarborRoom.of` reader or a `HarborKeyboardSpace` in a page the keyboard runs under is not
rebuilt as it opens. Only what lays out against it is.

`HarborRoom.steadySystemEdgeOf(context, HarborEdge.bottom)` is the home
indicator's height, held while the keyboard is up, as `viewPadding` is in
Flutter: for a footer that keeps its size while the keyboard animates. A body
that clears the keyboard has no `viewPadding` left at the bottom while the keyboard
is up, so read it here. It rebuilds its reader when the view padding changes,
as `MediaQuery.viewPaddingOf` does, but not on every frame of the keyboard. It
is zero below a solid bar that took the system edge, and below anything that marked the
edge handled. A footer that sits on the keyboard instead, giving the home
indicator's room back while the keyboard covers it, reads
`MediaQuery.viewPaddingOf` in a body that clears the keyboard: the indicator with
the keyboard down, 0 with it up.

### A keyboard the platform does not report

harbor reads the keyboard from `MediaQuery.viewInsets.bottom`, as `Scaffold` and
`EditableText` do, so that is the one place to feed it a keyboard the platform
does not report: one drawn by a plugin or a platform view, a TV's on-screen
keyboard reported over a channel. Rebuild `MediaQuery` above the root with the
larger of the two:

```dart
MaterialApp(
  builder: (context, child) {
    final MediaQueryData data = MediaQuery.of(context);
    final double keyboard = math.max(data.viewInsets.bottom, imeHeight); // logical px
    return MediaQuery(
      data: data.copyWith(viewInsets: data.viewInsets.copyWith(bottom: keyboard)),
      child: HarborRoot(child: child!),
    );
  },
);
```

`HarborKeyboardSource` does the same from a `ValueListenable<double>`, rebuilding
only its `MediaQuery` when the height changes:

```dart
HarborKeyboardSource(height: imeHeight, child: HarborRoot(child: child!)) // imeHeight: a ValueNotifier<double>
```

Bars, the keyboard reading, scroll views and Flutter's own widgets then all see the same
keyboard: a composer that rides it rides it, a tab bar that stays is covered. Mind:

- **Logical pixels.** A channel usually reports physical ones; divide by
  `MediaQuery.devicePixelRatioOf(context)`.
- **The larger value, not the sum,** so a keyboard the platform does report is
  not counted twice.
- **A floating keyboard** (an iPad's, a split one) covers no edge and should not
  count as shown: report zero for it, as the platform does.
- **Above a scaled screen.** Put it outside `HarborScaledScreen`, so the height is
  re-based into the reference screen's coordinates with the rest of the insets.

## HarborFrame and Scaffold

A frame does what a `Scaffold` does for the edges, so a page built from a `HarborFrame` does not need
one. Keep a `Scaffold` only where Material needs it, for its surface or to host `SnackBar`s, and
then give it the frame as its body and **turn off its resizing**:

```dart
Scaffold(
  resizeToAvoidBottomInset: false, // the frame handles the keyboard
  body: HarborFrame(top: [...], bottom: [...], body: ...),
)
```

A resizing `Scaffold` shrinks the frame before the frame ever sees the keyboard. Nothing is
counted twice, but every bar then rides up above the keyboard: a tab bar that stays is lifted
instead of covered, and `bodyClearsKeyboard: false` has nothing to run under. Leave the Scaffold's
`appBar`, `bottomNavigationBar` and `floatingActionButton` empty and use bars and floats instead.

## Talking to the frame

```dart
HarborHideBar(edge: HarborEdge.bottom, mode: HarborYield.withdraw, child: panel)
HarborAttachedBar(edge: HarborEdge.bottom, bar: HarborBar.overlay(child: unsavedBar), child: form)
HarborFrame.of(context).hideBar(HarborEdge.top, mode: HarborYield.dark) // returns a claim; release() it
```

`HarborFrame.of(context)` is the nearest frame's handle, as `Scaffold.of` is the
nearest `ScaffoldState`. It throws a `FlutterError` when there is no frame
above the context, in release builds too, as `Scaffold.of` does;
`HarborFrame.maybeOf` returns null instead. The frame makes its handle and runs
its lifecycle, so the handle carries only what content asks of it: claims,
attached bars, page covers and the room. Claims are counted and go to the
nearest frame that has a bar on that edge. A `HarborHideBar` takes its claim
while it is built, after its frame, so the bar hides in the next frame drawn; a
claim taken with `hideBar` in the tap that opens a mode lands in the next frame
drawn, and a page that opens without the bar builds it with `state:
HarborBarState.withdrawn`. An attached bar joins the frame's
bars on the next frame drawn; one added by hand with `attachBar` returns a
`HarborAttachedBarHandle` to update or remove it by.

## Floats, popovers and toasts

```dart
HarborFrame(
  floats: [
    HarborFloat(placement: const HarborAligned(alignment: AlignmentDirectional.bottomEnd), child: fab),
    HarborFloat(placement: HarborAnchored(launchAnchor, side: HarborAnchorSide.above, overlap: 6), child: bubble),
    HarborFloat(modal: true, onDismiss: closeQuickActions, child: quickActions), // a barrier over the page
  ],
  bottom: [HarborBar.solid(child: InboxTabs(launch: HarborAnchorPoint(anchor: launchAnchor, child: launchButton)))],
  body: ...,
)

HarborToasts.show(context, slot: HarborToastSlot.low, builder: (_) => Toast('Saved'));
HarborToasts.show(context, placement: const HarborAligned(alignment: Alignment(0, -0.8)), builder: (_) => Toast('Saved'));
HarborToasts.show(context, placement: HarborAnchored(copyAnchor, side: HarborAnchorSide.above), builder: (_) => Toast('Copied'));
final undo = HarborToasts.show(context, persist: true, builder: (_) => UndoToast(onUndo: restore));
final HarborToastClosedReason why = await undo.closed;    // hide, dismiss, timeout or remove
HarborToasts.show(
  context,
  transitionBuilder: (context, animation, child) => SlideTransition(
    position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
    child: child,
  ),
  builder: (_) => Toast('Saved'),
);
```

Floats sit in the **room**: the rectangle no system edge, bar or keyboard covers.
Where in it is the float's `placement`, a `HarborPlacement`, which toasts and popovers
take too, so a placement means the same everywhere:

- `HarborAligned(alignment:, margin:)` puts it at a point of the room,
  `margin` in from its edges: bottom centre and 16 by default.
- `HarborAnchored(anchor, side:, gap:, overlap:, crossAlignment:, crossOffset:, flips:, margin:)`
  puts it by an anchor: `below` it, 8 away, centred on it and 8 in from the room's
  edges by default. `overlap` reaches back over the anchor, as a speech bubble's
  tail sits over its button.

An anchored float sits on its `side` of its anchor; `start` and `end` are in
reading order, as in `AlignmentDirectional`, so `start` is on the right under
right-to-left. Across that side it is centred on its anchor unless its
`crossAlignment` says `start` or `end`, the anchor's edges in reading order (or
its top and bottom beside it), as a dropdown lines up under its button's leading
edge; `crossOffset` moves it on from there, toward the reading end. A float and a
toast keep their side; a popover flips to the other when its side has no room,
unless its placement says `flips: false`. While its
anchor is not in the tree, an anchored float is not shown, takes no taps and is
not read out by screen readers. It is placed again in every frame that is drawn,
so it moves with its anchor in the same frame drawn, a row scrolling under an open
menu included. A `HarborAnchor` refers to one `HarborAnchorPoint`, so give each
row of a list its own; in debug builds two points left on one anchor are
reported after the frame drawn, as two leaders on one `LayerLink` are.
A placement's `alignment` and `margin` take directional values, so
`AlignmentDirectional.bottomEnd` puts a button where a right-to-left reader expects it.
On a dual-screen device a float keeps to one screen and keeps its margin off the
hinge, as it does off the room's edges.
A `modal` float is modal: a barrier (clear unless you give it a `barrierColor`)
keeps taps off the page and its bars and tells screen readers to leave them
alone, a tap beside the float, back or Escape calls its `onDismiss`, and the floats
listed before it are hidden while it is up. Its `barrierLabel` ('Dismiss' when
none is given) is what a screen reader announces for the barrier; a Material app
passes `MaterialLocalizations.of(context).modalBarrierDismissLabel`. It holds
keyboard focus as a dialog does: it takes focus when it opens, Tab goes round
inside it and the arrow keys (a TV remote's D-pad) stop at its edges, and focus
goes back to where it was when it closes. `requestFocus: false` leaves focus on
the page, as it does for a route; Escape from there still closes the float, unless
focus is on a page of a `Navigator` nested in the frame's body, whose route
answers Escape before the frame does.
A toast is shown at a slot (`top`, `high`, `middle`, `low`) or by a `placement`:
at an exact point (`HarborAligned`), placed as a float there would be. An
`AlignmentDirectional` follows the reading direction of the page that showed it.
It fades and scales in over `animationStyle` (220 ms each way by default).
A `transitionBuilder` brings your own entrance and exit, run on harbor's
animation, and `AnimationStyle.noAnimation` shows a widget that animates
itself as it is, as `showSnackBar(snackBarAnimationStyle:)` does. A hidden
toast stays at least 300 ms, so its own exit can run.
A toast goes to the page on top (a sheet over a page over the root), so a `low`
toast clears that sheet's footer, and it also stays clear of the bars of the
frame it was shown from (a tab's own header). If its frame leaves, the
toast moves to the page now on top.

A toast shown with a `HarborAnchored` placement sits by a `HarborAnchorPoint`
instead, as an anchored float does: on its `side` (`below` by default), `gap` away
(8), lined up by its `crossAlignment` (centred), and kept in the room:
"Copied" by the button that copied. Show it from the page that holds the anchor: it is shown by
that page, not the one on top. Toasts at one anchor and side take turns. While the
anchor is out of the tree the toast is not shown, takes no taps and is not read
out, and its time stops. If its page is popped, it does not move to the page now
on top: it is hidden, and `closed` reports `remove`.

Toasts shown at the same slot or alignment of one page take turns, as a
`ScaffoldMessenger` shows its snack bars: the next comes in once the one before
it has run its exit, so "Copied" tapped twice is never drawn over itself. To
replace the toast that is up, `hide()` it; one hidden while it waits leaves
without being shown. Toasts at different slots show together.
`queue: HarborToastQueue.replace` takes the turn at once instead: the toast goes
first and the one up leaves, closed with `HarborToastClosedReason.replaced`, for
an Undo whose window is tied to a pending action. `HarborFlarePolicy(queue:,
child:)` (its 0.8 name, kept until it folds into `HarborDefaultsScope`) sets that for a subtree, such as a remote-driven TV screen where a newer
"Saved" should replace the one up rather than arrive late. `closed`
completes once a toast has left, with why. `entry.phase` (`waiting`, `shown`,
`closed`) and `entry.wasShown` say where it is synchronously, before `closed`
completes: a toast hidden while it waits is `closed` by the time `hide()`
returns, and `wasShown` is false, so an analytics count or an `onDismiss` can
answer on the spot.

A toast stays 4 s, as a `SnackBar` does, and its `duration` counts only while it
is in sight: from the end of its entrance, and not while another route covers
its page (the time starts over when that route leaves). `persist: true` keeps it
up until it is hidden, as `SnackBar(persist:)` does. Give it to a toast with a
button, an Undo: a screen-reader user moving through the page needs longer than
4 s to reach it. `entry.hold()` stops the time until you `release()` the
`HarborToastHold` it returns: call it from the toast's own `Listener` when a
finger goes down, or when focus moves in; `HarborToastEntry.maybeOf(context)`
inside the toast's builder is its own entry. harbor never holds a toast by
itself. Holds are counted, the time starts over at the last release, and
`entry.held` says whether one is on. `countsEntrance: true` counts the duration
from the start of the entrance, so a 4 s toast is on screen 4 s, and setting
`entry.duration` after it is shown starts the time over with the new one (longer
once a screen reader turns on, say). `countsWhileCovered: true` keeps the time
running while another page covers the toast's, so a "Saved" toast is gone when
the user comes back; a hold still stops it. A toast with neither a slot nor an alignment goes to
`HarborToastSlot.high`, and `target: HarborToastTarget.root` sends it to the
outermost frame, clear of the system edges alone.

A toast keeps 16 in from the room's edges (8 by an anchor). Its placement's
`margin` sets that, and `HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero)`
gives a bar the width of the screen, a fixed `SnackBar`'s look, still above the bars
and off the system edges. `reachesSystemEdges: true`, for a toast at a slot or an alignment,
lets it run over the system edges it is against (under the home
indicator at the bottom, the status bar at the top, the side insets always),
still off the bars and the keyboard, and hands its content the system edges it covers
as `MediaQuery.padding` to keep its text clear: `SnackBarBehavior.fixed`'s look.

An anchored toast never flips, so its transition knows its side:
`HarborToastEntry.maybeOf(context)` in a `transitionBuilder` gives its `anchor`
and `side`, and `HarborAnchorClip(anchor:, side:, child:)` clips at the anchor's
edge, for a toast that slides out from under the field it hangs from.

A toast shown with no frame above it (a widget test that pumps a bare
`MaterialApp`, a preview, a screen not yet built from a frame) still shows: it
goes to the nearest `Overlay`, at its slot and clear of `MediaQuery.padding` and
`viewInsets`. Without a `HarborRoot`, the outermost frame of the page is its
page: a toast shown from a frame inside a header goes to the page, not the
header. With no overlay either, it is reported through
`FlutterError.reportError`, in release builds too. A toast's timers stop when it
is hidden or when nothing is left to show it, so a test that ends with one up
has no timer pending.

Toasts were called signals through 0.3.0 and flares through 0.8; both sets of old names still
work, deprecated, until 1.0.

Through 0.6, floats, popovers and toasts took their placement as loose parameters
(`HarborBuoy(alignment:, margin:)`, `HarborBuoy.anchored(anchor:, side:, gap:, ...)`,
`HarborPortalBuoy(side:, ...)`, `HarborFlares.raise(alignment:, anchor:, ...)`), and the
sides and cross alignments were `HarborBuoySide` and `HarborBuoyCrossAlignment`. Those
still work, deprecated, with the defaults they had, and go at 1.0; `dart fix --apply`
rewrites them to placements.

```dart
final menu = OverlayPortalController();

HarborPopover(                          // in a list row, anywhere below a frame
  controller: menu,
  placement: const HarborAnchored(        // by its child: no anchor of its own
    null,
    side: HarborAnchorSide.below,
    crossAlignment: HarborCrossAlignment.start, // under the row's leading edge
  ),
  onDismiss: menu.hide,                   // a tap outside, Escape or back
  consumeOutsideTaps: true,               // and that tap presses nothing else
  popoverBuilder: (context) => const RowMenu(),
  child: GestureDetector(onTap: menu.toggle, child: row),
)
```

A **popover** is an anchored float opened from where it is used rather than
listed in `HarborFrame.floats`: a menu from a list row, a popover from a button in
another package. It is an `OverlayPortal`, so it builds with the row's
themes and sits in the nearest `Overlay`, placed in the room of the
frame around the row by its `placement`, anchored to its `child` when the placement
has no anchor. Until that anchor is in the tree, it is not shown, takes no taps and is
not read out. Given no placement it sits above its child, as it did before
placements; `HarborAnchored`'s own side is below. When its `side` has
no room, it flips to the other side of the anchor (unless `flips: false`), so a menu from a row just
above the tab bar or the keyboard opens above the row; when neither side has
room, it is held inside the room. `HarborPopover.sideOf(context)` in
the popover is the side it landed on, so a popover can point its arrow at the
anchor after a flip. The popover is placed as it paints, so it hears of a flip on
the next frame drawn. To have it open in the frame drawn as it is built (a menu opened by
building it), call `controller.show()` in your widget's `initState`: an
`OverlayPortalController` keeps a `show()` made before its portal is attached,
and the portal shows as it attaches.

With an `onDismiss`, a popover closes as a `MenuAnchor` does: the popover and
its `child` are one `TapRegion` group, so a tap outside both calls `onDismiss`
while a tap on the row that opened it is left to the row, and so do Escape with
focus in either and back (before it reaches the page). The tap goes on to what
is under it, as a `MenuAnchor`'s does, unless `consumeOutsideTaps` is set. It
puts up no barrier and leaves the page to screen readers, as a menu does. So in
a modal float, a tap on the barrier while the popover is open calls both
`onDismiss`es, and in a dialog it calls the popover's and closes the
dialog, as it does with a `MenuAnchor` open in a dialog.

A popover leaves focus where it was when it opens, as a `MenuAnchor` does.
`requestFocus: true` makes it take focus as a sheet with no barrier does: the popover
is a focus scope of its own that becomes the first focus of the scope around its
`child` (the page's, or a modal float's or a dialog's), so a control in it with
`autofocus: true` takes it from there. It is not modal, so Tab past its last control
does what it does at a route's edge rather than going round inside it. When it
closes, focus goes back to where it was, if focus is still in the popover. It needs an
`onDismiss`, so Escape from inside it can close it; that Escape closes the popover
before a modal float it was opened from.

## Sheets and dialogs

```dart
showHarborSheet(context, builder: (_) => HarborSheet(header: title, footer: actions, body: form));
showHarborSheet(context, builder: (_) => HarborSheet.draggable(
  header: title,
  extent: const HarborSheetExtent(rest: 0.5, max: 0.88, min: 0.25), // the defaults
  builder: (context, controller) => HarborScrollView(controller: controller, slivers: [...]),
));
showHarborSheet(context, coversPage: true, barrier: HarborSheetBarrier.none, builder: ...);
showHarborDialog(context, inheritRoom: true, builder: ...);
```

A sheet starts a page of its own. It takes the themes and text style of the page that
opened it, and stops short of the status bar. Its header is an overlay bar with a fade
(on a draggable sheet, dragging the header drags the sheet), and its footer is a solid bar that
rides the keyboard and keeps 16 off the edge. It keeps the home
indicator in its system edges, so its footer clears it exactly once. A draggable
sheet's heights are fractions of the space between the status bar and the
keyboard. A sheet opened with **`coversPage: true`**
reports how far it covers the page that opened it, and that page's
content keeps clear of it while it's up: in the same frame drawn as the sheet,
as it slides in and out and as it is dragged.

`showHarborSheet(reachesTop: true)` lets a sheet reach the top of the
screen, and hands its header and body the status bar to clear, as a page's
are. A header that paints under the status bar and pads its own title would
pad twice, so it passes `HarborSheet(clearsTopSystemEdge: false)` (on
`HarborSheet.draggable` too): the sheet keeps the height `reachesTop` gave
it, and the top system edge is handled for its content, which reads zero there.
Toasts and floats in the sheet still keep clear of the status bar. Without
`reachesTop` it changes nothing: the sheet stops short of the status
bar and is handed no top system edge to clear.

On a phone on its side, or with a cutout on a side edge, `HarborSheet(clearsSides: true)`
keeps the header, body and footer clear of the system edges on the left and right and
marks them handled, so nothing beneath clears them again, while the surface still runs
edge to edge. It is off by default, as `showModalBottomSheet`'s `useSafeArea`
is: then the header and footer run the sheet's full width and are handed the
side system edges in `MediaQuery.padding`, and so is the body, which clears them only
where it keeps clear. `useSafeArea` insets the whole sheet, its surface
and its top too; `clearsSides` insets only what is over the surface, and only
the sides.

A sheet keeps its body above the keyboard and caps its height by the space
above it. `HarborSheet(bodyClearsKeyboard: false)` leaves the keyboard to the body,
as `HarborFrame(bodyClearsKeyboard: false)` does a page's: for an editing toolbar that
holds a keyboard-sized space so nothing jumps when a field takes focus, or an
inspector the keyboard may cover. The body runs under the keyboard and reads it
in `MediaQuery.viewInsets`, a footer that rides the keyboard still rides up on it, and
`maxExtentFraction` (0.9 of the space above the keyboard by default), or a
draggable sheet's extents, is a share of the whole height.

On a dual-screen device, sheets and dialogs keep to one screen, as Material's do,
and toasts and floats keep to the screen that holds them, never across the hinge.
A flat fold, which has no width, may still be spanned.

Which hinges and folds they keep off is a policy, `HarborHinge`, modelled on
Material 3's `HingePolicy`:

| `HarborHinge` | Keeps off |
|---|---|
| `avoidSeparating` (default) | A hinge with width, and a fold that is half open: what separates the screen |
| `avoidOccluding` | Only a hinge with width, which hides content; a half-open fold is still one screen |
| `always` | Every hinge and fold, a flat one too |
| `never` | Nothing: the inner screen is one wide, unbroken screen, for a canvas or a map |

Set the app's default on `HarborRoot(hinge:)`, a page's on `HarborFrame(hinge:)`, and
one overlay's on `showHarborSheet(hinge:)`, `showHarborDialog(hinge:)`,
`HarborToasts.show(hinge:)` or `HarborFloat(hinge:)`; the nearest wins, and a toast
takes the policy of the page that showed it. A popover (a row's menu) keeps to
the screen that holds its anchor, as a Material menu keeps to its button's, and
flips within it; `HarborPopover(hinge:)` sets its own. A sheet a hinge keeps to
one screen can fill that screen, top to bottom, with
`showHarborSheet(fillsScreenAtHinge: true)`, as Microsoft suggests for a partial
overlay on a dual-screen device. It changes only where harbor puts
things: `MediaQuery.displayFeatures` stays as the platform reports it, so a
two-pane layout or a video player beneath still sees the hinge. `anchorPoint:`
picks the side.

Bars keep off a hinge the page's policy keeps off, as both Microsoft and Google
ask: a header or a tab bar across a vertical hinge keeps to the screen where
reading starts (the left one, or the right one right to left), and a rail down a
horizontal hinge keeps to the top screen. The body still runs across, so a page
is one canvas; split it into panes for two. Only a frame as big as the screen
reads the hinge. `HarborFrame(hinge: HarborHinge.never)` lays bars across it, and the
page's overlays too; `HarborFrame(barHinge: HarborHinge.never)` lays only the bars
across it, so its sheets, dialogs, toasts and menus still keep off.

`HarborPanes(start:, end:)` is two panes, modelled on Windows' `TwoPaneView`:
either side of a hinge the policy keeps off (side by side for a vertical one,
start on top for a horizontal one), side by side when the width reaches
`minWideWidth` (840 by default, Material's expanded width), one above the other
when the height reaches `minTallHeight` (off by default), and otherwise
`priority`'s pane alone. Each pane is built as a screen of its own, with its size,
the system edges only on its outer edges and only the display features inside it, so
each can be a `HarborFrame` with bars of its own: list and detail, two pages of a
book, a canvas and its tools. `HarborPanes.modeOf(context)` tells a list whether
its detail is on screen, so a tap can fill the end pane or open a page.

```dart
HarborPanes(
  start: HarborFrame(top: [HarborBar.overlay(child: header)], body: list),
  end: HarborFrame(body: detail),
  priority: HarborPanePriority.start, // the list, on a phone
)
```

`HarborPosture.of(context)` is how a foldable is held: `flat`, `tabletop` (half
open with the fold across the screen) or `book` (half open with the fold down the
middle). On a table, a `HarborPanes` puts its start pane above the fold and its end
pane below, so a video player sits above its controls, as Android's tabletop
guidance has it; in a book, the two panes are its pages.

A sheet with `barrier: HarborSheetBarrier.none` is not a route of its own, so
it is tied to the page that opened it: back (and a pop) closes it before the
page, the iOS back swipe stands aside while it is up, it hides while another
page is on top (from the first frame of that page's push until its pop has
finished), and it leaves when its page is replaced or removed. In a page built
from a frame, the page draws it, just above itself: a dialog, a modal sheet or
a menu opened over the page sits over the sheet too, which stays in view behind
its barrier and out of reach, as a `Scaffold`'s persistent bottom sheet does. In
a page with no frame it has nothing to be drawn by, so it hides while anything
is over the page. Escape closes it as
back does, from focus in the sheet or in a frame on its page, and is left to
the widgets above while no such sheet is up. It is not modal, as a persistent
bottom sheet is not: it is a focus scope of its own, as a route is, so Tab goes
through the sheet in order and then on to the page, and it leaves focus where it
was when it opens unless you pass `requestFocus: true`. Then focus goes back to
the page when it closes. A
`PopScope` inside such a sheet has no route to register with; put it around
the page instead.

A page that handles back itself with `PopScope(canPop: false)` (a tab bar that
goes back a tab) keeps back from a modal float, a popover and a sheet with no
barrier, as it does from a `Drawer` or a persistent bottom sheet:
`Navigator.maybePop` sees `canPop: false` before it looks at the page's local
history, which is where harbor ties them, so only your handler hears back. Close
them from that handler first, with `Navigator.pop`, which removes the newest
entry of that history:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) {
    if (didPop) return;
    if (ModalRoute.of(context)!.willHandlePopInternally) {
      Navigator.of(context).pop(); // closes the top float, popover or barrier-less sheet
      return;
    }
    tabs.back();
  },
  child: HarborFrame(...),
)
```

Each back press then closes one of them, the newest first, and only once they are
all closed does it reach `tabs.back()`.

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
when that changes, so a button can show whether it opens or closes. `close()`
and `remove()` do nothing once the sheet has left, however it went, so a widget
can close the sheet it opened from its own `dispose` without asking first. It
works for a sheet with a barrier too. `transitionAnimationController:` slides the
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
`animationStyle:` (its fade, 180 ms by default). `transitionBuilder:` brings your own
entrance and exit in place of the fade, as `showGeneralDialog`'s does: it is handed the
route's animation curved by `animationStyle`, and under reduced motion an animation that
is already complete, so the dialog is simply there.

`showHarborDialog` pushes a `HarborDialogRoute`, as `showDialog` pushes a `DialogRoute`.
Push one yourself to keep the route or to choose the navigator:

```dart
final HarborDialogRoute<bool> confirm = HarborDialogRoute<bool>(context: context, builder: (_) => const ConfirmDelete());
final bool? delete = await Navigator.of(context).push(confirm);
```

It takes the same options. The page at `context` lends it its themes and, with
`inheritRoom: true`, its room, both read as the route is pushed rather than
when it is made. Inheriting the room, the dialog treats the opening page's bars as
system edges, so a menu stays between that page's header and its composer.

Three more options are named and behave as `showModalBottomSheet`'s. `isDismissible: false`
makes a sheet the user has to answer: a tap on the barrier does nothing, and
back still closes it. `requestFocus: false` leaves focus in the page.
`anchorPoint:` picks which screen of a dual-screen device it opens on.

What harbor draws on its own is drawn as the widgets layer draws it, with no
theme: sheet and dialog barriers are `showGeneralDialog`'s half-black
(`0x80000000`), and a hairline edge effect is a translucent black (`0x1F000000`), a
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
finger down by any part that doesn't scroll, and closes on a fling faster than
`closeFlingVelocity:` (700, as a modal bottom sheet) or when let go under half shown. A draggable sheet closes at its floor, and its
`HarborSheetExtent(snapSizes:)` are the heights it snaps to (by default its
rest and its ceiling). A fling down on its header from its lowest height goes
to the floor and closes it when it is faster than 700 logical px/s, the speed
at which a Material `BottomSheet` closes; a slower one goes back to that height.
A fling down faster than 1200 (or `closeFlingVelocity`, if higher) closes it
from any height.
`closeFlingVelocity:` sets that speed, on either kind of sheet
(`closeFlingVelocity: 400` is the speed harbor used before 0.3.1). A fling on its list is
`DraggableScrollableSheet`'s own, as in a modal bottom sheet: from the lowest
height it closes the sheet at any speed. `HarborSheetExtent(shouldCloseOnMinExtent: false)` rests at the floor
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

## Keeping in sight

```dart
HarborKeepInSight(onObscured: (covered) => titleOpacity.value = covered, child: heroTitle); // covered: 0 to 1
HarborKeepInSight(keepInSight: true, child: field);       // re-reveals as the keyboard opens or focus moves in
HarborKeepInSightRegion(child: canvas)                    // + HarborKeepInSight(lift: true, clearance: 80)
HarborKeepInSight.reveal(context, clearance: 24);
```

A focused field reveals its own caret, as `EditableText` does. A `HarborKeepInSight` with
`keepInSight: true` reveals all of itself: when the keyboard opens, and when focus moves into
it from outside, by a tap or the keyboard's next action. So a field and the
button under it come up together, `clearance` clear of the keyboard.
`onlyWhileFocused: true` keeps the rest of a form's widgets still.

A region lifts over 280 ms and settles back the same way. Give it an
`animationStyle:` to change that: its `duration` and `curve` are for the lift,
its `reverseDuration` and `reverseCurve` for settling back, and
`AnimationStyle.noAnimation` moves the content at once.

## Accessibility

What harbor hides is hidden from everyone: a dark or withdrawn bar is skipped
by keyboard focus and by screen readers, not only by taps, and a float whose
anchor is not in the tree is not read out. Toasts are live
regions, so screen readers announce them, with a dismiss action that hides
them, as a `SnackBar` is. A toast whose widget is already its own live region
(a `SnackBar`-like widget from your design library) is shown with
`liveRegion: false`, so harbor adds no second, unlabelled one around it. A
toast with a button is shown with `persist: true`, as a `SnackBar` with an
action persists, so it is still there when a screen reader reaches it. Sheets and toasts keep the themes of
the page they came from, and so do dialogs. With reduced motion
(`MediaQuery.disableAnimations`) bars, toasts, sheets and dialogs appear and
leave without moving, and keep-in-sight reveals and lifts jump into place. On iOS a tap on the
status bar scrolls a page built from a frame to the top, as it does under a `Scaffold`, and
as there only the page whose status bar band is on top at the screen's top left:
a page under a route in an outer navigator, under an overlay, or in the
right-hand pane of a split stays where it is.

## TV

```dart
MaterialApp(
  builder: (context, child) => HarborScaledScreen(
    referenceSize: const Size(1200, 675),
    systemEdges: const HarborSystemEdges.titleSafe(HarborTitleSafe.fraction(0.05)),
    child: HarborRoot(child: child!),
  ),
);
```

A scaled screen lays out on a reference screen and scales to fit, re-basing the
real insets into its coordinates. Title-safe is one of the system edges, so bars
take it and `HarborClear` keeps clear of it like any other inset. A rail is
a start bar with a `restingExtent`, and pages choose `HarborFollow.live` (move
with it) or `.resting` (let it open over them).

## The inspector

`HarborInspectorOverlay(child:)` (around `HarborRoot` in `MaterialApp.builder`, or
anywhere below it) draws every bar's space, each frame's room
and the keyboard. Each bar is labelled with its extent; `labelStyle:` sets
the labels' font, so they read in widget tests and goldens rather than as
`flutter_test`'s boxes. `HarborInspector.snapshot(context)` returns the same as data,
and `HarborInspector.nearest(context)` the nearest frame alone: its frame, body,
room and bars in global coordinates, the way a test or a tool reads a
frame without reaching into it.
In debug and profile builds the `ext.harbor.inspector` VM-service extension serves
it as JSON, for tools that drive the app. Its 0.8 name, `ext.harbor.chart`, is still served, and
the JSON still carries the 0.8 keys (`clearWater`, `docks`, `tide`) beside the new ones, until 1.0.

Tooling that runs outside the widget tree (a debug panel, a logger, an
automation driver) reads `HarborInspector.snapshotAll()`: every frame of every live
root, with no context. A root mounted inside another frame (a phone drawn in a
page, a preview) is listed too, and each of its entries says `isolated: true`;
`ext.harbor.inspector` leaves those out unless it is called with `isolated=true`. A
root is taken off the inspector when it is disposed.

To hear frames come and go, as a `NavigatorObserver` hears routes, give the root
a `HarborFrameObserver`:

```dart
class HarborLog extends HarborFrameObserver {
  @override
  void didJoin(HarborController frame) => debugPrint('joined ${frame.debugLabel}');
  @override
  void didLeave(HarborController frame) => debugPrint('left ${frame.debugLabel}');
}

HarborRoot(observers: [HarborLog()], child: child!)
HarborFrame.of(context).registry.addObserver(log); // or on a registry you already have; removeObserver(log)
```

A frame joins as it is built, in the middle of a frame drawn, so both events arrive
after that frame drawn, in order: by then the frame has laid out and the inspector can
read it. A frame that joins and leaves within one frame drawn is reported to no one.
The layout records behind the inspector stay internal; read a frame through
`HarborInspector.snapshotOf(frame.registry)` or `HarborInspector.nearest`.

The widget inspector and `debugDumpApp` show each harbor widget's settings, as
they do a `SafeArea`'s or a `ListView`'s, leaving out the ones at their
defaults: a `HarborFrame` lists its bars and floats, and a bar reads as
`HarborBar.overlay(keyboard: rides, debugLabel: "composer")`. The values (`HarborBar`,
`HarborFloat`, `HarborEdgeEffect`, `HarborSystemEdges`, `HarborTitleSafe`, `HarborSheetExtent`)
are `Diagnosticable`, so they print the same way in a test failure or a log.

Two fields are reserved and not yet read: `HarborSystemEdgeFeature.hinge` (sheets,
dialogs, toasts and floats keep off a hinge through `MediaQuery.displayFeatures`,
not through the system edges) and `HarborController.isPage`, which records whether the
controller's frame was built as a page (`HarborFrame.page`, or `isPage: true`); toasts find their
page by route instead.

## Trials

Trials are in `harbor_test`, a dev dependency beside harbor
(`flutter pub add dev:harbor_test`). It brings `flutter_test`, which harbor
itself does not depend on.

```dart
import 'package:harbor_test/harbor_test.dart';

testWidgets('the composer rides the keyboard', (tester) async {
  final trial = await tester.pumpHarborTrial(app, device: HarborTrialDevice.androidThreeButton);
  await trial.showKeyboard();
  expect(tester.getRect(find.byType(Composer)).bottom, trial.keyboardTop);
});
```

`showKeyboard()` pumps 600 ms, long enough for the frame to follow;
`showKeyboard(pumpFor: Duration.zero)` stops at the first frame drawn after the keyboard
arrives, and `settle: true` pumps until nothing is animating. `hideKeyboard()` takes the same.

Devices: `iPhone17`, `iPhoneSE`, `androidThreeButton`, `androidGesture`,
`iPhone17Landscape`, `androidThreeButtonLandscape`, `androidGestureLandscape`,
`foldableOpen` (a flat fold), `dualScreenCover`,
`dualScreenOpen` (a hinge), `television`, plus the `phones` and `all` lists.
Each device goes on the view at its own `devicePixelRatio`, and
`device.displayFeatures` puts its folds and hinges there.
`pumpHarborTrial(textScaleFactor:)` grows the system text size, so bars are
measured at the size their text grew to. `trial.roomAround(finder)` returns the room
around a widget, and `isInRoom` asserts against it, so a test checks where
something sits relative to everything in the way, not against a number:
`expect(find.byType(Menu), isInRoom(trial.roomAround(find.byType(Menu))))`.
`trial.barsAround(finder)` lists the bars of the frame around a widget. Both
read `HarborInspector.nearest`, so a test of your own can too.

`package:harbor/testing.dart`, where trials used to be, is now empty and
deprecated: importing it points to `harbor_test`. It will be removed in a later release.

## Example

`example/` is a small harbor game that exercises every pattern above. Toggle
the inspector in its Harbor Office to see the layers.

This repository pins Flutter with fvm, hence `fvm flutter` below; plain `flutter` works too.
The videos at the top of this page are `example/lib/showcase/` (the phone tour,
`fvm flutter run -t lib/showcase_main.dart`) and `example/lib/showcase_wide/` (the
wide-format one, `fvm flutter run -t lib/showcase_wide_main.dart`; render it with
`render_showcase.sh showcase_wide`). `example/tool/render_showcase.sh`
records it frame by frame on the test clock, so it comes out the same every
time, and `example/test/showcase_test.dart` checks each caption against the
real page on the phone.

The video is narrated. `example/tool/narrate.py` voices each line of
`example/lib/showcase/narration.tsv`, times every word, and checks that each
clip says what the script says. The showcase's timeline is built from those
timings, so the keyboard rises as "comes in" is spoken. Chapters the
panorama was not drawn for show the Field Guide's drawing of the harbour thing it illustrates,
and each runs a real harbor page on the phone: sheets, dialogs and toasts open
on the phone's own navigator as the narrator names them. Narration: the Kokoro-82M
voice `am_liam`, generated on device by Kass. In this release the videos still narrate the
0.8 harbour words (pier, quay, tide and the rest); they are re-voiced in the new names later.

The **Harbor Field Guide** ([in your browser](https://supposedlysam.github.io/harbor/), the book button on the game's first page, or
`fvm flutter run -t lib/field_guide_main.dart`) has a page for every class,
titled by its name in code, with a harbour drawing to illustrate it (a quay, like a solid bar,
is where the body stops) and a
pretend phone to try it on: its own status bar, home indicator and keyboard, a
gauge to drag the keyboard in and out, the class's options, live readings
of `MediaQuery` and the room data, and the code for what's on the phone.

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
