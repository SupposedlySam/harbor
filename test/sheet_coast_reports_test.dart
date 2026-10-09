// #97: a sheet that casts the status bar off for its content still keeps it out of its clear
// water. #98: casting the sides off with no HarborSea keeps the bottom inset.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Future<BuildContext> _app(final WidgetTester tester, {required final bool sea}) async {
  late BuildContext page;
  await tester.pumpSeaTrial(MaterialApp(
    builder: sea ? (final c, final child) => HarborSea(child: child!) : null,
    home: Builder(builder: (final c) {
      page = c;
      return const SizedBox.expand();
    }),
  ));
  return page;
}

void main() {
  group('#98 clearsSides with no HarborSea', () {
    for (final bool sea in <bool>[false, true]) {
      for (final bool sides in <bool>[false, true]) {
        testWidgets('the body reads the home indicator at the bottom (sea: $sea, clearsSides: $sides)', (final tester) async {
          final BuildContext page = await _app(tester, sea: sea);
          late EdgeInsets padding;
          unawaited(showHarborSheet<void>(
            page,
            builder: (final BuildContext _) => HarborSheet(
              clearsSides: sides,
              body: Builder(builder: (final c) {
                padding = MediaQuery.paddingOf(c);
                return const SizedBox(height: 100);
              }),
            ),
          ));
          await tester.pumpAndSettle();
          expect(padding.bottom, 34);
        });
      }
    }

    testWidgets('a HarborMoored over a new port, with no sea, casts off only its own edges', (final tester) async {
      late EdgeInsets padding;
      await tester.pumpSeaTrial(MaterialApp(
        home: HarborMoored(
          edges: HarborEdge.horizontal,
          clear: HarborClear.coast,
          tide: false,
          // A new port reads its coast from the waters above it, as a sheet's does.
          child: Harbor(newPort: true, body: Builder(builder: (final c) {
            padding = MediaQuery.paddingOf(c);
            return const SizedBox.expand();
          })),
        ),
      ));
      expect(padding.top, 62);
      expect(padding.bottom, 34);
    });
  });

  group('#97 clearsTopCoast: false and the clear water', () {
    Future<(BuildContext, EdgeInsets)> open(final WidgetTester tester, {required final bool clears}) async {
      final BuildContext page = await _app(tester, sea: true);
      late BuildContext inSheet;
      unawaited(showHarborSheet<void>(
        page,
        keepsTopCoast: true,
        builder: (final BuildContext _) => HarborSheet.draggable(
          clearsTopCoast: clears,
          extent: const HarborSheetExtent(rest: 1.0, max: 1.0),
          builder: (final c, final controller) {
            inSheet = c;
            return ListView(controller: controller, children: const <Widget>[SizedBox(height: 2000)]);
          },
        ),
      ));
      await tester.pumpAndSettle();
      return (inSheet, MediaQuery.paddingOf(inSheet));
    }

    Future<double> flareTop(final WidgetTester tester, final BuildContext inSheet) async {
      HarborFlares.raise(
        inSheet,
        slot: HarborFlareSlot.top,
        builder: (final c) => const SizedBox(key: ValueKey<String>('flare'), height: 20, width: 60),
        duration: null,
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return tester.getRect(find.byKey(const ValueKey<String>('flare'))).top;
    }

    testWidgets('the content reads no status bar, but a flare keeps clear of it', (final tester) async {
      final (BuildContext inSheet, EdgeInsets padding) = await open(tester, clears: false);
      expect(padding.top, 0, reason: 'what clearsTopCoast: false is for');
      expect(Harbor.of(inSheet).clearWaterInGlobal()!.top, 62);
      expect(await flareTop(tester, inSheet), 62 + 16);
    });

    testWidgets('positive control: with the option off, the same', (final tester) async {
      final (BuildContext inSheet, EdgeInsets padding) = await open(tester, clears: true);
      expect(padding.top, 62);
      expect(await flareTop(tester, inSheet), 62 + 16);
    });
  });
}
