// helper_reach.dart with the imports of harbor and harbor_test added (#150): each call is migrated.
// The imports name nothing the file uses, so dart fix removes them too, and the file ends as
// helper_reach.dart would have if the analyzer had migrated it.
//
// Each call is migrated by one fix file only, so the golden does not depend on their order.

import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

import 'helper_reach_support.dart';

Future<void> reach(final WidgetTester tester) async {
  final Session session = await openSession(tester);
  session.trial.docksAround(find.byType(Session));
  session.trial.clearWaterAround(find.byType(Session));
  <Object?>[session.frame.coast, frameOf(session).buoys];
}
