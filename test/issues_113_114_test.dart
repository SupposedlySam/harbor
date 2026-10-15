// #113: a toast that keeps counting while a route covers its page. #114: a hinge policy for a
// frame's bars alone, HarborDefaults(barHinge:), leaving its overlays the policy above.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

void main() {
  group('#113 countsWhileCovered', () {
    Future<HarborToastEntry> showThenCover(
      final WidgetTester tester, {
      required final bool counts,
      final bool hold = false,
    }) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          navigatorKey: _navigator,
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      final HarborToastEntry entry = HarborToasts.show(
        page,
        builder: (final BuildContext _) => const Text('saved'),
        timing: HarborToastTiming(duration: const Duration(seconds: 2), countsWhileCovered: counts),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // the entrance
      if (hold) {
        entry.hold();
      }
      unawaited(
        _navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (final BuildContext _) => const HarborFrame(body: Text('next page'))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      return entry;
    }

    testWidgets('positive control: by default its time stops under the covering page', (final tester) async {
      final HarborToastEntry entry = await showThenCover(tester, counts: false);
      expect(entry.showing.value, isTrue);
    });

    testWidgets('with it, the time runs under the covering page and the toast is gone on return', (final tester) async {
      final HarborToastEntry entry = await showThenCover(tester, counts: true);
      expect(entry.showing.value, isFalse);
    });

    testWidgets('a hold still stops it', (final tester) async {
      final HarborToastEntry entry = await showThenCover(tester, counts: true, hold: true);
      expect(entry.showing.value, isTrue);
    });
  });

  group('#114 HarborDefaults(barHinge:)', () {
    const HarborTrialDevice dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540

    Future<BuildContext> page(
      final WidgetTester tester, {
      final HarborHinge? hinge,
      final HarborHinge? barHinge,
    }) async {
      late BuildContext inside;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            defaults: HarborDefaults(hinge: hinge, barHinge: barHinge),
            bottom: const <HarborBar>[
              HarborBar.solid(
                child: SizedBox(key: ValueKey<String>('tabs'), height: 56, width: double.infinity),
              ),
            ],
            body: Builder(
              builder: (final BuildContext context) {
                inside = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        device: dual,
      );
      return inside;
    }

    Future<Rect> sheet(final WidgetTester tester, final BuildContext page) async {
      unawaited(
        showHarborSheet<void>(
          page,
          builder: (final BuildContext _) =>
              const HarborSheet(body: SizedBox(key: ValueKey<String>('sheet'), height: 100)),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(find.byKey(const ValueKey<String>('sheet')));
    }

    testWidgets('it lays the bars across the hinge and leaves the overlays keeping off it', (final tester) async {
      final BuildContext inside = await page(tester, barHinge: HarborHinge.never);
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).width, 1114);
      expect((await sheet(tester, inside)).right, lessThanOrEqualTo(540));
    });

    testWidgets('positive control: hinge: sets both, so the sheet crosses too', (final tester) async {
      final BuildContext inside = await page(tester, hinge: HarborHinge.never);
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).width, 1114);
      expect((await sheet(tester, inside)).right, 1114);
    });

    testWidgets('with neither, the bars keep off it', (final tester) async {
      await page(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('tabs'))).right, 540);
    });
  });
}
