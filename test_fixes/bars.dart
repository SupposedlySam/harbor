// The `bars:` transforms (lib/fix_data/bars.yaml): this file is written against `clear:`, deprecated
// in 0.8.0 and removed in 0.9.0, and against 0.8.0's `bars:`, renamed `clearsBars:` in 0.9.0.
// bars.dart.expect is what `dart fix --apply` makes of it: the rename's transforms (rename.yaml)
// take the old names to the new ones as it goes.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void moored(BuildContext context) {
  // The coast alone becomes clearsBars: false; everything, the default, goes.
  HarborMoored(clear: HarborClear.coast, child: SizedBox());
  HarborMoored(clear: HarborClear.everything, child: SizedBox());
  HarborMoored(edges: {HarborEdge.top}, clear: HarborClear.coast, tide: false, child: SizedBox());
  HarborMoored.clearanceOf(context, clear: HarborClear.coast);
  HarborMoored.clearanceOf(context, edges: HarborEdge.vertical, clear: HarborClear.everything);
}

void both(BuildContext context, bool b) {
  // 0.8 allowed both: bars && clear != coast. With coast the result is false whatever bars says,
  // so both go and clearsBars: false is written once; with everything, bars stands, renamed.
  HarborMoored(bars: true, clear: HarborClear.coast, child: SizedBox());
  HarborMoored(bars: b, clear: HarborClear.coast, child: const SizedBox());
  HarborMoored(bars: b, clear: HarborClear.everything, child: const SizedBox());
  HarborFairway(clear: HarborClear.coast, bars: false, slivers: <Widget>[]);
  HarborFairway.paddingOf(context, bars: b, clear: HarborClear.everything);
  HarborFairwaySliver(bars: true, clear: HarborClear.coast, sliver: SliverToBoxAdapter());
  // The same calls as dart fix sees them when rename.yaml runs first (the order Linux picked in #163's
  // CI): bars: is already clearsBars:, and the coast branch must still leave only one.
  HarborClear(clearsBars: true, clear: HarborClear.coast, child: SizedBox());
  HarborClear.clearanceOf(context, clearsBars: b, clear: HarborClear.coast);
}

void bars(BuildContext context, bool b) {
  // 0.8.0's bars: alone is clearsBars: in 0.9.0.
  HarborMoored(bars: false, child: SizedBox());
  HarborMoored.clearanceOf(context, bars: b);
  HarborFairway(bars: false, slivers: <Widget>[]);
  HarborFairway.box(bars: false, child: const SizedBox());
  HarborFairway.paddingOf(context, bars: b);
  HarborFairwaySliver(bars: false, sliver: SliverToBoxAdapter());
}

void fairways(BuildContext context) {
  HarborFairway(clear: HarborClear.coast, slivers: <Widget>[]);
  HarborFairway(scrollDirection: Axis.horizontal, clear: HarborClear.everything, slivers: <Widget>[]);
  HarborFairway.box(clear: HarborClear.coast, tide: false, child: const SizedBox());
  HarborFairway.paddingOf(context, clear: HarborClear.coast);
  HarborFairway.paddingOf(context, axis: Axis.horizontal, clear: HarborClear.everything);
  HarborFairwaySliver(clear: HarborClear.coast, sliver: SliverToBoxAdapter());
  HarborFairwaySliver(clearLeading: false, clear: HarborClear.everything, sliver: SliverToBoxAdapter());
}
