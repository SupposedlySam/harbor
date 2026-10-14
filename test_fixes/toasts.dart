// The toast timing transforms (lib/fix_data/toasts.yaml): `duration:`, `persist:`, `countsEntrance:`
// and `countsWhileCovered:` on HarborToasts.show become one `timing:`. toasts.dart.expect is what
// `dart fix --apply` makes of it.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart';

Widget _toast(BuildContext context) => const SizedBox();

void alone(BuildContext context, Duration d, bool b) {
  // Each old argument on its own.
  HarborToasts.show(context, duration: const Duration(seconds: 2), builder: _toast);
  HarborToasts.show(context, duration: d, builder: _toast);
  HarborToasts.show(context, duration: null, builder: _toast);
  HarborToasts.show(context, persist: true, builder: _toast);
  HarborToasts.show(context, persist: false, builder: _toast);
  HarborToasts.show(context, countsEntrance: true, builder: _toast);
  HarborToasts.show(context, countsWhileCovered: b, builder: _toast);
}

void together(BuildContext context, Duration d, bool b) {
  // persist: true ran out never, whatever the duration said.
  HarborToasts.show(context, duration: d, persist: true, builder: _toast);
  HarborToasts.show(context, duration: d, persist: false, builder: _toast);
  HarborToasts.show(context, persist: true, countsWhileCovered: true, builder: _toast);
  HarborToasts.show(context, duration: null, countsEntrance: b, builder: _toast);
  HarborToasts.show(
    context,
    slot: HarborToastSlot.low,
    duration: d,
    countsEntrance: true,
    countsWhileCovered: b,
    builder: _toast,
  );
  HarborToasts.show(context, persist: false, countsEntrance: true, builder: _toast);
}

void untouched(BuildContext context, bool p) {
  // persist: given a variable is left for you, with the rest of the call.
  HarborToasts.show(context, persist: p, builder: _toast);
  HarborToasts.show(context, persist: p, duration: null, builder: _toast);
}

void older(BuildContext context, HarborAnchor anchor) {
  // The 0.8 and 0.3 names, and the 0.6 placement arguments, migrate on the way.
  HarborFlares.raise(context, persist: true, builder: _toast);
  HarborFlares.raise(context, alignment: Alignment.topCenter, duration: null, builder: _toast);
  HarborSignals.raise(context, anchor: anchor, countsWhileCovered: true, builder: _toast);
}
