// The rename's member transforms (lib/fix_data/rename.yaml, 0.9.0): every renamed getter, method and
// static, read through an old type name or a new one, and a tear-off of each kind.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void reads(
  BuildContext context,
  Harbor frame,
  HarborSea sea,
  HarborDock dock,
  HarborDockRecord record,
  HarborPontoon pontoon,
  HarborPontoonHandle handle,
  HarborCoast edges,
  HarborTideState keyboard,
  HarborDryDock space,
  HarborWatersData room,
  HarborCastOff handled,
  HarborLayoutRecord layout,
  HarborController controller,
  HarborMoored clear,
  HarborFairway scroll,
  HarborFairwaySliver sliver,
  HarborWake fade,
  HarborWakeBand band,
  HarborWakeMask mask,
  HarborPortalBuoy popover,
  HarborFlareEntry toast,
  HarborFleet registry,
  HarborSheet sheet,
  HarborDialogRoute<void> dialog,
  HarborChartEntry entry,
  HarborScaleModel scaled,
) {
  <Object?>[frame.buoys, frame.coast, frame.newPort, frame.bodyClearsTide, frame.wakePainter, frame.dockHinge, sea.coast];
  <Object?>[dock.wake, dock.tide, dock.coast, dock.effectiveCoast, record.tide, pontoon.dock, handle.dock];
  <Object?>[edges.calmTide, keyboard.highWater, keyboard.highWaterIsEstimate, keyboard.isIn, space.showsChildAtHighTide];
  <Object?>[room.coast, room.coastSteady, room.docks, room.docksResting, room.wakes, room.hasDocks, room.wakesPainted];
  <Object?>[room.castOff(HarborEdge.vertical), room.wakeOf(HarborEdge.top), handled.tide, handled.docks];
  <Object?>[layout.clearWater, layout.docks, layout.tide];
  <Object?>[controller.clearWater, controller.clearWaterInGlobal(), controller.fleet, controller.isPort, controller.dockedEdges];
  <Object?>[controller.breakwaterTopsInGlobal, controller.breakwaterCoverage, controller.breakwaterChanges, controller.flares];
  <Object?>[clear.tide, clear.mooringLine, clear.extra, scroll.mooringLine, scroll.tide, scroll.wake, scroll.startsInOpenWater];
  <Object?>[sliver.tide, fade.dockOpacity, band.dockEdge, band.wakeEnd, band.dockOpacity, mask.wakes, mask.dockOpacity];
  <Object?>[popover.buoyBuilder, toast.raisedIn, toast.reachesCoast, registry.harbors, registry.sea];
  <Object?>[sheet.headerWake, sheet.footerWake, sheet.footerTide, sheet.clearsTopCoast, sheet.bodyClearsTide, dialog.inheritClearWater];
  <Object?>[entry.clearWater, entry.docks, entry.tide, scaled.coast];
}

void calls(BuildContext context, HarborController controller, HarborFlareEntry toast) {
  HarborTide.isInOf(context);
  HarborWaters.steadyCoastOf(context, HarborEdge.bottom);
  HarborWaters.dockFaceOf(context, HarborEdge.top);
  HarborWakeMask.alphaWake(context, const <HarborEdge, HarborWakeBand>{}, const SizedBox());
  controller.withDockOn(HarborEdge.top);
  final HarborClaim claim = controller.makeWay(HarborEdge.bottom, mode: HarborYield.dark);
  final HarborPontoonHandle handle = controller.addPontoon(HarborEdge.bottom, const HarborDock.reserve(extent: 0));
  controller.updatePontoon(handle, HarborEdge.top, const HarborDock.reserve(extent: 0));
  controller.pontoonsOn(HarborEdge.top);
  controller.removePontoon(handle);
  controller.addBreakwater(ValueNotifier<double>(0)).remove();
  controller.addBreakwaterEdge(ValueNotifier<double>(0)).remove();
  toast.lower();
  toast.lower(reason: HarborFlareClosedReason.dismiss);
  claim.release();
}

void tearOffs(BuildContext context) {
  final bool Function(BuildContext) isIn = HarborTide.isInOf;
  final HarborFlareEntry Function(BuildContext, {required WidgetBuilder builder}) show = HarborFlares.raise;
  final void Function({HarborFlareClosedReason reason}) Function(HarborFlareEntry) lower =
      (final HarborFlareEntry e) => e.lower;
  <Object?>[isIn, show, lower];
}
