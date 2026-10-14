// `bars: false` replaced `clear: HarborClear.coast` in 0.8.0 (the pre-rename step of #120, Q1), and the
// enum went in 0.9.0. These pin where `bars: false` places, on a page with a translucent header and tab
// bar and the keyboard up: the numbers the enum's tests measured before it went.
//
// On an iPhone 17: status bar 62, home indicator 34, 874 tall, a keyboard of 336. The body does not
// clear the tide, so the keyboard reaches the content and each widget decides for itself.

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
Future<HarborTrial> _pumpPage(final WidgetTester tester, final Widget body) async {
  // A fresh tree each time, so one variant's scroll offset does not carry into the next.
  await tester.pumpWidget(const SizedBox());
  final HarborTrial trial = await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: Material(
        child: HarborFrame(
          bodyClearsKeyboard: false,
          top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
          bottom: <HarborBar>[HarborBar.overlay(child: _bar('tabs', 60))],
          body: body,
        ),
      ),
    ),
  );
  await trial.showKeyboard(settle: true);
  expect(trial.keyboardTop, _keyboardTop, reason: 'positive control: the keyboard is up');
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
    testWidgets('places its child clear of the coast alone, the keyboard left out', (final tester) async {
      await _pumpPage(tester, HarborClear(bars: false, child: _content()));
      final Rect bars = _rect(tester, 'content');
      // bars: false leaves the keyboard out though tide is true, and runs
      // to the bottom of the screen, where the home indicator's coast is under the keyboard.
      expect(bars, const Rect.fromLTRB(0, _statusBar, 402, _screen));
    });

    // Breaks if: bars: false casts off something clear: coast did not, or stops casting off what it did.
    testWidgets('casts off the coast and the docks but not the keyboard', (final tester) async {
      late BuildContext bars;
      await _pumpPage(tester, HarborClear(bars: false, child: _Probe((final c) => bars = c)));
      expect(HarborRoom.of(bars).systemEdges.top, 0, reason: 'the coast is cast off');
      expect(HarborRoom.of(bars).bars.top, 0, reason: 'the docks are cast off, though not cleared');
      expect(MediaQuery.viewInsetsOf(bars).bottom, 336, reason: 'the keyboard is left to the content');
    });

    // Breaks if: clearanceOf ignores bars.
    testWidgets('clearanceOf gives the coast alone', (final tester) async {
      late EdgeInsetsDirectional bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            bars = HarborClear.clearanceOf(context, bars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, const EdgeInsetsDirectional.only(top: _statusBar));
    });

    // Breaks if: the default changes.
    test('bars defaults to true', () {
      expect(const HarborClear(child: SizedBox()).bars, isTrue);
    });
  });

  group('HarborFairway(bars: false)', () {
    // Breaks if: bars: false clears the docks, or drops the keyboard a coast-only fairway keeps.
    testWidgets('rests its ends clear of the coast alone, the keyboard kept', (final tester) async {
      final (double, double) bars = await _fairwayEnds(
        tester,
        HarborScrollView(bars: false, slivers: <Widget>[_rows()]),
      );
      // Unlike HarborMoored, a fairway's bottom end keeps clear of the keyboard while tide is true.
      expect(bars, (_statusBar, _keyboardTop));
    });

    // Breaks if: paddingOf ignores bars.
    testWidgets('paddingOf gives the coast alone, and the keyboard', (final tester) async {
      late EdgeInsets bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            bars = HarborScrollView.paddingOf(context, bars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, const EdgeInsets.only(top: _statusBar, bottom: 336));
    });

    // Breaks if: the sliver ignores bars.
    testWidgets('a fairway sliver rests its ends clear of the coast alone', (final tester) async {
      Future<(double, double)> ends(final Widget sliver) =>
          _fairwayEnds(tester, CustomScrollView(slivers: <Widget>[sliver]));
      final (double, double) bars = await ends(HarborSliverClear(bars: false, sliver: _rows()));
      expect(bars, (_statusBar, _keyboardTop));
    });
  });
}
