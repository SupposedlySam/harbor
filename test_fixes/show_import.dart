// A file that imports harbor with `show` (#146). dart fix writes the new names a template brings in
// (HarborToastTiming, HarborAligned, HarborBarrier, HarborDefaults, HarborDefaultsScope,
// HarborBarState) bare, and leaves the `show` list as it was, so show_import.dart.expect does not
// compile: each new name is an undefined_function or undefined_identifier. That is the analyzer
// (Dart 3.13.3): a template's `kind: 'import'` variable reaches DartEditBuilder.writeImportedName,
// which takes the existing import of package:harbor/harbor.dart without reading its combinators, and
// a `replacedBy` asks importLibraryElement for that import without a name to show. A rename is
// different: it renames the name in the `show` list too, as HarborDockKind shows here. The README's
// upgrading section and each release's Migrating notes say what to do by hand. If the analyzer
// learns to extend the list, this golden fails, and the notes can go.
//
// Each call is migrated by one fix file only, so the golden does not depend on their order.

import 'package:flutter/widgets.dart';
import 'package:harbor/harbor.dart'
    show
        HarborController,
        HarborDockKind,
        HarborEdge,
        HarborFlarePolicy,
        HarborHinge,
        HarborRoot,
        HarborToastQueue,
        HarborToasts,
        HarborYield,
        showHarborSheet;

Widget _toast(BuildContext context) => const SizedBox();

Object show(BuildContext context, HarborController frame) {
  // A rename: the shown name is renamed with the call.
  const Object kind = HarborDockKind.pier;
  // toasts.yaml: HarborToastTiming.
  HarborToasts.show(context, duration: const Duration(seconds: 2), builder: _toast);
  // placement.yaml: HarborAligned.
  HarborToasts.show(context, alignment: Alignment.topCenter, builder: _toast);
  // sheets.yaml: HarborBarrier.
  showHarborSheet<void>(context, isDismissible: false, builder: (_) => const SizedBox());
  // defaults.yaml: HarborDefaults, and HarborDefaultsScope by replacedBy.
  HarborRoot(hinge: HarborHinge.never, child: const SizedBox());
  HarborFlarePolicy(queue: HarborToastQueue.replace, child: const SizedBox());
  // audit.yaml: HarborBarState.
  frame.hideBar(HarborEdge.top, mode: HarborYield.dark);
  return kind;
}
