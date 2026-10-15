// #117: a toast that takes its place's turn at once, show(queue: replace) or a HarborFlarePolicy.
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
    for (final bool frame in <bool>[true, false]) {
      testWidgets('stops its transition and completes with null (page with frame: $frame)', (final tester) async {
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
                return frame ? HarborFrame(body: body) : body;
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

  group('#117 a toast that takes its turn at once', () {
    Future<BuildContext> page(
      final WidgetTester tester, {
      final bool root = true,
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
          builder: root ? (final BuildContext context, final Widget? child) => HarborRoot(child: child!) : null,
          home: root ? HarborFrame(body: body) : body,
        ),
      );
      return inside;
    }

    Widget text(final String label) => Text(label);

    for (final bool root in <bool>[true, false]) {
      testWidgets('replace: shown at once, the one up hidden as replaced (root: $root)', (final tester) async {
        final BuildContext inside = await page(tester, root: root);
        final HarborToastEntry first = HarborToasts.show(
          inside,
          slot: HarborToastSlot.low,
          builder: (final BuildContext _) => text('saved'),
          timing: HarborToastTiming.untilHidden,
        );
        await _step(tester);
        HarborToastClosedReason? why;
        unawaited(first.closed.then((final HarborToastClosedReason r) => why = r));
        HarborToasts.show(
          inside,
          slot: HarborToastSlot.low,
          queue: HarborToastQueue.replace,
          builder: (final BuildContext _) => text('undo'),
          timing: HarborToastTiming.untilHidden,
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
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('undo'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('saved'), findsOneWidget);
      expect(find.text('undo'), findsNothing);
    });

    testWidgets('a HarborFlarePolicy sets it for a subtree, and a show can still wait under it', (final tester) async {
      final BuildContext inside = await page(tester, policy: HarborToastQueue.replace);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('saved'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('removed'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('removed'), findsOneWidget);
      expect(find.text('saved'), findsNothing);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        queue: HarborToastQueue.wait,
        builder: (final BuildContext _) => text('later'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('removed'), findsOneWidget);
      expect(find.text('later'), findsNothing);
    });

    testWidgets('only its own place: a toast at another slot stays up', (final tester) async {
      final BuildContext inside = await page(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.top,
        builder: (final BuildContext _) => text('top'),
        timing: HarborToastTiming.untilHidden,
      );
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        builder: (final BuildContext _) => text('saved'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      HarborToasts.show(
        inside,
        slot: HarborToastSlot.low,
        queue: HarborToastQueue.replace,
        builder: (final BuildContext _) => text('undo'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('top'), findsOneWidget);
      expect(find.text('undo'), findsOneWidget);
    });
  });
}
