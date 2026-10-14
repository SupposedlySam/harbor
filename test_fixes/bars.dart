// The `bars:` transforms (lib/fix_data/bars.yaml): this file is written against `clear:`, deprecated
// in 0.8.0 and removed in 0.9.0, and bars.dart.expect is what `dart fix --apply` makes of it: the
// rename's transforms (rename.yaml) take the old class names to the new ones as it goes.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void moored(BuildContext context) {
  // The coast alone becomes bars: false; everything, the default, goes.
  const HarborMoored(clear: HarborClear.coast, child: SizedBox());
  const HarborMoored(clear: HarborClear.everything, child: SizedBox());
  const HarborMoored(edges: {HarborEdge.top}, clear: HarborClear.coast, tide: false, child: SizedBox());
  HarborMoored.clearanceOf(context, clear: HarborClear.coast);
  HarborMoored.clearanceOf(context, edges: HarborEdge.vertical, clear: HarborClear.everything);
}

void fairways(BuildContext context) {
  const HarborFairway(clear: HarborClear.coast, slivers: <Widget>[]);
  const HarborFairway(scrollDirection: Axis.horizontal, clear: HarborClear.everything, slivers: <Widget>[]);
  HarborFairway.box(clear: HarborClear.coast, tide: false, child: const SizedBox());
  HarborFairway.paddingOf(context, clear: HarborClear.coast);
  HarborFairway.paddingOf(context, axis: Axis.horizontal, clear: HarborClear.everything);
  const HarborFairwaySliver(clear: HarborClear.coast, sliver: SliverToBoxAdapter());
  const HarborFairwaySliver(clearLeading: false, clear: HarborClear.everything, sliver: SliverToBoxAdapter());
}
