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

void withdraws(bool b) {
  // withdrawsAtHighTide becomes a keyboard stance, where the bar stays (the default). With rides or
  // reserves, or a variable, it cannot be one stance, so it is left on the deprecated flag.
  const HarborBar.overlay(withdrawsAtHighTide: true, child: SizedBox());
  const HarborBar.solid(keyboard: HarborKeyboardStance.stays, withdrawsAtHighTide: true, child: SizedBox());
  const HarborBar.reserve(extent: 40, withdrawsAtHighTide: true);
  const HarborBar.solid(withdrawsAtHighTide: false, child: SizedBox());
  const HarborBar.solid(keyboard: HarborKeyboardStance.rides, withdrawsAtHighTide: true, child: SizedBox());
  HarborBar.overlay(withdrawsAtHighTide: b, child: const SizedBox());
  // The 0.8 names chain through the rename.
  const HarborDock.quay(tide: HarborTideStance.pilings, withdrawsAtHighTide: true, child: SizedBox());
  const HarborDock.pier(withdrawsAtHighTide: true, child: SizedBox());
}

void animationStyle(Duration d) {
  // duration: and curve: go into animationStyle:, alone or together; given beside an
  // animationStyle they are left, deprecated and still working.
  const HarborBar.overlay(duration: Duration(milliseconds: 120), child: SizedBox());
  const HarborBar.solid(curve: Curves.linear, child: SizedBox());
  HarborBar.reserve(extent: 40, duration: d, curve: Curves.easeOut);
  const HarborBar.solid(
    duration: Duration(milliseconds: 120),
    animationStyle: AnimationStyle(reverseDuration: Duration(milliseconds: 60)),
    child: SizedBox(),
  );
  const HarborDock.pier(duration: Duration(milliseconds: 90), child: SizedBox());
  const HarborKeepInSightRegion(duration: Duration(milliseconds: 400), curve: Curves.easeIn, child: SizedBox());
  const HarborKeepInSightRegion(curve: Curves.easeIn, child: SizedBox());
}

void sizing(HarborSizing variable, double f) {
  // HarborSizing is a class: hugBody is hug(), and a frame's maxExtentFraction moves into it. A
  // frame that fills never read the fraction, so it goes; beside a variable sizing it is left.
  const HarborFrame(sizing: HarborSizing.hugBody, body: SizedBox());
  const HarborFrame(sizing: HarborSizing.hugBody, maxExtentFraction: 0.5, body: SizedBox());
  HarborFrame.page(sizing: HarborSizing.hugBody, maxExtentFraction: f, body: const SizedBox());
  const HarborFrame(maxExtentFraction: 0.5, body: SizedBox());
  const HarborFrame(sizing: HarborSizing.fill, maxExtentFraction: 0.5, body: SizedBox());
  HarborFrame(sizing: variable, maxExtentFraction: 0.5, body: const SizedBox());
  const HarborSizing hugs = HarborSizing.hugBody;
  const Harbor(sizing: HarborSizing.hugBody, maxExtentFraction: 0.8, body: SizedBox());
  <Object>[hugs];
}

void keepInSight(BuildContext context, RenderBox box, HarborController frame, bool b) {
  // HarborKeepInSight splits into three widgets. A call that does one job becomes that widget, its
  // keepInSight: or lift: the new widget's active: when it is not true; one that does two is left.
  HarborKeepInSight(onObscured: (double c) {}, child: const SizedBox());
  HarborKeepInSight(edge: HarborEdge.bottom, onObscured: (double c) {}, clearance: 8, child: const SizedBox());
  const HarborKeepInSight(keepInSight: true, child: SizedBox());
  const HarborKeepInSight(keepInSight: true, onlyWhileFocused: true, clearance: 16, child: SizedBox());
  const HarborKeepInSight(lift: true, clearance: 80, holdPosition: true, child: SizedBox());
  HarborKeepInSight(keepInSight: true, onObscured: (double c) {}, child: const SizedBox());
  HarborKeepInSight(keepInSight: b, child: const SizedBox());
  HarborKeepInSight(lift: b, holdPosition: b, child: const SizedBox());
  const HarborKeepInSightRegion(child: SizedBox());
  // The 0.8 names chain through the rename.
  const HarborBeacon(keepInSight: true, clearance: 24, child: SizedBox());
  const HarborLighthouseRegion(child: HarborBeacon(lift: true, child: SizedBox()));
  HarborKeepInSight.reveal(context, clearance: 24);
  HarborLighthouse.reveal(context);
  HarborKeepInSight.coverageOf(box, frame, HarborEdge.top);
}
