// The rename's constructor transforms (lib/fix_data/rename.yaml, 0.9.0): HarborDock, a deprecated
// subclass whose constructors are replaced by HarborBar's; HarborMooringLine, replaced by
// HarborClear.rowInsets; HarborBuoy, a subclass too; and named constructors reached through an old
// type name, which keep their names.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void bars() {
  final List<HarborDock> top = <HarborDock>[
    const HarborDock.pier(child: SizedBox()),
    const HarborDock.quay(debugLabel: 'tabs', child: SizedBox()),
    const HarborDock.reserve(extent: 80),
    const HarborDock.reserve(extent: 40, kind: HarborDockKind.quay),
  ];
  Harbor(top: top, bottom: const <HarborDock>[HarborDock.quay(child: SizedBox())], body: const SizedBox());
  final HarborDock Function({required Widget child}) pier = HarborDock.pier;
  <Object?>[pier];
}

void rows() {
  const HarborMooringLine(child: SizedBox());
  const HarborMooringLine(follow: HarborFollow.resting, child: SizedBox());
  // A tear-off and the type HarborMooringLine have no HarborClear equivalent: left, deprecated.
  final HarborMooringLine Function({required Widget child}) row = HarborMooringLine.new;
  <Object?>[row];
}

void floats(HarborAnchor anchor) {
  const HarborBuoy(child: SizedBox());
  const HarborBuoy(modal: true, onDismiss: _close, child: SizedBox());
  const List<HarborBuoy> floats = <HarborBuoy>[HarborBuoy(child: SizedBox())];
  <Object?>[floats];
}

void named(BuildContext context) {
  HarborFairway.box(child: const SizedBox());
  HarborFairway.paddingOf(context);
  const HarborCoast.fixed(EdgeInsets.zero);
  const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05));
  const HarborWake.fade(length: 12);
  const HarborWake.hairline();
  HarborSheet.draggable(builder: (context, controller) => const SizedBox());
}

// A value the API returns, kept in a variable typed with an old subclass name. Before the fix this
// does not compile, since the API returns the new class; the fix renames the type, so after it,
// it does. No API returns a HarborFairway, so it is declared from its own constructor.
void stored(HarborDock dock, Harbor frame, HarborSea sea) {
  final HarborWake edge = dock.wake;
  final List<HarborDock> top = frame.top;
  final HarborCoast? edges = frame.coast;
  final HarborCoast root = sea.coast;
  final List<HarborBuoy> floats = frame.buoys;
  final HarborFairway scroll = HarborFairway(slivers: const <Widget>[]);
  final HarborDock copy = dock.copyWith(tide: HarborTideStance.float);
  <Object?>[edge, top, edges, root, floats, scroll, copy];
}

void _close() {}
