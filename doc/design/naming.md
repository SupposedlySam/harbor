# Naming: the complete rename table (#120)

The table the rename release applies mechanically. It is drafted from the source, not from
memory: `lib/harbor.dart`'s exports (and their `show`/`hide` lists) and
`harbor_test/lib/harbor_test.dart`, at `fc1fbc8`. `DECISIONS.md` ("Naming (#120)") wins over this
file where they disagree. Where this file departs from the RFC table that DECISIONS adopted, it
says so in [Departures from the RFC](#departures-from-the-rfc), and each departure is an open
question or has its reason beside it.

## 1. Principles

1. **Three nouns.** What is in the way is **edges**: the platform's `systemEdges` and the
   `keyboard`. Something that claims an edge is a **bar**. What is left is **room**. Every other
   name is a role built from those three.
2. **Plain words for plain concepts.** A thing Flutter developers already have a word for gets
   that word: toast, popover, scroll view, keyboard, inspector, page.
3. **`Harbor` stays as the prefix.** It is the brand and keeps the API grouped in completion. Only
   the noun after it changes.
4. **A name says what the thing is, not what it is like.** `HarborBar.solid` says the body stops at
   it; `HarborDock.quay` said it was a stone wall.
5. **Rename once.** A name scheduled to be removed or folded by a later decided step (the audit's
   steps 5 to 10, the defaults, flares and sheets work) is **not** given a new name only to be
   deprecated again. It keeps its old name until its own step retires it, unless its destination
   already exists in the rename release, in which case it goes straight there. Rows marked
   *later* below follow this rule.
6. **Names already plain stay.** The placement types (`HarborPlacement`, `HarborAligned`,
   `HarborAnchored`, `HarborAnchorSide`, `HarborCrossAlignment`) and the new types from the other
   drafts (`HarborBarrier`, `HarborDefaults`, `HarborDefaultsScope`) keep their names. Types those
   drafts introduce with harbour words take the new vocabulary when they land:
   `HarborFlareTiming` → `HarborToastTiming`, `headerDock:` → `headerBar:`,
   `HarborSheet.defaultHeaderDock` → `defaultHeaderBar`, `flareQueue`/`flareMargin`/`flareDuration`
   → `toastQueue`/`toastMargin`/`toastDuration`, `dockHinge` → `barHinge`.

## 2. What `fix_data` can carry (measured)

These shapes were measured, not assumed: a throwaway package pair with a `lib/fix_data.yaml`, run
through `dart fix --apply` and `dart analyze` on Dart 3.13.4, the SDK pinned by `.fvmrc`.

| Code | Shape | Result |
|---|---|---|
| **T** | `typedef Old = New` (deprecated) + `rename` on `typedef: Old`, constructor names unchanged | Works: `Old(...)`, `Old.box(...)`, `Old?` and `Old.staticMember` all become `New...` |
| **T+S** | as **T**, plus a renamed static member kept on `New` as a deprecated forwarder, with `rename` keyed on `inClass: New` | Works: `Waters.dockFaceOf(c)` → `Room.barFaceOf(c)` |
| **T+E** | enum renamed through a typedef, a renamed value kept on the new enum as a deprecated `static const` (keyed `constant:`, `inEnum:`) | Works, including switch patterns: `TideStance.float` → `Keyboard.rides` |
| **SUB** | class whose **named constructors** are renamed: the old name is a deprecated **subclass** with deprecated constructors, `rename` on `class: Old` and `replacedBy` each old constructor | Works: `Dock.pier(x: 1)` → `Bar.overlay(x: 1)`, `List<Dock>` → `List<Bar>` |
| **RP** | `renameParameter` on a deprecated parameter | Works |
| **RB** | `replacedBy` from one element to another: a constructor to **another class's named constructor**, a function to a static method, an enum value to **another enum's value** | Works for all three. The enum value needs its own `@Deprecated`, not only its enum |
| **M** | Manual, with a "Migrating" note in the CHANGELOG | |
| — | Not renamed | |

Two failures, both of which corrupt code rather than leaving it alone:

- **A typedef cannot carry a renamed constructor.** With `typedef HarborDock = HarborBar` and a
  deprecated `HarborBar.pier`, `dart fix` rewrote `HarborDock.pier(x: 1)` to **`HarborBar.HarborBar(x: 1)`**,
  with a `rename` and with a `replacedBy` alike. Any class whose named constructors change must use
  **SUB**. In this table that is `HarborDock` alone.
- **A typedef cannot carry a fix on a named constructor's call either.** Found by the rename
  release's goldens: `HarborCoast.fixed(z, calmTide: true)`, with `typedef HarborCoast =
  HarborSystemEdges` and a deprecated `calmTide`, came out as `HarborSystemEdges.HarborSystemEdges(...)`,
  and so did `HarborFairway.box(tide: false)`, `HarborWake.fade(dockOpacity: 0.5)` and the 0.7
  placement fix of `HarborBuoy.anchored(anchor: a)`. A deprecated argument in the call makes the
  typedef's rename land on the constructor. So **SUB** also covers any class with a named
  constructor whose call a fix rewrites (a renamed or deprecated argument), not only renamed
  constructors: in the release that is `HarborDock`, `HarborBuoy`, `HarborCoast`, `HarborWake` and
  `HarborFairway`. A subclass costs one thing a typedef does not: a 0.8 variable typed with the old
  name that holds a value the API returns (`final HarborWake w = dock.wake;`) does not compile
  against 0.9 until `dart fix` renames its type, which it does (`test_fixes/rename_constructors.dart`).
- **A class rename and a static rename on one expression, keyed to the old class, break it.** A
  `rename` of class `Waters` and a `rename` of `Waters.dockFaceOf` produced `Room.dockFaceOf`, which
  does not exist. Key the member's rename on the **new** class and keep the old member there as a
  deprecated forwarder (**T+S**).

Not measured, and expected to work on Flutter's own evidence (its `fix_data` uses them): `rename` of
an instance getter, field or method (`inClass:`), `renameParameter` on a constructor, and members of
an extension (`inExtension:`, for `harbor_test`). Each still gets a golden in `test_fixes/`, as
DECISIONS requires.

`fix_data` cannot express a change that depends on an argument's **value** (one enum value to one
parameter, another to a different one). Those rows are **M**.

## 3. The table: `package:harbor`

Members are listed under their type. A member, value or parameter not listed keeps its name: every
public member was read, and the ones without a harbour word are left out to keep the table short.

### The frame and the root

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborSea` | `HarborRoot` | T | |
| `HarborSea.coast` | `systemEdges` | RP | And on `Harbor`, `HarborScaleModel` |
| `HarborSea.observers` | unchanged | | Now `List<HarborFrameObserver>` |
| `Harbor` | `HarborFrame` | T | `Harbor.of` / `maybeOf` keep their names |
| `Harbor.newPort` | `isPage` | RP | Plus the decided `HarborFrame.page(...)` constructor, which sets it. `fix_data` cannot choose a constructor by a `bool`'s value, so the fix writes `isPage: true`, and `.page` is the documented spelling. Not inferred at route boundaries (DECISIONS.md, measured): a route under the root needs none, and a nested `Navigator` would move under the outer bars |
| `Harbor.dockHinge` | `barHinge` | RP | Since moved, with `hinge`, into `HarborFrame(defaults: HarborDefaults(...))`; `defaults.yaml` takes `dockHinge:` straight there |
| `Harbor.buoys` | `floats` | RP | `List<HarborFloat>` |
| `Harbor.bodyClearsTide` | `bodyClearsKeyboard` | RP | And on `HarborSheet` |
| `Harbor.wakePainter` | `edgeEffectPainter` | RP | See Q4 |
| `Harbor.top/bottom/start/end`, `body`, `margin`, `minimum`, `sizing`, `hinge`, `debugLabel` | unchanged | | |
| `Harbor.maxExtentFraction` | `sizing: HarborSizing.hug(maxFraction:)` | conditional fix | Deprecated after 0.9.1. Beside `fill` (or no `sizing`), which never read it, the fix removes it; beside a variable it is left |

### Bars (docks)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborDock` | `HarborBar` | **SUB** | The only class that must ship as a deprecated subclass (§2) |
| `HarborDock.pier` | `HarborBar.overlay` | SUB (RB) | The body runs under it |
| `HarborDock.quay` | `HarborBar.solid` | SUB (RB) | The body stops at it |
| `HarborDock.reserve` | `HarborBar.reserve` | SUB (RB) | Same name, but it is still a constructor of the old subclass, so it needs its own `replacedBy` |
| `HarborDock.wake` | `edgeEffect` | RP | Q4 |
| `HarborDock.tide` | `keyboard` | RP | `HarborKeyboardStance` (Q3) |
| `HarborDock.coast` / `effectiveCoast` | `systemEdges` / `effectiveSystemEdges` | RP / rename | |
| `HarborDock.withdrawsAtHighTide` | `keyboard: HarborKeyboardStance.withdraws` | M + conditional fix | After 0.9.1. `withdraws` lays out as `stays` does. `audit.yaml` rewrites `withdrawsAtHighTide: true` on a bar that stays (the default) and drops `false`; with `rides`, `reserves` or a variable the deprecated flag is left, still working. `reserves` and withdrawing cannot both be said in one stance, which is the point: a bar that holds the keyboard's space has nothing to withdraw for |
| `HarborDock.copyWith(tide:)` | `copyWith(keyboard:)` | RP | |
| `HarborDock.kind`, `state`, `extentPolicy`, `animationStyle`, `backdrop`, `hitTestBehavior`, `restingExtent`, `minimum`, `reserved`, `key`, `debugLabel` | unchanged | | |
| `HarborDock.duration` / `curve` | `animationStyle: AnimationStyle(duration:, curve:)` | conditional fix | Deprecated after 0.9.1, on the bar and on `HarborKeepInSightRegion`; the fix writes the style where the call gives none, and leaves a call that gives both |
| `HarborDockKind` | `HarborBarKind` | T+E | |
| `HarborDockKind.pier` / `.quay` | `.overlay` / `.solid` | T+E | |
| `HarborDockState` | `HarborBarState` | T | `open`, `dark`, `withdrawn` unchanged. `HarborYield` merges into it later |
| `HarborCoastStance` | `HarborSystemEdgeStance` | T | `live`, `steady`, `none` unchanged. Singular: a bar takes one edge |
| `HarborExtentPolicy` | unchanged | | Plain |
| `HarborDockRecord` | `HarborBarRecord` | **SUB** | SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required` |
| `HarborDockRecord.tide` | `keyboard` | rename | `HarborKeyboardStance` |
| `HarborDockSlot` | — | — | Already deprecated and leaving the exports; not renamed |
| `HarborSliverDock` | `HarborSliverBar` | T | A bar inside a scroll view. Not a `SliverAppBar` (traps) |
| `HarborPontoon` | `HarborAttachedBar` | **SUB** | Departure, Q2. SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required` |
| `HarborPontoon.dock` | `bar` | RP | |
| `HarborPontoonHandle` | `HarborAttachedBarHandle` | T | `.dock` → `.bar` (rename) |
| `HarborMakeWay` | `HarborHideBar` | T | Departure, Q2 |
| `HarborMakeWay.mode` | `HarborHideBar.state` | M + conditional fix | After 0.9.1: a `HarborBarState`, `withdrawn` by default, never `open` (asserted). `audit.yaml` rewrites a written-out `mode: HarborYield.dark` / `.withdraw`; a variable is left on the deprecated `mode` |
| `HarborYield` | `HarborBarState` | M + conditional fix | Merged after 0.9.1 (`dark` → `dark`, `withdraw` → `withdrawn`). Deprecated, not aliased: a typedef would change the type of `HarborClaim.mode`. `hideBar(edge, mode:)` is `hideBar(edge, state:)`, and `HarborClaim.mode` is `state` |
| `HarborClaim` | unchanged | | |

### The edges: system edges and the keyboard

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborCoast` | `HarborSystemEdges` | **SUB** | `.fixed`, `.titleSafe`, `.ambient`, `.none`, `apply`, `features` unchanged. SUB, not T, as shipped: `.fixed(calmTide:)` (§2) |
| `HarborCoast.calmTide` | `ignoresKeyboard` | RP + rename | It is what `none` sets for goldens |
| `HarborCoastFeature` | `HarborSystemEdgeFeature` | T | Values unchanged |
| `HarborTitleSafe` | unchanged | — | TV vocabulary, not harbour. The fold into `HarborSystemEdges` was dropped (DECISIONS.md): plain already, and the churn is not worth it |
| `HarborTide` | `HarborKeyboard` | T+S | The reader. Q3 |
| `HarborTide.of` | `HarborKeyboard.of` | T | |
| `HarborTide.isInOf` | `HarborKeyboard.isShownOf` | T+S | |
| `HarborTideState` | `HarborKeyboardState` | **SUB** | Still an immutable snapshot, not a `State` (README note, traps). SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required` |
| `HarborTideState.highWater` | `settledHeight` | rename | "The last settled height in this orientation" |
| `HarborTideState.highWaterIsEstimate` | `settledHeightIsEstimate` | rename | |
| `HarborTideState.isIn` | `isShown` | rename | |
| `HarborTideState.height`, `remaining`, `phase`, `isSettled`, `avoidedAbove` | unchanged | | |
| `HarborTidePhase` | `HarborKeyboardPhase` | T+E | |
| `HarborTidePhase.low` / `rising` / `high` / `falling` | `.hidden` / `.opening` / `.shown` / `.closing` | T+E | |
| `HarborTideStance` | `HarborKeyboardStance` | T+E | Q3 |
| `HarborTideStance.float` / `pilings` / `dryDock` | `.rides` / `.stays` / `.reserves` | T+E | `rides`/`stays` from the RFC; `reserves` matches `HarborKeyboardSpace` |
| `HarborDryDock` | `HarborKeyboardSpace` | T | |
| `HarborDryDock.showsChildAtHighTide` | `showsChildWithKeyboard` | RP + rename | As shipped; the draft's `showsChildWhileShown` read as "while the child is shown" |
| `HarborTideSource` | `HarborKeyboardSource` | T | |
| `HarborEdge`, `HarborEdges` | unchanged | | "Edge" keeps its meaning: a side of the frame (traps) |
| `HarborHinge`, `HarborPosture`, `HarborPanes`, `HarborPanePriority`, `HarborPanesMode` | unchanged | | Plain |

### Room (clear water and waters)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborWaters` | `HarborRoom` | T+S | Q6 |
| `HarborWaters.steadyCoastOf` | `steadySystemEdgeOf` | T+S | |
| `HarborWaters.dockFaceOf` | `barFaceOf` | T+S | |
| `HarborWaters.of`, `maybeRawOf`, `clearanceOf` | unchanged | | |
| `HarborWatersData` | `HarborRoomData` | T | |
| `HarborWatersData.coast` / `coastSteady` | `systemEdges` / `systemEdgesSteady` | rename | |
| `HarborWatersData.docks` / `docksResting` / `hasDocks` | `bars` / `barsResting` / `hasBars` | rename | |
| `HarborWatersData.wakes` / `wakesPainted` / `wakeOf` | `fadeBands` / `fadeBandsPainted` / `fadeBandOf` | rename | Q4: they hold `HarborFadeBand`s, so they are named after fades (as shipped) |
| `HarborWatersData.castOff` | `handled` | rename | Matches `HarborHandled` |
| `HarborWatersData.margin`, `frameSize`, `copyWith`, `toCssVariables` | unchanged | | The CSS keys are already `--harbor-inset-*` |
| `HarborWatersAspect` | `HarborRoomAspect` | T+E | `coast` → `systemEdges`, `docks` → `bars`; `margin`, `frame` unchanged |
| `HarborController.clearWater` | `room` | rename | `ValueListenable<Rect>` |
| `HarborController.clearWaterInGlobal` | `roomInGlobal` | rename | |
| `HarborLayoutRecord.clearWater` / `docks` / `tide` | `room` / `bars` / `keyboard` | rename (+ RP) | `frame`, `body`, `obstruction` unchanged. The class keeps its name, so its constructor takes only the new names (breaking); the RP fix still fires on the old, undefined ones |
| `HarborCastOff` | `HarborHandled` | T | |
| `HarborCastOff.tide` / `docks` | `clearsKeyboard` / `clearsBars` | RP | `edges`, `margin` unchanged. The `clears…` family, as shipped |
| `HarborOpenWater` | *retired here* | M | Audit step 8 retires it, and its destination exists: `Builder` + `HarborRoom.of(context)`. Deprecate it in the rename release instead of renaming it (principle 5). Not expressible as a fix: a builder parameter becomes a widget |
| `HarborWatersWidgetBuilder` | *retired with it* | — | |

### Content that keeps clear

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborMoored` | `HarborClear` | T | Collides with today's `HarborClear` enum: Q1 sets the order |
| `HarborMoored.tide` | `clearsKeyboard` | RP | A `bool` that says what it keeps clear of reads `clears…`, as `bodyClearsKeyboard` does; a bar's `keyboard:` is a stance and stays (as shipped) |
| `HarborMoored.mooringLine` | `rowInsets` | RP | |
| `HarborMoored.extra` | `padding` | RP | Audit step 7 decided it; it is a pure rename, so it goes here once |
| `HarborMoored.clear` | `clearsBars` (`bool`) | **M** | Q1. `HarborClear.coast` → `clearsBars: false`; `HarborClear.everything` (the default) → omitted. Value-dependent, so `bars.yaml` handles the two literals |
| `HarborMoored.bars` (0.8.0) | `clearsBars` | RP + rename | The `clears…` family (as shipped). And on the scroll view, the sliver, `paddingOf` and `clearanceOf` |
| `HarborMoored.edges`, `follow`, `minimum`, `clearanceOf` | unchanged | | |
| `HarborClear` (enum: `everything`, `coast`) | *removed*: `clearsBars: false` | M | Q1. Gives the name to the widget. Also "one spelling for coast only" (audit step 7): the same `clearsBars: false` as `HarborHandled` |
| `HarborMooringLine` | `HarborClear.rowInsets` | **RB** (measured) | Goes straight to the constructor audit step 7 decided, so it is not renamed twice. `follow:` and `child:` carry over unchanged. `find.byType(HarborMooringLine)` has no equivalent: M |
| `HarborFollow` | unchanged | | `live`, `resting` are plain |
| `HarborCenter`, `HarborSticky` | unchanged | | |

### Scroll views (fairways)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborFairway` | `HarborScrollView` | **SUB** | `.box` and `paddingOf` keep their names. Not a `ScrollView` subclass (traps). SUB, not T, as shipped: `.box(tide:)` (§2) |
| `HarborFairway.tide` | `clearsKeyboard` | RP | And on the sliver and `paddingOf` |
| `HarborFairway.mooringLine` | `rowInsets` | RP | |
| `HarborFairway.clear` | `clearsBars` (`bool`) | M | As on `HarborClear`, Q1. And on the sliver and `paddingOf` |
| `HarborFairway.wake` | `edgeEffects` | RP | Q4 |
| `HarborFairway.startsInOpenWater` | `startsUnderBars` | RP | It starts the first sliver at the frame's edge, under the bars |
| `HarborFairway` (every other parameter: `CustomScrollView`'s, `revealMargin`, `minimum`, `padding`) | unchanged | | |
| `HarborFairwaySliver` | `HarborSliverClear` | T | `clearLeading`, `clearTrailing`, `minimum`, `padding` unchanged; `tide`, `clear` as above |

### The edge effect (wake)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborWake` | `HarborEdgeEffect` | **SUB** | Departure, Q4. `.fade`, `.hairline`, `.none` unchanged. SUB, not T, as shipped: `.fade(dockOpacity:)` (§2) |
| `HarborWake.dockOpacity` | `faceOpacity` | RP + rename | The opacity at the bar's face. And on `HarborWakeMask` |
| `HarborWake.restsAt`, `length`, `blurSigma`, `color`, `curve`, `clearance`, `kind` | unchanged | | |
| `HarborWakeKind` | `HarborEdgeEffectKind` | T | Values unchanged |
| `HarborRest` | unchanged | | |
| `HarborRest.wakeEnd` / `dockEdge` | `.fadeEnd` / `.barFace` | T+E | |
| `HarborWakeBand` | `HarborFadeBand` | **SUB** | It only has length for a fade. SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required` |
| `HarborWakeBand.dockEdge` / `wakeEnd` / `dockOpacity` | `barFace` / `fadeEnd` / `faceOpacity` | RP + rename | |
| `HarborWakePainter` | `HarborEdgeEffectPainter` | T | |
| `HarborWakeMask` | `HarborFadeMask` | **SUB** | `wakes:` → `bands:`. SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required`; `alphaWake` is a static of both |
| `HarborWakeMask.alphaWake` | `HarborFadeMask.alphaFade` | T+S | |
| `harborAlphaWake` | — | — | Already deprecated; goes with the removals |

### Floats, popovers and toasts (buoys and flares)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborBuoy` | `HarborFloat` | **SUB** | Declared in the tree. `.anchored` is deprecated by the placement work and keeps its name. SUB, not T, as shipped: the placement fix renames `.anchored(anchor:)` to the unnamed constructor (§2) |
| `HarborBuoy` (every parameter) | unchanged | | `modal`, `barrierColor`, `barrierLabel` are reshaped by `HarborBarrier` in the sheets step (`sheets.md`, as shipped) |
| `HarborPortalBuoy` | `HarborPopover` | **SUB** | Opened on demand by an anchor. Decided. SUB, not T, as shipped (owner review): it takes the old parameter name `buoyBuilder:`, so the new constructor keeps `popoverBuilder:` `required`; `sideOf`, `maybeSideOf` are statics of both |
| `HarborPortalBuoy.buoyBuilder` | `popoverBuilder` | RP | As `OverlayPortal.overlayChildBuilder` names its content |
| `HarborPortalBuoy.sideOf` / `maybeSideOf`, `flips`, `consumeOutsideTaps`, the rest | unchanged | | |
| `HarborBuoySide`, `HarborBuoyCrossAlignment` | — | — | Renamed by the placement work to `HarborAnchorSide`, `HarborCrossAlignment` |
| `HarborAnchor`, `HarborAnchorPoint`, `HarborAnchorClip` | unchanged | | Plain |
| `HarborFlares` | `HarborToasts` | T+S | Transient. Decided |
| `HarborFlares.raise` | `HarborToasts.show` | T+S | |
| `raise(reachesCoast:)` | `reachesSystemEdges:` | RP | And `HarborToastEntry.reachesSystemEdges` |
| `raise(target:)`, `persist:`, `duration:` and the rest | unchanged | | `persist`/`duration` fold into `HarborToastTiming` later |
| `HarborFlareSlot` | `HarborToastSlot` | T | `top`, `high`, `middle`, `low` unchanged |
| `HarborFlareTarget` | `HarborToastTarget` | T+E | `.sea` → `.root`; `.topmost` unchanged |
| `HarborFlareEntry` | `HarborToastEntry` | T+S | `maybeOf` unchanged |
| `HarborFlareEntry.lower` | `hide` | rename | As `ScaffoldMessenger.hideCurrentSnackBar` |
| `HarborFlareEntry.raisedIn` | `shownFrom` | rename | Going `@internal` in the flares split |
| `HarborFlareEntry` (`closed`, `phase`, `wasShown`, `hold`, `held`, `duration`, `anchor`, `side`, the rest) | unchanged | | |
| `HarborFlareClosedReason` | `HarborToastClosedReason` | T+E | `.lower` → `.hide`, as `SnackBarClosedReason.hide`; `dismiss`, `timeout`, `remove`, `replaced` unchanged |
| `HarborFlarePhase` | `HarborToastPhase` | T | Values unchanged |
| `HarborFlareQueue` | `HarborToastQueue` | T | Values unchanged |
| `HarborFlareHold` | `HarborToastHold` | T | |
| `HarborFlareTransitionBuilder` | `HarborToastTransitionBuilder` | T | |
| `HarborFlarePolicy` | `HarborDefaultsScope(defaults: HarborDefaults(toastQueue:))` | replacedBy | Deprecated into `HarborDefaultsScope` (Q19), never renamed (principle 5). Only its constructor is deprecated: deprecating the class made `dart fix` crash on `HarborFlarePolicy.queueOf` |
| `HarborSignals`, `HarborSignalSlot`, `HarborSignalTarget`, `HarborSignalEntry`, `HarborSignalTransitionBuilder`, `HarborSignalClosedReason` | — | — | Already deprecated aliases. They now alias aliases, which compiles; their existing messages must name the new types, not the flare ones |
| `HarborController.flares` / `raiseFlare` | `toasts` / `showToast` | rename | Going `@internal` (audit step 9) |
| `HarborController.signals` | — | — | Already deprecated |

### Sheets and dialogs

| Old | New | Fix | Note |
|---|---|---|---|
| `showHarborSheet(breakwater:)` | `coversPage:` | RP | From the RFC |
| `showHarborSheet(keepsTopCoast:)` | `reachesTop:` | RP | The name `sheets.md` already chose, so the sheets step need not rename it again |
| `HarborSheet.headerWake` / `footerWake` | `headerEdgeEffect` / `footerEdgeEffect` | RP | Q4 |
| `HarborSheet.footerTide` | `footerKeyboard` | RP | |
| `HarborSheet.clearsTopCoast` | `clearsTopSystemEdge` | RP | |
| `HarborSheet.bodyClearsTide` | `bodyClearsKeyboard` | RP | |
| `HarborSheet`, `HarborSheetExtent`, `HarborSheetController`, `HarborSheetBarrier`, `showHarborSheet`, `showHarborDialog`, `HarborDialogRoute` | unchanged | | Plain. `HarborSheetBarrier` is replaced by `HarborBarrier` in the sheets step, and the header and footer knobs by `headerBar:`/`footerBar:` (`sheets.md`, as shipped) |
| `HarborBreakwater` | `HarborPageCover` | T | Going `@internal` |
| `HarborController.addBreakwater` / `addBreakwaterEdge` / `breakwaterTopsInGlobal` / `breakwaterCoverage` / `breakwaterChanges` | `addPageCover` / `addPageCoverEdge` / `pageCoverTopsInGlobal` / `pageCoverage` / `pageCoverChanges` | rename | Going `@internal` |
| `showHarborDialog(inheritClearWater:)` | `inheritRoom:` | RP | And on `HarborDialogRoute` |
| `closeHarborSheet` | — | — | Already deprecated |

### Keeping things in sight (the lighthouse)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborBeacon` | `HarborKeepInSight` | T | From the RFC. Split after 0.9.1 (below), and `HarborKeepInSight` is deprecated whole |
| `HarborKeepInSight(onObscured:)` | `HarborCoverageListener(edge:, onCoverage:, child:)` | conditional fix | The audit's split (owner, 2026-10-14): reports what covers it |
| `HarborKeepInSight(keepInSight:)` | `HarborKeepVisible(active:, onlyWhileFocused:, clearance:, child:)` | conditional fix | Keeps itself scrolled clear of the bars and the keyboard, on by default; `keepInSight:` given a variable becomes `active:` |
| `HarborKeepInSight(lift:)` | `HarborLift(active:, clearance:, holdPosition:, child:)` | conditional fix | Lifts over what covers the bottom, inside a region. A call that does two jobs is manual: nest the widgets |
| `HarborKeepInSight.reveal` / `coverageOf` | `HarborKeepVisible.reveal` / `coverageOf` | RB | |
| `HarborLighthouse` | `HarborKeepInSight` | T+S | Its statics `reveal` and `coverageOf` move onto the widget class, as `Scrollable.ensureVisible` sits on `Scrollable`, and on to `HarborKeepVisible` after 0.9.1. A typedef to a widget is harmless here: `HarborLighthouse` is `abstract final` and nobody constructs it |
| `HarborLighthouseRegion` | `HarborKeepInSightRegion` | T | And `HarborKeepVisibleRegion` after 0.9.1 (T), so the names match |

### The inspector (the chart) and the frame registry (the fleet)

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborChart` | `HarborInspector` | T | `snapshot`, `snapshotOf`, `snapshotAll`, `nearest` unchanged |
| `HarborChartEntry` | `HarborInspectorEntry` | **SUB** | SUB, not T, as shipped (owner review): it takes the old parameter names, so the new constructor keeps them `required` |
| `HarborChartEntry.clearWater` / `docks` / `tide` | `room` / `bars` / `keyboard` | rename | |
| `HarborChartOverlay` | `HarborInspectorOverlay` | T | |
| `ext.harbor.chart` (VM service) and its JSON keys `clearWater`, `docks`, `tide` | `ext.harbor.inspector`, `room`, `bars`, `keyboard` | M | A wire format for tools. Register both names for the deprecation window and send both key sets; tools are not reached by `dart fix` |
| `HarborFleet` | `HarborFrameRegistry` | T | Every frame under one root |
| `HarborFleet.harbors` / `sea` | `frames` / `root` | rename | `topmost`, `addObserver`, `removeObserver` unchanged |
| `HarborFleetObserver` | `HarborFrameObserver` | T | As `NavigatorObserver`. `didJoin`, `didLeave` unchanged |
| `HarborController` | unchanged | | Plain, and the brand prefix covers it. After 0.9.1 its public surface is `hideBar`, `attachBar` / `updateAttachedBar` / `detachBar`, `addPageCover` / `addPageCoverEdge`, `room` / `roomInGlobal`, `registry`, `debugLabel` and `isPage`; the rest is `@internal` (`parent`, `route`, `isRouteLevel`, `withBarOn`, `edgesWithBars`, `claimedStateOf`, `attachedBarsOn`, `pageCoverage`, `pageCoverChanges`, `pageCoverTopsInGlobal`, `toasts`, the leave listeners, and `HarborController.of` / `maybeOf`, for which `HarborFrame.of` / `maybeOf` stand). Their 0.8 names lose their rename fixes, which would have traded a deprecation for `invalid_use_of_internal_member` |
| `HarborController.fleet` | `registry` | rename | |
| `HarborController.makeWay` | `hideBar` | rename | Q2 |
| `HarborController.addPontoon` / `updatePontoon` / `removePontoon` / `pontoonsOn` | `attachBar` / `updateAttachedBar` / `detachBar` / `attachedBarsOn` | rename | |
| `HarborController.withDockOn` / `dockedEdges` | `withBarOn` / `edgesWithBars` | rename | |
| `HarborController.isPort` / `isSea` | `isPage` / `isRoot` | rename | `isPort`'s stale doc is fixed in audit step 9 |
| `HarborController.lastLayout`, `renderBox` | — | — | Already deprecated |
| `HarborScaleModel` | `HarborScaledScreen` | T | Departure: the RFC's `HarborScaledFrame` reads as a kind of `HarborFrame`, which it is not. It lays out a whole screen at a reference size |
| `HarborScaleModel.letterbox`, `referenceSize`, `devicePixelRatio` | unchanged | | `coast` → `systemEdges` as above |
| `HarborSizing` | unchanged: a class | rename (`hugBody`) | After 0.9.1 a class: `HarborSizing.fill` (a constant, as before) and `HarborSizing.hug({maxFraction})`. `hugBody` is a deprecated constant equal to `hug()`, renamed to `hug()` by the fix; `values`, `name` and `index` are kept, deprecated |

## 4. The table: `package:harbor_test`

`harbor_test` ships its own `lib/fix_data.yaml`, released after harbor as CLAUDE.md describes. The
package name stays: it is on pub.dev, and "test" is plain.

| Old | New | Fix | Note |
|---|---|---|---|
| `HarborSeaTrials` (extension on `WidgetTester`) | `HarborTrials` | rename (`extension:`) | Rarely written. As shipped: an extension cannot be aliased, so the old one stays as a deprecated extension holding only `pumpSeaTrial` |
| `pumpSeaTrial` | `pumpHarborTrial` | rename | Measured: `inExtension: 'HarborSeaTrials'` matches only the explicit `HarborSeaTrials(tester).pumpSeaTrial()`; the implicit `tester.pumpSeaTrial()` matches by its target's type, `inClass: 'WidgetTester'`. Keyed both ways |
| `pumpSeaTrial(tideIn:)` | `keyboardShown:` | RP | |
| `HarborSeaTrial` | `HarborTrial` | T | |
| `HarborSeaTrial.raiseTide` / `lowerTide` | `showKeyboard` / `hideKeyboard` | rename | |
| `HarborSeaTrial.setTide(tideIn:)` | `setKeyboard(shown:)` | rename + RP | |
| `HarborSeaTrial.tideIn` | `keyboardShown` | rename | |
| `HarborSeaTrial.waterline` | `keyboardTop` | rename | The device height less the keyboard |
| `HarborSeaTrial.clearWaterAround` / `docksAround` | `roomAround` / `barsAround` | rename | |
| `isInClearWater` | `isInRoom` | rename (`function:`) | |
| `HarborTrialDevice` | unchanged | | Plain |
| `HarborTrialDevice.coast` / `tideHeight` | `systemEdges` / `keyboardHeight` | RP + rename | The class keeps its name, so its constructor and `copyWith` take only the new names, `required` (harbor_test 0.4.0 is breaking there); the RP fix fires on the old, undefined ones. The old getters stay |
| `HarborTrialDevice.reportsCoastUnderTide` | `reportsSystemEdgesUnderKeyboard` | RP + rename | |
| `HarborTrialDevice.coastWhen(tideIn:)` | `systemEdgesWhen(keyboardShown:)` | rename + RP | |
| `HarborTrialDevice` presets, `phones`, `all`, `copyWith`, the rest | unchanged | | `copyWith(coast:, tideHeight:)` as above |

## 5. Collisions and traps

**With an existing harbor name**

- **`HarborClear`, the enum, and `HarborClear`, the widget.** One library cannot hold both, and a
  deprecated alias of the enum must keep its own name. Resolved by Q1: the enum goes first, and
  `clear:` becomes `bars: bool`, the same switch `HarborHandled` has.
- **`HarborKeyboard` is wanted twice.** The RFC writes `keyboard: HarborKeyboard.rides` for the
  stance, and `HarborTide.of(context)` needs a home too. Resolved by Q3: the reader is
  `HarborKeyboard`, the enum `HarborKeyboardStance`.
- **`HarborBar.attached` and `HarborBar.withdraw` are not constructible.** `HarborBar` (today's
  `HarborDock`) is a value, not a widget, and `HarborPontoon` and `HarborMakeWay` are widgets that
  wrap a child. A pontoon also holds an overlay or a solid bar, so "attached" is not a third kind
  beside them. Resolved by Q2.
- **"Edge" means two things.** `HarborEdge` (and every `edges:` and `edge:` parameter) is a side of
  the frame; `systemEdges` is what the platform takes at the sides. Kept: the RFC adopted it, and
  it reads correctly in both places (`HarborClear(edges: {HarborEdge.bottom})` is "clear at the
  bottom"). The README should say once that a system edge is an inset *at* an edge.
- **"Room" means two things.** `HarborRoom.of(context)` is the insets around the room (system
  edges, bars, fades, margin); `controller.room` is the rectangle itself. Q6.
- **"Frame" means two things.** `HarborFrame`, and a frame drawn by the engine ("the dock makes way
  a frame later", README:466). The README should say "the next frame drawn" for the second, as it
  mostly does already. `HarborWatersAspect.frame` and `frameSize` already mean the first.
- **"Float" means two things for one release.** `HarborFloat` (the overlay) arrives while
  `HarborTideStance.float` is still a deprecated alias of `.rides`. They never meet in a type, only
  in prose: the README must not say "a floating bar" for a bar that rides the keyboard.
- **"Clear" means two things.** `HarborClear` and `clear:` keep clear; `HarborSheetBarrier.clear`
  (and `HarborBarrier.clear` later) is transparent. Different types, so no compile collision.
- **`HarborToastEntry.timing`** is today's `ValueListenable<int>` that ticks when `duration` is
  set, and `flares.md` brings a `timing:` of type `HarborToastTiming`. `flares.md` already marks the
  getter as plumbing that goes internal in the handle split; that must land before, or with, the
  timing value.
- **Two names still end in *State* without being a `State`**: `HarborKeyboardState` and
  `HarborBarState`. README:125-126 keeps its note with the new names.

**With Flutter and common packages.** With the prefix, no new name collides with a Flutter symbol
or with the toast and popover packages (`fluttertoast`'s `Fluttertoast`, `oktoast`'s `OKToast`,
`popover`'s `showPopover`). What a name implies is the trap:

- `HarborScrollView` is a `StatelessWidget`, not a `ScrollView` subclass; `is ScrollView` is false,
  and it has no `buildSlivers`. Its dartdoc says so in the first line.
- `HarborSliverBar` pins and stacks, but it is not a `SliverAppBar`: no `expandedHeight`, no
  `flexibleSpace`.
- `HarborInspector` has nothing to do with Flutter's `WidgetInspector` or DevTools' inspector. Its
  dartdoc says it is a debug overlay and a snapshot API.
- `HarborToast` must not be read as Android's `Toast`: it is any widget, anywhere in the room,
  taking turns like a `SnackBar`. The README's Flutter row already makes the snack-bar comparison.
- `HarborFrame.page` beside Navigator 2.0's `Page`: the same idea (a route's content), and the
  dartdoc can say so.

**Mechanical traps for the release itself** (§2): `HarborDock` must be a deprecated subclass, not a
typedef, and so must `HarborBuoy`, `HarborCoast`, `HarborWake` and `HarborFairway` (found in the release); every renamed static is kept as a deprecated forwarder on the **new** class and its fix is
keyed there; every renamed enum value is a deprecated `static const` on the new enum, keyed
`constant:`. The existing `lib/` has no `fix_data` yet; the placement work adds the first file, and
this release adds `lib/fix_data/rename.yaml`.

**What will need rewording** (listed, not rewritten):

- `README.md`, nearly every section:
  - the tagline (lines 10-12);
  - "The one rule" (quay and pier);
  - the 27-row Glossary, which becomes the "Renamed in 0.x" table;
  - "In Flutter's terms", which shrinks to the rows where harbor differs;
  - the pronunciation note (128-129), which goes;
  - the *State* note (125-126);
  - Getting started, Docks, Content, The tide, A keyboard the platform does not report, Harbor and
    Scaffold, Talking to the harbor, Buoys and flares (including the signals history, 610-612),
    Sheets and dialogs, The lighthouse, Accessibility, TV, The chart, Sea trials and Example.
- `lib/harbor.dart`'s library comment, every dartdoc that says coast, tide, dock, water, wake,
  moor, port, flare, buoy or breakwater, and every `debugFillProperties` label (`tide: float` in
  `HarborDock.pier(tide: float, debugLabel: "composer")`).
- `harbor_test/pubspec.yaml`'s description ("Sea trials for harbor ... clear-water matchers"). The
  root `pubspec.yaml` description is already plain.
- **The field guide's entry names**, all in `example/lib/field_guide/entries_*.dart` (`className:`):
  - `Harbor`, `Harbor(newPort: true)`, `Harbor.bodyClearsTide`, `HarborSea`;
  - `HarborDock.pier`, `HarborDock.quay`, `HarborDock.hitTestBehavior`,
    `HarborDock.restingExtent + HarborFollow`, `HarborDock.withdrawsAtHighTide`, `HarborDockState`,
    `HarborCoastStance`, `bottom: [composer, tabBar]`;
  - `HarborCoast`, `HarborCoast.titleSafe`, `HarborTide.of`, `HarborTideStance.float`,
    `HarborTideStance.pilings`, `HarborTideStance.float + .pilings`, `HarborTideStance.dryDock`;
  - `HarborMoored`, `HarborMooringLine`, `HarborCastOff`, `HarborOpenWater`, `HarborFairway`,
    `HarborFairwaySliver`, `HarborSliverDock`, `HarborWakePainter`;
  - `HarborMakeWay`, `HarborPontoon`;
  - `HarborBuoy`, `HarborBuoy(modal: true)`, `HarborBuoy.anchored`, `HarborPortalBuoy`,
    `HarborFlares.raise`;
  - `HarborBeacon(keepInSight:)`, `HarborBeacon(onObscured:)`, `HarborLighthouseRegion`;
  - `HarborScaleModel`, `HarborChart`, `HarborSizing.hugBody`, `showHarborSheet(breakwater: true)`,
    `showHarborDialog(inheritClearWater:)`, `pumpSeaTrial`;
  - the stage titles (`'A breakwater sheet'`, `'The breakwater'`, `'outer Harbor pier'`,
    `'HarborSeaTrial'` and the rest).

  Each entry's `realWorld` text and drawing describe the namesake (Q5).
- **The showcase narration**, `example/lib/showcase/narration.tsv`: chapters `sea`, `coast`,
  `pier`, `quay`, `wake`, `moored`, `mooring`, `fairway`, `sliverdock`, `openwater`, `tide`,
  `drydock`, `makeway`, `pontoon`, `buoy`, `portal`, `signal`, `sheet`, `breakwater`, `dialog`,
  `sticky` ("below the docks"), `lighthouse`, `chart`, `trials`, `outro`. Only `intro` is plain
  already. Also the captions in `example/lib/showcase/caption.dart`, the checks in
  `example/test/showcase_test.dart` that compare each caption with the page, and the wide video's
  `example/lib/showcase_wide/narration.tsv` (`intro` to `outro`). All are re-voiced through
  `example/tool/narrate.py`, so the timeline moves with them.
- The example game's names ("Harbor Office"), and `example/integration_test/play_through_test.dart`
  where it names harbor symbols.

## 6. Departures from the RFC

DECISIONS adopted the RFC table with five choices and one correction. This file departs from it in
these places, each for a reason given above:

| RFC | Here | Why |
|---|---|---|
| `HarborBar.attached` | `HarborAttachedBar` (widget) | Q2 |
| `HarborBar.withdraw` (`dark` / `slide`) | `HarborHideBar` (widget), `mode:` still `HarborYield` | Q2 |
| `keyboard: HarborKeyboard.rides` | `keyboard: HarborKeyboardStance.rides` | Q3 |
| `HarborEdgeFade` | `HarborEdgeEffect` | Q4 |
| `HarborRowInsets` | `HarborClear.rowInsets` | DECISIONS (audit step 7) made it a constructor; a measured `replacedBy` gets there in one step |
| `HarborScaledFrame` | `HarborScaledScreen` | Not a kind of `HarborFrame` |

### Found in the rename release

What shipped differs from the tables above in these places, each measured by `test_fixes/`:

- `HarborBuoy`, `HarborCoast`, `HarborWake` and `HarborFairway` are deprecated subclasses (**SUB**),
  not typedefs (§2), as `HarborDock` is.
- So are `HarborTideState`, `HarborWakeBand`, `HarborWakeMask`, `HarborPortalBuoy`, `HarborPontoon`,
  `HarborDockRecord` and `HarborChartEntry` (owner review): kept on the new constructor, a renamed
  required parameter would have to become optional beside its old name and be asserted. As
  subclasses they carry the old names, and every new constructor keeps `required`.
  `HarborLayoutRecord` and `HarborTrialDevice` keep their names, so their old parameter names are
  dropped (breaking), and their `renameParameter` fixes still fire on an undefined parameter
  (`test_fixes/rename_constructors.dart`, `rename_trials.dart`).
- A `bool` that says what something keeps clear of is named `clears…` (owner review), as
  `bodyClearsKeyboard`, `clearsSides` and `clearsTopSystemEdge` are: `clearsKeyboard:` and
  `clearsBars:` on `HarborClear`, `HarborScrollView`, `HarborSliverClear`, `HarborHandled`,
  `paddingOf` and `clearanceOf`, where the draft had `keyboard:` and kept 0.8.0's `bars:`. `bars:`
  is deprecated with a fix, and `bars.yaml` writes `clearsBars:`. A bar's `keyboard:` is a
  `HarborKeyboardStance` and stays.
- The fade collections are named after fades (Q4): `fadeBands`, `fadeBandsPainted`, `fadeBandOf`,
  `HarborFadeMask(bands:)`, and the `HarborEdgeEffectPainter`'s map. `HarborScrollView.edgeEffects`
  is a `bool` (whether its content fades) and keeps the name.
- Positional parameters take the new words, as they show in hovers and generated overrides:
  `attachBar(edge, bar)`, `updateAttachedBar(handle, edge, bar)`,
  `HarborFrameObserver.didJoin(frame)` / `didLeave(frame)`, `HarborKeepInSight.coverageOf(box, frame,
  edge)`. An override that kept `harbor` gets `avoid_renaming_method_parameters`; no fix renames it.
- An old parameter and its new name, both given, must agree, or it is an assert. Inside a `const`
  constructor the check compares with `identical`, since `==` on a type with its own equality is
  not a constant expression.
- **Done in a mechanical follow-up after 0.10.1** (deferred from the release): the source files are
  named after the types they hold (`bar.dart`, `keyboard.dart`, `room.dart`, `system_edges.dart`,
  `scroll_view.dart`, `clear.dart`, `keep_in_sight.dart`, `inspector.dart`, `edge_effect.dart`,
  `scaled_screen.dart`, `frame.dart`, `render_frame.dart`; `buoy.dart` split into `float.dart` and its
  parts `anchor.dart`, `popover.dart`, `toast.dart` and `placement_engine.dart`; `make_way.dart` into
  `hide_bar.dart` and `attached_bar.dart`), private and internal names are in the new words
  (`HarborKeyboardScope`, `HarborFloatLayer`, ...), and so are the test files and their descriptions.
  None is public API, so none needs a forwarder or a fix. `dock_slot.dart` keeps its name, after the
  deprecated `HarborDockSlot` it holds, and every deprecated name keeps its spelling.
- **Re-voiced after 0.10.1** (Q5): both showcase videos. The chapters are keyed and captioned by the
  API they show (`overlay` captioned `HarborBar.overlay`, `coverspage` captioned
  `showHarborSheet(coversPage: true)`, ...), the narration says what each does with the harbour as
  illustration ("Like a quay, a stone wall on the shore"), the plates take the field guide's
  `className` and `realWorld` instead of a pinned copy of the 0.8 labels, and the phone's bars lost
  the `pier` and `quay` debug labels, so the inspector chapter shows their kinds.
- `HarborSeaTrials` is a deprecated extension of its own, and `pumpSeaTrial`'s fix is keyed on
  both the extension and `WidgetTester` (§4).
- Harbour words the tables left out are renamed the same way, with forwarders and fixes:
  `HarborWaters.clearanceOf(tide:)` → `clearsKeyboard:`; `HarborMoored.clearanceOf` and
  `HarborFairway.paddingOf` take the same renamed parameters as their widgets;
  `HarborWatersData`'s constructor and `copyWith` take the renamed field names.
- `bars.yaml` (0.8.0) still rewrites `clear: HarborClear.coast` and `.everything`, keyed on the new
  classes and on `HarborFairway`, though the enum and `clear:` are gone, so a 0.7 call migrates in
  one run. A 0.8 call that gave both (`bars: b, clear: HarborClear.coast`, read as `b && false`)
  comes out with one `clearsBars: false`, not two arguments.
- The placement fix of an anchored flare drops `reachesCoast:` (a no-op by an anchor since 0.6.3),
  which would assert once the call takes a `HarborAnchored` placement.

## 7. Open questions

1. **The order for `HarborClear`.** The widget cannot take the name while the enum holds it.
   *Recommendation:* a small release before the rename adds `bars: bool` to `HarborMoored`,
   `HarborFairway`, `HarborFairwaySliver` and `paddingOf`, and deprecates `clear:` and the enum,
   with a CHANGELOG note (the change depends on the value, so no fix; it has 16 call sites in this
   repo's example and tests). The rename release then removes the enum, ahead of the batch removal,
   and `HarborMoored` becomes `HarborClear`. `bars:` is a new-vocabulary word arriving one release
   early, which is cheaper than renaming the parameter twice. Removing early is allowed before 1.0.
2. **Pontoon and make-way as widgets.** `HarborBar.attached` and `.withdraw` cannot be constructors
   of a value class (§5). *Recommendation:* `HarborAttachedBar(edge:, bar:, child:)` and
   `HarborHideBar(edge:, mode:, child:)`. Verb-phrase widget names have Flutter precedent
   (`IgnorePointer`, `ExcludeSemantics`). The controller methods follow: `attachBar`, `hideBar`.
3. **`HarborKeyboard`: reader or stance?** *Recommendation:* the reader, `HarborKeyboard.of(context)`
   and `isShownOf`, because it is what content calls. The stance becomes `HarborKeyboardStance` with
   `rides`, `stays` and `reserves`, beside `HarborSystemEdgeStance`. An enum carrying both values
   and an `of` (as `HarborHinge` does) would mix a policy with a reading.
4. **The wake's new name.** The RFC's `HarborEdgeFade` misnames two of its three variants:
   `HarborEdgeFade.hairline` is a line, and `.none` is nothing. *Recommendation:*
   `HarborEdgeEffect` (`.fade`, `.hairline`, `.none`). It covers all three and is the word iOS uses
   for the same thing (the scroll edge effect). Where only a fade has a length, the names stay
   specific: `HarborFadeBand`, `HarborFadeMask`.
5. **The field guide and the videos are built on the metaphor.** Every field guide entry pairs the
   class with "a drawing of the real thing it's named after", and the narration explains each
   class by its namesake ("The quay, a stone wall on the shore"). *Recommendation:* keep the
   harbour as the illustration and the brand, since the package is still harbor, but stop
   presenting it as the meaning. Entries are titled by the new class name, the drawing is captioned
   as an illustration ("like a quay, the body stops at it"), and the narration is rewritten and
   re-voiced after the rename release. The rename does not wait for the videos.
6. **One word, `room`, for both waters and clear water.** DECISIONS chose `room` for both.
   `HarborRoom.of(context)` returns the insets around the room, and `controller.room` returns the
   room's rectangle. *Recommendation:* keep it. The data describes what bounds the room, and its
   fields (`systemEdges`, `bars`, `edgeEffects`, `margin`) say so. The alternative,
   `HarborInsets`, is plainer but generic enough to be mistaken for an `EdgeInsets` helper. Review
   should confirm this rather than let the table settle it silently.
