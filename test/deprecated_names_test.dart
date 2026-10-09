// The names harbor used before 1.0 still compile and still work, until 1.0 removes them.
//
// Each old name is used once here, the way a consumer's code written against it would use it.

// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

void main() {
  group('Signals, renamed flares', () {
    test('are the same types under their old names', () {
      expect(HarborSignals, HarborFlares);
      expect(HarborSignalSlot, HarborFlareSlot);
      expect(HarborSignalTarget, HarborFlareTarget);
      expect(HarborSignalEntry, HarborFlareEntry);
      expect(HarborSignalClosedReason, HarborFlareClosedReason);
      expect(HarborSignalSlot.values, HarborFlareSlot.values);
      expect(HarborSignalClosedReason.values, HarborFlareClosedReason.values);
    });

    testWidgets('raise, show, list and close as flares do', (final tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
          home: Material(
            child: Harbor(
              body: Builder(
                builder: (final BuildContext context) {
                  page = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      bool transitioned = false;
      Widget transition(final BuildContext context, final Animation<double> animation, final Widget child) {
        transitioned = true;
        return FadeTransition(opacity: animation, child: child);
      }

      final HarborSignalTransitionBuilder builder = transition;
      final HarborSignalEntry entry = HarborSignals.raise(
        page,
        slot: HarborSignalSlot.low,
        target: HarborSignalTarget.topmost,
        transitionBuilder: builder,
        builder: (final BuildContext context) => const Text('Copied'),
        duration: null,
      );
      HarborSignalClosedReason? reason;
      unawaited(entry.closed.then((final HarborSignalClosedReason r) => reason = r));
      await tester.pumpAndSettle();

      expect(entry, isA<HarborFlareEntry>());
      expect(entry.alignment, HarborFlareSlot.low.alignment);
      expect(find.text('Copied'), findsOneWidget);
      expect(transitioned, isTrue, reason: 'the transition builder given under its old name ran');
      final HarborController harbor = HarborController.of(page);
      expect(harbor.signals, <HarborFlareEntry>[entry]);
      expect(harbor.signals, harbor.flares);

      entry.lower(reason: HarborSignalClosedReason.dismiss);
      await tester.pumpAndSettle();
      expect(find.text('Copied'), findsNothing);
      expect(reason, HarborFlareClosedReason.dismiss);
      expect(harbor.signals, isEmpty);
    });
  });
}
