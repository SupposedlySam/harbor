import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/art/sea.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/open_sea.dart';

/// A stand-in for Harbor Town: a new port with a 56-high tab bar quay.
Widget _town() => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: const HarborPage(
    child: Harbor(
      newPort: true,
      bottom: <HarborDock>[
        HarborDock.quay(debugLabel: 'tab bar', child: SizedBox(key: ValueKey<String>('tab bar'), height: 56)),
      ],
      body: OpenSeaTab(),
    ),
  ),
);

/// The Sea and the bobbing boats never settle, so step time instead.
Future<void> _sail(final WidgetTester tester, [final Duration by = const Duration(milliseconds: 600)]) async {
  for (int i = 0; i < 6; i++) {
    await tester.pump(by ~/ 6);
  }
}

final Finder _header = find.byType(PierHeader);
final Finder _card = find.byKey(const ValueKey<String>('voyage card 0'));
final Finder _drawer = find.byKey(const ValueKey<String>('shanty drawer'));
final Finder _fogHorn = find.byKey(const ValueKey<String>('fog horn'));

HarborDockRecord _topDock(final HarborSeaTrial trial) =>
    trial.docksAround(_card).singleWhere((final HarborDockRecord d) => d.edge == HarborEdge.top);

void main() {
  testWidgets('in landscape the mood chips run past the cutout but rest on the mooring line', (final WidgetTester tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17Landscape;
    await tester.pumpSeaTrial(_town(), device: device);
    await _sail(tester);

    final Finder fairway = find.ancestor(
      of: find.byKey(const ValueKey<String>('mood calm')),
      matching: find.byType(Scrollable),
    );
    expect(tester.getRect(fairway).left, 0.0, reason: 'the fairway runs to the frame edge, under the cutout');
    expect(tester.getRect(fairway).right, device.size.width);
    expect(tester.getRect(find.byKey(const ValueKey<String>('mood calm'))).left, moreOrLessEquals(device.coast.left + 16));
    await _sail(tester, const Duration(seconds: 2));
  });

  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    group('Open Sea on ${device.name}', () {
      testWidgets('the header is a pier below the status bar over full-bleed open water', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_town(), device: device);
        await _sail(tester);

        expect(tester.getRect(_header).top, moreOrLessEquals(device.coast.top));
        final HarborDockRecord header = _topDock(trial);
        expect(header.kind, HarborDockKind.pier);
        expect(header.rect.top, 0.0, reason: 'the dock (and its frosting) runs under the status bar');
        // Open water starts at the top of the screen, under the status bar and the header.
        final Rect sea = tester.getRect(find.byType(Sea));
        expect(sea.top, 0.0);
        expect(sea.bottom, moreOrLessEquals(tester.getRect(find.byKey(const ValueKey<String>('tab bar'))).top));
        await _sail(tester, const Duration(seconds: 2));
      });

      testWidgets('the mood chips start on the mooring line and choosing one changes the sea', (final WidgetTester tester) async {
        await tester.pumpSeaTrial(_town(), device: device);
        await _sail(tester);

        expect(tester.getRect(find.byKey(const ValueKey<String>('mood calm'))).left, moreOrLessEquals(16.0));
        await tester.tap(find.byKey(const ValueKey<String>('mood stormy')));
        await _sail(tester);
        final ChoiceChip stormy = tester.widget(find.byKey(const ValueKey<String>('mood stormy')));
        expect(stormy.selected, isTrue);
        await _sail(tester, const Duration(seconds: 2));
      });

      testWidgets('the voyage card is moored in the clear water, and the fog horn sits just above the tab bar', (
        final WidgetTester tester,
      ) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_town(), device: device);
        await _sail(tester, const Duration(milliseconds: 300));

        final Rect water = trial.clearWaterAround(_card);
        expect(_card, isInClearWater(water));
        expect(water.top, greaterThan(tester.getRect(_header).bottom), reason: 'the header and its wake are cleared');
        final Rect tabBar = tester.getRect(find.byKey(const ValueKey<String>('tab bar')));
        expect(water.bottom, moreOrLessEquals(tabBar.top));

        // The page is still "loading": the fog horn is up.
        expect(_fogHorn, findsOneWidget);
        expect(_fogHorn, isInClearWater(water));
        expect(tester.getRect(_fogHorn).bottom, moreOrLessEquals(water.bottom - 16));

        await _sail(tester, const Duration(seconds: 2));
        expect(_fogHorn, findsNothing);
      });

      testWidgets('the shanty drawer withdraws the header and the card reflows above it', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_town(), device: device);
        await _sail(tester, const Duration(seconds: 2));
        final Rect before = tester.getRect(_card);

        await tester.ensureVisible(find.text('Sing a shanty'));
        await tester.tap(find.text('Sing a shanty'));
        await _sail(tester, const Duration(seconds: 1));

        expect(_drawer, findsOneWidget);
        expect(_topDock(trial).state, HarborDockState.withdrawn);
        final Rect card = tester.getRect(_card);
        final Rect drawer = tester.getRect(_drawer);
        expect(card.top, lessThan(before.top), reason: 'the card moves up into the header\'s ground');
        expect(card.top, greaterThanOrEqualTo(device.coast.top), reason: 'but stays clear of the status bar');
        expect(card.bottom, lessThanOrEqualTo(drawer.top + 0.5));
        expect(drawer.top, lessThan(tester.getRect(find.byKey(const ValueKey<String>('tab bar'))).top));
        expect(_card, isInClearWater(trial.clearWaterAround(_card)));

        // Closing the drawer releases the claim.
        await tester.tap(find.byTooltip('Close'));
        await _sail(tester, const Duration(seconds: 1));
        expect(_drawer, findsNothing);
        expect(_topDock(trial).state, HarborDockState.open);
        expect(tester.getRect(_card), before);
      });

      testWidgets('on a followed voyage the header goes dark for the drawer, keeping its ground', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_town(), device: device);
        await _sail(tester, const Duration(seconds: 2));

        await tester.ensureVisible(find.text('Follow this voyage'));
        await tester.tap(find.text('Follow this voyage'));
        await _sail(tester, const Duration(seconds: 2));
        expect(find.byType(VoyagePage), findsOneWidget);
        expect(find.byTooltip('Back'), findsOneWidget);
        final Rect before = tester.getRect(_card);

        await tester.ensureVisible(find.text('Sing a shanty'));
        await tester.tap(find.text('Sing a shanty'));
        await _sail(tester, const Duration(seconds: 1));

        expect(_topDock(trial).state, HarborDockState.dark);
        final Rect card = tester.getRect(_card);
        expect(card.top, moreOrLessEquals(before.top), reason: 'a dark header keeps its ground');
        expect(card.bottom, lessThanOrEqualTo(tester.getRect(_drawer).top + 0.5));

        await tester.tap(find.byTooltip('Close'));
        await _sail(tester, const Duration(seconds: 1));
        expect(_topDock(trial).state, HarborDockState.open);
      });
    });
  }
}
