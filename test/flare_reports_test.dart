// Flares as reported in #83 to #86, and HarborMakeWay's frame as reported in #82: each test
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
  group('#85 a flare lowered before it is built', () {
    testWidgets('leaves the overlay, says why, and lets the next flare at its slot in', (final tester) async {
      late BuildContext page;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (final c) => SizedBox.expand(child: Builder(builder: (final c) {
        page = c;
        return const SizedBox.expand();
      })))));
      final HarborFlareEntry first = HarborFlares.raise(page, slot: HarborFlareSlot.low, builder: (final c) => const Text('first'));
      first.lower(reason: HarborFlareClosedReason.dismiss);
      HarborFlareClosedReason? why;
      unawaited(first.closed.then((final r) => why = r));
      await tester.pump();
      expect(find.text('first'), findsNothing, reason: 'never built');
      HarborFlares.raise(page, slot: HarborFlareSlot.low, builder: (final c) => const Text('second'), duration: null);
      await _step(tester);
      expect(find.text('second'), findsOneWidget);
      expect(why, HarborFlareClosedReason.dismiss);
    });

    testWidgets('positive control: lowered after it is built, it runs its exit and then lets the next in', (final tester) async {
      late BuildContext page;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (final c) {
        page = c;
        return const SizedBox.expand();
      })));
      final HarborFlareEntry first = HarborFlares.raise(page, slot: HarborFlareSlot.low, builder: (final c) => const Text('first'), duration: null);
      HarborFlares.raise(page, slot: HarborFlareSlot.low, builder: (final c) => const Text('second'), duration: null);
      await _step(tester);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing, reason: 'waiting its turn');
      first.lower();
      await tester.pump();
      expect(find.text('first'), findsOneWidget, reason: 'running its exit');
      await _step(tester);
      expect(find.text('first'), findsNothing);
      expect(find.text('second'), findsOneWidget);
    });
  });

  group('#86 with no HarborSea', () {
    Future<BuildContext> pumpBand(final WidgetTester tester, {required final bool sea}) async {
      late BuildContext inner;
      await tester.pumpSeaTrial(MaterialApp(
        builder: sea ? (final c, final child) => HarborSea(child: child!) : null,
        home: Harbor(
          top: <HarborDock>[
            HarborDock.pier(
              child: SizedBox(
                key: const ValueKey<String>('band'),
                height: 100,
                child: Harbor(body: Builder(builder: (final c) {
                  inner = c;
                  return const SizedBox.expand();
                })),
              ),
            ),
          ],
          body: const SizedBox.expand(),
        ),
      ));
      return inner;
    }

    Widget flare(final BuildContext _) => const SizedBox(key: ValueKey<String>('flare'), height: 20, width: 100);

    for (final bool sea in <bool>[false, true]) {
      testWidgets('a flare raised from a header band\'s own harbor goes to the page, not the band (sea: $sea)', (final tester) async {
        final BuildContext inner = await pumpBand(tester, sea: sea);
        HarborFlares.raise(inner, slot: HarborFlareSlot.low, builder: flare, duration: null);
        await _step(tester);
        // iPhone 17: 874 high, a 34 home indicator, a flare 16 in from the clear water.
        expect(_rect(tester, 'flare').bottom, 874 - 34 - 16);
        expect(_rect(tester, 'flare').top, greaterThan(_rect(tester, 'band').bottom));
      });
    }
  });

  group('#83 a flare\'s margin', () {
    Future<BuildContext> pumpPage(final WidgetTester tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(MaterialApp(
        builder: (final c, final child) => HarborSea(child: child!),
        home: Harbor(
          bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', 56))],
          body: Builder(builder: (final c) {
            page = c;
            return const SizedBox.expand();
          }),
        ),
      ));
      return page;
    }

    testWidgets('is 16 by default', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      HarborFlares.raise(page, slot: HarborFlareSlot.low, builder: (final c) => _bar('toast', 40), duration: null);
      await _step(tester);
      expect(_rect(tester, 'toast'), const Rect.fromLTRB(16, 874 - 34 - 56 - 16 - 40, 402 - 16, 874 - 34 - 56 - 16));
    });

    testWidgets('zero reaches the clear water\'s edges, still above the docks', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      HarborFlares.raise(page, slot: HarborFlareSlot.low, margin: EdgeInsets.zero, builder: (final c) => _bar('toast', 40), duration: null);
      await _step(tester);
      expect(_rect(tester, 'toast'), Rect.fromLTRB(0, 874 - 34 - 56 - 40, 402, _rect(tester, 'nav').top));
    });

    testWidgets('is read in the reading direction, and in an overlay too', (final tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (final c) {
            page = c;
            return const SizedBox.expand();
          }),
        ),
      ));
      HarborFlares.raise(
        page,
        slot: HarborFlareSlot.low,
        margin: const EdgeInsetsDirectional.only(start: 40, bottom: 4),
        builder: (final c) => _bar('toast', 40),
        duration: null,
      );
      await _step(tester);
      // No harbor: the overlay keeps it off the home indicator, then the margin.
      expect(_rect(tester, 'toast'), const Rect.fromLTRB(0, 874 - 34 - 4 - 40, 402 - 40, 874 - 34 - 4));
    });
  });

  group('#84 holding a flare', () {
    Future<HarborFlareEntry> raise(final WidgetTester tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(MaterialApp(
        builder: (final c, final child) => HarborSea(child: child!),
        home: Builder(builder: (final c) {
          page = c;
          return const SizedBox.expand();
        }),
      ));
      final HarborFlareEntry entry = HarborFlares.raise(page, builder: (final c) => const Text('toast'), duration: const Duration(seconds: 1));
      // The entrance, 220 ms: time counts from its end.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return entry;
    }

    testWidgets('stops its time until released, then counts it from the start', (final tester) async {
      final HarborFlareEntry entry = await raise(tester);
      final HarborFlareHold hold = entry.hold();
      expect(entry.held.value, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(entry.showing.value, isTrue, reason: 'held past its second');
      expect(hold.release(), isNull);
      await tester.pump(const Duration(milliseconds: 900));
      expect(entry.showing.value, isTrue, reason: 'its second starts over at the release');
      await tester.pump(const Duration(milliseconds: 200));
      expect(entry.showing.value, isFalse);
      HarborFlareClosedReason? why;
      unawaited(entry.closed.then((final r) => why = r));
      await tester.pump(const Duration(milliseconds: 400));
      expect(why, HarborFlareClosedReason.timeout);
    });

    testWidgets('holds are counted, and a second release of one hold does nothing', (final tester) async {
      final HarborFlareEntry entry = await raise(tester);
      final HarborFlareHold a = entry.hold();
      final HarborFlareHold b = entry.hold();
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
      final HarborFlareEntry entry = await raise(tester);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(entry.showing.value, isFalse);
    });

    testWidgets('a held flare can still be lowered', (final tester) async {
      final HarborFlareEntry entry = await raise(tester);
      entry.hold();
      entry.lower();
      expect(entry.showing.value, isFalse);
    });
  });

  group('#82 HarborMakeWay\'s frame', () {
    Widget page(final Widget body) => MaterialApp(
      builder: (final c, final child) => HarborSea(child: child!),
      home: Harbor(bottom: <HarborDock>[HarborDock.quay(duration: Duration.zero, child: _bar('nav', 56))], body: body),
    );
    const Widget moored = HarborMoored(child: SizedBox.expand(key: ValueKey<String>('body')));

    testWidgets('a claim taken in a build reaches the harbor on the next frame, as documented', (final tester) async {
      final ValueNotifier<bool> claim = ValueNotifier<bool>(false);
      await tester.pumpSeaTrial(page(ValueListenableBuilder<bool>(
        valueListenable: claim,
        builder: (final c, final active, final _) => HarborMakeWay(edge: HarborEdge.bottom, active: active, child: moored),
      )));
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56);
      claim.value = true;
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56, reason: 'the harbor was built before the claim');
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34);
    });

    testWidgets('a claim taken in a tap lands in the next frame drawn', (final tester) async {
      late BuildContext body;
      await tester.pumpSeaTrial(page(Builder(builder: (final c) {
        body = c;
        return moored;
      })));
      final HarborClaim claim = Harbor.of(body).makeWay(HarborEdge.bottom);
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34);
      claim.release();
      await tester.pump();
      expect(_rect(tester, 'body').bottom, 874 - 34 - 56);
    });
  });
}
