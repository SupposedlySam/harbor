// HarborPortalBuoy(requestFocus: true) (#66): the buoy takes keyboard focus as it opens, as a sheet
// with no barrier does with requestFocus, and hands it back as it closes. Before #66 a portal buoy
// had no such option: focus stayed where it was, as it does for a MenuAnchor, which is still the
// default and is checked here as the control.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: Material(child: home),
);

/// A row's "Open" button with a portal buoy menu of two items, and a button below it.
Widget _row({
  required final OverlayPortalController menu,
  required final List<String> events,
  required final FocusNode opener,
  final FocusNode? below,
  final bool requestFocus = true,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const SizedBox(height: 100),
    HarborPortalBuoy(
      controller: menu,
      side: HarborBuoySide.end,
      requestFocus: requestFocus,
      onDismiss: () {
        events.add('menu');
        menu.hide();
      },
      buoyBuilder: (final BuildContext context) => SizedBox(
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(onPressed: () {}, child: const Text('Copy')),
            TextButton(onPressed: () {}, child: const Text('Share')),
          ],
        ),
      ),
      child: TextButton(focusNode: opener, onPressed: menu.toggle, child: const Text('Open')),
    ),
    const SizedBox(height: 200),
    TextButton(focusNode: below, onPressed: () {}, child: const Text('Below')),
  ],
);

/// The portal buoy's own focus scope, found from one of its items.
FocusScopeNode _buoyScope(final WidgetTester tester) => FocusScope.of(tester.element(find.text('Copy')));

bool _focusInBuoy(final WidgetTester tester) => _buoyScope(tester).hasFocus;

String _focused() {
  final TextButton? button = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>();
  return button == null ? '-' : (button.child! as Text).data!;
}

void main() {
  late OverlayPortalController menu;
  late FocusNode opener;
  late FocusNode below;
  late List<String> events;

  setUp(() {
    menu = OverlayPortalController();
    opener = FocusNode(debugLabel: 'opener');
    below = FocusNode(debugLabel: 'below');
    events = <String>[];
  });

  tearDown(() {
    opener.dispose();
    below.dispose();
  });

  Future<void> open(final WidgetTester tester) async {
    opener.requestFocus();
    await tester.pump();
    menu.show();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('by default it leaves focus where it was, as a MenuAnchor does', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener, requestFocus: false))));
    await open(tester);
    expect(find.text('Copy'), findsOneWidget, reason: 'positive control: the menu is up');
    expect(opener.hasPrimaryFocus, isTrue);
  });

  testWidgets('with requestFocus it takes focus as it opens, and gives it back as Escape closes it', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener))));
    await open(tester);
    expect(opener.hasFocus, isFalse, reason: 'focus left the opener');
    expect(_focusInBuoy(tester), isTrue, reason: 'focus moved into the menu');
    expect(_buoyScope(tester).debugLabel, 'HarborPortalBuoy');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(), 'Copy', reason: 'Tab starts at the menu\'s first item');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(events, <String>['menu'], reason: 'Escape from inside the menu reached onDismiss (#15)');
    expect(find.text('Copy'), findsNothing);
    expect(opener.hasPrimaryFocus, isTrue, reason: 'focus went back to the opener');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab past its last item does what it does at a route\'s edge, not going round inside it', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener, below: below))));
    await open(tester);
    final NavigatorState navigator = Navigator.of(tester.element(find.text('Copy')));
    expect(_buoyScope(tester).traversalEdgeBehavior, navigator.widget.routeTraversalEdgeBehavior);
    expect(_buoyScope(tester).traversalEdgeBehavior, isNot(TraversalEdgeBehavior.closedLoop));

    final List<String> reached = <String>[];
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      reached.add(_focused());
    }
    expect(reached.take(2), <String>['Copy', 'Share']);
    expect(reached.last, isNot(isIn(<String>['Copy', 'Share'])), reason: 'Tab left the menu after its last item: $reached');
    expect(_focusInBuoy(tester), isFalse);
  });

  testWidgets('it leaves focus alone as it closes once focus has moved out of it', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener, below: below))));
    await open(tester);
    expect(_focusInBuoy(tester), isTrue, reason: 'positive control: the menu took focus');
    below.requestFocus();
    await tester.pump();
    menu.hide();
    await tester.pump();
    expect(below.hasPrimaryFocus, isTrue, reason: 'closing the menu did not take focus from the page');
  });

  testWidgets('its scope is disposed after it closes, and a new one is made when it opens again', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener))));
    await open(tester);
    final FocusScopeNode first = _buoyScope(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(() => ChangeNotifier.debugAssertNotDisposed(first), throwsFlutterError, reason: 'the closed menu\'s scope was disposed');

    await open(tester);
    expect(_buoyScope(tester), isNot(same(first)));
    expect(_focusInBuoy(tester), isTrue, reason: 'it takes focus again');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(events, <String>['menu', 'menu']);
    expect(opener.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back closes it and gives focus back, before back reaches the page', (final tester) async {
    await tester.pumpSeaTrial(_app(Harbor(body: _row(menu: menu, events: events, opener: opener))));
    await open(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(events, <String>['menu']);
    expect(opener.hasPrimaryFocus, isTrue);
  });

  group('in a modal buoy', () {
    Widget modalPage() => StatefulBuilder(
      builder: (final BuildContext context, final StateSetter setState) => Harbor(
        buoys: <HarborBuoy>[
          if (!events.contains('modal'))
            HarborBuoy(
              modal: true,
              onDismiss: () => setState(() => events.add('modal')),
              child: Material(child: _row(menu: menu, events: events, opener: opener)),
            ),
        ],
        body: const SizedBox.expand(),
      ),
    );

    testWidgets('Escape from inside it closes it before the modal buoy (#23)', (final tester) async {
      await tester.pumpSeaTrial(_app(modalPage()));
      await tester.pump();
      await open(tester);
      expect(_buoyScope(tester).debugLabel, 'HarborPortalBuoy');
      expect(_focusInBuoy(tester), isTrue, reason: 'positive control: the menu took focus from the modal buoy');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(events, <String>['menu'], reason: 'the first Escape closed the menu alone');
      expect(find.text('Open'), findsOneWidget, reason: 'the modal buoy is still up');
      // The portal buoy lets go of Escape the frame after it has gone, as it always has.
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(events, <String>['menu', 'modal'], reason: 'the next Escape reached the modal buoy');
    });

    testWidgets("it gives focus back to the modal buoy's scope", (final tester) async {
      await tester.pumpSeaTrial(_app(modalPage()));
      await tester.pump();
      final FocusScopeNode modal = FocusScope.of(tester.element(find.text('Open')));
      await open(tester);
      expect(_buoyScope(tester).parent, same(modal), reason: "the menu's scope is in the modal buoy's");

      menu.hide();
      await tester.pump();
      expect(opener.hasPrimaryFocus, isTrue, reason: 'focus went back to the opener in the modal buoy');
      expect(modal.hasFocus, isTrue);
    });
  });

  test('a portal buoy that takes focus must be one Escape can close', () {
    expect(
      () => HarborPortalBuoy(
        controller: OverlayPortalController(),
        requestFocus: true,
        buoyBuilder: (final BuildContext _) => const SizedBox(),
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });
}
