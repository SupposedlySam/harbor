// A dialog keeps clear of the system edges by default, as one from showDialog does with its
// useSafeArea: a tall Material Dialog stopped at the keyboard but ran under the status bar and the
// home indicator. `clearsSystemEdges: false` leaves them to the dialog, as it was.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const ValueKey<String> _content = ValueKey<String>('content');

/// Pumps a page on [device] and returns its context, to open dialogs from.
Future<(BuildContext, HarborTrial)> _page(
  final WidgetTester tester, {
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
}) async {
  late BuildContext pageContext;
  final HarborTrial trial = await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: Material(
        child: HarborFrame(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ),
    device: device,
  );
  return (pageContext, trial);
}

/// A Material dialog taller than any screen, scrolling its content.
/// The key is on what fills the dialog's surface: `Dialog` itself is laid out across the screen,
/// with its inset as padding.
Widget _tall(final BuildContext _) => const Dialog(
  child: SingleChildScrollView(key: _content, child: SizedBox(width: 200, height: 3000)),
);

Future<Rect> _show(
  final WidgetTester tester,
  final BuildContext page,
  final WidgetBuilder builder, {
  final bool? clearsSystemEdges,
}) async {
  unawaited(
    clearsSystemEdges == null
        ? showHarborDialog<void>(page, builder: builder)
        : showHarborDialog<void>(page, clearsSystemEdges: clearsSystemEdges, builder: builder),
  );
  await tester.pumpAndSettle();
  return tester.getRect(find.byKey(_content));
}

void main() {
  for (final HarborTrialDevice device in <HarborTrialDevice>[HarborTrialDevice.iPhone17, HarborTrialDevice.iPhoneSE]) {
    final EdgeInsets edges = device.systemEdges;
    group(device.name, () {
      testWidgets('a tall dialog keeps clear of the status bar and the home indicator', (final tester) async {
        final (BuildContext page, _) = await _page(tester, device: device);
        final Rect dialog = await _show(tester, page, _tall);
        expect(dialog.top, greaterThanOrEqualTo(edges.top));
        expect(dialog.bottom, lessThanOrEqualTo(device.size.height - edges.bottom));
        // Material's own inset is kept, inside the system edges, as under showDialog's SafeArea.
        expect(dialog.top, edges.top + 24);
        expect(dialog.bottom, device.size.height - edges.bottom - 24);
      });

      testWidgets('clearsSystemEdges: false leaves a tall dialog as it was', (final tester) async {
        final (BuildContext page, _) = await _page(tester, device: device);
        final Rect dialog = await _show(tester, page, _tall, clearsSystemEdges: false);
        expect(dialog.top, 24);
        expect(dialog.bottom, device.size.height - 24);
      });

      testWidgets('a HarborClear inside the dialog does not clear the system edges again', (final tester) async {
        final (BuildContext page, _) = await _page(tester, device: device);
        final Rect content = await _show(
          tester,
          page,
          (final BuildContext _) => const HarborClear(child: SizedBox.expand(key: _content)),
        );
        expect(content, Rect.fromLTRB(0, edges.top, device.size.width, device.size.height - edges.bottom));
      });

      testWidgets('with clearsSystemEdges: false a HarborClear inside clears them, once', (final tester) async {
        final (BuildContext page, _) = await _page(tester, device: device);
        final Rect content = await _show(
          tester,
          page,
          (final BuildContext _) => const HarborClear(child: SizedBox.expand(key: _content)),
          clearsSystemEdges: false,
        );
        expect(content, Rect.fromLTRB(0, edges.top, device.size.width, device.size.height - edges.bottom));
      });

      testWidgets('a short dialog is centred between the system edges', (final tester) async {
        final (BuildContext page, _) = await _page(tester, device: device);
        final Rect dialog = await _show(
          tester,
          page,
          (final BuildContext _) => const Dialog(child: SizedBox(key: _content, width: 200, height: 100)),
        );
        expect(dialog.center.dy, device.size.height / 2 + (edges.top - edges.bottom) / 2);
      });

      testWidgets('with the keyboard up a tall dialog stops at the keyboard, not above it', (final tester) async {
        final (BuildContext page, HarborTrial trial) = await _page(tester, device: device);
        await trial.showKeyboard();
        final Rect dialog = await _show(tester, page, _tall);
        expect(dialog.top, edges.top + 24);
        // The keyboard covers the home indicator, which is not cleared on top of it.
        expect(dialog.bottom, device.size.height - device.keyboardHeight - 24);
      });
    });
  }

  for (final bool clearInside in <bool>[false, true]) {
    testWidgets(
      'with inheritRoom the dialog clears the opener\'s bars in place of the status bar'
      '${clearInside ? ', and a HarborClear inside adds nothing' : ''}',
      (final tester) async {
        late BuildContext page;
        await tester.pumpHarborTrial(
          MaterialApp(
            builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
            home: Material(
              child: HarborFrame(
                top: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 50))],
                bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 60))],
                body: Builder(
                  builder: (final BuildContext context) {
                    page = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        );
        final Rect room = HarborFrame.of(page).roomInGlobal()!;
        unawaited(
          showHarborDialog<void>(
            page,
            inheritRoom: true,
            builder: (final BuildContext _) => clearInside
                ? const HarborClear(child: SizedBox.expand(key: _content))
                : const SizedBox.expand(key: _content),
          ),
        );
        await tester.pumpAndSettle();
        expect(room.top, 62 + 50);
        expect(tester.getRect(find.byKey(_content)), room);
      },
    );
  }

  testWidgets('HarborDialogRoute clears the system edges by default and takes clearsSystemEdges', (
    final tester,
  ) async {
    final (BuildContext page, _) = await _page(tester);
    final HarborDialogRoute<void> cleared = HarborDialogRoute<void>(context: page, builder: _tall);
    expect(cleared.clearsSystemEdges, isTrue);
    unawaited(Navigator.of(page).push(cleared));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_content)).top, 62 + 24);
    Navigator.of(page).pop();
    await tester.pumpAndSettle();

    final HarborDialogRoute<void> left = HarborDialogRoute<void>(
      context: page,
      clearsSystemEdges: false,
      builder: _tall,
    );
    expect(left.clearsSystemEdges, isFalse);
    unawaited(Navigator.of(page).push(left));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(_content)).top, 24);
  });
}
