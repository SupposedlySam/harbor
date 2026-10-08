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

Widget _bar(final String label, final double height) => SizedBox(
  key: ValueKey<String>(label),
  height: height,
  width: double.infinity,
  child: Text(label),
);

Widget _app(final Widget home, {final HarborCoast coast = HarborCoast.ambient}) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(coast: coast, child: child!),
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

/// Reads only the coast, through the raw waters, so nothing but the coast aspect can rebuild it.
class _CoastReader extends StatelessWidget {
  const _CoastReader(this.seen);

  final List<double> seen;

  @override
  Widget build(final BuildContext context) {
    seen.add(HarborWaters.maybeRawOf(context, aspect: HarborWatersAspect.coast)!.coast.top);
    return const SizedBox.expand();
  }
}

/// Reads one aspect of the waters through [HarborWaters.of].
class _AspectReader extends StatelessWidget {
  const _AspectReader(this.aspect);

  final HarborWatersAspect aspect;

  @override
  Widget build(final BuildContext context) {
    HarborWaters.of(context, aspect: aspect);
    return const SizedBox(height: 10);
  }
}

/// Records the tide each time it is rebuilt.
class _TideReader extends StatelessWidget {
  const _TideReader(this.seen);

  final List<HarborTideState> seen;

  @override
  Widget build(final BuildContext context) {
    seen.add(HarborTide.of(context));
    return const SizedBox.expand();
  }
}

void main() {
  group('Claims', () {
    // Breaks if: releasing one claim releases every claim on the edge.
    testWidgets('are counted: the dock comes back only when every claim is released', (final tester) async {
      late BuildContext body;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            body: _Probe((final BuildContext c) => body = c),
          ),
        ),
      );
      final HarborController harbor = HarborController.of(body);
      final HarborClaim first = harbor.makeWay(HarborEdge.top);
      final HarborClaim second = harbor.makeWay(HarborEdge.top);
      expect(harbor.claimedStateOf(HarborEdge.top), HarborDockState.withdrawn);

      first.release();
      await tester.pumpAndSettle();
      expect(harbor.claimedStateOf(HarborEdge.top), HarborDockState.withdrawn, reason: 'one claim is still held');
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
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            body: HarborMoored(
              child: Harbor(
                debugLabel: 'component',
                body: _Probe((final BuildContext c) => inner = c),
              ),
            ),
          ),
        ),
      );
      final double open = _rect(tester, 'header').height;
      expect(open, greaterThan(0));

      final HarborClaim claim = HarborController.of(inner).makeWay(HarborEdge.top);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('header')).hitTestable(), findsNothing, reason: 'the page header withdrew');

      claim.release();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'header').height, open);
    });
  });

  group('Breakwaters', () {
    Future<HarborController> page(final WidgetTester tester) async {
      late BuildContext body;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: HarborMoored(
              child: _Probe((final BuildContext c) => body = c, child: const SizedBox.expand(key: ValueKey<String>('content'))),
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
        ..addBreakwater(low)
        ..addBreakwater(high);
      await tester.pumpAndSettle();
      expect(harbor.breakwaterCoverage, 300);
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
      final HarborBreakwater breakwater = harbor.addBreakwater(cover);
      await tester.pumpAndSettle();
      expect(_rect(tester, 'content').bottom, lessThan(before), reason: 'positive control: it covered');

      breakwater.remove();
      await tester.pumpAndSettle();
      expect(harbor.breakwaterCoverage, 0);
      expect(_rect(tester, 'content').bottom, before);
    });
  });

  group('Signals', () {
    // Breaks if: the port on top is any route that is still active, rather than the current one.
    testWidgets('go to the current route even when a background page re-mounts its harbor', (final tester) async {
      final ValueNotifier<int> generation = ValueNotifier<int>(0);
      addTearDown(generation.dispose);
      final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
      late BuildContext top;
      await tester.pumpSeaTrial(
        MaterialApp(
          navigatorKey: navigator,
          builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
          home: ValueListenableBuilder<int>(
            valueListenable: generation,
            builder: (final BuildContext context, final int g, final Widget? _) =>
                Harbor(key: ValueKey<int>(g), debugLabel: 'background', body: const SizedBox.expand()),
          ),
        ),
      );
      unawaited(navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (final BuildContext context) => Harbor(
          debugLabel: 'front',
          body: _Probe((final BuildContext c) => top = c),
        ),
      )));
      await tester.pumpAndSettle();
      // The page underneath rebuilds a fresh harbor, which joins the fleet after the front one.
      generation.value++;
      await tester.pumpAndSettle();

      final HarborController front = HarborController.of(top);
      expect(front.fleet.topmost, same(front));
    });

    // Breaks if: an exact alignment is ignored in favour of the slot, or placed anywhere but its
    // point in the clear water, 16 in from its edges, as a buoy at that alignment would be.
    testWidgets('take an exact alignment within the clear water', (final tester) async {
      const Alignment notch = Alignment(0.0, -0.8);
      late BuildContext page;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(Harbor(body: _Probe((final BuildContext c) => page = c))));
      HarborSignals.raise(
        page,
        alignment: notch,
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = trial.clearWaterAround(find.byType(_Probe)).deflate(16);
      expect(_rect(tester, 'toast'), notch.inscribe(const Size(200, 40), water));
    });

    // Breaks if: a directional alignment is resolved where the signal is shown rather than in the
    // reading direction of the page that raised it.
    testWidgets('resolve a directional alignment in the direction of the page that raised it', (final tester) async {
      late BuildContext page;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Directionality(textDirection: TextDirection.rtl, child: _Probe((final BuildContext c) => page = c)),
          ),
        ),
      );
      HarborSignals.raise(
        page,
        alignment: AlignmentDirectional.centerEnd,
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = trial.clearWaterAround(find.byType(_Probe)).deflate(16);
      expect(_rect(tester, 'toast'), Alignment.centerLeft.inscribe(const Size(200, 40), water));
    });

    // Breaks if: the overlay a signal falls back to ignores its exact alignment.
    testWidgets('without a harbor, take an exact alignment within the overlay’s padded water', (final tester) async {
      const Alignment notch = Alignment(0.0, -0.8);
      late BuildContext page;
      await tester.pumpSeaTrial(MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))));
      HarborSignals.raise(
        page,
        alignment: notch,
        builder: (final BuildContext c) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40),
        duration: null,
      );
      await tester.pumpAndSettle();
      final Rect water = const EdgeInsets.fromLTRB(16, _statusBar + 16, 16, 34 + 16).deflateRect(Offset.zero & const Size(402, _screen));
      expect(_rect(tester, 'toast'), notch.inscribe(const Size(200, 40), water));
    });

    // Breaks if: a signal with no harbor above it is dropped (it used to assert, and show nothing
    // in release), or the overlay it falls back to ignores the coast or the keyboard.
    testWidgets('without a harbor, go to the nearest overlay, clear of the coast and the keyboard', (final tester) async {
      late BuildContext page;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))),
      );
      await trial.raiseTide();
      final HarborSignalEntry low = HarborSignals.raise(
        page,
        slot: HarborSignalSlot.low,
        builder: (final BuildContext c) => _bar('low', 30),
        duration: null,
      );
      final HarborSignalEntry top = HarborSignals.raise(
        page,
        slot: HarborSignalSlot.top,
        builder: (final BuildContext c) => _bar('top', 30),
        duration: null,
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'low').bottom, lessThanOrEqualTo(trial.waterline));
      expect(_rect(tester, 'low').bottom, greaterThan(trial.waterline - 30 - 16 - 1), reason: 'it sits on the keyboard');
      expect(_rect(tester, 'top').top, greaterThanOrEqualTo(_statusBar));

      low.lower();
      top.lower();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('low')), findsNothing);
      expect(find.byKey(const ValueKey<String>('top')), findsNothing);
    });

    // Breaks if: a signal with nowhere to go is dropped without a word, or asserts (which a
    // release build never sees).
    testWidgets('without a harbor or an overlay, report that the signal was not shown', (final tester) async {
      late BuildContext bare;
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: _Probe((final BuildContext c) => bare = c),
      ));
      final HarborSignalEntry entry = HarborSignals.raise(bare, builder: (final BuildContext c) => _bar('lost', 30));
      final Object? error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect('$error', contains('HarborSignals.raise'));
      expect(entry.showing.value, isFalse);
    });

    // Breaks if: a signal's timers outlive the tree. The test framework fails a test that ends
    // with a timer pending, so the check is the end of each test.
    testWidgets('leave no timer pending when the harbor goes away', (final tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(_app(Harbor(body: _Probe((final BuildContext c) => page = c))));
      HarborSignals.raise(page, builder: (final BuildContext c) => _bar('afloat', 30));
      HarborSignals.raise(page, builder: (final BuildContext c) => _bar('lowering', 30)).lower();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('afloat')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('leave no timer pending when the overlay goes away', (final tester) async {
      late BuildContext page;
      await tester.pumpSeaTrial(MaterialApp(home: Material(child: _Probe((final BuildContext c) => page = c))));
      HarborSignals.raise(page, builder: (final BuildContext c) => _bar('afloat', 30));
      await tester.pump();
      HarborSignals.raise(page, builder: (final BuildContext c) => _bar('lowering', 30)).lower();
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('afloat')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('The tide', () {
    Future<HarborSeaTrial> page(final WidgetTester tester, final List<HarborTideState> seen) =>
        tester.pumpSeaTrial(_app(Harbor(bodyClearsTide: false, body: _TideReader(seen))));

    Future<void> frames(final WidgetTester tester) async {
      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    // Breaks if: high water is no longer kept per orientation.
    testWidgets('keeps a high-water mark per orientation', (final tester) async {
      final List<HarborTideState> seen = <HarborTideState>[];
      final HarborSeaTrial trial = await page(tester, seen);
      await trial.raiseTide();
      await trial.lowerTide();
      expect(seen.last.highWater, 336);
      expect(seen.last.highWaterIsEstimate, isFalse);

      tester.view.physicalSize = const Size(_screen, 402);
      await frames(tester);
      expect(seen.last.highWaterIsEstimate, isTrue, reason: 'no keyboard has settled in landscape');
      expect(seen.last.highWater, isNot(336));
    });

    // Breaks if: high water only ever rises. The example's field guide holds this too; the
    // package owns the concept, so it holds it here.
    testWidgets('lets high water fall when the keyboard settles lower', (final tester) async {
      final List<HarborTideState> seen = <HarborTideState>[];
      final HarborSeaTrial trial = await page(tester, seen);
      await trial.raiseTide();
      await trial.lowerTide();
      expect(seen.last.highWater, 336, reason: 'positive control');

      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await frames(tester);
      expect(seen.last.highWater, 250);
    });
  });

  group('The waters', () {
    // Breaks if: the waters stop being clamped to MediaQuery.
    testWidgets('honor a layer outside the harbor that removed padding', (final tester) async {
      late BuildContext inside;
      late BuildContext control;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
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
      expect(HarborWaters.of(control).coast.top, _statusBar, reason: 'positive control');
      expect(HarborWaters.of(inside).coast.top, 0);
    });

    // Breaks if: casting off an edge keeps that edge's wake.
    testWidgets('cast off an edge\'s wake along with the edge', (final tester) async {
      late BuildContext under;
      late BuildContext castOff;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.pier(wake: const HarborWake.fade(length: 12), child: _bar('header', 50))],
            body: _Probe(
              (final BuildContext c) => under = c,
              child: HarborCastOff(
                edges: const <HarborEdge>{HarborEdge.top},
                child: _Probe((final BuildContext c) => castOff = c),
              ),
            ),
          ),
        ),
      );
      expect(HarborWaters.of(under).wakes, contains(HarborEdge.top), reason: 'positive control');
      expect(HarborWaters.of(castOff).wakes, isNot(contains(HarborEdge.top)));
      expect(HarborWaters.of(castOff).wakeOf(HarborEdge.top), HarborWakeBand.none);
    });

    // Breaks if: a reader of the coast aspect is not rebuilt when the coast changes.
    testWidgets('rebuild a coast reader when the coast changes', (final tester) async {
      final ValueNotifier<double> top = ValueNotifier<double>(20);
      addTearDown(top.dispose);
      final List<double> seen = <double>[];
      await tester.pumpSeaTrial(
        MaterialApp(
          home: ValueListenableBuilder<double>(
            valueListenable: top,
            // The reader is const, so nothing but the waters can rebuild it.
            child: Harbor(body: _CoastReader(seen)),
            builder: (final BuildContext context, final double t, final Widget? page) =>
                HarborSea(coast: HarborCoast.fixed(EdgeInsetsDirectional.only(top: t)), child: page!),
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
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            body: _Probe((final BuildContext c) => body = c),
          ),
        ),
      );
      final Map<String, String> css = HarborWaters.of(body).toCssVariables(TextDirection.ltr);
      expect(css['--harbor-inset-top'], '${_statusBar + 50}px');
    });

    // Breaks if: HarborCastOff(tide: true) keeps the keyboard.
    testWidgets('cast off the tide when asked', (final tester) async {
      late BuildContext under;
      late BuildContext castOff;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            body: _Probe(
              (final BuildContext c) => under = c,
              child: HarborCastOff(
                edges: const <HarborEdge>{},
                tide: true,
                child: _Probe((final BuildContext c) => castOff = c),
              ),
            ),
          ),
        ),
      );
      await trial.raiseTide();
      expect(MediaQuery.viewInsetsOf(under).bottom, greaterThan(0), reason: 'positive control');
      expect(MediaQuery.viewInsetsOf(castOff).bottom, 0);
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
        final EdgeInsets coast = on.coastWhen(tideIn: share > 0);
        tester.view
          ..padding = FakeViewPadding(left: coast.left, top: coast.top, right: coast.right, bottom: coast.bottom)
          ..viewInsets = FakeViewPadding(bottom: on.tideHeight * share);
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
      final List<HarborTideState> tide = <HarborTideState>[];
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Column(
              children: <Widget>[
                const _AspectReader(HarborWatersAspect.docks),
                SizedBox(height: 10, child: _TideReader(tide)),
              ],
            ),
          ),
        ),
      );
      rebuilds.updateAll((final Type _, final int _) => 0);
      await trial.raiseTide();
      expect(rebuilds[_TideReader], greaterThan(1), reason: 'positive control: the keyboard moved over several frames');
      expect(rebuilds[_AspectReader], lessThanOrEqualTo(1));
    });

    // Breaks if: HarborWaters.of depends on the whole MediaQuery again, or a content role reads
    // the waters (or MediaQuery) beyond the parts it uses.
    testWidgets('readers of the coast, the docks and the margin hold still while the keyboard moves', (final tester) async {
      final List<double> insetsSeen = <double>[];
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            body: Column(
              children: <Widget>[
                const _AspectReader(HarborWatersAspect.coast),
                const _AspectReader(HarborWatersAspect.docks),
                const _AspectReader(HarborWatersAspect.margin),
                HarborOpenWater(builder: (final BuildContext context, final HarborWatersData waters) => const SizedBox(height: 10)),
                const HarborMooringLine(child: SizedBox(height: 10)),
                const HarborMoored(edges: HarborEdge.horizontal, tide: false, child: SizedBox(height: 10)),
                const SizedBox(
                  height: 40,
                  child: HarborFairway(
                    scrollDirection: Axis.horizontal,
                    slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(width: 2000))],
                  ),
                ),
                // The positive control: something that reads the keyboard does see it move.
                _Probe((final BuildContext c) => insetsSeen.add(MediaQuery.viewInsetsOf(c).bottom), child: const SizedBox(height: 10)),
              ],
            ),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{
        _AspectReader,
        HarborOpenWater,
        HarborMooringLine,
        HarborMoored,
        HarborFairway,
      });
      insetsSeen.clear();
      await slideTide(tester, tideIn: true);
      expect(insetsSeen, hasLength(10), reason: 'positive control: the body saw every frame of the keyboard');
      expect(insetsSeen.last, device.tideHeight);
      expect(rebuilds, <Type, int>{
        _AspectReader: 0,
        HarborOpenWater: 0,
        HarborMooringLine: 0,
        HarborMoored: 0,
        HarborFairway: 0,
      });
    });

    // A body that clears the tide takes the keyboard out of its view padding, as
    // `MediaQueryData.removeViewInsets` does, so on a phone with a home indicator the steady
    // coast's clamp is reached on every frame the keyboard moves. The iPhone SE above has no
    // bottom coast and never reaches it.
    // Breaks if: HarborWaters.of subscribes coast readers to the steady coast's clamp.
    testWidgets('a coast-only moored block holds still while the keyboard rises over a home indicator', (final tester) async {
      const HarborTrialDevice phone = HarborTrialDevice.iPhone17;
      final List<HarborTideState> tide = <HarborTideState>[];
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Column(
              children: <Widget>[
                const HarborMoored(
                  edges: <HarborEdge>{HarborEdge.top, HarborEdge.start, HarborEdge.end},
                  clear: HarborClear.coast,
                  tide: false,
                  child: SizedBox(height: 10),
                ),
                const _AspectReader(HarborWatersAspect.coast),
                SizedBox(height: 10, child: _TideReader(tide)),
              ],
            ),
          ),
        ),
        device: phone,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborMoored, _AspectReader, _TideReader});
      await slideTide(tester, tideIn: true, on: phone);
      expect(rebuilds[_TideReader], greaterThanOrEqualTo(10), reason: 'positive control: the keyboard moved on every frame');
      // Once each, for the platform taking the home indicator out of the padding.
      expect(rebuilds[HarborMoored], 1);
      expect(rebuilds[_AspectReader], 1);
    });

    // The standard is `MediaQuery.viewPaddingOf`: it rebuilds when the view padding changes, and
    // the steady coast should rebuild no more often than that while holding its value.
    // Breaks if: steadyCoastOf depends on the tide gauge, which notifies on every frame.
    testWidgets('the steady coast holds still while the keyboard rises over a home indicator', (final tester) async {
      const HarborTrialDevice phone = HarborTrialDevice.iPhone17;
      final List<double> steady = <double>[];
      final List<double> viewPadding = <double>[];
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: Column(
              children: <Widget>[
                _Probe(
                  (final BuildContext c) => steady.add(HarborWaters.steadyCoastOf(c, HarborEdge.bottom)),
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
      expect(steady, everyElement(phone.coast.bottom));
      expect(steady.length, lessThanOrEqualTo(viewPadding.length));
    });

    // Breaks if: isInOf depends on the tide gauge as a whole, which notifies on every frame.
    testWidgets('a reader of whether the tide is in rebuilds exactly when it comes and goes', (final tester) async {
      final List<bool> seen = <bool>[];
      await tester.pumpSeaTrial(
        _app(Harbor(bodyClearsTide: false, body: _Probe((final BuildContext c) => seen.add(HarborTide.isInOf(c))))),
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
      await tester.pumpSeaTrial(
        _app(
          const Harbor(
            bottom: <HarborDock>[
              HarborDock.quay(tide: HarborTideStance.dryDock, child: HarborDryDock(child: SizedBox.expand())),
            ],
            body: SizedBox.expand(),
          ),
        ),
        device: device,
      );
      final Map<Type, int> rebuilds = countRebuilds(<Type>{HarborDryDock});
      void recordHeight() => heights.add(tester.getSize(find.byType(HarborDryDock)).height);
      recordHeight();
      await slideTide(tester, tideIn: true);
      recordHeight();
      // The tide came in (1) and settled at a new high-water mark (2).
      expect(rebuilds[HarborDryDock], 2);
      await slideTide(tester, tideIn: false);
      recordHeight();
      // It went out (3), and settling at low water left the mark where it was.
      expect(rebuilds[HarborDryDock], 3);
      expect(heights, <double>[device.size.height * 0.4, device.tideHeight, device.tideHeight]);
    });
  });

  // The README's Scaffold advice, held. A resizing Scaffold shrinks the harbor before it sees the
  // keyboard, so a tab bar on pilings is lifted instead of covered; with resizing off, the harbor
  // owns the tide. Both halves are asserted, so the advice is checked and so is its reason.
  testWidgets('inside a Scaffold, the harbor owns the tide only once the Scaffold stops resizing', (final tester) async {
    Future<double> tabBarTopUnderKeyboard({required final bool resize}) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
          home: Scaffold(
            resizeToAvoidBottomInset: resize,
            body: Harbor(
              bottom: <HarborDock>[HarborDock.quay(child: _bar('tabs', 56))],
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await trial.raiseTide(settle: true);
      final double top = _rect(tester, 'tabs').top;
      await trial.lowerTide(settle: true);
      return top;
    }

    final double resting = _screen - 34 - 56; // above the home indicator
    expect(await tabBarTopUnderKeyboard(resize: false), resting, reason: 'pilings: the keyboard covers it');
    expect(await tabBarTopUnderKeyboard(resize: true), lessThan(_screen - 336), reason: 'the hazard the README warns of');
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
      coast: EdgeInsets.only(top: 24, bottom: 20),
      tideHeight: 400,
    );

    Future<void> pump(final WidgetTester tester, {final List<HarborDock> start = const <HarborDock>[], final List<HarborDock> top = const <HarborDock>[]}) =>
        tester.pumpSeaTrial(
          MaterialApp(
            builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
            home: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Harbor(start: start, top: top, body: const SizedBox.expand(key: ValueKey<String>('body'))),
            ),
          ),
          device: tablet,
        );

    testWidgets('a NavigationRail in a side dock takes its own width', (final tester) async {
      await pump(
        tester,
        start: <HarborDock>[
          HarborDock.quay(
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
      await pump(tester, top: <HarborDock>[HarborDock.pier(child: AppBar(key: const ValueKey<String>('bar'), title: const Text('t')))]);
      expect(_rect(tester, 'bar').height, kToolbarHeight);
    });

    testWidgets('a widget with no size of its own takes none', (final tester) async {
      await pump(
        tester,
        start: <HarborDock>[HarborDock.quay(child: Container(key: const ValueKey<String>('side'), color: Colors.red))],
        top: <HarborDock>[HarborDock.quay(child: Container(key: const ValueKey<String>('top'), color: Colors.blue))],
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
      await tester.pumpSeaTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) =>
              HarborChartOverlay(labelStyle: style, child: HarborSea(child: child!)),
          // No text on the page, so every paragraph painted is a chart label.
          home: const Harbor(
            top: <HarborDock>[HarborDock.pier(child: SizedBox(height: 50, width: double.infinity))],
            body: SizedBox.expand(),
          ),
        ),
      );
      await tester.pump();
      final List<double> heights = <double>[];
      final RenderObject chart = tester.renderObject(
        find.descendant(of: find.byType(HarborChartOverlay), matching: find.byType(CustomPaint)).first,
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
    await tester.pumpSeaTrial(
      _app(
        coast: HarborCoast.none,
        const Harbor(
          minimum: EdgeInsetsDirectional.only(top: 24),
          body: HarborMoored(child: SizedBox.expand(key: ValueKey<String>('content'))),
        ),
      ),
    );
    expect(_rect(tester, 'content').top, 24);
  });

  // Breaks if: a fast fling down no longer closes a draggable sheet.
  testWidgets('a draggable sheet closes on a fast fling down', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(_app(Harbor(body: _Probe((final BuildContext c) => page = c))));
    unawaited(showHarborSheet<void>(
      page,
      builder: (final BuildContext context) => HarborSheet.draggable(
        header: _bar('handle', 40),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('handle')), findsOneWidget, reason: 'positive control');
    // A short distance, so the sheet is nowhere near its minimum: only the speed can close it.
    await tester.fling(find.byKey(const ValueKey<String>('handle')), const Offset(0, 60), 3000);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('handle')), findsNothing);
  });
}
