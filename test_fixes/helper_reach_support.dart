// The helper helper_reach.dart and helper_reach_imported.dart reach harbor and harbor_test through
// (#150). It imports both libraries and uses nothing deprecated, so dart fix leaves it as it is: its
// .expect is itself.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

class Session {
  Session(this.trial, this.frame);

  final HarborTrial trial;
  final HarborFrame frame;
}

HarborFrame frameOf(final Session session) => session.frame;

Future<Session> openSession(final WidgetTester tester) async =>
    Session(await tester.pumpHarborTrial(const SizedBox()), const HarborFrame(body: SizedBox()));
