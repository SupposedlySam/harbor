// The `bars:` transforms (lib/fix_data/bars.yaml): this file is written against `clear:`, deprecated
// in 0.8.0 and removed in 0.9.0, and against 0.8.0's `bars:`, renamed `clearsBars:` in 0.9.0.
// bars.dart.expect is what `dart fix --apply` makes of it: the rename's transforms (rename.yaml)
// take the old names to the new ones as it goes.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void moored(BuildContext context) {
  // The coast alone becomes clearsBars: false; everything, the default, goes.
  const HarborMoored(clear: HarborClear.coast, child: SizedBox());
  const HarborMoored(clear: HarborClear.everything, child: SizedBox());
  const HarborMoored(edges: {HarborEdge.top}, clear: HarborClear.coast, tide: false, child: SizedBox());
  HarborMoored.clearanceOf(context, clear: HarborClear.coast);
  HarborMoored.clearanceOf(context, edges: HarborEdge.vertical, clear: HarborClear.everything);
}

void both(BuildContext context, bool b) {
  // 0.8 allowed both: bars && clear != coast. With coast the result is false whatever bars says,
  // so both go and clearsBars: false is written once; with everything, bars stands, renamed.
  const HarborMoored(bars: true, clear: HarborClear.coast, child: SizedBox());
  HarborMoored(bars: b, clear: HarborClear.coast, child: const SizedBox());
  HarborMoored(bars: b, clear: HarborClear.everything, child: const SizedBox());
  const HarborFairway(clear: HarborClear.coast, bars: false, slivers: <Widget>[]);
  HarborFairway.paddingOf(context, bars: b, clear: HarborClear.everything);
  const HarborFairwaySliver(bars: true, clear: HarborClear.coast, sliver: SliverToBoxAdapter());
}

void bars(BuildContext context, bool b) {
  // 0.8.0's bars: alone is clearsBars: in 0.9.0.
  const HarborMoored(bars: false, child: SizedBox());
  HarborMoored.clearanceOf(context, bars: b);
  const HarborFairway(bars: false, slivers: <Widget>[]);
  HarborFairway.box(bars: false, child: const SizedBox());
  HarborFairway.paddingOf(context, bars: b);
  const HarborFairwaySliver(bars: false, sliver: SliverToBoxAdapter());
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
