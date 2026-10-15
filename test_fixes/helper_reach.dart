// A file that reaches renamed members through a helper's typed field and return value, and imports
// neither harbor nor harbor_test (#150). dart fix leaves it as it is, so its .expect is itself. That
// is the analyzer (Dart 3.13.3): it offers a transform only in a file that imports one of the
// element's `uris:` (ElementMatcher.matches, data_driven/element_matcher.dart:132), and reads the
// file's own imports, not the library that declares the element or one that re-exports it
// (dart-lang/sdk#59764, #62491). helper_reach_imported.dart is the same file with the imports, and
// is migrated. The README's upgrading section and each release's Migrating notes say to add the
// import before `dart fix`. If the analyzer learns to follow the element, this golden fails, and the
// notes can go.

import 'package:flutter_test/flutter_test.dart';

import 'helper_reach_support.dart';

Future<void> reach(final WidgetTester tester) async {
  final Session session = await openSession(tester);
  session.trial.docksAround(find.byType(Session));
  session.trial.clearWaterAround(find.byType(Session));
  <Object?>[session.frame.coast, frameOf(session).buoys];
}
