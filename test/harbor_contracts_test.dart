// Promises the README makes that nothing in either suite held.
//
// Each test here was written against a mutant: a one-line change to lib/ that broke the promise
// and left all 68 package tests and all 351 example tests green. The comment on each test names
// the change it must fail on. If you weaken one of these tests, re-apply that change and check
// the test still goes red. A test that passes with the code broken is decoration.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _statusBar = 62; // iPhone17's top coast.
const double _screen = 874; // iPhone17's height.

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Widget _app(final Widget home, {final HarborSystemEdges coast = HarborSystemEdges.ambient}) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborRoot(systemEdges: coast, child: child!),
  home: Material(child: home),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

/// Captures the [BuildContext] it is built in.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild, {this.child = const SizedBox.expand()});

  final void Function(BuildContext context) onBuild;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    onBuild(context);
    return child;
  }
}

/// A layer that keeps its child clear of the coast at the top and bottom and casts off the coast
/// alone ([docks] false), so what is beneath still keeps clear of the docks.
class _CoastMargin extends StatelessWidget {
  const _CoastMargin({required this.child, this.docks = false, this.tide = false});

  final bool docks;
  final bool tide;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final EdgeInsetsDirectional coast = HarborRoom.of(context, aspect: HarborRoomAspect.systemEdges).systemEdges;
    return Padding(
      padding: HarborEdges.keep(coast, HarborEdge.vertical),
      child: HarborHandled(edges: HarborEdge.vertical, bars: docks, keyboard: tide, child: child),
    );
  }
}

/// Reads only the coast, through the raw waters, so nothing but the coast aspect can rebuild it.
class _CoastReader extends StatelessWidget {
  const _CoastReader(this.seen);

  final List<double> seen;

  @override
  Widget build(final BuildContext context) {
    seen.add(HarborRoom.maybeRawOf(context, aspect: HarborRoomAspect.systemEdges)!.systemEdges.top);
    return const SizedBox.expand();
  }
}

/// Reads one aspect of the waters through [HarborRoom.of].
class _AspectReader extends StatelessWidget {
  const _AspectReader(this.aspect);

  final HarborRoomAspect aspect;

  @override
  Widget build(final BuildContext context) {
    HarborRoom.of(context, aspect: aspect);
    return const SizedBox(height: 10);
  }
}

/// Records the tide each time it is rebuilt.
class _TideReader extends StatelessWidget {
  const _TideReader(this.seen);

  final List<HarborKeyboardState> seen;

  @override
  Widget build(final BuildContext context) {
    seen.add(HarborKeyboard.of(context));
    return const SizedBox.expand();
  }
}

void main() {
  group('Claims', () {
    // Breaks if: releasing one claim releases every claim on the edge.
    testWidgets('are counted: the dock comes back only when every claim is released', (final tester) async {
      late BuildContext body;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: _Probe((final BuildContext c) => body = c),
          ),
        ),
      );
      final HarborController harbor = HarborController.of(body);
      final HarborClaim first = harbor.hideBar(HarborEdge.top);
      final HarborClaim second = harbor.hideBar(HarborEdge.top);
      expect(harbor.claimedStateOf(HarborEdge.top), HarborBarState.withdrawn);

      first.release();
      await tester.pumpAndSettle();
      expect(harbor.claimedStateOf(HarborEdge.top), HarborBarState.withdrawn, reason: 'one claim is still held');
      expect(first.isActive, isFalse);
      expect(second.isActive, isTrue);

      second.release();
      await tester.pumpAndSettle();
      expect(harbor.claimedStateOf(HarborEdge.top), isNull);
    });

    // Breaks if: a claim stays on the harbor that asked, rather than the nearest one with a dock
    // on that edge.
    testWidgets('go to the nearest harbor outward that has a dock on the edge', (final tester) async {
      late BuildContext inner;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: HarborClear(
              child: HarborFrame(debugLabel: 'component', body: _Probe((final BuildContext c) => inner = c)),
            ),
          ),
        ),
      );
      final double open = _rect(tester, 'header').height;
      expect(open, greaterThan(0));

      final HarborClaim claim = HarborController.of(inner).hideBar(HarborEdge.top);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('header')).hitTestable(),
        findsNothing,
        reason: 'the page header withdrew',
      );

      claim.release();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'header').height, open);
    });
  });

  group('The handle', () {
    Future<({BuildContext page, BuildContext component, BuildContext outside})> nested(
      final WidgetTester tester,
    ) async {
      late BuildContext page;
      late BuildContext component;
      late BuildContext outside;
      await tester.pumpHarborTrial(
        Column(
          children: <Widget>[
            _Probe((final BuildContext c) => outside = c, child: const SizedBox(height: 10)),
            Expanded(
              child: _app(
                HarborFrame(
                  debugLabel: 'page',
                  top: <HarborBar>[
                    HarborBar.overlay(
                      debugLabel: 'header',
                      child: _Probe((final BuildContext c) => page = c, child: _bar('header', 50)),
                    ),
                  ],
                  body: HarborClear(
                    child: HarborFrame(debugLabel: 'component', body: _Probe((final BuildContext c) => component = c)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return (page: page, component: component, outside: outside);
    }

    // Breaks if: Harbor.of answers with any harbor but the nearest, as Scaffold.of does with its state.
    testWidgets('Harbor.of and Harbor.maybeOf find the nearest harbor', (final tester) async {
      final (:BuildContext page, :BuildContext component, :BuildContext outside) = await nested(tester);
      expect(HarborFrame.of(component), same(HarborController.of(component)));
      expect(HarborFrame.of(page), same(HarborController.of(page)));
      expect(HarborFrame.of(component), isNot(same(HarborFrame.of(page))));
      expect(HarborFrame.maybeOf(component), same(HarborFrame.of(component)));
      expect(HarborFrame.maybeOf(outside), isNull);
    });

    // Breaks if: the chart of the nearest harbor is not in global coordinates, or is some other
    // harbor's.
    testWidgets('HarborChart.nearest reads the nearest harbor in global coordinates', (final tester) async {
      final (:BuildContext page, :BuildContext component, :BuildContext outside) = await nested(tester);
      final HarborInspectorEntry pageChart = HarborInspector.nearest(page)!;
      expect(pageChart.label, 'page');
      final HarborBarRecord header = pageChart.bars.single;
      expect(header.label, 'header');
      // The dock's ground runs from the top of the screen, 10 below the probe above the app.
      expect(header.rect.top, 10);
      expect(header.rect.bottom, 10 + _statusBar + 50);
      expect(pageChart.room, HarborFrame.of(page).roomInGlobal());

      final HarborInspectorEntry componentChart = HarborInspector.nearest(component)!;
      expect(componentChart.label, 'component');
      expect(componentChart.room.top, header.rect.bottom);
      expect(HarborInspector.nearest(outside), isNull);
    });

    // Breaks if: updatePontoon or removePontoon miss the pontoon its handle stands for.
    testWidgets('a pontoon added by hand is held by a typed handle', (final tester) async {
      late BuildContext body;
      await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => body = c))));
      final HarborController harbor = HarborFrame.of(body);
      final HarborAttachedBarHandle handle = harbor.attachBar(
        HarborEdge.top,
        HarborBar.overlay(debugLabel: 'pontoon', child: _bar('pontoon', 40)),
      );
      await tester.pumpAndSettle();
      expect(handle.edge, HarborEdge.top);
      expect(HarborInspector.nearest(body)!.bars.single.edge, HarborEdge.top);

      harbor.updateAttachedBar(
        handle,
        HarborEdge.bottom,
        HarborBar.solid(debugLabel: 'pontoon', child: _bar('pontoon', 40)),
      );
      await tester.pumpAndSettle();
      expect(handle.edge, HarborEdge.bottom);
      expect(HarborInspector.nearest(body)!.bars.single.edge, HarborEdge.bottom);

      harbor.detachBar(handle);
      await tester.pumpAndSettle();
      expect(HarborInspector.nearest(body)!.bars, isEmpty);
      expect(find.byKey(const ValueKey<String>('pontoon')), findsNothing);
    });
  });

  group('Breakwaters', () {
    Future<HarborController> page(final WidgetTester tester) async {
      late BuildContext body;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: HarborClear(
              child: _Probe(
                (final BuildContext c) => body = c,
                child: const SizedBox.expand(key: ValueKey<String>('content')),
              ),
            ),
          ),
        ),
      );
      return HarborController.of(body);
    }

    // Breaks if: coverage takes the first breakwater rather than the largest.
    testWidgets('keep content clear of the largest of them', (final tester) async {
      final HarborController harbor = await page(tester);
      final ValueNotifier<double> low = ValueNotifier<double>(100);
      final ValueNotifier<double> high = ValueNotifier<double>(300);
      addTearDown(low.dispose);
      addTearDown(high.dispose);
      harbor
        ..addPageCover(low)
        ..addPageCover(high);
      await tester.pumpAndSettle();
      expect(harbor.pageCoverage, 300);
      expect(_rect(tester, 'content').bottom, lessThanOrEqualTo(_screen - 300));
    });

    // Breaks if: removing a breakwater does nothing. (Skipping only the list removal in
    // `_removeBreakwater` is NOT caught, and cannot be: `remove()` nulls the controller first, so
    // coverage already reads zero. That mutant leaks an entry and a listener, which no layout sees.)
    testWidgets('stop covering the page once removed', (final tester) async {
      final HarborController harbor = await page(tester);
      final double before = _rect(tester, 'content').bottom;
      final ValueNotifier<double> cover = ValueNotifier<double>(300);
      addTearDown(cover.dispose);
      final HarborPageCover breakwater = harbor.addPageCover(cover);
      await tester.pumpAndSettle();
      expect(_rect(tester, 'content').bottom, lessThan(before), reason: 'positive control: it covered');

      breakwater.remove();
      await tester.pumpAndSettle();
      expect(harbor.pageCoverage, 0);
      expect(_rect(tester, 'content').bottom, before);
    });
  });

  group('Flares', () {
    // Breaks if: the port on top is any route that is still active, rather than the current one.
    testWidgets('go to the current route even when a background page re-mounts its harbor', (final tester) async {
      final ValueNotifier<int> generation = ValueNotifier<int>(0);
      addTearDown(generation.dispose);
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      late BuildContext top;
      await tester.pumpHarborTrial(
        MaterialApp(
          navigatorKey: navigator,
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: ValueListenableBuilder<int>(
            valueListenable: generation,
            builder: (final BuildContext context, final int g, final Widget? _) =>
                HarborFrame(key: ValueKey<int>(g), debugLabel: 'background', body: const SizedBox.expand()),
          ),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (final BuildContext context) =>
                HarborFrame(debugLabel: 'front', body: _Probe((final BuildContext c) => top = c)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The page underneath rebuilds a fresh harbor, which joins the fleet after the front one.
      generation.value++;
      await tester.pumpAndSettle();

      final HarborController front = HarborController.of(top);
      expect(front.registry.topmost, same(front));
    });

    // Breaks if: an exact alignment is ignored in favour of the slot, or placed anywhere but its
    // point in the clear water, 16 in from its edges, as a buoy at that alignment would be.
    testWidgets('take an exact alignment within the clear water', (final tester) async {
      const Alignment notch = Alignment(0.0, -0.8);
      late BuildContext page;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(HarborFrame(body: _Probe((final BuildContext c) => page = c))),
      );
      HarborToasts.show(
        page,
        placement: const HarborAligned(alignment: notch),
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = trial.roomAround(find.byType(_Probe)).deflate(16);
      expect(_rect(tester, 'toast'), notch.inscribe(const Size(200, 40), water));
    });

    // Breaks if: a directional alignment is resolved where the flare is shown rather than in the
    // reading direction of the page that raised it.
    testWidgets('resolve a directional alignment in the direction of the page that raised it', (final tester) async {
      late BuildContext page;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: Directionality(textDirection: TextDirection.rtl, child: _Probe((final BuildContext c) => page = c)),
          ),
        ),
      );
      HarborToasts.show(
        page,
        placement: const HarborAligned(alignment: AlignmentDirectional.centerEnd),
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = trial.roomAround(find.byType(_Probe)).deflate(16);
      expect(_rect(tester, 'toast'), Alignment.centerLeft.inscribe(const Size(200, 40), water));
    });

    // Breaks if: the overlay a flare falls back to ignores its exact alignment.
    testWidgets('without a harbor, take an exact alignment within the overlay’s padded water', (final tester) async {
      const Alignment notch = Alignment(0.0, -0.8);
      late BuildContext page;
      await tester.pumpHarborTrial(MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))));
      HarborToasts.show(
        page,
        placement: const HarborAligned(alignment: notch),
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = const EdgeInsets.fromLTRB(
        16,
        _statusBar + 16,
        16,
        34 + 16,
      ).deflateRect(Offset.zero & const Size(402, _screen));
      expect(_rect(tester, 'toast'), notch.inscribe(const Size(200, 40), water));
    });

    // Breaks if: a flare with no harbor above it is dropped (it used to assert, and show nothing
    // in release), or the overlay it falls back to ignores the coast or the keyboard.
    testWidgets('without a harbor, go to the nearest overlay, clear of the coast and the keyboard', (
      final tester,
    ) async {
      late BuildContext page;
      final HarborTrial trial = await tester.pumpHarborTrial(
        MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))),
      );
      await trial.showKeyboard();
      final HarborToastEntry low = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final BuildContext c) => _bar('low', 30),
        duration: null,
      );
      final HarborToastEntry top = HarborToasts.show(
        page,
        slot: HarborToastSlot.top,
        builder: (final BuildContext c) => _bar('top', 30),
        duration: null,
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'low').bottom, lessThanOrEqualTo(trial.keyboardTop));
      expect(
        _rect(tester, 'low').bottom,
        greaterThan(trial.keyboardTop - 30 - 16 - 1),
        reason: 'it sits on the keyboard',
      );
      expect(_rect(tester, 'top').top, greaterThanOrEqualTo(_statusBar));

      low.hide();
      top.hide();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('low')), findsNothing);
      expect(find.byKey(const ValueKey<String>('top')), findsNothing);
    });

    // Breaks if: a flare with nowhere to go is dropped without a word, or asserts (which a
    // release build never sees).
    testWidgets('without a harbor or an overlay, report that the flare was not shown', (final tester) async {
      late BuildContext bare;
      await tester.pumpWidget(
        Directionality(textDirection: TextDirection.ltr, child: _Probe((final BuildContext c) => bare = c)),
      );
      final HarborToastEntry entry = HarborToasts.show(bare, builder: (final BuildContext c) => _bar('lost', 30));
      final Object? error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('HarborToasts.show'));
      expect(entry.showing.value, isFalse);
    });

    // Breaks if: a flare's timers outlive the tree. The test framework fails a test that ends
    // with a timer pending, so the check is the end of each test.
    testWidgets('leave no timer pending when the harbor goes away', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => page = c))));
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('afloat', 30));
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('lowering', 30)).hide();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('afloat')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('leave no timer pending when the overlay goes away', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))));
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('afloat', 30));
      await tester.pump();
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('lowering', 30)).hide();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('afloat')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group("A flare's time", () {
    Future<BuildContext> pumpPage(final WidgetTester tester, {final GlobalKey<NavigatorState>? navigator}) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          navigatorKey: navigator,
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: Material(child: HarborFrame(body: _Probe((final BuildContext c) => page = c))),
        ),
      );
      return page;
    }

    // Breaks if: the default is not a SnackBar's 4 s.
    testWidgets('is 4 s by default, as a SnackBar’s is', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborToastEntry entry = HarborToasts.show(page, builder: (final BuildContext c) => _bar('toast', 30));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 3500));
      expect(entry.showing.value, isTrue);
      await tester.pump(const Duration(milliseconds: 600));
      expect(entry.showing.value, isFalse);
    });

    // Breaks if: the time starts when the flare is raised rather than once its entrance has run.
    testWidgets('starts once its entrance has finished', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        animationStyle: const AnimationStyle(duration: Duration(seconds: 1)),
        duration: const Duration(seconds: 1),
        builder: (final BuildContext c) => _bar('toast', 30),
      );
      // Frame by frame, as a device draws them, so the entrance ends when it would.
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(entry.showing.value, isTrue, reason: 'it has been in full view for only 0.5 s');
      for (int i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(entry.showing.value, isFalse);
    });

    // Breaks if: the time runs while another route covers the page the flare is on.
    testWidgets('waits while another route covers its page', (final tester) async {
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      final BuildContext page = await pumpPage(tester, navigator: navigator);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        duration: const Duration(seconds: 1),
        builder: (final BuildContext c) => _bar('toast', 30),
      );
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (final BuildContext c) => const SizedBox.expand()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(entry.showing.value, isTrue, reason: 'nobody could see it');

      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('toast')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(entry.showing.value, isFalse, reason: 'its time ran once the page was back on top');
    });

    // Breaks if: persist is ignored, so a flare with a button times out before a screen reader
    // reaches it, as a SnackBar with an action does not.
    testWidgets('with persist, does not run out', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        persist: true,
        duration: const Duration(seconds: 1),
        builder: (final BuildContext c) => _bar('undo', 30),
      );
      HarborToastClosedReason? reason;
      unawaited(entry.closed.then((final HarborToastClosedReason r) => reason = r));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(entry.showing.value, isTrue);

      entry.hide();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('undo')), findsNothing);
      expect(reason, HarborToastClosedReason.hide);
    });

    // Breaks if: closed completes before the exit has run, or with the wrong reason.
    testWidgets('closes with timeout once its exit has run', (final tester) async {
      final BuildContext page = await pumpPage(tester);
      final HarborToastEntry entry = HarborToasts.show(
        page,
        duration: const Duration(seconds: 1),
        builder: (final BuildContext c) => _bar('toast', 30),
      );
      HarborToastClosedReason? reason;
      unawaited(entry.closed.then((final HarborToastClosedReason r) => reason = r));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(entry.showing.value, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(reason, isNull, reason: 'it is still on its way out');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey<String>('toast')), findsNothing);
      expect(reason, HarborToastClosedReason.timeout);
    });
  });

  group('Flares at the same place', () {
    final Finder first = find.byKey(const ValueKey<String>('first'));
    final Finder second = find.byKey(const ValueKey<String>('second'));

    // Breaks if: two flares at one slot are shown at once, drawn over each other, rather than one
    // after the other as a ScaffoldMessenger shows its snack bars; or the one waiting starts its
    // time before it is shown.
    testWidgets('are shown one at a time, each after the last has left', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => page = c))));
      final HarborToastEntry one = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final BuildContext c) => _bar('first', 30),
        duration: null,
      );
      final HarborToastEntry two = HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final BuildContext c) => _bar('second', 30),
        duration: const Duration(seconds: 1),
      );
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(second, findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(two.showing.value, isTrue, reason: 'its time has not started while it waits');

      one.hide();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(first, findsOneWidget, reason: 'the first runs its exit before the next comes in');
      expect(second, findsNothing);
      await tester.pumpAndSettle();
      expect(first, findsNothing);
      expect(second, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100));
      expect(two.showing.value, isFalse);
      await tester.pumpAndSettle();
    });

    // Breaks if: a flare lowered while it waits is still shown when its turn comes, or its closed
    // future waits for an exit it never had.
    testWidgets('leave the queue at once when lowered while waiting', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => page = c))));
      final HarborToastEntry one = HarborToasts.show(
        page,
        builder: (final BuildContext c) => _bar('first', 30),
        duration: null,
      );
      final HarborToastEntry two = HarborToasts.show(
        page,
        builder: (final BuildContext c) => _bar('second', 30),
        duration: null,
      );
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('third', 30), duration: null);
      HarborToastClosedReason? reason;
      unawaited(two.closed.then((final HarborToastClosedReason r) => reason = r));
      await tester.pumpAndSettle();

      two.hide();
      await tester.pump();
      expect(reason, HarborToastClosedReason.hide);
      one.hide();
      await tester.pumpAndSettle();
      expect(second, findsNothing);
      expect(find.byKey(const ValueKey<String>('third')), findsOneWidget);
    });

    testWidgets('without a harbor, are shown one at a time in the overlay', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))));
      final HarborToastEntry one = HarborToasts.show(
        page,
        builder: (final BuildContext c) => _bar('first', 30),
        duration: null,
      );
      HarborToasts.show(page, builder: (final BuildContext c) => _bar('second', 30), duration: null);
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(second, findsNothing);

      one.hide();
      await tester.pumpAndSettle();
      expect(first, findsNothing);
      expect(second, findsOneWidget);
    });

    // Positive control: the queue is per place, so flares at two slots still show together.
    testWidgets('at two slots, are shown together', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => page = c))));
      HarborToasts.show(
        page,
        slot: HarborToastSlot.top,
        builder: (final BuildContext c) => _bar('first', 30),
        duration: null,
      );
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        builder: (final BuildContext c) => _bar('second', 30),
        duration: null,
      );
      await tester.pumpAndSettle();
      expect(first, findsOneWidget);
      expect(second, findsOneWidget);
    });
  });

  group('The tide', () {
    Future<HarborTrial> page(final WidgetTester tester, final List<HarborKeyboardState> seen) =>
        tester.pumpHarborTrial(_app(HarborFrame(bodyClearsKeyboard: false, body: _TideReader(seen))));

    Future<void> frames(final WidgetTester tester) async {
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Breaks if: high water is no longer kept per orientation.
    testWidgets('keeps a high-water mark per orientation', (final tester) async {
      final List<HarborKeyboardState> seen = <HarborKeyboardState>[];
      final HarborTrial trial = await page(tester, seen);
      await trial.showKeyboard();
      await trial.hideKeyboard();
      expect(seen.last.settledHeight, 336);
      expect(seen.last.settledHeightIsEstimate, isFalse);

      tester.view.physicalSize = const Size(_screen, 402) * tester.view.devicePixelRatio;
      await frames(tester);
      expect(seen.last.settledHeightIsEstimate, isTrue, reason: 'no keyboard has settled in landscape');
      expect(seen.last.settledHeight, isNot(336));
    });

    // Breaks if: high water only ever rises. The example's field guide holds this too; the
    // package owns the concept, so it holds it here.
    testWidgets('lets high water fall when the keyboard settles lower', (final tester) async {
      final List<HarborKeyboardState> seen = <HarborKeyboardState>[];
      final HarborTrial trial = await page(tester, seen);
      await trial.showKeyboard();
      await trial.hideKeyboard();
      expect(seen.last.settledHeight, 336, reason: 'positive control');

      tester.view.viewInsets = FakeViewPadding(bottom: 250 * tester.view.devicePixelRatio);
      await frames(tester);
      expect(seen.last.settledHeight, 250);
    });
  });

  group('The waters', () {
    // Breaks if: the waters stop being clamped to MediaQuery.
    testWidgets('honor a layer outside the harbor that removed padding', (final tester) async {
      late BuildContext inside;
      late BuildContext control;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: Column(
              children: <Widget>[
                Expanded(child: _Probe((final BuildContext c) => control = c)),
                Expanded(
                  child: Builder(
                    builder: (final BuildContext context) => MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: _Probe((final BuildContext c) => inside = c),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(HarborRoom.of(control).systemEdges.top, _statusBar, reason: 'positive control');
      expect(HarborRoom.of(inside).systemEdges.top, 0);
    });

    // Breaks if: casting off an edge keeps that edge's wake.
    testWidgets('cast off an edge\'s wake along with the edge', (final tester) async {
      late BuildContext under;
      late BuildContext castOff;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: <HarborBar>[
              HarborBar.overlay(edgeEffect: const HarborEdgeEffect.fade(length: 12), child: _bar('header', 50)),
            ],
            body: _Probe(
              (final BuildContext c) => under = c,
              child: HarborHandled(
                edges: const <HarborEdge>{HarborEdge.top},
                child: _Probe((final BuildContext c) => castOff = c),
              ),
            ),
          ),
        ),
      );
      expect(HarborRoom.of(under).edgeEffects, contains(HarborEdge.top), reason: 'positive control');
      expect(HarborRoom.of(castOff).edgeEffects, isNot(contains(HarborEdge.top)));
      expect(HarborRoom.of(castOff).edgeEffectOf(HarborEdge.top), HarborFadeBand.none);
    });

    // Breaks if: a reader of the coast aspect is not rebuilt when the coast changes.
    testWidgets('rebuild a coast reader when the coast changes', (final tester) async {
      final ValueNotifier<double> top = ValueNotifier<double>(20);
      addTearDown(top.dispose);
      final List<double> seen = <double>[];
      await tester.pumpHarborTrial(
        MaterialApp(
          home: ValueListenableBuilder<double>(
            valueListenable: top,
            // The reader is const, so nothing but the waters can rebuild it.
            child: HarborFrame(body: _CoastReader(seen)),
            builder: (final BuildContext context, final double t, final Widget? page) => HarborRoot(
              systemEdges: HarborSystemEdges.fixed(EdgeInsetsDirectional.only(top: t)),
              child: page!,
            ),
          ),
        ),
      );
      expect(seen.last, 20);
      top.value = 40;
      await tester.pump();
      expect(seen.last, 40);
    });

    // Breaks if: the CSS insets ignore the docks.
    testWidgets('give a web view the larger of the coast and the docks', (final tester) async {
      late BuildContext body;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: _Probe((final BuildContext c) => body = c),
          ),
        ),
      );
      final Map<String, String> css = HarborRoom.of(body).toCssVariables(TextDirection.ltr);
      expect(css['--harbor-inset-top'], '${_statusBar + 50}px');
    });

    // Breaks if: HarborCastOff(tide: true) keeps the keyboard.
    testWidgets('cast off the tide when asked', (final tester) async {
      late BuildContext under;
      late BuildContext castOff;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: _Probe(
              (final BuildContext c) => under = c,
              child: HarborHandled(
                edges: const <HarborEdge>{},
                keyboard: true,
                child: _Probe((final BuildContext c) => castOff = c),
              ),
            ),
          ),
        ),
      );
      await trial.showKeyboard();
      expect(MediaQuery.viewInsetsOf(under).bottom, greaterThan(0), reason: 'positive control');
      expect(MediaQuery.viewInsetsOf(castOff).bottom, 0);
    });
  });

  group('Casting off the coast alone', () {
    // A frosted header and a frosted tab bar, both piers, so the body runs under them and the
    // fairway is the one that keeps clear.
    Widget page({required final Widget body, final bool bodyClearsTide = true}) => _app(
      HarborFrame(
        bodyClearsKeyboard: bodyClearsTide,
        top: <HarborBar>[
          HarborBar.overlay(edgeEffect: const HarborEdgeEffect.fade(length: 12), child: _bar('header', 50)),
        ],
        bottom: <HarborBar>[HarborBar.overlay(child: _bar('tabs', 60))],
        body: body,
      ),
    );
    Widget rows() => HarborScrollView(
      slivers: <Widget>[
        SliverList.builder(
          itemCount: 30,
          itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50),
        ),
      ],
    );

    // Breaks if: HarborCastOff(docks: false) casts the docks off too, or keeps them as they are
    // measured from the body's edge rather than from the edge of the layer that cleared the coast.
    testWidgets('leaves the docks to a fairway beneath a layer that cleared the coast', (final tester) async {
      await tester.pumpHarborTrial(page(body: _CoastMargin(child: rows())));
      final double headerFace = _rect(tester, 'header').bottom;
      final double tabsFace = _rect(tester, 'tabs').top;
      expect(headerFace, _statusBar + 50, reason: 'positive control: the header absorbed the status bar');
      expect(tabsFace, _screen - 34 - 60, reason: 'positive control: the tab bar absorbed the home indicator');
      expect(_rect(tester, 'row0').top, headerFace + 12, reason: 'the first row rests past the header and its wake');
      await tester.drag(find.byType(Scrollable), const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row29').bottom, tabsFace, reason: 'the last row rests on the tab bar');
    });

    // Breaks if: casting off the docks too is no longer the default.
    testWidgets('by default casts the docks off with the coast', (final tester) async {
      await tester.pumpHarborTrial(page(body: _CoastMargin(docks: true, child: rows())));
      expect(_rect(tester, 'row0').top, _statusBar, reason: 'nothing beneath clears the header any more');
    });

    // Breaks if: MediaQuery beneath does not say what the waters beneath say.
    testWidgets('tells MediaQuery and the waters beneath what is still in the way', (final tester) async {
      late BuildContext under;
      late BuildContext beneath;
      await tester.pumpHarborTrial(
        page(
          body: _Probe(
            (final BuildContext c) => under = c,
            child: _CoastMargin(child: _Probe((final BuildContext c) => beneath = c)),
          ),
        ),
      );
      expect(MediaQuery.paddingOf(under).top, _statusBar + 50 + 12, reason: 'positive control');
      expect(MediaQuery.paddingOf(beneath).top, 50 + 12);
      expect(MediaQuery.paddingOf(beneath).bottom, 60);
      expect(MediaQuery.viewPaddingOf(beneath).top, 50 + 12);
      expect(MediaQuery.viewPaddingOf(beneath).bottom, 60);
      final HarborRoomData waters = HarborRoom.of(beneath);
      expect(waters.systemEdges, EdgeInsetsDirectional.zero);
      expect(waters.bars, const EdgeInsetsDirectional.only(top: 50 + 12, bottom: 60));
      expect(waters.barsResting, const EdgeInsetsDirectional.only(top: 50 + 12, bottom: 60));
      expect(waters.edgeEffectOf(HarborEdge.top), const HarborFadeBand(barFace: 50, fadeEnd: 50 + 12));
      expect(waters.hasBars, containsAll(HarborEdge.vertical));
      final HarborRoomData raw = HarborRoom.maybeRawOf(beneath)!;
      expect(raw.bars, waters.bars, reason: 'measured from the layer, not left for MediaQuery to clamp');
      expect(raw.barsResting, waters.barsResting);
      expect(
        HarborRoom.steadySystemEdgeOf(beneath, HarborEdge.bottom),
        0,
        reason: 'the steady coast went with the coast',
      );
    });

    // Breaks if: tide: stops casting off the keyboard when the docks are kept.
    testWidgets('casts off the tide when asked, and keeps the docks', (final tester) async {
      late BuildContext beneath;
      final HarborTrial trial = await tester.pumpHarborTrial(
        page(
          bodyClearsTide: false,
          body: _CoastMargin(tide: true, child: _Probe((final BuildContext c) => beneath = c)),
        ),
      );
      await trial.showKeyboard();
      expect(MediaQuery.viewInsetsOf(beneath).bottom, 0);
      // The keyboard took the live coast, so the layer pads nothing and the tab bar reaches into it
      // from its own edge.
      final double layerBottom = tester.getRect(find.byType(HarborHandled)).bottom;
      expect(layerBottom, _screen, reason: 'positive control: the body runs under the keyboard');
      expect(MediaQuery.paddingOf(beneath).bottom, layerBottom - _rect(tester, 'tabs').top);
      expect(HarborRoom.of(beneath).bars.bottom, layerBottom - _rect(tester, 'tabs').top);
    });

    // Breaks if: outside any harbor, the docks kept are read from padding that was all coast.
    testWidgets('outside any harbor casts off all of MediaQuery.padding, as it is all coast', (final tester) async {
      late BuildContext beneath;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: HarborHandled(
            edges: HarborEdge.vertical,
            bars: false,
            child: _Probe((final BuildContext c) => beneath = c),
          ),
        ),
      );
      expect(MediaQuery.paddingOf(beneath), EdgeInsets.zero);
      expect(MediaQuery.viewPaddingOf(beneath), EdgeInsets.zero);
      expect(HarborRoom.of(beneath).bars, EdgeInsetsDirectional.zero);
    });

    // Breaks if: a horizontal fairway starts casting off the edges across it. Its items are
    // handed the docks there (a header above a carousel) as they stand, coast included.
    testWidgets('a horizontal fairway hands the docks across it to its items', (final tester) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        page(
          body: HarborScrollView.box(
            scrollDirection: Axis.horizontal,
            child: _Probe((final BuildContext c) => item = c, child: const SizedBox(width: 100)),
          ),
        ),
      );
      expect(MediaQuery.paddingOf(item).top, _statusBar + 50 + 12);
      expect(HarborRoom.of(item).bars.top, _statusBar + 50 + 12);
      expect(HarborRoom.of(item).systemEdges.top, _statusBar);
    });
  });

  group('A reader rebuilds only for what it reads', () {
    // No bottom coast, so the keyboard moving changes viewInsets and nothing else.
    const HarborTrialDevice device = HarborTrialDevice.iPhoneSE;

    // Brings the keyboard in or out over ten frames, as the platform animates it. On a phone that
    // stops reporting its home indicator in padding under the keyboard, the padding goes with it.
    Future<void> slideTide(
      final WidgetTester tester, {
      required final bool tideIn,
      final HarborTrialDevice on = device,
    }) async {
      for (int i = 1; i <= 10; i++) {
        final double share = tideIn ? i / 10 : 1 - i / 10;
        final EdgeInsets coast = on.systemEdgesWhen(keyboardShown: share > 0);
        // The view is in physical pixels, as the platform reports it.
        final double ratio = tester.view.devicePixelRatio;
        tester.view
          ..padding = FakeViewPadding(
            left: coast.left * ratio,
            top: coast.top * ratio,
            right: coast.right * ratio,
            bottom: coast.bottom * ratio,
          )
          ..viewInsets = FakeViewPadding(bottom: on.keyboardHeight * share * ratio);
        await tester.pump(const Duration(milliseconds: 16));
      }
      // Long enough for the tide gauge to settle.
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    /// Counts the rebuilds of every element whose widget's type is in [types].
    Map<Type, int> countRebuilds(final Set<Type> types) {
      final Map<Type, int> counts = <Type, int>{for (final Type t in types) t: 0};
      debugOnRebuildDirtyWidget = (final Element element, final bool builtOnce) {
        final Type type = element.widget.runtimeType;
        if (counts.containsKey(type)) {
          counts[type] = counts[type]! + 1;
        }
      };
      addTearDown(() => debugOnRebuildDirtyWidget = null);
      return counts;
    }

    // Found merging #2 with #5: the steady coast's clamp reads the keyboard, and on a phone with a
    // home indicator it reached that read for every reader of the waters, so a reader of the docks
    // rebuilt through the keyboard's rise again (3 times here, against 1). The iPhone SE above has no
    // bottom coast, so the tests there never reach the clamp. The one rebuild left is the home
    // indicator's padding going to zero, which the docks clamp does read.
    // Breaks if: the steady coast subscribes to the keyboard for readers outside the coast aspect.
    testWidgets('a reader of the docks holds still on a phone with a home indicator too', (final tester) async {
      final Map<Type, int> rebuilds = countRebuilds(<Type>{_AspectReader, _TideReader});
      final List<HarborKeyboardState> tide = <HarborKeyboardState>[];
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: Column(
              children: <Widget>[
                const _AspectReader(HarborRoomAspect.bars),
                SizedBox(height: 10, child: _TideReader(tide)),
              ],
            ),
          ),
        ),
      );
      rebuilds.updateAll((final Type _, final int _) => 0);
      await trial.showKeyboard();
      expect(rebuilds[_TideReader], greaterThan(1), reason: 'positive control: the keyboard moved over several frames');
      expect(rebuilds[_AspectReader], lessThanOrEqualTo(1));
    });

    // Breaks if: HarborWaters.of depends on the whole MediaQuery again, or a content role reads
    // the waters (or MediaQuery) beyond the parts it uses.
    testWidgets('readers of the coast, the docks and the margin hold still while the keyboard moves', (
      final tester,
    ) async {
      final List<double> insetsSeen = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: Column(
              children: <Widget>[
                const _AspectReader(HarborRoomAspect.systemEdges),
                const _AspectReader(HarborRoomAspect.bars),
                const _AspectReader(HarborRoomAspect.margin),
                const _RoomReader(),
                const HarborClear.rowInsets(child: SizedBox(height: 10)),
                const HarborClear(edges: HarborEdge.horizontal, keyboard: false, child: SizedBox(height: 10)),
                const SizedBox(
                  height: 40,
                  child: HarborScrollView(
                    scrollDirection: Axis.horizontal,
                    slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(width: 2000))],
                  ),
                ),
                // The positive control: something that reads the keyboard does see it move.
                _Probe(
                  (final BuildContext c) => insetsSeen.add(MediaQuery.viewInsetsOf(c).bottom),
                  child: const SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{_AspectReader, _RoomReader, HarborClear, HarborScrollView});
      insetsSeen.clear();
      await slideTide(tester, tideIn: true);
      expect(insetsSeen, hasLength(10), reason: 'positive control: the body saw every frame of the keyboard');
      expect(insetsSeen.last, device.keyboardHeight);
      expect(rebuilds, <Type, int>{_AspectReader: 0, _RoomReader: 0, HarborClear: 0, HarborScrollView: 0});
    });

    // A fairway that clears the coast alone casts off the coast and hands its rows the docks, the
    // way `HarborCastOff(docks: false)` does. Neither it nor a row reading the docks has a reason to
    // rebuild while the keyboard moves under a body that does not clear it.
    // Breaks if: the fairway reads the coast, the waters or MediaQuery beyond the aspect it uses.
    testWidgets('a fairway that clears the coast alone holds still while the keyboard moves, and so do its rows', (
      final tester,
    ) async {
      final List<double> insetsSeen = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: Column(
              children: <Widget>[
                const SizedBox(
                  height: 40,
                  child: HarborScrollView(
                    scrollDirection: Axis.horizontal,
                    bars: false,
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: SizedBox(width: 50, child: _AspectReader(HarborRoomAspect.bars))),
                    ],
                  ),
                ),
                _Probe(
                  (final BuildContext c) => insetsSeen.add(MediaQuery.viewInsetsOf(c).bottom),
                  child: const SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborScrollView, _AspectReader});
      insetsSeen.clear();
      await slideTide(tester, tideIn: true);
      expect(insetsSeen, hasLength(10), reason: 'positive control: the body saw every frame of the keyboard');
      expect(rebuilds, <Type, int>{HarborScrollView: 0, _AspectReader: 0});
    });

    // A vertical fairway follows the keyboard only for its bottom end, so one that leaves the
    // keyboard to someone else has nothing to follow.
    // Breaks if: tide: false still reads the keyboard, or the fairway reads MediaQuery as a whole.
    testWidgets('a fairway that leaves the keyboard holds still while it moves', (final tester) async {
      final List<double> insetsSeen = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: Column(
              children: <Widget>[
                const SizedBox(
                  height: 100,
                  child: HarborScrollView(
                    keyboard: false,
                    slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(height: 10))],
                  ),
                ),
                const SizedBox(
                  height: 100,
                  child: HarborScrollView(
                    keyboard: false,
                    bars: false,
                    slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(height: 10))],
                  ),
                ),
                _Probe(
                  (final BuildContext c) => insetsSeen.add(MediaQuery.viewInsetsOf(c).bottom),
                  child: const SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborScrollView});
      insetsSeen.clear();
      await slideTide(tester, tideIn: true);
      expect(insetsSeen, hasLength(10), reason: 'positive control: the body saw every frame of the keyboard');
      expect(rebuilds, <Type, int>{HarborScrollView: 0});
    });

    // A body that clears the tide takes the keyboard out of its view padding, as
    // `MediaQueryData.removeViewInsets` does, so on a phone with a home indicator the steady
    // coast's clamp is reached on every frame the keyboard moves. The iPhone SE above has no
    // bottom coast and never reaches it.
    // Breaks if: HarborWaters.of subscribes coast readers to the steady coast's clamp.
    testWidgets('a coast-only moored block holds still while the keyboard rises over a home indicator', (
      final tester,
    ) async {
      const HarborTrialDevice phone = HarborTrialDevice.iPhone17;
      final List<HarborKeyboardState> tide = <HarborKeyboardState>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: Column(
              children: <Widget>[
                const HarborClear(
                  edges: <HarborEdge>{HarborEdge.top, HarborEdge.start, HarborEdge.end},
                  bars: false,
                  keyboard: false,
                  child: SizedBox(height: 10),
                ),
                const _AspectReader(HarborRoomAspect.systemEdges),
                SizedBox(height: 10, child: _TideReader(tide)),
              ],
            ),
          ),
        ),
        device: phone,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborClear, _AspectReader, _TideReader});
      await slideTide(tester, tideIn: true, on: phone);
      expect(
        rebuilds[_TideReader],
        greaterThanOrEqualTo(10),
        reason: 'positive control: the keyboard moved on every frame',
      );
      // Once each, for the platform taking the home indicator out of the padding.
      expect(rebuilds[HarborClear], 1);
      expect(rebuilds[_AspectReader], 1);
    });

    // The standard is `MediaQuery.viewPaddingOf`: it rebuilds when the view padding changes, and
    // the steady coast should rebuild no more often than that while holding its value.
    // Breaks if: steadyCoastOf depends on the tide gauge, which notifies on every frame.
    testWidgets('the steady coast holds still while the keyboard rises over a home indicator', (final tester) async {
      const HarborTrialDevice phone = HarborTrialDevice.iPhone17;
      final List<double> steady = <double>[];
      final List<double> viewPadding = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            body: Column(
              children: <Widget>[
                _Probe(
                  (final BuildContext c) => steady.add(HarborRoom.steadySystemEdgeOf(c, HarborEdge.bottom)),
                  child: const SizedBox(height: 10),
                ),
                _Probe(
                  (final BuildContext c) => viewPadding.add(MediaQuery.viewPaddingOf(c).bottom),
                  child: const SizedBox(height: 10),
                ),
              ],
            ),
          ),
        ),
        device: phone,
      );
      steady.clear();
      viewPadding.clear();
      await slideTide(tester, tideIn: true, on: phone);
      expect(viewPadding.last, 0, reason: 'positive control: the body took the keyboard out of its view padding');
      expect(steady, everyElement(phone.systemEdges.bottom));
      expect(steady.length, lessThanOrEqualTo(viewPadding.length));
    });

    // Breaks if: isInOf depends on the tide gauge as a whole, which notifies on every frame.
    testWidgets('a reader of whether the tide is in rebuilds exactly when it comes and goes', (final tester) async {
      final List<bool> seen = <bool>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: _Probe((final BuildContext c) => seen.add(HarborKeyboard.isShownOf(c))),
          ),
        ),
        device: device,
      );
      expect(seen, <bool>[false]);
      await slideTide(tester, tideIn: true);
      expect(seen, <bool>[false, true]);
      await slideTide(tester, tideIn: false);
      expect(seen, <bool>[false, true, false]);
    });

    // Breaks if: a dry dock reads the whole tide, which moves on every frame.
    testWidgets('a dry dock rebuilds when the tide comes, goes or sets a new high-water mark', (final tester) async {
      final List<double> heights = <double>[];
      await tester.pumpHarborTrial(
        _app(
          const HarborFrame(
            bottom: <HarborBar>[
              HarborBar.solid(
                keyboard: HarborKeyboardStance.reserves,
                child: HarborKeyboardSpace(child: SizedBox.expand()),
              ),
            ],
            body: SizedBox.expand(),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborKeyboardSpace});
      void recordHeight() => heights.add(tester.getSize(find.byType(HarborKeyboardSpace)).height);
      recordHeight();
      await slideTide(tester, tideIn: true);
      recordHeight();
      // The tide came in (1) and settled at a new high-water mark (2).
      expect(rebuilds[HarborKeyboardSpace], 2);
      await slideTide(tester, tideIn: false);
      recordHeight();
      // It went out (3), and settling at low water left the mark where it was.
      expect(rebuilds[HarborKeyboardSpace], 3);
      expect(heights, <double>[device.size.height * 0.4, device.keyboardHeight, device.keyboardHeight]);
    });
  });

  // The README's Scaffold advice, held. A resizing Scaffold shrinks the harbor before it sees the
  // keyboard, so a tab bar on pilings is lifted instead of covered; with resizing off, the harbor
  // owns the tide. Both halves are asserted, so the advice is checked and so is its reason.
  testWidgets('inside a Scaffold, the harbor owns the tide only once the Scaffold stops resizing', (
    final tester,
  ) async {
    Future<double> tabBarTopUnderKeyboard({required final bool resize}) async {
      final HarborTrial trial = await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: Scaffold(
            resizeToAvoidBottomInset: resize,
            body: HarborFrame(
              bottom: <HarborBar>[HarborBar.solid(child: _bar('tabs', 56))],
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await trial.showKeyboard(settle: true);
      final double top = _rect(tester, 'tabs').top;
      await trial.hideKeyboard(settle: true);
      return top;
    }

    final double resting = _screen - 34 - 56; // above the home indicator
    expect(await tabBarTopUnderKeyboard(resize: false), resting, reason: 'pilings: the keyboard covers it');
    expect(
      await tabBarTopUnderKeyboard(resize: true),
      lessThan(_screen - 336),
      reason: 'the hazard the README warns of',
    );
  });

  group('A dock lays its child out like a Row or Column does', () {
    // Reported by rubric-owner: a NavigationRail in a start quay took the whole 1024-wide frame and
    // left the page 0 wide, silently. A dock offered its child any extent up to the frame's, and a
    // widget that fills what it is given (NavigationRail, AppBar, an empty Container) took all of
    // it. Docks now leave the child unbounded along the edge's depth, as a Row or Column does, so
    // Row- and Column-native widgets size as they do there, and one that truly wants to fill fails
    // loudly instead of eating the page. Breaks if: the dock bounds its child at the frame again.
    const HarborTrialDevice tablet = HarborTrialDevice(
      name: 'tablet',
      size: Size(1024, 1366),
      systemEdges: EdgeInsets.only(top: 24, bottom: 20),
      keyboardHeight: 400,
    );

    Future<void> pump(
      final WidgetTester tester, {
      final List<HarborBar> start = const <HarborBar>[],
      final List<HarborBar> top = const <HarborBar>[],
    }) => tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: Scaffold(
          resizeToAvoidBottomInset: false,
          body: HarborFrame(
            start: start,
            top: top,
            body: const SizedBox.expand(key: ValueKey<String>('body')),
          ),
        ),
      ),
      device: tablet,
    );

    testWidgets('a NavigationRail in a side dock takes its own width', (final tester) async {
      await pump(
        tester,
        start: <HarborBar>[
          HarborBar.solid(
            child: NavigationRail(
              key: const ValueKey<String>('rail'),
              selectedIndex: 0,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(icon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
          ),
        ],
      );
      expect(_rect(tester, 'rail').width, 80);
      expect(_rect(tester, 'body').width, 1024 - 80);
    });

    testWidgets('an AppBar in a top dock takes its own height', (final tester) async {
      await pump(
        tester,
        top: <HarborBar>[
          HarborBar.overlay(
            child: AppBar(key: const ValueKey<String>('bar'), title: const Text('t')),
          ),
        ],
      );
      expect(_rect(tester, 'bar').height, kToolbarHeight);
    });

    testWidgets('a widget with no size of its own takes none', (final tester) async {
      await pump(
        tester,
        start: <HarborBar>[
          HarborBar.solid(
            child: Container(key: const ValueKey<String>('side'), color: Colors.red),
          ),
        ],
        top: <HarborBar>[
          HarborBar.solid(
            child: Container(key: const ValueKey<String>('top'), color: Colors.blue),
          ),
        ],
      );
      expect(_rect(tester, 'side').width, 0);
      expect(_rect(tester, 'top').height, 0);
      expect(_rect(tester, 'body').width, 1024, reason: 'the page keeps the frame');
    });
  });

  // Asked for by rubric-owner, for layout goldens: the chart's dock labels carry each dock's
  // extent, and with no way to set their font, flutter_test drew them as boxes. Breaks if:
  // labelStyle is not merged into what the chart paints.
  testWidgets('a chart overlay paints its labels in the style it is given', (final tester) async {
    Future<List<double>> labelHeights({final TextStyle? style}) async {
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborInspectorOverlay(
            labelStyle: style,
            child: HarborRoot(child: child!),
          ),
          // No text on the page, so every paragraph painted is a chart label.
          home: const HarborFrame(
            top: <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50, width: double.infinity))],
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      final List<double> heights = <double>[];
      final RenderObject chart = tester.renderObject(
        find.descendant(of: find.byType(HarborInspectorOverlay), matching: find.byType(CustomPaint)).first,
      );
      expect(
        chart,
        paints..everything((final Symbol method, final List<dynamic> arguments) {
          if (method == #drawParagraph) {
            heights.add((arguments[0] as ui.Paragraph).height);
          }
          return true;
        }),
      );
      return heights;
    }

    expect(await labelHeights(), isNotEmpty, reason: 'positive control: the chart paints labels');
    expect(await labelHeights(), everyElement(9), reason: 'the default label size');
    expect(await labelHeights(style: const TextStyle(fontSize: 20)), everyElement(20));
  });

  // Breaks if: a harbor's minimum is not applied to a bare edge.
  testWidgets('a harbor keeps its minimum off a bare edge', (final tester) async {
    await tester.pumpHarborTrial(
      _app(
        coast: HarborSystemEdges.none,
        const HarborFrame(
          minimum: EdgeInsetsDirectional.only(top: 24),
          body: HarborClear(child: SizedBox.expand(key: ValueKey<String>('content'))),
        ),
      ),
    );
    expect(_rect(tester, 'content').top, 24);
  });

  // Breaks if: a fast fling down no longer closes a draggable sheet.
  testWidgets('a draggable sheet closes on a fast fling down', (final tester) async {
    late BuildContext page;
    await tester.pumpHarborTrial(_app(HarborFrame(body: _Probe((final BuildContext c) => page = c))));
    unawaited(
      showHarborSheet<void>(
        page,
        builder: (final BuildContext context) => HarborSheet.draggable(
          header: _bar('handle', 40),
          builder: (final BuildContext context, final ScrollController controller) => HarborScrollView(
            controller: controller,
            slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('handle')), findsOneWidget, reason: 'positive control');
    // A short distance, so the sheet is nowhere near its minimum: only the speed can close it.
    await tester.fling(find.byKey(const ValueKey<String>('handle')), const Offset(0, 60), 3000);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('handle')), findsNothing);
  });

  // Breaks if: a builder stops taking the named builder type a caller holds it in.
  testWidgets('open water and a draggable sheet take named builder types', (final tester) async {
    final HarborWatersWidgetBuilder background = (final BuildContext context, final HarborRoomData waters) =>
        SizedBox(key: const ValueKey<String>('water'), height: waters.frameSize.height);
    final ScrollableWidgetBuilder list = (final BuildContext context, final ScrollController controller) =>
        HarborScrollView(controller: controller, slivers: const <Widget>[]);
    await tester.pumpHarborTrial(_app(HarborFrame(body: HarborOpenWater(builder: background))));
    expect(_rect(tester, 'water').height, tester.view.physicalSize.height / tester.view.devicePixelRatio);
    expect(HarborSheet.draggable(builder: list).builder, same(list));
  });
}

/// Reads the whole room, as `HarborOpenWater` did before it was retired for a Builder.
class _RoomReader extends StatelessWidget {
  const _RoomReader();

  @override
  Widget build(final BuildContext context) {
    HarborRoom.of(context);
    return const SizedBox(height: 10);
  }
}
