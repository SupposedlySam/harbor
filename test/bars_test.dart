// `clearsBars: false` (spelled `bars: false` until 0.9.0) replaced `clear: HarborClear.coast` in 0.8.0
// (the pre-rename step of #120, Q1), and the enum went in 0.9.0. These pin where `clearsBars: false`
// places, on a page with a translucent header and tab bar and the keyboard up: the numbers the enum's
// tests measured before it went.
//
// On an iPhone 17: status bar 62, home indicator 34, 874 tall, a keyboard of 336. The body does not
// clear the keyboard, so the keyboard reaches the content and each widget decides for itself.

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

/// A 50 header and a 60 tab bar, both overlay bars, over [body], with the keyboard up.
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

/// Where a scroll view's first row rests and, scrolled to the end, where its last row rests.
Future<(double, double)> _scrollViewEnds(final WidgetTester tester, final Widget scrollView) async {
  await _pumpPage(tester, scrollView);
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
  group('HarborClear(clearsBars: false)', () {
    // Breaks if: clearsBars: false keeps clear of the bars or the keyboard, where clear: coast did not.
    testWidgets('places its child clear of the system edges alone, the keyboard left out', (final tester) async {
      await _pumpPage(tester, HarborClear(clearsBars: false, child: _content()));
      final Rect bars = _rect(tester, 'content');
      // clearsBars: false leaves the keyboard out though clearsKeyboard is true, and runs
      // to the bottom of the screen, where the home indicator's system edge is under the keyboard.
      expect(bars, const Rect.fromLTRB(0, _statusBar, 402, _screen));
    });

    // Breaks if: clearsBars: false marks handled something clear: coast did not, or stops marking handled what it did.
    testWidgets('marks the system edges and the bars handled but not the keyboard', (final tester) async {
      late BuildContext bars;
      await _pumpPage(tester, HarborClear(clearsBars: false, child: _Probe((final c) => bars = c)));
      expect(HarborRoom.of(bars).systemEdges.top, 0, reason: 'the coast is cast off');
      expect(HarborRoom.of(bars).bars.top, 0, reason: 'the docks are cast off, though not cleared');
      expect(MediaQuery.viewInsetsOf(bars).bottom, 336, reason: 'the keyboard is left to the content');
    });

    // Breaks if: clearanceOf ignores clearsBars.
    testWidgets('clearanceOf gives the system edges alone', (final tester) async {
      late EdgeInsetsDirectional bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            bars = HarborClear.clearanceOf(context, clearsBars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, const EdgeInsetsDirectional.only(top: _statusBar));
    });

    // Breaks if: the default changes.
    test('clearsBars defaults to true', () {
      expect(const HarborClear(child: SizedBox()).clearsBars, isTrue);
    });
  });

  group('HarborScrollView(clearsBars: false)', () {
    // Breaks if: clearsBars: false clears the bars, or drops the keyboard a system-edges-only scroll view keeps.
    testWidgets('rests its ends clear of the system edges alone, the keyboard kept', (final tester) async {
      final (double, double) bars = await _scrollViewEnds(
        tester,
        HarborScrollView(clearsBars: false, slivers: <Widget>[_rows()]),
      );
      // Unlike HarborClear, a scroll view's bottom end keeps clear of the keyboard while clearsKeyboard is true.
      expect(bars, (_statusBar, _keyboardTop));
    });

    // Breaks if: paddingOf ignores clearsBars.
    testWidgets('paddingOf gives the system edges alone, and the keyboard', (final tester) async {
      late EdgeInsets bars;
      await _pumpPage(
        tester,
        Builder(
          builder: (final BuildContext context) {
            bars = HarborScrollView.paddingOf(context, clearsBars: false);
            return const SizedBox.expand();
          },
        ),
      );
      expect(bars, const EdgeInsets.only(top: _statusBar, bottom: 336));
    });

    // Breaks if: the sliver ignores clearsBars.
    testWidgets('a sliver clear rests its ends clear of the system edges alone', (final tester) async {
      Future<(double, double)> ends(final Widget sliver) =>
          _scrollViewEnds(tester, CustomScrollView(slivers: <Widget>[sliver]));
      final (double, double) bars = await ends(HarborSliverClear(clearsBars: false, sliver: _rows()));
      expect(bars, (_statusBar, _keyboardTop));
    });
  });
}
