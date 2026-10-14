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
  const HarborSea(coast: HarborCoast.none, child: SizedBox());
  const HarborScaleModel(referenceSize: Size(1200, 675), coast: HarborCoast.ambient, child: SizedBox());
  const HarborCoast.fixed(EdgeInsets.zero, calmTide: true);
}

void bars(HarborDock dock) {
  const HarborDock.pier(wake: HarborWake.none, tide: HarborTideStance.float, coast: HarborCoastStance.live, child: SizedBox());
  const HarborDock.quay(tide: HarborTideStance.dryDock, child: SizedBox());
  const HarborDock.reserve(extent: 80, tide: HarborTideStance.float, coast: HarborCoastStance.none);
  dock.copyWith(tide: HarborTideStance.pilings, state: HarborDockState.dark);
  const HarborPontoon(edge: HarborEdge.bottom, dock: HarborDock.pier(child: SizedBox()), child: SizedBox());
}

void keyboard(BuildContext context) {
  const HarborDryDock(showsChildAtHighTide: true);
  const HarborTideState(height: 0, remaining: 0, highWater: 300, highWaterIsEstimate: false, phase: HarborTidePhase.low);
}

void room(BuildContext context, HarborWatersData waters) {
  HarborWaters.clearanceOf(context, HarborEdge.bottom, tide: false);
  const HarborWatersData(coast: EdgeInsetsDirectional.zero, docks: EdgeInsetsDirectional.zero, hasDocks: <HarborEdge>{});
  waters.copyWith(coastSteady: EdgeInsetsDirectional.zero, docksResting: EdgeInsetsDirectional.zero, wakes: const <HarborEdge, HarborWakeBand>{}, wakesPainted: const <HarborEdge>{});
  const HarborCastOff(tide: true, docks: false, child: SizedBox());
  const HarborWakeBand(dockEdge: 40, wakeEnd: 80, dockOpacity: 0.5);
}

void content(BuildContext context) {
  const HarborMoored(tide: false, mooringLine: true, extra: EdgeInsets.all(8), child: SizedBox());
  HarborMoored.clearanceOf(context, tide: false, mooringLine: true, extra: EdgeInsets.zero);
  const HarborFairway(mooringLine: false, tide: false, wake: false, startsInOpenWater: true, slivers: <Widget>[]);
  HarborFairway.box(tide: false, wake: false, child: const SizedBox());
  HarborFairway.paddingOf(context, mooringLine: false, tide: false);
  const HarborFairwaySliver(tide: false, sliver: SliverToBoxAdapter());
}

void effects() {
  const HarborWake.fade(length: 12, dockOpacity: 0.6);
  const HarborWakeMask(wakes: <HarborEdge, HarborWakeBand>{}, dockOpacity: 0.5, child: SizedBox());
}

void overlays(BuildContext context, OverlayPortalController menu) {
  HarborPortalBuoy(controller: menu, buoyBuilder: (_) => const SizedBox(), child: const SizedBox());
  HarborFlares.raise(context, reachesCoast: true, builder: (_) => const SizedBox());
  showHarborSheet<void>(context, breakwater: true, keepsTopCoast: true, builder: (_) => const SizedBox());
  HarborSheet(
    headerWake: HarborWake.none,
    footerWake: HarborWake.none,
    footerTide: HarborTideStance.pilings,
    clearsTopCoast: false,
    bodyClearsTide: false,
    body: const SizedBox(),
  );
  HarborSheet.draggable(footerTide: HarborTideStance.float, builder: (context, controller) => const SizedBox());
  showHarborDialog<void>(context, inheritClearWater: true, builder: (_) => const SizedBox());
  HarborDialogRoute<void>(context: context, inheritClearWater: true, builder: (_) => const SizedBox());
}
