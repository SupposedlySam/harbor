import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/boats.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_content.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/stage.dart';

const Duration _step = Duration(milliseconds: 500);

/// Shows the whole phone on pages that crop to part of it, so measurements are
/// taken against the whole device.
Future<void> _wholePhone(final WidgetTester tester) async {
  final Finder toggle = find.byKey(const ValueKey<String>('focus toggle'));
  if (toggle.evaluate().isNotEmpty) {
    await tester.tap(toggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _pumpEntry(final WidgetTester tester, final Widget entry) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: Palette.theme(),
      builder: (final BuildContext context, final Widget? child) =>
          HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
      home: entry,
    ),
  );
  await tester.pump();
  await _wholePhone(tester);
  await tester.pump();
  await tester.pump(_step);
  expect(tester.takeException(), isNull);
}

Finder _key(final String key) => find.byKey(ValueKey<String>(key));

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(_key(key).first);

/// How far the stage's screen is scaled down on the page.
double _scale(final WidgetTester tester, {final double deviceWidth = 402}) =>
    (tester.getRect(_key('stage')).width - 20) / deviceWidth;

/// The top of the stage's screen, inside its bezel.
double _frameTop(final WidgetTester tester) => tester.getRect(_key('stage')).top + 10;
double _frameBottom(final WidgetTester tester) => tester.getRect(_key('stage')).bottom - 10;

Future<void> _tap(final WidgetTester tester, final String key) async {
  final Finder finder = _key(key);
  // The stage's own settings start folded away.
  if (finder.evaluate().isEmpty && _key('stage settings').evaluate().isNotEmpty) {
    await tester.ensureVisible(_key('stage settings'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(_key('stage settings'));
    await tester.pump(_step);
  }
  expect(finder, findsOneWidget, reason: key);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(_step);
  expect(tester.takeException(), isNull, reason: key);
}

/// Scrolls the page (not the stage) so [key] sits mid-screen.
Future<void> _centerOnPage(final WidgetTester tester, final String key) async {
  final Finder scroller = find.ancestor(of: _key('stage'), matching: find.byType(Scrollable));
  if (scroller.evaluate().isEmpty) {
    // The page doesn't scroll: the stage is always in sight.
    return;
  }
  final ScrollPosition page = tester.state<ScrollableState>(scroller.first).position;
  page.jumpTo(
    (page.pixels + tester.getCenter(_key(key).first).dy - 437).clamp(page.minScrollExtent, page.maxScrollExtent),
  );
  await tester.pump();
}

/// Taps something on the stage, with the page scrolled so it's in view.
Future<void> _tapStage(final WidgetTester tester, final String key) async {
  await _centerOnPage(tester, key);
  await tester.tap(_key(key));
  await tester.pump();
  await tester.pump(_step);
  expect(tester.takeException(), isNull, reason: key);
}

Future<void> _setTide(final WidgetTester tester, {required final bool high}) async {
  final Finder toggle = _key('tide toggle');
  final IconButton button = tester.widget<IconButton>(toggle);
  final bool isHigh = button.tooltip == 'Lower the tide';
  if (isHigh != high) {
    await _tap(tester, 'tide toggle');
  }
}

ScrollPosition _stageScroll(final WidgetTester tester, final String key) =>
    tester.state<ScrollableState>(find.descendant(of: _key(key), matching: find.byType(Scrollable)).first).position;

Future<void> _scrollStage(final WidgetTester tester, final String key, final double to) async {
  final ScrollPosition position = _stageScroll(tester, key);
  position.jumpTo(to.clamp(position.minScrollExtent, position.maxScrollExtent));
  await tester.pump();
  await tester.pump(_step);
}

Widget _page(final String id) => Builder(
  builder: (final BuildContext context) => contentEntries.firstWhere((final GuideEntry e) => e.id == id).page(context),
);

Matcher _near(final double value) => moreOrLessEquals(value, epsilon: 0.6);

double _frameLeft(final WidgetTester tester) => tester.getRect(_key('stage')).left + 10;
double _frameRight(final WidgetTester tester) => tester.getRect(_key('stage')).right - 10;
double _keyboardTop(final WidgetTester tester) => tester.getRect(find.byType(KeyboardArt)).top;

/// Sets a slider the way dragging it would, then lets the stage follow.
Future<void> _slide(final WidgetTester tester, final String label, final double value) async {
  final Finder slider = _key('slider $label');
  await tester.ensureVisible(slider);
  await tester.pump(const Duration(milliseconds: 300));
  tester.widget<Slider>(slider).onChanged!(value);
  await tester.pump();
  await tester.pump(_step);
  expect(tester.takeException(), isNull, reason: label);
}

/// The code card's text, as the controls have it now.
String _code(final WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _key('code card'), matching: find.byType(Text))).data!;

Matcher _rectNear(final Rect rect) => predicate<Rect>(
  (final Rect r) =>
      (r.left - rect.left).abs() < 0.6 &&
      (r.top - rect.top).abs() < 0.6 &&
      (r.right - rect.right).abs() < 0.6 &&
      (r.bottom - rect.bottom).abs() < 0.6,
  'within 0.6 of $rect',
);

/// How opaque the dock holding [key] is drawn.
double _opacityOf(final WidgetTester tester, final String key) =>
    tester.widget<Opacity>(find.ancestor(of: _key(key), matching: find.byType(Opacity)).first).opacity;

void main() {
  test('both groups are listed, named as in code', () {
    expect(
      contentEntries
          .where((final GuideEntry e) => e.group == GuideGroup.content)
          .map((final GuideEntry e) => e.className),
      <String>[
        'HarborMoored',
        'HarborMooringLine',
        'HarborFairway',
        'HarborFairwaySliver',
        'HarborSliverDock',
        'HarborSticky',
        'HarborCenter',
        'HarborOpenWater',
        'HarborCastOff',
      ],
    );
    expect(
      contentEntries.where((final GuideEntry e) => e.group == GuideGroup.talk).map((final GuideEntry e) => e.className),
      <String>['HarborMakeWay', 'HarborPontoon'],
    );
  });

  testWidgets('every plate draws', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[for (final GuideEntry e in contentEntries) Expanded(child: Builder(builder: e.art))],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('HarborMoored', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-moored'));
    Rect box(final WidgetTester tester) => _rect(tester, 'moored box');

    testWidgets('lands between the pier and the quay by default', (final WidgetTester tester) async {
      await pump(tester);
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
      expect(box(tester).left, _near(_frameLeft(tester)));
      expect(box(tester).right, _near(_frameRight(tester)));
      expect(_code(tester), contains('edges: HarborEdge.all,'));
    });

    testWidgets('tide on: the bottom rises clear of the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      expect(_code(tester), contains('tide: true,'));
    });

    testWidgets('tide off: the bottom stays on the quay under the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle tide');
      expect(_code(tester), contains('tide: false,'));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
      expect(box(tester).bottom, greaterThan(_keyboardTop(tester) + 1));
    });

    testWidgets('edges top: clears the pier, but not the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: top');
      expect(_code(tester), contains('edges: {HarborEdge.top},'));
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('edges bottom: runs under the pier, but clears the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: bottom');
      expect(_code(tester), contains('edges: {HarborEdge.bottom},'));
      expect(box(tester).top, _near(_frameTop(tester)));
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('edges horizontal: runs under the pier and ignores the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: horizontal');
      expect(_code(tester), contains('edges: HarborEdge.horizontal,'));
      expect(box(tester).top, _near(_frameTop(tester)));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('edges all, picked again, clears top and bottom again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: horizontal');
      await _tap(tester, 'edges: all');
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('clear coast: sits under the pier, just below the status bar, and ignores the keyboard', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'clear: coast');
      expect(_code(tester), contains('clear: HarborClear.coast,'));
      expect(box(tester).top, _near(_frameTop(tester) + 62 * _scale(tester)));
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
      await _setTide(tester, high: true);
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('clear everything, picked again, clears the pier again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'clear: coast');
      await _tap(tester, 'clear: everything');
      expect(_code(tester), contains('clear: HarborClear.everything,'));
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
    });

    testWidgets('mooringLine adds the margin on the sides only', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle mooringLine');
      final double s = _scale(tester);
      expect(_code(tester), contains('mooringLine: true,'));
      expect(box(tester).left, _near(_frameLeft(tester) + 16 * s));
      expect(box(tester).right, _near(_frameRight(tester) - 16 * s));
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('minimum is a floor: it lifts the edges with less in the way and leaves the pier alone', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _slide(tester, 'minimum', 48);
      final double s = _scale(tester);
      expect(_code(tester), contains('minimum: EdgeInsetsDirectional.all(48),'));
      expect(box(tester).left, _near(_frameLeft(tester) + 48 * s));
      expect(box(tester).right, _near(_frameRight(tester) - 48 * s));
      // The pier and the status bar already keep the top more than 48 away.
      expect(box(tester).top, _near(_rect(tester, 'pier header').bottom));
      // The body ends at the quay, so nothing is in the way there but the floor.
      expect(box(tester).bottom, _near(_rect(tester, 'quay bar').top - 48 * s));
    });

    testWidgets('minimum sets the top where only the coast is cleared and the coast is smaller', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'clear: coast');
      await _slide(tester, 'minimum', 48);
      // The status bar's 62 is more than 48, so the top stays.
      expect(box(tester).top, _near(_frameTop(tester) + 62 * _scale(tester)));
      await _tap(tester, 'toggle Status bar');
      expect(box(tester).top, _near(_frameTop(tester) + 48 * _scale(tester)));
    });
  });

  group('HarborMooringLine', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-mooring-line'));

    testWidgets('rows line up on the margin while the strips run edge to edge', (final WidgetTester tester) async {
      await pump(tester);
      final Rect strip = _rect(tester, 'strip 0');
      final Rect line = _rect(tester, 'line 0');
      final double s = _scale(tester);
      expect(strip.left, _near(_frameLeft(tester)));
      expect(strip.right, _near(_frameRight(tester)));
      expect(line.left - strip.left, _near(16 * s));
      expect(strip.right - line.right, _near(16 * s));
      expect(find.textContaining('HarborMooringLine · '), findsWidgets);
      expect(_code(tester), contains('child: HarborMooringLine(child: BoatRow(i)),'));
    });

    testWidgets('turned off, rows touch the edge', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle HarborMooringLine');
      expect(_rect(tester, 'line 0').left, _near(_rect(tester, 'strip 0').left));
      expect(_rect(tester, 'line 0').right, _near(_rect(tester, 'strip 0').right));
      expect(find.textContaining('HarborMooringLine · '), findsNothing);
      expect(_code(tester), contains('// touches the edge'));
      expect(_code(tester), isNot(contains('HarborMooringLine(')));
    });

    testWidgets('landscape: the side cutouts join the margin on both sides', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: iPhone 17 landscape');
      final Rect strip = _rect(tester, 'strip 0');
      final Rect line = _rect(tester, 'line 0');
      final double s = _scale(tester, deviceWidth: 874);
      expect(strip.width, _near(874 * s));
      expect(line.left - strip.left, _near((62 + 16) * s));
      expect(strip.right - line.right, _near((62 + 16) * s));
    });

    testWidgets('a cutout on one side only moves that side', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: dual screen cover');
      final Rect strip = _rect(tester, 'strip 0');
      final Rect line = _rect(tester, 'line 0');
      final double s = _scale(tester, deviceWidth: 466);
      expect(line.left - strip.left, _near(16 * s));
      expect(strip.right - line.right, _near((84 + 16) * s));
    });

    testWidgets('right-to-left flips the row but keeps the cutout where it is', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: dual screen cover');
      final Finder boat = find.descendant(of: _key('line 0'), matching: find.byType(BoatArt));
      expect(tester.getRect(boat).left, _near(_rect(tester, 'line 0').left));
      await _tap(tester, 'toggle Right-to-left');
      final Rect strip = _rect(tester, 'strip 0');
      final Rect line = _rect(tester, 'line 0');
      final double s = _scale(tester, deviceWidth: 466);
      // The boat now leads from the right.
      expect(tester.getRect(boat).right, _near(line.right));
      // The cutout is on the physical right, so that side keeps the wider gap.
      expect(line.left - strip.left, _near(16 * s));
      expect(strip.right - line.right, _near((84 + 16) * s));
    });
  });

  group('HarborFairway', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-fairway'));

    testWidgets('the first row rests past the pier and its 12 wake', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'pier header').bottom + 12 * _scale(tester)));
      expect(_code(tester), contains('scrollDirection: Axis.vertical,'));
    });

    testWidgets('the last row rests on the quay', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'fairway vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('ensureVisible reveals row 13 clear of the quay', (final WidgetTester tester) async {
      await pump(tester);
      expect(find.text('ensureVisible(row 13)'), findsOneWidget);
      await _tapStage(tester, 'reveal button');
      expect(_rect(tester, 'stage row 12').bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('startsInOpenWater: the first row starts at the top of the frame', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle startsInOpenWater');
      expect(_code(tester), contains('startsInOpenWater: true,'));
      await _scrollStage(tester, 'fairway vertical', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_frameTop(tester)));
      // The far end still rests clear.
      await _scrollStage(tester, 'fairway vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('padding is added to the clearance at both ends and the sides', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'padding', 32);
      final double s = _scale(tester);
      expect(_code(tester), contains('padding: EdgeInsetsDirectional.all(32),'));
      await _scrollStage(tester, 'fairway vertical', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'pier header').bottom + (12 + 32) * s));
      expect(_rect(tester, 'stage row 0').left, _near(_frameLeft(tester) + (32 + 16) * s));
      await _scrollStage(tester, 'fairway vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'quay bar').top - 32 * s));
    });

    testWidgets('revealMargin: a reveal lands that much further clear of the quay', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'revealMargin', 48);
      expect(_code(tester), contains('revealMargin: 48,'));
      await _tapStage(tester, 'reveal button');
      expect(_rect(tester, 'stage row 12').bottom, _near(_rect(tester, 'quay bar').top - 48 * _scale(tester)));
    });

    testWidgets('horizontal: cards rest on the margin at both ends', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      final double s = _scale(tester);
      expect(_code(tester), contains('scrollDirection: Axis.horizontal,'));
      expect(_key('stage row 0'), findsNothing);
      expect(_rect(tester, 'stage card 0').left, _near(_frameLeft(tester) + 16 * s));
      await _scrollStage(tester, 'fairway horizontal', double.infinity);
      expect(_rect(tester, 'stage card 7').right, _near(_frameRight(tester) - 16 * s));
    });

    testWidgets('horizontal: the button offers card 5 and the code names it', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      expect(find.text('ensureVisible(card 5)'), findsOneWidget);
      expect(_code(tester), contains('Scrollable.ensureVisible(row4.currentContext!,'));
    });

    testWidgets('horizontal: ensureVisible reveals card 5 clear of the margin', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      await _tapStage(tester, 'reveal button');
      expect(_rect(tester, 'stage card 4').right, _near(_frameRight(tester) - 16 * _scale(tester)));
    });

    testWidgets('vertical, picked again, brings the rows back', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      await _tap(tester, 'scrollDirection: vertical');
      expect(_key('stage card 0'), findsNothing);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'pier header').bottom + 12 * _scale(tester)));
    });
  });

  group('HarborFairwaySliver', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-fairway-sliver'));

    testWidgets('with both slivers wrapped, each end rests clear of its pier', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'pier header').bottom));
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_rect(tester, 'bottom pier').top));
      expect(_code(tester), contains('HarborFairwaySliver(clearTrailing: false, sliver: firstRows),'));
      expect(_code(tester), contains('HarborFairwaySliver(clearLeading: false, sliver: lastRows),'));
    });

    testWidgets('first sliver off: the first row starts under the pier', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle first sliver');
      await _scrollStage(tester, 'custom scroll view', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_frameTop(tester)));
      expect(_code(tester), contains('    firstRows,\n'));
      // The other end is untouched.
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_rect(tester, 'bottom pier').top));
    });

    testWidgets('last sliver off: the last row ends under the bottom pier', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle last sliver');
      expect(_code(tester), contains('    lastRows,\n'));
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_frameBottom(tester)));
      await _scrollStage(tester, 'custom scroll view', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'pier header').bottom));
    });
  });

  group('HarborSliverDock', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-sliver-dock'));

    testWidgets('at rest, each sliver dock scrolls in line with its rows', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'sliver dock 1').top, _near(_rect(tester, 'stage row 2').bottom));
      expect(_rect(tester, 'sliver dock 2').top, _near(_rect(tester, 'stage row 8').bottom));
    });

    testWidgets('scrolled, the docks pin under the pier and stack', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sliver dock fairway', 900);
      expect(_rect(tester, 'sliver dock 1').top, _near(_rect(tester, 'pier header').bottom));
      expect(_rect(tester, 'sliver dock 2').top, _near(_rect(tester, 'sliver dock 1').bottom));
      expect(_code(tester), contains("Text('Crew')"));
    });

    testWidgets('second off: only the first dock pins', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle second HarborSliverDock');
      expect(_key('sliver dock 2'), findsNothing);
      expect(_code(tester), isNot(contains("Text('Crew')")));
      await _scrollStage(tester, 'sliver dock fairway', 900);
      expect(_rect(tester, 'sliver dock 1').top, _near(_rect(tester, 'pier header').bottom));
    });
  });

  group('HarborSticky', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-sticky'));

    testWidgets('at rest, the pill sits at the top of its item', (final WidgetTester tester) async {
      await pump(tester);
      // The item's margin, border and padding.
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'tall item').top + (8 + 1 + 10) * _scale(tester)));
    });

    testWidgets('scrolled under, it sticks gap below the pinned sliver dock', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky fairway', 250);
      expect(_rect(tester, 'tall item').top, lessThan(_rect(tester, 'sticky sliver dock').bottom));
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver dock').bottom + 8 * _scale(tester)));
    });

    testWidgets('scrolled far enough, it stays inside its item and leaves with it', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky fairway', 650);
      expect(
        _rect(tester, 'sticky pill').bottom,
        _near(_rect(tester, 'tall item').bottom - (8 + 1 + 10) * _scale(tester)),
      );
      expect(_rect(tester, 'sticky pill').top, lessThan(_rect(tester, 'sticky sliver dock').bottom));
    });

    testWidgets('gap sets how far below the docks it sticks', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'gap', 24);
      expect(_code(tester), contains('HarborSticky(gap: 24,'));
      await _scrollStage(tester, 'sticky fairway', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver dock').bottom + 24 * _scale(tester)));
    });

    testWidgets('a gap of 0 sticks it right against the docks', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'gap', 0);
      await _scrollStage(tester, 'sticky fairway', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver dock').bottom));
    });

    testWidgets('changing the gap while it sticks moves it at once', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky fairway', 250);
      await _slide(tester, 'gap', 24);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver dock').bottom + 24 * _scale(tester)));
    });

    testWidgets('without the pinned sliver dock, it sticks below the pier', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle pinned HarborSliverDock');
      expect(_key('sticky sliver dock'), findsNothing);
      await _scrollStage(tester, 'sticky fairway', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'pier header').bottom + 8 * _scale(tester)));
    });
  });

  group('HarborCenter', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-center'));

    testWidgets('centers on the frame, not on the water between the piers', (final WidgetTester tester) async {
      await pump(tester);
      final double middle = (_frameTop(tester) + _frameBottom(tester)) / 2;
      expect(_rect(tester, 'centered controls').center.dy, _near(middle));
      expect(_rect(tester, 'frame middle').center.dy, _near(middle));
      expect(_code(tester), contains('overlapBudget: 24,'));
    });

    testWidgets('at high tide, it overlaps the keyboard by no more than the budget', (final WidgetTester tester) async {
      await pump(tester);
      await _setTide(tester, high: true);
      expect(_rect(tester, 'centered controls').bottom, _near(_keyboardTop(tester) + 24 * _scale(tester)));
    });

    testWidgets('a budget of 0 keeps it fully above the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'overlapBudget', 0);
      expect(_code(tester), contains('overlapBudget: 0,'));
      await _setTide(tester, high: true);
      expect(_rect(tester, 'centered controls').bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('a big enough budget leaves it centered under the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'overlapBudget', 160);
      await _setTide(tester, high: true);
      expect(_rect(tester, 'centered controls').center.dy, _near((_frameTop(tester) + _frameBottom(tester)) / 2));
      expect(_rect(tester, 'centered controls').bottom, greaterThan(_keyboardTop(tester)));
    });
  });

  group('HarborOpenWater', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-open-water'));

    testWidgets('runs full bleed and shades a band for the coast and the docks at each end', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      final double s = _scale(tester);
      expect(_rect(tester, 'open water').top, _near(_frameTop(tester)));
      expect(_rect(tester, 'open water').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'coast band top').height, _near(62 * s));
      expect(_rect(tester, 'docks band top').bottom, _near(_rect(tester, 'pier header').bottom));
      expect(_rect(tester, 'coast band bottom').height, _near(34 * s));
      expect(_rect(tester, 'docks band bottom').top, _near(_rect(tester, 'bottom pier').top));
      expect(find.text('waters.coast.top 62'), findsOneWidget);
      expect(find.text('waters.docks.top 114'), findsOneWidget);
      expect(find.text('waters.coast.bottom 34'), findsOneWidget);
      expect(find.text('waters.docks.bottom 90'), findsOneWidget);
      expect(find.textContaining('frameSize 402 × 874'), findsOneWidget);
      expect(_code(tester), contains('bottom: [HarborDock.pier(child: Bar())],'));
    });

    testWidgets('bottom dock quay: the body ends at the quay and nothing reaches it from below', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'bottom dock: quay');
      expect(_code(tester), contains('bottom: [HarborDock.quay(child: Bar())],'));
      expect(_rect(tester, 'open water').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_rect(tester, 'docks band bottom').height, _near(0));
      expect(_rect(tester, 'coast band bottom').height, _near(0));
      // The top is untouched.
      expect(_rect(tester, 'docks band top').bottom, _near(_rect(tester, 'pier header').bottom));
    });

    testWidgets('bottom dock pier, picked again, runs under it again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'bottom dock: quay');
      await _tap(tester, 'bottom dock: pier');
      expect(_rect(tester, 'open water').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'docks band bottom').top, _near(_rect(tester, 'bottom pier').top));
    });
  });

  group('HarborCastOff', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-cast-off'));

    testWidgets('on: the SafeArea inside clears nothing again', (final WidgetTester tester) async {
      await pump(tester);
      final Rect box = _rect(tester, 'hand padded box');
      expect(box.top, _near(_rect(tester, 'pier header').bottom));
      expect(box.bottom, _near(_rect(tester, 'bottom pier').top));
      expect(_rect(tester, 'inner safe area'), _rectNear(box));
      expect(find.text('clears nothing again'), findsOneWidget);
      expect(_code(tester), contains('child: HarborCastOff('));
    });

    testWidgets('off: the SafeArea inside clears the docks a second time', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle HarborCastOff');
      final Rect box = _rect(tester, 'hand padded box');
      final Rect inner = _rect(tester, 'inner safe area');
      expect(inner.top - box.top, _near(box.top - _frameTop(tester)));
      expect(box.bottom - inner.bottom, _near(_frameBottom(tester) - box.bottom));
      expect(find.text('clears the docks a second time'), findsOneWidget);
      expect(_code(tester), contains('// pads again'));
      expect(_code(tester), isNot(contains('HarborCastOff')));
    });

    testWidgets('edges vertical in landscape: the side cutouts are cleared twice', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: iPhone 17 landscape');
      final double s = _scale(tester, deviceWidth: 874);
      Rect box = _rect(tester, 'hand padded box');
      expect(box.left, _near(_frameLeft(tester) + 62 * s));
      expect(_rect(tester, 'inner safe area'), _rectNear(box));

      await _tap(tester, 'edges: vertical');
      expect(_code(tester), contains('edges: HarborEdge.vertical,'));
      box = _rect(tester, 'hand padded box');
      final Rect inner = _rect(tester, 'inner safe area');
      expect(inner.top, _near(box.top));
      expect(inner.left - box.left, _near(62 * s));
      expect(box.right - inner.right, _near(62 * s));
    });

    testWidgets('edges all, picked again, casts the sides off again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: iPhone 17 landscape');
      await _tap(tester, 'edges: vertical');
      await _tap(tester, 'edges: all');
      expect(_code(tester), contains('edges: HarborEdge.all,'));
      expect(_rect(tester, 'inner safe area'), _rectNear(_rect(tester, 'hand padded box')));
    });
  });

  group('HarborMakeWay', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('talk-make-way'));

    Future<void> press(final WidgetTester tester, final String edge) async {
      await _tap(tester, 'toggle make way: $edge');
      await tester.pump(_step);
    }

    testWidgets('withdraw bottom: the tab bar leaves and gives its ground back', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'make way fairway').bottom, _near(_rect(tester, 'quay bar').top));
      await press(tester, 'bottom');
      expect(_code(tester), contains('HarborMakeWay(edge: HarborEdge.bottom, mode: HarborYield.withdraw, child: ...)'));
      expect(_rect(tester, 'make way fairway').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'quay bar').top, greaterThanOrEqualTo(_frameBottom(tester) - 0.6));
    });

    testWidgets('releasing the claim brings the tab bar back', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'bottom');
      await press(tester, 'bottom');
      expect(_code(tester), contains('// (bottom: no claim)'));
      expect(_rect(tester, 'make way fairway').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_rect(tester, 'quay bar').bottom, lessThan(_frameBottom(tester)));
    });

    testWidgets('withdraw top: the pier leaves and the rows rise toward the status bar', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      final double rowTop = _rect(tester, 'stage row 0').top;
      final double pierBottom = _rect(tester, 'pier header').bottom;
      await press(tester, 'top');
      expect(_code(tester), contains('HarborMakeWay(edge: HarborEdge.top, mode: HarborYield.withdraw, child: ...)'));
      expect(_rect(tester, 'pier header').bottom, lessThanOrEqualTo(_frameTop(tester) + 0.6));
      // The rows move up by the pier's ground: down to the status bar.
      expect(_rect(tester, 'stage row 0').top, _near(rowTop - (pierBottom - _frameTop(tester) - 62 * _scale(tester))));
    });

    testWidgets('dark top: the pier is hidden and untappable but keeps its ground', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'mode: dark');
      final double rowGap = _rect(tester, 'stage row 0').top - _rect(tester, 'pier header').bottom;
      expect(_key('pier header').hitTestable(), findsOneWidget);
      await press(tester, 'top');
      expect(_code(tester), contains('HarborMakeWay(edge: HarborEdge.top, mode: HarborYield.dark, child: ...)'));
      expect(_rect(tester, 'stage row 0').top - _rect(tester, 'pier header').bottom, _near(rowGap));
      expect(_opacityOf(tester, 'pier header'), 0);
      expect(_key('pier header').hitTestable(), findsNothing);
    });

    testWidgets('dark bottom: the tab bar is hidden but the body still ends above it', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'mode: dark');
      await press(tester, 'bottom');
      expect(_rect(tester, 'make way fairway').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_opacityOf(tester, 'quay bar'), 0);
    });

    testWidgets('withdraw, picked again, gives the ground back again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'mode: dark');
      await _tap(tester, 'mode: withdraw');
      expect(_code(tester), contains('.makeWay(HarborEdge.bottom, mode: HarborYield.withdraw);'));
      await press(tester, 'bottom');
      expect(_rect(tester, 'make way fairway').bottom, _near(_frameBottom(tester)));
    });

    testWidgets('changing the mode while a claim is held moves the claim to the new mode', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await press(tester, 'bottom');
      expect(_rect(tester, 'make way fairway').bottom, _near(_frameBottom(tester)));
      await _tap(tester, 'mode: dark');
      await tester.pump(_step);
      expect(_rect(tester, 'make way fairway').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_opacityOf(tester, 'quay bar'), 0);
    });
  });

  group('HarborPontoon', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('talk-pontoon'));

    Future<void> press(final WidgetTester tester, final String key) async {
      await _tapStage(tester, key);
      await tester.pump(_step);
    }

    testWidgets('Edit moors the unsaved bar above the tab bar', (final WidgetTester tester) async {
      await pump(tester);
      expect(_key('unsaved bar'), findsNothing);
      await press(tester, 'deep edit button');
      expect(find.text('Cargo manifest (edited)'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('as a pier, the body runs on under the bar and rows rest clear of it', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await press(tester, 'deep edit button');
      expect(_code(tester), contains('dock: HarborDock.pier(child: UnsavedBar(onSave: save)),'));
      expect(_rect(tester, 'pontoon fairway').bottom, _near(_rect(tester, 'quay bar').top));
      await _scrollStage(tester, 'pontoon fairway', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'unsaved bar').top));
    });

    testWidgets('as a quay, the body ends above the bar', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'dock: quay');
      expect(_code(tester), contains('dock: HarborDock.quay(child: UnsavedBar(onSave: save)),'));
      await press(tester, 'deep edit button');
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_rect(tester, 'pontoon fairway').bottom, _near(_rect(tester, 'unsaved bar').top));
    });

    testWidgets('dock pier, picked again, lets the body run under the bar again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'dock: quay');
      await press(tester, 'deep edit button');
      await _tap(tester, 'dock: pier');
      await tester.pump(_step);
      expect(_rect(tester, 'pontoon fairway').bottom, _near(_rect(tester, 'quay bar').top));
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'quay bar').top));
    });

    testWidgets('Save takes the bar away again', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'deep edit button');
      await press(tester, 'save button');
      expect(_key('unsaved bar'), findsNothing);
      expect(find.text('Cargo manifest'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('Undo takes the bar away too', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'deep edit button');
      await press(tester, 'deep edit button');
      expect(_key('unsaved bar'), findsNothing);
    });
  });
}
