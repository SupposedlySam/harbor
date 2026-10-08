import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_floating.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/stage.dart';
import 'package:harbor_example/field_guide/stage_kit.dart';

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
double _scale(final WidgetTester tester) => (tester.getRect(_key('stage')).width - 20) / 402;

/// The edges of the stage's screen, inside its bezel.
double _frameTop(final WidgetTester tester) => tester.getRect(_key('stage')).top + 10;
double _frameBottom(final WidgetTester tester) => tester.getRect(_key('stage')).bottom - 10;
double _frameLeft(final WidgetTester tester) => tester.getRect(_key('stage')).left + 10;
double _frameRight(final WidgetTester tester) => tester.getRect(_key('stage')).right - 10;

/// The bottom of the stage's first header (a [StageHeader] or a keyed header).
double _headerBottom(final WidgetTester tester) => tester.getRect(find.byType(StageHeader).first).bottom;

double _keyboardTop(final WidgetTester tester) => tester.getRect(find.byType(KeyboardArt)).top;

Future<void> _tap(final WidgetTester tester, final String key) async {
  final Finder finder = _key(key);
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
  await tester.tap(_key(key).first);
  await tester.pump();
  await tester.pump(_step);
  expect(tester.takeException(), isNull, reason: key);
}

Future<void> _setTide(final WidgetTester tester, {required final bool high}) async {
  final IconButton button = tester.widget<IconButton>(_key('tide toggle'));
  final bool isHigh = button.tooltip == 'Lower the tide';
  if (isHigh != high) {
    await _tap(tester, 'tide toggle');
  }
  await tester.pump(_step);
}

ScrollPosition _stageScroll(final WidgetTester tester, final String key) =>
    tester.state<ScrollableState>(find.descendant(of: _key(key), matching: find.byType(Scrollable)).first).position;

Future<void> _scrollStage(final WidgetTester tester, final String key, final double to) async {
  final ScrollPosition position = _stageScroll(tester, key);
  position.jumpTo(to.clamp(position.minScrollExtent, position.maxScrollExtent));
  await tester.pump();
  await tester.pump(_step);
}

/// Closes the sheet open on the stage (a non-modal sheet is not a route).
Future<void> _popStage(final WidgetTester tester, final String keyInside) async {
  HarborSheet.close(tester.element(_key(keyInside).first));
  await tester.pump();
  await tester.pump(_step);
  await tester.pump(_step);
}

Widget _page(final String id) => Builder(
  builder: (final BuildContext context) => floatingEntries.firstWhere((final GuideEntry e) => e.id == id).page(context),
);

Matcher _near(final double value) => moreOrLessEquals(value, epsilon: 0.6);
Matcher _atMost(final double value) => lessThanOrEqualTo(value + 0.6);
Matcher _atLeast(final double value) => greaterThanOrEqualTo(value - 0.6);

/// The code card's text, as the controls have it now.
String _code(final WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _key('code card'), matching: find.byType(Text))).data!;

/// Moves the slider for [label] to [value], as a drag would.
Future<void> _slide(final WidgetTester tester, final String label, final double value) async {
  final Finder slider = _key('slider $label');
  expect(slider, findsOneWidget, reason: label);
  await tester.ensureVisible(slider);
  await tester.pump(const Duration(milliseconds: 300));
  tester.widget<Slider>(slider).onChanged!(value);
  await tester.pump();
  await tester.pump(_step);
}

bool _selected(final WidgetTester tester, final String key) => tester.widget<ChoiceChip>(_key(key)).selected;

bool _switchedOn(final WidgetTester tester, final String key) => tester.widget<SwitchListTile>(_key(key)).value;

String _textOf(final WidgetTester tester, final String key) =>
    tester.widget<Text>(find.descendant(of: _key(key), matching: find.byType(Text)).first).data!;

/// The space a sheet's height fractions are of, with the keyboard down: the
/// screen below the status bar.
const double _sheetSpace = 874 - 62;

/// The top of a draggable sheet at [fraction] of the space below the status bar.
double _extentTop(final WidgetTester tester, final double fraction) =>
    _frameBottom(tester) - fraction * _sheetSpace * _scale(tester);

Future<void> _openDraggable(final WidgetTester tester) async {
  await _tapStage(tester, 'open draggable sheet');
  await tester.pump(_step);
}

/// Lets a released draggable sheet snap or close.
Future<void> _settle(final WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_step);
  await tester.pump(_step);
}

Future<void> _openBreakwater(final WidgetTester tester) async {
  await _tapStage(tester, 'open breakwater sheet');
  await tester.pump(_step);
  // The cover reaches the harbor a frame after the sheet settles.
  await tester.pump(_step);
}

/// A barrier that dims the page under a sheet.
Finder _dimmed() => find.byWidgetPredicate((final Widget w) => w is ModalBarrier && (w.color?.a ?? 0) > 0);

/// Raises the tide and waits for a beacon to follow it: it reveals a few
/// frames after the keyboard settles, then scrolls there.
Future<void> _raiseTideForBeacon(final WidgetTester tester) async {
  await _setTide(tester, high: true);
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Where [key] is, even scrolled out of sight.
Rect _offstageRect(final WidgetTester tester, final String key) =>
    tester.getRect(find.byKey(ValueKey<String>(key), skipOffstage: false));

double _headerTitleOpacity(final WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: _key('header title'), matching: find.byType(Opacity)).first).opacity;

/// Opens the breakwater sheet over the lift and waits for the region to ease
/// up: the sheet reports its painted top a frame after it settles.
Future<void> _openLiftSheet(final WidgetTester tester) async {
  await _tapStage(tester, 'open lift sheet');
  await tester.pump(_step);
  await tester.pump(_step);
  await tester.pump(_step);
}

void main() {
  test('the three groups are listed, named as in code', () {
    List<String> names(final GuideGroup group) => floatingEntries
        .where((final GuideEntry e) => e.group == group)
        .map((final GuideEntry e) => e.className)
        .toList();
    expect(names(GuideGroup.floating), <String>[
      'HarborBuoy',
      'HarborBuoy.anchored',
      'HarborBuoy(modal: true)',
      'HarborPortalBuoy',
      'HarborSignals.raise',
    ]);
    expect(names(GuideGroup.sheets), <String>[
      'HarborSheet',
      'HarborSheet.draggable',
      'showHarborSheet(breakwater: true)',
      'showHarborDialog(inheritClearWater:)',
    ]);
    expect(names(GuideGroup.lighthouse), <String>[
      'HarborBeacon(keepInSight:)',
      'HarborBeacon(onObscured:)',
      'HarborLighthouseRegion',
    ]);
  });

  testWidgets('every plate draws', (final WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: <Widget>[for (final GuideEntry e in floatingEntries) Expanded(child: Builder(builder: e.art))],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  // -------------------------------------------------------------------------
  // HarborBuoy

  testWidgets('HarborBuoy: each alignment places the buoy there in the clear water, margin in from its edges', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    const Map<String, Alignment> alignments = <String, Alignment>{
      'topCenter': Alignment.topCenter,
      'topRight': Alignment.topRight,
      'center': Alignment.center,
      'bottomLeft': Alignment.bottomLeft,
      'bottomCenter': Alignment.bottomCenter,
      'bottomRight': Alignment.bottomRight,
    };
    for (final MapEntry<String, Alignment> alignment in alignments.entries) {
      await _tap(tester, 'alignment: ${alignment.key}');
      // The clear water runs from the header down to the tab bar, edge to edge.
      final Rect water = Rect.fromLTRB(
        _frameLeft(tester),
        _headerBottom(tester),
        _frameRight(tester),
        _rect(tester, 'buoy tab bar').top,
      ).deflate(16 * s);
      final Rect buoy = _rect(tester, 'free buoy');
      final Rect expected = alignment.value.inscribe(buoy.size, water);
      expect(buoy.left, _near(expected.left), reason: alignment.key);
      expect(buoy.top, _near(expected.top), reason: alignment.key);
      expect(_code(tester), contains('alignment: Alignment.${alignment.key},'));
    }
  });

  testWidgets('HarborBuoy: margin sets how far the buoy keeps from the tab bar and the edge', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    for (final double margin in <double>[0, 16, 48]) {
      await _slide(tester, 'margin', margin);
      expect(
        _rect(tester, 'free buoy').bottom,
        _near(_rect(tester, 'buoy tab bar').top - margin * s),
        reason: '$margin',
      );
      expect(_rect(tester, 'free buoy').right, _near(_frameRight(tester) - margin * s), reason: '$margin');
      expect(_code(tester), contains('margin: const EdgeInsets.all(${margin.toStringAsFixed(0)}),'));
    }
  });

  testWidgets('HarborBuoy: without the header, the buoy clears only the status bar', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    await _tap(tester, 'alignment: topCenter');
    expect(_rect(tester, 'free buoy').top, _near(_headerBottom(tester) + 16 * s));
    expect(_code(tester), contains('top: [HarborDock.pier(child: Header())],'));

    await _tap(tester, 'toggle header (pier)');
    expect(find.byType(StageHeader), findsNothing);
    expect(_rect(tester, 'free buoy').top, _near(_frameTop(tester) + (62 + 16) * s));
    expect(_code(tester), isNot(contains('HarborDock.pier')));

    await _tap(tester, 'toggle header (pier)');
    expect(_rect(tester, 'free buoy').top, _near(_headerBottom(tester) + 16 * s));
  });

  testWidgets('HarborBuoy: without the tab bar, the buoy clears the home indicator', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    expect(_code(tester), contains('bottom: [HarborDock.quay(child: TabBar())],'));

    await _tap(tester, 'toggle tab bar (quay)');
    expect(_key('buoy tab bar'), findsNothing);
    expect(_rect(tester, 'free buoy').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_code(tester), isNot(contains('HarborDock.quay')));

    await _tap(tester, 'toggle tab bar (quay)');
    expect(_rect(tester, 'free buoy').bottom, _near(_rect(tester, 'buoy tab bar').top - 16 * s));
  });

  testWidgets('HarborBuoy: the keyboard becomes the floor of the clear water at high tide', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    await _setTide(tester, high: true);
    expect(_rect(tester, 'free buoy').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setTide(tester, high: false);
    expect(tester.getRect(find.byType(KeyboardArt)).height, 0);
    expect(_rect(tester, 'free buoy').bottom, _near(_rect(tester, 'buoy tab bar').top - 16 * s));
  });

  // -------------------------------------------------------------------------
  // HarborBuoy.anchored

  testWidgets('HarborBuoy.anchored: by default the bubble sits gap above the dock button, centered on it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    final Rect button = _rect(tester, 'anchor button');
    expect(_rect(tester, 'anchored buoy').bottom, _near(button.top - 8 * s));
    expect(_rect(tester, 'anchored buoy').center.dx, _near(button.center.dx));
    expect(_selected(tester, 'anchor: dock button'), isTrue);
    expect(_code(tester), contains('anchor: launch,'));
    expect(_code(tester), contains('side: HarborBuoySide.above,'));
  });

  testWidgets('HarborBuoy.anchored: each side puts the bubble gap away on that side of the boat', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await _tap(tester, 'anchor: draggable boat');
    expect(_code(tester), contains('anchor: boat,'));
    Rect bubble() => _rect(tester, 'anchored buoy');
    final Rect boat = _rect(tester, 'draggable anchor');

    await _tap(tester, 'side: below');
    expect(bubble().top, _near(boat.bottom + 8 * s));
    expect(bubble().center.dx, _near(boat.center.dx));
    expect(_code(tester), contains('side: HarborBuoySide.below,'));

    await _tap(tester, 'side: start');
    expect(bubble().right, _near(boat.left - 8 * s));
    expect(bubble().center.dy, _near(boat.center.dy));

    await _tap(tester, 'side: end');
    expect(bubble().left, _near(boat.right + 8 * s));
    expect(bubble().center.dy, _near(boat.center.dy));

    await _tap(tester, 'side: above');
    expect(bubble().bottom, _near(boat.top - 8 * s));
    expect(bubble().center.dx, _near(boat.center.dx));
  });

  testWidgets('HarborBuoy.anchored: gap sets the distance from the anchor', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    for (final double gap in <double>[0, 24, 32]) {
      await _slide(tester, 'gap', gap);
      expect(
        _rect(tester, 'anchored buoy').bottom,
        _near(_rect(tester, 'anchor button').top - gap * s),
        reason: '$gap',
      );
      expect(_code(tester), contains('gap: ${gap.toStringAsFixed(0)},'));
    }
  });

  testWidgets('HarborBuoy.anchored: overlap pulls the bubble back over its anchor', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await _slide(tester, 'overlap', 6);
    expect(_rect(tester, 'anchored buoy').bottom, _near(_rect(tester, 'anchor button').top - (8 - 6) * s));
    // Past the gap, the bubble's foot sits over the button.
    await _slide(tester, 'overlap', 20);
    expect(_rect(tester, 'anchored buoy').bottom, _near(_rect(tester, 'anchor button').top + (20 - 8) * s));
    expect(_code(tester), contains('overlap: 20,'));
  });

  testWidgets('HarborBuoy.anchored: dragging the boat anchors the bubble to it; the dock button takes it back', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    final Rect before = _rect(tester, 'draggable anchor');
    await tester.drag(_key('draggable anchor'), const Offset(-20, 60));
    await tester.pump();
    await tester.pump(_step);
    final Rect boat = _rect(tester, 'draggable anchor');
    expect(boat.center.dx, lessThan(before.center.dx));
    expect(boat.center.dy, greaterThan(before.center.dy));
    expect(_selected(tester, 'anchor: draggable boat'), isTrue);
    expect(_rect(tester, 'anchored buoy').bottom, _near(boat.top - 8 * s));
    expect(_rect(tester, 'anchored buoy').center.dx, _near(boat.center.dx));

    await _tapStage(tester, 'anchor button');
    expect(_selected(tester, 'anchor: dock button'), isTrue);
    expect(_rect(tester, 'anchored buoy').bottom, _near(_rect(tester, 'anchor button').top - 8 * s));

    await _tap(tester, 'anchor: draggable boat');
    await _tap(tester, 'anchor: dock button');
    expect(_rect(tester, 'anchored buoy').bottom, _near(_rect(tester, 'anchor button').top - 8 * s));
  });

  testWidgets('HarborBuoy.anchored: dragged into the header, the bubble above it stops margin below the header', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await tester.drag(_key('draggable anchor'), Offset(0, -tester.getRect(_key('stage')).height));
    await tester.pump();
    await tester.pump(_step);
    expect(_rect(tester, 'anchored buoy').top, _near(_rect(tester, 'anchored header').bottom + 8 * s));
    // So it overlaps the boat rather than going under the header.
    expect(_rect(tester, 'anchored buoy').bottom, greaterThan(_rect(tester, 'draggable anchor').top));
  });

  testWidgets('HarborBuoy.anchored: dragged to the left edge, the bubble below it stops margin in from the edge', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await _tap(tester, 'side: below');
    await tester.drag(_key('draggable anchor'), Offset(-tester.getRect(_key('stage')).width, 0));
    await tester.pump();
    await tester.pump(_step);
    final Rect boat = _rect(tester, 'draggable anchor');
    expect(boat.left, _near(_frameLeft(tester)));
    expect(_rect(tester, 'anchored buoy').left, _near(_frameLeft(tester) + 8 * s));
    expect(_rect(tester, 'anchored buoy').top, _near(boat.bottom + 8 * s));
    expect(_rect(tester, 'anchored buoy').center.dx, greaterThan(boat.center.dx));
  });

  // -------------------------------------------------------------------------
  // HarborPortalBuoy

  testWidgets('HarborPortalBuoy: the menu opened from the first row sits gap below it', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _tapStage(tester, 'stage row 0');
    final Rect row = _rect(tester, 'stage row 0');
    expect(_rect(tester, 'portal buoy').top, _near(row.bottom + 8 * s));
    expect(_code(tester), contains('side: HarborBuoySide.below,'));
  });

  testWidgets('HarborPortalBuoy: the menu opened from the last row flips above it, clear of the tab bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _scrollStage(tester, 'portal stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    final Rect row = _rect(tester, 'stage row 11');
    expect(_rect(tester, 'portal buoy').bottom, _near(row.top - 8 * s));
    expect(_rect(tester, 'portal buoy').bottom, _atMost(_rect(tester, 'portal tab bar').top));
  });

  testWidgets('HarborPortalBuoy: with the keyboard up, the menu from the last row in sight flips above the keyboard', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _setTide(tester, high: true);
    await _scrollStage(tester, 'portal stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    final Rect row = _rect(tester, 'stage row 11');
    expect(row.bottom, _atMost(_keyboardTop(tester)));
    expect(_rect(tester, 'portal buoy').bottom, _near(row.top - 8 * s));
    expect(_rect(tester, 'portal buoy').bottom, _atMost(_keyboardTop(tester)));
  });

  testWidgets('HarborPortalBuoy: without flips, the menu below the last row is held clear of the tab bar instead', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle flips');
    expect(_code(tester), contains('flips: false,'));
    await _scrollStage(tester, 'portal stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    expect(_rect(tester, 'portal buoy').bottom, _near(_rect(tester, 'portal tab bar').top - 8 * s));
  });

  // -------------------------------------------------------------------------
  // HarborBuoy(modal: true)

  testWidgets('HarborBuoy(modal: true): hides the buoy listed before it and is centered in the clear water', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    expect(_key('modal buoy'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    final Rect water = Rect.fromLTRB(
      _frameLeft(tester),
      _rect(tester, 'modal header').bottom,
      _frameRight(tester),
      _rect(tester, 'modal tab bar').top,
    );
    expect(_rect(tester, 'modal buoy').center.dy, _near(water.center.dy));
    expect(_rect(tester, 'modal buoy').center.dx, _near(water.center.dx));
    expect(find.text('HarborBuoy(modal: true)'), findsWidgets);
    expect(_code(tester), contains('HarborBuoy(modal: true, onDismiss: close, child: QuickActions()), // a barrier; hides the tooltip'));
  });

  testWidgets('HarborBuoy(modal: true): not modal, both buoys float, the first at the bottom center', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle modal');
    expect(_key('modal buoy'), findsOneWidget);
    expect(_key('listed first'), findsOneWidget);
    expect(_rect(tester, 'listed first').bottom, _near(_rect(tester, 'modal tab bar').top - 16 * s));
    expect(_rect(tester, 'listed first').center.dx, _near((_frameLeft(tester) + _frameRight(tester)) / 2));
    expect(find.text('Not modal: the buoys before me stay up.'), findsOneWidget);
    expect(_code(tester), contains('HarborBuoy(child: QuickActions()), // floats beside it'));

    await _tap(tester, 'toggle modal');
    expect(_key('listed first'), findsNothing);
  });

  testWidgets('HarborBuoy(modal: true): taking the launch down brings the first buoy back', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    await _tap(tester, 'toggle launch up');
    expect(_key('modal buoy'), findsNothing);
    expect(_key('listed first'), findsOneWidget);
    expect(_code(tester), isNot(contains('QuickActions')));

    await _tap(tester, 'toggle launch up');
    expect(_key('modal buoy'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    expect(_code(tester), contains('QuickActions'));
  });

  testWidgets('HarborBuoy(modal: true): Stand down and Call the launch take it down and up again', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    await _tapStage(tester, 'launch away');
    expect(_key('modal buoy'), findsNothing);
    expect(_key('listed first'), findsOneWidget);
    expect(_switchedOn(tester, 'toggle launch up'), isFalse);

    await _tapStage(tester, 'call the launch');
    expect(_key('modal buoy'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    expect(_switchedOn(tester, 'toggle launch up'), isTrue);
  });

  // -------------------------------------------------------------------------
  // HarborSignals.raise

  testWidgets('HarborSignals.raise: each slot lands at its place in the page’s clear water', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    for (final HarborSignalSlot slot in HarborSignalSlot.values) {
      await _tapStage(tester, 'raise ${slot.name}');
      final Rect water = Rect.fromLTRB(
        _frameLeft(tester),
        _headerBottom(tester),
        _frameRight(tester),
        _rect(tester, 'signals tab bar').top,
      ).deflate(16 * s);
      final Rect signal = _rect(tester, 'signal');
      final Rect expected = slot.alignment.inscribe(signal.size, water);
      expect(signal.top, _near(expected.top), reason: slot.name);
      expect(signal.center.dx, _near(expected.center.dx), reason: slot.name);
      expect(find.text('${slot.name} · topmost'), findsOneWidget);
      expect(_code(tester), contains('slot: HarborSignalSlot.${slot.name},'));
      expect(_code(tester), contains('target: HarborSignalTarget.topmost,'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(_step);
    }
  });

  testWidgets('HarborSignals.raise: a signal is lowered after three seconds', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('signals'));
    await _tapStage(tester, 'raise middle');
    await tester.pump(const Duration(seconds: 2));
    expect(_key('signal'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(_step);
    expect(_key('signal'), findsNothing);
  });

  testWidgets('HarborSignals.raise: sent to the sea, it clears only the coast, over the header and tab bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tap(tester, 'target: sea');
    expect(_code(tester), contains('target: HarborSignalTarget.sea,'));

    await _tapStage(tester, 'raise top');
    expect(_rect(tester, 'signal').top, _near(_frameTop(tester) + (62 + 16) * s));
    expect(_rect(tester, 'signal').top, lessThan(_headerBottom(tester)));
    expect(find.text('top · sea'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);

    await _tapStage(tester, 'raise low');
    expect(_rect(tester, 'signal').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_rect(tester, 'signal').bottom, greaterThan(_rect(tester, 'signals tab bar').top));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
  });

  testWidgets('HarborSignals.raise: raised from a sheet, topmost lands in the sheet’s clear water', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open signals sheet');
    await tester.pump(_step);

    // Below the sheet's header and its 12-point wake.
    await _tapStage(tester, 'sheet raise top');
    expect(_rect(tester, 'signal').top, _near(_rect(tester, 'signals sheet header').bottom + (12 + 16) * s));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);

    // Above the footer's dock, which starts 10 above its marker.
    await _tapStage(tester, 'sheet raise low');
    expect(_rect(tester, 'signal').bottom, _near(_rect(tester, 'signals sheet footer').top - (10 + 16) * s));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
    await _popStage(tester, 'signals sheet header');
  });

  testWidgets('HarborSignals.raise: raised from a sheet to the sea, it lands over the sheet’s footer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tap(tester, 'target: sea');
    await _tapStage(tester, 'open signals sheet');
    await tester.pump(_step);
    await _tapStage(tester, 'sheet raise low');
    expect(_rect(tester, 'signal').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_rect(tester, 'signal').bottom, greaterThan(_rect(tester, 'signals sheet footer').top));
    expect(find.text('low · sea'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
    await _popStage(tester, 'signals sheet header');
  });

  // -------------------------------------------------------------------------
  // HarborSheet

  testWidgets('HarborSheet: opens inside the stage as tall as its content, its footer clear of the home indicator', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    expect(_key('sheet header'), findsNothing);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    final Rect sheet = tester.getRect(find.byType(HarborSheet));
    expect(sheet.bottom, _near(_frameBottom(tester)));
    expect(sheet.top, _near(_rect(tester, 'sheet header').top));
    expect(_rect(tester, 'sheet footer').bottom, _near(_frameBottom(tester) - 34 * s));
    expect(_rect(tester, 'sheet body').top, _atLeast(_rect(tester, 'sheet header').bottom));
    expect(_rect(tester, 'sheet body').bottom, _atMost(_rect(tester, 'sheet footer').top));
    // Three rows tall.
    expect(_rect(tester, 'sheet body').height, _near(3 * 56 * s));
    expect(_code(tester), contains("header: SheetHeader(title: 'HarborSheet'),"));
    expect(_code(tester), contains('footer: MakeSailButton(),'));
  });

  testWidgets(
    'HarborSheet: with a header, the body ends at the footer, with no empty band between them',
    (final WidgetTester tester) async {
      await _pumpEntry(tester, _page('sheet'));
      final double s = _scale(tester);
      await _tapStage(tester, 'open sheet');
      await tester.pump(_step);
      // The footer's dock starts 12 above its button.
      expect(_rect(tester, 'sheet body').bottom, _near(_rect(tester, 'sheet footer').top - 12 * s));
      await _popStage(tester, 'sheet footer');
    },
  );

  testWidgets('HarborSheet: its footer’s Make sail closes it', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet'));
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _tapStage(tester, 'sheet footer');
    await tester.pump(_step);
    expect(_key('sheet header'), findsNothing);
  });

  testWidgets('HarborSheet: the header toggle rebuilds the open sheet with and without its header', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    final Rect header = _rect(tester, 'sheet header');
    final double bodyTop = _rect(tester, 'sheet body').top;
    await _tap(tester, 'toggle header');
    expect(_key('sheet header'), findsNothing);
    // The body now starts at the sheet's top, and the sheet is shorter by
    // just the header and its wake: the rows stay where they were.
    expect(tester.getRect(find.byType(HarborSheet)).top, _near(_rect(tester, 'sheet body').top));
    expect(tester.getRect(find.byType(HarborSheet)).top, greaterThan(header.top));
    expect(_rect(tester, 'sheet body').top, _near(bodyTop));
    expect(_code(tester), isNot(contains('SheetHeader')));

    await _tap(tester, 'toggle header');
    expect(_key('sheet header'), findsOneWidget);
    expect(_code(tester), contains('SheetHeader'));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: without its footer, the body itself clears the home indicator', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _tap(tester, 'toggle footer');
    expect(_key('sheet footer'), findsNothing);
    expect(_rect(tester, 'sheet body').bottom, _atMost(_frameBottom(tester) - 34 * s));
    expect(_code(tester), isNot(contains('MakeSailButton')));

    await _tap(tester, 'toggle footer');
    expect(_key('sheet footer'), findsOneWidget);
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: footerTide float rides the keyboard, footerMinimum above it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    expect(_selected(tester, 'footerTide: float'), isTrue);
    await _setTide(tester, high: true);
    await tester.pump(_step);
    expect(_rect(tester, 'sheet footer').bottom, _near(_keyboardTop(tester) - 16 * s));
    expect(_rect(tester, 'sheet header').top, _atLeast(_frameTop(tester) + 62 * s));
    await _setTide(tester, high: false);
    expect(_rect(tester, 'sheet footer').bottom, _near(_frameBottom(tester) - 34 * s));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: footerTide pilings stays put and the keyboard covers it; the body stays above', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _tap(tester, 'footerTide: pilings');
    expect(_code(tester), contains('footerTide: HarborTideStance.pilings,'));
    final Rect low = _rect(tester, 'sheet footer');
    await _setTide(tester, high: true);
    await tester.pump(_step);
    expect(_rect(tester, 'sheet footer').top, _near(low.top));
    expect(_rect(tester, 'sheet footer').top, greaterThan(_keyboardTop(tester)));
    expect(_rect(tester, 'sheet body').bottom, _atMost(_keyboardTop(tester)));
    await _setTide(tester, high: false);
    expect(_rect(tester, 'sheet footer').top, _near(low.top));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: footerTide dryDock holds the keyboard\'s ground with a tray the keyboard takes over', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _tap(tester, 'footerTide: dryDock');
    expect(_code(tester), contains('footerTide: HarborTideStance.dryDock,'));
    expect(_code(tester), contains('HarborDryDock(child: FlagTray())'));
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('dryDock:'));
    // The tray runs to the screen's edge: no coast and no minimum under it.
    expect(_rect(tester, 'flag tray').bottom, _near(_frameBottom(tester)));
    // Once the keyboard has been up, the tray is exactly its height.
    await _setTide(tester, high: true);
    await tester.pump(_step);
    await _setTide(tester, high: false);
    await tester.pump(_step);
    final Rect tray = _rect(tester, 'flag tray');
    final Rect button = _rect(tester, 'sheet footer');
    expect(button.bottom, _atMost(tray.top));

    await _setTide(tester, high: true);
    await tester.pump(_step);
    expect(tray.top, _near(_keyboardTop(tester)), reason: 'the keyboard covers the tray exactly');
    expect(_rect(tester, 'sheet footer').top, _near(button.top), reason: 'the button above it holds still');
    expect(_rect(tester, 'sheet body').bottom, _atMost(button.top));
    await _setTide(tester, high: false);
    await tester.pump(_step);
    expect(_rect(tester, 'sheet footer').top, _near(button.top));
    expect(_rect(tester, 'flag tray').top, _near(tray.top));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: the hint says what to look for at each footerTide', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet'));
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('float:'));
    await _tap(tester, 'footerTide: pilings');
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('pilings:'));
    expect(_key('flag tray'), findsNothing);
    await _tap(tester, 'footerTide: dryDock');
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('dryDock:'));
  });

  testWidgets('HarborSheet: rows sets how tall the body is, and the sheet grows with it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    final double threeRowsTop = tester.getRect(find.byType(HarborSheet)).top;
    for (final int rows in <int>[1, 8]) {
      await _slide(tester, 'rows', rows.toDouble());
      expect(_rect(tester, 'sheet body').height, _near(rows * 56 * s), reason: '$rows');
      expect(_key('stage row ${rows - 1}'), findsOneWidget);
      expect(_key('stage row $rows'), findsNothing);
      expect(tester.getRect(find.byType(HarborSheet)).top, _near(threeRowsTop - (rows - 3) * 56 * s), reason: '$rows');
      expect(_code(tester), contains('child: ${rows}Rows()'));
    }
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: maxExtent caps the sheet’s share of the space above the keyboard; the body scrolls', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _slide(tester, 'rows', 16);
    double height() => tester.getRect(find.byType(HarborSheet)).height;
    expect(height(), _near(0.9 * _sheetSpace * s));
    final ScrollPosition body = tester
        .state<ScrollableState>(find.ancestor(of: _key('sheet body'), matching: find.byType(Scrollable)).first)
        .position;
    expect(body.maxScrollExtent, greaterThan(0));

    await _slide(tester, 'maxExtent %', 50);
    expect(height(), _near(0.5 * _sheetSpace * s));
    expect(_code(tester), contains('maxExtentFraction: 0.50,'));

    // With the keyboard up, it is half of what is left above the keyboard.
    await _setTide(tester, high: true);
    await tester.pump(_step);
    expect(_keyboardTop(tester) - tester.getRect(find.byType(HarborSheet)).top, _near(0.5 * (_sheetSpace - 336) * s));
    await _setTide(tester, high: false);
    await _popStage(tester, 'sheet footer');
  });

  // -------------------------------------------------------------------------
  // HarborSheet.draggable

  testWidgets('HarborSheet.draggable: opens at its rest height', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.5)));
    expect(_code(tester), contains('extent: const HarborSheetExtent(rest: 0.50, max: 0.88, min: 0.25),'));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: dragged up by its header, it stops at max', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    await tester.drag(_key('drag header'), Offset(0, -tester.getRect(_key('stage')).height));
    await _settle(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.88)));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: dragging its list drags the sheet up to max', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    await tester.drag(_key('stage row 1'), Offset(0, -tester.getRect(_key('stage')).height));
    await _settle(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.88)));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: let go above min, it snaps back to rest', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    // Slowly, so it is not a fling: down to about 0.35.
    await tester.timedDrag(
      _key('drag header'),
      Offset(0, 0.15 * _sheetSpace * _scale(tester)),
      const Duration(seconds: 1),
    );
    await _settle(tester);
    expect(_key('drag header'), findsOneWidget);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.5)));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: dragged below min, it closes', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    await tester.timedDrag(
      _key('drag header'),
      Offset(0, 0.4 * _sheetSpace * _scale(tester)),
      const Duration(seconds: 1),
    );
    await _settle(tester);
    expect(_key('drag header'), findsNothing);
  });

  testWidgets('HarborSheet.draggable: rest sets where it opens', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _slide(tester, 'rest %', 30);
    expect(_code(tester), contains('rest: 0.30,'));
    await _openDraggable(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.3)));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: max sets how high it drags', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _slide(tester, 'max %', 70);
    expect(_code(tester), contains('max: 0.70,'));
    await _openDraggable(tester);
    await tester.drag(_key('drag header'), Offset(0, -tester.getRect(_key('stage')).height));
    await _settle(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.7)));
    await _popStage(tester, 'drag header');
  });

  testWidgets('HarborSheet.draggable: min sets how far down it can go before it closes', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _slide(tester, 'min %', 40);
    expect(_code(tester), contains('min: 0.40'));
    await _openDraggable(tester);
    // The same drag that snaps back to rest with min at 0.25 now closes it.
    await tester.timedDrag(
      _key('drag header'),
      Offset(0, 0.15 * _sheetSpace * _scale(tester)),
      const Duration(seconds: 1),
    );
    await _settle(tester);
    expect(_key('drag header'), findsNothing);
  });

  testWidgets('HarborSheet.draggable: the sliders keep min ≤ rest and rest 5 below max', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _slide(tester, 'rest %', 85);
    expect(_code(tester), contains('HarborSheetExtent(rest: 0.85, max: 0.90, min: 0.25)'));
    await _slide(tester, 'min %', 60);
    expect(_code(tester), contains('HarborSheetExtent(rest: 0.85, max: 0.90, min: 0.60)'));
    await _slide(tester, 'max %', 30);
    expect(_code(tester), contains('HarborSheetExtent(rest: 0.25, max: 0.30, min: 0.25)'));
    await _slide(tester, 'min %', 50);
    expect(_code(tester), contains('HarborSheetExtent(rest: 0.50, max: 0.55, min: 0.50)'));
    expect(find.text('rest % 50'), findsOneWidget);
    expect(find.text('max % 55'), findsOneWidget);
    expect(find.text('min % 50'), findsOneWidget);
  });

  testWidgets('HarborSheet.draggable: heights are taken when it is hoisted', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('sheet-draggable'));
    await _openDraggable(tester);
    await _slide(tester, 'rest %', 30);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.5)));
    await _popStage(tester, 'drag header');
    await _openDraggable(tester);
    expect(_rect(tester, 'drag header').top, _near(_extentTop(tester, 0.3)));
    await _popStage(tester, 'drag header');
  });

  // -------------------------------------------------------------------------
  // showHarborSheet(breakwater: true)

  testWidgets('showHarborSheet(breakwater: true): the list’s last row comes to rest above the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    expect(_code(tester), contains('breakwater: true,'));
    await _openBreakwater(tester);
    expect(find.textContaining('breakwater: true. Scroll the list'), findsOneWidget);
    await _scrollStage(tester, 'breakwater list', double.infinity);
    expect(_rect(tester, 'stage row 13').bottom, _near(_rect(tester, 'breakwater sheet header').top));
    await _popStage(tester, 'breakwater sheet header');
  });

  testWidgets('showHarborSheet(breakwater: false): the list’s last row stays under the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle breakwater');
    expect(_code(tester), contains('breakwater: false,'));
    await _openBreakwater(tester);
    expect(find.textContaining('breakwater: false. Scroll the list'), findsOneWidget);
    await _scrollStage(tester, 'breakwater list', double.infinity);
    // The list ends at the home indicator, as if the sheet weren't there.
    expect(_rect(tester, 'stage row 13').bottom, _near(_frameBottom(tester) - 34 * s));
    expect(_rect(tester, 'stage row 13').bottom, greaterThan(_rect(tester, 'breakwater sheet header').top));
    await _popStage(tester, 'breakwater sheet header');
  });

  testWidgets('showHarborSheet(barrier: none): the page stays live under the sheet, undimmed', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    expect(_selected(tester, 'barrier: none'), isTrue);
    expect(_code(tester), contains('barrier: HarborSheetBarrier.none,'));
    await _openBreakwater(tester);
    expect(_dimmed(), findsNothing);
    await tester.drag(_key('stage row 1'), const Offset(0, -80));
    await tester.pump();
    await tester.pump(_step);
    expect(_stageScroll(tester, 'breakwater list').pixels, greaterThan(0));
    expect(_key('breakwater sheet header'), findsOneWidget);
    await _popStage(tester, 'breakwater sheet header');
  });

  testWidgets('showHarborSheet(barrier: dismissible): dims the page, and a tap on it closes the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    await _tap(tester, 'barrier: dismissible');
    expect(_code(tester), contains('barrier: HarborSheetBarrier.dismissible,'));
    await _openBreakwater(tester);
    expect(_dimmed(), findsOneWidget);
    // The barrier takes the tap, not the row under it.
    await tester.tapAt(tester.getCenter(_key('stage row 1')));
    await tester.pump();
    await tester.pump(_step);
    await tester.pump(_step);
    expect(_key('breakwater sheet header'), findsNothing);
    expect(_dimmed(), findsNothing);
  });

  testWidgets('showHarborSheet(barrier: clear): leaves the page undimmed, and a tap on it closes the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    await _tap(tester, 'barrier: clear');
    expect(_code(tester), contains('barrier: HarborSheetBarrier.clear,'));
    await _openBreakwater(tester);
    expect(_dimmed(), findsNothing);
    // The barrier takes the tap, not the row under it.
    await tester.tapAt(tester.getCenter(_key('stage row 1')));
    await tester.pump();
    await tester.pump(_step);
    await tester.pump(_step);
    expect(_key('breakwater sheet header'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // showHarborDialog(inheritClearWater:)

  testWidgets('showHarborDialog(inheritClearWater: true): stays between the header and the composer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('dialog'));
    final double s = _scale(tester);
    expect(_code(tester), contains('inheritClearWater: true,'));
    await _tapStage(tester, 'open dialog');
    expect(_rect(tester, 'call box').top, _near(_rect(tester, 'office header').bottom + 10 * s));
    expect(_rect(tester, 'call box').bottom, _near(_rect(tester, 'office footer').top - 10 * s));
    await _tapStage(tester, 'over and out');
    expect(_key('call box'), findsNothing);
  });

  testWidgets('showHarborDialog(inheritClearWater: false): sees only the coast, covering the header and composer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('dialog'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle inheritClearWater');
    expect(_code(tester), contains('inheritClearWater: false,'));
    await _tapStage(tester, 'open dialog');
    expect(_rect(tester, 'call box').top, _near(_frameTop(tester) + (62 + 10) * s));
    expect(_rect(tester, 'call box').bottom, _near(_frameBottom(tester) - (34 + 10) * s));
    await _tapStage(tester, 'over and out');
    expect(_key('call box'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // HarborBeacon(keepInSight:)

  testWidgets('HarborBeacon(keepInSight:): tapping the field focuses it', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    expect(find.text('Tap me, then raise the tide'), findsOneWidget);
    await _tapStage(tester, 'beacon field');
    expect(find.text('HarborBeacon field'), findsOneWidget);
  });

  testWidgets('HarborBeacon(keepInSight:): the focused field is kept clearance above the rising keyboard', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    expect(_code(tester), contains('keepInSight: true,'));
    await _tapStage(tester, 'beacon field');
    await _raiseTideForBeacon(tester);
    expect(_stageScroll(tester, 'reveal fairway').pixels, greaterThan(0));
    expect(_rect(tester, 'beacon field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setTide(tester, high: false);
  });

  testWidgets('HarborBeacon(keepInSight:): clearance sets how far above the keyboard the field is kept', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _slide(tester, 'clearance', 40);
    expect(_code(tester), contains('clearance: 40,'));
    expect(_code(tester), contains('HarborLighthouse.reveal(fieldContext, clearance: 40);'));
    await _tapStage(tester, 'beacon field');
    await _raiseTideForBeacon(tester);
    expect(_rect(tester, 'beacon field').bottom, _near(_keyboardTop(tester) - 40 * s));
    await _setTide(tester, high: false);
  });

  testWidgets('HarborBeacon(keepInSight: false): the field is left under the keyboard until reveal', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle keepInSight');
    expect(_code(tester), contains('keepInSight: false,'));
    await _tapStage(tester, 'beacon field');
    await _raiseTideForBeacon(tester);
    expect(_stageScroll(tester, 'reveal fairway').pixels, 0);
    expect(_offstageRect(tester, 'beacon field').top, greaterThan(_keyboardTop(tester)));

    // Revealed by hand, with the same clearance.
    await _tapStage(tester, 'reveal');
    await tester.pump(_step);
    expect(_rect(tester, 'beacon field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setTide(tester, high: false);
  });

  testWidgets('HarborBeacon(onlyWhileFocused: true): a field without focus is not brought into sight', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    expect(_code(tester), contains('onlyWhileFocused: true,'));
    await _raiseTideForBeacon(tester);
    expect(_stageScroll(tester, 'reveal fairway').pixels, 0);
    expect(_offstageRect(tester, 'beacon field').top, greaterThan(_keyboardTop(tester)));
    await _setTide(tester, high: false);
  });

  testWidgets('HarborBeacon(onlyWhileFocused: false): the field is brought into sight with or without focus', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle onlyWhileFocused');
    expect(_code(tester), contains('onlyWhileFocused: false,'));
    expect(find.text('Tap me, then raise the tide'), findsOneWidget);
    await _raiseTideForBeacon(tester);
    expect(_rect(tester, 'beacon field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setTide(tester, high: false);
  });

  // -------------------------------------------------------------------------
  // HarborBeacon(onObscured:)

  testWidgets('HarborBeacon(onObscured:): in clear water it reports 0 and the header title is hidden', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    expect(_rect(tester, 'hero title').top, greaterThan(_rect(tester, 'obscured header').bottom));
    // Both readouts: in the header and in the controls.
    expect(find.text('covered 0%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 0);
  });

  testWidgets('HarborBeacon(onObscured:): half under the header, it reports how much is covered', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    final double s = _scale(tester);
    await _scrollStage(tester, 'hero fairway', 150);
    final Rect title = _rect(tester, 'hero title');
    // The clear water starts below the header's 12-point wake.
    final double covered = (_rect(tester, 'obscured header').bottom + 12 * s - title.top) / title.height;
    expect(covered, inExclusiveRange(0.1, 0.99));
    expect(_textOf(tester, 'covered readout'), 'covered ${(covered * 100).round()}%');
    expect(find.text('covered ${(covered * 100).round()}%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), moreOrLessEquals(covered, epsilon: 0.02));
  });

  testWidgets('HarborBeacon(onObscured:): fully under the header, it reports 100% and hands off the title', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    await _scrollStage(tester, 'hero fairway', 280);
    expect(_rect(tester, 'hero title').bottom, _atMost(_rect(tester, 'obscured header').bottom));
    expect(find.text('covered 100%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 1);

    await _scrollStage(tester, 'hero fairway', 0);
    expect(find.text('covered 0%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 0);
  });

  testWidgets('HarborBeacon(onObscured:): startsInOpenWater runs the hero under the header; off, it starts below', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    final double s = _scale(tester);
    // The title sits 16 above the bottom of the 300-point hero.
    expect(_rect(tester, 'hero title').bottom, _near(_frameTop(tester) + (300 - 16) * s));
    expect(_code(tester), contains('startsInOpenWater: true,'));

    await _tap(tester, 'toggle startsInOpenWater');
    expect(_code(tester), contains('startsInOpenWater: false,'));
    expect(_rect(tester, 'hero title').bottom, _near(_rect(tester, 'obscured header').bottom + (12 + 300 - 16) * s));
    expect(find.text('covered 0%'), findsNWidgets(2));
  });

  // -------------------------------------------------------------------------
  // HarborLighthouseRegion

  testWidgets('HarborLighthouseRegion: at rest it already lifts the boat clearance clear of the home indicator', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    // Placed 60 up, it needs 34 + 40: lifted 14.
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - (34 + 40) * s));
    expect(_code(tester), contains('lift: true,'));
  });

  testWidgets('HarborLighthouseRegion: lifts the boat clearance clear of a breakwater sheet, and back down', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    final double restingBottom = _rect(tester, 'lift boat').bottom;
    await _openLiftSheet(tester);
    final double sheetTop = _rect(tester, 'lift sheet header').top;
    expect(restingBottom, greaterThan(sheetTop));
    expect(_rect(tester, 'lift boat').bottom, _near(sheetTop - 40 * s));
    await _popStage(tester, 'lift sheet header');
    await tester.pump(_step);
    expect(_rect(tester, 'lift boat').bottom, _near(restingBottom));
  });

  testWidgets('HarborLighthouseRegion: without lift, the boat sits where it is placed, under the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle lift');
    // The region eases there from the frame after it measures.
    await tester.pump(_step);
    expect(_code(tester), contains('lift: false,'));
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - 60 * s));
    await _openLiftSheet(tester);
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - 60 * s));
    expect(_rect(tester, 'lift boat').bottom, greaterThan(_rect(tester, 'lift sheet header').top));
    await _popStage(tester, 'lift sheet header');
  });

  testWidgets('HarborLighthouseRegion: clearance sets how far clear the boat is lifted', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    // With no clearance, 60 up already clears the home indicator: no lift.
    await _slide(tester, 'clearance', 0);
    await tester.pump(_step);
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - 60 * s));

    await _slide(tester, 'clearance', 120);
    await tester.pump(_step);
    expect(_code(tester), contains('clearance: 120,'));
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - (34 + 120) * s));
    await _openLiftSheet(tester);
    expect(_rect(tester, 'lift boat').bottom, _near(_rect(tester, 'lift sheet header').top - 120 * s));
    await _popStage(tester, 'lift sheet header');
  });

  testWidgets('HarborLighthouseRegion: holdPosition keeps the boat where it is until it is let go', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    final double restingBottom = _rect(tester, 'lift boat').bottom;
    await _tap(tester, 'toggle holdPosition');
    expect(_code(tester), contains('holdPosition: true,'));
    await _openLiftSheet(tester);
    expect(_rect(tester, 'lift boat').bottom, _near(restingBottom));
    expect(restingBottom, greaterThan(_rect(tester, 'lift sheet header').top));

    await _tap(tester, 'toggle holdPosition');
    await tester.pump(_step);
    expect(_rect(tester, 'lift boat').bottom, _near(_rect(tester, 'lift sheet header').top - 40 * s));
    await _popStage(tester, 'lift sheet header');
  });
}
