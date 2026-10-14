// `bars: false` replaces `clear: HarborClear.coast` (the pre-rename step of #120, Q1): it must place
// exactly as the enum did, on a page with a translucent header and tab bar and the keyboard up.
//
// On an iPhone 17: status bar 62, home indicator 34, 874 tall, a keyboard of 336. The body does not
// clear the tide, so the keyboard reaches the content and each widget decides for itself.

// The deprecated `clear:` is the reference these tests measure `bars:` against.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _statusBar = 62;
const double _screen = 874;
const double _keyboardTop = _screen - 336;

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Widget _rows() => SliverList.builder(
  itemCount: 30,
  itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

/// A 50 header and a 60 tab bar, both piers, over [body], with the keyboard up.
Future<HarborSeaTrial> _pumpPage(final WidgetTester tester, final Widget body) async {
  // A fresh tree each time, so one variant's scroll offset does not carry into the next.
  await tester.pumpWidget(const SizedBox());
  final HarborSeaTrial trial = await tester.pumpSeaTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Material(
        child: Harbor(
          bodyClearsTide: false,
          top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
          bottom: <HarborDock>[HarborDock.pier(child: _bar('tabs', 60))],
          body: body,
        ),
      ),
    ),
  );
  await trial.raiseTide(settle: true);
  expect(trial.waterline, _keyboardTop, reason: 'positive control: the keyboard is up');
  expect(_rect(tester, 'header').bottom, _statusBar + 50, reason: 'positive control: the header is there');
  return trial;
}

/// Where a fairway's first row rests and, scrolled to the end, where its last row rests.
Future<(double, double)> _fairwayEnds(final WidgetTester tester, final Widget fairway) async {
  await _pumpPage(tester, fairway);
  final double first = _rect(tester, 'row0').top;
  await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
  await tester.pumpAndSettle();
  return (first, _rect(tester, 'row29').bottom);
}

Widget _content() => const SizedBox.expand(key: ValueKey<String>('content'));

/// Captures the [BuildContext] it is built in.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(final BuildContext context) {
    onBuild(context);
    return const SizedBox.shrink();
  }
}

void main() {
  group('HarborMoored(bars: false)', () {
    // Breaks if: bars: false keeps clear of the docks or the keyboard, where clear: coast did not.
    testWidgets('places its child exactly as clear: HarborClear.coast did, the keyboard left out', (final tester) async {
      await _pumpPage(tester, HarborMoored(clear: HarborClear.coast, child: _content()));
      final Rect coast = _rect(tester, 'content');
      await _pumpPage(tester, HarborMoored(bars: false, child: _content()));
      final Rect bars = _rect(tester, 'content');
      expect(bars, coast);
      // clear: coast left the keyboard out though tide is true: bars: false does the same, and runs
      // to the bottom of the screen, where the home indicator's coast is under the keyboard.
      expect(bars, const Rect.fromLTRB(0, _statusBar, 402, _screen));
    });

    // Breaks if: bars: false casts off something clear: coast did not, or stops casting off what it did.
    testWidgets('casts off the coast and the docks but not the keyboard, as clear: coast did', (final tester) async {
      late BuildContext coast;
      late BuildContext bars;
      await _pumpPage(tester, HarborMoored(clear: HarborClear.coast, child: _Probe((final c) => coast = c)));
      final HarborWatersData coastWaters = HarborWaters.of(coast);
      final EdgeInsets coastInsets = MediaQuery.viewInsetsOf(coast);
      await _pumpPage(tester, HarborMoored(bars: false, child: _Probe((final c) => bars = c)));
      expect(HarborWaters.of(bars).docks, coastWaters.docks);
      expect(HarborWaters.of(bars).coast, coastWaters.coast);
      expect(MediaQuery.viewInsetsOf(bars), coastInsets);
      expect(HarborWaters.of(bars).coast.top, 0, reason: 'the coast is cast off');
      expect(HarborWaters.of(bars).docks.top, 0, reason: 'the docks are cast off, though not cleared');
      expect(MediaQuery.viewInsetsOf(bars).bottom, 336, reason: 'the keyboard is left to the content');
    });

    // Breaks if: clearanceOf ignores bars.
    testWidgets('clearanceOf gives what clear: coast gave', (final tester) async {
      late EdgeInsetsDirectional coast;
      late EdgeInsetsDirectional bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            coast = HarborMoored.clearanceOf(context, clear: HarborClear.coast);
            bars = HarborMoored.clearanceOf(context, bars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, coast);
      expect(bars, const EdgeInsetsDirectional.only(top: _statusBar));
    });

    // Breaks if: clear: stops forwarding, or the default changes.
    test('clear: still forwards, and reads back', () {
      expect(const HarborMoored(child: SizedBox()).bars, isTrue);
      expect(const HarborMoored(clear: HarborClear.coast, child: SizedBox()).bars, isFalse);
      expect(const HarborMoored(clear: HarborClear.everything, child: SizedBox()).bars, isTrue);
      expect(const HarborMoored(bars: false, child: SizedBox()).clear, HarborClear.coast);
      expect(const HarborMoored(child: SizedBox()).clear, HarborClear.everything);
    });

    // Breaks if: a call that says both, in conflict, is quietly resolved one way.
    test('asserts when clear: everything and bars: false are both given', () {
      final HarborClear everything = HarborClear.values.byName('everything');
      expect(() => HarborMoored(clear: everything, bars: false, child: const SizedBox()), throwsAssertionError);
    });
  });

  group('HarborFairway(bars: false)', () {
    // Breaks if: bars: false clears the docks, or drops the keyboard a coast-only fairway keeps.
    testWidgets('rests its ends exactly as clear: HarborClear.coast did, the keyboard kept', (final tester) async {
      final (double, double) coast = await _fairwayEnds(
        tester,
        HarborFairway(clear: HarborClear.coast, slivers: <Widget>[_rows()]),
      );
      final (double, double) bars = await _fairwayEnds(tester, HarborFairway(bars: false, slivers: <Widget>[_rows()]));
      expect(bars, coast);
      // Unlike HarborMoored, a fairway's bottom end keeps clear of the keyboard while tide is true.
      expect(bars, (_statusBar, _keyboardTop));
    });

    // Breaks if: paddingOf ignores bars.
    testWidgets('paddingOf gives what clear: coast gave', (final tester) async {
      late EdgeInsets coast;
      late EdgeInsets bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            coast = HarborFairway.paddingOf(context, clear: HarborClear.coast);
            bars = HarborFairway.paddingOf(context, bars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, coast);
      expect(bars, const EdgeInsets.only(top: _statusBar, bottom: 336));
    });

    // Breaks if: the sliver ignores bars.
    testWidgets('a fairway sliver rests its ends as clear: coast did', (final tester) async {
      Future<(double, double)> ends(final Widget sliver) =>
          _fairwayEnds(tester, CustomScrollView(slivers: <Widget>[sliver]));
      final (double, double) coast = await ends(HarborFairwaySliver(clear: HarborClear.coast, sliver: _rows()));
      final (double, double) bars = await ends(HarborFairwaySliver(bars: false, sliver: _rows()));
      expect(bars, coast);
      expect(bars, (_statusBar, _keyboardTop));
    });

    // Breaks if: clear: stops forwarding, or a conflict is quietly resolved one way.
    test('clear: still forwards, and a conflict asserts', () {
      expect(const HarborFairway(clear: HarborClear.coast, slivers: <Widget>[]).bars, isFalse);
      expect(const HarborFairway(bars: false, slivers: <Widget>[]).clear, HarborClear.coast);
      expect(HarborFairway.box(clear: HarborClear.coast, child: const SizedBox()).bars, isFalse);
      expect(const HarborFairwaySliver(clear: HarborClear.coast, sliver: SliverToBoxAdapter()).bars, isFalse);
      final HarborClear everything = HarborClear.values.byName('everything');
      expect(() => HarborFairway(clear: everything, bars: false, slivers: const <Widget>[]), throwsAssertionError);
      expect(
        () => HarborFairwaySliver(clear: everything, bars: false, sliver: const SliverToBoxAdapter()),
        throwsAssertionError,
      );
    });
  });
}
