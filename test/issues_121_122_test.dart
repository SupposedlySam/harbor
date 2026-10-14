// #121: a sheet controller's close() and remove() do nothing once its sheet has left.
// #122: a flare's lifecycle, read synchronously: waiting, shown, closed, and whether it was seen.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Future<BuildContext> _page(final WidgetTester tester, {final bool sea = true}) async {
  late BuildContext inside;
  final Widget body = Builder(
    builder: (final BuildContext context) {
      inside = context;
      return const SizedBox.expand();
    },
  );
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: sea ? (final BuildContext context, final Widget? child) => HarborRoot(child: child!) : null,
      home: sea ? HarborFrame(body: body) : body,
    ),
  );
  return inside;
}

void main() {
  group('#121 a controller whose sheet has left', () {
    for (final String how in <String>['closed by the controller', 'torn down with its overlay']) {
      testWidgets('close() and remove() do nothing, and closed is complete ($how)', (final tester) async {
        final BuildContext page = await _page(tester);
        final HarborSheetController controller = HarborSheetController();
        addTearDown(controller.dispose);
        unawaited(
          showHarborSheet<void>(
            page,
            barrier: HarborBarrier.none,
            controller: controller,
            builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 100)),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.isAttached, isTrue, reason: 'positive control');
        if (how == 'closed by the controller') {
          controller.close();
          await tester.pumpAndSettle();
        } else {
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
        }
        expect(controller.isAttached, isFalse);
        controller
          ..close()
          ..remove();
        expect(tester.takeException(), isNull);
        bool done = false;
        unawaited(controller.closed.then((final _) => done = true));
        await tester.pump();
        expect(done, isTrue);
      });
    }

    testWidgets('close() twice while it slides out is one close', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborSheetController controller = HarborSheetController();
      addTearDown(controller.dispose);
      int results = 0;
      unawaited(
        showHarborSheet<void>(
          page,
          barrier: HarborBarrier.none,
          controller: controller,
          builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 100)),
        ).then((final _) => results++),
      );
      await tester.pumpAndSettle();
      controller.close();
      await tester.pump(const Duration(milliseconds: 50));
      controller.close();
      await tester.pumpAndSettle();
      expect(results, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('#122 a flare\'s phase', () {
    for (final bool sea in <bool>[true, false]) {
      testWidgets('lowered while it waits its turn: closed at once, never shown (sea: $sea)', (final tester) async {
        final BuildContext page = await _page(tester, sea: sea);
        final HarborToastEntry up = HarborToasts.show(
          page,
          builder: (final BuildContext _) => const Text('up'),
          duration: null,
        );
        final HarborToastEntry waiting = HarborToasts.show(
          page,
          builder: (final BuildContext _) => const Text('next'),
          duration: null,
        );
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(up.phase, HarborToastPhase.shown);
        expect(up.wasShown, isTrue);
        expect(waiting.phase, HarborToastPhase.waiting);
        waiting.hide();
        expect(waiting.phase, HarborToastPhase.closed, reason: 'answered on the spot, before closed completes');
        expect(waiting.wasShown, isFalse);
      });

      testWidgets('raised and lowered in the same frame: closed, never shown (sea: $sea)', (final tester) async {
        final BuildContext page = await _page(tester, sea: sea);
        final HarborToastEntry entry = HarborToasts.show(
          page,
          builder: (final BuildContext _) => const Text('cancelled'),
          duration: null,
        );
        entry.hide();
        await tester.pump();
        expect(entry.phase, HarborToastPhase.closed);
        expect(entry.wasShown, isFalse);
      });
    }

    testWidgets('shown, then lowered: closed once it has left, and it was shown', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        builder: (final BuildContext _) => const Text('saved'),
        duration: null,
      );
      await tester.pump();
      expect(entry.phase, HarborToastPhase.shown);
      entry.hide();
      expect(entry.phase, HarborToastPhase.shown, reason: 'still running its exit');
      // Its exit, then the 300 ms it lingers: a timer pumpAndSettle does not wait for.
      await tester.pump(const Duration(milliseconds: 500));
      expect(entry.phase, HarborToastPhase.closed);
      expect(entry.wasShown, isTrue);
    });
  });
}
