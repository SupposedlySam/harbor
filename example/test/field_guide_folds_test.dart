// The folds and hinges pages: HarborHinge, HarborPanes and HarborPosture, measured on the stage's
// dual-screen and foldable devices, open flat, half open like a book and half open on a table.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entries_folds.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/guide_page.dart';
import 'package:harbor_example/field_guide/stage.dart';

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
  await _step(tester);
}

/// Steps time: the seas never settle.
Future<void> _step(final WidgetTester tester, [final int times = 3]) async {
  for (int i = 0; i < times; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Finder _key(final String key) => find.byKey(ValueKey<String>(key));

/// Taps a control, opening the stage's own settings first when it is one of theirs.
Future<void> _tap(final WidgetTester tester, final String key) async {
  final Finder finder = _key(key);
  final Finder fold = _key('stage settings');
  if (finder.evaluate().isEmpty && fold.evaluate().isNotEmpty) {
    await tester.ensureVisible(fold);
    await _step(tester, 1);
    await tester.tap(fold);
    await _step(tester);
  }
  await tester.ensureVisible(finder);
  await _step(tester, 1);
  await tester.tap(finder);
  await _step(tester);
}

/// Sets a slider control to [value], as dragging its thumb there would.
Future<void> _slide(final WidgetTester tester, final String label, final double value) async {
  final Finder finder = _key('slider $label');
  await tester.ensureVisible(finder);
  await _step(tester, 1);
  tester.widget<Slider>(finder).onChanged!(value);
  await _step(tester);
}

StageSettings _settings(final WidgetTester tester) => tester.widget<ProbeReadout>(find.byType(ProbeReadout)).settings;

/// Where [finder] is on the stage, in the held device's own points.
Rect _onDevice(final WidgetTester tester, final Finder finder) {
  final Rect screen = tester.getRect(_key('stage')).deflate(10);
  final double scale = screen.width / _settings(tester).held.size.width;
  final Rect r = tester.getRect(finder);
  return Rect.fromLTRB(
    (r.left - screen.left) / scale,
    (r.top - screen.top) / scale,
    (r.right - screen.left) / scale,
    (r.bottom - screen.top) / scale,
  );
}

String _code(final WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _key('code card'), matching: find.byType(Text))).data!;

String? _reading(final WidgetTester tester, final String label) => _settings(tester).probes[label];

/// The device is drawn small on a phone-sized test view, so a point on it is a fraction of a pixel.
void _near(final double actual, final double expected, final String what) =>
    expect(actual, moreOrLessEquals(expected, epsilon: 1.5), reason: what);

void main() {
  test('the folds group lists hinge, panes and posture', () {
    expect(foldEntries.map((final GuideEntry e) => e.className), <String>[
      'HarborHinge',
      'HarborPanes',
      'HarborPosture',
    ]);
    expect(foldEntries.every((final GuideEntry e) => e.group == GuideGroup.folds), isTrue);
  });

  group('the stage', () {
    test('dual screen open is two 540 screens and a 34 hinge, as the sea trial is', () {
      const StageDevice dual = StageDevice.dualScreenOpen;
      expect(StageDevice.phones, contains(dual));
      expect(dual.size, const Size(1114, 720));
      expect(dual.displayFeatures.single.bounds, const Rect.fromLTRB(540, 0, 574, 720));
    });

    test('held in a posture, a fold half opens, and on a table the device turns on its side', () {
      final StageDevice book = StageDevice.foldableOpen.held(HarborPosture.book);
      expect(book.size, const Size(750, 832));
      expect(HarborPosture.from(book.displayFeatures), HarborPosture.book);
      final StageDevice table = StageDevice.foldableOpen.held(HarborPosture.tabletop);
      expect(table.size, const Size(832, 750));
      expect(table.displayFeatures.single.bounds, const Rect.fromLTRB(0, 375, 832, 375));
      expect(HarborPosture.from(table.displayFeatures), HarborPosture.tabletop);
      expect(StageDevice.iPhone17.held(HarborPosture.book), same(StageDevice.iPhone17), reason: 'no fold to hold');
    });

    testWidgets('draws the hinge as a hinge and the fold as a crease, and offers a posture only for them', (
      final tester,
    ) async {
      await _pumpEntry(tester, const HingeEntry());
      _near(_onDevice(tester, _key('stage hinge')).left, 540, 'the hinge starts where the left screen ends');
      _near(_onDevice(tester, _key('stage hinge')).width, 34, 'and is 34 wide');
      expect(_key('Posture: book'), findsNothing, reason: 'the stage settings start folded');
      await _tap(tester, 'Device: foldable open');
      expect(_key('stage hinge'), findsNothing);
      _near(_onDevice(tester, _key('stage fold')).center.dx, 375, 'the crease down the middle');
      expect(_key('Posture: book'), findsOneWidget);
      await _tap(tester, 'Device: iPhone 17');
      expect(_key('Posture: book'), findsNothing, reason: 'a phone has no fold to hold');
      expect(_key('stage fold'), findsNothing);
    });
  });

  group('HarborHinge', () {
    testWidgets('avoidSeparating on a dual screen: the bars and the float keep to the left screen', (
      final tester,
    ) async {
      await _pumpEntry(tester, const HingeEntry());
      expect(_settings(tester).held.name, 'dual screen open', reason: 'the page opens on the device it is about');
      _near(_onDevice(tester, _key('hinge header')).right, 540, 'the header stops at the hinge');
      _near(_onDevice(tester, _key('hinge tab bar')).right, 540, 'so does the tab bar');
      final Rect float = _onDevice(tester, _key('hinge buoy'));
      _near(float.center.dx, 270, 'the float is centred on the left screen');
      expect(_reading(tester, 'The page’s hinge'), contains('kept off          hinge x 540–574 flat'));
      expect(_code(tester), contains('  defaults: HarborDefaults(hinge: HarborHinge.avoidSeparating),\n'));
    });

    testWidgets('never: the bars and the float run across the hinge', (final tester) async {
      await _pumpEntry(tester, const HingeEntry());
      await _tap(tester, 'policy: never');
      _near(_onDevice(tester, _key('hinge header')).right, 1114, 'the header runs to the far edge');
      _near(_onDevice(tester, _key('hinge tab bar')).right, 1114, 'so does the tab bar');
      _near(_onDevice(tester, _key('hinge buoy')).center.dx, 557, 'the float sits on the hinge');
      expect(_reading(tester, 'The page’s hinge'), contains('kept off          none'));
    });

    testWidgets('a flat fold: avoidSeparating crosses it, always stops at it', (final tester) async {
      await _pumpEntry(tester, const HingeEntry());
      await _tap(tester, 'Device: foldable open');
      _near(_onDevice(tester, _key('hinge header')).right, 750, 'a flat fold has no width: nothing separates');
      _near(_onDevice(tester, _key('hinge buoy')).center.dx, 375, 'the float spans the crease');
      await _tap(tester, 'policy: always');
      _near(_onDevice(tester, _key('hinge header')).right, 375, 'always keeps off even a flat fold');
      final Rect float = _onDevice(tester, _key('hinge buoy'));
      expect(
        float.left >= 375 - 1.5 || float.right <= 375 + 1.5,
        isTrue,
        reason: 'the float keeps to one side: $float',
      );
    });

    testWidgets('a fold half open like a book: avoidSeparating keeps off it, avoidOccluding does not', (
      final tester,
    ) async {
      await _pumpEntry(tester, const HingeEntry());
      await _tap(tester, 'Device: foldable open');
      await _tap(tester, 'Posture: book');
      expect(_reading(tester, 'The page’s hinge'), contains('HarborPosture.of  book'));
      _near(_onDevice(tester, _key('hinge header')).right, 375, 'a half-open fold separates');
      await _tap(tester, 'policy: avoidOccluding');
      _near(
        _onDevice(tester, _key('hinge header')).right,
        750,
        'a fold hides nothing: only a hinge with width occludes',
      );
    });

    testWidgets('barHinge sets the bars alone; a float\'s own hinge sets the float alone', (final tester) async {
      await _pumpEntry(tester, const HingeEntry());
      await _tap(tester, 'policy: never');
      await _tap(tester, 'set on: HarborDefaults(barHinge:)');
      _near(_onDevice(tester, _key('hinge header')).right, 1114, 'the bars cross the hinge');
      _near(_onDevice(tester, _key('hinge buoy')).center.dx, 270, 'the float keeps the root\'s avoidSeparating');
      expect(_code(tester), contains('  defaults: HarborDefaults(barHinge: HarborHinge.never),\n'));

      await _tap(tester, 'set on: HarborFloat(hinge:)');
      _near(_onDevice(tester, _key('hinge header')).right, 540, 'the bars are back on the left screen');
      _near(_onDevice(tester, _key('hinge buoy')).center.dx, 557, 'the float alone crosses');
      expect(_code(tester), contains('      hinge: HarborHinge.never,\n'));
    });

    testWidgets('right to left, the bars keep to the right screen, where reading starts', (final tester) async {
      await _pumpEntry(tester, const HingeEntry());
      await _tap(tester, 'toggle Right-to-left');
      _near(_onDevice(tester, _key('hinge header')).left, 574, 'the header starts past the hinge');
      _near(_onDevice(tester, _key('hinge header')).right, 1114, 'and runs to the right edge');
    });
  });

  group('HarborPanes', () {
    testWidgets('on a dual screen the panes go either side of the hinge', (final tester) async {
      await _pumpEntry(tester, const PanesEntry());
      final Rect start = _onDevice(tester, _key('start pane'));
      final Rect end = _onDevice(tester, _key('end pane'));
      _near(start.left, 0, 'start on the left screen');
      _near(start.right, 540, 'up to the hinge');
      _near(end.left, 574, 'end past the hinge');
      _near(end.right, 1114, 'to the far edge');
      _near(_onDevice(tester, _key('start header')).top, 24, 'each pane is a frame whose header clears the status bar');
      expect(_reading(tester, 'HarborPanes.modeOf'), 'wide');
    });

    testWidgets('on a phone, priority\'s pane alone', (final tester) async {
      await _pumpEntry(tester, const PanesEntry());
      await _tap(tester, 'Device: iPhone 17');
      _near(_onDevice(tester, _key('start pane')).width, 402, 'the list fills the phone');
      expect(_key('end pane'), findsNothing);
      expect(_reading(tester, 'HarborPanes.modeOf'), 'single');
      await _tap(tester, 'priority: end');
      expect(_key('start pane'), findsNothing);
      _near(_onDevice(tester, _key('end pane')).width, 402, 'the message fills it instead');
      expect(
        find.textContaining('opens this as a page of its own'),
        findsOneWidget,
        reason: 'modeOf tells it the list is not up',
      );
      expect(_code(tester), contains('  priority: HarborPanePriority.end,\n'));
    });

    testWidgets('a flat fold splits nothing: past minWideWidth startFraction decides; a book\'s fold decides', (
      final tester,
    ) async {
      await _pumpEntry(tester, const PanesEntry());
      await _tap(tester, 'Device: foldable open');
      expect(_reading(tester, 'HarborPanes.modeOf'), 'single', reason: '750 is under 840');
      await _slide(tester, 'minWideWidth', 700);
      await _slide(tester, 'startFraction %', 30);
      expect(_reading(tester, 'HarborPanes.modeOf'), 'wide');
      _near(_onDevice(tester, _key('start pane')).right, 225, '30% of 750');
      _near(_onDevice(tester, _key('end pane')).left, 225, 'the end pane takes the rest');
      expect(_code(tester), contains('  minWideWidth: 700,\n  startFraction: 0.30,\n'));

      await _tap(tester, 'Posture: book');
      _near(_onDevice(tester, _key('start pane')).right, 375, 'the half-open fold, not startFraction');
      _near(_onDevice(tester, _key('end pane')).left, 375, 'either side of it');
    });

    testWidgets('on a table, start above the fold and end below', (final tester) async {
      await _pumpEntry(tester, const PanesEntry());
      await _tap(tester, 'Device: foldable open');
      await _tap(tester, 'Posture: tabletop');
      expect(_settings(tester).held.size, const Size(832, 750), reason: 'turned on its side');
      _near(_onDevice(tester, _key('start pane')).bottom, 375, 'above the fold');
      _near(_onDevice(tester, _key('end pane')).top, 375, 'below it');
      _near(_onDevice(tester, _key('end pane')).width, 832, 'the full width');
      expect(_reading(tester, 'HarborPanes.modeOf'), 'tall');
    });

    testWidgets('hinge: never splits by the width alone, even on a dual screen', (final tester) async {
      await _pumpEntry(tester, const PanesEntry());
      await _tap(tester, 'hinge: never');
      _near(_onDevice(tester, _key('start pane')).right, 557, 'half of 1114, across the hinge');
      expect(_code(tester), contains('  hinge: HarborHinge.never,\n'));
    });
  });

  group('HarborPosture', () {
    testWidgets('flat, one page; on a table, the video above the fold and the controls below', (final tester) async {
      await _pumpEntry(tester, const PostureEntry());
      expect(_settings(tester).held.name, 'foldable open');
      expect(find.text('HarborPosture.flat'), findsOneWidget);
      expect(_key('posture panes'), findsNothing);

      await _tap(tester, 'posture: tabletop');
      expect(find.text('HarborPosture.tabletop'), findsOneWidget);
      expect(_onDevice(tester, _key('posture video')).bottom, lessThanOrEqualTo(375 + 1.5), reason: 'above the fold');
      expect(_onDevice(tester, _key('posture controls')).top, greaterThanOrEqualTo(375 - 1.5), reason: 'below it');
      expect(_reading(tester, 'The page’s hinge'), contains('HarborPosture.of  tabletop'));
    });

    testWidgets('a page that does not read the posture lays its video over the fold', (final tester) async {
      await _pumpEntry(tester, const PostureEntry());
      await _tap(tester, 'posture: tabletop');
      await _tap(tester, 'toggle follows posture');
      final Rect video = _onDevice(tester, _key('posture video'));
      expect(video.top < 375 && video.bottom > 375, isTrue, reason: 'the video bends over the crease: $video');
      expect(_code(tester), contains('return OnePage();'));
    });

    testWidgets('held like a book, the video and the controls are its two pages', (final tester) async {
      await _pumpEntry(tester, const PostureEntry());
      await _tap(tester, 'posture: book');
      expect(find.text('HarborPosture.book'), findsOneWidget);
      expect(_onDevice(tester, _key('posture video')).right, lessThanOrEqualTo(375 + 1.5));
      expect(_onDevice(tester, _key('posture controls')).left, greaterThanOrEqualTo(375 - 1.5));
    });

    testWidgets('a dual screen\'s hinge half open on a table is a posture too', (final tester) async {
      await _pumpEntry(tester, const PostureEntry());
      await _tap(tester, 'Device: dual screen open');
      await _tap(tester, 'posture: tabletop');
      expect(_settings(tester).held.size, const Size(720, 1114));
      expect(_onDevice(tester, _key('posture video')).bottom, lessThanOrEqualTo(540 + 1.5), reason: 'the upper screen');
      expect(_onDevice(tester, _key('posture controls')).top, greaterThanOrEqualTo(574 - 1.5), reason: 'the lower one');
    });

    testWidgets('a phone has no posture to take', (final tester) async {
      await _pumpEntry(tester, const PostureEntry());
      await _tap(tester, 'Device: iPhone 17');
      await _tap(tester, 'posture: book');
      expect(_settings(tester).posture, HarborPosture.flat);
      expect(find.text('HarborPosture.flat'), findsOneWidget);
    });
  });

  testWidgets('no control on any folds page throws', (final tester) async {
    for (final GuideEntry entry in foldEntries) {
      await _pumpEntry(tester, Builder(key: ValueKey<String>(entry.id), builder: entry.page));
      final List<String> controls = <String>[
        for (final Widget w in tester.widgetList(
          find.byWidgetPredicate((final Widget w) => w is ChoiceChip || w is SwitchListTile),
        ))
          (w.key! as ValueKey<String>).value,
      ];
      for (final String key in controls) {
        await _tap(tester, key);
        expect(tester.takeException(), isNull, reason: '${entry.className}: $key');
      }
    }
  });
}
