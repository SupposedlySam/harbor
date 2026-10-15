// The audit's transforms (lib/fix_data/audit.yaml): this file is written against the spellings
// deprecated after 0.9.1. audit.dart.expect is what `dart fix --apply` makes of it.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void hideBar(BuildContext context, HarborController frame, HarborYield variable) {
  // HarborYield merges into HarborBarState: a written-out mode becomes state, withdraw (the
  // default) goes, and a variable is left on the deprecated mode, which still works.
  const HarborHideBar(edge: HarborEdge.bottom, mode: HarborYield.dark, child: SizedBox());
  const HarborHideBar(edge: HarborEdge.bottom, mode: HarborYield.withdraw, child: SizedBox());
  HarborHideBar(edge: HarborEdge.top, mode: variable, child: const SizedBox());
  const HarborMakeWay(edge: HarborEdge.bottom, mode: HarborYield.dark, child: SizedBox());
  frame.hideBar(HarborEdge.top, mode: HarborYield.dark);
  frame.hideBar(HarborEdge.top, mode: HarborYield.withdraw);
  frame.hideBar(HarborEdge.top, mode: variable);
  frame.makeWay(HarborEdge.bottom, mode: HarborYield.dark);
  HarborFrame.of(context).hideBar(HarborEdge.bottom, mode: HarborYield.dark);
}
