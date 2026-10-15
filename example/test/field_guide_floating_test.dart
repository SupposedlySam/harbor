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

/// Pumps [entry]; unless [wholePhone] is false, the stage then shows the whole
/// phone whatever the page's own focus.
Future<void> _pumpEntry(final WidgetTester tester, final Widget entry, {final bool wholePhone = true}) async {
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
  if (wholePhone) {
    await _wholePhone(tester);
  }
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

Future<void> _setKeyboard(final WidgetTester tester, {required final bool shown}) async {
  final IconButton button = tester.widget<IconButton>(_key('tide toggle'));
  // The button offers to hide the keyboard while it is shown.
  final bool isShown = (button.icon as Icon).icon == Icons.keyboard_hide_rounded;
  if (isShown != shown) {
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

/// Expects [key] to be drawn inside the stage's view, not cut off past it.
void _expectInView(final WidgetTester tester, final String key) {
  final Rect view = tester.getRect(_key('stage'));
  final Rect rect = _rect(tester, key);
  expect(rect.top, greaterThanOrEqualTo(view.top - 0.6), reason: '$key top');
  expect(rect.bottom, lessThanOrEqualTo(view.bottom + 0.6), reason: '$key bottom');
}

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

Future<void> _openCoversPage(final WidgetTester tester) async {
  await _tapStage(tester, 'open coversPage sheet');
  await tester.pump(_step);
  // The cover reaches the frame a drawn frame after the sheet settles.
  await tester.pump(_step);
}

/// A barrier that dims the page under a sheet.
Finder _dimmed() => find.byWidgetPredicate((final Widget w) => w is ModalBarrier && (w.color?.a ?? 0) > 0);

/// Shows the keyboard and waits for HarborKeepVisible to follow it: it reveals
/// a few frames after the keyboard settles, then scrolls there.
Future<void> _showKeyboardForKeepInSight(final WidgetTester tester) async {
  await _setKeyboard(tester, shown: true);
  for (int i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Where [key] is, even scrolled out of sight.
Rect _offstageRect(final WidgetTester tester, final String key) =>
    tester.getRect(find.byKey(ValueKey<String>(key), skipOffstage: false));

double _headerTitleOpacity(final WidgetTester tester) =>
    tester.widget<Opacity>(find.ancestor(of: _key('header title'), matching: find.byType(Opacity)).first).opacity;

/// Opens the coversPage sheet over the lift and waits for the region to ease
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
      'HarborFloat',
      'HarborFloat + HarborAnchored',
      'HarborFloat(modal: true)',
      'HarborPopover',
      'HarborToasts.show',
    ]);
    expect(names(GuideGroup.sheets), <String>[
      'HarborSheet',
      'HarborSheet.draggable',
      'showHarborSheet(coversPage: true)',
      'showHarborDialog(inheritRoom:)',
    ]);
    expect(names(GuideGroup.lighthouse), <String>[
      'HarborKeepVisible',
      'HarborCoverageListener',
      'HarborKeepVisibleRegion',
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
  // What each page shows of the phone

  // Under each page's own focus, what opens or shows a thing on the stage is in view, and so is
  // every part of the phone the thing's behaviour moves.
  for (final (String id, List<String> keys) page in <(String, List<String>)>[
    ('buoy', <String>['free float', 'float tab bar']),
    ('buoy-anchored', <String>['anchor button', 'anchored float', 'anchored header', 'draggable anchor']),
    ('buoy-modal', <String>['call the launch', 'modal float', 'modal header', 'modal tab bar']),
    ('buoy-portal', <String>['stage row 0', 'popover tab bar']),
    ('signals', <String>['show top', 'show low', 'open toasts sheet', 'toasts tab bar']),
    ('sheet', <String>['open sheet']),
    ('sheet-draggable', <String>['open draggable sheet']),
    ('sheet-breakwater', <String>['open coversPage sheet']),
    ('dialog', <String>['open dialog', 'office header', 'office footer']),
    ('lighthouse-reveal', <String>['reveal', 'reveal header', 'kept field']),
    ('beacon-obscured', <String>['obscured header', 'header title', 'covered readout', 'hero title']),
    ('lighthouse-region', <String>['open lift sheet', 'lift boat']),
  ]) {
    testWidgets('${page.$1}: under the page’s own focus, ${page.$2.join(', ')} are in view', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, _page(page.$1), wholePhone: false);
      for (final String key in page.$2) {
        _expectInView(tester, key);
      }
    });
  }

  testWidgets('HarborSheet: under the page’s own focus, the tallest sheet is in view, header to footer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'), wholePhone: false);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _slide(tester, 'rows', 16);
    await _slide(tester, 'maxExtent %', 100);
    _expectInView(tester, 'sheet header');
    _expectInView(tester, 'sheet footer');
    await _popStage(tester, 'sheet footer');
  });

  testWidgets(
    'HarborKeepVisible: under the page’s own focus, reveal, the field and the keyboard are in view',
    (final WidgetTester tester) async {
      await _pumpEntry(tester, _page('lighthouse-reveal'), wholePhone: false);
      await _tapStage(tester, 'kept field');
      await _showKeyboardForKeepInSight(tester);
      _expectInView(tester, 'reveal');
      _expectInView(tester, 'kept field');
      expect(_keyboardTop(tester), lessThan(tester.getRect(_key('stage')).bottom));
    },
  );

  testWidgets('HarborKeepVisibleRegion: under the page’s own focus, the open sheet and the lifted boat are in view', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'), wholePhone: false);
    await _openLiftSheet(tester);
    _expectInView(tester, 'open lift sheet');
    _expectInView(tester, 'lift sheet header');
    _expectInView(tester, 'lift boat');
  });

  testWidgets('showHarborSheet(coversPage: true): under the page’s own focus, the button and the sheet are in view', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'), wholePhone: false);
    await _openCoversPage(tester);
    _expectInView(tester, 'open coversPage sheet');
    _expectInView(tester, 'coversPage sheet header');
  });

  // -------------------------------------------------------------------------
  // HarborFloat

  testWidgets('HarborFloat: each alignment places the float there in the room, margin in from its edges', (
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
      // The room runs from the header down to the tab bar, edge to edge.
      final Rect room = Rect.fromLTRB(
        _frameLeft(tester),
        _headerBottom(tester),
        _frameRight(tester),
        _rect(tester, 'float tab bar').top,
      ).deflate(16 * s);
      final Rect buoy = _rect(tester, 'free float');
      final Rect expected = alignment.value.inscribe(buoy.size, room);
      expect(buoy.left, _near(expected.left), reason: alignment.key);
      expect(buoy.top, _near(expected.top), reason: alignment.key);
      expect(_code(tester), contains('alignment: Alignment.${alignment.key},'));
    }
  });

  testWidgets('HarborFloat: margin sets how far the float keeps from the tab bar and the edge', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    for (final double margin in <double>[0, 16, 48]) {
      await _slide(tester, 'margin', margin);
      expect(
        _rect(tester, 'free float').bottom,
        _near(_rect(tester, 'float tab bar').top - margin * s),
        reason: '$margin',
      );
      expect(_rect(tester, 'free float').right, _near(_frameRight(tester) - margin * s), reason: '$margin');
      expect(_code(tester), contains('margin: const EdgeInsets.all(${margin.toStringAsFixed(0)}),'));
    }
  });

  testWidgets('HarborFloat: without the header, the float clears only the status bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    await _tap(tester, 'alignment: topCenter');
    expect(_rect(tester, 'free float').top, _near(_headerBottom(tester) + 16 * s));
    expect(_code(tester), contains('top: [HarborBar.overlay(child: Header())],'));

    await _tap(tester, 'toggle header (overlay)');
    expect(find.byType(StageHeader), findsNothing);
    expect(_rect(tester, 'free float').top, _near(_frameTop(tester) + (62 + 16) * s));
    expect(_code(tester), isNot(contains('HarborBar.overlay')));

    await _tap(tester, 'toggle header (overlay)');
    expect(_rect(tester, 'free float').top, _near(_headerBottom(tester) + 16 * s));
  });

  testWidgets('HarborFloat: without the tab bar, the float clears the home indicator', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    expect(_code(tester), contains('bottom: [HarborBar.solid(child: TabBar())],'));

    await _tap(tester, 'toggle tab bar (solid)');
    expect(_key('float tab bar'), findsNothing);
    expect(_rect(tester, 'free float').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_code(tester), isNot(contains('HarborBar.solid')));

    await _tap(tester, 'toggle tab bar (solid)');
    expect(_rect(tester, 'free float').bottom, _near(_rect(tester, 'float tab bar').top - 16 * s));
  });

  testWidgets('HarborFloat: the keyboard becomes the floor of the room while it is shown', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy'));
    final double s = _scale(tester);
    await _setKeyboard(tester, shown: true);
    expect(_rect(tester, 'free float').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setKeyboard(tester, shown: false);
    expect(tester.getRect(find.byType(KeyboardArt)).height, 0);
    expect(_rect(tester, 'free float').bottom, _near(_rect(tester, 'float tab bar').top - 16 * s));
  });

  // -------------------------------------------------------------------------
  // HarborFloat + HarborAnchored

  testWidgets('HarborAnchored: by default the bubble sits gap above the bar button, centered on it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    final Rect button = _rect(tester, 'anchor button');
    expect(_rect(tester, 'anchored float').bottom, _near(button.top - 8 * s));
    expect(_rect(tester, 'anchored float').center.dx, _near(button.center.dx));
    expect(_selected(tester, 'anchor: bar button'), isTrue);
    expect(_code(tester), contains('HarborAnchored(\n        launch,'));
    expect(_code(tester), contains('side: HarborAnchorSide.above,'));
  });

  testWidgets('HarborAnchored: each side puts the bubble gap away on that side of the boat', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await _tap(tester, 'anchor: draggable boat');
    expect(_code(tester), contains('HarborAnchored(\n        boat,'));
    Rect bubble() => _rect(tester, 'anchored float');
    final Rect boat = _rect(tester, 'draggable anchor');

    await _tap(tester, 'side: below');
    expect(bubble().top, _near(boat.bottom + 8 * s));
    expect(bubble().center.dx, _near(boat.center.dx));
    expect(_code(tester), contains('side: HarborAnchorSide.below,'));

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

  testWidgets('HarborAnchored: gap sets the distance from the anchor', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    for (final double gap in <double>[0, 24, 32]) {
      await _slide(tester, 'gap', gap);
      expect(
        _rect(tester, 'anchored float').bottom,
        _near(_rect(tester, 'anchor button').top - gap * s),
        reason: '$gap',
      );
      expect(_code(tester), contains('gap: ${gap.toStringAsFixed(0)},'));
    }
  });

  testWidgets('HarborAnchored: overlap pulls the bubble back over its anchor', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await _slide(tester, 'overlap', 6);
    expect(_rect(tester, 'anchored float').bottom, _near(_rect(tester, 'anchor button').top - (8 - 6) * s));
    // Past the gap, the bubble's foot sits over the button.
    await _slide(tester, 'overlap', 20);
    expect(_rect(tester, 'anchored float').bottom, _near(_rect(tester, 'anchor button').top + (20 - 8) * s));
    expect(_code(tester), contains('overlap: 20,'));
  });

  testWidgets('HarborAnchored: dragging the boat anchors the bubble to it; the bar button takes it back', (
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
    expect(_rect(tester, 'anchored float').bottom, _near(boat.top - 8 * s));
    expect(_rect(tester, 'anchored float').center.dx, _near(boat.center.dx));

    await _tapStage(tester, 'anchor button');
    expect(_selected(tester, 'anchor: bar button'), isTrue);
    expect(_rect(tester, 'anchored float').bottom, _near(_rect(tester, 'anchor button').top - 8 * s));

    await _tap(tester, 'anchor: draggable boat');
    await _tap(tester, 'anchor: bar button');
    expect(_rect(tester, 'anchored float').bottom, _near(_rect(tester, 'anchor button').top - 8 * s));
  });

  testWidgets('HarborAnchored: dragged into the header, the bubble above it stops margin below the header', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-anchored'));
    final double s = _scale(tester);
    await tester.drag(_key('draggable anchor'), Offset(0, -tester.getRect(_key('stage')).height));
    await tester.pump();
    await tester.pump(_step);
    expect(_rect(tester, 'anchored float').top, _near(_rect(tester, 'anchored header').bottom + 8 * s));
    // So it overlaps the boat rather than going under the header.
    expect(_rect(tester, 'anchored float').bottom, greaterThan(_rect(tester, 'draggable anchor').top));
  });

  testWidgets('HarborAnchored: dragged to the left edge, the bubble below it stops margin in from the edge', (
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
    expect(_rect(tester, 'anchored float').left, _near(_frameLeft(tester) + 8 * s));
    expect(_rect(tester, 'anchored float').top, _near(boat.bottom + 8 * s));
    expect(_rect(tester, 'anchored float').center.dx, greaterThan(boat.center.dx));
  });

  // -------------------------------------------------------------------------
  // HarborPopover

  testWidgets('HarborPopover: the menu opened from the first row sits gap below it', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _tapStage(tester, 'stage row 0');
    final Rect row = _rect(tester, 'stage row 0');
    expect(_rect(tester, 'popover').top, _near(row.bottom + 8 * s));
    expect(_code(tester), contains('side: HarborAnchorSide.below,'));
  });

  testWidgets('HarborPopover: the menu opened from the last row flips above it, clear of the tab bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _scrollStage(tester, 'popover stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    final Rect row = _rect(tester, 'stage row 11');
    expect(_rect(tester, 'popover').bottom, _near(row.top - 8 * s));
    expect(_rect(tester, 'popover').bottom, _atMost(_rect(tester, 'popover tab bar').top));
  });

  testWidgets('HarborPopover: with the keyboard up, the menu from the last row in sight flips above the keyboard', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _setKeyboard(tester, shown: true);
    await _scrollStage(tester, 'popover stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    final Rect row = _rect(tester, 'stage row 11');
    expect(row.bottom, _atMost(_keyboardTop(tester)));
    expect(_rect(tester, 'popover').bottom, _near(row.top - 8 * s));
    expect(_rect(tester, 'popover').bottom, _atMost(_keyboardTop(tester)));
  });

  testWidgets('HarborPopover: without flips, the menu below the last row is held clear of the tab bar instead', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-portal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle flips');
    expect(_code(tester), contains('flips: false,'));
    await _scrollStage(tester, 'popover stage', double.infinity);
    await _tapStage(tester, 'stage row 11');
    expect(_rect(tester, 'popover').bottom, _near(_rect(tester, 'popover tab bar').top - 8 * s));
  });

  // -------------------------------------------------------------------------
  // HarborFloat(modal: true)

  testWidgets('HarborFloat(modal: true): hides the float listed before it and is centered in the room', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    expect(_key('modal float'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    final Rect room = Rect.fromLTRB(
      _frameLeft(tester),
      _rect(tester, 'modal header').bottom,
      _frameRight(tester),
      _rect(tester, 'modal tab bar').top,
    );
    expect(_rect(tester, 'modal float').center.dy, _near(room.center.dy));
    expect(_rect(tester, 'modal float').center.dx, _near(room.center.dx));
    expect(find.text('HarborFloat(modal: true)'), findsWidgets);
    expect(
      _code(tester),
      contains('HarborFloat(modal: true, onDismiss: close, child: QuickActions()), // a barrier; hides the tooltip'),
    );
  });

  testWidgets('HarborFloat(modal: true): not modal, both floats stay up, the first at the bottom center', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle modal');
    expect(_key('modal float'), findsOneWidget);
    expect(_key('listed first'), findsOneWidget);
    expect(_rect(tester, 'listed first').bottom, _near(_rect(tester, 'modal tab bar').top - 16 * s));
    expect(_rect(tester, 'listed first').center.dx, _near((_frameLeft(tester) + _frameRight(tester)) / 2));
    expect(find.text('Not modal: the floats before me stay up.'), findsOneWidget);
    expect(_code(tester), contains('HarborFloat(child: QuickActions()), // floats beside it'));

    await _tap(tester, 'toggle modal');
    expect(_key('listed first'), findsNothing);
  });

  testWidgets('HarborFloat(modal: true): taking the launch down brings the first float back', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    await _tap(tester, 'toggle launch up');
    expect(_key('modal float'), findsNothing);
    expect(_key('listed first'), findsOneWidget);
    expect(_code(tester), isNot(contains('QuickActions')));

    await _tap(tester, 'toggle launch up');
    expect(_key('modal float'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    expect(_code(tester), contains('QuickActions'));
  });

  testWidgets('HarborFloat(modal: true): Stand down and Call the launch take it down and up again', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('buoy-modal'));
    await _tapStage(tester, 'launch away');
    expect(_key('modal float'), findsNothing);
    expect(_key('listed first'), findsOneWidget);
    expect(_switchedOn(tester, 'toggle launch up'), isFalse);

    await _tapStage(tester, 'call the launch');
    expect(_key('modal float'), findsOneWidget);
    expect(_key('listed first'), findsNothing);
    expect(_switchedOn(tester, 'toggle launch up'), isTrue);
  });

  // -------------------------------------------------------------------------
  // HarborToasts.show

  testWidgets('HarborToasts.show: each slot lands at its place in the page’s room', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    for (final HarborToastSlot slot in HarborToastSlot.values) {
      await _tapStage(tester, 'show ${slot.name}');
      final Rect room = Rect.fromLTRB(
        _frameLeft(tester),
        _headerBottom(tester),
        _frameRight(tester),
        _rect(tester, 'toasts tab bar').top,
      ).deflate(16 * s);
      final Rect toast = _rect(tester, 'toast');
      final Rect expected = slot.alignment.inscribe(toast.size, room);
      expect(toast.top, _near(expected.top), reason: slot.name);
      expect(toast.center.dx, _near(expected.center.dx), reason: slot.name);
      expect(find.text('${slot.name} · topmost'), findsOneWidget);
      expect(_code(tester), contains('slot: HarborToastSlot.${slot.name},'));
      expect(_code(tester), contains('target: HarborToastTarget.topmost,'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(_step);
    }
  });

  testWidgets('HarborToasts.show: a toast hides after four seconds', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('signals'));
    await _tapStage(tester, 'show middle');
    await tester.pump(const Duration(seconds: 3));
    expect(_key('toast'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(_step);
    expect(_key('toast'), findsNothing);
  });

  testWidgets('HarborToasts.show: sent to the root, it clears only the system edges, over the header and tab bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tap(tester, 'target: root');
    expect(_code(tester), contains('target: HarborToastTarget.root,'));

    await _tapStage(tester, 'show top');
    expect(_rect(tester, 'toast').top, _near(_frameTop(tester) + (62 + 16) * s));
    expect(_rect(tester, 'toast').top, lessThan(_headerBottom(tester)));
    expect(find.text('top · root'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);

    await _tapStage(tester, 'show low');
    expect(_rect(tester, 'toast').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_rect(tester, 'toast').bottom, greaterThan(_rect(tester, 'toasts tab bar').top));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
  });

  testWidgets('HarborToasts.show: shown from a sheet, topmost lands in the sheet’s room', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open toasts sheet');
    await tester.pump(_step);

    // Below the sheet's header and its 12-point fade.
    await _tapStage(tester, 'sheet show top');
    expect(_rect(tester, 'toast').top, _near(_rect(tester, 'toasts sheet header').bottom + (12 + 16) * s));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);

    // Above the footer's bar, which starts 10 above its marker.
    await _tapStage(tester, 'sheet show low');
    expect(_rect(tester, 'toast').bottom, _near(_rect(tester, 'toasts sheet footer').top - (10 + 16) * s));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
    await _popStage(tester, 'toasts sheet header');
  });

  testWidgets('HarborToasts.show: shown from a sheet to the root, it lands over the sheet’s footer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('signals'));
    final double s = _scale(tester);
    await _tap(tester, 'target: root');
    await _tapStage(tester, 'open toasts sheet');
    await tester.pump(_step);
    await _tapStage(tester, 'sheet show low');
    expect(_rect(tester, 'toast').bottom, _near(_frameBottom(tester) - (34 + 16) * s));
    expect(_rect(tester, 'toast').bottom, greaterThan(_rect(tester, 'toasts sheet footer').top));
    expect(find.text('low · root'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(_step);
    await _popStage(tester, 'toasts sheet header');
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

  testWidgets('HarborSheet: with a header, the body ends at the footer, with no empty band between them', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    // The footer's bar starts 12 above its button.
    expect(_rect(tester, 'sheet body').bottom, _near(_rect(tester, 'sheet footer').top - 12 * s));
    await _popStage(tester, 'sheet footer');
  });

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
    // just the header and its fade: the rows stay where they were.
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

  testWidgets('HarborSheet: footerKeyboard: rides follows the keyboard, footerMinimum above it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    final double s = _scale(tester);
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    expect(_selected(tester, 'footerKeyboard: rides'), isTrue);
    await _setKeyboard(tester, shown: true);
    await tester.pump(_step);
    expect(_rect(tester, 'sheet footer').bottom, _near(_keyboardTop(tester) - 16 * s));
    expect(_rect(tester, 'sheet header').top, _atLeast(_frameTop(tester) + 62 * s));
    await _setKeyboard(tester, shown: false);
    expect(_rect(tester, 'sheet footer').bottom, _near(_frameBottom(tester) - 34 * s));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets('HarborSheet: footerKeyboard: stays holds still and the keyboard covers it; the body stays above', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    await _tapStage(tester, 'open sheet');
    await tester.pump(_step);
    await _tap(tester, 'footerKeyboard: stays');
    expect(_code(tester), contains('footerKeyboard: HarborKeyboardStance.stays,'));
    final Rect hidden = _rect(tester, 'sheet footer');
    await _setKeyboard(tester, shown: true);
    await tester.pump(_step);
    expect(_rect(tester, 'sheet footer').top, _near(hidden.top));
    expect(_rect(tester, 'sheet footer').top, greaterThan(_keyboardTop(tester)));
    expect(_rect(tester, 'sheet body').bottom, _atMost(_keyboardTop(tester)));
    await _setKeyboard(tester, shown: false);
    expect(_rect(tester, 'sheet footer').top, _near(hidden.top));
    await _popStage(tester, 'sheet footer');
  });

  testWidgets(
    'HarborSheet: footerKeyboard: reserves holds the keyboard\'s ground with a tray the keyboard takes over',
    (final WidgetTester tester) async {
      await _pumpEntry(tester, _page('sheet'));
      await _tapStage(tester, 'open sheet');
      await tester.pump(_step);
      await _tap(tester, 'footerKeyboard: reserves');
      expect(_code(tester), contains('footerKeyboard: HarborKeyboardStance.reserves,'));
      expect(_code(tester), contains('HarborKeyboardSpace(child: FlagTray())'));
      expect(tester.widget<Text>(_key('hint')).data!, startsWith('reserves:'));
      // The tray runs to the screen's edge: no system edge and no minimum under it.
      expect(_rect(tester, 'flag tray').bottom, _near(_frameBottom(tester)));
      // Once the keyboard has been up, the tray is exactly its height.
      await _setKeyboard(tester, shown: true);
      await tester.pump(_step);
      await _setKeyboard(tester, shown: false);
      await tester.pump(_step);
      final Rect tray = _rect(tester, 'flag tray');
      final Rect button = _rect(tester, 'sheet footer');
      expect(button.bottom, _atMost(tray.top));

      await _setKeyboard(tester, shown: true);
      await tester.pump(_step);
      expect(tray.top, _near(_keyboardTop(tester)), reason: 'the keyboard covers the tray exactly');
      expect(_rect(tester, 'sheet footer').top, _near(button.top), reason: 'the button above it holds still');
      expect(_rect(tester, 'sheet body').bottom, _atMost(button.top));
      await _setKeyboard(tester, shown: false);
      await tester.pump(_step);
      expect(_rect(tester, 'sheet footer').top, _near(button.top));
      expect(_rect(tester, 'flag tray').top, _near(tray.top));
      await _popStage(tester, 'sheet footer');
    },
  );

  testWidgets('HarborSheet: the hint says what to look for at each footerKeyboard stance', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet'));
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('rides:'));
    await _tap(tester, 'footerKeyboard: stays');
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('stays:'));
    expect(_key('flag tray'), findsNothing);
    await _tap(tester, 'footerKeyboard: reserves');
    expect(tester.widget<Text>(_key('hint')).data!, startsWith('reserves:'));
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
    await _setKeyboard(tester, shown: true);
    await tester.pump(_step);
    expect(_keyboardTop(tester) - tester.getRect(find.byType(HarborSheet)).top, _near(0.5 * (_sheetSpace - 336) * s));
    await _setKeyboard(tester, shown: false);
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
  // showHarborSheet(coversPage: true)

  testWidgets('showHarborSheet(coversPage: true): the list’s last row comes to rest above the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    expect(_code(tester), contains('coversPage: true,'));
    await _openCoversPage(tester);
    expect(find.textContaining('coversPage: true. Scroll the list'), findsOneWidget);
    await _scrollStage(tester, 'coversPage list', double.infinity);
    expect(_rect(tester, 'stage row 13').bottom, _near(_rect(tester, 'coversPage sheet header').top));
    await _popStage(tester, 'coversPage sheet header');
  });

  testWidgets('showHarborSheet(coversPage: false): the list’s last row stays under the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle coversPage');
    expect(_code(tester), contains('coversPage: false,'));
    await _openCoversPage(tester);
    expect(find.textContaining('coversPage: false. Scroll the list'), findsOneWidget);
    await _scrollStage(tester, 'coversPage list', double.infinity);
    // The list ends at the home indicator, as if the sheet weren't there.
    expect(_rect(tester, 'stage row 13').bottom, _near(_frameBottom(tester) - 34 * s));
    expect(_rect(tester, 'stage row 13').bottom, greaterThan(_rect(tester, 'coversPage sheet header').top));
    await _popStage(tester, 'coversPage sheet header');
  });

  testWidgets('showHarborSheet(barrier: none): the page stays live under the sheet, undimmed', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    expect(_selected(tester, 'barrier: none'), isTrue);
    expect(_code(tester), contains('barrier: HarborSheetBarrier.none,'));
    await _openCoversPage(tester);
    expect(_dimmed(), findsNothing);
    await tester.drag(_key('stage row 1'), const Offset(0, -80));
    await tester.pump();
    await tester.pump(_step);
    expect(_stageScroll(tester, 'coversPage list').pixels, greaterThan(0));
    expect(_key('coversPage sheet header'), findsOneWidget);
    await _popStage(tester, 'coversPage sheet header');
  });

  testWidgets('showHarborSheet(barrier: dismissible): dims the page, and a tap on it closes the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    await _tap(tester, 'barrier: dismissible');
    expect(_code(tester), contains('barrier: HarborSheetBarrier.dismissible,'));
    await _openCoversPage(tester);
    expect(_dimmed(), findsOneWidget);
    // The barrier takes the tap, not the row under it.
    await tester.tapAt(tester.getCenter(_key('stage row 1')));
    await tester.pump();
    await tester.pump(_step);
    await tester.pump(_step);
    expect(_key('coversPage sheet header'), findsNothing);
    expect(_dimmed(), findsNothing);
  });

  testWidgets('showHarborSheet(barrier: clear): leaves the page undimmed, and a tap on it closes the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('sheet-breakwater'));
    await _tap(tester, 'barrier: clear');
    expect(_code(tester), contains('barrier: HarborSheetBarrier.clear,'));
    await _openCoversPage(tester);
    expect(_dimmed(), findsNothing);
    // The barrier takes the tap, not the row under it.
    await tester.tapAt(tester.getCenter(_key('stage row 1')));
    await tester.pump();
    await tester.pump(_step);
    await tester.pump(_step);
    expect(_key('coversPage sheet header'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // showHarborDialog(inheritRoom:)

  testWidgets('showHarborDialog(inheritRoom: true): stays between the header and the composer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('dialog'));
    final double s = _scale(tester);
    expect(_code(tester), contains('inheritRoom: true,'));
    await _tapStage(tester, 'open dialog');
    expect(_rect(tester, 'call box').top, _near(_rect(tester, 'office header').bottom + 10 * s));
    expect(_rect(tester, 'call box').bottom, _near(_rect(tester, 'office footer').top - 10 * s));
    await _tapStage(tester, 'over and out');
    expect(_key('call box'), findsNothing);
  });

  testWidgets('showHarborDialog(inheritRoom: false): sees only the system edges, covering the header and composer', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('dialog'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle inheritRoom');
    expect(_code(tester), contains('inheritRoom: false,'));
    await _tapStage(tester, 'open dialog');
    expect(_rect(tester, 'call box').top, _near(_frameTop(tester) + (62 + 10) * s));
    expect(_rect(tester, 'call box').bottom, _near(_frameBottom(tester) - (34 + 10) * s));
    await _tapStage(tester, 'over and out');
    expect(_key('call box'), findsNothing);
  });

  // -------------------------------------------------------------------------
  // HarborKeepVisible

  testWidgets('HarborKeepVisible: tapping the field focuses it', (final WidgetTester tester) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    expect(find.text('Tap me, then show the keyboard'), findsOneWidget);
    await _tapStage(tester, 'kept field');
    expect(find.text('HarborKeepVisible field'), findsOneWidget);
  });

  testWidgets('HarborKeepVisible: the focused field is kept clearance above the rising keyboard', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    expect(_code(tester), contains('active: true,'));
    await _tapStage(tester, 'kept field');
    await _showKeyboardForKeepInSight(tester);
    expect(_stageScroll(tester, 'reveal scroll view').pixels, greaterThan(0));
    expect(_rect(tester, 'kept field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setKeyboard(tester, shown: false);
  });

  testWidgets('HarborKeepVisible: clearance sets how far above the keyboard the field is kept', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _slide(tester, 'clearance', 40);
    expect(_code(tester), contains('clearance: 40,'));
    expect(_code(tester), contains('HarborKeepVisible.reveal(fieldContext, clearance: 40);'));
    await _tapStage(tester, 'kept field');
    await _showKeyboardForKeepInSight(tester);
    expect(_rect(tester, 'kept field').bottom, _near(_keyboardTop(tester) - 40 * s));
    await _setKeyboard(tester, shown: false);
  });

  testWidgets('HarborKeepVisible(active: false): the field is left under the keyboard until reveal', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle active');
    expect(_code(tester), contains('active: false,'));
    await _tapStage(tester, 'kept field');
    await _showKeyboardForKeepInSight(tester);
    expect(_stageScroll(tester, 'reveal scroll view').pixels, 0);
    expect(_offstageRect(tester, 'kept field').top, greaterThan(_keyboardTop(tester)));

    // Revealed by hand, with the same clearance.
    await _tapStage(tester, 'reveal');
    await tester.pump(_step);
    expect(_rect(tester, 'kept field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setKeyboard(tester, shown: false);
  });

  testWidgets('HarborKeepVisible(onlyWhileFocused: true): a field without focus is not brought into sight', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    expect(_code(tester), contains('onlyWhileFocused: true,'));
    await _showKeyboardForKeepInSight(tester);
    expect(_stageScroll(tester, 'reveal scroll view').pixels, 0);
    expect(_offstageRect(tester, 'kept field').top, greaterThan(_keyboardTop(tester)));
    await _setKeyboard(tester, shown: false);
  });

  testWidgets('HarborKeepVisible(onlyWhileFocused: false): the field is brought into sight with or without focus', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-reveal'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle onlyWhileFocused');
    expect(_code(tester), contains('onlyWhileFocused: false,'));
    expect(find.text('Tap me, then show the keyboard'), findsOneWidget);
    await _showKeyboardForKeepInSight(tester);
    expect(_rect(tester, 'kept field').bottom, _near(_keyboardTop(tester) - 16 * s));
    await _setKeyboard(tester, shown: false);
  });

  // -------------------------------------------------------------------------
  // HarborCoverageListener

  testWidgets('HarborCoverageListener: in the room it reports 0 and the header title is hidden', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    expect(_rect(tester, 'hero title').top, greaterThan(_rect(tester, 'obscured header').bottom));
    // Both readouts: in the header and in the controls.
    expect(find.text('covered 0%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 0);
  });

  testWidgets('HarborCoverageListener: half under the header, it reports how much is covered', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    final double s = _scale(tester);
    await _scrollStage(tester, 'hero scroll view', 150);
    final Rect title = _rect(tester, 'hero title');
    // The room starts below the header's 12-point fade.
    final double covered = (_rect(tester, 'obscured header').bottom + 12 * s - title.top) / title.height;
    expect(covered, inExclusiveRange(0.1, 0.99));
    expect(_textOf(tester, 'covered readout'), 'covered ${(covered * 100).round()}%');
    expect(find.text('covered ${(covered * 100).round()}%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), moreOrLessEquals(covered, epsilon: 0.02));
  });

  testWidgets('HarborCoverageListener: fully under the header, it reports 100% and hands off the title', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    await _scrollStage(tester, 'hero scroll view', 280);
    expect(_rect(tester, 'hero title').bottom, _atMost(_rect(tester, 'obscured header').bottom));
    expect(find.text('covered 100%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 1);

    await _scrollStage(tester, 'hero scroll view', 0);
    expect(find.text('covered 0%'), findsNWidgets(2));
    expect(_headerTitleOpacity(tester), 0);
  });

  testWidgets('HarborCoverageListener: startsUnderBars runs the hero under the header; off, it starts below', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('beacon-obscured'));
    final double s = _scale(tester);
    // The title sits 16 above the bottom of the 300-point hero.
    expect(_rect(tester, 'hero title').bottom, _near(_frameTop(tester) + (300 - 16) * s));
    expect(_code(tester), contains('startsUnderBars: true,'));

    await _tap(tester, 'toggle startsUnderBars');
    expect(_code(tester), contains('startsUnderBars: false,'));
    expect(_rect(tester, 'hero title').bottom, _near(_rect(tester, 'obscured header').bottom + (12 + 300 - 16) * s));
    expect(find.text('covered 0%'), findsNWidgets(2));
  });

  // -------------------------------------------------------------------------
  // HarborKeepVisibleRegion

  testWidgets('HarborKeepVisibleRegion: at rest it already lifts the boat clearance clear of the home indicator', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    // Placed 60 up, it needs 34 + 40: lifted 14.
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - (34 + 40) * s));
    expect(_code(tester), contains('active: true,'));
  });

  testWidgets('HarborKeepVisibleRegion: lifts the boat clearance clear of a coversPage sheet, and back down', (
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

  testWidgets('HarborKeepVisibleRegion: without lift, the boat sits where it is placed, under the sheet', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, _page('lighthouse-region'));
    final double s = _scale(tester);
    await _tap(tester, 'toggle active');
    // The region eases there from the frame after it measures.
    await tester.pump(_step);
    expect(_code(tester), contains('active: false,'));
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - 60 * s));
    await _openLiftSheet(tester);
    expect(_rect(tester, 'lift boat').bottom, _near(_frameBottom(tester) - 60 * s));
    expect(_rect(tester, 'lift boat').bottom, greaterThan(_rect(tester, 'lift sheet header').top));
    await _popStage(tester, 'lift sheet header');
  });

  testWidgets('HarborKeepVisibleRegion: clearance sets how far clear the boat is lifted', (
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

  testWidgets('HarborKeepVisibleRegion: holdPosition keeps the boat where it is until it is let go', (
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
