# Flares: a timing value and a slim handle

Status: proposal, 2026-10-13. Nothing here is implemented. Line numbers are against `987db9c`.
It builds on `placement.md` and assumes it has landed: `HarborPlacement`, `HarborAligned`,
`HarborAnchored`, `HarborAnchorSide`, and `raise(slot:, placement:)` with `slot:` kept as a shorthand.

## The problem, measured

**`raise` takes 19 named parameters** (buoy.dart:1731-1752). They fall into five groups, and
nothing in the signature says which group a parameter belongs to:

| Group | Parameters | After `placement.md` |
|---|---|---|
| Where | `slot`, `alignment`, `anchor`, `side`, `gap`, `crossAlignment`, `margin` | `slot`, `placement` |
| Which water | `target`, `reachesCoast`, `hinge` | unchanged |
| How long | `duration`, `persist`, `countsEntrance`, `countsWhileCovered` | **this proposal** |
| Turn-taking | `queue` | unchanged |
| How it looks | `builder`, `animationStyle`, `transitionBuilder`, `liveRegion` | unchanged |

`placement.md` takes the first row down from seven to two. This draft deals with the rest.

- **`persist` and `duration: null` do the same thing.** The timer runs only when
  `duration != null && !entry.persist` (buoy.dart:2116-2118), and the entry's own doc says so: "Null
  never times out, the same as [persist]" (controller.dart:178). The example uses `duration: null`
  (showcase_wide/wide.dart:334, showcase/demos.dart:930). The README uses `persist: true`
  (README:489). The two do differ in one case: setting `entry.duration` on a persisting flare starts
  no timer, because `persist` is still true. Nobody relies on that, and the README's own advice ("longer
  once a screen reader turns on", README:580) assumes the opposite.
- **Two timing flags sit loose in the list.** `countsEntrance` and `countsWhileCovered` are read in
  exactly one place, `_syncTimeout` (buoy.dart:2121-2122). They change how `duration` is counted,
  but sit eight and fifteen parameters away from it.
- **`target` is accepted and ignored for an anchored flare.** The port is picked from the anchor
  before `target` is looked at (buoy.dart:1784-1789). The doc admits it: "[target] is not read"
  (buoy.dart:1683). Nothing asserts.

**`HarborFlareEntry` has 32 public members** (controller.dart:121-347). It is the type `raise`
returns and `maybeOf` hands to a builder, but it is also the record harbor's machinery runs on:

- **Configuration copied off `raise` (17):** `builder`, `alignment`, `anchor`, `side`, `gap`,
  `crossAlignment`, `margin`, `reachesCoast`, `hinge`, `countsWhileCovered`, `queue`,
  `countsEntrance`, `persist`, `animationStyle`, `transitionBuilder`, `liveRegion`, plus the
  `duration` value.
- **Plumbing (7):** `timing`, a `ValueListenable<int>` that ticks when `duration` is set
  (:212; read only at buoy.dart:2088/2137). `transitionDuration` / `reverseTransitionDuration`
  (:232-235) and `lingers` (:239). `raisedIn` and `avoidInGlobal` (:247, :258; read at
  buoy.dart:520/560). `owner` (:265), which is written at controller.dart:838 and **read nowhere** in
  `lib/`, `test/`, `harbor_test/` or `example/`.
- **The handle (9, `duration` counted in both lists):** `duration` (setter), `showing`, `closed`, `maybeOf`, `held`, `hold`, `phase`,
  `wasShown`, `lower`.

Outside `lib/`, the repo reads only the handle, plus `anchor`/`side` for the transition recipe
(test/flare_coast_timing_test.dart:201) and `alignment` in a deprecation test
(test/deprecated_names_test.dart:64). A grep of `test/`, `harbor_test/` and `example/` for the
other configuration and plumbing names found no reads.

`lower({reason})` (:338) also lets a caller pick any `HarborFlareClosedReason`. A caller can close
a flare as `timeout` or `replaced`, and `closed` then reports something that did not happen.

## 1. The timing value

```dart
/// How long a flare stays up, and what counts toward that time.
@immutable
final class HarborFlareTiming with Diagnosticable {
  /// A SnackBar's 4 s.
  static const Duration defaultDuration = Duration(seconds: 4);

  /// Stays until lowered, as SnackBar(persist: true). For a flare with a button, an Undo.
  static const HarborFlareTiming untilLowered = HarborFlareTiming(duration: null);

  const HarborFlareTiming({
    this.duration = defaultDuration,
    this.countsEntrance = false,
    this.countsWhileCovered = false,
  });

  /// How long it stays in sight. Null: until lowered.
  final Duration? duration;

  /// Count from the start of the entrance, so a 4 s flare is on screen 4 s, entrance included.
  final bool countsEntrance;

  /// Keep counting while another route covers the flare's page. A hold still stops it.
  final bool countsWhileCovered;
}
```

`persist` disappears into `duration: null`, so there is one way to say "until lowered".
`untilLowered` is a `static const`, not a constructor, so `timing: HarborFlareTiming.untilLowered`
reads as a value. "Timing" is plain English; "Flare" stays in the name because a flare is a harbor
idea.

## 2. `raise`

```dart
static HarborFlareEntry raise(
  BuildContext context, {
  required WidgetBuilder builder,
  HarborFlareSlot? slot,                       // shorthand for an aligned placement; high with neither
  HarborPlacement? placement,                  // placement.md; exclusive with slot
  HarborFlareTiming timing = const HarborFlareTiming(),
  HarborFlareQueue? queue,                     // null: HarborFlarePolicy.queueOf(context)
  HarborFlareTarget? target,                   // null: topmost; asserted null for an anchored placement
  bool reachesCoast = false,                   // HarborAligned only (placement.md)
  HarborHinge? hinge,                          // null: HarborHinge.of(context)
  AnimationStyle? animationStyle,              // 220 ms each way
  HarborFlareTransitionBuilder? transitionBuilder,
  bool liveRegion = true,
});
```

That leaves 11 named parameters instead of 19.

**Queue and target stay as separate parameters.** Neither is placement or timing.
`queue` decides what happens when the place is taken, and the place is still the key: alignment,
or anchor and side (controller.dart:173). It already has an inherited default
(`HarborFlarePolicy`, buoy.dart:2334). `target` decides which port's water the flare uses, so it
sits with `reachesCoast` and `hinge` among the "which water" options that `placement.md` keeps beside the
placement. The one change is that `target` becomes nullable. That way an anchored flare that
names a target can be asserted against, instead of the target being ignored without a word.

**Presentation stays loose too.** `animationStyle` is Flutter's own type, used the way
`showSnackBar(snackBarAnimationStyle:)` uses it. Wrapping three parameters in a harbor value
would add a name to learn and take nothing away.

## 3. The handle

```dart
/// A raised flare: returned by HarborFlares.raise, and found inside its builder or transition
/// with maybeOf.
abstract final class HarborFlareEntry {
  /// The flare whose builder or transitionBuilder context is in; null outside one.
  static HarborFlareEntry? maybeOf(BuildContext context);

  /// Where it was raised (placement.md). A slot is a HarborAligned.
  HarborPlacement get placement;

  /// The anchor it sits by; null unless placed by one. Kept for transitions.
  HarborAnchor? get anchor;

  /// The side of its anchor; an anchored flare never flips, so a transition can rely on it.
  HarborAnchorSide get side;

  /// How long it stays in sight; null until lowered. Setting it starts the time over.
  Duration? get duration;
  set duration(Duration? value);

  /// False from the moment it is lowered.
  ValueListenable<bool> get showing;

  /// waiting, shown or closed, updated synchronously before [closed] completes.
  HarborFlarePhase get phase;

  /// Whether it was ever built on screen.
  bool get wasShown;

  /// Completes once it has left, with why.
  Future<HarborFlareClosedReason> get closed;

  /// Stops its time until the returned hold is released. Holds are counted.
  HarborFlareHold hold();

  /// Whether a hold is on.
  ValueListenable<bool> get held;

  /// Lowers it; [closed] reports HarborFlareClosedReason.lower.
  void lower();
}
```

That leaves 12 members instead of 32, one of them (`placement`) new. The configuration and the plumbing move to an internal
`final class RaisedFlare extends HarborFlareEntry` in controller.dart. `harbor.dart`'s `show`
list leaves it out, the same way it leaves out `flareShown`/`flareLeft` today
(controller.dart:369-372). Because `HarborFlareEntry` is `abstract final`, a consumer cannot
subclass it, and harbor can add members to it later without breaking anyone.
Internal code (`_Flare`, the buoy layer, `_OverlayQueue`, `queueFlare`) holds a `RaisedFlare`.

- `side` stays non-null so the README recipe still compiles (`side: entry.side`). On an aligned
  flare it returns the anchored default side and means nothing, as it does today
  (controller.dart:159).
- **`timing` is not reused for the new value.** That name already belongs to the internal
  `ValueListenable<int>`, which is deprecated in step 1 and removed at 1.0. Only `duration` needs to
  change after the raise. Nobody has asked to change `countsEntrance` on a flare that is already up.
- The internal `lower(reason:)` remains on `RaisedFlare`, for `dismiss`, `timeout` and `replaced`.

## 4. Before and after

README:489, the Undo:

```dart
// before
final undo = HarborFlares.raise(context, persist: true, builder: (_) => UndoToast(onUndo: restore));
// after
final undo = HarborFlares.raise(context, timing: HarborFlareTiming.untilLowered, builder: (_) => UndoToast(onUndo: restore));
```

example/lib/showcase_wide/wide.dart:331-334, a flare the timeline lowers itself:

```dart
// before
_flare = HarborFlares.raise(page, slot: HarborFlareSlot.low, duration: null, builder: ...);
// after
_flare = HarborFlares.raise(page, slot: HarborFlareSlot.low, timing: HarborFlareTiming.untilLowered, builder: ...);
```

README:595-598 and test/flare_coast_timing_test.dart:201, the transition recipe. Only the
anchored placement's enum is renamed (`placement.md`). The recipe itself does not change:

```dart
HarborFlares.raise(
  context,
  placement: HarborPlacement.anchored(fieldAnchor, side: HarborAnchorSide.below),
  transitionBuilder: (context, animation, child) {
    final HarborFlareEntry entry = HarborFlareEntry.maybeOf(context)!;
    return HarborAnchorClip(anchor: entry.anchor!, side: entry.side, child: child);  // unchanged
  },
  builder: (_) => const Toast('Copied'),
);
```

The README's `countsEntrance` / `countsWhileCovered` prose (README:578-583) becomes
`timing: HarborFlareTiming(countsWhileCovered: true)`.

## 5. Migration

**0.x release with deprecations (non-breaking):**

- Add `HarborFlareTiming` and `raise(timing:)`. Deprecate `duration:`, `persist:`, `countsEntrance:`
  and `countsWhileCovered:` on `raise`, and merge them into a timing value at the top of `raise`.
  Assert that `timing:` is not given alongside any of them. The old `duration` defaults to 4 s and is
  non-null, so the parameter has to become nullable with a sentinel to tell "unset" apart. The merge
  can then fall back to `timing.duration`.
- `persist: true` merges as `duration: null`. That is the behaviour change described above:
  setting `entry.duration` on it now starts a timer. Note it in CHANGELOG.
- Make `target` nullable and assert it is null for an anchored placement.
- Split `HarborFlareEntry` into the handle and `RaisedFlare`. Keep the 21 members that leave the
  handle as `@Deprecated` getters that forward to the record. All of them, plumbing included: a
  forwarding getter costs a line, and pre-1.0 is no reason to break a reader nobody can see. Keep
  `alignment`, `gap`, `crossAlignment` and `margin` as `placement.md`'s derived getters, also deprecated
  in favour of `placement`.
- Deprecate `lower(reason:)`'s parameter. Passing one still works until 1.0.
- `HarborFlareEntry`'s constructor is already `@internal` (controller.dart:123), so no consumer
  builds one. Changing it to `abstract final` breaks only `implements HarborFlareEntry` in a
  consumer's fake. None exist in this repo, and that break waits for 1.0.

**`lib/fix_data/flares.yaml` can automate:**

- `raise(duration: X)` with no other timing argument → `timing: HarborFlareTiming(duration: X)`,
  a single-fragment `changeParameters` (remove `duration`, add `timing` with an `argumentValue`
  over `arguments[duration]`).
- `raise(countsWhileCovered: X)` and `raise(countsEntrance: X)` alone, the same way.

**Manual:**

- **`persist:`.** A template cannot read the argument's value. I could not confirm any
  data-driven fix condition beyond whether an argument is present, so `persist: true` is not
  rewritten automatically. The deprecation message carries the exact replacement
  (`timing: HarborFlareTiming.untilLowered`).
- Calls that combine two or more timing arguments. Each combination is another template, and
  the repo has none to cover.
- Readers of the deprecated entry members. The repo has none outside `lib/`. The deprecation
  message names what to use instead (`placement`, or "internal: no replacement").
- Every fix gets a `test_fixes/` case, as in `placement.md`.

**1.0:** remove the deprecated `raise` parameters, the deprecated entry members, the `reason:`
parameter and the `HarborSignal*` typedefs (deprecated.dart:9-41, already slated for 1.0).

## 6. Open questions

1. **Keep `duration:` as a shorthand beside `timing:`, as `slot:` is beside `placement:`?** The only
   example call that sets it to a value repeats the default (office.dart:715). The other two set it to
   null (wide.dart:334, demos.dart:930).
   *Recommendation: no. `slot:` earns its keep because every example flare uses it. `duration:`
   does not, and a second spelling of "until lowered" is the problem this proposal removes.*
2. **`abstract final class` with an internal subclass, or keep one class and mark the internals
   `@internal`?** `@internal` is only a lint (`invalid_use_of_internal_member`), and dartdoc still
   lists the members.
   *Recommendation: the split. The public type then says exactly what a caller may do, and it is
   the same pattern the repo already uses for unexported helpers.*
3. **Should `HarborFlarePolicy` carry a `timing:` for a subtree**, as it carries `queue:`? A TV
   screen or a screen-reader session might want every flare to stay longer.
   *Recommendation: not in this change. No caller asks for it, and per-flare `entry.duration` already
   covers the screen-reader case. The value type makes it a one-field addition later.*
4. **Should `side` on the handle become nullable** (null for an aligned flare)? That would be more
   honest, but `HarborAnchorClip(side: entry.side)` would stop compiling.
   *Recommendation: keep it non-null until 1.0. Then reconsider it together with `placement.md`
   Q4 (the default side), because the two decide what `side` means without an anchor.*
