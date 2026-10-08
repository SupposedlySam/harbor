import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor/testing.dart';

Widget _bar(final String label, final double height) => SizedBox(
  key: ValueKey<String>(label),
  height: height,
  width: double.infinity,
  child: Text(label),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

class _Observer extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(final Route<dynamic> route, final Route<dynamic>? previousRoute) => pushed.add(route);
}

/// Pumps a page in a harbor and returns its context, to open sheets from.
Future<BuildContext> _page(
  final WidgetTester tester, {
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
  final ThemeData? theme,
  final List<NavigatorObserver> observers = const <NavigatorObserver>[],
}) async {
  late BuildContext pageContext;
  await tester.pumpSeaTrial(
    MaterialApp(
      theme: theme,
      navigatorObservers: observers,
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Material(
        child: Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return const SizedBox.expand(key: ValueKey<String>('page'));
            },
          ),
        ),
      ),
    ),
    device: device,
  );
  return pageContext;
}

void main() {
  testWidgets('a sheet route carries its settings to navigator observers', (final tester) async {
    final _Observer observer = _Observer();
    final BuildContext page = await _page(tester, observers: <NavigatorObserver>[observer]);
    unawaited(showHarborSheet<void>(
      page,
      routeSettings: const RouteSettings(name: 'share', arguments: 7),
      builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 200)),
    ));
    await tester.pumpAndSettle();
    expect(observer.pushed.last.settings.name, 'share');
    expect(observer.pushed.last.settings.arguments, 7);
  });

  testWidgets('a sheet barrier reads the Material dismiss label, or the one given', (final tester) async {
    final BuildContext page = await _page(tester);
    late BuildContext sheet;
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) {
        sheet = context;
        return const HarborSheet(body: SizedBox(height: 200));
      },
    ));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(sheet)!.barrierLabel, const DefaultMaterialLocalizations().modalBarrierDismissLabel);
    closeHarborSheet(sheet);
    await tester.pumpAndSettle();

    unawaited(showHarborSheet<void>(
      page,
      barrierLabel: 'Close the share sheet',
      builder: (final BuildContext context) {
        sheet = context;
        return const HarborSheet(body: SizedBox(height: 200));
      },
    ));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(sheet)!.barrierLabel, 'Close the share sheet');
  });

  testWidgets('a sheet barrier has a label without Material localizations', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        pageRouteBuilder: <T>(final RouteSettings settings, final WidgetBuilder builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (final BuildContext context, final Animation<double> a, final Animation<double> b) => builder(context),
        ),
        home: Builder(
          builder: (final BuildContext context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    late BuildContext sheet;
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) {
        sheet = context;
        return const HarborSheet(body: SizedBox(height: 200));
      },
    ));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(sheet)!.barrierLabel, 'Close sheet');
  });

  testWidgets('a sheet spans the screen by default, however wide', (final tester) async {
    final BuildContext page = await _page(tester, device: HarborTrialDevice.television);
    unawaited(showHarborSheet<void>(page, builder: (final BuildContext context) => HarborSheet(body: _bar('content', 200))));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'content').width, 1920);
  });

  testWidgets('a sheet takes its width from the bottom sheet theme when asked', (final tester) async {
    final BuildContext page = await _page(tester, device: HarborTrialDevice.television);
    unawaited(showHarborSheet<void>(
      page,
      maxWidthFromTheme: true,
      builder: (final BuildContext context) => HarborSheet(body: _bar('content', 200)),
    ));
    await tester.pumpAndSettle();
    // Material 3's cap, as showModalBottomSheet has it, centered.
    expect(_rect(tester, 'content').width, 640);
    expect(_rect(tester, 'content').center.dx, 960);
  });

  testWidgets('a themed sheet width follows BottomSheetThemeData.constraints, and maxWidth beats both', (final tester) async {
    final BuildContext page = await _page(
      tester,
      device: HarborTrialDevice.television,
      theme: ThemeData(bottomSheetTheme: const BottomSheetThemeData(constraints: BoxConstraints(maxWidth: 480))),
    );
    late BuildContext sheet;
    unawaited(showHarborSheet<void>(
      page,
      maxWidthFromTheme: true,
      builder: (final BuildContext context) {
        sheet = context;
        return HarborSheet(body: _bar('content', 200));
      },
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'content').width, 480);
    closeHarborSheet(sheet);
    await tester.pumpAndSettle();

    unawaited(showHarborSheet<void>(
      page,
      maxWidth: 720,
      maxWidthFromTheme: true,
      builder: (final BuildContext context) => HarborSheet(body: _bar('content', 200)),
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'content').width, 720);
  });

  testWidgets('a sheet with a Material parent hosts a text field and keeps the page text style', (final tester) async {
    final BuildContext page = await _page(tester);
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => DefaultTextStyle(
        style: const TextStyle(fontSize: 21, color: Colors.teal),
        child: HarborSheet(
          material: true,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const TextField(key: ValueKey<String>('field')),
              InkWell(onTap: () {}, child: const Text('reply', key: ValueKey<String>('reply'))),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const ValueKey<String>('field')), 'hello');
    expect(find.text('hello'), findsOneWidget);
    final BuildContext reply = tester.element(find.byKey(const ValueKey<String>('reply')));
    expect(DefaultTextStyle.of(reply).style.fontSize, 21);
    expect(DefaultTextStyle.of(reply).style.color, Colors.teal);
  });

  testWidgets('a clipped sheet cuts an edge-to-edge body to its corners', (final tester) async {
    final BuildContext page = await _page(tester);
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet(
        clip: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        body: _bar('bleed', 200),
      ),
    ));
    await tester.pumpAndSettle();
    final Rect bleed = _rect(tester, 'bleed');
    bool hits(final Offset point) => tester
        .hitTestOnBinding(point)
        .path
        .any((final HitTestEntry entry) => entry.target == tester.renderObject(find.byKey(const ValueKey<String>('bleed'))));
    expect(hits(bleed.center), isTrue);
    expect(hits(bleed.topLeft + const Offset(2, 2)), isFalse);
    expect(hits(bleed.topRight + const Offset(-2, 2)), isFalse);
    expect(hits(bleed.bottomLeft + const Offset(2, -2)), isTrue);
  });

  testWidgets('a content-sized sheet follows the finger down and springs back when let go early', (final tester) async {
    final BuildContext page = await _page(tester);
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet(dragToClose: true, body: _bar('content', 300)),
    ));
    await tester.pumpAndSettle();
    final Rect rest = _rect(tester, 'content');
    final TestGesture gesture = await tester.startGesture(rest.center);
    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(_rect(tester, 'content').top, closeTo(rest.top + 100, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_rect(tester, 'content'), rest);
  });

  testWidgets('a content-sized sheet closes when flung or dragged past half way', (final tester) async {
    final BuildContext page = await _page(tester);
    bool closed = false;
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet(dragToClose: true, body: _bar('content', 300)),
    ).then((final void _) => closed = true));
    await tester.pumpAndSettle();
    await tester.fling(find.byKey(const ValueKey<String>('content')), const Offset(0, 120), 2000);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(find.byKey(const ValueKey<String>('content')), findsNothing);

    closed = false;
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet(dragToClose: true, body: _bar('content', 300)),
    ).then((final void _) => closed = true));
    await tester.pumpAndSettle();
    await tester.timedDrag(find.byKey(const ValueKey<String>('content')), const Offset(0, 220), const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('a draggable sheet snaps to the sizes it is given', (final tester) async {
    final BuildContext page = await _page(tester);
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet.draggable(
        extent: const HarborSheetExtent(snapSizes: <double>[0.3, 0.5, 0.7]),
        header: _bar('handle', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    const double available = 874.0 - 62.0;
    expect(_rect(tester, 'handle').top, closeTo(874 - available * 0.5, 2));
    // To about 0.72: the nearest snap is 0.7, not the ceiling.
    await tester.drag(find.byKey(const ValueKey<String>('handle')), const Offset(0, -available * 0.22));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'handle').top, closeTo(874 - available * 0.7, 2));
    // A fling down goes to the next size down.
    await tester.fling(find.byKey(const ValueKey<String>('handle')), const Offset(0, 60), 800);
    await tester.pumpAndSettle();
    expect(_rect(tester, 'handle').top, closeTo(874 - available * 0.5, 2));
  });

  testWidgets('a draggable sheet in a route of its own closes that route when flung down', (final tester) async {
    final BuildContext page = await _page(tester);
    bool closed = false;
    unawaited(showGeneralDialog<void>(
      context: page,
      pageBuilder: (final BuildContext context, final Animation<double> a, final Animation<double> b) => HarborSheet.draggable(
        header: _bar('handle', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ).then((final void _) => closed = true));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('handle')), findsOneWidget);
    await tester.fling(find.byKey(const ValueKey<String>('handle')), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(find.byKey(const ValueKey<String>('handle')), findsNothing);
    expect(find.byKey(const ValueKey<String>('page')), findsOneWidget);
  });
}
