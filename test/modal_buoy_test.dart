// A modal buoy is modal: a barrier over the page, dismissed by a tap beside it, by back or by
// Escape, and a focus scope that holds the keyboard as a dialog's does. Until 0.2.0 `modal: true`
// only hid the buoys listed before it, and taps and back reached the page; in 0.2.0 focus stayed
// on the page and Escape did nothing. Each test fails on that behaviour, except the one that
// checks Escape is left alone with no modal buoy up.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// A page with a button that opens a modal menu of two buttons, as a list row's menu does.
class _FocusPage extends StatefulWidget {
  const _FocusPage({this.requestFocus = true, this.autofocusShare = false});

  final bool requestFocus;
  final bool autofocusShare;

  @override
  State<_FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<_FocusPage> {
  final FocusNode opener = FocusNode(debugLabel: 'opener');
  bool menu = false;
  int dismissed = 0;

  void open() => setState(() => menu = true);

  @override
  void dispose() {
    opener.dispose();
    super.dispose();
  }

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
          requestFocus: widget.requestFocus,
          alignment: Alignment.center,
          child: Column(
            key: const ValueKey<String>('menu'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextButton(onPressed: () {}, child: const Text('Copy')),
              TextButton(autofocus: widget.autofocusShare, onPressed: () {}, child: const Text('Share')),
            ],
          ),
        ),
    ],
    body: Column(
      children: <Widget>[
        TextButton(focusNode: opener, onPressed: open, child: const Text('Open menu')),
        TextButton(onPressed: () {}, child: const Text('Other page action')),
      ],
    ),
  );
}

Future<_FocusPageState> _pumpFocusPage(final WidgetTester tester, {final _FocusPage home = const _FocusPage()}) async {
  await tester.pumpSeaTrial(
    MaterialApp(
      navigatorKey: _navigator,
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: const Harbor(body: Center(child: Text('home'))),
    ),
    device: HarborTrialDevice.androidGesture,
  );
  unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => home)));
  await tester.pumpAndSettle();
  final _FocusPageState page = tester.state<_FocusPageState>(find.byType(_FocusPage));
  page.opener.requestFocus();
  await tester.pump();
  return page;
}

/// Whether the primary focus is the menu's nearest focus scope, as a dialog's scope has it on
/// open, or something inside the menu.
bool _focusIsInMenu(final WidgetTester tester) {
  final FocusNode? focused = FocusManager.instance.primaryFocus;
  final Element menu = tester.element(find.byKey(const ValueKey<String>('menu')));
  if (focused == null || identical(focused, FocusScope.of(menu))) {
    return focused != null;
  }
  bool inside = false;
  focused.context?.visitAncestorElements((final Element e) {
    inside = identical(e, menu);
    return !inside;
  });
  return inside;
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

  test('a modal buoy without onDismiss is refused', () {
    expect(() => HarborBuoy(modal: true, child: const SizedBox()), throwsAssertionError);
  });

  group('a modal buoy is modal for the keyboard', () {
    testWidgets('it takes focus when it opens, keeps Tab and arrows inside, and gives focus back', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      expect(page.opener.hasPrimaryFocus, isTrue, reason: 'positive control: the opener has focus');

      page.open();
      await tester.pumpAndSettle();
      expect(page.opener.hasFocus, isFalse, reason: 'focus left the opener');
      expect(_focusIsInMenu(tester), isTrue, reason: 'focus moved into the menu, as it moves into a dialog');

      final List<String> reached = <String>[];
      for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
      ]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
        final TextButton? button = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>();
        reached.add(button == null ? '-' : (button.child! as Text).data!);
      }
      expect(reached, everyElement(isIn(<String>['Copy', 'Share'])), reason: 'traversal stays in the menu: $reached');
      expect(reached.toSet(), <String>{'Copy', 'Share'}, reason: 'and reaches both of its items');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'Escape called onDismiss');
      expect(find.text('Copy'), findsNothing);
      expect(page.opener.hasPrimaryFocus, isTrue, reason: 'focus went back to the opener');
      expect(find.text('Open menu'), findsOneWidget, reason: 'Escape closed the menu, not the page');
    });

    testWidgets('Escape from the page dismisses it when it leaves focus where it was', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      page.open();
      await tester.pumpAndSettle();
      page.opener.requestFocus();
      await tester.pump();
      expect(page.opener.hasPrimaryFocus, isTrue, reason: 'positive control: focus is on the page');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Open menu'), findsOneWidget, reason: 'the page is still there');
    });

    testWidgets('a tap beside it gives focus back too', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      page.open();
      await tester.pumpAndSettle();
      expect(page.opener.hasFocus, isFalse, reason: 'positive control: the menu took focus');

      await tester.tapAt(const Offset(4, 400));
      await tester.pumpAndSettle();
      expect(page.dismissed, 1);
      expect(page.opener.hasPrimaryFocus, isTrue);
    });

    testWidgets('a child with autofocus takes focus when it opens', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester, home: const _FocusPage(autofocusShare: true));
      page.open();
      await tester.pumpAndSettle();
      final TextButton? focused = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>();
      expect((focused?.child as Text?)?.data, 'Share');
    });

    testWidgets('requestFocus: false leaves focus where it was', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester, home: const _FocusPage(requestFocus: false));
      page.open();
      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsOneWidget, reason: 'positive control: the menu is up');
      expect(page.opener.hasPrimaryFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'Escape from the page still dismisses it');
    });

    testWidgets('Escape with no modal buoy up is left to the widgets above', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 0);
      expect(find.text('Open menu'), findsOneWidget, reason: 'a page route is not dismissed by Escape');
      expect(page.opener.hasPrimaryFocus, isTrue);
    });
  });
}
