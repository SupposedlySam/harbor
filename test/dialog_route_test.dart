// A harbor dialog is a dialog route, as one from showDialog or showGeneralDialog is: a popup
// route, with their route settings, barrier, focus and animation options.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

class _Observer extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(final Route<dynamic> route, final Route<dynamic>? previousRoute) => pushed.add(route);
}

class _PageAware extends StatefulWidget {
  const _PageAware({super.key, required this.observer, required this.child});

  final RouteObserver<PageRoute<dynamic>> observer;
  final Widget child;

  @override
  State<_PageAware> createState() => _PageAwareState();
}

class _PageAwareState extends State<_PageAware> with RouteAware {
  int coveredByPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.observer.subscribe(this, ModalRoute.of(context)! as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    widget.observer.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() => coveredByPage++;

  @override
  Widget build(final BuildContext context) => widget.child;
}

/// Pumps a page in a harbor and returns its context, to open dialogs from.
Future<BuildContext> _page(
  final WidgetTester tester, {
  final List<NavigatorObserver> observers = const <NavigatorObserver>[],
  final Widget Function(Widget page)? wrap,
}) async {
  late BuildContext pageContext;
  final Widget page = Harbor(
    body: Builder(
      builder: (final BuildContext context) {
        pageContext = context;
        return Center(child: TextButton(onPressed: () {}, child: const Text('Page action')));
      },
    ),
  );
  await tester.pumpSeaTrial(
    MaterialApp(
      navigatorObservers: observers,
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Material(child: wrap?.call(page) ?? page),
    ),
  );
  return pageContext;
}

/// Opens a dialog with two buttons and returns its builder's context.
Future<BuildContext> _open(
  final WidgetTester tester,
  final BuildContext page, {
  final RouteSettings? routeSettings,
  final String? barrierLabel,
  final String? semanticLabel,
  final TraversalEdgeBehavior? traversalEdgeBehavior,
  final bool? requestFocus,
  final AnimationStyle? animationStyle,
  final bool settle = true,
}) async {
  late BuildContext dialog;
  unawaited(showHarborDialog<void>(
    page,
    routeSettings: routeSettings,
    barrierLabel: barrierLabel,
    semanticLabel: semanticLabel,
    traversalEdgeBehavior: traversalEdgeBehavior,
    requestFocus: requestFocus,
    animationStyle: animationStyle,
    builder: (final BuildContext context) {
      dialog = context;
      return Center(
        child: Column(
          key: const ValueKey<String>('dialog'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(onPressed: () {}, child: const Text('Keep')),
            TextButton(onPressed: () {}, child: const Text('Delete')),
          ],
        ),
      );
    },
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return dialog;
}

double _opacity(final WidgetTester tester) => tester
    .widget<FadeTransition>(find.ancestor(of: find.byKey(const ValueKey<String>('dialog')), matching: find.byType(FadeTransition)).first)
    .opacity
    .value;

/// The nearest semantics node at or above [node] that has [test].
SemanticsNode? _nearest(final SemanticsNode? node, final bool Function(SemanticsNode node) test) {
  SemanticsNode? candidate = node;
  while (candidate != null && !test(candidate)) {
    candidate = candidate.parent;
  }
  return candidate;
}

void main() {
  testWidgets('a dialog is a popup route, as a dialog from showDialog is', (final tester) async {
    final BuildContext page = await _page(tester);
    final BuildContext dialog = await _open(tester, page);
    expect(ModalRoute.of(dialog), isA<PopupRoute<Object?>>());
    expect(ModalRoute.of(dialog), isNot(isA<PageRoute<Object?>>()));
  });

  testWidgets('a page-route observer does not see a dialog as a page covering its page', (final tester) async {
    final RouteObserver<PageRoute<dynamic>> pages = RouteObserver<PageRoute<dynamic>>();
    final GlobalKey<_PageAwareState> aware = GlobalKey<_PageAwareState>();
    final BuildContext page = await _page(
      tester,
      observers: <NavigatorObserver>[pages],
      wrap: (final Widget page) => _PageAware(key: aware, observer: pages, child: page),
    );
    await _open(tester, page);
    expect(find.text('Delete'), findsOneWidget);
    expect(aware.currentState!.coveredByPage, 0);
  });

  testWidgets('a dialog route carries its settings to navigator observers', (final tester) async {
    final _Observer observer = _Observer();
    final BuildContext page = await _page(tester, observers: <NavigatorObserver>[observer]);
    await _open(tester, page, routeSettings: const RouteSettings(name: 'confirm-delete', arguments: 7));
    expect(observer.pushed.last.settings.name, 'confirm-delete');
    expect(observer.pushed.last.settings.arguments, 7);
  });

  // harbor's core imports no design library, so a Material app passes Material's localized
  // label itself; the default is the English that Material and Cupertino fall back to.
  testWidgets("a dialog barrier is announced with the label given, Material's by the documented recipe", (final tester) async {
    final BuildContext page = await _page(tester);
    BuildContext dialog = await _open(tester, page);
    expect(ModalRoute.of(dialog)!.barrierLabel, 'Dismiss');
    Navigator.of(dialog).pop();
    await tester.pumpAndSettle();

    dialog = await _open(tester, page, barrierLabel: MaterialLocalizations.of(page).modalBarrierDismissLabel);
    expect(ModalRoute.of(dialog)!.barrierLabel, const DefaultMaterialLocalizations().modalBarrierDismissLabel);
  });

  testWidgets("a dialog barrier is showGeneralDialog's black by default, as a sheet's is", (final tester) async {
    final BuildContext page = await _page(tester);
    final BuildContext dialog = await _open(tester, page);
    expect(ModalRoute.of(dialog)!.barrierColor, const Color(0x80000000));
  });

  testWidgets("a dialog's content is a route of its own for screen readers, named by semanticLabel", (final tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final BuildContext page = await _page(tester);
    await _open(tester, page, semanticLabel: 'Delete message');
    final SemanticsNode delete = tester.getSemantics(find.text('Delete'));
    final SemanticsNode? named = _nearest(delete, (final SemanticsNode node) => node.flagsCollection.namesRoute);
    expect(named?.label, 'Delete message');
    final SemanticsNode? scope = _nearest(named, (final SemanticsNode node) => node.flagsCollection.scopesRoute);
    expect(scope, isNotNull);
    // The page's own button is outside the dialog's route scope.
    expect(_nearest(tester.getSemantics(find.text('Page action')), (final SemanticsNode node) => identical(node, scope)), isNull);
    semantics.dispose();
  });

  testWidgets("a dialog's content scopes a route even with no semanticLabel", (final tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final BuildContext page = await _page(tester);
    await _open(tester, page);
    final SemanticsNode delete = tester.getSemantics(find.text('Delete'));
    expect(_nearest(delete, (final SemanticsNode node) => node.flagsCollection.scopesRoute), isNotNull);
    expect(_nearest(delete, (final SemanticsNode node) => node.flagsCollection.namesRoute), isNull);
    semantics.dispose();
  });

  testWidgets('traversalEdgeBehavior: closedLoop keeps Tab inside the dialog', (final tester) async {
    final BuildContext page = await _page(tester);
    final BuildContext dialog = await _open(tester, page, traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);
    expect(FocusScope.of(dialog).traversalEdgeBehavior, TraversalEdgeBehavior.closedLoop);
    final List<String> order = <String>[];
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final Text? label = FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>()?.child as Text?;
      order.add(label?.data ?? '');
    }
    expect(order, <String>['Keep', 'Delete', 'Keep']);
  });

  testWidgets('requestFocus: false leaves focus where it was on the page', (final tester) async {
    final FocusNode field = FocusNode();
    addTearDown(field.dispose);
    final BuildContext page = await _page(tester, wrap: (final Widget page) => Column(
      children: <Widget>[
        EditableText(controller: TextEditingController(), focusNode: field, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF000000)),
        Expanded(child: page),
      ],
    ));
    field.requestFocus();
    await tester.pump();
    await _open(tester, page, requestFocus: false);
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets("animationStyle sets a dialog's fade, and noAnimation opens it at once", (final tester) async {
    final BuildContext page = await _page(tester);
    final BuildContext dialog = await _open(
      tester,
      page,
      animationStyle: const AnimationStyle(duration: Duration(milliseconds: 400), reverseDuration: Duration(milliseconds: 100)),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_opacity(tester), closeTo(0.5, 0.01));
    await tester.pumpAndSettle();
    Navigator.of(dialog).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_opacity(tester), closeTo(0.5, 0.01));
    await tester.pumpAndSettle();

    await _open(tester, page, animationStyle: AnimationStyle.noAnimation, settle: false);
    await tester.pump();
    expect(_opacity(tester), 1.0);
  });

  testWidgets("a Hero on the page does not fly into a dialog, as it does not into showDialog's", (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const Align(
                alignment: Alignment.topLeft,
                child: Hero(tag: 'avatar', child: SizedBox(key: ValueKey<String>('page avatar'), width: 40, height: 40)),
              );
            },
          ),
        ),
      ),
    );
    final Rect resting = tester.getRect(find.byKey(const ValueKey<String>('page avatar')));
    unawaited(showHarborDialog<void>(
      page,
      builder: (final BuildContext _) => const Center(
        child: Hero(tag: 'avatar', child: SizedBox(key: ValueKey<String>('dialog avatar'), width: 200, height: 200)),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    // In a flight both heroes' children are swapped for placeholders and a shuttle crosses between them.
    expect(find.byKey(const ValueKey<String>('page avatar')), findsOneWidget);
    expect(tester.getRect(find.byKey(const ValueKey<String>('page avatar'))), resting);
    expect(tester.getSize(find.byKey(const ValueKey<String>('dialog avatar'))), const Size(200, 200));
    await tester.pumpAndSettle();
  });

  testWidgets('a draggable sheet in a dialog closes the dialog when flung below its floor', (final tester) async {
    final BuildContext page = await _page(tester);
    bool closed = false;
    unawaited(showHarborDialog<void>(
      page,
      builder: (final BuildContext _) => HarborSheet.draggable(
        header: const SizedBox(key: ValueKey<String>('handle'), height: 40, width: double.infinity),
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
    expect(find.text('Page action'), findsOneWidget);
  });
}
