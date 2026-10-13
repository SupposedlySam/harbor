# Defaults: one place for app- and page-level policy

Status: proposal, 2026-10-13. Nothing here is implemented. Line numbers are against `987db9c`.
It builds on `placement.md` (`HarborPlacement`, `HarborAligned`, `HarborAnchored`) and assumes
that lands first.

## The problem, measured

An app sets some choices once and expects every page, sheet and toast beneath to follow them. In
harbor each of those choices travels by a different route, and some have no route at all:

| Choice | How it reaches a subtree today | Where |
|---|---|---|
| Overlay hinge policy | `HarborSea(hinge:)` / `Harbor(hinge:)` install an internal `HarborHingeScope`; read with `dependOn` | harbor.dart:553-555, hinge.dart:36-37, hinge.dart:95 |
| Dock hinge policy | `Harbor(dockHinge:)`, read by that harbor alone and never handed down; the sea cannot set it | harbor.dart:104, :534, :81 |
| Flare queue | `HarborFlarePolicy`, a public standalone `InheritedWidget`, read with `getInherited` (no dependency) | buoy.dart:2334-2345, read at :1782 |
| Flare margin | No subtree route. Per call, `null` means a hard-coded 16 or 8 | buoy.dart:551, :561, :1913, :2020, :2028 |
| Flare duration and animation | No subtree route. 4 s in the signature, 220 ms in the entry | buoy.dart:1736, controller.dart:146 |
| Barrier label | No subtree route. The README tells you to pass it on every call | README:520-522, :860, :872, :916; buoy.dart:381, dialog.dart:27-29, sheet.dart:671-673 |
| Sheet `maxWidth` | No subtree route. Per call | sheet.dart:715-717, README:919 |

**Correction to the brief.** The flare margin is *not* carried through `HarborWatersData`.
`HarborWatersData.margin` (waters.dart:109-112) is the mooring line, the page margin that
`HarborSea(margin:)` and `Harbor(margin:)` set and that an inner harbor inherits when its own is
null (harbor.dart:523-526). Flares never read it. That is a fifth nearest-wins mechanism, and a
sound one: it is measured geometry, it rides the waters' aspect system, and it stays where it is
(see "What must not go in").

Three consequences:

- **Two of the four routes disagree on dependency.** `HarborHinge.of` registers a dependency
  (hinge.dart:37), even when `raise` and `showHarborSheet` call it from a tap handler
  (buoy.dart:1780, sheet.dart:775). `HarborFlarePolicy.queueOf` does not (buoy.dart:2341), so
  its `updateShouldNotify` (:2344) never has a dependent to notify.
- **The page's policy stops at the route boundary.** Sheets, dialogs and flares capture the
  opening page's `InheritedTheme`s (sheet.dart:762, dialog.dart:64, buoy.dart:1759). Neither
  `HarborHingeScope` nor `HarborFlarePolicy` is one, and no other code installs a
  `HarborHingeScope` (the only one is at harbor.dart:554). So inside a sheet opened from
  `Harbor(hinge: HarborHinge.never)`, `HarborHinge.of` finds the sea's scope, and a flare raised
  from the sheet's content takes the app's policy rather than the page's. I read this from the
  source and did not run it.
- **A Material app repeats itself on every call.** README:912-933 is the recipe: a barrier label,
  an on-tap hint and a `maxWidth` per `showHarborSheet`, a label per `showHarborDialog` and per
  modal `HarborBuoy`. The example app passes none of them (`grep barrierLabel example/lib` finds
  nothing), so every barrier in it is announced in English whatever the locale.

## 1. The value type

```dart
/// Choices an app or page makes once for everything beneath it: which hinges overlays and
/// docks keep off, how flares queue and time, and what barriers are announced as.
/// Every field is nullable; null means "the next one out decides".
@immutable
class HarborDefaults with Diagnosticable {
  const HarborDefaults({
    this.hinge, this.dockHinge,
    this.barrierLabel, this.sheetMaxWidth, this.sheetBarrierOnTapHint,
    this.flareQueue, this.flareDuration, this.flareAnimationStyle, this.flareMargin,
  });

  /// Which hinges and folds sheets, dialogs, flares and buoys keep off.
  final HarborHinge? hinge;
  /// Which hinges and folds docks keep off, when that should differ from [hinge].
  final HarborHinge? dockHinge;
  /// What a screen reader announces for a sheet's, dialog's or modal buoy's barrier.
  final String? barrierLabel;
  /// The widest a sheet is drawn, centred, on a wide screen.
  final double? sheetMaxWidth;
  /// What tapping a sheet's barrier does, for a screen reader.
  final String? sheetBarrierOnTapHint;
  /// Whether a flare waits its turn or replaces the one up.
  final HarborFlareQueue? flareQueue;
  /// How long a flare stays in sight; a flare with `persist: true` ignores it.
  final Duration? flareDuration;
  /// How a flare comes in and leaves.
  final AnimationStyle? flareAnimationStyle;
  /// How far a flare raised at a slot keeps in from the clear water's edges.
  final EdgeInsetsGeometry? flareMargin;

  /// Harbor's own choices, written once: what every null resolves to at the top.
  static const HarborDefaults fallback = HarborDefaults(
    hinge: HarborHinge.avoidSeparating, barrierLabel: harborBarrierDismissLabel,
    flareQueue: HarborFlareQueue.wait, flareDuration: Duration(seconds: 4),
    flareAnimationStyle: AnimationStyle(duration: Duration(milliseconds: 220)),
    flareMargin: HarborAligned.defaultMargin,
  ); // dockHinge null: it follows hinge. sheetMaxWidth, sheetBarrierOnTapHint null: none.

  /// This, with every field [nearer] sets taking its place.
  HarborDefaults merge(HarborDefaults? nearer);

  /// The resolved defaults at [context], every field non-null except the three that may be.
  /// Rebuilds [context] when they change: for build methods (docks).
  static HarborDefaults of(BuildContext context);

  /// The same, read once without a dependency: for `raise`, `showHarborSheet` and other calls
  /// made from a handler.
  static HarborDefaults read(BuildContext context);
}

/// Merges [defaults] over those above it, for a subtree that is not a harbor.
class HarborDefaultsScope extends StatelessWidget {
  const HarborDefaultsScope({super.key, required this.defaults, required this.child});
}
```

`HarborSea` and `Harbor` each gain `final HarborDefaults? defaults`. `HarborSea`'s merges over
`HarborDefaults.fallback`; a `Harbor`'s over whatever is above it. Both install the same private
scope, an `InheritedTheme`, so the capture that sheets, dialogs and flares already do carries
it across the route. That closes the boundary gap above without new code in any overlay.

**Precedence, one rule.** A call-site argument wins. Otherwise the nearest scope that sets the
field wins, field by field: `Harbor(defaults: HarborDefaults(flareQueue: replace))` under a sea
that sets `barrierLabel` keeps the sea's label. `HarborDefaults.fallback` closes the chain.

**When it is read.** Overlays read with `read` at the moment they open or are raised, from the
opening context, as `hinge` is read today (sheet.dart:775, dialog.dart:136, buoy.dart:1780).
Docks read with `of` in `Harbor`'s build, replacing harbor.dart:534's
`widget.dockHinge ?? widget.hinge ?? HarborHinge.of(context)` with
`defaults.dockHinge ?? defaults.hinge`.

**Call-site parameters become nullable where they are not already.** `raise(duration:)` today
defaults to 4 s (buoy.dart:1736) and also accepts `null` for "until lowered". Switch the
spelling of "until lowered" to `persist: true`, which already exists, and let `null` mean "the
default". `HarborBuoy(barrierLabel:)` changes from `String` with a default (buoy.dart:305, :334,
:382) to `String?`. Code that *reads* `buoy.barrierLabel` sees a nullable type, which is the one
source-breaking edge here.

### What must not go in

- **Measured geometry**: the mooring line, `coast`, `minimum`, `bodyClearsTide`, `sizing`. These
  are inherited through `HarborWatersData` with aspects so that readers rebuild only for what
  they read (README:373-379). Moving them into a bag that rebuilds as a whole would undo that.
- **What a call is about**: `builder`, `placement`, `anchor`, `persist`, `liveRegion`,
  `semanticLabel`, `routeSettings`, a dock's `tide:` and `wake:`. These differ per call by nature.
  A default for them hides a decision the caller should make.
- **Design-library pieces**: a sheet's `surface`, `clip`, `contentBuilder`. They are widgets and
  callbacks, and they belong in the app's `Theme` or its own wrapper. harbor imports no design
  library, and a widget-valued default is a second theming system. (See Q4.)
- **Sea-only plumbing**: `observers`.
- **Anything an explicit `HarborPlacement` already carries.** `placement.md` puts the margin on
  the value, with one `static const` per variant. `flareMargin` therefore applies only where
  `raise` builds the placement itself, `slot:` or nothing (see Q2).

## 2. Before and after

**A Material app's sheets** (README:912-919, and every sheet after it):

```dart
// before, on every call
final MaterialLocalizations l = MaterialLocalizations.of(context);
showHarborSheet(context,
  barrierLabel: l.modalBarrierDismissLabel,
  barrierOnTapHint: l.scrimOnTapHint(l.bottomSheetLabel),
  maxWidth: Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640,
  builder: ...);

// after, once (MaterialApp.builder sits inside Localizations, so this re-runs on a locale change)
builder: (context, child) {
  final MaterialLocalizations l = MaterialLocalizations.of(context);
  return HarborSea(
    defaults: HarborDefaults(
      barrierLabel: l.modalBarrierDismissLabel,
      sheetBarrierOnTapHint: l.scrimOnTapHint(l.bottomSheetLabel),
      sheetMaxWidth: Theme.of(context).bottomSheetTheme.constraints?.maxWidth ?? 640,
    ),
    child: child!,
  );
},
showHarborSheet(context, builder: ...);
```

**A TV screen whose flares replace** (README:559-561, test/issues_117_118_test.dart:55):

```dart
// before
HarborFlarePolicy(queue: HarborFlareQueue.replace, child: page)
// after
HarborDefaultsScope(defaults: const HarborDefaults(flareQueue: HarborFlareQueue.replace), child: page)
// or, when page is a Harbor
Harbor(defaults: const HarborDefaults(flareQueue: HarborFlareQueue.replace), ...)
```

**A canvas page on a foldable** (README:749-751):

```dart
// before
Harbor(dockHinge: HarborHinge.never, top: [...], body: canvas)
HarborSea(hinge: HarborHinge.never, child: child!)
// after
Harbor(defaults: const HarborDefaults(dockHinge: HarborHinge.never), top: [...], body: canvas)
HarborSea(defaults: const HarborDefaults(hinge: HarborHinge.never), child: child!)
```

Overlay-level `hinge:` (`showHarborSheet`, `showHarborDialog`, `raise`, `HarborBuoy`,
`HarborPortalBuoy`) is unchanged. It is the call-site override.

## 3. Migration

**0.x release with deprecations (non-breaking apart from the `barrierLabel` type):**

- `HarborSea(hinge:)`, `Harbor(hinge:)`, `Harbor(dockHinge:)` become deprecated. Each folds into
  `defaults` in build, and the explicit `defaults` field wins over the deprecated parameter. On
  `HarborSea` that means `hinge` turns nullable with no default, so that "not given" can be told
  apart.
- `HarborFlarePolicy` becomes a deprecated `StatelessWidget` that builds a `HarborDefaultsScope`.
  `HarborFlarePolicy.queueOf` forwards to `HarborDefaults.read(context).flareQueue`. Code that
  relied on its being an `InheritedWidget` (looking it up by type) breaks. None does in this repo.
- `HarborHinge.of` stays and reads `HarborDefaults.of(context).hinge`. `HarborHingeScope` is
  `@internal` and goes.
- **Behaviour change, for the CHANGELOG:** `dockHinge` is now inherited. Today it is read by its
  own harbor only (harbor.dart:534) and never scoped, so a full-screen harbor nested in a page
  with `dockHinge: never` (a nested `Navigator`'s page) keeps its docks off the hinge. After this
  change it lays them across. The page's policy reaching into its sheets is a behaviour change
  too, and the intended one.
- `raise(duration: null)` as "until lowered" becomes `persist: true`. A debug assert catches
  `duration: null` with `persist: false` for one release.

**`lib/fix_data/defaults.yaml` (beside `placement.yaml`) can automate:**

- `HarborFlarePolicy(queue: X, child: C)` → `HarborDefaultsScope(defaults: HarborDefaults(flareQueue: X), child: C)`:
  `replacedBy` plus `changeParameters`, with an `argumentValue` template over `arguments[queue]`.
- `HarborSea(hinge: X)` and `Harbor(hinge: X)` → `defaults: HarborDefaults(hinge: X)`, and
  `Harbor(dockHinge: X)` the same way. These are one-argument shapes.
- Each gets a `test_fixes/` case under `dart fix --compare-to-golden`, in `tool/check.sh` as
  `placement.md` proposes.

**Manual:**

- `Harbor(hinge: A, dockHinge: B)` together: two arguments merged into one value. I have not
  checked whether fix-data's conditional templates can express it, so treat it as manual until
  someone tries.
- Repeated `barrierLabel:`/`maxWidth:` arguments. They still work as overrides. Lifting them to
  the sea is a refactor, not a fix.
- `raise(duration: null)` → `persist: true`. The intent behind a null value cannot be
  recognised by a fix.

**1.0:** remove `HarborFlarePolicy`, `Harbor(hinge:, dockHinge:)` and `HarborSea(hinge:)`.

## 4. Open questions

1. **A standalone scope widget, or only `Harbor`/`HarborSea`?** `HarborFlarePolicy` is used
   around subtrees that are not harbors, and its deprecation needs somewhere to forward.
   *Recommendation: ship `HarborDefaultsScope`. It costs one small widget, and it is the
   `DefaultTextStyle.merge` shape Flutter developers know.*
2. **`flareMargin` against `HarborPlacement`'s margin.** `HarborAligned.margin` is non-null with a
   const default, so a raise with an explicit placement cannot say "use the default margin".
   *Recommendation: `flareMargin` applies only to flares whose placement `raise` builds itself
   (`slot:` or nothing), which is every flare in example/. Do not make the placement margin
   nullable to accommodate it.*
3. **Flat fields with prefixes, or nested `HarborFlareDefaults`/`HarborSheetDefaults`?**
   Nesting reads well but doubles the merge logic and the `copyWith`s, and puts two classes in
   the public API for nine fields. *Recommendation: flat, prefixed by the harbor idea they
   govern (`sheet…`, `flare…`). Revisit if it passes about fifteen fields.*
4. **Should `dragToClose`, `closeFlingVelocity` or the sheet's `surface`/`clip` go in?** The
   Material recipe repeats them too (README:926-930). *Recommendation: not now. They are about
   how a sheet looks and feels, not policy. An app that wants them once already writes its own
   `showAppSheet` wrapper. Add `sheetDragToClose` later if issues ask for it. Keep widget-valued
   fields out for good.*
