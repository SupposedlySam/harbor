// A modal buoy is modal: a barrier over the page, dismissed by a tap beside it, by back or by
// Escape, and a focus scope that holds the keyboard as a dialog's does. Until 0.2.0 `modal: true`
// only hid the buoys listed before it, and taps and back reached the page; in 0.2.0 focus stayed
// on the page and Escape did nothing. Each test fails on that behaviour, except the one that
// checks Escape is left to the widgets above with no modal buoy up, which fails if the harbor maps
// Escape to a disabled action instead. A buoy's child also keeps its state when the layer around it
// changes shape: it was built again when a buoy turned modal, or a flare came up.

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

Future<_FocusPageState> _pumpFocusPage(
  final WidgetTester tester, {
  final _FocusPage home = const _FocusPage(),
  final Widget Function(Widget page)? around,
}) async {
  await tester.pumpSeaTrial(
    MaterialApp(
      navigatorKey: _navigator,
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: const Harbor(body: Center(child: Text('home'))),
    ),
    device: HarborTrialDevice.androidGesture,
  );
  unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => around?.call(home) ?? home)));
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

/// A button that counts its taps, to see whether a buoy's child keeps its state.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(final BuildContext context) => TextButton(onPressed: () => setState(() => n++), child: Text('n=$n'));
}

/// A speed-dial button that turns modal while it is open, and optionally a modal menu listed before
/// it, so each can change while the other's child has state.
class _SpeedDialPage extends StatefulWidget {
  const _SpeedDialPage();

  @override
  State<_SpeedDialPage> createState() => _SpeedDialPageState();
}

class _SpeedDialPageState extends State<_SpeedDialPage> {
  bool dialOpen = false;
  bool menu = false;

  void update(final VoidCallback change) => setState(change);

  @override
  Widget build(final BuildContext context) => Harbor(
    buoys: <HarborBuoy>[
      if (menu)
        HarborBuoy(
          modal: true,
          onDismiss: () => setState(() => menu = false),
          alignment: Alignment.topCenter,
          child: const Text('menu'),
        ),
      HarborBuoy(
        key: const ValueKey<String>('dial'),
        modal: dialOpen,
        onDismiss: () => setState(() => dialOpen = false),
        child: const _Counter(),
      ),
    ],
    body: const SizedBox.expand(),
  );
}

Future<_SpeedDialPageState> _pumpSpeedDial(final WidgetTester tester) async {
  await tester.pumpSeaTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: const _SpeedDialPage(),
    ),
  );
  await tester.tap(find.text('n=0'));
  await tester.pump();
  expect(find.text('n=1'), findsOneWidget, reason: 'positive control: the child counted the tap');
  return tester.state<_SpeedDialPageState>(find.byType(_SpeedDialPage));
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

    // An Actions inside the page route and above the harbor sees Escape only if the harbor maps
    // nothing for it: a disabled action in the harbor would stop the search there, and the page
    // route alone could not tell, since it ignores Escape too.
    testWidgets('Escape with no modal buoy up reaches the Actions above the harbor', (final tester) async {
      int aboveEscapes = 0;
      final _FocusPageState page = await _pumpFocusPage(
        tester,
        around: (final Widget harbor) => Actions(
          actions: <Type, Action<Intent>>{DismissIntent: CallbackAction<DismissIntent>(onInvoke: (final _) => aboveEscapes++)},
          child: harbor,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(aboveEscapes, 1, reason: 'no modal buoy: Escape is for the widgets above');

      page.open();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'with the menu up, Escape closed it');
      expect(aboveEscapes, 1, reason: 'and did not reach the widgets above');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(aboveEscapes, 2, reason: 'once it closed, Escape is theirs again');
    });

    testWidgets('Escape closes a modal buoy before a sheet with no barrier under it', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      unawaited(showHarborSheet<void>(
        tester.element(find.text('Open menu')),
        barrier: HarborSheetBarrier.none,
        builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 120, child: Text('sheet'))),
      ));
      await tester.pumpAndSettle();
      page.open();
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget, reason: 'positive control: the sheet is up');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'the first Escape closed the menu');
      expect(find.text('sheet'), findsOneWidget, reason: 'and left the sheet');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing, reason: 'the second closed the sheet');
      expect(find.text('Open menu'), findsOneWidget, reason: 'and left the page');
    });

    // A sheet opened over a modal buoy is drawn above it and takes focus. Closing it must hand focus
    // back, so the next Escape reaches the buoy. Failed before: the sheet disposed its focus scope
    // while that scope still held primary focus and was still mounted, so focus stayed on a disposed
    // node and Escape went nowhere.
    testWidgets('a sheet with no barrier opened over a modal buoy gives focus back as it closes', (final tester) async {
      final _FocusPageState page = await _pumpFocusPage(tester);
      page.open();
      await tester.pumpAndSettle();
      unawaited(showHarborSheet<void>(
        tester.element(find.text('Open menu')),
        barrier: HarborSheetBarrier.none,
        requestFocus: true,
        builder: (final BuildContext _) => HarborSheet(
          body: SizedBox(height: 120, child: TextButton(autofocus: true, onPressed: () {}, child: const Text('in the sheet'))),
        ),
      ));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>()?.child, isA<Text>(),
          reason: 'positive control: the sheet took focus');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('in the sheet'), findsNothing, reason: 'the first Escape closed the sheet, the topmost thing');
      expect(page.dismissed, 0, reason: 'and left the menu');
      final FocusNode? focused = FocusManager.instance.primaryFocus;
      expect(focused?.context, isNotNull, reason: 'focus is on a node still in the tree, not the sheet\'s disposed scope');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(page.dismissed, 1, reason: 'the second Escape reached the menu');
    });
  });

  group('a buoy\'s child keeps its state', () {
    testWidgets('when its buoy turns modal and back', (final tester) async {
      final _SpeedDialPageState page = await _pumpSpeedDial(tester);
      page.update(() => page.dialOpen = true);
      await tester.pumpAndSettle();
      expect(find.text('n=1'), findsOneWidget, reason: 'opening the dial kept the count');
      expect(FocusScope.of(tester.element(find.text('n=1'))).hasFocus, isTrue, reason: 'and the dial took focus as it turned modal');

      page.update(() => page.dialOpen = false);
      await tester.pumpAndSettle();
      expect(find.text('n=1'), findsOneWidget, reason: 'closing it kept the count');
    });

    testWidgets('when another buoy turns modal and leaves', (final tester) async {
      final _SpeedDialPageState page = await _pumpSpeedDial(tester);
      page.update(() => page.menu = true);
      await tester.pumpAndSettle();
      expect(find.text('menu'), findsOneWidget, reason: 'positive control: the modal menu is up');
      expect(find.text('n=1'), findsOneWidget, reason: 'a modal buoy coming up kept the count');

      page.update(() => page.menu = false);
      await tester.pumpAndSettle();
      expect(find.text('n=1'), findsOneWidget, reason: 'and its leaving kept it');
    });

    testWidgets('when a flare comes up in its harbor', (final tester) async {
      await _pumpSpeedDial(tester);
      HarborFlares.raise(tester.element(find.text('n=1')), persist: true, builder: (final BuildContext _) => const Text('Copied'));
      await tester.pumpAndSettle();
      expect(find.text('Copied'), findsOneWidget, reason: 'positive control: the flare is up');
      expect(find.text('n=1'), findsOneWidget, reason: 'a flare coming up kept the count');
    });
  });
}
