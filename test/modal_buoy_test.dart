// A modal buoy is modal: a barrier over the page, dismissed by a tap beside it or by back. Until
// 0.2.0 `modal: true` only hid the buoys listed before it, and taps and back reached the page.
// Each test here fails on that behaviour.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

class _Page extends StatefulWidget {
  const _Page({required this.taps});

  final List<String> taps;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  bool menu = true;
  int dismissed = 0;

  void close() => setState(() => menu = false);

  @override
  Widget build(final BuildContext context) => Harbor(
    buoys: <HarborBuoy>[
      if (menu)
        HarborBuoy(
          modal: true,
          onDismiss: () => setState(() {
            menu = false;
            dismissed++;
          }),
          alignment: Alignment.center,
          child: const SizedBox(key: ValueKey<String>('menu'), width: 160, height: 120, child: Text('menu')),
        ),
    ],
    body: Align(
      alignment: Alignment.topLeft,
      child: TextButton(onPressed: () => widget.taps.add('page'), child: const Text('Page action')),
    ),
  );
}

Future<_PageState> _pumpPage(final WidgetTester tester, final List<String> taps) async {
  await tester.pumpSeaTrial(
    MaterialApp(
      navigatorKey: _navigator,
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: const Harbor(body: Center(child: Text('home'))),
    ),
    device: HarborTrialDevice.androidGesture,
  );
  unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => _Page(taps: taps))));
  await tester.pumpAndSettle();
  return tester.state<_PageState>(find.byType(_Page));
}

void main() {
  testWidgets('a tap beside a modal buoy dismisses it instead of reaching the page', (final tester) async {
    final List<String> taps = <String>[];
    final _PageState page = await _pumpPage(tester, taps);
    expect(find.text('menu'), findsOneWidget, reason: 'positive control: the menu is up');

    await tester.tap(find.text('Page action'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, isEmpty, reason: 'the barrier took the tap');
    expect(page.dismissed, 1);
    expect(find.text('menu'), findsNothing);

    await tester.tap(find.text('Page action'));
    expect(taps, <String>['page'], reason: 'positive control: with the menu gone the page answers');
  });

  testWidgets('back dismisses a modal buoy and leaves its page', (final tester) async {
    final _PageState page = await _pumpPage(tester, <String>[]);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(page.dismissed, 1);
    expect(find.text('menu'), findsNothing);
    expect(find.text('Page action'), findsOneWidget, reason: 'the page is still there');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Page action'), findsNothing, reason: 'positive control: back pops the page once the buoy is gone');
  });

  testWidgets('screen readers leave the page alone while a modal buoy is up', (final tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final _PageState page = await _pumpPage(tester, <String>[]);
    expect(find.bySemanticsLabel('Page action'), findsNothing);
    expect(find.bySemanticsLabel('menu'), findsOneWidget, reason: 'the buoy itself is read');

    page.close();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Page action'), findsOneWidget, reason: 'positive control: back with the buoy gone');
    semantics.dispose();
  });

  testWidgets('a modal buoy\'s barrier is announced with its barrierLabel', (final tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          buoys: <HarborBuoy>[
            HarborBuoy(modal: true, onDismiss: () {}, barrierLabel: 'Fermer', child: const SizedBox(width: 100, height: 100)),
          ],
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Fermer'), findsOneWidget);
    expect(find.bySemanticsLabel('Dismiss'), findsNothing);
    semantics.dispose();
  });

  test('a modal buoy without onDismiss is refused', () {
    expect(() => HarborBuoy(modal: true, child: const SizedBox()), throwsAssertionError);
  });
}
