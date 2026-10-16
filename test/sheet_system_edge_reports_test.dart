// #97: a sheet that marks the status bar handled for its content still keeps it out of its
// room. #98: marking the sides handled with no HarborRoot keeps the bottom inset.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Future<BuildContext> _app(final WidgetTester tester, {required final bool root}) async {
  late BuildContext page;
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: root ? (final c, final child) => HarborRoot(child: child!) : null,
      home: Builder(
        builder: (final c) {
          page = c;
          return const SizedBox.expand();
        },
      ),
    ),
  );
  return page;
}

void main() {
  group('#98 clearsSides with no HarborRoot', () {
    for (final bool root in <bool>[false, true]) {
      for (final bool sides in <bool>[false, true]) {
        testWidgets('the body reads the home indicator at the bottom (root: $root, clearsSides: $sides)', (
          final tester,
        ) async {
          final BuildContext page = await _app(tester, root: root);
          late EdgeInsets padding;
          unawaited(
            showHarborSheet<void>(
              page,
              builder: (final BuildContext _) => HarborSheet(
                clearsSides: sides,
                body: Builder(
                  builder: (final c) {
                    padding = MediaQuery.paddingOf(c);
                    return const SizedBox(height: 100);
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(padding.bottom, 34);
        });
      }
    }

    testWidgets('a HarborClear over a page, with no root, marks only its own edges handled', (final tester) async {
      late EdgeInsets padding;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: HarborClear(
            edges: HarborEdge.horizontal,
            clearsBars: false,
            clearsKeyboard: false,
            // A page reads its system edges from the room above it, as a sheet's does.
            child: HarborFrame(
              isPage: true,
              body: Builder(
                builder: (final c) {
                  padding = MediaQuery.paddingOf(c);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      expect(padding.top, 62);
      expect(padding.bottom, 34);
    });
  });

  group('#97 clearsTopSystemEdge: false and the room', () {
    Future<(BuildContext, EdgeInsets)> open(final WidgetTester tester, {required final bool clears}) async {
      final BuildContext page = await _app(tester, root: true);
      late BuildContext inSheet;
      unawaited(
        showHarborSheet<void>(
          page,
          reachesTop: true,
          builder: (final BuildContext _) => HarborSheet.draggable(
            clearsTopSystemEdge: clears,
            extent: const HarborSheetExtent(rest: 1.0, max: 1.0),
            builder: (final c, final controller) {
              inSheet = c;
              return ListView(controller: controller, children: const <Widget>[SizedBox(height: 2000)]);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return (inSheet, MediaQuery.paddingOf(inSheet));
    }

    Future<double> toastTop(final WidgetTester tester, final BuildContext inSheet) async {
      HarborToasts.show(
        inSheet,
        slot: HarborToastSlot.top,
        builder: (final c) => const SizedBox(key: ValueKey<String>('flare'), height: 20, width: 60),
        timing: HarborToastTiming.untilHidden,
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return tester.getRect(find.byKey(const ValueKey<String>('flare'))).top;
    }

    testWidgets('the content reads no status bar, but a toast keeps clear of it', (final tester) async {
      final (BuildContext inSheet, EdgeInsets padding) = await open(tester, clears: false);
      expect(padding.top, 0, reason: 'what clearsTopCoast: false is for');
      expect(HarborFrame.of(inSheet).roomInGlobal()!.top, 62);
      expect(await toastTop(tester, inSheet), 62 + 16);
    });

    testWidgets('positive control: with the option off, the same', (final tester) async {
      final (BuildContext inSheet, EdgeInsets padding) = await open(tester, clears: true);
      expect(padding.top, 62);
      expect(await toastTop(tester, inSheet), 62 + 16);
    });
  });
}
