// The rename's type transforms (lib/fix_data/rename.yaml, 0.9.0): every old type name, in a type, a
// construction and a static access. rename_types.dart.expect is what `dart fix --apply` makes of it.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

class Log extends HarborFleetObserver {
  const Log();
}

void types(BuildContext context, HarborController controller, ValueNotifier<double> ime) {
  // The frame and the root.
  const HarborSea sea = HarborSea(child: SizedBox());
  const Harbor frame = Harbor(body: SizedBox());
  final HarborController? nearest = Harbor.maybeOf(context);

  // Bars.
  const HarborDockKind kind = HarborDockKind.pier;
  const HarborDockState state = HarborDockState.dark;
  const HarborCoastStance stance = HarborCoastStance.steady;
  final List<HarborDockRecord> records = <HarborDockRecord>[];
  const HarborSliverDock pinned = HarborSliverDock(child: SizedBox());
  const HarborMakeWay hide = HarborMakeWay(edge: HarborEdge.bottom, child: SizedBox());
  final HarborPontoonHandle? handle = null;

  // The system edges and the keyboard.
  const HarborCoast edges = HarborCoast.ambient;
  const HarborCoast fixed = HarborCoast.fixed(EdgeInsets.zero);
  const HarborCoastFeature feature = HarborCoastFeature.statusBar;
  final HarborTideState keyboard = HarborTide.of(context);
  const HarborTidePhase phase = HarborTidePhase.low;
  const HarborTideStance keyboardStance = HarborTideStance.float;
  const HarborDryDock space = HarborDryDock();
  final HarborTideSource source = HarborTideSource(height: ime, child: const SizedBox());

  // The room.
  final HarborWatersData room = HarborWaters.of(context, aspect: HarborWatersAspect.margin);
  const HarborCastOff handled = HarborCastOff(child: SizedBox());
  const HarborMoored clear = HarborMoored(child: SizedBox());
  HarborMoored.clearanceOf(context);

  // Scroll views and the edge effect.
  const HarborFairway scroll = HarborFairway(slivers: <Widget>[]);
  final HarborFairway box = HarborFairway.box(child: const SizedBox());
  HarborFairway.paddingOf(context);
  const HarborFairwaySliver sliver = HarborFairwaySliver(sliver: SliverToBoxAdapter());
  const HarborWake fade = HarborWake.fade(length: 12);
  const HarborWakeKind fadeKind = HarborWakeKind.fade;
  const HarborWakeBand band = HarborWakeBand.none;
  const HarborWakePainter painter = HarborWakeMask.alphaWake;
  const HarborWakeMask mask = HarborWakeMask(wakes: <HarborEdge, HarborWakeBand>{}, child: SizedBox());

  // Popovers and toasts.
  final HarborFlareEntry toast = HarborFlares.raise(context, slot: HarborFlareSlot.low, builder: (_) => const SizedBox());
  const HarborFlareTarget target = HarborFlareTarget.topmost;
  toast.closed.then((final HarborFlareClosedReason reason) => reason);
  const HarborFlarePhase toastPhase = HarborFlarePhase.waiting;
  const HarborFlareQueue queue = HarborFlareQueue.replace;
  final HarborFlareHold hold = toast.hold();
  final HarborFlareTransitionBuilder transition = (context, animation, child) => child;
  final HarborPortalBuoy? popover = null;

  // Sheets, keeping in sight, the inspector, the registry and the scaled screen.
  final HarborBreakwater cover = controller.addBreakwater(ValueNotifier<double>(0));
  const HarborBeacon keep = HarborBeacon(child: SizedBox());
  HarborLighthouse.reveal(context);
  const HarborLighthouseRegion region = HarborLighthouseRegion(child: SizedBox());
  final List<HarborChartEntry> entries = HarborChart.snapshot(context);
  const HarborChartOverlay inspector = HarborChartOverlay(child: SizedBox());
  final HarborFleet registry = controller.fleet;
  const HarborFleetObserver log = Log();
  const HarborScaleModel scaled = HarborScaleModel(referenceSize: Size(1200, 675), child: SizedBox());

  <Object?>[sea, frame, nearest, kind, state, stance, records, pinned, hide, handle, edges, fixed, feature];
  <Object?>[keyboard, phase, keyboardStance, space, source, room, handled, clear, scroll, box, sliver, fade];
  <Object?>[fadeKind, band, painter, mask, target, queue, toastPhase, hold, transition, popover, cover, keep];
  <Object?>[region, entries, inspector, registry, log, scaled];
}
