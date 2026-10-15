import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_content.dart';
import 'package:harbor_example/field_guide/entries_docks.dart';
import 'package:harbor_example/field_guide/entries_frames.dart';
import 'package:harbor_example/field_guide/guide_page.dart' show ProbeReadout;
import 'package:harbor_example/field_guide/stage.dart' show StatusBarArt;

const double _deviceWidth = 402;
const double _statusBar = 62;
const double _homeIndicator = 34;
const double _keyboard = 336;
const Set<String> _stageToggles = <String>{
  'toggle Status bar',
  'toggle Home indicator',
  'toggle Right-to-left',
  'toggle HarborInspectorOverlay',
};

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
  await _settle(tester);
  await _showStage(tester);
}

Future<void> _settle(final WidgetTester tester, {final int steps = 4}) async {
  for (int i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _showStage(final WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey<String>('stage')));
  await _settle(tester, steps: 2);
}

/// The phone's screen on the stage, and how far the stage scales it.
({Rect screen, double scale}) _screen(final WidgetTester tester, {final double deviceWidth = _deviceWidth}) {
  final Rect screen = tester.getRect(find.byKey(const ValueKey<String>('stage'))).deflate(10);
  return (screen: screen, scale: screen.width / deviceWidth);
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Finder _onStage(final Finder finder) =>
    find.descendant(of: find.byKey(const ValueKey<String>('stage')), matching: finder);

/// Taps a control and lets everything it starts run out.
Future<void> _tapKey(final WidgetTester tester, final String key) async {
  await _tapNow(tester, key);
  await _settle(tester);
}

/// Taps a control and pumps a single frame, for watching what it starts.
Future<void> _tapNow(final WidgetTester tester, final String key) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Sets a slider control to [value], as dragging its thumb there would.
Future<void> _slide(final WidgetTester tester, final String label, final double value) async {
  final Finder finder = find.byKey(ValueKey<String>('slider $label'));
  await tester.ensureVisible(finder);
  await tester.pump();
  tester.widget<Slider>(finder).onChanged!(value);
  await _settle(tester);
}

/// Shows the keyboard or hides it again.
Future<void> _toggleKeyboard(final WidgetTester tester) => _tapKey(tester, 'tide toggle');

/// What the code card under the stage says.
String _code(final WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const ValueKey<String>('code card')), matching: find.byType(Text)))
    .data!;

/// Opens the stage settings and picks a device or flips a stage switch.
Future<void> _stageSetting(final WidgetTester tester, final String key) async {
  if (find.byKey(ValueKey<String>(key)).evaluate().isEmpty) {
    await _tapKey(tester, 'stage settings');
  }
  await _tapKey(tester, key);
  await _showStage(tester);
}

/// Taps every option chip and switch of the entry (not the stage's own), and the keyboard toggle.
Future<void> _tapEveryControl(final WidgetTester tester) async {
  final Set<String> tapped = <String>{};
  for (int pass = 0; pass < 4; pass++) {
    final List<String> keys = <String>[
      for (final Widget w in tester.widgetList(
        find.byWidgetPredicate((final Widget w) => w is ChoiceChip || w is SwitchListTile),
      ))
        if (w.key case final ValueKey<String> key) key.value,
    ].where((final String k) => !k.startsWith('Device:') && !_stageToggles.contains(k) && !tapped.contains(k)).toList();
    if (keys.isEmpty) {
      break;
    }
    for (final String key in keys) {
      tapped.add(key);
      if (find.byKey(ValueKey<String>(key)).evaluate().isEmpty) {
        continue;
      }
      await _tapKey(tester, key);
      expect(tester.takeException(), isNull, reason: 'after tapping $key');
    }
  }
  await _toggleKeyboard(tester);
  await _toggleKeyboard(tester);
  expect(tester.takeException(), isNull);
}

void _near(final double actual, final double expected, final String what) =>
    expect(actual, moreOrLessEquals(expected, epsilon: 0.75), reason: what);

/// The fade bands the scroll view holding [row] fades its rows along.
Map<HarborEdge, HarborFadeBand> _fadesOver(final WidgetTester tester, final String row) => tester
    .widget<HarborFadeMask>(
      find.ancestor(of: find.byKey(ValueKey<String>(row)), matching: find.byType(HarborFadeMask)).first,
    )
    .bands;

/// The render box that draws a bar's frame (and its hairline), found from
/// something in the bar.
RenderBox _barFrameOf(final WidgetTester tester, final Finder inBar) {
  RenderObject? node = tester.renderObject(inBar);
  while (node != null && node.runtimeType.toString() != 'RenderHarborBarFrame') {
    node = node.parent;
  }
  expect(node, isNotNull, reason: 'a bar frame above the bar\'s child');
  return node! as RenderBox;
}

void main() {
  test('the entries are listed in their groups', () {
    expect(frameEntries.map((final e) => e.className), <String>[
      'HarborFrame',
      'HarborRoot',
      'HarborFrame(isPage: true)',
      'HarborSizing.hug',
    ]);
    expect(dockEntries.map((final e) => e.className), <String>[
      'HarborBar.overlay',
      'HarborBar.solid',
      'bottom: [composer, tabBar]',
      'HarborBarState',
      'HarborBar.restingExtent + HarborFollow',
      'HarborBar.hitTestBehavior',
      'HarborBar.reserve',
    ]);
  });

  group('HarborFrame', () {
    testWidgets('the body starts below the top solid bar and rows keep the margin', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HarborEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect body = _rect(tester, 'harbor body');
      _near(body.top, _rect(tester, 'top bar').bottom, 'body top at the top bar');
      _near(_rect(tester, 'top bar').top - screen.top, _statusBar * scale, 'the bar pads itself below the status bar');
      _near(body.bottom, _rect(tester, 'bottom bar').top, 'body bottom at the bottom bar');
      _near(
        screen.bottom - _rect(tester, 'bottom bar').bottom,
        _homeIndicator * scale,
        'the bar sits above the home indicator',
      );
      _near(_rect(tester, 'row insets marker').left - body.left, 16 * scale, 'row insets');
      _near(body.left, screen.left, 'the body runs to the frame\'s edge');
      expect(_code(tester), contains('top: [HarborBar.solid(child: Header())]'));
      expect(_code(tester), contains('bottom: [HarborBar.solid(child: TabBar())]'));
    });

    testWidgets('top bar off: the body starts at the top of the screen', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HarborEntry());
      await _tapKey(tester, 'toggle top bar');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('top bar')), findsNothing);
      _near(_rect(tester, 'harbor body').top, screen.top, 'body top at the screen top');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'bottom bar').top, 'the bottom bar still holds');
      expect(_code(tester), isNot(contains('top:')));
    });

    testWidgets('bottom bar off: the body runs to the bottom of the screen', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HarborEntry());
      await _tapKey(tester, 'toggle bottom bar');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('bottom bar')), findsNothing);
      _near(_rect(tester, 'harbor body').bottom, screen.bottom, 'body bottom at the screen bottom');
      _near(_rect(tester, 'harbor body').top, _rect(tester, 'top bar').bottom, 'the top bar still holds');
      expect(_code(tester), isNot(contains('bottom:')));
    });

    testWidgets('margin: rows keep the margin the slider sets', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HarborEntry());
      await _slide(tester, 'margin', 32);
      await _showStage(tester);
      final (screen: _, :double scale) = _screen(tester);
      _near(
        _rect(tester, 'row insets marker').left - _rect(tester, 'harbor body').left,
        32 * scale,
        'row insets at 32',
      );
      expect(_code(tester), contains('EdgeInsetsDirectional.symmetric(horizontal: 32)'));
      await _slide(tester, 'margin', 0);
      await _showStage(tester);
      _near(
        _rect(tester, 'row insets marker').left,
        _rect(tester, 'harbor body').left,
        'no margin: rows at the body\'s edge',
      );
    });

    testWidgets('bodyClearsKeyboard on: the body ends at the keyboard top when the keyboard is up', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborEntry());
      await _toggleKeyboard(tester);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(screen.bottom - _rect(tester, 'harbor body').bottom, _keyboard * scale, 'body bottom at the keyboard top');
      expect(
        find.textContaining('keyboard 0'),
        findsOneWidget,
        reason: 'nothing of the keyboard reaches over the body',
      );
      expect(_code(tester), contains('bodyClearsKeyboard: true'));
    });

    testWidgets('bodyClearsKeyboard off: the body runs under the keyboard and is told how far it reaches', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborEntry());
      await _tapKey(tester, 'toggle bodyClearsKeyboard');
      await _toggleKeyboard(tester);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect body = _rect(tester, 'harbor body');
      _near(body.bottom, _rect(tester, 'bottom bar').top, 'the body still ends at the bottom bar');
      final double underBar = (screen.bottom - body.bottom) / scale;
      expect(underBar, lessThan(_keyboard - 100), reason: 'the body reaches well under the keyboard');
      expect(find.textContaining('keyboard ${(_keyboard - underBar).toStringAsFixed(0)}'), findsOneWidget);
      expect(_code(tester), contains('bodyClearsKeyboard: false'));
    });
  });

  group('HarborRoot', () {
    testWidgets('HarborClear content clears the system edges and keeps the root\'s margin', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborRootEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'clear marker').top - screen.top, (_statusBar + 12) * scale, 'below the status bar');
      _near(_rect(tester, 'clear marker').left - screen.left, 16 * scale, 'the root\'s margin');
      _near(screen.right - _rect(tester, 'clear marker').right, 16 * scale, 'the margin on the end side too');
      expect(find.text('systemEdges T 62'), findsOneWidget);
      expect(find.text('systemEdges B 34'), findsOneWidget);
      expect(_code(tester), startsWith('MaterialApp('));
    });

    // Breaks if: the stage draws a portrait status bar on a phone on its side (it spilled over the
    // marker), or the system edge readings sit in a corner where the screen's curve and the side
    // system edge cut them off, or vanish with a 0 band. Jonah saw all three on the web build.
    // Hiding the status bar hides the bar, not the phone: the island and the camera are hardware.
    testWidgets('a hidden status bar takes its time and icons, and leaves the island or camera', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborRootEntry());
      expect(
        tester.widget<StatusBarArt>(find.byType(StatusBarArt)).icons,
        isTrue,
        reason: 'positive control: the bar is drawn',
      );
      await _stageSetting(tester, 'toggle Status bar');
      final StatusBarArt island = tester.widget<StatusBarArt>(find.byType(StatusBarArt));
      expect(island.icons, isFalse);
      expect(island.island, isTrue);
      await _stageSetting(tester, 'Device: Android gesture');
      final StatusBarArt camera = tester.widget<StatusBarArt>(find.byType(StatusBarArt));
      expect(camera.icons, isFalse);
      expect(camera.camera, isTrue);
      await _stageSetting(tester, 'Device: Android 3-button');
      expect(find.byType(StatusBarArt), findsNothing, reason: 'no cutout: nothing is left at the top');
    });

    testWidgets('on a phone on its side there is no status bar, and the system edge readings stay in view', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborRootEntry());
      await _stageSetting(tester, 'Device: iPhone 17 landscape');
      await _showStage(tester);
      expect(find.byType(StatusBarArt), findsNothing, reason: 'no top system edge, no status bar');
      expect(
        find.byKey(const ValueKey<String>('side island')),
        findsOneWidget,
        reason: 'the island sits in the left system edge',
      );
      final (:Rect screen, scale: _) = _screen(tester);
      // The landscape screen's own scale: 874 points across.
      final double scale = screen.width / 874;
      final Rect labels = _rect(tester, 'system edge labels');
      expect(screen.right - labels.right, greaterThanOrEqualTo(62 * scale), reason: 'clear of the right system edge');
      expect(labels.bottom, lessThanOrEqualTo(screen.bottom - 21 * scale), reason: 'above the bottom system edge');
      expect(find.text('systemEdges T 0'), findsOneWidget);
      expect(find.text('systemEdges B 21'), findsOneWidget);
      await _tapKey(tester, 'toggle Home indicator');
      expect(find.text('systemEdges B 0'), findsOneWidget, reason: 'a 0 system edge still reads 0');
    });

    // An Android phone on its side keeps its status bar (Jonah asked for it), and with three
    // buttons its navigation bar moves to the right, where the home indicator switch hides it.
    testWidgets('an Android phone on its side keeps its status bar, and its navigation bar is on the right', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HarborRootEntry());
      await _stageSetting(tester, 'Device: Android 3-button landscape');
      await _showStage(tester);
      final StatusBarArt bar = tester.widget<StatusBarArt>(find.byType(StatusBarArt));
      expect(bar.icons, isTrue);
      expect(bar.camera, isFalse);
      expect(find.byKey(const ValueKey<String>('side navigation bar')), findsOneWidget);
      final (:Rect screen, scale: _) = _screen(tester);
      final double scale = screen.width / 915;
      _near(_rect(tester, 'clear marker').top - screen.top, (24 + 12) * scale, 'below the status bar');
      _near(screen.right - _rect(tester, 'clear marker').right, (48 + 16) * scale, 'clear of the navigation bar');
      _near(_rect(tester, 'clear marker').left - screen.left, 16 * scale, 'no system edge on the left');
      await _tapKey(tester, 'toggle Home indicator');
      expect(find.byKey(const ValueKey<String>('side navigation bar')), findsNothing);
      _near(screen.right - _rect(tester, 'clear marker').right, 16 * scale, 'the navigation bar gives its side back');
    });

    testWidgets(
      'an Android gesture phone on its side has its camera on the left, which stays when the status bar is hidden',
      (final WidgetTester tester) async {
        await _pumpEntry(tester, const HarborRootEntry());
        await _stageSetting(tester, 'Device: Android gesture landscape');
        await _showStage(tester);
        expect(
          tester.widget<StatusBarArt>(find.byType(StatusBarArt)).camera,
          isFalse,
          reason: 'the camera has left the top',
        );
        expect(find.byKey(const ValueKey<String>('side camera')), findsOneWidget);
        final (:Rect screen, scale: _) = _screen(tester);
        final double scale = screen.width / 915;
        _near(_rect(tester, 'clear marker').left - screen.left, (24 + 16) * scale, 'clear of the camera');
        expect(find.text('systemEdges B 24'), findsOneWidget);
        await _stageSetting(tester, 'toggle Status bar');
        expect(find.byType(StatusBarArt), findsNothing, reason: 'the cutout is on the side: the top is all status bar');
        expect(find.byKey(const ValueKey<String>('side camera')), findsOneWidget, reason: 'the camera is hardware');
      },
    );

    testWidgets('nested HarborRoot: the outer bar reads as a system edge', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HarborRootEntry());
      await _tapKey(tester, 'toggle nested HarborRoot');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'outer bar').bottom - screen.top, (_statusBar + 52) * scale, 'the bar under the status bar');
      _near(_rect(tester, 'clear marker').top, _rect(tester, 'outer bar').bottom + 12 * scale, 'below the outer bar');
      _near(_rect(tester, 'clear marker').left - screen.left, 16 * scale, 'the nested root\'s margin');
      expect(find.text('systemEdges T 114'), findsOneWidget);
      expect(find.text('systemEdges B 34'), findsOneWidget);
      expect(_code(tester), contains('body: HarborRoot(child: preview)'));
    });
  });

  group('HarborFrame(isPage:)', () {
    testWidgets('isPage off: the inner header sits under the outer one', (final WidgetTester tester) async {
      await _pumpEntry(tester, const PageEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'inner header').top, _rect(tester, 'outer header').bottom, 'sees the outer bars');
      _near(
        _rect(tester, 'inner header').top - screen.top,
        (_statusBar + 52) * scale,
        'below the status bar and outer header',
      );
      _near(
        _rect(tester, 'stage row 0').top,
        _rect(tester, 'inner header').bottom + 12 * scale,
        'rows rest past the inner fade',
      );
      expect(find.text('HarborFrame(isPage: false)'), findsOneWidget);
      expect(_code(tester), contains('isPage: false'));
    });

    testWidgets('isPage on: the inner header sees only the system edges and goes under the status bar', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const PageEntry());
      await _tapKey(tester, 'toggle isPage');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'inner header').top, _rect(tester, 'outer header').top, 'level with the outer header');
      _near(_rect(tester, 'inner header').top - screen.top, _statusBar * scale, 'right below the status bar');
      _near(
        _rect(tester, 'stage row 0').top,
        _rect(tester, 'inner header').bottom + 12 * scale,
        'rows rest past the inner fade',
      );
      expect(find.text('HarborFrame(isPage: true)'), findsWidgets);
      expect(_code(tester), contains('isPage: true'));
    });
  });

  group('HarborSizing.hug', () {
    testWidgets('hug(): the frame is as tall as its body and bar', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HugBodyEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect frame = _rect(tester, 'sized frame');
      _near(frame.top, _rect(tester, 'sized body').top, 'no top bar: frame top is the body top');
      _near(_rect(tester, 'sized body').height, 180 * scale, 'the body keeps its own height');
      _near(frame.bottom, screen.bottom, 'sits at the bottom');
      _near(frame.height, (180 + 56 + _homeIndicator) * scale, 'body + bar + home indicator');
      expect(_code(tester), contains('sizing: HarborSizing.hug()'));
    });

    testWidgets('hug() follows the body height slider', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HugBodyEntry());
      await _slide(tester, 'body height', 300);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'sized frame').height, (300 + 56 + _homeIndicator) * scale, 'grew with the body');
      _near(_rect(tester, 'sized frame').bottom, screen.bottom, 'still at the bottom');
      expect(find.text('body 300 tall'), findsOneWidget);
      expect(_code(tester), contains('SizedBox(height: 300'));
    });

    testWidgets('fill: the frame takes the whole height whatever the body asks for', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HugBodyEntry());
      await _tapKey(tester, 'sizing: fill');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      _near(_rect(tester, 'sized frame').top, screen.top, 'fill takes the whole height');
      _near(_rect(tester, 'sized frame').bottom, screen.bottom, 'down to the bottom');
      await _slide(tester, 'body height', 300);
      await _showStage(tester);
      _near(_rect(tester, 'sized frame').top, _screen(tester).screen.top, 'the body height does not size it');
      expect(_code(tester), contains('sizing: HarborSizing.fill'));
    });
  });

  group('HarborBar.overlay', () {
    Future<void> pumpOverlay(final WidgetTester tester) => _pumpEntry(tester, const OverlayBarEntry());

    testWidgets('fade: rows rest past the fade, which runs from the bar\'s face', (final WidgetTester tester) async {
      await pumpOverlay(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(
        _rect(tester, 'stage row 0').top - screen.top,
        (_statusBar + 52 + 16) * scale,
        'first row past the 16 fade',
      );
      expect(_fadesOver(tester, 'stage row 0'), <HarborEdge, HarborFadeBand>{
        HarborEdge.top: const HarborFadeBand(barFace: _statusBar + 52, fadeEnd: _statusBar + 52 + 16),
      });
      expect(
        _code(tester),
        contains('edgeEffect: HarborEdgeEffect.fade(length: 16, blurSigma: 0, restsAt: HarborRest.fadeEnd)'),
      );
    });

    testWidgets('fade length: the fade and the resting line move together', (final WidgetTester tester) async {
      await pumpOverlay(tester);
      await _slide(tester, 'length', 40);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(
        _rect(tester, 'stage row 0').top - screen.top,
        (_statusBar + 52 + 40) * scale,
        'first row past the 40 fade',
      );
      expect(
        _fadesOver(tester, 'stage row 0')[HarborEdge.top],
        const HarborFadeBand(barFace: _statusBar + 52, fadeEnd: _statusBar + 52 + 40),
      );
      expect(_code(tester), contains('HarborEdgeEffect.fade(length: 40,'));
    });

    testWidgets('restsAt barFace: rows rest at the bar\'s face, under the fade', (final WidgetTester tester) async {
      await pumpOverlay(tester);
      await _tapKey(tester, 'restsAt: barFace');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'stage row 0').top - screen.top, (_statusBar + 52) * scale, 'first row at the bar\'s face');
      expect(
        _fadesOver(tester, 'stage row 0')[HarborEdge.top],
        const HarborFadeBand(barFace: _statusBar + 52, fadeEnd: _statusBar + 52 + 16),
      );
      expect(_code(tester), contains('restsAt: HarborRest.barFace'));
    });

    testWidgets('blurSigma: the content under the bar is frosted', (final WidgetTester tester) async {
      await pumpOverlay(tester);
      expect(_onStage(find.byType(BackdropFilter)), findsNothing, reason: 'no frosting at 0');
      await _slide(tester, 'blurSigma', 12);
      final Finder frost = _onStage(find.byType(BackdropFilter));
      expect(frost, findsOneWidget);
      expect(tester.widget<BackdropFilter>(frost).filter, ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12));
      expect(_code(tester), contains('blurSigma: 12'));
    });

    testWidgets('edgeEffect none: rows rest at the bar\'s face and nothing fades them', (
      final WidgetTester tester,
    ) async {
      await pumpOverlay(tester);
      await _tapKey(tester, 'edgeEffect: none');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'stage row 0').top - screen.top, (_statusBar + 52) * scale, 'first row at the bar\'s face');
      expect(_fadesOver(tester, 'stage row 0'), isEmpty);
      expect(find.byKey(const ValueKey<String>('slider length')), findsNothing, reason: 'fade options hide');
      expect(find.byKey(const ValueKey<String>('restsAt: fadeEnd')), findsNothing);
      expect(_code(tester), contains('edgeEffect: HarborEdgeEffect.none'));
    });

    testWidgets('edgeEffect hairline: a line on the bar\'s face, rows rest right at it', (
      final WidgetTester tester,
    ) async {
      await pumpOverlay(tester);
      final Finder header = _onStage(find.text('HarborBar.overlay'));
      // The bar draws its planks and title, and nothing after them.
      final Color planks = Palette.plank.withValues(alpha: 0.82);
      expect(
        _barFrameOf(tester, header),
        paints
          ..rect(color: planks)
          ..paragraph(),
      );
      expect(
        _barFrameOf(tester, header),
        isNot(
          paints
            ..rect()
            ..paragraph()
            ..rect(),
        ),
      );
      await _tapKey(tester, 'edgeEffect: hairline');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'stage row 0').top - screen.top, (_statusBar + 52) * scale, 'first row at the bar\'s face');
      expect(_fadesOver(tester, 'stage row 0'), isEmpty);
      final RenderBox frame = _barFrameOf(tester, header);
      expect(
        frame,
        paints
          ..rect(color: planks)
          ..paragraph()
          ..rect(rect: Rect.fromLTWH(0, frame.size.height - 1, frame.size.width, 1), color: Palette.brass),
      );
      expect(_code(tester), contains('edgeEffect: HarborEdgeEffect.hairline()'));
    });

    testWidgets('backdrop: the planks are drawn under the bar, or not at all', (final WidgetTester tester) async {
      await pumpOverlay(tester);
      final Finder planks = _onStage(
        find.byWidgetPredicate((final Widget w) => w is ColoredBox && w.color == Palette.plank.withValues(alpha: 0.82)),
      );
      expect(planks, findsOneWidget);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(tester.getRect(planks).top, screen.top, 'the backdrop runs up under the status bar');
      _near(tester.getRect(planks).height, (_statusBar + 52) * scale, 'over the bar\'s whole ground');
      expect(_code(tester), contains('backdrop: PierPlanks()'));
      await _tapKey(tester, 'toggle backdrop');
      expect(planks, findsNothing);
      expect(_code(tester), isNot(contains('backdrop:')));
    });
  });

  group('HarborBar.solid', () {
    testWidgets('the body starts where the solid bars end', (final WidgetTester tester) async {
      await _pumpEntry(tester, const SolidBarEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect body = _rect(tester, 'harbor body');
      _near(body.top, _rect(tester, 'top bar').bottom, 'below the top bar');
      _near(body.bottom, _rect(tester, 'bottom bar').top, 'above the bottom bar');
      _near(
        screen.bottom - _rect(tester, 'bottom bar').bottom,
        _homeIndicator * scale,
        'the home indicator beats minimum 16',
      );
      expect(find.textContaining('padding  T 0 · B 0'), findsOneWidget);
    });

    testWidgets('top bar off: the body starts at the top and is padded by the status bar', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const SolidBarEntry());
      await _tapKey(tester, 'toggle top bar');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('top bar')), findsNothing);
      _near(_rect(tester, 'harbor body').top, screen.top, 'body top at the screen top');
      expect(find.textContaining('padding  T 62 · B 0'), findsOneWidget);
      expect(_code(tester), isNot(contains('top:')));
    });

    testWidgets('bottom bar off: the body runs to the bottom and its minimum slider goes', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const SolidBarEntry());
      await _tapKey(tester, 'toggle bottom bar');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('bottom bar')), findsNothing);
      expect(find.byKey(const ValueKey<String>('slider minimum')), findsNothing);
      _near(_rect(tester, 'harbor body').bottom, screen.bottom, 'body bottom at the screen bottom');
      expect(find.textContaining('padding  T 0 · B 34'), findsOneWidget);
      expect(_code(tester), isNot(contains('bottom:')));
    });

    testWidgets('minimum: more than the home indicator lifts the bar off the edge', (final WidgetTester tester) async {
      await _pumpEntry(tester, const SolidBarEntry());
      await _slide(tester, 'minimum', 40);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(screen.bottom - _rect(tester, 'bottom bar').bottom, 40 * scale, 'the bar 40 off the edge');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'bottom bar').top, 'the body still ends at the bar');
      expect(find.text('HarborBar.solid(minimum: 40)'), findsOneWidget);
      expect(_code(tester), contains('HarborBar.solid(minimum: 40,'));
    });

    testWidgets('minimum: keeps the bar 16 off the edge of a phone with no home indicator', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const SolidBarEntry());
      await _stageSetting(tester, 'Device: iPhone SE');
      final (:Rect screen, :double scale) = _screen(tester, deviceWidth: 375);
      _near(screen.bottom - _rect(tester, 'bottom bar').bottom, 16 * scale, 'the bar 16 off the edge');
      await _slide(tester, 'minimum', 0);
      await _showStage(tester);
      _near(
        _rect(tester, 'bottom bar').bottom,
        _screen(tester, deviceWidth: 375).screen.bottom,
        'minimum 0: on the edge',
      );
    });
  });

  group('bottom: [composer, tabBar]', () {
    testWidgets('two solid bars add up: the body ends above both', (final WidgetTester tester) async {
      await _pumpEntry(tester, const StackingEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'composer').bottom, _rect(tester, 'tabBar').top, 'composer stacks on the tab bar');
      _near(screen.bottom - _rect(tester, 'tabBar').bottom, _homeIndicator * scale, 'the tab bar is nearest the edge');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'composer').top, 'the body ends above both');
      expect(_code(tester), contains('HarborBar.solid(child: Composer()),\n    HarborBar.solid(child: TabBar())'));
    });

    testWidgets('an overlay composer over a solid tab bar: the body runs under the composer, stops at the tab bar', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const StackingEntry());
      await _tapKey(tester, 'composer: overlay');
      await _showStage(tester);
      _near(_rect(tester, 'composer').bottom, _rect(tester, 'tabBar').top, 'still stacked');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'tabBar').top, 'the body runs under the overlay bar');
      expect(_code(tester), contains('HarborBar.overlay(child: Composer())'));
    });

    testWidgets('two overlay bars: the body runs to the screen bottom under both', (final WidgetTester tester) async {
      await _pumpEntry(tester, const StackingEntry());
      await _tapKey(tester, 'composer: overlay');
      await _tapKey(tester, 'tabBar: overlay');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('assert card')), findsNothing);
      _near(_rect(tester, 'composer').bottom, _rect(tester, 'tabBar').top, 'still stacked');
      _near(_rect(tester, 'harbor body').bottom, screen.bottom, 'the body runs under both');
    });

    testWidgets('a solid bar listed inside an overlay bar asserts, and the stage says so', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const StackingEntry());
      await _tapKey(tester, 'tabBar: overlay');
      await _showStage(tester);
      expect(find.byKey(const ValueKey<String>('assert card')), findsOneWidget);
      // It sits in the bottom 480 the page focuses on, not off the top of that view.
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect card = _rect(tester, 'assert card');
      expect(card.top, greaterThanOrEqualTo(screen.bottom - 480 * scale));
      expect(card.bottom, lessThanOrEqualTo(screen.bottom));
      expect(find.byKey(const ValueKey<String>('composer')), findsNothing);
      expect(_code(tester), endsWith('// Asserts: a solid bar listed inside an overlay bar.'));
      await _tapKey(tester, 'tabBar: solid');
      expect(find.byKey(const ValueKey<String>('assert card')), findsNothing);
      expect(find.byKey(const ValueKey<String>('composer')), findsOneWidget);
    });

    testWidgets('second bar off: the composer alone sits on the edge', (final WidgetTester tester) async {
      await _pumpEntry(tester, const StackingEntry());
      await _tapKey(tester, 'toggle second bar (tabBar)');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      expect(find.byKey(const ValueKey<String>('tabBar')), findsNothing);
      expect(find.byKey(const ValueKey<String>('tabBar: solid')), findsNothing, reason: 'its options go with it');
      _near(screen.bottom - _rect(tester, 'composer').bottom, _homeIndicator * scale, 'the composer takes the edge');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'composer').top, 'the body ends above it');
      expect(_code(tester), isNot(contains('TabBar()')));
      await _tapKey(tester, 'composer: overlay');
      await _showStage(tester);
      _near(
        _rect(tester, 'harbor body').bottom,
        _screen(tester).screen.bottom,
        'a lone overlay bar: the body runs under it',
      );
    });
  });

  group('HarborBarState', () {
    Future<void> pumpState(final WidgetTester tester) => _pumpEntry(tester, const BarStateEntry());
    String hint(final WidgetTester tester) => tester.widget<Text>(find.byKey(const ValueKey<String>('hint'))).data!;

    testWidgets('open: drawn, tappable, and its ground taken', (final WidgetTester tester) async {
      await pumpState(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'harbor body').top, _rect(tester, 'state header').bottom, 'the body starts below it');
      _near(_rect(tester, 'state header').bottom - screen.top, (_statusBar + 52) * scale, 'below the status bar');
      await tester.tap(find.byKey(const ValueKey<String>('header button')));
      await _settle(tester, steps: 1);
      expect(find.text('taps: 1'), findsOneWidget, reason: 'the header takes taps');
      expect(find.byKey(const ValueKey<String>('held ground')), findsNothing);
      expect(hint(tester), startsWith('open:'));
      expect(_code(tester), contains('state: HarborBarState.open'));
    });

    testWidgets('dark: not drawn or tappable, but it keeps its ground', (final WidgetTester tester) async {
      await pumpState(tester);
      final double open = _rect(tester, 'harbor body').top;
      await _tapKey(tester, 'state: dark');
      await _showStage(tester);
      _near(_rect(tester, 'harbor body').top, open, 'nothing moves');
      final Finder held = find.byKey(const ValueKey<String>('held ground'));
      expect(held, findsOneWidget, reason: 'the ground it holds is outlined');
      _near(tester.getRect(held).bottom, open, 'right where the body starts');
      final Finder lamp = find
          .ancestor(of: find.byKey(const ValueKey<String>('state header')), matching: find.byType(Opacity))
          .first;
      expect(tester.widget<Opacity>(lamp).opacity, 0, reason: 'not drawn');
      await tester.tapAt(tester.getRect(find.byKey(const ValueKey<String>('header button'))).center);
      await _settle(tester, steps: 1);
      expect(find.text('taps: 0'), findsOneWidget, reason: 'its button takes no taps');
      expect(hint(tester), contains('the dashed box is the ground it still holds'));
      expect(_code(tester), contains('state: HarborBarState.dark'));
    });

    testWidgets('withdrawn: it slides out and gives its ground back', (final WidgetTester tester) async {
      await pumpState(tester);
      await _tapKey(tester, 'state: withdrawn');
      await _showStage(tester);
      final (:Rect screen, scale: _) = _screen(tester);
      _near(_rect(tester, 'harbor body').top, screen.top, 'the body takes the ground');
      expect(
        _rect(tester, 'state header').bottom,
        lessThanOrEqualTo(screen.top + 0.75),
        reason: 'slid out past the top',
      );
      expect(_code(tester), contains('state: HarborBarState.withdrawn'));
      await _tapKey(tester, 'state: open');
      await _showStage(tester);
      _near(_rect(tester, 'harbor body').top, _rect(tester, 'state header').bottom, 'back open');
    });

    testWidgets('extentPolicy.hold: the body waits until the header has gone', (final WidgetTester tester) async {
      await pumpState(tester);
      final double open = _rect(tester, 'harbor body').top;
      await _tapNow(tester, 'state: withdrawn');
      await tester.pump(const Duration(milliseconds: 600));
      _near(_rect(tester, 'harbor body').top, open, 'mid-slide: the body has not moved');
      expect(_rect(tester, 'state header').bottom, lessThan(open - 10), reason: 'the header is sliding away');
      await _settle(tester);
      _near(_rect(tester, 'harbor body').top, _screen(tester).screen.top, 'gone: the body takes the ground');
      expect(hint(tester), startsWith('withdrawn + hold:'));
      expect(_code(tester), contains('extentPolicy: HarborExtentPolicy.hold'));
    });

    testWidgets('extentPolicy.follow: the body rises with the header as it slides', (final WidgetTester tester) async {
      await pumpState(tester);
      final double open = _rect(tester, 'harbor body').top;
      await _tapKey(tester, 'extentPolicy: follow');
      await _tapNow(tester, 'state: withdrawn');
      await tester.pump(const Duration(milliseconds: 600));
      final double top = _rect(tester, 'harbor body').top;
      expect(top, lessThan(open - 10), reason: 'mid-slide: the body has risen');
      expect(top, greaterThan(_screen(tester).screen.top + 10), reason: 'but not all the way yet');
      _near(top, _rect(tester, 'state header').bottom, 'right behind the header');
      await _settle(tester);
      _near(_rect(tester, 'harbor body').top, _screen(tester).screen.top, 'gone: the body has the ground');
      expect(hint(tester), startsWith('withdrawn + follow:'));
      expect(_code(tester), contains('extentPolicy: HarborExtentPolicy.follow'));
      expect(find.text('Withdraw and return (follow)'), findsOneWidget);
    });

    testWidgets('extentPolicy.release: the body takes the ground at once, the header slides over the rows', (
      final WidgetTester tester,
    ) async {
      await pumpState(tester);
      await _tapKey(tester, 'extentPolicy: release');
      await _tapNow(tester, 'state: withdrawn');
      await tester.pump(const Duration(milliseconds: 600));
      final Rect screen = _screen(tester).screen;
      _near(_rect(tester, 'harbor body').top, screen.top, 'mid-slide: the body already has the ground');
      expect(
        _rect(tester, 'state header').bottom,
        greaterThan(screen.top + 20),
        reason: 'the header is still on its way out',
      );
      expect(hint(tester), startsWith('withdrawn + release:'));
      expect(_code(tester), contains('extentPolicy: HarborExtentPolicy.release'));
    });

    testWidgets('duration: sets how long the header takes to withdraw', (final WidgetTester tester) async {
      await pumpState(tester);
      final double open = _rect(tester, 'harbor body').top;
      await _slide(tester, 'duration', 2000);
      expect(_code(tester), contains('Duration(milliseconds: 2000)'));
      await _tapNow(tester, 'state: withdrawn');
      await tester.pump(const Duration(milliseconds: 1500));
      _near(_rect(tester, 'harbor body').top, open, '2000: still holding at 1500');
      await tester.pump(const Duration(milliseconds: 800));
      _near(_rect(tester, 'harbor body').top, _screen(tester).screen.top, '2000: gone by 2300');

      await _tapKey(tester, 'state: open');
      await _slide(tester, 'duration', 100);
      await _tapNow(tester, 'state: withdrawn');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      _near(_rect(tester, 'harbor body').top, _screen(tester).screen.top, '100: gone by 200');
    });

    testWidgets('withdraw and return plays the header out and back', (final WidgetTester tester) async {
      await pumpState(tester);
      final double open = _rect(tester, 'harbor body').top;
      final Finder play = find.byKey(const ValueKey<String>('play withdraw'));
      await tester.ensureVisible(play);
      await _settle(tester, steps: 1);
      await tester.tap(play);
      await _showStage(tester);
      await _settle(tester, steps: 3);
      expect(_rect(tester, 'harbor body').top, lessThan(open - 20), reason: 'withdrawn: the body rose');
      expect(tester.widget<OutlinedButton>(play).onPressed, isNull, reason: 'the button waits while it plays');
      await _settle(tester, steps: 6);
      _near(_rect(tester, 'harbor body').top, open, 'back open');
      expect(tester.widget<OutlinedButton>(play).onPressed, isNotNull);
    });
  });

  group('HarborBar.restingExtent + HarborFollow', () {
    testWidgets('at rest the rail is restingExtent wide and both panels start past it', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const RestingExtentEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'rail').right - screen.left, 72 * scale, 'rail at 72');
      _near(_rect(tester, 'panel live').left, _rect(tester, 'rail').right, 'live past the rail');
      _near(_rect(tester, 'panel second').left, _rect(tester, 'rail').right, 'second past the rail');
      expect(_code(tester), contains('restingExtent: 72'));
    });

    testWidgets('restingExtent: the rail and both panels move to the new width', (final WidgetTester tester) async {
      await _pumpEntry(tester, const RestingExtentEntry());
      await _slide(tester, 'restingExtent', 100);
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'rail').right - screen.left, 100 * scale, 'rail at 100');
      _near(_rect(tester, 'panel live').left - screen.left, 100 * scale, 'live at 100');
      _near(_rect(tester, 'panel second').left - screen.left, 100 * scale, 'second at 100');
      expect(_code(tester), contains('restingExtent: 100'));
    });

    testWidgets('follow resting: opening the rail moves live content, resting content holds', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const RestingExtentEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      await tester.tapAt(_rect(tester, 'rail').center);
      await _settle(tester);
      _near(_rect(tester, 'rail').right - screen.left, 210 * scale, 'the rail opened');
      _near(_rect(tester, 'panel live').left, _rect(tester, 'rail').right, 'live follows the open rail');
      _near(_rect(tester, 'panel second').left - screen.left, 72 * scale, 'resting holds at the resting extent');
      expect(
        find.byWidgetPredicate(
          (final Widget w) => w is SwitchListTile && w.key == const ValueKey<String>('toggle rail open') && w.value,
        ),
        findsOneWidget,
      );
      expect(_code(tester), contains('Rail(open: true)'));
    });

    testWidgets('rail open switch opens and closes the rail', (final WidgetTester tester) async {
      await _pumpEntry(tester, const RestingExtentEntry());
      await _tapKey(tester, 'toggle rail open');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'rail').right - screen.left, 210 * scale, 'open');
      _near(_rect(tester, 'panel live').left - screen.left, 210 * scale, 'live follows');
      await _tapKey(tester, 'toggle rail open');
      await _showStage(tester);
      _near(_rect(tester, 'rail').right - screen.left, 72 * scale, 'closed again');
      _near(_rect(tester, 'panel live').left - screen.left, 72 * scale, 'live comes back');
    });

    testWidgets('follow live: the second panel moves with the open rail too', (final WidgetTester tester) async {
      await _pumpEntry(tester, const RestingExtentEntry());
      await _tapKey(tester, 'follow: live');
      await _tapKey(tester, 'toggle rail open');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      _near(_rect(tester, 'panel second').left - screen.left, 210 * scale, 'second follows the open rail');
      _near(_rect(tester, 'panel second').left, _rect(tester, 'panel live').left, 'level with live');
      expect(find.text('HarborClear(\n  follow: HarborFollow.live,\n)'), findsNWidgets(2));
      expect(_code(tester), contains('HarborClear(follow: HarborFollow.live, child: page)'));
    });
  });

  group('HarborBar.hitTestBehavior', () {
    /// Taps the header's empty part, beside its title, and returns the row
    /// under that point.
    Future<int> tapBesideTitle(final WidgetTester tester) async {
      final Rect header = _rect(tester, 'gate header');
      final Offset at = Offset(header.left + 4, header.center.dy);
      final int row = List<int>.generate(30, (final int i) => i).firstWhere((final int i) {
        final Finder f = find.byKey(ValueKey<String>('stage row $i'));
        if (f.evaluate().isEmpty) {
          return false;
        }
        final Rect r = tester.getRect(f);
        return r.top <= at.dy && at.dy < r.bottom;
      });
      await tester.tapAt(at);
      await _settle(tester, steps: 1);
      return row;
    }

    Future<void> tapTitle(final WidgetTester tester) async {
      await tester.tapAt(tester.getCenter(_onStage(find.textContaining('hitTestBehavior: '))));
      await _settle(tester, steps: 1);
    }

    testWidgets('opaque: a tap on the header never reaches the row under it', (final WidgetTester tester) async {
      await _pumpEntry(tester, const HitTestEntry());
      await tapBesideTitle(tester);
      expect(find.text('row taps: 0'), findsOneWidget);
      await tester.tapAt(_rect(tester, 'gate header').bottomCenter + const Offset(0, 60));
      await _settle(tester, steps: 1);
      expect(find.textContaining('row taps: 1'), findsOneWidget, reason: 'rows clear of the header take taps');
      expect(_code(tester), contains('hitTestBehavior: HitTestBehavior.opaque'));
    });

    testWidgets('translucent: taps beside the title reach the row beneath; the title keeps its own', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HitTestEntry());
      await _tapKey(tester, 'hitTestBehavior: translucent');
      await _showStage(tester);
      final int row = await tapBesideTitle(tester);
      expect(find.text('row taps: 1 (last: row ${row + 1})'), findsOneWidget);
      expect(find.text('1 tap'), findsOneWidget, reason: 'the row marks the tap');
      await tapTitle(tester);
      expect(find.textContaining('row taps: 1'), findsOneWidget, reason: 'the title takes its own tap');
      expect(_code(tester), contains('hitTestBehavior: HitTestBehavior.translucent'));
    });

    testWidgets('deferToChild: only the header\'s child stops taps; its empty parts let them through', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const HitTestEntry());
      await _tapKey(tester, 'hitTestBehavior: deferToChild');
      await _showStage(tester);
      final int row = await tapBesideTitle(tester);
      expect(find.text('row taps: 1 (last: row ${row + 1})'), findsOneWidget);
      await tapTitle(tester);
      expect(find.textContaining('row taps: 1'), findsOneWidget, reason: 'the title takes its own tap');
      expect(find.text('hitTestBehavior: deferToChild'), findsOneWidget);
    });
  });

  group('HarborBar.reserve', () {
    /// How far the body's probe reads padding at the bottom.
    double paddingBottom(final WidgetTester tester) {
      final String reading = tester.widget<ProbeReadout>(find.byType(ProbeReadout)).settings.probes['frame body']!;
      return double.parse(RegExp(r'padding  T \d+ · B (\d+)').firstMatch(reading)!.group(1)!);
    }

    testWidgets('an overlay reserve holds 80: the body runs under the footer and rests clear of it', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const ReserveEntry());
      final (:Rect screen, :double scale) = _screen(tester);
      expect(paddingBottom(tester), 80, reason: 'the body is told how far the reserve reaches');
      _near(_rect(tester, 'harbor body').bottom, screen.bottom, 'an overlay bar: the body runs to the edge');
      final Rect footer = _rect(tester, 'reserve footer');
      _near(footer.height, 80 * scale, 'the footer drawn elsewhere fills the 80 held for it');
      _near(footer.bottom, screen.bottom, 'from the edge, over the home indicator');
      expect(_code(tester), contains('HarborBar.reserve(extent: 80),'));
    });

    testWidgets('a short reserve reaches the system edge; with none, just its extent', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const ReserveEntry());
      await _slide(tester, 'extent', 20);
      expect(paddingBottom(tester), _homeIndicator, reason: 'the larger of the system edge and the extent');
      final (:Rect screen, :double scale) = _screen(tester);
      _near(
        _rect(tester, 'reserve footer').height,
        _homeIndicator * scale,
        'the footer stops at the system edge, not at 20',
      );

      await _stageSetting(tester, 'Device: iPhone SE');
      expect(paddingBottom(tester), 20, reason: 'no home indicator: the extent alone');
      final ({Rect screen, double scale}) se = _screen(tester, deviceWidth: 375);
      _near(_rect(tester, 'reserve footer').height, 20 * se.scale, 'the footer is the extent high');
      expect(_code(tester), contains('HarborBar.reserve(extent: 20),'));
    });

    testWidgets('a solid reserve stops the body at it', (final WidgetTester tester) async {
      await _pumpEntry(tester, const ReserveEntry());
      await _tapKey(tester, 'kind: solid');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      expect(paddingBottom(tester), 0, reason: 'a solid bar takes its ground: nothing left to clear');
      _near(_rect(tester, 'harbor body').bottom, screen.bottom - 80 * scale, 'the body ends where the reserve starts');
      _near(_rect(tester, 'harbor body').bottom, _rect(tester, 'reserve footer').top, 'at the footer drawn elsewhere');
      expect(_code(tester), contains('HarborBar.reserve(extent: 80, kind: HarborBarKind.solid),'));
    });

    testWidgets('past a tab bar outside it, a reserve reaches its extent beyond the tab bar', (
      final WidgetTester tester,
    ) async {
      await _pumpEntry(tester, const ReserveEntry());
      await _tapKey(tester, 'toggle tab bar outside');
      await _showStage(tester);
      final (:Rect screen, :double scale) = _screen(tester);
      final Rect tabBar = _rect(tester, 'reserve tab bar');
      _near(screen.bottom - tabBar.bottom, _homeIndicator * scale, 'the tab bar absorbs the system edge');
      _near(_rect(tester, 'harbor body').bottom, tabBar.top, 'the body stops at the tab bar, a solid bar');
      expect(paddingBottom(tester), 80, reason: 'the reserve is an overlay bar 80 past the tab bar');
      final Rect footer = _rect(tester, 'reserve footer');
      _near(footer.bottom, tabBar.top, 'the footer sits on the tab bar');
      _near(footer.height, 80 * scale, 'and keeps all 80: the system edge is the tab bar\'s');
      expect(_code(tester), contains('        HarborBar.solid(child: TabBar()),\n'));
    });
  });

  testWidgets('the stage settings start folded under the class options, and open on a tap', (
    final WidgetTester tester,
  ) async {
    await _pumpEntry(tester, const HarborEntry());
    final Finder fold = find.byKey(const ValueKey<String>('stage settings'));
    final Finder device = find.byKey(const ValueKey<String>('Device: iPhone SE'));
    expect(fold, findsOneWidget);
    expect(device, findsNothing);
    expect(find.text('iPhone 17'), findsOneWidget, reason: 'the folded row says what the stage is set to');
    // The class's own options come first, right under the phone.
    final Finder classOptions = find.byWidgetPredicate((final Widget w) => w is SwitchListTile || w is ChoiceChip);
    expect(tester.getRect(classOptions.first).top, lessThan(tester.getRect(fold).top));

    await tester.ensureVisible(fold);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(fold);
    await _settle(tester, steps: 1);
    expect(device, findsOneWidget);
    await tester.ensureVisible(device);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(device);
    await _settle(tester, steps: 1);
    await tester.ensureVisible(fold);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(fold);
    await _settle(tester, steps: 1);
    expect(device, findsNothing);
    expect(find.text('iPhone SE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('smoke only: no control on any frame or bar page throws when tapped', (final WidgetTester tester) async {
    for (final Widget entry in const <Widget>[
      HarborEntry(),
      HarborRootEntry(),
      PageEntry(),
      HugBodyEntry(),
      OverlayBarEntry(),
      SolidBarEntry(),
      StackingEntry(),
      BarStateEntry(),
      RestingExtentEntry(),
      HitTestEntry(),
    ]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpEntry(tester, entry);
      await _tapEveryControl(tester);
    }
  });

  testWidgets('unfolding the plate leaves the stage half the page, at any size', (final WidgetTester tester) async {
    // HarborAttachedBar's plate has the longest text.
    for (final Size size in <Size>[const Size(402, 874), const Size(414, 896), const Size(375, 667)]) {
      await _pumpEntry(tester, const PontoonEntry());
      tester.view
        ..physicalSize = size
        ..padding = const FakeViewPadding(top: 44, bottom: 34)
        ..viewPadding = const FakeViewPadding(top: 44, bottom: 34);
      await _settle(tester);
      final Finder plate = find.byKey(const ValueKey<String>('plate'));
      final Finder stage = find.byKey(const ValueKey<String>('stage'));
      final double stageBefore = tester.getRect(stage).height;
      await tester.tap(plate);
      await _settle(tester, steps: 2);
      expect(tester.takeException(), isNull, reason: '$size');
      expect(find.textContaining('As drawn', findRichText: true), findsOneWidget, reason: 'unfolded at $size');
      final Rect quay = tester.getRect(find.byKey(const ValueKey<String>('control quay handle')));
      final double body = quay.top - tester.getRect(plate).top;
      expect(
        tester.getRect(plate).height,
        lessThanOrEqualTo(body / 2 + 1),
        reason: 'the plate takes at most half ($size)',
      );
      expect(tester.getRect(stage).height, greaterThan(stageBefore / 3), reason: 'the stage keeps its share ($size)');
      await tester.tap(plate);
      await _settle(tester, steps: 2);
      _near(tester.getRect(stage).height, stageBefore, 'folded again ($size)');
    }
  });
}
