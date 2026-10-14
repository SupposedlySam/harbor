// The signal names' `dart fix` transforms (lib/fix_data/signals.yaml): flares were signals through
// 0.3.0. A call through an old name is renamed, and then takes the placement transforms too.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void signals(BuildContext context, HarborAnchor anchor) {
  HarborSignals.raise(context, slot: HarborSignalSlot.low, target: HarborSignalTarget.sea, builder: (_) => const SizedBox());
  final HarborSignalEntry entry = HarborSignals.raise(context, alignment: Alignment.bottomCenter, builder: (_) => const SizedBox());
  HarborSignals.raise(context, anchor: anchor, builder: (_) => const SizedBox());
  entry.closed.then((final HarborSignalClosedReason reason) => reason);
  final HarborSignalTransitionBuilder fade = (context, animation, child) => FadeTransition(opacity: animation, child: child);
  fade(context, const AlwaysStoppedAnimation<double>(1), const SizedBox());
}
