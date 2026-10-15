// The HarborDefaults transforms (lib/fix_data/defaults.yaml): a frame's and a root's hinge policy into
// `defaults:`, every combination, under the new and the 0.8 names, and HarborFlarePolicy into
// HarborDefaultsScope.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

void frames(HarborHinge h) {
  HarborFrame(hinge: HarborHinge.never, body: const SizedBox());
  HarborFrame(barHinge: h, body: const SizedBox());
  HarborFrame(dockHinge: HarborHinge.always, body: const SizedBox());
  HarborFrame(hinge: HarborHinge.never, barHinge: HarborHinge.always, body: const SizedBox());
  HarborFrame(hinge: h, dockHinge: HarborHinge.never, body: const SizedBox());
  Harbor(hinge: HarborHinge.avoidOccluding, body: const SizedBox());
  Harbor(dockHinge: HarborHinge.never, body: const SizedBox());
  HarborFrame.page(hinge: HarborHinge.never, body: const SizedBox());
  HarborFrame.page(barHinge: HarborHinge.never, body: const SizedBox());
  HarborFrame.page(hinge: h, barHinge: HarborHinge.always, body: const SizedBox());
  // Left alone: defaults: is given beside the old argument, and wins; merge them by hand.
  HarborFrame(defaults: const HarborDefaults(toastQueue: HarborToastQueue.replace), hinge: h, body: const SizedBox());
}

void roots(HarborHinge h) {
  HarborRoot(hinge: HarborHinge.never, child: const SizedBox());
  HarborRoot(hinge: h, child: const SizedBox());
  HarborSea(hinge: HarborHinge.never, child: const SizedBox());
}

void policies(HarborToastQueue q) {
  HarborFlarePolicy(queue: HarborToastQueue.replace, child: const SizedBox());
  HarborFlarePolicy(queue: q, child: const SizedBox());
}

// Left alone, and must not stop dart fix: with HarborFlarePolicy deprecated as a class, a static
// call through it crashed the analysis server under `dart fix --apply`, so only its constructor is.
HarborToastQueue queue(BuildContext context) => HarborFlarePolicy.queueOf(context);

// Owner review's shape: an outer barHinge over a nested frame's own hinge. test/defaults_test.dart
// measures the migrated form keeping the inner tabs at 540.
Widget nested(Widget tabs) => HarborFrame(
  barHinge: HarborHinge.never,
  body: HarborFrame(hinge: HarborHinge.avoidSeparating, bottom: <HarborBar>[HarborBar.solid(child: tabs)], body: const SizedBox()),
);
