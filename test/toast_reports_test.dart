// Toasts as reported in #83 to #86, and HarborMakeWay's frame as reported in #82: each test
// measures what the report asked for, and fails on the code the report was written against.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<void> _step(final WidgetTester tester, [final int times = 5]) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('#85 a toast hidden before it is built', () {
    testWidgets('leaves the overlay, says why, and lets the next toast at its slot in', (final tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final c) => SizedBox.expand(
              child: Builder(
                builder: (final c) {
                  page = c;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      final HarborToastEntry first = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final c) => const Text('first'),
      );
      first.dismiss();
      HarborToastClosedReason? why;
      unawaited(first.closed.then((final r) => why = r));
      await tester.pump();
      expect(find.text('first'), findsNothing, reason: 'never built');
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final c) => const Text('second'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('second'), findsOneWidget);
      expect(why, HarborToastClosedReason.dismiss);
    });

    testWidgets('positive control: hidden after it is built, it runs its exit and then lets the next in', (
      final tester,
    ) async {
      late BuildContext page;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (final c) {
              page = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final HarborToastEntry first = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final c) => const Text('first'),
        timing: HarborToastTiming.untilHidden,
      );
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final c) => const Text('second'),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing, reason: 'waiting its turn');
      first.hide();
      await tester.pump();
      expect(find.text('first'), findsOneWidget, reason: 'running its exit');
      await _step(tester);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });
  });

  group('#86 with no HarborSea', () {
    Future<BuildContext> pumpBand(final WidgetTester tester, {required final bool root}) async {
      late BuildContext inner;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: root ? (final c, final child) => HarborRoot(child: child!) : null,
          home: HarborFrame(
            top: <HarborBar>[
              HarborBar.overlay(
                child: SizedBox(
                  key: const ValueKey<String>('band'),
                  height: 100,
                  child: HarborFrame(
                    body: Builder(
                      builder: (final c) {
                        inner = c;
                        return const SizedBox.expand();
                      },
                    ),
                  ),
                ),
              ),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      );
      return inner;
    }

    Widget toast(final BuildContext _) => const SizedBox(key: ValueKey<String>('flare'), height: 20, width: 100);

    for (final bool root in <bool>[false, true]) {
      testWidgets('a toast shown from a header band\'s own frame goes to the page, not the band (root: $root)', (
        final tester,
      ) async {
        final BuildContext inner = await pumpBand(tester, root: root);
        HarborToasts.show(inner, slot: HarborToastSlot.low, builder: toast, timing: HarborToastTiming.untilHidden);
        await _step(tester);
        // iPhone 17: 874 high, a 34 home indicator, a toast 16 in from the room.
        expect(_rect(tester, 'flare').bottom, 874 - 34 - 16);
        expect(_rect(tester, 'flare').top, greaterThan(_rect(tester, 'band').bottom));
      });
    }
  });

  testWidgets('#86 an anchored toast shown from a header band\'s own frame, with no root, hangs below the band', (
    final tester,
  ) async {
    final HarborAnchor anchor = HarborAnchor(debugLabel: 'menu');
    late BuildContext inner;
    await tester.pumpHarborTrial(
      MaterialApp(
        home: HarborFrame(
          top: <HarborBar>[
            HarborBar.overlay(
              child: SizedBox(
                key: const ValueKey<String>('band'),
                height: 100,
                child: HarborFrame(
                  body: Builder(
                    builder: (final c) {
                      inner = c;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: HarborAnchorPoint(
                          anchor: anchor,
                          child: const SizedBox(key: ValueKey<String>('menu'), width: 80, height: 30),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
          body: const SizedBox.expand(),
        ),
      ),
    );
    HarborToasts.show(
      inner,
      placement: HarborAnchored(anchor),
      builder: (final c) => const SizedBox(key: ValueKey<String>('flare'), height: 40, width: 120),
      timing: HarborToastTiming.untilHidden,
    );
    await _step(tester);
    // Shown by the page, it hangs 8 below the button, out over the page. Shown by the band's own
    // frame, it was kept inside the band's 100 and could not.
    expect(_rect(tester, 'flare').top, _rect(tester, 'menu').bottom + 8);
    expect(_rect(tester, 'flare').bottom, greaterThan(_rect(tester, 'band').bottom));
  });

  group('#83 a toast\'s margin', () {
    Future<BuildContext> pumpPage(final WidgetTester tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final c, final child) => HarborRoot(child: child!),
          home: HarborFrame(
            bottom: <HarborBar>[HarborBar.solid(child: _bar('nav', 56))],
            body: Builder(
              builder: (final c) {
                page = c;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      return page;
    }

    testWidgets('is 16 by default', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final c) => _bar('toast', 40),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'toast'), const Rect.fromLTRB(16, 874 - 34 - 56 - 16 - 40, 402 - 16, 874 - 34 - 56 - 16));
    });

    testWidgets('zero reaches the room\'s edges, still above the bars', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      HarborToasts.show(
        page,
        placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
        builder: (final c) => _bar('toast', 40),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      expect(_rect(tester, 'toast'), Rect.fromLTRB(0, 874 - 34 - 56 - 40, 402, _rect(tester, 'nav').top));
    });

    testWidgets('is read in the reading direction, and in an overlay too', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (final c) {
                page = c;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      HarborToasts.show(
        page,
        placement: HarborAligned(
          alignment: HarborToastSlot.low.alignment,
          margin: const EdgeInsetsDirectional.only(start: 40, bottom: 4),
        ),
        builder: (final c) => _bar('toast', 40),
        timing: HarborToastTiming.untilHidden,
      );
      await _step(tester);
      // No frame: the overlay keeps it off the home indicator, then the margin.
      expect(_rect(tester, 'toast'), const Rect.fromLTRB(0, 874 - 34 - 4 - 40, 402 - 40, 874 - 34 - 4));
    });
  });

  group('#84 holding a toast', () {
    Future<HarborToastEntry> show(final WidgetTester tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final c, final child) => HarborRoot(child: child!),
          home: Builder(
            builder: (final c) {
              page = c;
              return const SizedBox.expand();
            },
          ),
        ),
      );
      final HarborToastEntry entry = HarborToasts.show(
        page,
        builder: (final c) => const Text('toast'),
        timing: const HarborToastTiming(duration: Duration(seconds: 1)),
      );
      // The entrance, 220 ms: time counts from its end.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return entry;
    }

    testWidgets('stops its time until released, then counts it from the start', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      final HarborToastHold hold = entry.hold();
      expect(entry.held.value, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(entry.showing.value, isTrue, reason: 'held past its second');
      expect(hold.release(), isNull);
      await tester.pump(const Duration(milliseconds: 900));
      expect(entry.showing.value, isTrue, reason: 'its second starts over at the release');
      await tester.pump(const Duration(milliseconds: 200));
      expect(entry.showing.value, isFalse);
      HarborToastClosedReason? why;
      unawaited(entry.closed.then((final r) => why = r));
      await tester.pump(const Duration(milliseconds: 400));
      expect(why, HarborToastClosedReason.timeout);
    });

    testWidgets('holds are counted, and a second release of one hold does nothing', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      final HarborToastHold a = entry.hold();
      final HarborToastHold b = entry.hold();
      a.release();
      a.release();
      await tester.pump(const Duration(seconds: 2));
      expect(entry.showing.value, isTrue, reason: 'b still holds it');
      b.release();
      expect(entry.held.value, isFalse);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(entry.showing.value, isFalse);
    });

    testWidgets('positive control: unheld, it times out after its second', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(entry.showing.value, isFalse);
    });

    testWidgets('a held toast can still be hidden', (final tester) async {
      final HarborToastEntry entry = await show(tester);
      entry.hold();
      entry.hide();
      expect(entry.showing.value, isFalse);
    });
  });

  group('#82 HarborMakeWay\'s frame', () {
    Widget page(final Widget body) => MaterialApp(
      builder: (final c, final child) => HarborRoot(child: child!),
      home: HarborFrame(
        bottom: <HarborBar>[
          HarborBar.solid(
            animationStyle: const AnimationStyle(duration: Duration.zero),
            child: _bar('nav', 56),
          ),
        ],
        body: body,
      ),
    );
    const Widget clear = HarborClear(child: SizedBox.expand(key: ValueKey<String>('body')));

    testWidgets('a claim taken in a build reaches the frame on the next frame, as documented', (final tester) async {
      final ValueNotifier<bool> claim = ValueNotifier<bool>(false);
      await tester.pumpHarborTrial(
        page(
          ValueListenableBuilder<bool>(
            valueListenable: claim,
            builder: (final c, final active, final _) =>
                HarborHideBar(edge: HarborEdge.bottom, active: active, child: clear),
          ),
        ),
      );
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56);
      claim.value = true;
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56, reason: 'the harbor was built before the claim');
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34);
    });

    testWidgets('a claim taken in a tap lands in the next frame drawn', (final tester) async {
      late BuildContext body;
      await tester.pumpHarborTrial(
        page(
          Builder(
            builder: (final c) {
              body = c;
              return clear;
            },
          ),
        ),
      );
      final HarborClaim claim = HarborFrame.of(body).hideBar(HarborEdge.bottom);
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34);
      claim.release();
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56);
    });
  });
}
