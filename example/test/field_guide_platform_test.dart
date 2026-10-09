import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_platform.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/guide_page.dart';
import 'package:harbor_example/field_guide/stage.dart';

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
  await _step(tester);
}

/// Steps time: the seas never settle.
Future<void> _step(final WidgetTester tester, [final int times = 3]) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Finder _key(final String key) => find.byKey(ValueKey<String>(key));

Future<void> _tap(final WidgetTester tester, final Finder finder) async {
  await _unfoldStageSettings(tester, finder);
  await tester.ensureVisible(finder);
  await _step(tester, 1);
  await tester.tap(finder);
  await _step(tester);
}

/// The stage's own settings start folded away: open them when [finder] is one.
Future<void> _unfoldStageSettings(final WidgetTester tester, final Finder finder) async {
  final Finder fold = _key('stage settings');
  if (finder.evaluate().isEmpty && fold.evaluate().isNotEmpty) {
    await tester.ensureVisible(fold);
    await _step(tester, 1);
    await tester.tap(fold);
    await _step(tester);
  }
}

/// Raises or lowers the tide with the gauge's button and lets it finish.
Future<void> _toggleTide(final WidgetTester tester) async {
  await _tap(tester, _key('tide toggle'));
  await _step(tester, 4);
}

/// Taps the slider [label] at [fraction] of its width: 0 and 1 are its ends.
Future<void> _slide(final WidgetTester tester, final String label, final double fraction) async {
  final Finder slider = _key('slider $label');
  await tester.ensureVisible(slider);
  await _step(tester, 1);
  final Rect r = tester.getRect(slider);
  await tester.tapAt(Offset((r.left + 1) + (r.width - 2) * fraction, r.center.dy));
  await _step(tester);
}

/// The stage's screen: the bezel's inside.
Rect _screen(final WidgetTester tester) => tester.getRect(_key('stage')).deflate(10);

/// [global], a rect on the test's screen, in the stage device's own points.
Rect _toDevice(final WidgetTester tester, final Rect global, final double deviceWidth) {
  final Rect screen = _screen(tester);
  final double scale = screen.width / deviceWidth;
  return Rect.fromLTRB(
    (global.left - screen.left) / scale,
    (global.top - screen.top) / scale,
    (global.right - screen.left) / scale,
    (global.bottom - screen.top) / scale,
  );
}

/// Where [finder] is on the stage, in the device's own points.
Rect _onDevice(final WidgetTester tester, final Finder finder, final double deviceWidth) =>
    _toDevice(tester, tester.getRect(finder), deviceWidth);

/// The code card's text.
String _code(final WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _key('code card'), matching: find.byType(Text))).data!;

/// What the readings panel shows for the probe [label].
String? _reading(final WidgetTester tester, final String label) =>
    tester.widget<ProbeReadout>(find.byType(ProbeReadout)).settings.probes[label];

void main() {
  test('every entry is in the platform group', () {
    expect(platformEntries, hasLength(7));
    expect(platformEntries.every((final GuideEntry e) => e.group == GuideGroup.platform), isTrue);
  });

  testWidgets('no control on any platform page throws', (final WidgetTester tester) async {
    for (final GuideEntry entry in platformEntries) {
      await _pumpEntry(tester, Builder(key: ValueKey<String>(entry.id), builder: entry.page));
      final List<Key> controls = <Key>[
        for (final Widget chip in tester.widgetList(find.byType(ChoiceChip))) chip.key!,
        for (final Widget toggle in tester.widgetList(find.byType(SwitchListTile))) toggle.key!,
      ];
      for (final Key key in controls) {
        await _tap(tester, find.byKey(key));
        expect(tester.takeException(), isNull, reason: '${entry.className}: $key');
      }
    }
  });

  group('HarborCoast', () {
    const double width = 402;

    testWidgets('ambient takes the status bar and home indicator as coast', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      expect(_onDevice(tester, _key('coast header'), width).top, moreOrLessEquals(62, epsilon: 0.5));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874 - 34, epsilon: 0.5));
      expect(find.descendant(of: _key('coast header'), matching: find.text('HarborCoast.ambient')), findsOneWidget);
      expect(_code(tester), contains('  coast: HarborCoast.ambient,\n'));
      expect(
        _key('coast bands'),
        paints
          ..rect(rect: const Rect.fromLTWH(0, 0, width, 62))
          ..rect(rect: const Rect.fromLTWH(0, 874 - 34, width, 34)),
      );
    });

    testWidgets('ambient follows the status bar and home indicator switches', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      await _tap(tester, _key('toggle Status bar'));
      expect(_onDevice(tester, _key('coast header'), width).top, moreOrLessEquals(0, epsilon: 0.5));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874 - 34, epsilon: 0.5));
      await _tap(tester, _key('toggle Home indicator'));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874, epsilon: 0.5));
      // No coast left: the deckle edge is the first thing the bands draw.
      expect(_key('coast bands'), paints..rect(rect: (Offset.zero & const Size(width, 874)).deflate(3)));
    });

    testWidgets('ambient takes the landscape phone’s side insets', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      await _tap(tester, _key('Device: iPhone 17 landscape'));
      expect(
        _key('coast bands'),
        paints
          ..rect(rect: const Rect.fromLTWH(0, 402 - 21, 874, 21))
          ..rect(rect: const Rect.fromLTWH(0, 0, 62, 402))
          ..rect(rect: const Rect.fromLTWH(874 - 62, 0, 62, 402)),
      );
      expect(_onDevice(tester, _key('coast bar'), 874).bottom, moreOrLessEquals(402 - 21, epsilon: 0.5));
    });

    testWidgets('fixed(...) is 24 top and bottom whatever the device says', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      await _tap(tester, _key('coast: HarborCoast.fixed(...)'));
      expect(_onDevice(tester, _key('coast header'), width).top, moreOrLessEquals(24, epsilon: 0.5));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874 - 24, epsilon: 0.5));
      expect(find.descendant(of: _key('coast header'), matching: find.text('HarborCoast.fixed(...)')), findsOneWidget);
      expect(_code(tester), contains('  coast: HarborCoast.fixed(EdgeInsetsDirectional.symmetric(vertical: 24)),\n'));
      expect(
        _key('coast bands'),
        paints
          ..rect(rect: const Rect.fromLTWH(0, 0, width, 24))
          ..rect(rect: const Rect.fromLTWH(0, 874 - 24, width, 24)),
      );
      await _tap(tester, _key('toggle Status bar'));
      await _tap(tester, _key('toggle Home indicator'));
      expect(_onDevice(tester, _key('coast header'), width).top, moreOrLessEquals(24, epsilon: 0.5));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874 - 24, epsilon: 0.5));
      // In landscape the device's 62 side insets are not taken either: after
      // the top and bottom bands comes the deckle edge, no side bands.
      await _tap(tester, _key('Device: iPhone 17 landscape'));
      expect(
        _key('coast bands'),
        paints
          ..rect(rect: const Rect.fromLTWH(0, 0, 874, 24))
          ..rect(rect: const Rect.fromLTWH(0, 402 - 24, 874, 24))
          ..rect(rect: (Offset.zero & const Size(874, 402)).deflate(3)),
      );
    });

    testWidgets('none has no coast', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      await _tap(tester, _key('coast: HarborCoast.none'));
      expect(_onDevice(tester, _key('coast header'), width).top, moreOrLessEquals(0, epsilon: 0.5));
      expect(_onDevice(tester, _key('coast bar'), width).bottom, moreOrLessEquals(874, epsilon: 0.5));
      expect(find.descendant(of: _key('coast header'), matching: find.text('HarborCoast.none')), findsOneWidget);
      expect(_code(tester), contains('  coast: HarborCoast.none,\n'));
      expect(_key('coast bands'), paints..rect(rect: (Offset.zero & const Size(width, 874)).deflate(3)));
    });

    testWidgets('none has no tide; ambient and fixed do', (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastEntry());
      double tide() => HarborChart.snapshot(
        tester.element(_key('coast bar')),
      ).firstWhere((final HarborChartEntry e) => e.label == 'postcard').tide;

      await _toggleTide(tester);
      expect(tide(), moreOrLessEquals(336, epsilon: 0.5));
      await _tap(tester, _key('coast: HarborCoast.fixed(...)'));
      expect(tide(), moreOrLessEquals(336, epsilon: 0.5));
      await _tap(tester, _key('coast: HarborCoast.none'));
      expect(tide(), 0);
      // The stage itself still reports the keyboard.
      expect(_reading(tester, 'The stage (what the platform reports)'), contains('\nkeyboard 336\n'));
    });
  });

  group('HarborCoast.titleSafe', () {
    /// The moored card in the television's own points.
    Rect card(final WidgetTester tester) => _onDevice(tester, _key('moored card'), 1200);

    testWidgets('fraction(0.05) is 5% of the width and height', (final WidgetTester tester) async {
      await _pumpEntry(tester, const TitleSafeEntry());
      expect(card(tester).left, moreOrLessEquals(60, epsilon: 0.5));
      expect(card(tester).bottom, moreOrLessEquals(675 - 33.75, epsilon: 0.5));
      expect(_onDevice(tester, _key('tv header'), 1200).top, moreOrLessEquals(33.75, epsilon: 0.5));
      expect(
        _key('safe line'),
        paints
          ..path()
          ..rect(rect: const Rect.fromLTRB(60, 33.75, 1140, 675 - 33.75)),
      );
      expect(_code(tester), contains('HarborTitleSafe.fraction(0.05),'));
    });

    testWidgets('the fraction slider sets the band', (final WidgetTester tester) async {
      await _pumpEntry(tester, const TitleSafeEntry());
      await _slide(tester, 'fraction %', 1);
      expect(find.text('fraction % 10'), findsOneWidget);
      expect(card(tester).left, moreOrLessEquals(120, epsilon: 0.5));
      expect(card(tester).bottom, moreOrLessEquals(675 - 67.5, epsilon: 0.5));
      expect(
        _key('safe line'),
        paints
          ..path()
          ..rect(rect: const Rect.fromLTRB(120, 67.5, 1080, 675 - 67.5)),
      );
      expect(_code(tester), contains('HarborTitleSafe.fraction(0.10),'));
      await _slide(tester, 'fraction %', 0);
      expect(find.text('fraction % 0'), findsOneWidget);
      expect(card(tester).left, moreOrLessEquals(0, epsilon: 0.5));
      expect(card(tester).bottom, moreOrLessEquals(675, epsilon: 0.5));
      expect(_code(tester), contains('HarborTitleSafe.fraction(0.00),'));
    });

    testWidgets('fixed 48 · 27 is the same band on every edge pair', (final WidgetTester tester) async {
      await _pumpEntry(tester, const TitleSafeEntry());
      await _tap(tester, _key('HarborTitleSafe: fixed 48 · 27'));
      expect(_key('slider fraction %'), findsNothing);
      expect(card(tester).left, moreOrLessEquals(48, epsilon: 0.5));
      expect(card(tester).bottom, moreOrLessEquals(675 - 27, epsilon: 0.5));
      expect(_onDevice(tester, _key('tv header'), 1200).top, moreOrLessEquals(27, epsilon: 0.5));
      expect(
        _key('safe line'),
        paints
          ..path()
          ..rect(rect: const Rect.fromLTRB(48, 27, 1152, 648)),
      );
      expect(
        _code(tester),
        contains('HarborTitleSafe.fixed(EdgeInsetsDirectional.symmetric(horizontal: 48, vertical: 27)),'),
      );
      await _tap(tester, _key('toggle Right-to-left'));
      expect(card(tester).right, moreOrLessEquals(1200 - 48, epsilon: 0.5));
    });

    testWidgets('fixed start 96 widens the start edge only', (final WidgetTester tester) async {
      await _pumpEntry(tester, const TitleSafeEntry());
      await _tap(tester, _key('HarborTitleSafe: fixed start 96'));
      expect(_key('slider fraction %'), findsNothing);
      expect(card(tester).left, moreOrLessEquals(96, epsilon: 0.5));
      expect(card(tester).bottom, moreOrLessEquals(675 - 27, epsilon: 0.5));
      expect(
        _key('safe line'),
        paints
          ..path()
          ..rect(rect: const Rect.fromLTRB(96, 27, 1152, 648)),
      );
      expect(_code(tester), contains('HarborTitleSafe.fixed(EdgeInsetsDirectional.fromSTEB(96, 27, 48, 27)),'));
      // Right-to-left: the start band is now on the right.
      await _tap(tester, _key('toggle Right-to-left'));
      expect(card(tester).right, moreOrLessEquals(1200 - 96, epsilon: 0.5));
      expect(
        _key('safe line'),
        paints
          ..path()
          ..rect(rect: const Rect.fromLTRB(48, 27, 1104, 648)),
      );
    });

    testWidgets('the stage is a television with no tide', (final WidgetTester tester) async {
      await _pumpEntry(tester, const TitleSafeEntry());
      expect(_screen(tester).height / _screen(tester).width, moreOrLessEquals(675 / 1200, epsilon: 0.001));
      expect(_key('tide toggle'), findsNothing);
      await _unfoldStageSettings(tester, _key('Device: Television'));
      expect(_key('Device: Television'), findsOneWidget);
      expect(_key('Device: iPhone 17'), findsNothing);
      expect(_key('toggle Status bar'), findsNothing);
    });
  });

  group('HarborScaleModel', () {
    /// Where [key] is in the model's own 1200 points.
    Rect inModel(final WidgetTester tester, final String key) {
      final Rect model = tester.getRect(_key('scale model screen'));
      final Rect r = tester.getRect(_key(key));
      final double scale = model.width / 1200;
      return Rect.fromLTRB(
        (r.left - model.left) / scale,
        (r.top - model.top) / scale,
        (r.right - model.left) / scale,
        (r.bottom - model.top) / scale,
      );
    }

    testWidgets('letterboxes 16:9 and the coast does not reach it', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ScaleModelEntry());
      final Rect screen = _screen(tester);
      final Rect model = tester.getRect(_key('scale model screen'));
      expect(model.width, moreOrLessEquals(screen.width, epsilon: 0.5));
      expect(model.height / model.width, moreOrLessEquals(675 / 1200, epsilon: 0.001));
      // Centered: the letterbox is even above and below.
      expect(model.top - screen.top, moreOrLessEquals(screen.bottom - model.bottom, epsilon: 0.5));
      // Readings: the phone has a coast, the model inside it has none, and sees the reference size.
      expect(_reading(tester, 'The phone, outside the model'), startsWith('padding  T 62 · B 34 · L 0 · R 0\n'));
      expect(_reading(tester, 'Inside HarborScaleModel'), startsWith('padding  T 0 · B 0 · L 0 · R 0\n'));
      expect(_reading(tester, 'Size inside the model'), 'MediaQuery.size  1200 × 675');
      expect(_reading(tester, 'Size outside the model'), 'MediaQuery.size  402 × 874');
      expect(inModel(tester, 'scale model header').top, moreOrLessEquals(0, epsilon: 0.5));
      expect(inModel(tester, 'scale model rail').left, moreOrLessEquals(0, epsilon: 0.5));
    });

    testWidgets('the letterbox is black, or night', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ScaleModelEntry());
      Color letterbox() => tester
          .widget<ColoredBox>(
            find.descendant(of: find.byType(HarborScaleModel), matching: find.byType(ColoredBox)).first,
          )
          .color;

      expect(letterbox(), const Color(0xFF000000));
      expect(_code(tester), isNot(contains('letterbox:')));
      await _tap(tester, _key('letterbox: night'));
      expect(letterbox(), Palette.night);
      expect(_code(tester), contains('    letterbox: Palette.night,\n'));
      await _tap(tester, _key('letterbox: black'));
      expect(letterbox(), const Color(0xFF000000));
    });

    testWidgets('coast: titleSafe(0.05) gives the model a band of its own', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ScaleModelEntry());
      expect(_code(tester), isNot(contains('coast:')));
      await _tap(tester, _key('toggle coast: titleSafe(0.05)'));
      expect(_reading(tester, 'Inside HarborScaleModel'), startsWith('padding  T 34 · B 34 · L 60 · R 60\n'));
      expect(_code(tester), contains('    coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),\n'));
      // In the model's 1200 points: the header and the rail keep clear of the band.
      expect(inModel(tester, 'scale model header').top, moreOrLessEquals(33.75, epsilon: 0.5));
      expect(inModel(tester, 'scale model rail').left, moreOrLessEquals(60, epsilon: 0.5));
    });

    testWidgets('in landscape the home indicator reaches the model', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ScaleModelEntry());
      await _tap(tester, _key('Device: iPhone 17 landscape'));
      final Rect screen = _screen(tester);
      final Rect model = tester.getRect(_key('scale model screen'));
      // Pillarboxed: the model is as tall as the phone and centered across it.
      expect(model.height, moreOrLessEquals(screen.height, epsilon: 0.5));
      expect(model.left - screen.left, moreOrLessEquals(screen.right - model.right, epsilon: 0.5));
      expect(_reading(tester, 'The phone, outside the model'), startsWith('padding  T 0 · B 21 · L 62 · R 62\n'));
      // The 21 home indicator, scaled by 675 / 402; the side insets fall in the pillarbox.
      expect(_reading(tester, 'Inside HarborScaleModel'), startsWith('padding  T 0 · B 35 · L 0 · R 0\n'));
      expect(_reading(tester, 'Size outside the model'), 'MediaQuery.size  874 × 402');
      expect(_reading(tester, 'Size inside the model'), 'MediaQuery.size  1200 × 675');
    });
  });

  group('HarborEdge', () {
    HarborChartEntry chart(final WidgetTester tester) => HarborChart.snapshot(
      tester.element(_key('edge start')),
    ).firstWhere((final HarborChartEntry e) => e.label == 'edges');

    HarborDockRecord dock(final HarborChartEntry chart, final String label) =>
        chart.docks.firstWhere((final HarborDockRecord d) => d.label == label);

    testWidgets('quay side docks take their ground from the body', (final WidgetTester tester) async {
      await _pumpEntry(tester, const EdgeEntry());
      final HarborChartEntry page = chart(tester);
      final HarborDockRecord start = dock(page, 'start');
      final HarborDockRecord end = dock(page, 'end');
      expect(start.kind, HarborDockKind.quay);
      expect(start.edge, HarborEdge.start);
      expect(end.kind, HarborDockKind.quay);
      expect(end.edge, HarborEdge.end);
      expect(page.body.left, moreOrLessEquals(start.rect.right, epsilon: 0.5));
      expect(page.body.right, moreOrLessEquals(end.rect.left, epsilon: 0.5));
      expect(_code(tester), contains('  start: [HarborDock.quay(child: PortLight())],\n'));
      expect(_code(tester), contains('  end: [HarborDock.quay(child: StarboardLight())],\n'));
    });

    testWidgets('pier side docks let the body run under them', (final WidgetTester tester) async {
      await _pumpEntry(tester, const EdgeEntry());
      await _tap(tester, _key('side docks: HarborDock.pier'));
      final HarborChartEntry page = chart(tester);
      final HarborDockRecord start = dock(page, 'start');
      expect(start.kind, HarborDockKind.pier);
      expect(dock(page, 'end').kind, HarborDockKind.pier);
      expect(page.body.left, moreOrLessEquals(page.frame.left, epsilon: 0.5));
      expect(page.body.right, moreOrLessEquals(page.frame.right, epsilon: 0.5));
      // The clear water still stops at the lights.
      expect(page.clearWater.left, moreOrLessEquals(start.rect.right, epsilon: 0.5));
      expect(_code(tester), contains('  start: [HarborDock.pier(child: PortLight())],\n'));
      expect(_code(tester), contains('  end: [HarborDock.pier(child: StarboardLight())],\n'));
    });

    testWidgets('left to right, start is on the left', (final WidgetTester tester) async {
      await _pumpEntry(tester, const EdgeEntry());
      final Rect screen = _screen(tester);
      expect(tester.getRect(_key('edge start')).left, moreOrLessEquals(screen.left, epsilon: 0.5));
      expect(tester.getRect(_key('edge end')).right, moreOrLessEquals(screen.right, epsilon: 0.5));
      expect(find.textContaining('Directionality: ltr\n'), findsOneWidget);
      expect(find.textContaining('HarborEdge.start is on the left\nHarborEdge.end is on the right\n'), findsOneWidget);
      expect(find.textContaining('HarborEdge.start.opposite: end\n'), findsOneWidget);
    });

    testWidgets('start and end swap sides right-to-left', (final WidgetTester tester) async {
      await _pumpEntry(tester, const EdgeEntry());
      await _tap(tester, _key('toggle Right-to-left'));
      final Rect flipped = _screen(tester);
      expect(tester.getRect(_key('edge start')).right, moreOrLessEquals(flipped.right, epsilon: 0.5));
      expect(tester.getRect(_key('edge end')).left, moreOrLessEquals(flipped.left, epsilon: 0.5));
      expect(find.textContaining('Directionality: rtl\n'), findsOneWidget);
      expect(find.textContaining('HarborEdge.start is on the right\nHarborEdge.end is on the left\n'), findsOneWidget);
    });

    testWidgets('in landscape the side docks absorb the side insets', (final WidgetTester tester) async {
      await _pumpEntry(tester, const EdgeEntry());
      await _tap(tester, _key('Device: iPhone 17 landscape'));
      final HarborChartEntry page = chart(tester);
      final Rect start = _toDevice(tester, dock(page, 'start').rect, 874);
      final Rect end = _toDevice(tester, dock(page, 'end').rect, 874);
      // Each dock reaches the screen's edge and holds its 76 light past the 62 inset.
      expect(start.left, moreOrLessEquals(0, epsilon: 0.5));
      expect(start.width, moreOrLessEquals(62 + 76, epsilon: 0.5));
      expect(end.right, moreOrLessEquals(874, epsilon: 0.5));
      expect(end.width, moreOrLessEquals(62 + 76, epsilon: 0.5));
      expect(_onDevice(tester, _key('edge start'), 874).left, moreOrLessEquals(62, epsilon: 0.5));
      expect(_onDevice(tester, _key('edge end'), 874).right, moreOrLessEquals(874 - 62, epsilon: 0.5));
    });
  });

  group('HarborChart', () {
    const String snapshot = 'HarborChart.snapshot(context)';

    testWidgets('snapshot charts the quay where the tab bar is', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ChartEntry());
      final Finder bar = _key('chart tab bar');
      final List<HarborChartEntry> chart = HarborChart.snapshot(tester.element(bar));
      final HarborChartEntry page = chart.firstWhere((final HarborChartEntry e) => e.label == 'chart page');
      final HarborDockRecord quay = page.docks.firstWhere((final HarborDockRecord d) => d.label == 'quay tab bar');
      expect(quay.kind, HarborDockKind.quay);
      expect(quay.edge, HarborEdge.bottom);
      // The quay takes its ground: the body ends where it starts, at the tab bar.
      expect(quay.rect.top, moreOrLessEquals(page.body.bottom, epsilon: 0.5));
      expect(quay.rect.top, moreOrLessEquals(tester.getRect(bar).top, epsilon: 0.5));
    });

    testWidgets('the readings list the snapshot', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ChartEntry());
      final String listed = _reading(tester, snapshot)!;
      expect(listed, contains("'chart page' · depth 1 · clear water "));
      expect(listed, contains('\n  pier header · pier · top · extent 114'));
      expect(listed, contains('\n  quay tab bar · quay · bottom · extent 90'));
      expect(find.text(listed), findsOneWidget);
    });

    testWidgets('the breakwater sheet joins the chart and the list', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ChartEntry());
      await _tap(tester, _key('toggle breakwater sheet'));
      await _step(tester, 4);
      final List<HarborChartEntry> after = HarborChart.snapshot(tester.element(_key('chart tab bar')));
      expect(after.map((final HarborChartEntry e) => e.label), contains('breakwater sheet'));
      expect(_reading(tester, snapshot), contains("\n'breakwater sheet' · depth "));
    });

    testWidgets('the sheet switch closes the sheet, and follows it when the stage dismisses it', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const ChartEntry());
      List<String> harbors() => <String>[
        for (final HarborChartEntry e in HarborChart.snapshot(tester.element(_key('chart tab bar')))) e.label,
      ];
      bool switchOn() => tester.widget<SwitchListTile>(_key('toggle breakwater sheet')).value;

      await _tap(tester, _key('toggle breakwater sheet'));
      await _step(tester, 4);
      expect(_key('breakwater sheet body'), findsOneWidget);
      expect(switchOn(), isTrue);
      await _tap(tester, _key('toggle breakwater sheet'));
      await _step(tester, 4);
      expect(_key('breakwater sheet body'), findsNothing);
      expect(harbors(), isNot(contains('breakwater sheet')));
      expect(switchOn(), isFalse);

      // Dismissed on the stage (its barrier tapped), the sheet turns the switch off.
      await _tap(tester, _key('toggle breakwater sheet'));
      await _step(tester, 4);
      await tester.tapAt(tester.getRect(_key('stage')).topCenter + const Offset(0, 40));
      await _step(tester, 4);
      expect(_key('breakwater sheet body'), findsNothing);
      expect(switchOn(), isFalse);
    });

    testWidgets('with the list off, the readings stop following the chart', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ChartEntry());
      await _tap(tester, _key('toggle list HarborChart.snapshot'));
      await _tap(tester, _key('toggle breakwater sheet'));
      await _step(tester, 4);
      expect(_reading(tester, snapshot) ?? '', isNot(contains('breakwater sheet')));
    });

    testWidgets(
      'with the list off, the snapshot leaves the readings',
      (final WidgetTester tester) async {
        await _pumpEntry(tester, const ChartEntry());
        await _tap(tester, _key('toggle list HarborChart.snapshot'));
        expect(_reading(tester, snapshot), isNull);
      },
    );

    testWidgets('the HarborChartOverlay switch draws the docks over the stage', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ChartEntry());
      final Finder overlay = find.descendant(of: find.byType(HarborChartOverlay), matching: find.byType(CustomPaint));
      // Piers teal, quays sand, as 32-bit colors: a paint's color is stored at
      // a lower precision than the const it was given.
      const int pier = 0x5526C6DA;
      const int quay = 0x55E0B070;
      List<int> filled() {
        final List<int> colors = <int>[];
        expect(
          overlay.first,
          paints..everything((final Symbol method, final List<dynamic> arguments) {
            if (method == #drawRect) {
              colors.add((arguments[1] as Paint).color.toARGB32());
            }
            return true;
          }),
        );
        return colors;
      }

      expect(filled(), containsAll(<int>[pier, quay]));
      await _tap(tester, _key('toggle HarborChartOverlay'));
      expect(tester.widget<CustomPaint>(overlay.first).foregroundPainter, isNull);
      expect(filled(), isNot(anyOf(contains(pier), contains(quay))));
    });
  });

  group('pumpSeaTrial', () {
    const Map<String, String> trialNames = <String, String>{
      'iPhone 17': 'iPhone17',
      'iPhone SE': 'iPhoneSE',
      'Android 3-button': 'androidThreeButton',
      'Android gesture': 'androidGesture',
      'iPhone 17 landscape': 'iPhone17Landscape',
      'foldable open': 'foldableOpen',
      'dual screen cover': 'dualScreenCover',
    };
    String n(final double v) => v.toStringAsFixed(0);

    for (final StageDevice device in StageDevice.phones) {
      testWidgets('on ${device.name} the composer rides to the waterline', (final WidgetTester tester) async {
        await _pumpEntry(tester, const SeaTrialEntry());
        await _tap(tester, _key('Device: ${device.name}'));
        final double width = device.size.width;
        final double height = device.size.height;
        final EdgeInsets coast = device.coast;
        String readout() => tester.widget<Text>(_key('trial readout')).data!;
        final String trial = trialNames[device.name]!;

        expect(
          readout(),
          'HarborTrialDevice.$trial\n'
          'size        ${n(width)} × ${n(height)}\n'
          'coast       T ${n(coast.top)} · B ${n(coast.bottom)} · L ${n(coast.left)} · R ${n(coast.right)}\n'
          'tideHeight  ${n(device.tideHeight)}\n'
          'tideIn      false\n'
          'waterline   ${n(height)}',
        );
        expect(_code(tester), contains('    device: HarborTrialDevice.$trial,\n'));
        expect(
          _code(tester),
          contains('// ${n(height)} − ${n(device.tideHeight)} = ${n(height - device.tideHeight)}\n'),
        );
        // Keyboard down: the composer clears the home indicator, and there is no waterline mark.
        expect(
          _onDevice(tester, _key('trial composer'), width).bottom,
          moreOrLessEquals(height - coast.bottom, epsilon: 0.5),
        );
        expect(_key('waterline mark'), findsNothing);

        await _toggleTide(tester);
        final double waterline = height - device.tideHeight;
        expect(readout(), endsWith('tideIn      true\nwaterline   ${n(waterline)}'));
        expect(_onDevice(tester, _key('trial composer'), width).bottom, moreOrLessEquals(waterline, epsilon: 0.5));
        expect(_onDevice(tester, _key('waterline mark'), width).center.dy, moreOrLessEquals(waterline, epsilon: 0.5));
      });
    }

    testWidgets('without the home indicator the composer sits on the bottom', (final WidgetTester tester) async {
      await _pumpEntry(tester, const SeaTrialEntry());
      await _tap(tester, _key('toggle Home indicator'));
      expect(_onDevice(tester, _key('trial composer'), 402).bottom, moreOrLessEquals(874, epsilon: 0.5));
    });
  });

  group('HarborWakePainter', () {
    /// The wake bands of the masks over the whole body (a wake painter's).
    List<Map<HarborEdge, HarborWakeBand>> bodyMasks(final WidgetTester tester) => <Map<HarborEdge, HarborWakeBand>>[
      for (final HarborWakeMask mask in tester.widgetList<HarborWakeMask>(
        find.ancestor(
          of: find.byWidgetPredicate((final Widget w) => w is StageProbe && w.label == 'Body'),
          matching: find.byType(HarborWakeMask),
        ),
      ))
        if (mask.wakes.isNotEmpty) mask.wakes,
    ];

    /// The wake bands the fairway fades its own rows by.
    Map<HarborEdge, HarborWakeBand> fairwayMask(final WidgetTester tester) => tester
        .widget<HarborWakeMask>(
          find.descendant(of: find.byType(HarborFairway), matching: find.byType(HarborWakeMask)).first,
        )
        .wakes;

    // The header's pier is 62 of status bar and 52 of header from the body's top edge.
    const HarborWakeBand band = HarborWakeBand(dockEdge: 114, wakeEnd: 114 + 24);

    testWidgets('with no wakePainter the fairway fades its own rows', (final WidgetTester tester) async {
      await _pumpEntry(tester, const WakePainterEntry());
      expect(fairwayMask(tester), <HarborEdge, HarborWakeBand>{HarborEdge.top: band});
      expect(bodyMasks(tester), isEmpty);
      expect(_key('tinted wake top'), findsNothing);
      expect(_code(tester), contains('  // No wakePainter: the fairway fades its rows;\n'));
    });

    testWidgets('HarborWakeMask.alphaWake fades the whole body', (final WidgetTester tester) async {
      await _pumpEntry(tester, const WakePainterEntry());
      await _tap(tester, _key('wakePainter: HarborWakeMask.alphaWake'));
      expect(bodyMasks(tester), <Map<HarborEdge, HarborWakeBand>>[
        <HarborEdge, HarborWakeBand>{HarborEdge.top: band},
      ]);
      expect(fairwayMask(tester), isEmpty);
      expect(_key('tinted wake top'), findsNothing);
      expect(_code(tester), contains('  wakePainter: HarborWakeMask.alphaWake, // the whole body fades\n'));
    });

    testWidgets('a custom painter is handed the wake bands', (final WidgetTester tester) async {
      await _pumpEntry(tester, const WakePainterEntry());
      await _tap(tester, _key('wakePainter: tintedWake (your own)'));
      final Rect screen = _screen(tester);
      final double scale = screen.height / 874;
      final Rect haze = tester.getRect(_key('tinted wake top'));
      final Rect header = tester.getRect(_key('wake header'));
      // The band runs from the body's top (the frame's, under the pier) to 24 past the pier's face.
      expect(haze.top, moreOrLessEquals(screen.top, epsilon: 0.5));
      expect(haze.bottom - header.bottom, moreOrLessEquals(24 * scale, epsilon: 0.5));
      // Solid at the body's edge, half at the dock's face, gone at the wake's end.
      final Gradient gradient =
          (tester
                      .widget<DecoratedBox>(
                        find.descendant(of: _key('tinted wake top'), matching: find.byType(DecoratedBox)),
                      )
                      .decoration
                  as BoxDecoration)
              .gradient!;
      expect(gradient.stops, <double>[0, 114 / 138, 1]);
      expect(_key('tinted wake bottom'), findsNothing);
      expect(fairwayMask(tester), isEmpty);
      expect(bodyMasks(tester), isEmpty);
      expect(_code(tester), contains('  wakePainter: tintedWake,\n'));
    });

    testWidgets('the length slider sets how far the wake runs', (final WidgetTester tester) async {
      await _pumpEntry(tester, const WakePainterEntry());
      await _slide(tester, 'length', 1);
      expect(find.text('length 48'), findsOneWidget);
      expect(fairwayMask(tester), <HarborEdge, HarborWakeBand>{
        HarborEdge.top: const HarborWakeBand(dockEdge: 114, wakeEnd: 114 + 48),
      });
      expect(_code(tester), contains('      wake: HarborWake.fade(length: 48),\n'));
      await _tap(tester, _key('wakePainter: tintedWake (your own)'));
      final double scale = _screen(tester).height / 874;
      expect(
        tester.getRect(_key('tinted wake top')).bottom - tester.getRect(_key('wake header')).bottom,
        moreOrLessEquals(48 * scale, epsilon: 0.5),
      );
      // No length: the haze ends at the pier's face.
      await _slide(tester, 'length', 0);
      expect(find.text('length 0'), findsOneWidget);
      expect(
        tester.getRect(_key('tinted wake top')).bottom,
        moreOrLessEquals(tester.getRect(_key('wake header')).bottom, epsilon: 0.5),
      );
      expect(_code(tester), contains('      wake: HarborWake.fade(length: 0),\n'));
    });
  });
}
