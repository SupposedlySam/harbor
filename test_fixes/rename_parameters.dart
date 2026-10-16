// The rename's parameter transforms (lib/fix_data/rename.yaml, 0.9.0): every renamed named argument,
// alone and together, on the class or function that now declares it.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void frames(BuildContext context, HarborWakePainter painter) {
  Harbor(newPort: true, body: const SizedBox());
  Harbor(
    buoys: const <HarborBuoy>[],
    coast: HarborCoast.none,
    newPort: false,
    bodyClearsTide: false,
    wakePainter: painter,
    dockHinge: HarborHinge.never,
    body: const SizedBox(),
  );
  HarborSea(coast: HarborCoast.none, child: SizedBox());
  HarborScaleModel(referenceSize: Size(1200, 675), coast: HarborCoast.ambient, child: SizedBox());
  HarborCoast.fixed(EdgeInsets.zero, calmTide: true);
}

void bars(HarborDock dock) {
  HarborDock.pier(wake: HarborWake.none, tide: HarborTideStance.rides, coast: HarborCoastStance.live, child: SizedBox());
  HarborDock.quay(tide: HarborTideStance.reserves, child: SizedBox());
  HarborDock.reserve(extent: 80, tide: HarborTideStance.rides, coast: HarborCoastStance.none);
  dock.copyWith(tide: HarborTideStance.stays, state: HarborDockState.dark);
  HarborPontoon(edge: HarborEdge.bottom, dock: HarborDock.pier(child: SizedBox()), child: SizedBox());
}

void keyboard(BuildContext context) {
  HarborDryDock(showsChildAtHighTide: true);
  HarborTideState(height: 0, remaining: 0, highWater: 300, highWaterIsEstimate: false, phase: HarborTidePhase.hidden);
}

void room(BuildContext context, HarborWatersData waters) {
  HarborWaters.clearanceOf(context, HarborEdge.bottom, tide: false);
  HarborWatersData(coast: EdgeInsetsDirectional.zero, docks: EdgeInsetsDirectional.zero, hasDocks: <HarborEdge>{});
  waters.copyWith(coastSteady: EdgeInsetsDirectional.zero, docksResting: EdgeInsetsDirectional.zero, wakes: const <HarborEdge, HarborWakeBand>{}, wakesPainted: const <HarborEdge>{});
  HarborCastOff(tide: true, docks: false, child: SizedBox());
  HarborWakeBand(dockEdge: 40, wakeEnd: 80, dockOpacity: 0.5);
}

void content(BuildContext context) {
  HarborMoored(tide: false, mooringLine: true, extra: EdgeInsets.all(8), child: SizedBox());
  HarborMoored.clearanceOf(context, tide: false, mooringLine: true, extra: EdgeInsets.zero);
  HarborFairway(mooringLine: false, tide: false, wake: false, startsInOpenWater: true, slivers: <Widget>[]);
  HarborFairway.box(tide: false, wake: false, child: const SizedBox());
  HarborFairway.paddingOf(context, mooringLine: false, tide: false);
  HarborFairwaySliver(tide: false, sliver: SliverToBoxAdapter());
}

void effects() {
  HarborWake.fade(length: 12, dockOpacity: 0.6);
  HarborWakeMask(wakes: <HarborEdge, HarborWakeBand>{}, dockOpacity: 0.5, child: SizedBox());
}

void overlays(BuildContext context, OverlayPortalController menu) {
  HarborPortalBuoy(controller: menu, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  HarborFlares.raise(context, reachesCoast: true, builder: (_) => const SizedBox());
  showHarborSheet<void>(context, breakwater: true, keepsTopCoast: true, builder: (_) => const SizedBox());
  HarborSheet(
    headerWake: HarborWake.none,
    footerWake: HarborWake.none,
    footerTide: HarborTideStance.stays,
    clearsTopCoast: false,
    bodyClearsTide: false,
    body: const SizedBox(),
  );
  HarborSheet.draggable(footerTide: HarborTideStance.rides, builder: (context, controller) => const SizedBox());
  showHarborDialog<void>(context, inheritClearWater: true, builder: (_) => const SizedBox());
  HarborDialogRoute<void>(context: context, inheritClearWater: true, builder: (_) => const SizedBox());
}
