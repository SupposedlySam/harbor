// The placement API's `dart fix` transforms (lib/fix_data/placement.yaml): this file is written
// against the deprecated API, and placement.dart.expect is what `dart fix --apply` makes of it.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void buoys(HarborAnchor anchor, VoidCallback close) {
  // The renamed enums, in a type and in a value.
  const HarborBuoySide side = HarborBuoySide.below;
  const HarborBuoyCrossAlignment cross = HarborBuoyCrossAlignment.start;

  // before and after, the names of start and end through 0.2.0, through either enum name.
  const HarborBuoySide before = HarborBuoySide.start;
  const HarborAnchorSide after = HarborAnchorSide.end;

  // An aligned buoy.
  HarborBuoy(alignment: AlignmentDirectional.bottomEnd, child: SizedBox());
  HarborBuoy(margin: EdgeInsets.zero, child: SizedBox());
  HarborBuoy(alignment: Alignment.topCenter, margin: EdgeInsets.all(4), requestFocus: false, child: SizedBox());
  HarborBuoy(alignment: Alignment.center, onDismiss: close, child: const SizedBox());

  // An anchored buoy: its old side was above, so side: above is written where it was left out.
  HarborBuoy.anchored(anchor: anchor, child: const SizedBox());
  HarborBuoy.anchored(anchor: anchor, side: side, overlap: 6, child: const SizedBox());
  HarborBuoy.anchored(anchor: anchor, gap: 4, crossAlignment: cross, crossOffset: 2, margin: EdgeInsets.zero, child: const SizedBox());
  HarborBuoy.anchored(
    anchor: anchor,
    side: HarborBuoySide.end,
    gap: 1,
    overlap: 2,
    crossAlignment: HarborBuoyCrossAlignment.end,
    crossOffset: 3,
    margin: const EdgeInsets.all(5),
    modal: true,
    onDismiss: close,
    child: const SizedBox(),
  );

  // A tear-off is left alone: it has no arguments to move, and renamed it would be a type, not a
  // constructor. It stays deprecated, for a hand to change.
  final HarborBuoy Function({required HarborAnchor anchor, required Widget child}) tearOff = HarborBuoy.anchored;
  tearOff(anchor: anchor, child: const SizedBox());
}

void portals(HarborAnchor anchor, OverlayPortalController menu) {
  // A portal buoy given no placement arguments stays as it is: nothing in it is deprecated.
  HarborPortalBuoy(controller: menu, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  HarborPortalBuoy(controller: menu, side: HarborBuoySide.below, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  HarborPortalBuoy(
    controller: menu,
    side: HarborBuoySide.below,
    crossAlignment: HarborBuoyCrossAlignment.start,
    onDismiss: menu.hide,
    buoyBuilder: (_) => const SizedBox(),
    child: const SizedBox(),
  );
  HarborPortalBuoy(controller: menu, anchor: anchor, gap: 2, flips: false, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  HarborPortalBuoy(controller: menu, overlap: 4, crossOffset: 8, margin: EdgeInsets.zero, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  // A dropdown passes five or more.
  HarborPortalBuoy(
    controller: menu,
    side: HarborBuoySide.end,
    gap: 1,
    overlap: 2,
    crossOffset: 3,
    margin: EdgeInsets.zero,
    buoyBuilder: (_) => const SizedBox(),
    child: const SizedBox(),
  );
  // All eight.
  HarborPortalBuoy(
    controller: menu,
    anchor: anchor,
    side: HarborBuoySide.below,
    gap: 1,
    overlap: 2,
    crossAlignment: HarborBuoyCrossAlignment.end,
    crossOffset: 3,
    margin: const EdgeInsets.all(4),
    flips: false,
    buoyBuilder: (_) => const SizedBox(),
    child: const SizedBox(),
  );
}

void flares(BuildContext context, HarborAnchor anchor) {
  // A slot alone is not deprecated, and stays.
  HarborFlares.raise(context, slot: HarborFlareSlot.low, builder: (_) => const SizedBox());
  HarborFlares.raise(context, alignment: const Alignment(0, -0.8), builder: (_) => const SizedBox());
  HarborFlares.raise(context, alignment: Alignment.topCenter, margin: EdgeInsets.zero, builder: (_) => const SizedBox());
  HarborFlares.raise(context, slot: HarborFlareSlot.low, margin: EdgeInsets.zero, reachesCoast: true, builder: (_) => const SizedBox());
  HarborFlares.raise(context, margin: const EdgeInsets.all(4), builder: (_) => const SizedBox());

  // An anchored flare: its old side was below, as a HarborAnchored's is.
  HarborFlares.raise(context, anchor: anchor, builder: (_) => const SizedBox());
  HarborFlares.raise(context, anchor: anchor, side: HarborBuoySide.above, builder: (_) => const SizedBox());
  // reachesCoast did nothing by an anchor since 0.6.3, and asserts with a HarborAnchored placement, so
  // it goes, whatever it was given.
  HarborFlares.raise(context, anchor: anchor, reachesCoast: true, builder: (_) => const SizedBox());
  HarborFlares.raise(context, anchor: anchor, gap: 4, reachesCoast: false, builder: (_) => const SizedBox());
  HarborFlares.raise(
    context,
    anchor: anchor,
    side: HarborBuoySide.start,
    gap: 2,
    crossAlignment: HarborBuoyCrossAlignment.end,
    margin: EdgeInsets.zero,
    builder: (_) => const SizedBox(),
  );
}

void flaresNotLiteral(BuildContext context, HarborAnchor anchor, HarborAnchor? maybeAnchor, AlignmentGeometry where, double gap) {
  // An anchor alone is moved whatever its argument is: a variable, a field, a call.
  HarborFlares.raise(context, anchor: anchor, gap: gap, margin: EdgeInsets.zero, builder: (_) => const SizedBox());
  HarborFlares.raise(context, alignment: where, margin: EdgeInsets.zero, builder: (_) => const SizedBox());
  // Both an anchor and an alignment (#143): which one applies depends on the values, which a fix
  // cannot see, so it is left alone, deprecated, and the CHANGELOG says what to write.
  HarborFlares.raise(
    context,
    builder: (_) => const SizedBox(),
    anchor: maybeAnchor,
    gap: 8,
    alignment: maybeAnchor != null ? null : Alignment.topCenter,
    margin: EdgeInsets.zero,
  );
  HarborFlares.raise(context, anchor: maybeAnchor, alignment: where, builder: (_) => const SizedBox());
  // side, gap and crossAlignment did nothing without an anchor, and assert beside a placement.
  HarborFlares.raise(context, alignment: where, gap: gap, builder: (_) => const SizedBox());
  HarborFlares.raise(context, margin: EdgeInsets.zero, side: HarborBuoySide.above, crossAlignment: HarborBuoyCrossAlignment.end, builder: (_) => const SizedBox());
}
