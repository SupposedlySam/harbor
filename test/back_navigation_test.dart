// A sheet with no barrier lives in the navigator's overlay, not in a route of its own, so it has
// to be tied to the page that opened it by hand. Found by the back-navigation audit; each test
// failed on the code before this file existed.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// A page with two buttons in its harbor, as a settings page has, wrapped in [around] if given.
/// Returns a context inside the harbor.
Future<BuildContext> _pushButtonPage(final WidgetTester tester, {final Widget Function(Widget page)? around}) async {
  late BuildContext inside;
  final Widget page = Harbor(
    body: Builder(
      builder: (final BuildContext context) {
        inside = context;
        return Column(
          children: <Widget>[
            TextButton(onPressed: () {}, child: const Text('Wi-Fi')),
            TextButton(onPressed: () {}, child: const Text('Bluetooth')),
            const _Counter(),
          ],
        );
      },
    ),
  );
  unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => around?.call(page) ?? page)));
  await tester.pumpAndSettle();
  return inside;
}

/// Something on the page with state of its own, to see whether it is rebuilt or remounted.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(final BuildContext context) => const SizedBox(height: 8);
}

void _openButtonSheet(final BuildContext context, {final bool? requestFocus}) => unawaited(showHarborSheet<void>(
  context,
  barrier: HarborSheetBarrier.none,
  requestFocus: requestFocus,
  builder: (final BuildContext _) => HarborSheet(
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextButton(onPressed: () {}, child: const Text('Shuffle')),
        TextButton(onPressed: () {}, child: const Text('Repeat')),
      ],
    ),
  ),
));

void _focus(final WidgetTester tester, final String button) => Focus.of(tester.element(find.text(button))).requestFocus();

/// The label of the focused button, or the focused node's label when it is not in one.
String _focused() {
  final FocusNode? node = FocusManager.instance.primaryFocus;
  final TextButton? button = node?.context?.findAncestorWidgetOfExactType<TextButton>();
  return button == null ? '${node?.debugLabel}' : (button.child! as Text).data!;
}

Future<List<String>> _tabs(final WidgetTester tester, final int count) async {
  final List<String> reached = <String>[];
  for (int i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    reached.add(_focused());
  }
  return reached;
}

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

  // Failed before: the sheet came back as the page on top started to leave, painted and tappable
  // over it for the whole pop transition (its entry sits above every page in the overlay).
  testWidgets('a sheet with no barrier waits for the page on top to finish leaving', (final tester) async {
    await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
    _openSheet(await _pushPage(tester));
    await tester.pumpAndSettle();
    unawaited(_navigator.currentState!.push(MaterialPageRoute<void>(builder: (final BuildContext _) => const Harbor(body: Center(child: Text('third'))))));
    await tester.pumpAndSettle();

    _navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('third'), findsOneWidget, reason: 'positive control: the page on top is still leaving');
    expect(find.text('sheet'), findsNothing, reason: 'not painted over the leaving page');
    expect(find.text('sheet').hitTestable(), findsNothing, reason: 'not tappable over the leaving page');

    await tester.pumpAndSettle();
    expect(find.text('third'), findsNothing);
    expect(find.text('sheet').hitTestable(), findsOneWidget, reason: 'back once its page is on top again');
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

  group('a sheet with no barrier and the keyboard', () {
    // Failed before: Escape did nothing; only back closed the sheet.
    testWidgets('Escape in the sheet closes it and leaves its page', (final tester) async {
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      _openButtonSheet(await _pushButtonPage(tester));
      await tester.pumpAndSettle();
      _focus(tester, 'Shuffle');
      await tester.pump();
      expect(_focused(), 'Shuffle', reason: 'positive control: focus is in the sheet');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsNothing);
      expect(find.text('Wi-Fi'), findsOneWidget, reason: 'the page is still there');
    });

    // Failed before: Escape from the page did nothing while its sheet was up.
    testWidgets('Escape from the page closes its sheet first, as back does', (final tester) async {
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      _openButtonSheet(await _pushButtonPage(tester));
      await tester.pumpAndSettle();
      _focus(tester, 'Wi-Fi');
      await tester.pump();
      expect(find.text('Shuffle'), findsOneWidget, reason: 'positive control: the sheet is up');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsNothing);
      expect(find.text('Wi-Fi'), findsOneWidget, reason: 'the page is still there');
      expect(_focused(), 'Wi-Fi', reason: 'focus stayed where it was on the page');
    });

    // Failed before at the second Escape: the sheet stayed up. An action mapped while the sheet is
    // closed, even a disabled one, would stop the search below the page's own Actions and fail the
    // first expectation instead.
    testWidgets('with no sheet up, Escape reaches the Actions above the page', (final tester) async {
      int pageEscapes = 0;
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      final BuildContext inside = await _pushButtonPage(
        tester,
        around: (final Widget page) => Actions(
          actions: <Type, Action<Intent>>{DismissIntent: CallbackAction<DismissIntent>(onInvoke: (final _) => pageEscapes++)},
          child: page,
        ),
      );
      _focus(tester, 'Wi-Fi');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(pageEscapes, 1, reason: 'no sheet: Escape is the page\'s');

      _openButtonSheet(inside);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsNothing, reason: 'with the sheet up, Escape closed it');
      expect(pageEscapes, 1, reason: 'and did not reach the page');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(pageEscapes, 2, reason: 'once it closed, Escape is the page\'s again');
    });

    testWidgets("opening and closing the sheet keeps the page's widgets mounted", (final tester) async {
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      final BuildContext inside = await _pushButtonPage(tester);
      final State<_Counter> before = tester.state(find.byType(_Counter));
      _openButtonSheet(inside);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsOneWidget, reason: 'positive control: the sheet is up');
      _focus(tester, 'Wi-Fi');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsNothing);
      expect(identical(tester.state(find.byType(_Counter)), before), isTrue);
    });

    testWidgets('it leaves focus on the page when it opens, and takes it with requestFocus', (final tester) async {
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      final BuildContext inside = await _pushButtonPage(tester);
      _focus(tester, 'Wi-Fi');
      await tester.pump();
      _openButtonSheet(inside);
      await tester.pumpAndSettle();
      expect(_focused(), 'Wi-Fi', reason: 'as a persistent bottom sheet, it does not take focus');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      _openButtonSheet(inside, requestFocus: true);
      await tester.pumpAndSettle();
      expect(await _tabs(tester, 2), <String>['Shuffle', 'Repeat'], reason: 'focus is in the sheet, so Tab starts there');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Shuffle'), findsNothing);
      expect(_focused(), 'Wi-Fi', reason: 'focus went back to where it was on the page');
    });

    testWidgets('Tab goes through the sheet in order and on to the page, and back', (final tester) async {
      await tester.pumpSeaTrial(_app(), device: HarborTrialDevice.androidGesture);
      _openButtonSheet(await _pushButtonPage(tester));
      await tester.pumpAndSettle();
      _focus(tester, 'Shuffle');
      await tester.pump();
      expect(await _tabs(tester, 4), <String>['Repeat', 'Wi-Fi', 'Bluetooth', 'Shuffle']);
    });

    // Failed before: under a navigator that keeps Tab inside each route, Tab left the sheet for the
    // page and never came back, since the sheet's buttons sat in the navigator's own scope.
    testWidgets("Tab at the sheet's edge does what it does at a route's", (final tester) async {
      await tester.pumpSeaTrial(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (final BuildContext context, final Widget? child) => HarborSea(
            child: Navigator(
              key: _navigator,
              routeTraversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
              onGenerateRoute: (final RouteSettings _) => PageRouteBuilder<void>(
                pageBuilder: (final BuildContext _, final Animation<double> _, final Animation<double> _) =>
                    const Harbor(body: Center(child: Text('home'))),
              ),
            ),
          ),
        ),
        device: HarborTrialDevice.androidGesture,
      );
      _openButtonSheet(await _pushButtonPage(tester, around: (final Widget page) => Material(child: page)));
      await tester.pumpAndSettle();
      _focus(tester, 'Shuffle');
      await tester.pump();
      expect(await _tabs(tester, 3), <String>['Repeat', 'Shuffle', 'Repeat']);
    });
  });
}
