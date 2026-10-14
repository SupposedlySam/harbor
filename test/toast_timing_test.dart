// HarborToastTiming: one value for how long a toast stays (doc/design/flares.md, DECISIONS Q11-Q14),
// the deprecated duration:, persist:, countsEntrance: and countsWhileCovered: forwarding to it, and
// the slim HarborToastEntry a caller holds.

// The deprecated spellings are what part of this file checks.
// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/foundation.dart';
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
      await _wait(tester, 1.1);
      expect(entry.showing.value, isFalse, reason: 'counted from the start of the entrance');
    });

    testWidgets('given with a deprecated spelling, it asserts', (final tester) async {
      final BuildContext page = await _page(tester);
      for (final VoidCallback show in <VoidCallback>[
        () => HarborToasts.show(page, timing: HarborToastTiming.untilHidden, duration: null, builder: _toast),
        () => HarborToasts.show(page, timing: HarborToastTiming.untilHidden, persist: false, builder: _toast),
        () => HarborToasts.show(page, timing: HarborToastTiming.untilHidden, countsEntrance: false, builder: _toast),
        () =>
            HarborToasts.show(page, timing: HarborToastTiming.untilHidden, countsWhileCovered: false, builder: _toast),
      ]) {
        expect(show, throwsAssertionError);
      }
    });
  });

  group('the deprecated spellings forward to it', () {
    testWidgets('duration: null stays, and duration: d is d', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry stays = HarborToasts.show(page, duration: null, builder: _toast);
      final HarborToastEntry two = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        duration: const Duration(seconds: 2),
        builder: _toast,
      );
      expect(stays.duration, isNull);
      expect(two.duration, const Duration(seconds: 2));
      await _wait(tester, 2.5);
      expect(two.showing.value, isFalse);
      expect(stays.showing.value, isTrue);
      stays.hide();
      await _wait(tester, 1);
    });

    testWidgets('persist: true is a null duration, whatever duration: says', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        persist: true,
        duration: const Duration(seconds: 1),
        builder: _toast,
      );
      expect(entry.duration, isNull);
      expect(entry.persist, isTrue);
      await _wait(tester, 10);
      expect(entry.showing.value, isTrue);
      // The behaviour change: persist was a flag beside the duration, so setting a duration on a
      // persisting toast started no time. It is the duration now, so it does.
      entry.duration = const Duration(seconds: 1);
      expect(entry.persist, isFalse);
      await _wait(tester, 1.1);
      expect(entry.showing.value, isFalse);
    });

    testWidgets('persist: false is the default', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, persist: false, builder: _toast);
      expect(entry.duration, const Duration(seconds: 4));
      await _wait(tester, 4.5);
      expect(entry.showing.value, isFalse);
    });

    testWidgets('countsEntrance: and countsWhileCovered: land on the value', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        countsEntrance: true,
        countsWhileCovered: true,
        duration: const Duration(seconds: 1),
        builder: _toast,
      );
      expect(entry.countsEntrance, isTrue);
      expect(entry.countsWhileCovered, isTrue);
      await _wait(tester, 1.1);
      expect(entry.showing.value, isFalse);
    });

    testWidgets('raise, the 0.8 name, forwards them too', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.raise(page, persist: true, builder: _toast);
      expect(entry.duration, isNull);
      final HarborToastEntry timed = HarborToasts.raise(
        page,
        slot: HarborToastSlot.low,
        timing: const HarborToastTiming(duration: Duration(seconds: 1)),
        builder: _toast,
      );
      expect(timed.duration, const Duration(seconds: 1));
      entry.hide();
      await _wait(tester, 2);
    });
  });

  group('the entry', () {
    testWidgets('reads back how it was shown through its deprecated getters', (final tester) async {
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
      expect(entry.queue, HarborToastQueue.replace);
      expect(entry.liveRegion, isFalse);
      expect(entry.transitionDuration, Duration.zero);
      expect(entry.owner, same(HarborFrame.of(page)));
      expect(entry.shownFrom, same(HarborFrame.of(page)));
      expect(entry.timing, isA<ValueListenable<int>>());
      expect(entry.reachesSystemEdges, isFalse);
      expect(entry.placement, isA<HarborAligned>());
      expect(entry.anchor, isNull);
      expect(entry.side, HarborAnchorSide.below, reason: 'non-null, for HarborAnchorClip(side: entry.side)');
      entry.hide();
      await _wait(tester, 1);
    });

    testWidgets('hide(reason:), deprecated, still reports the first reason given', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborToastEntry entry = HarborToasts.show(page, builder: _toast);
      entry
        ..hide(reason: HarborToastClosedReason.dismiss)
        ..hide();
      await _wait(tester, 1);
      expect(await _closed(tester, entry), HarborToastClosedReason.dismiss);
    });
  });
}
