// What `dart fix` cannot do for 0.8-era code fixed against 1.0 directly, without stepping through
// 0.10.3 (DECISIONS.md, "Fix data after 1.0"). 1.0 removed the deprecated names, so the analyzer
// reports each of these as undefined rather than deprecated, and offers no data-driven fix for it.
// jump_to_1_0.dart.expect is what `dart fix --apply` makes of it: these lines are left as they are,
// or half done. On 0.10.3 every one of them migrates. If a line here starts to migrate, the
// analyzer has changed, and the CHANGELOG's list for 1.0.0-dev.1 can lose it.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

// A `const` creation of a removed class (creation_with_non_type, or an undefined name): left as it
// is. The same call without `const` migrates (rename_constructors.dart, bars.dart).
const HarborDock header = HarborDock.pier(child: SizedBox());
const HarborMoored footer = HarborMoored(bars: false, child: SizedBox());

void values(BuildContext context, HarborFlareEntry toast, RenderBox box, HarborController frame) {
  // A renamed enum value (undefined_enum_constant): the type is renamed, the value is not.
  <Object>[HarborDockKind.pier, HarborTidePhase.low, HarborFlareTarget.sea, HarborAnchorSide.before];
  // A static of a class that split in two (HarborKeepInSight): left as it is.
  HarborKeepInSight.reveal(context);
  HarborKeepInSight.coverageOf(box, frame, HarborEdge.top);
  // A rename whose target 1.0 removed too: the type is renamed, the getter is not.
  <Object?>[toast.raisedIn, toast.reachesCoast];
  // A tear-off of a removed constructor: renamed with its class, to a constructor that is not there.
  final HarborDock Function({required Widget child}) pier = HarborDock.pier;
  <Object?>[pier];
}

// A getter read through implicit `this` in an extension: left as it is. Read through a receiver
// (`bar.wake`), or in a subclass, it migrates (rename_members.dart).
extension Reads on HarborDock {
  List<Object?> get reads => <Object?>[wake, tide];
}

Future<void> trials(WidgetTester tester) async {
  // An explicit extension override: the extension is renamed, its method is not.
  await HarborSeaTrials(tester).pumpSeaTrial(const SizedBox());
}
