# API decisions for #120

Decided by the owner agent on 2026-10-14. Jonah delegated these: "make the decisions you believe are
right for the product ... Breaking changes are okay. Add dart fixes if you can." The proposals they
settle are the other files in this directory. Where a proposal and this file disagree, this file
wins.

## How every change ships

- **Deprecate first, then remove.** Each reshaped API ships in a minor release that keeps the old
  spelling as `@Deprecated` and forwards it to the new one, with a `fix_data` transform so that
  `dart fix --apply` rewrites call sites. The old spellings are removed together in one breaking
  release before 1.0. A data-driven fix only works reliably while the old element still exists, so
  this order is what lets the fixes carry the migration.
- **Fixes live in `lib/fix_data/`**, one YAML file per area (`placement.yaml`, `flares.yaml`, ...),
  so that parallel work does not collide in one file.
- **Every transform has a golden test** in `test_fixes/`, checked by
  `dart fix --compare-to-golden` in `tool/check.sh`. A fix that is not tested is a fix that rots.
  `test_fixes/` is excluded from analysis and pubignored.
- **A deprecation message names the replacement and says `dart fix` handles it**, where it does,
  and in which files: "`dart fix` applies it in a file that imports package:harbor/harbor.dart"
  (package:harbor_test/harbor_test.dart for harbor_test). The analyzer offers a data-driven fix only
  in a file that imports one of the element's `uris:`, and reads the file's own imports, not the
  library that declares the element or one that re-exports it (`ElementMatcher.matches`,
  `data_driven/element_matcher.dart:132`, Dart 3.13.3). So a file that reaches a member through a
  helper's typed field, without importing harbor, is not migrated (#150), and the Migrating notes
  say to add the import first. Listing the declaring `src/` library in `uris:` does not help.
  Listing `dart:core`, which every library imports implicitly, does make the fixes fire everywhere
  (measured in #150), and was rejected: the documented contract is that `uris:` are public libraries
  that include the element, so it is off-spec, and an analyzer that validated `uris:` could drop
  every harbor fix rather than fall back. It also rewrote another package's class that shares a
  harbor class's name and a deprecated member's name, into code that did not compile. The Dart team
  knows the gap: dart-lang/sdk#59764 (following exports would be "ideal, but I don't know whether
  it's feasible") and the open request dart-lang/sdk#62491. `test_fixes/helper_reach.dart` fails
  when the analyzer follows the element, and the notes can go.
- **The CHANGELOG has a "Migrating" note** for anything a fix cannot express, such as a behaviour
  change or a default that moved.
- New public names are plain where the concept is plain (placement, aligned, anchored, barrier,
  timing, defaults). Nautical names stay on harbor's own ideas (buoy, flare, dock, clear water).
  Whether harbor's own ideas get renamed (#120) is decided last, once the surface is smaller.

## Fix data after 1.0 (1.0.0-dev.1, 2026-10-16)

1.0 removes every deprecated name, so a 0.x call is no longer `deprecated_member_use` but
`undefined_*`, and a data-driven fix fires only where the analyzer offers one for that diagnostic.
Measured in a scratch consumer (Dart 3.13, the Flutter in `.fvmrc`): every `test_fixes/` input, a
0.8-era file, fixed against 0.10.3 and against 1.0, then compared with the goldens. Against 0.10.3
every golden matched. Against 1.0:

- **Still fire:** type renames (typedefs and removed subclasses), member renames through a
  receiver or in a subclass, methods through implicit `this`, parameter renames, and the composite
  rewrites (`placement.yaml`, `sheets.yaml`, `toasts.yaml`, `bars.yaml`, `audit.yaml`,
  `defaults.yaml`), in calls written without `const`. A transform keyed on a surviving class fires
  even where the member it names is gone (`HarborFloat.anchored`, `HarborScrollView.box`).
- **Kept, re-keyed:** `HarborDock.pier`, `.quay` and `.reserve`. Keyed on `HarborDock`, they never
  matched once the class was gone, and the class rename turned `HarborDock.pier(...)` into an
  undefined `HarborBar.pier(...)`. Keyed on `HarborBar`, where the rename lands them, they fire on
  the next pass, parameters included. The owner chose to re-key rather than drop, since these are
  the most-used 0.8 calls.
- **Kept, guarded:** `HarborFlarePolicy` to `HarborDefaultsScope`. Unguarded, it matched
  `HarborFlarePolicy.queueOf(context)` against 1.0, its `queue` template was invalid, and the
  analysis server threw ("Cannot access an invalid result") and left `dart fix` hanging for the
  whole project. `if: "queue != ''"` keeps it to the constructor call; `test_fixes/defaults.dart`
  keeps the `queueOf` line.
- **Dropped, cannot fire:** renamed enum values (`undefined_enum_constant` gets no data-driven
  fix), `HarborKeepInSight.reveal` and `.coverageOf` (keyed on a class that splits rather than
  being renamed), the `HarborDock`-keyed constructor transforms (re-keyed above), and
  `pumpSeaTrial` keyed on `HarborSeaTrials`. Re-keying that one on `HarborTrials`, by `inExtension:`
  or `inClass:`, was measured and does not fire: no data-driven fix for a method an extension
  override lacks. Dropped, firing into nothing: `HarborToastEntry.raisedIn` and `reachesCoast`,
  whose targets 1.0 removed too.
- **Left, the analyzer's:** a `const` creation of a removed class gets no fix at all (written
  without `const`, the same call migrates fully), a getter read through implicit `this` in an
  extension, a tear-off of a removed constructor, and a removed name in a `show` list.
  `test_fixes/jump_to_1_0.dart` records each, and the CHANGELOG lists them with the advice to step
  through 0.10.3, where every fix applies. The `dart:core` `uris:` workaround stays rejected (#150).

The goldens' inputs now write removed-class creations without `const`, so they keep checking the
transforms rather than the `const` limit, and `rename_values.dart` is gone with the enum-value
renames it checked.

## Naming (#120): adopt the rename

Harbor's capabilities are worth learning; the harbour words are a tax on top of them. The README
needs a 27-row table to translate them back into layout ideas, and a consumer that wrapped harbor
in its own adapters reached for plain words (root, bar, padding, scroll view, keep in sight,
anchor, toast) without being steered. So the API is renamed after the model it implements: **every
edge of the screen is claimed once, by the layer that owns it, and everything inside gets what is
left.** The `Harbor` prefix stays as the brand.

The RFC's table is adopted, with these choices on its open questions and one correction:

- **`room`** for what is left (clear water, waters).
- **`HarborBar`**, not `HarborEdgeBar`: `HarborBar.solid` (quay), `.overlay` (pier),
  `.attached` (pontoon).
- **`HarborClear`** for content that keeps clear of what is in the way (moored). It does more than
  `SafeArea`, so it should not borrow that name.
- **`HarborToast`** / **`HarborToasts.show`**, not `HarborNotice`. Toast is what developers search
  for, and harbor's flare is a transient message whatever it carries.
- **`HarborFrame`** with a **`HarborFrame.page`** constructor for a route boundary. The boundary is
  not inferred (see the audit's `newPort` step below): a route under the root needs no `.page`.
- **Correction:** the portal buoy becomes **`HarborPopover`**, not `HarborAnchored`.
  `HarborAnchored` is the anchored placement value from the placement work. The three overlays
  then read by their lifetime, in words developers know: `HarborFloat` (declared in the tree,
  formerly buoy), `HarborPopover` (opened on demand by an anchor, formerly portal buoy) and
  `HarborToast` (transient, formerly flare).

The complete old-to-new table is `naming.md`, reviewed and accepted on 2026-10-14 with its six
recommendations:

1. A small release before the rename adds `bars: bool` and deprecates the `HarborClear` enum, so the
   widget can take the name.
2. Pontoon and make way become the widgets `HarborAttachedBar` and `HarborHideBar`.
3. The keyboard reader is `HarborKeyboard`, and the stance is `HarborKeyboardStance`
   (`rides`, `stays`, `reserves`).
4. The wake becomes `HarborEdgeEffect` (`.fade`, `.hairline`, `.none`).
5. The harbour stays as illustration and brand in the field guide and the videos, but no longer as
   the meaning.
6. `room` serves for both clear water and waters.

Order of work:

1. The placement change, already in progress. Its new types are plain names already.
2. **One rename release**: new names, every old name kept as a deprecated typedef or forwarding
   member, `lib/fix_data/rename.yaml` covering every rename, and the README and field guide on the
   new names, with a short "Renamed in 0.x" table. Before it is applied, a complete old-to-new
   table for every public symbol is drafted in `doc/design/naming.md` and reviewed. The rename
   runs alone, because it touches every file.
3. The flares, sheets, defaults and smaller structural steps, written in the new vocabulary. So
   it is `HarborToastTiming`, not `HarborFlareTiming`.
4. One release before 1.0 removes every deprecated name.

## Placement (`placement.md`)

- Ship the sealed `HarborPlacement` with two variants, `HarborAligned` and `HarborAnchored`, and
  one internal placement engine used by the buoy layer, the portal buoy and the overlay flare.
- **Q1 `slot:` on `raise`:** keep it as a first-class shorthand, exclusive with `placement:`.
- **Q2 `HarborBuoy.anchored`:** deprecate it. `HarborBuoy(placement: HarborAnchored(...))`
  replaces it.
- **Q3 nullable anchor:** yes. `HarborAnchored.anchor` may be null only for `HarborPortalBuoy`,
  where it means "anchor to my child". `HarborBuoy` and `raise` assert it is non-null.
- **Q4 default side:** `HarborAnchored.side` defaults to `HarborAnchorSide.below`, the menu and
  toast case. It is a new type, so this breaks no existing call. The deprecated spellings keep the
  defaults they had (`above` for `HarborBuoy.anchored` and `HarborPortalBuoy`), and their fixes
  write `side: HarborAnchorSide.above` explicitly when the old call left it out, so a migrated call
  sits exactly where it did. `flips` stays nullable, and null keeps each host's behaviour.
- `HarborBuoySide` is renamed to `HarborAnchorSide` and `HarborBuoyCrossAlignment` to
  `HarborCrossAlignment`, with deprecated typedefs and `rename` fixes.
- An anchored placement asserts that `reachesCoast` is false, now that 0.6.3 made it a no-op.

## Flares (`flares.md`)

- Ship the `HarborFlareTiming` value, and fold `persist` into a null duration.
- **Q11 `duration:` shorthand:** no. `timing:` alone, so that "until lowered" has one spelling.
  The deprecated `duration:` and `persist:` forward to it, with fixes.
- **Q12 handle type:** split it. The public `HarborFlareEntry` becomes an `abstract final class`
  that says exactly what a caller may do, and the configuration lives in an internal subclass.
- **Q13 subtree timing:** not now. `HarborFlarePolicy`, or `HarborDefaults` once that lands, can
  gain it later.
- **Q14 nullable `side`:** keep it non-null until 1.0.

## Sheets, dialogs and modal buoys (`sheets.md`)

- Ship the shared `HarborBarrier` value (`.dimmed`, `.clear`, `.none`), replacing the
  `HarborSheetBarrier` enum and the loose barrier parameters on the sheet, the dialog and the modal
  buoy.
- **Q15 `none` on a dialog:** accept an assert. One shared type is worth it.
- **Q16 `modal:` on `HarborBuoy`:** deprecate it in favour of `barrier:`, and keep a read-only
  `bool get modal`.
- **Q17 header and footer defaults:** keep the sheet's own look, and publish it as
  `HarborSheet.defaultHeaderDock` / `defaultFooterDock` so a move to `headerDock:` starts from it.
- **Q18 `reachesTop` with `fillsScreenAtHinge`:** keep them separate, and document how one
  implies the other.

## Defaults (`defaults.md`)

- Ship `HarborDefaults` on `HarborSea` and `Harbor`, plus a standalone `HarborDefaultsScope`. The
  nearest scope wins, field by field.
- **Q19 standalone scope:** yes. `HarborFlarePolicy` deprecates into it.
- **Q20 `flareMargin`:** it applies only to flares whose placement `raise` builds itself (`slot:`
  or nothing).
- **Q21 shape:** flat, prefixed fields (`sheet…`, `flare…`). Revisit past about fifteen fields.
- **Q22 look and feel:** stays out of it. No widget-valued fields, ever.
- **Where `hinge:` and `barHinge:` live** (2026-10-15, at implementation): in `HarborDefaults`.
  `HarborRoot(hinge:)`, `HarborFrame(hinge:, barHinge:)` and `HarborFrame.page(hinge:, barHinge:)`
  are deprecated, forwarding into the frame's defaults with `defaults:` winning, and `dart fix`
  moves them (`defaults.yaml`). Keeping them as sugar was the other choice. Deprecating is the
  simpler one: one place to set a policy, one rule for which wins, no pair of spellings to
  document against each other, and the migration is mechanical. The overlay-level `hinge:`
  (`showHarborSheet`, `showHarborDialog`, `HarborToasts.show`, `HarborFloat`, `HarborPopover`)
  stays: it is the call-site override.
- **The fields, in the 0.9 names:** `hinge`, `barHinge`, `barrierLabel`, `sheetBarrierOnTapHint`,
  `sheetMaxWidth`, `toastQueue`, `toastTiming`, `toastAnimationStyle`, `toastMargin`. Nine.
  `flareDuration` became `toastTiming`, the `HarborToastTiming` value the flares step shipped, so
  that "how long" has one spelling at the call and in the defaults. The barrier step had given
  dialogs and floats an `onTapHint` too; the default stays `sheet…`, since the hint a Material app
  passes names the bottom sheet.
- **Nearest wins per frame** (2026-10-15, owner review): a frame's bars follow
  `own.barHinge ?? own.hinge ?? inherited.barHinge ?? inherited.hinge`, the order 0.9.1 had for a
  frame's own settings, so a frame's own `hinge` always beats a `barHinge` inherited from outside.
  `HarborDefaults.merge` carries it (a nearer `hinge` replaces an inherited `barHinge`), so frames
  and scopes beneath follow it too. No other field has a bar-specific twin.
- **Behaviour the CHANGELOG records:** `barHinge` is now inherited by nested frames, as `hinge` was,
  and a page's defaults cross into the sheets, dialogs and toasts it opens (they ride the themes
  those capture).

## The audit's smaller steps (`../../` issue #120 audit, steps 5–10)

All of these land after the four areas above, each with fixes:

- `HarborYield` merges into `HarborDockState`.
- `withdrawsAtHighTide` becomes a `HarborTideStance` value.
- `duration`/`curve` are dropped wherever `animationStyle` already covers them.
- `HarborSizing` becomes a class: `.fill` and `.hug(maxFraction:)`.
- Clearance naming:
  - `extra` becomes `padding`;
  - one spelling for "coast only";
  - one `mooringLine` default;
  - `HarborMooringLine` becomes a `HarborMoored` constructor;
  - `HarborOpenWater` is retired.
- Trim the surface:
  - `HarborController`'s internals go `@internal`;
  - ~~`HarborTitleSafe` folds into `HarborCoast`~~ **dropped** (2026-10-14): `HarborTitleSafe` is plain
    already (TV vocabulary, not harbour, as `naming.md` says), and its value is niche. Folding it
    into `HarborSystemEdges.titleSafe(fraction:)` would cost either compiling code (Dart cannot give
    one constructor the old positional `HarborTitleSafe` and the new named parameters) or ugly
    constructor names, for no gain in clarity. It keeps its name;
  - fix the stale `HarborCoastFeature.hinge` and `isPort` docs.
- `HarborBeacon` splits into three widgets, one per job. Named by the owner on 2026-10-14:
  `HarborCoverageListener(edge:, onCoverage:)` reports what covers it, `HarborKeepVisible` keeps itself
  scrolled clear (its whole job, so on by default; `reveal` and `coverageOf` move there), and
  `HarborLift` lifts over the keyboard inside a `HarborKeepVisibleRegion`. `HarborKeepInSight` is
  deprecated whole, forwarding exactly as before. `HarborKeepVisible` and `HarborLift` take `active:`,
  as `HarborHideBar` does, so a job can be switched off without remounting the child.
- One internal page-overlay host for flares and non-modal sheets.
- **`newPort`:** ~~infer it at route boundaries~~ **not inferred** (2026-10-14, measured). On an iPhone 17
  with a 50 overlay header and a 56 solid tab bar: `isPage` changes nothing for a route under
  `HarborRoot` (the root has no bars to reach in: the same rectangles, room data and frame size, and
  `test/audit_steps_test.dart` pins it), and inferring it at a nested `Navigator`'s routes would move
  their content 50 up, under the outer header, which a tab's own stack does not want. So `.page` is
  rarely written already, and `HarborFrame.page` stays explicit, for a frame inside another frame that
  should ignore its bars.

## harbor_material (2026-10-16)

harbor's core stays Material-free, as 0.2.0 made it ("harbor's core imports no design library, and a
test keeps it that way"), with a companion package for the Material pieces once people asked for
them. Two consumers have asked by writing the same glue by hand. Rubric did
first, and Flyby, adopting harbor fully, wrote it again as `AppFrame`, `showAppSheet`, a drag handle,
`AppToast` and a `HarborDefaults` filled from `MaterialLocalizations`. So the glue is a package,
`harbor_material/`, beside `harbor_test/` and built the same way: its own pubspec, CHANGELOG and
tests, a committed `pubspec_overrides.yaml` pointing harbor (and harbor_test) at the checkout, and a
directory of its own in `tool/check.sh`. It is not one of harbor's dev dependencies, so the root
analysis excludes it rather than resolve its imports without its `pub get`. 0.1.0 asks for
`harbor: ^1.0.0` and is released after harbor 1.0.0.

- **Which Material.** `package:flutter/material.dart`, the SDK's. Flutter 3.47 also publishes
  Material as `material_ui`, but its `Theme` and `ThemeData` are other classes, so a package built on
  one reads no theme in an app built on the other. Every consumer (Rubric, gravity_brew, Flyby)
  imports the SDK's, and the 3.47.4 SDK's `material.dart` carries no deprecation. If the framework
  copy is removed, as `test/boundary_test.dart` expects, harbor_material moves to `material_ui`
  with its consumers, in a breaking release of its own.
- **The names.** Each one is a harbor name with `Material` in it, as the package's name is:
  `HarborMaterialFrame` is a `HarborFrame` on a Material page. It is not `HarborScaffold`, because it
  is not a `Scaffold`: no drawer, no snack bar host, no `resizeToAvoidBottomInset`. It is not
  `AppFrame` either, since that name belongs to the app. `HarborMaterialBar.appBar` returns a
  `HarborBar`, as `HarborSheet.defaultHeaderBar` does. `HarborBar`'s constructors are harbor's, and
  an extension cannot add one, so it is a static on a class of its own. `HarborMaterialDefaults.of`,
  `HarborSnackToast` with `context.showSnackToast`, and `HarborMaterialSheet` with its
  `HarborMaterialSheetSurface` and `HarborMaterialDragHandle` follow the same pattern.
- **An AppBar's colour behind the status bar** comes from the bar's backdrop: a `Material` resolved
  by the `AppBar`'s own rules, listening to the same `ScrollNotificationObserver` the `AppBar`
  hears, so Material 3's scrolled-under colour and tint change with it. The other way would be to
  let the `AppBar` run under the status bar and pad itself, as it does in a `Scaffold`. A bar hands
  its child a `MediaQuery` with its own edge taken out, which is harbor's rule for every bar, and
  carving out an exception for one widget is not worth it. The cost is that a translucent `AppBar`
  colour is painted twice over the toolbar, which the docs say.
- **A drag handle with no header** goes in a solid bar, so a plain body starts below it, as Material
  pads a sheet's content below its handle. With a header, the handle goes above it, in the header's
  bar.
- **The sheet's surface is not clipped.** The content is clipped to the surface's shape by the
  transparent `Material` over it, not by `HarborSheet.clip`, which would clip the surface's shadow
  too.

**In harbor's core, with it (1.0.x):** a bar carries its child's annotations over the system edge it
pads. The platform reads the status bar's style at the middle of the status bar, and an `AppBar`
annotates only its own box, which a bar pads below the status bar. Measured on every phone trial
device, an `AppBar.systemOverlayStyle` in a top bar was never applied (`test/status_bar_style_test.dart`).
A `systemOverlayStyle:` on the bar was the other choice. The automatic one fixes every app that put an
`AppBar` in a bar, with no new API, follows the `AppBar`'s style as it changes, and works for any
annotation, so a bottom bar's reaches Android's navigation bar. A child with no annotation leaves the
lookup to the page, as before.

**Out of scope:** a top-anchored sheet, one that pulls down from under the status bar. Sheets come
up from the bottom. A pull-down panel is a float, a popover or an `OverlayPortal` that keeps clear
of the status bar by `HarborRoom.of(context).systemEdges`. The README says so where it describes
sheets.

## Handled for clearing, keeping the geometry (#162, 2026-10-21)

The room answers two questions on an edge: is something there (geometry: `barFaceOf`, `HarborRoom.of`'s
`bars` and `systemEdges`), and is something left to clear (consumption: `MediaQuery.padding` and every
widget that keeps clear). `HarborHandled` answered both with no. `HarborHandled(keepsGeometry: true)`
answers the second alone, for content that runs under a bar on purpose.

- **One record, not two.** The room data keeps its geometry and names the edges handled this way in
  `HarborRoomData.geometryOnly`. Widgets that keep clear read the room through `HarborRoom.clearingOf`
  (internal: `of(...)` with those edges handled), and `MediaQuery.padding` is zeroed as under any
  consumer, so a third-party list sees the same answer. The rejected shape is the one the issue's
  workaround had: an inherited "content handles the band" mark beside the room, which only the widgets
  that know it read.
- **`HarborRoom.of` is the geometry reader.** It no longer clamps a `geometryOnly` edge to
  `MediaQuery.padding` (which is zero there by design); every other edge is clamped as before.
  `steadySystemEdgeOf` is a clearing reader (a footer pads by it) and reads zero, as it does beneath
  any handled edge. A nested `HarborFrame` keeps clear, so it reads the clearing view.
- **`startsUnderBars` does not set it.** The brief proposed that a view starting under the bars mark its
  leading edge this way. Measured: slivers after the first already sit under the view's handled leading
  end, and the first sliver is handed the leading end back on purpose, so a hero's
  `HarborClear(clearsBars: false)` title keeps off the status bar (README). Marking it would break that.
  The primitive goes where the caller knows the content runs under the bar.
- **Named `keepsGeometry`**, the issue's own spelling, as a flag beside `clearsBars` and `clearsKeyboard`
  rather than a constructor: it is one more choice about what the layer handles. It requires
  `clearsBars: true` (an assert): handling the system edges alone while keeping their geometry has no
  case yet.
- **The inspector amount is 0.** A `HarborHandled` reports what it removed because the layer above it
  padded by that much by hand; this one marks content that moves nothing.
- Additive, so it ships in a minor (1.2.0).

## Product work outside the API

- **Android landscape trial devices**, gesture and 3-button: yes, in `harbor_test` and the
  field guide stage.
- **A "dock goes to the side" option:** not now. Panes plus side docks already cover it. Revisit if
  a consumer asks.
- **iPhone Duo poses:** when Xcode 27.1 is on this machine. That is not a blocker for anything above.
- **Field guide pages for hinge, panes, posture, reserve and the dual-screen device:** yes, once
  the Android landscape devices are on the stage.
- **The GitHub watcher checks when something changes**, not only 30 minutes after a turn: yes. It is
  owner tooling, outside the repo.
- **Not decided here, on purpose:**
  - **The watchdog's waiting probe** stays the human's call. showrunner leaves it to a human by
    design, because a probe the watched agent can set is an off switch.
  - **Who may start crawlers** (`roles.json`) is user-level permission and stays as it is.
