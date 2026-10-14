// The rename's enum value transforms (lib/fix_data/rename.yaml, 0.9.0): every renamed value, through
// the old type name and the new one, in an expression and in a switch.

import 'package:harbor/harbor.dart';

String values(final HarborTideStance stance, final HarborTidePhase phase) {
  final List<Object> all = <Object>[
    HarborTideStance.float,
    HarborTideStance.pilings,
    HarborTideStance.dryDock,
    HarborKeyboardStance.float,
    HarborTidePhase.low,
    HarborTidePhase.rising,
    HarborTidePhase.high,
    HarborTidePhase.falling,
    HarborDockKind.pier,
    HarborDockKind.quay,
    HarborBarKind.quay,
    HarborFlareTarget.sea,
    HarborFlareClosedReason.lower,
    HarborWatersAspect.coast,
    HarborWatersAspect.docks,
    HarborRest.wakeEnd,
    HarborRest.dockEdge,
  ];
  final String a = switch (stance) {
    HarborTideStance.float => 'rides',
    HarborTideStance.pilings => 'stays',
    HarborTideStance.dryDock => 'reserves',
  };
  switch (phase) {
    case HarborTidePhase.low:
    case HarborTidePhase.rising:
      return a;
    case HarborTidePhase.high || HarborTidePhase.falling:
      return '$all';
  }
}
