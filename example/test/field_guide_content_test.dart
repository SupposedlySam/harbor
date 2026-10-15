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
          HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
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
    // One frame to start the panel growing and one to finish, so the controls can scroll to all of it.
    await tester.pump();
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

/// Shows or hides the stage's keyboard with the button beside the stage.
Future<void> _setKeyboard(final WidgetTester tester, {required final bool shown}) async {
  final Finder toggle = _key('tide toggle');
  final IconButton button = tester.widget<IconButton>(toggle);
  final bool isShown = button.tooltip == 'Hide the keyboard';
  if (isShown != shown) {
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

/// How opaque the bar holding [key] is drawn.
double _opacityOf(final WidgetTester tester, final String key) =>
    tester.widget<Opacity>(find.ancestor(of: _key(key), matching: find.byType(Opacity)).first).opacity;

void main() {
  test('both groups are listed, named as in code', () {
    expect(
      contentEntries
          .where((final GuideEntry e) => e.group == GuideGroup.content)
          .map((final GuideEntry e) => e.className),
      <String>[
        'HarborClear',
        'HarborClear.rowInsets',
        'HarborScrollView',
        'HarborSliverClear',
        'HarborSliverBar',
        'HarborSticky',
        'HarborCenter',
        'HarborRoom.of',
        'HarborHandled',
      ],
    );
    expect(
      contentEntries.where((final GuideEntry e) => e.group == GuideGroup.talk).map((final GuideEntry e) => e.className),
      <String>['HarborHideBar', 'HarborAttachedBar'],
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

  group('HarborClear', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-moored'));
    Rect box(final WidgetTester tester) => _rect(tester, 'clear box');

    testWidgets('lands between the overlay header and the solid bar by default', (final WidgetTester tester) async {
      await pump(tester);
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
      expect(box(tester).left, _near(_frameLeft(tester)));
      expect(box(tester).right, _near(_frameRight(tester)));
      expect(_code(tester), contains('edges: HarborEdge.all,'));
    });

    testWidgets('clearsKeyboard on: the bottom rises clear of the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      expect(_code(tester), contains('clearsKeyboard: true,'));
    });

    testWidgets('clearsKeyboard off: the bottom stays on the solid bar under the keyboard', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'toggle clearsKeyboard');
      expect(_code(tester), contains('clearsKeyboard: false,'));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
      expect(box(tester).bottom, greaterThan(_keyboardTop(tester) + 1));
    });

    testWidgets('edges top: clears the overlay header, but not the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: top');
      expect(_code(tester), contains('edges: {HarborEdge.top},'));
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('edges bottom: runs under the overlay header, but clears the keyboard', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'edges: bottom');
      expect(_code(tester), contains('edges: {HarborEdge.bottom},'));
      expect(box(tester).top, _near(_frameTop(tester)));
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('edges horizontal: runs under the overlay header and ignores the keyboard', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'edges: horizontal');
      expect(_code(tester), contains('edges: HarborEdge.horizontal,'));
      expect(box(tester).top, _near(_frameTop(tester)));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('edges all, picked again, clears top and bottom again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'edges: horizontal');
      await _tap(tester, 'edges: all');
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('clearsBars off: sits under the overlay header, just below the status bar, and ignores the keyboard', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'toggle clearsBars');
      expect(_code(tester), contains('clearsBars: false,'));
      expect(box(tester).top, _near(_frameTop(tester) + 62 * _scale(tester)));
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
      await _setKeyboard(tester, shown: true);
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('clearsBars, switched on again, clears the overlay header again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle clearsBars');
      await _tap(tester, 'toggle clearsBars');
      expect(_code(tester), contains('clearsBars: true,'));
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
    });

    testWidgets('rowInsets adds the margin on the sides only', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle rowInsets');
      final double s = _scale(tester);
      expect(_code(tester), contains('rowInsets: true,'));
      expect(box(tester).left, _near(_frameLeft(tester) + 16 * s));
      expect(box(tester).right, _near(_frameRight(tester) - 16 * s));
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('minimum is a floor: it lifts the edges with less in the way and leaves the header alone', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _slide(tester, 'minimum', 48);
      final double s = _scale(tester);
      expect(_code(tester), contains('minimum: EdgeInsetsDirectional.all(48),'));
      expect(box(tester).left, _near(_frameLeft(tester) + 48 * s));
      expect(box(tester).right, _near(_frameRight(tester) - 48 * s));
      // The header and the status bar already keep the top more than 48 away.
      expect(box(tester).top, _near(_rect(tester, 'overlay header').bottom));
      // The body ends at the solid bar, so nothing is in the way there but the floor.
      expect(box(tester).bottom, _near(_rect(tester, 'solid bar').top - 48 * s));
    });

    testWidgets('minimum sets the top where only the system edges are cleared and they are smaller', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'toggle clearsBars');
      await _slide(tester, 'minimum', 48);
      // The status bar's 62 is more than 48, so the top stays.
      expect(box(tester).top, _near(_frameTop(tester) + 62 * _scale(tester)));
      // Hiding it on this iPhone leaves the island's 62; a phone whose status bar is 20 has less,
      // so the 48 decides there: 28 below where the system edge alone would put it. Measured against
      // the system edge alone rather than the frame, whose bezel and scale change with the device.
      await _tap(tester, 'Device: iPhone SE');
      final double at48 = box(tester).top;
      await _slide(tester, 'minimum', 34);
      final double at34 = box(tester).top;
      await _slide(tester, 'minimum', 0);
      final double systemEdgeAlone = box(tester).top;
      // 48 and 34 sit 28 and 14 below the 20 of system edge: twice as far, whatever the phone's scale.
      expect(at48, greaterThan(systemEdgeAlone));
      expect((at48 - systemEdgeAlone) / (at34 - systemEdgeAlone), closeTo(2, 0.05));
    });
  });

  group('HarborClear.rowInsets', () {
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
      expect(find.textContaining('HarborClear.rowInsets · '), findsWidgets);
      expect(_code(tester), contains('child: HarborClear.rowInsets(child: BoatRow(i)),'));
    });

    testWidgets('turned off, rows touch the edge', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle HarborClear.rowInsets');
      expect(_rect(tester, 'line 0').left, _near(_rect(tester, 'strip 0').left));
      expect(_rect(tester, 'line 0').right, _near(_rect(tester, 'strip 0').right));
      expect(find.textContaining('HarborClear.rowInsets · '), findsNothing);
      expect(_code(tester), contains('// touches the edge'));
      expect(_code(tester), isNot(contains('HarborClear.rowInsets(')));
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

  group('HarborScrollView', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-fairway'));

    testWidgets('the first row rests past the overlay header and its 12 fade', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'overlay header').bottom + 12 * _scale(tester)));
      expect(_code(tester), contains('scrollDirection: Axis.vertical,'));
    });

    testWidgets('the last row rests on the solid bar', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'scroll view vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('ensureVisible reveals row 13 clear of the solid bar', (final WidgetTester tester) async {
      await pump(tester);
      expect(find.text('ensureVisible(row 13)'), findsOneWidget);
      // The reveal is a control, not a button in the pretend app.
      expect(find.descendant(of: _key('stage'), matching: _key('reveal button')), findsNothing);
      await _tap(tester, 'reveal button');
      expect(_rect(tester, 'stage row 12').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('startsUnderBars: the first row starts at the top of the frame', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle startsUnderBars');
      expect(_code(tester), contains('startsUnderBars: true,'));
      await _scrollStage(tester, 'scroll view vertical', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_frameTop(tester)));
      // The far end still rests clear.
      await _scrollStage(tester, 'scroll view vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('padding is added to the clearance at both ends and the sides', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'padding', 32);
      final double s = _scale(tester);
      expect(_code(tester), contains('padding: EdgeInsetsDirectional.all(32),'));
      await _scrollStage(tester, 'scroll view vertical', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'overlay header').bottom + (12 + 32) * s));
      expect(_rect(tester, 'stage row 0').left, _near(_frameLeft(tester) + (32 + 16) * s));
      await _scrollStage(tester, 'scroll view vertical', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'solid bar').top - 32 * s));
    });

    testWidgets('revealMargin: a reveal lands that much further clear of the solid bar', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _slide(tester, 'revealMargin', 48);
      expect(_code(tester), contains('revealMargin: 48,'));
      await _tap(tester, 'reveal button');
      expect(_rect(tester, 'stage row 12').bottom, _near(_rect(tester, 'solid bar').top - 48 * _scale(tester)));
    });

    testWidgets('horizontal: cards rest on the margin at both ends', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      final double s = _scale(tester);
      expect(_code(tester), contains('scrollDirection: Axis.horizontal,'));
      expect(_key('stage row 0'), findsNothing);
      expect(_rect(tester, 'stage card 0').left, _near(_frameLeft(tester) + 16 * s));
      await _scrollStage(tester, 'scroll view horizontal', double.infinity);
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
      await _tap(tester, 'reveal button');
      expect(_rect(tester, 'stage card 4').right, _near(_frameRight(tester) - 16 * _scale(tester)));
    });

    testWidgets('vertical, picked again, brings the rows back', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'scrollDirection: horizontal');
      await _tap(tester, 'scrollDirection: vertical');
      expect(_key('stage card 0'), findsNothing);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'overlay header').bottom + 12 * _scale(tester)));
    });
  });

  group('HarborSliverClear', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-fairway-sliver'));

    testWidgets('with both slivers wrapped, each end rests clear of its overlay bar', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'overlay header').bottom));
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_rect(tester, 'bottom overlay bar').top));
      expect(_code(tester), contains('HarborSliverClear(clearTrailing: false, sliver: firstRows),'));
      expect(_code(tester), contains('HarborSliverClear(clearLeading: false, sliver: lastRows),'));
    });

    testWidgets('first sliver off: the first row starts under the overlay header', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle first sliver');
      await _scrollStage(tester, 'custom scroll view', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_frameTop(tester)));
      expect(_code(tester), contains('    firstRows,\n'));
      // The other end is untouched.
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_rect(tester, 'bottom overlay bar').top));
    });

    testWidgets('last sliver off: the last row ends under the bottom overlay bar', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle last sliver');
      expect(_code(tester), contains('    lastRows,\n'));
      await _scrollStage(tester, 'custom scroll view', double.infinity);
      expect(_rect(tester, 'stage row 17').bottom, _near(_frameBottom(tester)));
      await _scrollStage(tester, 'custom scroll view', 0);
      expect(_rect(tester, 'stage row 0').top, _near(_rect(tester, 'overlay header').bottom));
    });
  });

  group('HarborSliverBar', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-sliver-dock'));

    testWidgets('at rest, each sliver bar scrolls in line with its rows', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'sliver bar 1').top, _near(_rect(tester, 'stage row 2').bottom));
      expect(_rect(tester, 'sliver bar 2').top, _near(_rect(tester, 'stage row 8').bottom));
    });

    testWidgets('scrolled, the sliver bars pin under the overlay header and stack', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sliver bar scroll view', 900);
      expect(_rect(tester, 'sliver bar 1').top, _near(_rect(tester, 'overlay header').bottom));
      expect(_rect(tester, 'sliver bar 2').top, _near(_rect(tester, 'sliver bar 1').bottom));
      expect(_code(tester), contains("Text('Crew')"));
    });

    testWidgets('second off: only the first sliver bar pins', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle second HarborSliverBar');
      expect(_key('sliver bar 2'), findsNothing);
      expect(_code(tester), isNot(contains("Text('Crew')")));
      await _scrollStage(tester, 'sliver bar scroll view', 900);
      expect(_rect(tester, 'sliver bar 1').top, _near(_rect(tester, 'overlay header').bottom));
    });
  });

  group('HarborSticky', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-sticky'));

    testWidgets('at rest, the pill sits at the top of its item', (final WidgetTester tester) async {
      await pump(tester);
      // The item's margin, border and padding.
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'tall item').top + (8 + 1 + 10) * _scale(tester)));
    });

    testWidgets('scrolled under, it sticks gap below the pinned sliver bar', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky scroll view', 250);
      expect(_rect(tester, 'tall item').top, lessThan(_rect(tester, 'sticky sliver bar').bottom));
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver bar').bottom + 8 * _scale(tester)));
    });

    testWidgets('scrolled far enough, it stays inside its item and leaves with it', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky scroll view', 650);
      expect(
        _rect(tester, 'sticky pill').bottom,
        _near(_rect(tester, 'tall item').bottom - (8 + 1 + 10) * _scale(tester)),
      );
      expect(_rect(tester, 'sticky pill').top, lessThan(_rect(tester, 'sticky sliver bar').bottom));
    });

    testWidgets('gap sets how far below the bars it sticks', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'gap', 24);
      expect(_code(tester), contains('HarborSticky(gap: 24,'));
      await _scrollStage(tester, 'sticky scroll view', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver bar').bottom + 24 * _scale(tester)));
    });

    testWidgets('a gap of 0 sticks it right against the bars', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'gap', 0);
      await _scrollStage(tester, 'sticky scroll view', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver bar').bottom));
    });

    testWidgets('changing the gap while it sticks moves it at once', (final WidgetTester tester) async {
      await pump(tester);
      await _scrollStage(tester, 'sticky scroll view', 250);
      await _slide(tester, 'gap', 24);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'sticky sliver bar').bottom + 24 * _scale(tester)));
    });

    testWidgets('without the pinned sliver bar, it sticks below the overlay header', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle pinned HarborSliverBar');
      expect(_key('sticky sliver bar'), findsNothing);
      await _scrollStage(tester, 'sticky scroll view', 250);
      expect(_rect(tester, 'sticky pill').top, _near(_rect(tester, 'overlay header').bottom + 8 * _scale(tester)));
    });
  });

  group('HarborCenter', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-center'));

    testWidgets('centers on the frame, not on the room between the overlay bars', (final WidgetTester tester) async {
      await pump(tester);
      final double middle = (_frameTop(tester) + _frameBottom(tester)) / 2;
      expect(_rect(tester, 'centered controls').center.dy, _near(middle));
      expect(_rect(tester, 'frame middle').center.dy, _near(middle));
      expect(_code(tester), contains('overlapBudget: 24,'));
    });

    testWidgets('with the keyboard up, it overlaps the keyboard by no more than the budget', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _setKeyboard(tester, shown: true);
      expect(_rect(tester, 'centered controls').bottom, _near(_keyboardTop(tester) + 24 * _scale(tester)));
    });

    testWidgets('a budget of 0 keeps it fully above the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'overlapBudget', 0);
      expect(_code(tester), contains('overlapBudget: 0,'));
      await _setKeyboard(tester, shown: true);
      expect(_rect(tester, 'centered controls').bottom, _near(_keyboardTop(tester)));
    });

    testWidgets('a big enough budget leaves it centered under the keyboard', (final WidgetTester tester) async {
      await pump(tester);
      await _slide(tester, 'overlapBudget', 160);
      await _setKeyboard(tester, shown: true);
      expect(_rect(tester, 'centered controls').center.dy, _near((_frameTop(tester) + _frameBottom(tester)) / 2));
      expect(_rect(tester, 'centered controls').bottom, greaterThan(_keyboardTop(tester)));
    });
  });

  group('HarborRoom.of', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-open-water'));

    testWidgets('runs full bleed and shades a band for the system edges and the bars at each end', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      final double s = _scale(tester);
      expect(_rect(tester, 'full bleed').top, _near(_frameTop(tester)));
      expect(_rect(tester, 'full bleed').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'systemEdges band top').height, _near(62 * s));
      expect(_rect(tester, 'bars band top').bottom, _near(_rect(tester, 'overlay header').bottom));
      expect(_rect(tester, 'systemEdges band bottom').height, _near(34 * s));
      expect(_rect(tester, 'bars band bottom').top, _near(_rect(tester, 'bottom overlay bar').top));
      expect(find.text('room.systemEdges.top 62'), findsOneWidget);
      expect(find.text('room.bars.top 114'), findsOneWidget);
      expect(find.text('room.systemEdges.bottom 34'), findsOneWidget);
      expect(find.text('room.bars.bottom 90'), findsOneWidget);
      expect(find.textContaining('frameSize 402 × 874'), findsOneWidget);
      expect(_code(tester), contains('bottom: [HarborBar.overlay(child: Bar())],'));
      expect(_code(tester), contains('final room = HarborRoom.of(context);'));
    });

    testWidgets('bottom bar solid: the body ends at the solid bar and nothing reaches it from below', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'bottom bar: solid');
      expect(_code(tester), contains('bottom: [HarborBar.solid(child: Bar())],'));
      expect(_rect(tester, 'full bleed').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_rect(tester, 'bars band bottom').height, _near(0));
      expect(_rect(tester, 'systemEdges band bottom').height, _near(0));
      // The top is untouched.
      expect(_rect(tester, 'bars band top').bottom, _near(_rect(tester, 'overlay header').bottom));
    });

    testWidgets('bottom bar overlay, picked again, runs under it again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'bottom bar: solid');
      await _tap(tester, 'bottom bar: overlay');
      expect(_rect(tester, 'full bleed').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'bars band bottom').top, _near(_rect(tester, 'bottom overlay bar').top));
    });
  });

  group('HarborHandled', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('content-cast-off'));

    testWidgets('on: the SafeArea inside clears nothing again', (final WidgetTester tester) async {
      await pump(tester);
      final Rect box = _rect(tester, 'hand padded box');
      expect(box.top, _near(_rect(tester, 'overlay header').bottom));
      expect(box.bottom, _near(_rect(tester, 'bottom overlay bar').top));
      expect(_rect(tester, 'inner safe area'), _rectNear(box));
      expect(find.text('clears nothing again'), findsOneWidget);
      expect(_code(tester), contains('child: HarborHandled('));
    });

    testWidgets('off: the SafeArea inside clears the bars a second time', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'toggle HarborHandled');
      final Rect box = _rect(tester, 'hand padded box');
      final Rect inner = _rect(tester, 'inner safe area');
      expect(inner.top - box.top, _near(box.top - _frameTop(tester)));
      expect(box.bottom - inner.bottom, _near(_frameBottom(tester) - box.bottom));
      expect(find.text('clears the bars a second time'), findsOneWidget);
      expect(_code(tester), contains('// pads again'));
      expect(_code(tester), isNot(contains('HarborHandled')));
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

    testWidgets('edges all, picked again, handles the sides again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'Device: iPhone 17 landscape');
      await _tap(tester, 'edges: vertical');
      await _tap(tester, 'edges: all');
      expect(_code(tester), contains('edges: HarborEdge.all,'));
      expect(_rect(tester, 'inner safe area'), _rectNear(_rect(tester, 'hand padded box')));
    });
  });

  group('HarborHideBar', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('talk-make-way'));

    Future<void> press(final WidgetTester tester, final String edge) async {
      await _tap(tester, 'toggle hide bar: $edge');
      await tester.pump(_step);
    }

    testWidgets('withdraw bottom: the tab bar leaves and gives its ground back', (final WidgetTester tester) async {
      await pump(tester);
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      await press(tester, 'bottom');
      expect(
        _code(tester),
        contains('HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.withdrawn, child: ...)'),
      );
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_frameBottom(tester)));
      expect(_rect(tester, 'solid bar').top, greaterThanOrEqualTo(_frameBottom(tester) - 0.6));
    });

    testWidgets('releasing the claim brings the tab bar back', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'bottom');
      await press(tester, 'bottom');
      expect(_code(tester), contains('// (bottom: no claim)'));
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_rect(tester, 'solid bar').bottom, lessThan(_frameBottom(tester)));
    });

    testWidgets('withdraw top: the overlay header leaves and the rows rise toward the status bar', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      final double rowTop = _rect(tester, 'stage row 0').top;
      final double headerBottom = _rect(tester, 'overlay header').bottom;
      await press(tester, 'top');
      expect(
        _code(tester),
        contains('HarborHideBar(edge: HarborEdge.top, state: HarborBarState.withdrawn, child: ...)'),
      );
      expect(_rect(tester, 'overlay header').bottom, lessThanOrEqualTo(_frameTop(tester) + 0.6));
      // The rows move up by the header's ground: down to the status bar.
      expect(
        _rect(tester, 'stage row 0').top,
        _near(rowTop - (headerBottom - _frameTop(tester) - 62 * _scale(tester))),
      );
    });

    testWidgets('dark top: the overlay header is hidden and untappable but keeps its ground', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'state: dark');
      final double rowGap = _rect(tester, 'stage row 0').top - _rect(tester, 'overlay header').bottom;
      expect(_key('overlay header').hitTestable(), findsOneWidget);
      await press(tester, 'top');
      expect(_code(tester), contains('HarborHideBar(edge: HarborEdge.top, state: HarborBarState.dark, child: ...)'));
      expect(_rect(tester, 'stage row 0').top - _rect(tester, 'overlay header').bottom, _near(rowGap));
      expect(_opacityOf(tester, 'overlay header'), 0);
      expect(_key('overlay header').hitTestable(), findsNothing);
    });

    testWidgets('dark bottom: the tab bar is hidden but the body still ends above it', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await _tap(tester, 'state: dark');
      await press(tester, 'bottom');
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_opacityOf(tester, 'solid bar'), 0);
    });

    testWidgets('withdrawn, picked again, gives the ground back again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'state: dark');
      await _tap(tester, 'state: withdrawn');
      expect(_code(tester), contains('.hideBar(HarborEdge.bottom, state: HarborBarState.withdrawn);'));
      await press(tester, 'bottom');
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_frameBottom(tester)));
    });

    testWidgets('changing the state while a claim is held moves the claim to the new state', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await press(tester, 'bottom');
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_frameBottom(tester)));
      await _tap(tester, 'state: dark');
      await tester.pump(_step);
      expect(_rect(tester, 'hide bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_opacityOf(tester, 'solid bar'), 0);
    });
  });

  group('HarborAttachedBar', () {
    Future<void> pump(final WidgetTester tester) => _pumpEntry(tester, _page('talk-pontoon'));

    /// Taps the form's own button on the stage: the form is what attaches the bar.
    Future<void> press(final WidgetTester tester, final String key) async {
      await _tapStage(tester, key);
      await tester.pump(_step);
    }

    /// Flips the dirty switch in the controls.
    Future<void> flip(final WidgetTester tester) async {
      await _tap(tester, 'toggle dirty');
      await tester.pump(_step);
    }

    bool dirtySwitch(final WidgetTester tester) => tester.widget<SwitchListTile>(_key('toggle dirty')).value;

    testWidgets('the whole phone is in view: the form at the top, the tab bar at the bottom', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      expect(_key('focus toggle'), findsNothing, reason: 'the page shows the whole phone, uncropped');
      expect(_rect(tester, 'overlay header').top, greaterThanOrEqualTo(_frameTop(tester) - 0.6));
      expect(_rect(tester, 'deep edit button').top, greaterThan(_frameTop(tester)));
      expect(_rect(tester, 'solid bar').bottom, lessThanOrEqualTo(_frameBottom(tester) + 0.6));
    });

    testWidgets('dirty attaches the unsaved bar above the tab bar', (final WidgetTester tester) async {
      await pump(tester);
      expect(_key('unsaved bar'), findsNothing);
      await flip(tester);
      expect(find.text('Cargo manifest (edited)'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('Edit in the form attaches it too, and the switch follows', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'deep edit button');
      expect(dirtySwitch(tester), isTrue);
      expect(find.text('Cargo manifest (edited)'), findsOneWidget);
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('as an overlay bar, the body runs on under the bar and rows rest clear of it', (
      final WidgetTester tester,
    ) async {
      await pump(tester);
      await flip(tester);
      expect(_code(tester), contains('bar: HarborBar.overlay(child: UnsavedBar(onSave: save)),'));
      expect(_rect(tester, 'attached bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      await _scrollStage(tester, 'attached bar scroll view', double.infinity);
      expect(_rect(tester, 'stage row 15').bottom, _near(_rect(tester, 'unsaved bar').top));
    });

    testWidgets('as a solid bar, the body ends above the bar', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'bar: solid');
      expect(_code(tester), contains('bar: HarborBar.solid(child: UnsavedBar(onSave: save)),'));
      await flip(tester);
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_rect(tester, 'attached bar scroll view').bottom, _near(_rect(tester, 'unsaved bar').top));
    });

    testWidgets('bar overlay, picked again, lets the body run under the bar again', (final WidgetTester tester) async {
      await pump(tester);
      await _tap(tester, 'bar: solid');
      await flip(tester);
      await _tap(tester, 'bar: overlay');
      await tester.pump(_step);
      expect(_rect(tester, 'attached bar scroll view').bottom, _near(_rect(tester, 'solid bar').top));
      expect(_rect(tester, 'unsaved bar').bottom, _near(_rect(tester, 'solid bar').top));
    });

    testWidgets('Save takes the bar away again', (final WidgetTester tester) async {
      await pump(tester);
      await flip(tester);
      await press(tester, 'save button');
      expect(_key('unsaved bar'), findsNothing);
      expect(dirtySwitch(tester), isFalse);
      expect(find.text('Cargo manifest'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('Undo takes the bar away too', (final WidgetTester tester) async {
      await pump(tester);
      await press(tester, 'deep edit button');
      await press(tester, 'deep edit button');
      expect(_key('unsaved bar'), findsNothing);
      expect(dirtySwitch(tester), isFalse);
    });

    testWidgets('dirty off takes the bar away', (final WidgetTester tester) async {
      await pump(tester);
      await flip(tester);
      await flip(tester);
      expect(_key('unsaved bar'), findsNothing);
      expect(find.text('Edit'), findsOneWidget);
    });
  });
}
