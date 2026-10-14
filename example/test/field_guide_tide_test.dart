import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_tide.dart';
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
          HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
      home: entry,
    ),
  );
  await tester.pump();
  await _wholePhone(tester);
  await _step(tester);
  await _showStage(tester);
}

/// Scrolls the guide page so the whole stage and its keyboard button are in view.
Future<void> _showStage(final WidgetTester tester) async {
  await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey<String>('tide toggle'))), alignment: 1.0);
  await tester.pump();
}

/// Steps time: the seas never settle, so no pumpAndSettle.
Future<void> _step(final WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tap(final WidgetTester tester, final String key) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await tester.tap(finder);
  await _step(tester);
  await _showStage(tester);
}

Future<void> _toggleKeyboard(final WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('tide toggle')));
  await _step(tester);
  await _step(tester);
}

/// Sets a partial keyboard by tapping the gauge beside the stage where its
/// level would stand, then lets the keyboard settle there.
Future<void> _setKeyboard(final WidgetTester tester, final double fraction) async {
  final Rect gauge = _rect(tester, 'tide gauge');
  await tester.tapAt(Offset(gauge.center.dx, gauge.top + gauge.height * (1 - fraction)));
  await _step(tester);
  await _step(tester);
}

/// Starts the keyboard button and stops partway, with the keyboard still moving.
Future<void> _toggleKeyboardPartway(final WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey<String>('tide toggle')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

/// The bottom of the phone's screen, inside the stage's bezel.
double _screenBottom(final WidgetTester tester) => _rect(tester, 'stage').bottom - 10;

String _code(final WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const ValueKey<String>('code card')), matching: find.byType(Text)))
    .data!;

Rect _keyboard(final WidgetTester tester) => tester.getRect(find.byType(KeyboardArt));

/// The stage's scale: screen pixels per stage point.
double _scale(final WidgetTester tester) => _keyboard(tester).width / StageDevice.iPhone17.size.width;

String _text(final WidgetTester tester, final String key) =>
    tester.widget<Text>(find.byKey(ValueKey<String>(key))).data!;

void _near(final double actual, final double expected, [final String? reason]) =>
    expect(actual, moreOrLessEquals(expected, epsilon: 0.5), reason: reason);

void main() {
  test('every keyboard entry is in the keyboard group, named as in code', () {
    expect(tideEntries, hasLength(8));
    expect(tideEntries.map((final e) => e.className), <String>[
      'HarborKeyboard.of',
      'HarborKeyboardStance.rides',
      'HarborKeyboardStance.stays',
      'HarborKeyboardStance.rides + .stays',
      'HarborKeyboardStance.reserves',
      'HarborSystemEdgeStance',
      'HarborBar.withdrawsAtHighTide',
      'HarborFrame.bodyClearsKeyboard',
    ]);
  });

  testWidgets('HarborKeyboard.of reads height, remaining, settled height and phase', (final WidgetTester tester) async {
    await _pumpEntry(tester, const TideOfEntry());
    expect(tester.takeException(), isNull);
    expect(_text(tester, 'keyboard phase'), 'hidden');
    expect(_text(tester, 'keyboard settledHeightIsEstimate'), 'true');
    expect(_text(tester, 'keyboard settledHeight'), (874 * 0.4).toStringAsFixed(0));
    // The readout keeps clear of the header.
    expect(_rect(tester, 'keyboard readout').top, greaterThanOrEqualTo(_rect(tester, 'stage header').bottom));
    // The page shows the whole phone, so the readout and the keyboard it reads are both in view.
    expect(find.byKey(const ValueKey<String>('focus toggle')), findsNothing);
    final Rect stage = _rect(tester, 'stage');
    expect(_rect(tester, 'keyboard readout').top, greaterThan(stage.top));
    expect(_rect(tester, 'keyboard readout').bottom, lessThan(stage.bottom));

    await _toggleKeyboard(tester);
    expect(_text(tester, 'keyboard phase'), 'shown');
    expect(_text(tester, 'keyboard height'), '336');
    // The body cleared the keyboard, so none of it remains here.
    expect(_text(tester, 'keyboard remaining'), '0');
    expect(_text(tester, 'keyboard settledHeight'), '336');
    expect(_text(tester, 'keyboard settledHeightIsEstimate'), 'false');

    await _tap(tester, 'toggle bodyClearsKeyboard');
    expect(_text(tester, 'keyboard remaining'), '336');
    await _toggleKeyboard(tester);
    expect(_text(tester, 'keyboard phase'), 'hidden');
    expect(_text(tester, 'keyboard settledHeight'), '336');
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborKeyboard.of reads opening and closing while the keyboard moves', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const TideOfEntry());
    expect(_text(tester, 'keyboard isShown'), 'false');
    expect(find.text('stage keyboard 0'), findsOneWidget);

    await _toggleKeyboardPartway(tester);
    expect(_text(tester, 'keyboard phase'), 'opening');
    expect(_text(tester, 'keyboard isShown'), 'true');
    final double rising = double.parse(_text(tester, 'keyboard height'));
    expect(rising, inExclusiveRange(0, 336));
    expect(find.text('stage keyboard ${rising.toStringAsFixed(0)}'), findsOneWidget);
    // The staff shows the height against the estimate (40% of the screen).
    final double fill = tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byKey(const ValueKey<String>('keyboard readout')),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .widthFactor!;
    _near(fill * 874 * 0.4, rising, 'the gauge fills to the height');
    expect(find.text('settled height: an estimate (40% of the screen)'), findsOneWidget);

    await _step(tester);
    await _step(tester);
    expect(_text(tester, 'keyboard phase'), 'shown');
    expect(find.text('settled height: measured'), findsOneWidget);

    await _toggleKeyboardPartway(tester);
    expect(_text(tester, 'keyboard phase'), 'closing');
    expect(double.parse(_text(tester, 'keyboard height')), inExclusiveRange(0, 336));
    expect(
      _text(tester, 'keyboard settledHeight'),
      '336',
      reason: 'the settled height holds while the keyboard is moving',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborKeyboard.of: a keyboard that settles partway sets the settled height there', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const TideOfEntry());
    await _toggleKeyboard(tester);
    expect(_text(tester, 'keyboard settledHeight'), '336');

    await _setKeyboard(tester, 0.5);
    expect(_text(tester, 'keyboard height'), '168');
    expect(_text(tester, 'keyboard phase'), 'shown');
    expect(_text(tester, 'keyboard isShown'), 'true');
    expect(_text(tester, 'keyboard remaining'), '0');
    expect(_text(tester, 'keyboard settledHeight'), '168', reason: 'the settled height falls as well as rises');
    expect(_text(tester, 'keyboard settledHeightIsEstimate'), 'false');
    expect(find.text('stage keyboard 168'), findsOneWidget);
    _near(_keyboard(tester).height, 168 * _scale(tester));
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborKeyboard.of: bodyClearsKeyboard off leaves a partial keyboard in remaining', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const TideOfEntry());
    expect(_code(tester), contains('bodyClearsKeyboard: true,'));
    expect(_code(tester), contains('final keyboard = HarborKeyboard.of(context);'));
    await _setKeyboard(tester, 0.5);
    _near(_rect(tester, 'stage body').bottom, _keyboard(tester).top, "on: the body ends at the keyboard's top");
    expect(_text(tester, 'keyboard remaining'), '0');

    await _tap(tester, 'toggle bodyClearsKeyboard');
    expect(_code(tester), contains('bodyClearsKeyboard: false,'));
    expect(_text(tester, 'keyboard remaining'), '168');
    expect(_text(tester, 'keyboard height'), '168');
    _near(_rect(tester, 'stage body').bottom, _keyboard(tester).bottom, 'off: the body runs under the keyboard');
    expect(
      find.textContaining(RegExp(r'\nkeyboard 168\n')),
      findsOneWidget,
      reason: 'the body probe is told about the keyboard',
    );
    // The readout keeps clear only at the top, so it stays below the header.
    expect(_rect(tester, 'keyboard readout').top, greaterThanOrEqualTo(_rect(tester, 'stage header').bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rides: the composer rides the keyboard', (final WidgetTester tester) async {
    await _pumpEntry(tester, const FloatEntry());
    final Rect low = _rect(tester, 'composer');
    _near(_rect(tester, 'stage body').bottom, low.top, 'the body ends at the composer');
    await _toggleKeyboard(tester);
    final Rect high = _rect(tester, 'composer');
    _near(high.bottom, _keyboard(tester).top, "the composer sits on the keyboard's top");
    expect(high.top, lessThan(low.top));
    _near(_rect(tester, 'stage body').bottom, high.top);

    await _tap(tester, 'keyboard: stays');
    _near(_rect(tester, 'composer').top, low.top, 'when it stays it stays put under the keyboard');
    await _tap(tester, 'keyboard: rides');
    await _toggleKeyboard(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets("rides: with the keyboard partway up the composer sits on the keyboard's top", (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const FloatEntry());
    final double scale = _scale(tester);
    final Rect low = _rect(tester, 'composer');
    _near(low.bottom + 34 * scale, _screenBottom(tester), 'with the keyboard down it sits on the home indicator');

    await _setKeyboard(tester, 0.5);
    _near(_keyboard(tester).height, 168 * scale);
    final Rect composer = _rect(tester, 'composer');
    _near(composer.bottom, _keyboard(tester).top, 'it rides the keyboard partway up');
    _near(composer.height, low.height);
    _near(_rect(tester, 'stage body').bottom, composer.top, 'the body ends at the composer');
    expect(tester.takeException(), isNull);
  });

  testWidgets('rides: a keyboard shorter than the home indicator leaves the composer where it is', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const FloatEntry());
    final double low = _rect(tester, 'composer').bottom;
    // 5% of 336 is under 17pt: the keyboard is still inside the home
    // indicator's 34, so the composer neither dips nor rises yet.
    await _setKeyboard(tester, 0.05);
    expect(_keyboard(tester).height, greaterThan(0));
    _near(_rect(tester, 'composer').bottom, low, 'no dip');
    await _setKeyboard(tester, 0.2);
    _near(_rect(tester, 'composer').bottom, _keyboard(tester).top, 'past the home indicator it rides the keyboard');
    expect(tester.takeException(), isNull);
  });

  testWidgets('rides: the keyboard chip switches the composer to stays', (final WidgetTester tester) async {
    await _pumpEntry(tester, const FloatEntry());
    expect(find.text('keyboard: rides'), findsWidgets);
    expect(_code(tester), contains('keyboard: HarborKeyboardStance.rides,'));
    final Rect low = _rect(tester, 'composer');

    await _tap(tester, 'keyboard: stays');
    expect(_code(tester), contains('keyboard: HarborKeyboardStance.stays,'));
    expect(
      find.descendant(of: find.byKey(const ValueKey<String>('composer')), matching: find.text('keyboard: stays')),
      findsOneWidget,
    );
    _near(_rect(tester, 'composer').top, low.top, 'with the keyboard down rides and stays sit alike');

    await _setKeyboard(tester, 0.5);
    _near(_rect(tester, 'composer').top, low.top, 'when it stays it stays put');
    expect(_keyboard(tester).top, lessThan(_rect(tester, 'composer').top), reason: 'the keyboard covers it');
    _near(_rect(tester, 'stage body').bottom, _keyboard(tester).top, "the body ends at the keyboard's top");
    expect(tester.takeException(), isNull);
  });

  testWidgets("stays: the tab bar stays put and the body ends at the keyboard's top", (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const PilingsEntry());
    final Rect low = _rect(tester, 'tab bar');
    _near(_rect(tester, 'stage body').bottom, low.top);
    await _toggleKeyboard(tester);
    final Rect high = _rect(tester, 'tab bar');
    _near(high.top, low.top);
    _near(high.height, low.height);
    _near(_rect(tester, 'stage body').bottom, _keyboard(tester).top, "the body ends at the keyboard's top");
    expect(_keyboard(tester).top, lessThan(high.top), reason: 'the keyboard covers the tab bar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays: a keyboard lower than the tab bar leaves the body ending at the tab bar', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const PilingsEntry());
    final double scale = _scale(tester);
    final Rect low = _rect(tester, 'tab bar');
    _near(low.bottom + 34 * scale, _screenBottom(tester), 'the tab bar keeps the home indicator under it');

    // 20% of 336 is 67, short of the tab bar's 56 + 34.
    await _setKeyboard(tester, 0.2);
    final Rect keyboard = _keyboard(tester);
    _near(keyboard.height, 336 * 0.2 * scale);
    expect(keyboard.top, greaterThan(low.top), reason: 'the keyboard covers only the tab bar\'s lower part');
    _near(_rect(tester, 'tab bar').top, low.top);
    _near(_rect(tester, 'stage body').bottom, low.top, 'the body still ends at the tab bar');

    await _setKeyboard(tester, 0.5);
    _near(_rect(tester, 'tab bar').top, low.top);
    _near(
      _rect(tester, 'stage body').bottom,
      _keyboard(tester).top,
      "past the tab bar, the body ends at the keyboard's top",
    );
    expect(
      find.textContaining(RegExp(r'\nkeyboard 0\n')),
      findsOneWidget,
      reason: 'the body is not told about the keyboard',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the readings survive the keyboard coming up and going down', (final WidgetTester tester) async {
    // With a tab bar that stays, the body's probe never rebuilds with the keyboard up: its reading
    // has to stay rather than be cleared with every stage change.
    await _pumpEntry(tester, const PilingsEntry());
    expect(find.text('Readings'), findsOneWidget);
    await _toggleKeyboard(tester);
    expect(find.text('Readings'), findsOneWidget);
    await _toggleKeyboard(tester);
    expect(find.text('Readings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rides + stays: the composer sits on the tab bar, then rides past it', (final WidgetTester tester) async {
    await _pumpEntry(tester, const FloatAndPilingsEntry());
    final Rect tabLow = _rect(tester, 'tab bar');
    _near(_rect(tester, 'composer').bottom, tabLow.top, 'with the keyboard down the composer sits on the tab bar');
    await _toggleKeyboard(tester);
    final Rect composer = _rect(tester, 'composer');
    _near(composer.bottom, _keyboard(tester).top);
    expect(composer.bottom, lessThan(tabLow.top));
    _near(_rect(tester, 'tab bar').top, tabLow.top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rides + stays: the composer waits on the tab bar until the keyboard passes it', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const FloatAndPilingsEntry());
    final Rect tabLow = _rect(tester, 'tab bar');
    final Rect composerLow = _rect(tester, 'composer');
    _near(_rect(tester, 'stage body').bottom, composerLow.top);

    await _setKeyboard(tester, 0.2);
    expect(_keyboard(tester).top, greaterThan(tabLow.top), reason: 'the keyboard is still below the tab bar');
    _near(_rect(tester, 'composer').top, composerLow.top, 'the composer stays on the tab bar');
    _near(_rect(tester, 'tab bar').top, tabLow.top);
    _near(_rect(tester, 'stage body').bottom, composerLow.top);

    await _setKeyboard(tester, 0.5);
    final Rect composer = _rect(tester, 'composer');
    _near(composer.bottom, _keyboard(tester).top, 'past the tab bar the composer rides the keyboard');
    expect(composer.bottom, lessThan(tabLow.top));
    _near(_rect(tester, 'tab bar').top, tabLow.top, 'the tab bar stays under it');
    _near(_rect(tester, 'stage body').bottom, composer.top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves: keeps the keyboard\'s ground with the keyboard down and up', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const DryDockEntry());
    // The height settles once.
    await _toggleKeyboard(tester);
    final Rect ground = _rect(tester, 'keyboard space');
    final Rect keyboard = _keyboard(tester);
    _near(ground.height, keyboard.height, 'the keyboard covers the exact ground');
    _near(ground.top, keyboard.top);
    final double tabsTop = _rect(tester, 'reserve tabs').top;
    expect(_text(tester, 'reserve settled height'), 'settledHeight 336');

    await _toggleKeyboard(tester);
    final Rect lowGround = _rect(tester, 'keyboard space');
    _near(lowGround.height, ground.height, 'the ground holds with the keyboard down');
    _near(_rect(tester, 'reserve tabs').top, tabsTop, 'nothing above moves');
    _near(_rect(tester, 'stage body').bottom, tabsTop);

    await _tap(tester, 'toggle showsChildWithKeyboard');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves: before the height settles it keeps the 40% estimate, to the screen\'s edge', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const DryDockEntry());
    final double scale = _scale(tester);
    expect(_text(tester, 'reserve settled height'), 'settledHeight ${(874 * 0.4).toStringAsFixed(0)} (estimate)');
    final Rect ground = _rect(tester, 'keyboard space');
    _near(ground.height, 874 * 0.4 * scale);
    _near(ground.bottom, _screenBottom(tester), 'a reserving bar takes no system edge: its ground runs to the edge');
    _near(_rect(tester, 'reserve tabs').bottom, ground.top);
    expect(
      find.byKey(const ValueKey<String>('reserve swatches')),
      findsOneWidget,
      reason: 'the panel shows with the keyboard down',
    );
    _near(_rect(tester, 'reserve swatches').height, ground.height);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves: nothing above moves while the keyboard comes up', (final WidgetTester tester) async {
    await _pumpEntry(tester, const DryDockEntry());
    // The height settles once.
    await _toggleKeyboard(tester);
    await _toggleKeyboard(tester);
    final double tabsTop = _rect(tester, 'reserve tabs').top;
    final double groundHeight = _rect(tester, 'keyboard space').height;

    await _toggleKeyboardPartway(tester);
    expect(_keyboard(tester).height, inExclusiveRange(0, groundHeight), reason: 'the keyboard is partway up');
    _near(_rect(tester, 'reserve tabs').top, tabsTop, 'the tabs hold still');
    _near(_rect(tester, 'keyboard space').height, groundHeight, 'the ground holds');
    _near(_rect(tester, 'stage body').bottom, tabsTop, 'the body holds');
    expect(_text(tester, 'reserve settled height'), 'settledHeight 336');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves: a keyboard that settles partway resets the ground to it', (final WidgetTester tester) async {
    await _pumpEntry(tester, const DryDockEntry());
    await _toggleKeyboard(tester);
    await _setKeyboard(tester, 0.5);
    expect(_text(tester, 'reserve settled height'), 'settledHeight 168');
    final Rect ground = _rect(tester, 'keyboard space');
    final Rect keyboard = _keyboard(tester);
    _near(ground.height, keyboard.height, 'the shorter keyboard covers the exact ground');
    _near(ground.top, keyboard.top);
    _near(_rect(tester, 'stage body').bottom, _rect(tester, 'reserve tabs').top);
    expect(find.byKey(const ValueKey<String>('reserve swatches')), findsNothing, reason: 'the keyboard is up');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reserves: showsChildWithKeyboard keeps the panel under the keyboard', (final WidgetTester tester) async {
    await _pumpEntry(tester, const DryDockEntry());
    final Finder swatches = find.byKey(const ValueKey<String>('reserve swatches'));
    expect(_code(tester), isNot(contains('showsChildWithKeyboard')));
    await _toggleKeyboard(tester);
    expect(swatches, findsNothing, reason: 'off: the panel hides while the keyboard is up');

    await _tap(tester, 'toggle showsChildWithKeyboard');
    expect(_code(tester), contains('showsChildWithKeyboard: true,'));
    expect(swatches, findsOneWidget, reason: 'on: the panel stays');
    final Rect ground = _rect(tester, 'keyboard space');
    _near(tester.getRect(swatches).top, ground.top);
    _near(tester.getRect(swatches).height, ground.height);
    _near(ground.top, _keyboard(tester).top, 'the panel still fills the keyboard\'s ground');

    await _toggleKeyboard(tester);
    expect(swatches, findsOneWidget, reason: 'and it shows with the keyboard down either way');
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborSystemEdgeStance: live drops the home indicator, steady and none hold', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const CoastStanceEntry());
    final double scale = _scale(tester);
    Future<(double, double)> heights() async {
      final double low = _rect(tester, 'system edge bar ground').height;
      await _toggleKeyboard(tester);
      final double high = _rect(tester, 'system edge bar ground').height;
      await _toggleKeyboard(tester);
      return (low, high);
    }

    final (double liveLow, double liveHigh) = await heights();
    _near(liveLow - liveHigh, 34 * scale, 'live: the home indicator goes away with the keyboard');

    await _tap(tester, 'systemEdges: steady');
    final (double steadyLow, double steadyHigh) = await heights();
    _near(steadyLow, steadyHigh, 'steady: it holds');
    _near(steadyLow, liveLow);

    await _tap(tester, 'systemEdges: none');
    final (double noneLow, double noneHigh) = await heights();
    _near(noneLow, noneHigh);
    _near(noneLow, 56 * scale, 'none: only the bar');
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborSystemEdgeStance: each chip names its stance on the bar and in the code', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const CoastStanceEntry());
    final Finder bar = find.byKey(const ValueKey<String>('composer'));
    for (final String stance in <String>['live', 'steady', 'none']) {
      await _tap(tester, 'systemEdges: $stance');
      expect(find.descendant(of: bar, matching: find.text('systemEdges: $stance')), findsOneWidget);
      expect(_code(tester), contains('systemEdges: HarborSystemEdgeStance.$stance,'));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('HarborSystemEdgeStance: the hatched band is the system edge the bar took', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const CoastStanceEntry());
    final double scale = _scale(tester);
    // live, with the keyboard down: the bar and the home indicator under it.
    expect(find.text('bar 90'), findsOneWidget);
    expect(find.text('system edge 34'), findsOneWidget);
    _near(_rect(tester, 'system edge bar ground').bottom, _screenBottom(tester));
    _near(_rect(tester, 'composer').bottom + 34 * scale, _screenBottom(tester));

    await _tap(tester, 'systemEdges: none');
    expect(find.text('bar 56'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^system edge \d')), findsNothing, reason: 'none: no system edge is taken');
    _near(_rect(tester, 'composer').bottom, _screenBottom(tester), 'the bar runs to the screen\'s edge');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HarborSystemEdgeStance: with the keyboard partway up live has dropped the system edge and steady keeps it',
    (final WidgetTester tester) async {
      await _pumpEntry(tester, const CoastStanceEntry());
      final double scale = _scale(tester);
      await _setKeyboard(tester, 0.5);
      expect(find.text('bar 56'), findsOneWidget, reason: 'live: the home indicator went with the keyboard');
      expect(find.textContaining(RegExp(r'^system edge \d')), findsNothing);
      _near(_rect(tester, 'composer').bottom, _keyboard(tester).top, "the bar sits on the keyboard's top");

      await _tap(tester, 'systemEdges: steady');
      expect(find.text('bar 90'), findsOneWidget, reason: 'steady: it holds its height');
      expect(find.text('system edge 34'), findsOneWidget);
      _near(_rect(tester, 'system edge bar ground').bottom, _keyboard(tester).top, 'the bar still rides the keyboard');
      _near(
        _rect(tester, 'composer').bottom + 34 * scale,
        _keyboard(tester).top,
        'with the band between bar and keyboard',
      );

      await _tap(tester, 'systemEdges: none');
      expect(find.text('bar 56'), findsOneWidget);
      _near(_rect(tester, 'composer').bottom, _keyboard(tester).top);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('withdrawsAtHighTide: the tool strip leaves while the keyboard is up', (final WidgetTester tester) async {
    await _pumpEntry(tester, const WithdrawsAtHighTideEntry());
    _near(_rect(tester, 'tool strip').bottom, _rect(tester, 'composer').top);
    _near(_rect(tester, 'stage body').bottom, _rect(tester, 'tool strip').top);
    await _toggleKeyboard(tester);
    _near(_rect(tester, 'stage body').bottom, _rect(tester, 'composer').top, 'the strip gave its ground back');

    await _tap(tester, 'toggle withdrawsAtHighTide');
    await _step(tester);
    _near(_rect(tester, 'tool strip').bottom, _rect(tester, 'composer').top, 'off: it rides on the composer');
    _near(_rect(tester, 'stage body').bottom, _rect(tester, 'tool strip').top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('withdrawsAtHighTide: the strip leaves as soon as any keyboard is in', (final WidgetTester tester) async {
    await _pumpEntry(tester, const WithdrawsAtHighTideEntry());
    final Finder strip = find.byKey(const ValueKey<String>('tool strip'));
    expect(strip.hitTestable(), findsOneWidget);

    await _setKeyboard(tester, 0.3);
    expect(strip.hitTestable(), findsNothing, reason: 'it is withdrawn and takes no taps');
    final Rect composer = _rect(tester, 'composer');
    _near(composer.bottom, _keyboard(tester).top, 'the composer rides the keyboard');
    _near(_rect(tester, 'stage body').bottom, composer.top, 'the body grows into the strip\'s ground');
    expect(tester.takeException(), isNull);
  });

  testWidgets('withdrawsAtHighTide: the strip comes back when the keyboard goes down', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const WithdrawsAtHighTideEntry());
    final Rect low = _rect(tester, 'tool strip');
    await _toggleKeyboard(tester);
    await _toggleKeyboard(tester);
    // The strip slides back once the keyboard is down.
    await _step(tester);
    final Finder strip = find.byKey(const ValueKey<String>('tool strip'));
    expect(strip.hitTestable(), findsOneWidget);
    _near(_rect(tester, 'tool strip').top, low.top);
    _near(_rect(tester, 'tool strip').bottom, _rect(tester, 'composer').top);
    _near(_rect(tester, 'stage body').bottom, low.top, 'the body gives the ground back');
    expect(tester.takeException(), isNull);
  });

  testWidgets('withdrawsAtHighTide off: the strip rides the composer with the keyboard partway up', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const WithdrawsAtHighTideEntry());
    expect(find.text('withdrawsAtHighTide: true'), findsOneWidget);
    expect(_code(tester), contains('withdrawsAtHighTide: true,'));

    await _tap(tester, 'toggle withdrawsAtHighTide');
    expect(find.text('withdrawsAtHighTide: false'), findsOneWidget, reason: 'the strip names the setting');
    expect(_code(tester), contains('withdrawsAtHighTide: false,'));

    await _setKeyboard(tester, 0.3);
    final Rect composer = _rect(tester, 'composer');
    _near(composer.bottom, _keyboard(tester).top);
    _near(_rect(tester, 'tool strip').bottom, composer.top, 'the strip stays on the composer');
    expect(find.byKey(const ValueKey<String>('tool strip')).hitTestable(), findsOneWidget);
    _near(_rect(tester, 'stage body').bottom, _rect(tester, 'tool strip').top);
    expect(tester.takeException(), isNull);
  });

  testWidgets("bodyClearsKeyboard: the body ends at the keyboard's top or runs under it", (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const BodyClearsTideEntry());
    await _toggleKeyboard(tester);
    final double scale = _scale(tester);
    final Rect keyboard = _keyboard(tester);
    _near(_rect(tester, 'stage body').bottom, keyboard.top, "on: the body ends at the keyboard's top");
    _near(_rect(tester, 'clear marker').bottom + 28 * scale, keyboard.top);

    await _tap(tester, 'toggle bodyClearsKeyboard');
    _near(_rect(tester, 'stage body').bottom, keyboard.bottom, 'off: the body runs under the keyboard');
    _near(_rect(tester, 'clear marker').bottom + 28 * scale, keyboard.top, 'the HarborClear box still keeps clear');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bodyClearsKeyboard with the keyboard partway up: the probe reads 0 on and the keyboard off', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const BodyClearsTideEntry());
    final double scale = _scale(tester);
    expect(_code(tester), contains('bodyClearsKeyboard: true,'));
    await _setKeyboard(tester, 0.5);
    final Rect keyboard = _keyboard(tester);
    _near(keyboard.height, 168 * scale);
    _near(_rect(tester, 'stage body').bottom, keyboard.top);
    _near(_rect(tester, 'clear marker').bottom + 28 * scale, keyboard.top);
    expect(find.text('HarborFrame body (bodyClearsKeyboard: true)'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\nkeyboard 0\n')), findsOneWidget);

    await _tap(tester, 'toggle bodyClearsKeyboard');
    expect(_code(tester), contains('bodyClearsKeyboard: false,'));
    expect(find.text('HarborFrame body (bodyClearsKeyboard: false)'), findsOneWidget);
    expect(
      find.text('HarborFrame body (bodyClearsKeyboard: true)'),
      findsNothing,
      reason: 'the old reading is dropped',
    );
    expect(
      find.textContaining(RegExp(r'\nkeyboard 168\n')),
      findsOneWidget,
      reason: 'off: the body is told how far it reaches',
    );
    _near(_rect(tester, 'stage body').bottom, keyboard.bottom);
    _near(_rect(tester, 'clear marker').bottom + 28 * scale, keyboard.top, 'the HarborClear box keeps clear');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bodyClearsKeyboard changes nothing with the keyboard down', (final WidgetTester tester) async {
    await _pumpEntry(tester, const BodyClearsTideEntry());
    final double scale = _scale(tester);
    final Rect body = _rect(tester, 'stage body');
    final Rect marker = _rect(tester, 'clear marker');
    _near(body.bottom, _screenBottom(tester));
    _near(
      marker.bottom + 28 * scale,
      _screenBottom(tester) - 34 * scale,
      'the marker keeps clear of the home indicator',
    );

    await _tap(tester, 'toggle bodyClearsKeyboard');
    _near(_rect(tester, 'stage body').bottom, body.bottom);
    _near(_rect(tester, 'clear marker').bottom, marker.bottom);
    expect(find.textContaining(RegExp(r'\nkeyboard 0\n')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("a bottom crop draws the phone bigger and rides up with the keyboard's top", (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const PilingsEntry());
    final double wholeScale = _scale(tester);
    // Back to the page's own crop: the bottom of the phone.
    await _wholePhone(tester);
    final double scale = _scale(tester);
    expect(scale, greaterThan(wholeScale * 1.3), reason: 'the crop shows less of the phone, bigger');
    final Rect stage = tester.getRect(find.byKey(const ValueKey<String>('stage')));
    _near(_rect(tester, 'tab bar').bottom + 34 * scale, stage.bottom - 10, 'the bottom of the phone is in view');
    expect(_rect(tester, 'tab bar').top, greaterThan(stage.top));

    await _toggleKeyboard(tester);
    await tester.pump(const Duration(milliseconds: 400));
    // The view rose with the keyboard, keeping its top edge in sight.
    final Rect risen = tester.getRect(find.byKey(const ValueKey<String>('stage')));
    _near(risen.bottom, _keyboard(tester).top + 96 * scale, 'the keyboard top stays in view');
    _near(_rect(tester, 'stage body').bottom, _keyboard(tester).top, "and the body still ends at the keyboard's top");
    expect(tester.takeException(), isNull);
  });

  testWidgets('folding the controls gives the stage the room', (final WidgetTester tester) async {
    await _pumpEntry(tester, const PilingsEntry());
    final double before = _scale(tester);
    final Finder handle = find.byKey(const ValueKey<String>('control quay handle'));
    final double controlsTop = tester.getRect(handle).top;
    await tester.tap(handle);
    await _step(tester);
    expect(tester.getRect(handle).top, greaterThan(controlsTop), reason: 'the controls folded down');
    expect(_scale(tester), greaterThan(before), reason: 'the stage grew into the space');
    await tester.tap(handle);
    await _step(tester);
    _near(_scale(tester), before);
    expect(tester.takeException(), isNull);
  });
}
