# Placement: one value, one engine

Status: proposal, 2026-10-13. Nothing here is implemented. Line numbers are against `ee26a64`.

The four behaviour bugs listed below have since been fixed on their own as patches, ahead of this
proposal: 0.6.2 for the hinge paths and the dead `HarborBuoy.anchored(hinge:)`, and 0.6.3 for the
half-reaching anchored flare. The structural case for one engine still stands, because the drift
that produced them remains.

## The problem, measured

Three overlays answer the same question ("where does this go in the clear water?"). Each has its
own parameter list, and the lists have drifted:

| | alignment | within | anchor | side | gap | overlap | crossAlignment | crossOffset | flips | margin | reachesCoast | hinge |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `HarborBuoy` (buoy.dart:296) | yes | yes | | | | | | | | 16 | | yes |
| `HarborBuoy.anchored` (:320) | | | yes | above | 8 | yes | yes | yes | never | 8 | | **accepted, never read** |
| `HarborPortalBuoy` (:970) | | | optional | above | 8 | yes | yes | yes | true | 8 | | yes |
| `HarborFlares.raise` (:1722) | yes, + `slot` | internal | yes | **below** | 8 | **no** | yes | **no** | never | 16 / 8 | yes | yes |
| `HarborAnchorClip` (:2222) | | | yes | yes | | | | | | | | |

It is implemented three times:

1. **Buoy layer.** `_RenderBuoyLayer.performLayout` (buoy.dart:829-865) builds the water
   (margin, `within`, open vs clear water, hinge screen) and places aligned buoys;
   `_RenderBuoyLayer.paint` (:868-905) places anchored ones with `_anchoredOffset`.
2. **Portal buoy.** `_RenderPortalBuoy._water` / `_screenOf` / `performLayout` / `paint`
   (:1459-1552) build the water again, with a different screen-picking rule, and call
   `_anchoredOffset` with `flips`.
3. **Overlay flare fallback.** `_OverlayFlareState.build` (:1949-2003) rebuilds margin and
   `reachesCoast` from `MediaQuery` with `Padding` + `Align`, and borrows `_PortalBuoyLayout` for
   anchored flares only.

Flares in a harbor are converted into buoys at `_HarborBuoyLayerState._build` (:545-562), which is
where the drift becomes behaviour:

- **An anchored flare drops its hinge.** The `HarborBuoy.anchored` built at :545 passes no
  `hinge`, and the anchored branch never reads one (:852-854, :890). The overlay fallback does
  honour it (:1985). Same flare, different screen, depending on whether a harbor is above it.
- **An anchored flare with `reachesCoast` is half-reaching.** :568 marks it as reaching, so it is
  laid out in the open water with `_CoastConstraints` (:839, :857), but placed in the clear water
  (:890). The overlay fallback ignores `reachesCoast` for anchored flares (:1960).
- **An aligned overlay flare ignores the hinge entirely** (:1999-2002).
- **`HarborBuoy.anchored(hinge:)` is a dead parameter** (stored at :335, never read; its doc at
  :343-345 half admits it).
- **Defaults are written ten times.** Margin 16 at :300, :413, :560, :1904; margin 8 at :329,
  :422, :551, :981, :1073, :1905; gap 8 at :325, :419, :977, :1071, :1735, controller.dart:136.
  The prose repeats them at buoy.dart:1703 and controller.dart:167.
- `_anchoredOffset` (:220) and `_hingeBounds` (:2297) are top-level functions, against the
  repo's rule that logic lives on a class.

## 1. The value type

```dart
/// Where an overlay sits in the clear water. Shared by HarborBuoy, HarborPortalBuoy and
/// HarborFlares.raise, so a placement written for one means the same in the others.
@immutable
sealed class HarborPlacement with Diagnosticable {
  const HarborPlacement({required this.margin});
  const factory HarborPlacement.aligned({AlignmentGeometry alignment, EdgeInsetsGeometry margin}) = HarborAligned;
  const factory HarborPlacement.anchored(HarborAnchor? anchor, { /* as HarborAnchored */ }) = HarborAnchored;

  /// How far in from the edges of the water it is kept; an EdgeInsetsDirectional follows reading order.
  final EdgeInsetsGeometry margin;
}

final class HarborAligned extends HarborPlacement {
  static const EdgeInsets defaultMargin = EdgeInsets.all(16);
  const HarborAligned({this.alignment = Alignment.bottomCenter, super.margin = defaultMargin});

  /// The point of the water it sits at; an AlignmentDirectional follows reading order.
  final AlignmentGeometry alignment;
}

final class HarborAnchored extends HarborPlacement {
  static const EdgeInsets defaultMargin = EdgeInsets.all(8);
  static const double defaultGap = 8;
  const HarborAnchored(this.anchor, {
    this.side = HarborAnchorSide.above,
    this.gap = defaultGap,
    this.overlap = 0,
    this.crossAlignment = HarborCrossAlignment.center,
    this.crossOffset = 0,
    this.flips,
    super.margin = defaultMargin,
  });

  /// What it sits by. Null only for HarborPortalBuoy, which then anchors to its child.
  final HarborAnchor? anchor;
  /// Which side of the anchor; start and end are in reading order.
  final HarborAnchorSide side;
  /// Space between the anchor's edge and the overlay.
  final double gap;
  /// How far it reaches back over the anchor (a bubble's tail over its button). Subtracted from gap.
  final double overlap;
  /// How it lines up with the anchor across the side: leading edge, centre, trailing edge.
  final HarborCrossAlignment crossAlignment;
  /// Moved this far from crossAlignment, toward the reading end (down, beside the anchor).
  final double crossOffset;
  /// Whether it moves to the opposite side when its side has no room. Null takes the host's
  /// default: a portal buoy flips, a buoy and a flare keep their side.
  final bool? flips;
}
```

Both variants get `==`/`hashCode` so render objects can skip relayout on an equal placement.

**Margin goes on the placement.** Its default depends on the variant (16 aligned, 8 anchored).
Beside the placement, that default would live in each host again, which is the ten copies we
have now. On the variant it is one `static const` each.

**Hinge, `reachesCoast` and `within` stay beside it.** They decide *which water* the overlay may
use, not where it sits in that water:

- `hinge` is an inherited policy (`HarborHinge.of`, hinge.dart:36) shared with sheets and dialogs.
  The variant only decides which screen counts: the one holding the alignment point, or the one
  holding the anchor.
- `reachesCoast` is flare-only, and it also changes what the content receives (`MediaQuery.padding`).
  It becomes valid for `HarborAligned` only (asserted), which settles the half-reaching bug above.
- `within` is a host bound. In practice it is set by flares (`avoidInGlobal`, :559), and the engine
  applies it to both variants.

**Renames, with deprecated typedefs:** `HarborBuoySide` becomes `HarborAnchorSide`, and
`HarborBuoyCrossAlignment` becomes `HarborCrossAlignment`. Flares and `HarborAnchorClip` use them
too, so "Buoy" in the name is misleading. These are plain concepts, so they get plain names.
"Placement", "aligned" and "anchored" are plain English. The nautical words stay on the things
that are harbor ideas (buoy, flare, clear water).

## 2. Signatures, before and after

```dart
// HarborBuoy: one constructor
const HarborBuoy({Key? key, required Widget child, HarborPlacement placement = const HarborAligned(),
  bool modal = false, VoidCallback? onDismiss, Color barrierColor, bool requestFocus = true,
  String barrierLabel, Rect? within, HarborHinge? hinge});

// HarborPortalBuoy: anchored only, so the type says so
const HarborPortalBuoy({..., HarborAnchored placement = const HarborAnchored(null), HarborHinge? hinge, ...});

// HarborFlares.raise
static HarborFlareEntry raise(BuildContext context, {required WidgetBuilder builder,
  HarborFlareSlot? slot, HarborPlacement? placement, bool reachesCoast = false, HarborHinge? hinge, ...});

// HarborAnchorClip: unchanged apart from the enum rename
const HarborAnchorClip({Key? key, required HarborAnchor anchor, required HarborAnchorSide side, Widget? child});
```

README:478-479 and example/lib/shell.dart:68-73:

```dart
// before
HarborBuoy(alignment: AlignmentDirectional.bottomEnd, child: fab),
HarborBuoy.anchored(anchor: launchAnchor, side: HarborBuoySide.above, overlap: 6, child: bubble),
// after
HarborBuoy(placement: const HarborAligned(alignment: AlignmentDirectional.bottomEnd), child: fab),
HarborBuoy(placement: HarborPlacement.anchored(launchAnchor, overlap: 6), child: bubble),
```

README:617-625 (portal):

```dart
// before
HarborPortalBuoy(controller: menu, side: HarborBuoySide.below,
  crossAlignment: HarborBuoyCrossAlignment.start, buoyBuilder: ..., child: row)
// after
HarborPortalBuoy(controller: menu,
  placement: const HarborAnchored(null, side: HarborAnchorSide.below, crossAlignment: HarborCrossAlignment.start),
  buoyBuilder: ..., child: row)
```

README:486-488 (flares):

```dart
HarborFlares.raise(context, slot: HarborFlareSlot.low, builder: ...);                       // unchanged
HarborFlares.raise(context, placement: const HarborAligned(alignment: Alignment(0, -0.8)), builder: ...);
HarborFlares.raise(context, placement: HarborPlacement.anchored(copyAnchor, side: HarborAnchorSide.above), builder: ...);
```

`HarborFlareEntry` gains `final HarborPlacement placement`. Its `alignment`, `anchor`, `side`,
`gap`, `crossAlignment` and `margin` become getters derived from it. `anchor` and `side` stay
undeprecated, because README:596-598's transition recipe reads them.

## 3. The engine

One internal class replaces `_anchoredOffset`, `_hingeBounds`, `_screenFor` (:760),
`_screenOf` (:1471), `_coastCovered` (:821) and the water arithmetic in the three hosts:

```dart
@internal
abstract final class HarborPlacementEngine {
  /// The rectangle the overlay may occupy, and the coast it covers (for reachesCoast content).
  static HarborWater water({
    required Rect clear, Rect? open, Rect? within,      // open != null means reachesCoast
    required HarborPlacement placement, required TextDirection textDirection,
    List<Rect> hinges = const [], Offset? holding,      // null holding: the largest screen (layout-time)
  });

  /// Where an overlay of size sits in water, and the side it landed on (null when aligned).
  static HarborLanding place({
    required HarborPlacement placement, required HarborWater water, required Size size,
    Rect? anchorRect, required bool flips, required TextDirection textDirection,
  });

  static List<Rect> hingeBounds(HarborHinge hinge, List<DisplayFeature> features);
}

final class HarborWater { final Rect rect; final EdgeInsets coastCovered; }
final class HarborLanding { final Offset offset; final HarborAnchorSide? side; }
```

`water` runs the same steps in the same order for every host. It starts from clear (or open)
water, intersects `within` (the logic now at :842-851), and picks the screen that holds `holding`.
For aligned that is the alignment point, falling back to the screen where reading starts (:777-778).
For anchored it is the anchor centre, falling back to the nearest screen (:1479-1491). Then it
deflates by `placement.margin`. Choosing the screen-fallback rule by variant keeps today's
behaviour on both paths.

How each host calls it:

- **Buoy layer.** In `performLayout`, `water(holding: null for anchored, alignment point for
  aligned)` replaces :839-857. For aligned children, `place` replaces :861. In `paint`, anchored
  children call `water(holding: anchorRect.center)` + `place`, replacing :889-899. Anchored buoys
  and flares now honour the hinge, as the portal already does.
- **Portal buoy.** `_RenderPortalBuoy` keeps its harbor listening and side reporting (:1554-1576)
  and drops `_water` / `_screenOf` / the layout-time screen pick (:1459-1515) for `water(...)`,
  with `place` at :1533-1544. `_PortalBuoyLayout` (:1367) loses eight fields for one `placement`.
- **Overlay flare.** All three branches of `_OverlayFlareState.build` (:1960-2002) become one
  `_PortalBuoyLayout`-style render object (renamed `_PlacedLayout`, shared with the portal). Its
  clear water is the overlay less `max(padding, viewInsets)` (:1953-1958), and its open water is
  the overlay less `viewInsets`. Aligned overlay flares pick up hinge handling. The coast padding
  hand-off moves to `HarborWater.coastCovered`, which the buoy layer already uses through
  `_CoastConstraints`.

Flares in a harbor stop being rebuilt as ad-hoc `HarborBuoy`s with dropped fields (:545-562).
They become `HarborBuoy(placement: entry.placement, hinge: entry.hinge, within: ...)`, so nothing
is lost in translation.

## 4. Migration

**0.x release with deprecations (non-breaking):**

- `HarborBuoy(alignment:, margin:)` → deprecated params. `placement` becomes a getter that falls
  back to `HarborAligned(alignment, margin)`. A const constructor cannot build that value in its
  initializer list, so this has to be a getter. Assert that `placement` and the old params are not
  both given.
- `HarborBuoy.anchored(...)` → a deprecated constructor that stores the old fields. Its `hinge`
  param is deprecated with a note that it now takes effect.
- `HarborPortalBuoy(anchor:, side:, gap:, overlap:, crossAlignment:, crossOffset:, margin:, flips:)`
  → deprecated, merged into `placement` in `State.build`.
- `HarborFlares.raise(alignment:, anchor:, side:, gap:, crossAlignment:, margin:)` → deprecated,
  merged into `placement` at the top of `raise`.
- `HarborBuoySide`, `HarborBuoyCrossAlignment` → deprecated typedefs in deprecated.dart (static
  members resolve through a typedef). The existing `before`/`after` aliases move with the enum.

**`lib/fix_data/placement.yaml` can automate:**

- Both enum renames (`rename`, element kinds `enum`/`typedef`). This covers every use, the clip included.
- `HarborBuoy(alignment: X)` → `HarborBuoy(placement: HarborAligned(alignment: X))`, using
  `changeParameters` with `removeParameter` + `addParameter` and an `argumentValue` template over
  `fragment: 'arguments[alignment]'`. The same works for `raise(alignment:)` and the common
  `raise(anchor: X)`, which must write `side: HarborAnchorSide.below` when the old call left
  `side` out (a flare's old default, :1734) until Q4 is settled.
- `HarborBuoy.anchored(anchor: A, ...)` for the shapes that appear in the repo (README:479,
  shell.dart:68, radio.dart:442). Every optional argument doubles the template cases, so cover
  the frequent ones and stop.

Each transform gets a `test_fixes/` case checked by `dart fix --compare-to-golden`, added to
`tool/check.sh`.

**Manual:**

- Calls with many optional anchored arguments, or with arguments computed from variables.
- Portal buoys that set `side:` without `flips:`. The fix produces a placement with
  `flips: null`, which keeps flipping on a portal. Code that passed `flips: true` explicitly
  still needs a look.
- Behaviour changes that no fix can express: anchored buoys and flares now keep off a hinge, and
  `reachesCoast` with an anchored flare is now an assert instead of a half-applied layout.
  Both go in CHANGELOG.
- Readers of `HarborFlareEntry.gap` / `.crossAlignment` / `.margin` keep working through the
  getters.

**1.0:** remove the deprecated params, the `.anchored` constructor and the typedefs.

## 5. Open questions

1. **Keep `slot:` on `raise`?** Every flare in example/ uses it (shell.dart:232, office.dart:210,
   fleet.dart:64, ...), so dropping it for `placement: HarborAligned(alignment: HarborFlareSlot.low.alignment)`
   would make the common call longer.
   *Recommendation: keep `slot:` as a first-class shorthand, exclusive with `placement:`.*
2. **Keep `HarborBuoy.anchored` as undeprecated sugar?** It reads better, but keeping it brings
   back a second copy of the anchored parameter list, which is the drift this proposal removes.
   *Recommendation: deprecate it. Sugar that forwards a whole `HarborAnchored` would be fine:
   `HarborBuoy.anchored(HarborAnchored placement, {child, ...})`.*
3. **Nullable `anchor` on `HarborAnchored`.** It exists only for the portal's "anchor to my child".
   The alternative is to keep `HarborPortalBuoy(anchor:)` beside the placement and make
   `HarborAnchored.anchor` required, at the cost of a second type for the anchorless spec.
   *Recommendation: nullable anchor, asserted non-null in `HarborBuoy` and `raise`. One type is
   worth one assert.*
4. **Default side and flips differ per host** (buoy/portal default `above`, flare `below`;
   only the portal flips). A shared value cannot hold different defaults.
   *Recommendation: make `side` default to `below` everywhere, the menu and toast case. That is a
   breaking default for the anchored buoy and the portal, so ship it with the 1.0 removal rather
   than in the deprecation release. Keep `flips` nullable as the host's choice. Flares do not
   flip, because their transition needs a fixed side (README:595).*
