import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor/testing.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/fleet.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/fleet.dart';

const ValueKey<String> _tabs = ValueKey<String>('tabs');

/// The Fleet tab inside a stand-in for Harbor Town: a new port whose tab bar
/// is a quay on pilings.
Widget _townWithFleet() => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: const HarborPage(
    child: Harbor(
      newPort: true,
      bottom: <HarborDock>[HarborDock.quay(child: SizedBox(key: _tabs, height: 56))],
      body: FleetTab(),
    ),
  ),
);

Widget _detail(final Boat boat) => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: BoatDetailPage(boat: boat),
);

/// The Sea and the bobbing boat never settle, so step frames by hand.
Future<void> _settle(final WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Scrolls [scrollable] by [delta] exactly, then lets the beacons report.
Future<void> _sail(final WidgetTester tester, final Finder scrollable, final double delta) async {
  final ScrollPosition position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.pixels + delta);
  await _settle(tester);
}

/// Scrolls [scrollable] to its end; a lazy list only estimates its extent
/// until it has built its end, so sail on until the extent stops growing.
Future<void> _sailToEnd(final WidgetTester tester, final Finder scrollable) async {
  final ScrollPosition position = tester.state<ScrollableState>(scrollable).position;
  do {
    position.jumpTo(position.maxScrollExtent);
    await _settle(tester);
  } while (position.pixels < position.maxScrollExtent);
}

HarborDockRecord _dock(final HarborSeaTrial trial, final Finder around, final String label) =>
    trial.docksAround(around).singleWhere((final HarborDockRecord d) => d.label == label);

double _headerTitleOpacity(final WidgetTester tester, final Boat boat) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.descendant(of: find.byType(PierHeader), matching: find.text(boat.name)),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  final Boat boat = Fleet.boats.first;

  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    group('$device', () {
      testWidgets('fleet registry: rows rest past the wake; the tab bar stays put on the tide', (
        final WidgetTester tester,
      ) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_townWithFleet(), device: device);
        await tester.pumpAndSettle();

        // The first sliver rests just past the header's wake, and the first
        // boat below it.
        final Finder note = find.byType(LogbookNote);
        final Rect clear = trial.clearWaterAround(note);
        final HarborDockRecord header = _dock(trial, note, 'registry header');
        expect(clear.top, moreOrLessEquals(header.rect.bottom + 12));
        expect(tester.getRect(note).top, moreOrLessEquals(clear.top));
        final Finder firstRow = find.byKey(ValueKey<String>('boat row ${Fleet.boats.first.id}'));
        expect(tester.getRect(firstRow).top, greaterThanOrEqualTo(header.rect.bottom + 12));

        // Focus the search; the keyboard comes in over the tab bar.
        final Rect tabsBefore = tester.getRect(find.byKey(_tabs));
        await tester.tap(find.byKey(const ValueKey<String>('registry search')));
        await tester.pump();
        await trial.raiseTide();
        expect(tester.getRect(find.byKey(_tabs)), tabsBefore);
        expect(tabsBefore.top, greaterThanOrEqualTo(trial.waterline));

        // The last boat is still reachable, and docks above the keyboard.
        // A lazy list only estimates its extent until it has built its end,
        // so sail on until the extent stops growing.
        final ScrollPosition position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
        do {
          await tester.drag(find.byType(Scrollable).first, const Offset(0, -6000));
          await tester.pumpAndSettle();
        } while (position.pixels < position.maxScrollExtent);
        final Finder lastRow = find.byKey(ValueKey<String>('boat row ${Fleet.boats.last.id}'));
        expect(lastRow, findsOneWidget);
        expect(tester.getRect(lastRow).bottom, moreOrLessEquals(trial.waterline));
      });

      testWidgets('boat detail: hero, title handoff, pinned strips, carousel, pontoon', (
        final WidgetTester tester,
      ) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_detail(boat), device: device);
        await _settle(tester);

        final Finder page = find.byType(Scrollable).first;
        final Finder headerFinder = find.byKey(const ValueKey<String>('boat header'));
        final HarborDockRecord header = _dock(trial, headerFinder, 'boat header');
        final Rect clear = trial.clearWaterAround(headerFinder);
        expect(clear.top, moreOrLessEquals(header.rect.bottom + 8));

        // #10: the hero's title block clears the status bar, under the header.
        // #10: the hero starts at the frame's top, under the header and the
        // status bar.
        expect(tester.getRect(find.byKey(const ValueKey<String>('boat hero'))).top, 0.0);
        final Rect titleBlock = tester.getRect(find.byKey(const ValueKey<String>('hero title block')));
        expect(titleBlock.top, greaterThanOrEqualTo(device.coast.top));
        expect(titleBlock.top, lessThan(header.rect.bottom));

        // #11: the header's title fades in as the hero title passes under it.
        final double before = _headerTitleOpacity(tester, boat);
        final Rect heroTitle = tester.getRect(find.byKey(const ValueKey<String>('hero title')));
        await _sail(tester, page, heroTitle.top - clear.top + heroTitle.height / 2);
        expect(before, 0.0);
        expect(_headerTitleOpacity(tester, boat), moreOrLessEquals(0.5, epsilon: 0.05));

        // #12: the tab strip pins at the header's bottom, and the sort strip
        // stacks under it.
        final Finder voyage = find.byKey(const ValueKey<String>('longest voyage'));
        await _sail(tester, page, tester.getRect(voyage).top - clear.top + 60);
        final Rect tabs = tester.getRect(find.byKey(const ValueKey<String>('logbook tabs')));
        expect(tabs.top, moreOrLessEquals(header.rect.bottom));
        final Rect sort = tester.getRect(find.byKey(const ValueKey<String>('sort strip')));
        expect(sort.top, moreOrLessEquals(tabs.bottom));

        // The voyage pill rides its voyage, then sticks 8 below the last
        // pinned strip.
        expect(tester.getRect(voyage).top, lessThan(sort.bottom));
        expect(
          tester.getRect(find.byKey(const ValueKey<String>('voyage pill'))).top,
          moreOrLessEquals(sort.bottom + 8),
        );

        // #13: the carousel runs edge to edge, padded by the mooring line.
        final Finder carousel = find.byKey(const ValueKey<String>('crew carousel'));
        await tester.scrollUntilVisible(carousel, 100, scrollable: page);
        await Scrollable.ensureVisible(tester.element(carousel), alignment: 0.5);
        await _settle(tester);
        final double width = device.size.width;
        expect(tester.getRect(carousel).width, width);
        expect(tester.getRect(find.byKey(ValueKey<String>('crew ${Fleet.crew.first.name}'))).left, 16);
        await _sailToEnd(tester, find.descendant(of: carousel, matching: find.byType(Scrollable)).first);
        expect(tester.getRect(find.byKey(ValueKey<String>('crew ${Fleet.crew.last.name}'))).right, width - 16);

        // #14: the charter pill rests above the bottom coast, and the last
        // voyage tile rests above the pill.
        final Rect pill = tester.getRect(find.byKey(const ValueKey<String>('charter pill')));
        expect(pill.bottom, lessThanOrEqualTo(device.size.height - device.coast.bottom));
        await _sailToEnd(tester, page);
        final Rect lastTile = tester.getRect(find.byKey(const ValueKey<String>('voyage tile 11')));
        expect(lastTile.bottom, lessThanOrEqualTo(pill.top));
        expect(lastTile.bottom, greaterThan(pill.top - 40));
      });
    });
  }
}
