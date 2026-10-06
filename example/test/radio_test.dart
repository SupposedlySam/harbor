import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor/testing.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/fleet.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/radio.dart';

Widget _app() => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: HarborPage(child: ChannelPage(channel: Fleet.channels.first)),
);

final Finder _composer = find.byKey(ChannelPage.composerKey);
final Finder _header = find.byKey(ChannelPage.headerKey);
final Finder _field = find.descendant(of: _composer, matching: find.byType(TextField));

/// Pumps the channel and stows the logbook note so it covers no calls.
Future<HarborSeaTrial> _pumpChannel(final WidgetTester tester, final HarborTrialDevice device) async {
  final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(), device: device);
  await tester.pump();
  await tester.tap(find.byType(LogbookNote));
  await tester.pump();
  return trial;
}

void main() {
  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    group(device.name, () {
      testWidgets('the composer rests on the home indicator and floats on the tide', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await _pumpChannel(tester, device);
        final Finder newest = find.byKey(ChannelPage.callKey(0));

        expect(tester.getRect(_composer).bottom, device.size.height - device.coast.bottom);
        expect(tester.getRect(newest).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(newest).bottom, greaterThan(tester.getRect(_composer).top - 24));

        await tester.tap(_field);
        await trial.raiseTide();

        expect(tester.getRect(_composer).bottom, trial.waterline);
        expect(tester.getRect(newest).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(newest).bottom, greaterThan(tester.getRect(_composer).top - 24));
        expect(tester.getRect(newest).top, greaterThanOrEqualTo(tester.getRect(_header).bottom));
      });

      testWidgets('a sent call lands just above the composer', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await _pumpChannel(tester, device);
        await tester.tap(_field);
        await trial.raiseTide();
        await tester.enterText(_field, 'Ahoy, Harbor Control!');
        await tester.tap(find.byTooltip('Send'));
        await tester.pump();

        final Finder sent = find.byKey(ChannelPage.callKey(Fleet.channels.first.calls.length));
        expect(find.descendant(of: sent, matching: find.text('Ahoy, Harbor Control!')), findsOneWidget);
        expect(tester.getRect(sent).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(sent).bottom, greaterThan(tester.getRect(_composer).top - 24));
      });

      testWidgets('the crew buoy floats above the composer, below the header', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await _pumpChannel(tester, device);
        await tester.tap(_field);
        await trial.raiseTide();
        await tester.enterText(_field, 'Ask @');
        await tester.pump();
        await tester.pump();

        final Finder buoy = find.byKey(ChannelPage.mentionsKey);
        expect(buoy, findsOneWidget);
        expect(tester.getRect(buoy).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(buoy).top, greaterThanOrEqualTo(tester.getRect(_header).bottom));

        await tester.enterText(_field, 'Ask @H');
        await tester.pump();
        await tester.tap(find.text('Hana'));
        await tester.pump();
        expect(tester.widget<TextField>(_field).controller!.text, 'Ask @Hana ');
        expect(buoy, findsNothing);
      });

      testWidgets('the call actions stay in the clear water', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await _pumpChannel(tester, device);
        final Rect clear = trial.clearWaterAround(_composer);
        await tester.longPress(find.byKey(ChannelPage.callKey(0)));
        await tester.pump(const Duration(milliseconds: 300));

        final Finder card = find.byKey(ChannelPage.actionsKey);
        expect(card, findsOneWidget);
        expect(card, isInClearWater(clear));
        expect(tester.getRect(card).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(card).top, greaterThanOrEqualTo(tester.getRect(_header).bottom));
        await tester.tap(find.text('Reply'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(card, findsNothing);
        expect(tester.widget<TextField>(_field).controller!.text, startsWith('You, copy that.'));
      });

      testWidgets('an edited call is kept in sight as the tide comes in', (final WidgetTester tester) async {
        final HarborSeaTrial trial = await _pumpChannel(tester, device);
        // Fold the logbook note out of the way, as a sailor would.
        await tester.tap(find.byKey(const ValueKey<String>('logbook note')));
        await tester.pump(const Duration(milliseconds: 300));
        // The highest of our own calls still wholly in sight: the rising tide
        // would push it up under the header.
        final Rect clear = trial.clearWaterAround(_composer);
        int id = 0;
        for (int i = 0; i < Fleet.channels.first.calls.length; i++) {
          final Finder candidate = find.byKey(ChannelPage.callKey(i));
          if (candidate.evaluate().isEmpty || tester.getRect(candidate).top < clear.top) {
            break;
          }
          if (Fleet.channels.first.calls[i].mine) {
            id = i;
          }
        }
        expect(id, greaterThan(0));
        final Finder call = find.byKey(ChannelPage.callKey(id));
        await tester.longPress(call);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Edit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.widget<TextField>(_field).controller!.text, Fleet.channels.first.calls[id].text);

        await trial.raiseTide();

        expect(tester.getRect(call).top, greaterThanOrEqualTo(tester.getRect(_header).bottom));
        expect(tester.getRect(call).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));

        await tester.enterText(_field, 'Berth four, amended.');
        await tester.tap(find.byTooltip('Send'));
        await tester.pump();
        expect(find.descendant(of: call, matching: find.text('Berth four, amended.')), findsOneWidget);
      });

      testWidgets('the thread keeps clear of the photo locker', (final WidgetTester tester) async {
        await _pumpChannel(tester, device);
        await tester.tap(find.byTooltip('Photo locker'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();

        // The sheet's surface starts at its header; below the header is all sheet.
        final Rect sheet = tester.getRect(find.byType(SheetHeader));
        expect(sheet.top, lessThan(tester.getRect(_composer).top));
        expect(sheet.top, greaterThan(tester.getRect(_header).bottom));
        final Finder newest = find.byKey(ChannelPage.callKey(0));
        expect(tester.getRect(newest).bottom, lessThanOrEqualTo(sheet.top + 0.5));

        await tester.tap(find.byTooltip('Close'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(find.byType(HarborSheet), findsNothing);
        expect(tester.getRect(newest).bottom, lessThanOrEqualTo(tester.getRect(_composer).top));
        expect(tester.getRect(newest).bottom, greaterThan(tester.getRect(_composer).top - 24));
      });
    });
  }
}
