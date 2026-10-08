// A sheet with no barrier lives in the navigator's overlay, not in a route of its own, so it has
// to be tied to the page that opened it by hand. Found by the back-navigation audit; each test
// failed on the code before this file existed.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

Widget _app() => MaterialApp(
  navigatorKey: _navigator,
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: const Harbor(body: Center(child: Text('home'))),
);

/// Pushes a harbor page and returns a context inside it, as a button in its body would have.
Future<BuildContext> _pushPage(final WidgetTester tester, {final bool cupertino = false}) async {
  late BuildContext inside;
  Widget page(final BuildContext _) => Harbor(
    body: Builder(
      builder: (final BuildContext context) {
        inside = context;
        return const Center(child: Text('page'));
      },
    ),
  );
  unawaited(_navigator.currentState!.push(cupertino ? CupertinoPageRoute<void>(builder: page) : MaterialPageRoute<void>(builder: page)));
  await tester.pumpAndSettle();
  return inside;
}

void _openSheet(final BuildContext context) => unawaited(showHarborSheet<void>(
  context,
  barrier: HarborSheetBarrier.none,
  builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 200, child: Text('sheet'))),
));

void main() {
  // Failed before: back popped the page under the sheet (`page=false`).
  testWidgets('back closes a sheet with no barrier and leaves its page', (final tester) async {
    await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
    _openSheet(await _pushPage(tester));
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget, reason: 'positive control: the sheet is up');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(find.text('page'), findsOneWidget, reason: 'the page is still there');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing, reason: 'positive control: back pops the page once the sheet is gone');
  });

  // Failed before: opened from a context above the page's harbor, the sheet was tied to the sea,
  // which never leaves, so it outlived its page. A pop now closes the sheet first, as back does, so
  // the case left is the page being replaced or removed while its sheet is up.
  testWidgets('a sheet with no barrier leaves with the page that opened it', (final tester) async {
    await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
    final GlobalKey outer = GlobalKey();
    unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(
      builder: (final BuildContext _) => Harbor(key: outer, body: const Center(child: Text('page'))),
    )));
    await tester.pumpAndSettle();
    _openSheet(outer.currentContext!);
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget, reason: 'positive control: the sheet is up');

    unawaited(_navigator.currentState!.pushReplacement(
      MaterialPageRoute<void>(builder: (final BuildContext _) => const Harbor(body: Center(child: Text('replacement')))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('replacement'), findsOneWidget);
    expect(find.text('page'), findsNothing);
    expect(find.text('sheet'), findsNothing);
  });

  testWidgets('a pop closes the sheet first, then the page', (final tester) async {
    await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
    _openSheet(await _pushPage(tester));
    await tester.pumpAndSettle();
    _navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);
    expect(find.text('page'), findsOneWidget);
    _navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing);
  });

  // Failed before: the sheet stayed painted and tappable over a page pushed on top of its own.
  testWidgets('a sheet with no barrier is hidden while another page is on top, and back again after', (final tester) async {
    await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
    _openSheet(await _pushPage(tester));
    await tester.pumpAndSettle();
    unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => const Harbor(body: Center(child: Text('third'))))));
    await tester.pumpAndSettle();
    expect(find.text('third'), findsOneWidget);
    expect(find.text('sheet').hitTestable(), findsNothing, reason: 'not over the page on top');

    _navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet').hitTestable(), findsOneWidget, reason: 'back with its page');
  });

  // Failed before: the edge swipe dragged the page away from under the sheet.
  testWidgets("the iOS back swipe leaves a page alone while its sheet with no barrier is up", (final tester) async {
    await tester.pumpSeaTrial(_app());
    _openSheet(await _pushPage(tester, cupertino: true));
    await tester.pumpAndSettle();
    final TestGesture swipe = await tester.startGesture(const Offset(5, 300));
    for (int i = 0; i < 10; i++) {
      await swipe.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await swipe.up();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(find.text('sheet'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
