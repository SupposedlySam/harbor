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
  // dockedEdges, the breakwater readings, flares, withDockOn and pontoonsOn are left on their 0.8 names:
  // what they were renamed to went @internal after 0.9.1 (tool/fix_data/rename.dart).
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

// The same reads through implicit `this`, inside an extension on each type (#143): a member read with no
// target is matched by its declaring type rather than by a target's type.
extension Implicit on Harbor {
  List<Object?> get reads => <Object?>[buoys, coast, newPort, bodyClearsTide, wakePainter, dockHinge];
}
extension ImplicitSea on HarborSea {
  List<Object?> get reads => <Object?>[coast];
}
extension ImplicitDock on HarborDock {
  List<Object?> get reads => <Object?>[wake, tide, coast, effectiveCoast];
}
extension ImplicitDockRecord on HarborDockRecord {
  List<Object?> get reads => <Object?>[tide];
}
extension ImplicitPontoon on HarborPontoon {
  List<Object?> get reads => <Object?>[dock];
}
extension ImplicitPontoonHandle on HarborPontoonHandle {
  List<Object?> get reads => <Object?>[dock];
}
extension ImplicitCoast on HarborCoast {
  List<Object?> get reads => <Object?>[calmTide];
}
extension ImplicitTideState on HarborTideState {
  List<Object?> get reads => <Object?>[highWater, highWaterIsEstimate, isIn];
}
extension ImplicitDryDock on HarborDryDock {
  List<Object?> get reads => <Object?>[showsChildAtHighTide];
}
extension ImplicitWatersData on HarborWatersData {
  List<Object?> get reads => <Object?>[coast, coastSteady, docks, docksResting, wakes, hasDocks, wakesPainted, castOff(HarborEdge.vertical), wakeOf(HarborEdge.top)];
}
extension ImplicitCastOff on HarborCastOff {
  List<Object?> get reads => <Object?>[tide, docks];
}
extension ImplicitLayoutRecord on HarborLayoutRecord {
  List<Object?> get reads => <Object?>[clearWater, docks, tide];
}
extension ImplicitController on HarborController {
  List<Object?> get reads => <Object?>[clearWater, clearWaterInGlobal(), fleet, isPort, dockedEdges, breakwaterTopsInGlobal, breakwaterCoverage, breakwaterChanges, flares];

  void calls() {
    withDockOn(HarborEdge.top);
    final HarborClaim claim = makeWay(HarborEdge.bottom, mode: HarborYield.dark);
    final HarborPontoonHandle handle = addPontoon(HarborEdge.bottom, const HarborDock.reserve(extent: 0));
    updatePontoon(handle, HarborEdge.top, const HarborDock.reserve(extent: 0));
    pontoonsOn(HarborEdge.top);
    removePontoon(handle);
    addBreakwater(ValueNotifier<double>(0)).remove();
    addBreakwaterEdge(ValueNotifier<double>(0)).remove();
    claim.release();
  }
}
extension ImplicitMoored on HarborMoored {
  List<Object?> get reads => <Object?>[tide, mooringLine, extra];
}
extension ImplicitFairway on HarborFairway {
  List<Object?> get reads => <Object?>[mooringLine, tide, wake, startsInOpenWater];
}
extension ImplicitFairwaySliver on HarborFairwaySliver {
  List<Object?> get reads => <Object?>[tide];
}
extension ImplicitWake on HarborWake {
  List<Object?> get reads => <Object?>[dockOpacity];
}
extension ImplicitWakeBand on HarborWakeBand {
  List<Object?> get reads => <Object?>[dockEdge, wakeEnd, dockOpacity];
}
extension ImplicitWakeMask on HarborWakeMask {
  List<Object?> get reads => <Object?>[wakes, dockOpacity];
}
extension ImplicitPortalBuoy on HarborPortalBuoy {
  List<Object?> get reads => <Object?>[buoyBuilder];
}
extension ImplicitFlareEntry on HarborFlareEntry {
  List<Object?> get reads => <Object?>[raisedIn, reachesCoast];

  void calls() {
    lower();
    lower(reason: HarborFlareClosedReason.dismiss);
  }
}
extension ImplicitFleet on HarborFleet {
  List<Object?> get reads => <Object?>[harbors, sea];
}
extension ImplicitSheet on HarborSheet {
  List<Object?> get reads => <Object?>[headerWake, footerWake, footerTide, clearsTopCoast, bodyClearsTide];
}
extension ImplicitDialogRoute on HarborDialogRoute<void> {
  List<Object?> get reads => <Object?>[inheritClearWater];
}
extension ImplicitChartEntry on HarborChartEntry {
  List<Object?> get reads => <Object?>[clearWater, docks, tide];
}
extension ImplicitScaleModel on HarborScaleModel {
  List<Object?> get reads => <Object?>[coast];
}
