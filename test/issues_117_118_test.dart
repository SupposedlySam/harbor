// #117: a flare that takes its place's turn at once, raise(queue: replace) or a HarborFlarePolicy.
// #118: a non-modal sheet's transition is stopped when its overlay goes with the sheet still open.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Future<void> _step(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('#118 a non-modal sheet torn down with its overlay', () {
    for (final bool harbor in <bool>[true, false]) {
      testWidgets('stops its transition and completes with null (page with harbor: $harbor)', (final tester) async {
        late BuildContext page;
        await tester.pumpHarborTrial(
          MaterialApp(
            builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
            home: Builder(
              builder: (final BuildContext context) {
                final Widget body = Builder(
                  builder: (final BuildContext inner) {
                    page = inner;
                    return const SizedBox.expand();
                  },
                );
                return harbor ? HarborFrame(body: body) : body;
              },
            ),
          ),
        );
        String result = 'pending';
        unawaited(
          showHarborSheet<String>(
            page,
            barrier: HarborBarrier.none,
            builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 100)),
          ).then((final String? r) => result = r ?? 'null'),
        );
        await tester.pump(const Duration(milliseconds: 100)); // mid-transition
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'no ticker left running on the disposed overlay');
        expect(result, 'null');
      });
    }
  });

  group('#117 a flare that takes its turn at once', () {
    Future<BuildContext> page(
      final WidgetTester tester, {
      final bool sea = true,
      final HarborToastQueue? policy,
    }) async {
      late BuildContext inside;
      Widget body = Builder(
        builder: (final BuildContext context) {
          inside = context;
          return const SizedBox.expand();
        },
      );
      if (policy != null) {
        body = HarborFlarePolicy(queue: policy, child: body);
      }
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: sea ? (final BuildContext context, final Widget? child) => HarborRoot(child: child!) : null,
          home: sea ? HarborFrame(body: body) : body,
        ),
      );
      return inside;
    }

    Widget text(final String label) => Text(label);

    for (final bool sea in <bool>[true, false]) {
      testWidgets('replace: shown at once, the one up lowered as replaced (sea: $sea)', (final tester) async {
        final BuildContext inside = await page(tester, sea: sea);
        final HarborToastEntry first = HarborToasts.show(
          inside,
          slot: HarborToastSlot.low,
          builder: (final BuildContext _) => text('saved'),
          duration: null,
        );
        await _step(tester);
        HarborToastClosedReason? why;
        unawaited(first.closed.then((final HarborToastClosedReason r) => why = r));
        HarborToasts.show(
          inside,
          slot: HarborToastSlot.low,
          queue: HarborToastQueue.replace,
          builder: (final BuildContext _) => text('undo'),
          duration: null,
        );
        await _step(tester);
        expect(find.text('undo'), findsOneWidget);
        expect(find.text('saved'), findsNothing);
        expect(why, HarborToastClosedReason.replaced);
      });
    }

    testWidgets('positive control: by default it waits its turn', (final tester) async {
      final BuildContext inside = await page(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('saved'),
        duration: null,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('undo'),
        duration: null,
      );
      await _step(tester);
      expect(find.text('saved'), findsOneWidget);
      expect(find.text('undo'), findsNothing);
    });

    testWidgets('a HarborFlarePolicy sets it for a subtree, and a raise can still wait under it', (final tester) async {
      final BuildContext inside = await page(tester, policy: HarborToastQueue.replace);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('saved'),
        duration: null,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('removed'),
        duration: null,
      );
      await _step(tester);
      expect(find.text('removed'), findsOneWidget);
      expect(find.text('saved'), findsNothing);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        queue: HarborToastQueue.wait,
        builder: (final BuildContext _) => text('later'),
        duration: null,
      );
      await _step(tester);
      expect(find.text('removed'), findsOneWidget);
      expect(find.text('later'), findsNothing);
    });

    testWidgets('only its own place: a flare at another slot stays up', (final tester) async {
      final BuildContext inside = await page(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.top,
        builder: (final BuildContext _) => text('top'),
        duration: null,
      );
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('saved'),
        duration: null,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        queue: HarborToastQueue.replace,
        builder: (final BuildContext _) => text('undo'),
        duration: null,
      );
      await _step(tester);
      expect(find.text('top'), findsOneWidget);
      expect(find.text('undo'), findsOneWidget);
    });
  });
}
