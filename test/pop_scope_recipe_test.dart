// The README's recipe for a page under PopScope(canPop: false) (#62, declined in favour of it).
//
// With canPop false, Navigator.maybePop reports doNotPop before it looks at the page's local
// history, so back never reaches the modal buoy, portal buoy or sheet with no barrier that harbor
// tied to the page: only the app's own handler hears it, as the first test shows. The recipe calls
// Navigator.pop while the route will handle the pop internally, which removes the newest local
// history entry, so back closes them one at a time and only then reaches the app's handler.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// A page under PopScope(canPop: false), with a modal buoy, a portal buoy and a sheet with no
/// barrier to open. Its back() stands for the app's own handler (a tab bar going back a tab).
class _Page extends StatefulWidget {
  const _Page({super.key, required this.recipe, required this.events});

  final bool recipe;
  final List<String> events;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final OverlayPortalController menu = OverlayPortalController();
  bool actions = false;
  late BuildContext inside;

  void back() => widget.events.add('tabs.back');

  void openActions() => setState(() => actions = true);

  void openSheet() => unawaited(showHarborSheet<void>(
    inside,
    barrier: HarborSheetBarrier.none,
    builder: (final BuildContext _) => const HarborSheet(body: SizedBox(height: 200, child: Text('sheet'))),
  ).then((final void _) => widget.events.add('sheet closed')));

  @override
  Widget build(final BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (final bool didPop, final Object? _) {
      if (didPop) {
        return;
      }
      if (widget.recipe && ModalRoute.of(context)!.willHandlePopInternally) {
        Navigator.of(context).pop(); // closes the top buoy, portal buoy or barrier-less sheet
        return;
      }
      back();
    },
    child: Harbor(
      buoys: <HarborBuoy>[
        if (actions)
          HarborBuoy(
            modal: true,
            requestFocus: false,
            onDismiss: () => setState(() {
              actions = false;
              widget.events.add('actions closed');
            }),
            child: const Text('actions'),
          ),
      ],
      body: Builder(
        builder: (final BuildContext context) {
          inside = context;
          return Center(
            child: HarborPortalBuoy(
              controller: menu,
              onDismiss: () {
                menu.hide();
                widget.events.add('menu closed');
              },
              buoyBuilder: (final BuildContext _) => const Text('menu'),
              child: const Text('row'),
            ),
          );
        },
      ),
    ),
  );
}

Future<_PageState> _pumpAndOpenAll(final WidgetTester tester, {required final bool recipe, required final List<String> events}) async {
  final GlobalKey<_PageState> page = GlobalKey<_PageState>();
  await tester.pumpSeaTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Material(child: _Page(key: page, recipe: recipe, events: events)),
    ),
  );
  final _PageState state = page.currentState!;
  // Opened one after another, each settling before the next, so each is newer than the last.
  state.openActions();
  await tester.pumpAndSettle();
  state.menu.show();
  await tester.pumpAndSettle();
  state.openSheet();
  await tester.pumpAndSettle();
  expect(find.text('actions'), findsOneWidget, reason: 'positive control: the modal buoy is up');
  expect(find.text('menu'), findsOneWidget, reason: 'positive control: the portal buoy is up');
  expect(find.text('sheet'), findsOneWidget, reason: 'positive control: the sheet is up');
  return state;
}

Future<void> _back(final WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without the recipe, back under PopScope(canPop: false) reaches only the app\'s handler', (final tester) async {
    final List<String> events = <String>[];
    await _pumpAndOpenAll(tester, recipe: false, events: events);
    await _back(tester);
    expect(events, <String>['tabs.back'], reason: 'the premise of #62: nothing harbor tied to the page closed');
    expect(find.text('sheet'), findsOneWidget);
    expect(find.text('menu'), findsOneWidget);
    expect(find.text('actions'), findsOneWidget);
  });

  testWidgets('with the recipe, back closes the sheet, the portal buoy and the modal buoy one at a time, then reaches the app', (final tester) async {
    final List<String> events = <String>[];
    await _pumpAndOpenAll(tester, recipe: true, events: events);

    await _back(tester);
    expect(events, <String>['sheet closed']);
    expect(find.text('menu'), findsOneWidget, reason: 'one back press closes one thing');

    await _back(tester);
    expect(events, <String>['sheet closed', 'menu closed']);
    expect(find.text('actions'), findsOneWidget);

    await _back(tester);
    expect(events, <String>['sheet closed', 'menu closed', 'actions closed']);

    await _back(tester);
    expect(events, <String>['sheet closed', 'menu closed', 'actions closed', 'tabs.back'], reason: 'only now is back the app\'s');
    expect(find.text('row'), findsOneWidget, reason: 'and the page is still there');
  });
}
