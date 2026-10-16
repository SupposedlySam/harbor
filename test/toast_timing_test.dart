// HarborToastTiming: one value for how long a toast stays (doc/design/flares.md, DECISIONS Q11-Q14),
// and the slim HarborToastEntry a caller holds.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Future<BuildContext> _page(final WidgetTester tester) async {
  late BuildContext page;
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final c, final child) => HarborRoot(child: child!),
      home: HarborFrame(
        body: Builder(
          builder: (final c) {
            page = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
    device: HarborTrialDevice.iPhone17,
  );
  return page;
}

/// Pumps [seconds] in 100 ms steps, so the entrance and the timer both run.
Future<void> _wait(final WidgetTester tester, final double seconds) async {
  for (int i = 0; i < (seconds * 10).round(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _toast(final BuildContext _) => const Text('toast');

/// Why [entry] closed, once it has left; fails rather than waiting forever on fake time.
Future<HarborToastClosedReason?> _closed(final WidgetTester tester, final HarborToastEntry entry) async {
  HarborToastClosedReason? why;
  unawaited(entry.closed.then((final HarborToastClosedReason r) => why = r));
  await _wait(tester, 1);
  expect(why, isNotNull, reason: 'it has left');
  return why;
}

/// Not a constant, so a timing built from it is not canonicalized.
Duration _twoSeconds() => const Duration(seconds: 2);

void main() {
  group('the value', () {
    test('defaults to a SnackBar\'s 4 s, counted in sight, entrance excluded', () {
      const HarborToastTiming timing = HarborToastTiming();
      expect(timing.duration, const Duration(seconds: 4));
      expect(timing.duration, HarborToastTiming.defaultDuration);
      expect(timing.countsEntrance, isFalse);
      expect(timing.countsWhileCovered, isFalse);
      expect(HarborToastTiming.untilHidden.duration, isNull);
    });

    test('is equal by value', () {
      expect(
        HarborToastTiming(duration: _twoSeconds(), countsEntrance: true),
        const HarborToastTiming(duration: Duration(seconds: 2), countsEntrance: true),
      );
      expect(const HarborToastTiming(countsWhileCovered: true), isNot(const HarborToastTiming()));
      expect(
        const HarborToastTiming(countsEntrance: true).hashCode,
        const HarborToastTiming(countsEntrance: true).hashCode,
      );
    });

    test('describes itself, leaving out its defaults', () {
      expect(const HarborToastTiming().toString(), 'HarborToastTiming');
      expect(HarborToastTiming.untilHidden.toString(), 'HarborToastTiming(duration: until hidden)');
      expect(
        const HarborToastTiming(
          duration: Duration(seconds: 2),
          countsEntrance: true,
          countsWhileCovered: true,
        ).toString(),
        'HarborToastTiming(duration: 0:00:02.000000, counts entrance, counts while covered)',
      );
    });
  });

  group('timing:', () {
    testWidgets('positive control: with none, a toast leaves after 4 s in sight', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, builder: _toast);
      expect(entry.duration, const Duration(seconds: 4));
      await _wait(tester, 4);
      expect(entry.showing.value, isTrue, reason: 'its time starts after the 220 ms entrance');
      await _wait(tester, 0.5);
      expect(entry.showing.value, isFalse);
      expect(await _closed(tester, entry), HarborToastClosedReason.timeout);
    });

    testWidgets('untilHidden stays until it is hidden', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, timing: HarborToastTiming.untilHidden, builder: _toast);
      expect(entry.duration, isNull);
      await _wait(tester, 30);
      expect(entry.showing.value, isTrue);
      entry.hide();
      await _wait(tester, 1);
      expect(await _closed(tester, entry), HarborToastClosedReason.hide);
    });

    testWidgets('a duration of its own, and countsEntrance', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        timing: const HarborToastTiming(duration: Duration(seconds: 1), countsEntrance: true),
        builder: _toast,
      );
      await _wait(tester, 0.9);
      expect(entry.showing.value, isTrue, reason: 'positive control: still up just before its second');
      await _wait(tester, 0.2);
      expect(entry.showing.value, isFalse, reason: 'counted from the start of the entrance, not its end');
    });
  });

  group('the entry', () {
    testWidgets('reads back how it was placed', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        queue: HarborToastQueue.replace,
        liveRegion: false,
        animationStyle: AnimationStyle.noAnimation,
        timing: HarborToastTiming.untilHidden,
        builder: _toast,
      );
      await tester.pump();
      expect(entry.placement, isA<HarborAligned>());
      expect(entry.anchor, isNull);
      expect(entry.side, HarborAnchorSide.below, reason: 'non-null, for HarborAnchorClip(side: entry.side)');
      entry.hide();
      await _wait(tester, 1);
    });

    testWidgets('dismiss() closes it as the user dismissed it', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, timing: HarborToastTiming.untilHidden, builder: _toast);
      await _wait(tester, 0.5);
      expect(entry.phase, HarborToastPhase.shown, reason: 'positive control: it is up');
      entry.dismiss();
      expect(entry.showing.value, isFalse, reason: 'hidden at once, as hide() does');
      entry.hide();
      expect(await _closed(tester, entry), HarborToastClosedReason.dismiss, reason: 'the first reason stands');
      expect(find.text('toast'), findsNothing);
    });

    testWidgets('positive control: hide() reports hide, so dismiss is told apart', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, timing: HarborToastTiming.untilHidden, builder: _toast);
      await _wait(tester, 0.5);
      entry
        ..hide()
        ..dismiss();
      expect(await _closed(tester, entry), HarborToastClosedReason.hide);
    });

    testWidgets('dismiss() from inside the toast, as its own close button would', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        timing: HarborToastTiming.untilHidden,
        builder: (final BuildContext context) =>
            GestureDetector(onTap: () => HarborToastEntry.maybeOf(context)!.dismiss(), child: const Text('close')),
      );
      await _wait(tester, 0.5);
      await tester.tap(find.text('close'));
      expect(await _closed(tester, entry), HarborToastClosedReason.dismiss);
    });
  });
}
