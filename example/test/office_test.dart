import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/settings.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/office.dart';

Widget _officeApp(final HarborSettings settings) => HarborSettingsScope(
  settings: settings,
  child: MaterialApp(
    theme: Palette.theme(),
    builder: (final BuildContext context, final Widget? child) =>
        HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
    home: const HarborPage(child: Harbor(newPort: true, body: OfficeTab())),
  ),
);

Future<HarborSeaTrial> _pumpOffice(
  final WidgetTester tester, {
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
  final bool tideIn = false,
}) async {
  final HarborSettings settings = HarborSettings();
  addTearDown(settings.dispose);
  final HarborSeaTrial trial = await tester.pumpSeaTrial(_officeApp(settings), device: device, tideIn: tideIn);
  await tester.pump(const Duration(milliseconds: 100));
  return trial;
}

/// Scrolls the office fairway until [target] is built, then centers it. The
/// harbor's seas never settle, so this steps time rather than settling.
Future<void> _bringIntoView(final WidgetTester tester, final Finder target) async {
  final Finder scrollable = find
      .descendant(of: find.byKey(const ValueKey<String>('office fairway')), matching: find.byType(Scrollable))
      .first;
  for (int i = 0; i < 40 && target.evaluate().isEmpty; i++) {
    await tester.drag(scrollable, const Offset(0, -150));
    await tester.pump(const Duration(milliseconds: 300));
  }
  expect(target, findsWidgets);
  await Scrollable.ensureVisible(tester.element(target.first), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _open(final WidgetTester tester, final String row) async {
  await _bringIntoView(tester, find.text(row));
  await tester.tap(find.text(row));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

void main() {
  group('Cargo manifest (#25)', () {
    testWidgets('the footer clears the home indicator exactly once', (final WidgetTester tester) async {
      await _pumpOffice(tester);
      await _open(tester, 'Cargo manifest');
      expect(_rect(tester, 'cargo footer').bottom, 874.0 - 34.0);
    });

    testWidgets('keeps 16 off the bottom of a phone with no home indicator', (final WidgetTester tester) async {
      await _pumpOffice(tester, device: HarborTrialDevice.iPhoneSE);
      await _open(tester, 'Cargo manifest');
      expect(_rect(tester, 'cargo footer').bottom, 667.0 - 16.0);
    });

    testWidgets('the footer floats on the tide, and the crates scroll inside the cap', (
      final WidgetTester tester,
    ) async {
      final HarborSeaTrial trial = await _pumpOffice(tester, tideIn: true);
      await _open(tester, 'Cargo manifest');
      final HarborDockRecord footer = trial
          .docksAround(find.byKey(const ValueKey<String>('cargo footer')))
          .singleWhere((final HarborDockRecord d) => d.label == 'sheet footer');
      expect(footer.rect.bottom, trial.waterline);
      // The footer's own 16 minimum still stands over the keyboard.
      expect(_rect(tester, 'cargo footer').bottom, trial.waterline - 16.0);
      // Capped at 0.9 of the water above the keyboard: no overflow, the body scrolls.
      final Rect header = tester.getRect(find.byType(SheetHeader));
      expect(header.top, greaterThanOrEqualTo(trial.waterline * 0.1 - 0.5));
      expect(tester.takeException(), isNull);
      final ScrollableState crates = tester.state<ScrollableState>(
        find.descendant(of: find.byType(HarborSheet), matching: find.byType(Scrollable)).first,
      );
      expect(crates.position.maxScrollExtent, greaterThan(0));
    });
  });

  group('Charter board (#26)', () {
    testWidgets('rests at half the screen', (final WidgetTester tester) async {
      await _pumpOffice(tester);
      await _open(tester, 'Charter board');
      // Half of the water between the status bar and the bottom.
      expect(_rect(tester, 'charter header').top, moreOrLessEquals(874.0 - (874.0 - 62) * 0.5, epsilon: 1));
    });

    testWidgets('its heights are fractions of the water above the keyboard', (final WidgetTester tester) async {
      final HarborSeaTrial trial = await _pumpOffice(tester, tideIn: true);
      await _open(tester, 'Charter board');
      expect(_rect(tester, 'charter header').top, moreOrLessEquals(trial.waterline - (trial.waterline - 62) * 0.5, epsilon: 1));
    });
  });

  group('Harbor rules (#27)', () {
    for (final HarborTrialDevice device in HarborTrialDevice.phones) {
      testWidgets('"I agree" keeps at least 16 off the bottom on $device', (final WidgetTester tester) async {
        await _pumpOffice(tester, device: device);
        await _open(tester, 'Harbor rules');
        final double bottomCoast = device.coast.bottom > 16 ? device.coast.bottom : 16;
        expect(_rect(tester, 'i agree').bottom, device.size.height - bottomCoast);
      });
    }

    testWidgets('the rules start below the quay header', (final WidgetTester tester) async {
      await _pumpOffice(tester, device: HarborTrialDevice.iPhoneSE);
      await _open(tester, 'Harbor rules');
      final Rect header = _rect(tester, 'rules header');
      expect(header.top, 20.0);
      final Rect note = tester.getRect(
        find.descendant(of: find.byType(HarborRulesPage), matching: find.byType(LogbookNote)),
      );
      expect(note.top, greaterThanOrEqualTo(header.bottom));
    });
  });

  group('Signal flags (#28)', () {
    testWidgets('a signal raised on a page that leaves moves to the page on top', (final WidgetTester tester) async {
      await _pumpOffice(tester);
      await _bringIntoView(tester, find.byKey(const ValueKey<String>('raise and leave')));
      await tester.tap(find.byKey(const ValueKey<String>('raise and leave')));
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // The tower is gone, the flag still flies.
      expect(find.text('Signal tower'), findsNothing);
      final Finder flag = find.byKey(const ValueKey<String>('tower signal'));
      expect(flag, findsOneWidget);
      final Rect rect = tester.getRect(flag);
      expect(rect.bottom, lessThanOrEqualTo(874.0 - 34.0));
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('signals go to each slot', (final WidgetTester tester) async {
      await _pumpOffice(tester);
      await _bringIntoView(tester, find.text('Middle'));
      await tester.tap(find.text('Middle'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Steady as she goes'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Postcard (#29)', () {
    Future<(Rect, Rect)> postcardOn(
      final WidgetTester tester,
      final HarborTrialDevice device, {
      final bool tideIn = false,
    }) async {
      await _pumpOffice(tester, device: device, tideIn: tideIn);
      await _bringIntoView(tester, find.byKey(const ValueKey<String>('postcard header')));
      final Rect frame = _rect(tester, 'postcard frame');
      final Rect header = _rect(tester, 'postcard header').shift(-frame.topLeft);
      final Rect footer = tester.getRect(find.text('Wish you were here ⚓')).shift(-frame.topLeft);
      return (header, footer);
    }

    testWidgets('lays out the same on every device, keyboard or not', (final WidgetTester tester) async {
      final (Rect header17, Rect footer17) = await postcardOn(tester, HarborTrialDevice.iPhone17);
      final (Rect headerSE, Rect footerSE) = await postcardOn(tester, HarborTrialDevice.iPhoneSE);
      final (Rect headerTide, Rect footerTide) = await postcardOn(
        tester,
        HarborTrialDevice.androidThreeButton,
        tideIn: true,
      );
      expect(header17, const Rect.fromLTWH(0, 0, 300, 30));
      expect(headerSE, header17);
      expect(headerTide, header17);
      expect(footerSE, footer17);
      expect(footerTide, footer17);
    });
  });

  group('Chandlery (#30)', () {
    for (final HarborTrialDevice device in <HarborTrialDevice>[
      HarborTrialDevice.iPhone17,
      HarborTrialDevice.iPhoneSE,
    ]) {
      testWidgets('the shop\'s header docks right below the sheet\'s on $device', (final WidgetTester tester) async {
        await _pumpOffice(tester, device: device);
        await _open(tester, 'Chandlery');
        final Rect sheetHeader = _rect(tester, 'chandlery sheet header');
        final Rect shelves = _rect(tester, 'chandlery shelves');
        expect(shelves.top, sheetHeader.bottom);
      });
    }
  });

  group('Switches (#31)', () {
    testWidgets('flip the chart, right-to-left and TV', (final WidgetTester tester) async {
      final HarborSettings settings = HarborSettings();
      addTearDown(settings.dispose);
      await tester.pumpSeaTrial(_officeApp(settings));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey<String>('chart switch')));
      await tester.tap(find.byKey(const ValueKey<String>('rtl switch')));
      await tester.tap(find.byKey(const ValueKey<String>('tv switch')));
      await tester.pump();
      expect((settings.chart, settings.rtl, settings.tv), (true, true, true));
    });
  });
}
