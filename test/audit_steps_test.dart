// The audit's smaller steps (#120, DECISIONS.md): the new spellings, and the deprecated ones
// forwarding to them with the defaults they had.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _navHeight = 56;

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
  home: home,
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

HarborBar _tabs() => const HarborBar.solid(
  child: SizedBox(key: ValueKey<String>('nav'), height: _navHeight),
);

void main() {
  group('HarborYield merges into HarborBarState', () {
    Future<void> pumpHidden(final WidgetTester tester, final Widget Function(Widget child) hide) =>
        tester.pumpHarborTrial(
          _app(
            HarborFrame(
              bottom: <HarborBar>[_tabs()],
              body: hide(const HarborClear(child: SizedBox.expand(key: ValueKey<String>('body')))),
            ),
          ),
          device: HarborTrialDevice.iPhone17,
        );

    testWidgets('state: dark keeps the bar\'s space; withdrawn, the default, gives it back', (final tester) async {
      await pumpHidden(tester, (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, child: child));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34);

      await pumpHidden(
        tester,
        (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.dark, child: child),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
    });

    testWidgets('the deprecated mode: forwards to state', (final tester) async {
      await pumpHidden(
        tester,
        (final Widget child) => HarborHideBar(edge: HarborEdge.bottom, mode: HarborYield.dark, child: child),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
      const HarborHideBar old = HarborHideBar(edge: HarborEdge.top, mode: HarborYield.dark, child: SizedBox());
      expect(old.state, HarborBarState.dark);
      expect(old.mode, HarborYield.dark);
    });

    testWidgets('hideBar takes a state, and a claim reports it', (final tester) async {
      late HarborController frame;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bottom: <HarborBar>[_tabs()],
            body: Builder(
              builder: (final BuildContext context) {
                frame = HarborFrame.of(context);
                return const HarborClear(child: SizedBox.expand(key: ValueKey<String>('body')));
              },
            ),
          ),
        ),
        device: HarborTrialDevice.iPhone17,
      );
      final HarborClaim dark = frame.hideBar(HarborEdge.bottom, state: HarborBarState.dark);
      await tester.pumpAndSettle();
      expect(dark.state, HarborBarState.dark);
      expect(_rect(tester, 'body').bottom, 874 - 34 - _navHeight);
      final HarborClaim withdrawn = frame.hideBar(HarborEdge.bottom);
      await tester.pumpAndSettle();
      expect(withdrawn.state, HarborBarState.withdrawn);
      expect(withdrawn.mode, HarborYield.withdraw);
      expect(_rect(tester, 'body').bottom, 874 - 34);
      withdrawn.release();
      dark.release();
      final HarborClaim old = frame.hideBar(HarborEdge.bottom, mode: HarborYield.dark);
      expect(old.state, HarborBarState.dark);
      old.release();
    });

    test('open is not a way to hide, and state and mode must agree', () {
      expect(
        () => HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.open, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => HarborHideBar(
          edge: HarborEdge.bottom,
          state: HarborBarState.dark,
          mode: HarborYield.withdraw,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('withdrawsAtHighTide becomes HarborKeyboardStance.withdraws', () {
    Future<HarborTrial> pumpStrip(final WidgetTester tester, final HarborBar strip) => tester.pumpHarborTrial(
      _app(
        HarborFrame(
          bottom: <HarborBar>[strip],
          body: const SizedBox.expand(key: ValueKey<String>('body')),
        ),
      ),
      device: HarborTrialDevice.iPhone17,
    );

    HarborBar strip({final HarborKeyboardStance keyboard = HarborKeyboardStance.withdraws, final bool flag = false}) =>
        HarborBar.solid(
          keyboard: keyboard,
          withdrawsAtHighTide: flag,
          child: const SizedBox(key: ValueKey<String>('strip'), height: 44),
        );

    testWidgets('a bar that withdraws leaves while the keyboard is up and comes back after', (final tester) async {
      final HarborTrial trial = await pumpStrip(tester, strip());
      expect(_rect(tester, 'body').bottom, 874 - 34 - 44);
      await trial.showKeyboard(settle: true);
      expect(_rect(tester, 'body').bottom, trial.keyboardTop, reason: 'it gave its space back');
      expect(find.byKey(const ValueKey<String>('strip')).hitTestable(), findsNothing);
      await trial.hideKeyboard(settle: true);
      expect(_rect(tester, 'body').bottom, 874 - 34 - 44);
    });

    testWidgets('it takes the system edge as a bar that stays does', (final tester) async {
      expect(strip().effectiveSystemEdges, HarborSystemEdgeStance.steady);
      expect(strip().withdrawsAtHighTide, isTrue, reason: 'the deprecated getter reads the stance too');
      expect(strip(keyboard: HarborKeyboardStance.stays).withdrawsAtHighTide, isFalse);
    });

    testWidgets('the deprecated flag still withdraws a bar of any stance, and survives copyWith', (final tester) async {
      final HarborBar riding = strip(keyboard: HarborKeyboardStance.rides, flag: true);
      expect(riding.keyboard, HarborKeyboardStance.rides);
      expect(riding.withdrawsAtHighTide, isTrue);
      expect(riding.copyWith(state: HarborBarState.dark).withdrawsAtHighTide, isTrue);
      final HarborTrial trial = await pumpStrip(tester, riding);
      await trial.showKeyboard(settle: true);
      expect(_rect(tester, 'body').bottom, trial.keyboardTop);
    });

    testWidgets('the inspector reads it as withdraws, and as pilings under its 0.8 key', (final tester) async {
      late BuildContext inside;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bottom: <HarborBar>[strip()],
            body: Builder(
              builder: (final BuildContext context) {
                inside = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(HarborInspector.nearest(inside)!.bars.single.keyboard, HarborKeyboardStance.withdraws);
      final Map<String, Object?> json = HarborInspector.nearest(inside)!.toJson();
      expect(((json['bars']! as List<Object?>).single! as Map<String, Object?>)['keyboard'], 'withdraws');
      expect(((json['docks']! as List<Object?>).single! as Map<String, Object?>)['tide'], 'pilings');
      expect(strip().toDiagnosticsNode().toStringDeep(), contains('keyboard: withdraws'));
    });
  });

  group('duration and curve go into animationStyle', () {
    // How far the tab bar has slid out, [after] withdrawing it.
    Future<double> slidAfter(
      final WidgetTester tester,
      final HarborBar Function(HarborBarState state) bar,
      final Duration after,
    ) async {
      final ValueNotifier<HarborBarState> state = ValueNotifier<HarborBarState>(HarborBarState.open);
      addTearDown(state.dispose);
      await tester.pumpHarborTrial(
        _app(
          ValueListenableBuilder<HarborBarState>(
            valueListenable: state,
            builder: (final BuildContext context, final HarborBarState value, final Widget? _) =>
                HarborFrame(bottom: <HarborBar>[bar(value)], body: const SizedBox.expand()),
          ),
        ),
        device: HarborTrialDevice.iPhone17,
      );
      final double top = _rect(tester, 'nav').top;
      state.value = HarborBarState.withdrawn;
      await tester.pump();
      await tester.pump(after);
      return _rect(tester, 'nav').top - top;
    }

    HarborBar nav(final HarborBarState state, {final AnimationStyle? style, final Duration? duration}) =>
        duration != null
        ? HarborBar.solid(
            state: state,
            duration: duration,
            child: const SizedBox(key: ValueKey<String>('nav'), height: _navHeight),
          )
        : HarborBar.solid(
            state: state,
            animationStyle: style,
            child: const SizedBox(key: ValueKey<String>('nav'), height: _navHeight),
          );

    testWidgets('left unset, a bar still moves over 250 ms', (final tester) async {
      expect(await slidAfter(tester, nav, const Duration(milliseconds: 200)), lessThan(_navHeight + 34));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_rect(tester, 'nav').top, greaterThanOrEqualTo(874 - 0.5), reason: 'gone by 260 ms');
    });

    testWidgets('AnimationStyle(duration:) sets it, and the deprecated duration: still does', (final tester) async {
      HarborBar styled(final HarborBarState s) =>
          nav(s, style: const AnimationStyle(duration: Duration(milliseconds: 100)));
      await slidAfter(tester, styled, const Duration(milliseconds: 110));
      expect(_rect(tester, 'nav').top, greaterThanOrEqualTo(874 - 0.5));
      HarborBar old(final HarborBarState s) => nav(s, duration: const Duration(milliseconds: 100));
      await slidAfter(tester, old, const Duration(milliseconds: 110));
      expect(_rect(tester, 'nav').top, greaterThanOrEqualTo(874 - 0.5));
    });
  });

  group('HarborSizing is a class: fill, and hug(maxFraction:)', () {
    Future<double> heightOf(final WidgetTester tester, final HarborFrame frame) async {
      await tester.pumpHarborTrial(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: KeyedSubtree(key: const ValueKey<String>('frame'), child: frame),
          ),
        ),
        device: HarborTrialDevice.iPhone17,
      );
      return _rect(tester, 'frame').height;
    }

    const Widget tall = SizedBox(height: 2000);
    const Widget short = SizedBox(height: 120);

    testWidgets('hug() is as tall as its body, and maxFraction caps it as maxExtentFraction did', (final tester) async {
      expect(await heightOf(tester, const HarborFrame(sizing: HarborSizing.hug(), body: short)), 120);
      expect(await heightOf(tester, const HarborFrame(sizing: HarborSizing.hug(maxFraction: 0.5), body: tall)), 437);
      expect(
        await heightOf(tester, const HarborFrame(sizing: HarborSizing.hugBody, maxExtentFraction: 0.5, body: tall)),
        437,
      );
      expect(
        await heightOf(tester, const HarborFrame(maxExtentFraction: 0.5, body: short)),
        874,
        reason: 'fill ignores it',
      );
    });

    test('the enum\'s spellings still read as they did', () {
      expect(HarborSizing.hugBody, const HarborSizing.hug());
      expect(HarborSizing.hugBody.hugs, isTrue);
      expect(HarborSizing.fill.hugs, isFalse);
      expect(HarborSizing.values, <HarborSizing>[HarborSizing.fill, const HarborSizing.hug()]);
      expect(<String>[for (final HarborSizing s in HarborSizing.values) s.name], <String>['fill', 'hugBody']);
      expect(<int>[for (final HarborSizing s in HarborSizing.values) s.index], <int>[0, 1]);
      expect(const HarborSizing.hug(maxFraction: 0.5), isNot(const HarborSizing.hug()));
      expect(
        const HarborFrame(sizing: HarborSizing.hug(maxFraction: 0.5), body: short).maxExtentFraction,
        0.5,
        reason: 'the deprecated getter reads the sizing\'s fraction',
      );
    });
  });

  group('HarborKeepInSight splits into three widgets, one per job', () {
    testWidgets('HarborCoverageListener reports how much of it the header covers', (final tester) async {
      final List<double> reports = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50))],
            body: HarborScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: HarborCoverageListener(onCoverage: reports.add, child: const SizedBox(height: 100)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(reports.last, 0.0);
      await tester.drag(find.byType(Scrollable), const Offset(0, -50));
      await tester.pumpAndSettle();
      expect(reports.last, closeTo(0.5, 0.05));
    });

    Future<HarborTrial> pumpField(final WidgetTester tester, final bool active, final ScrollController controller) =>
        tester.pumpHarborTrial(
          _app(
            HarborFrame(
              body: HarborScrollView(
                controller: controller,
                slivers: <Widget>[
                  const SliverToBoxAdapter(child: SizedBox(height: 600)),
                  SliverToBoxAdapter(
                    child: HarborKeepVisible(
                      active: active,
                      clearance: 16,
                      child: const SizedBox(key: ValueKey<String>('field'), height: 40),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 600)),
                ],
              ),
            ),
          ),
          device: HarborTrialDevice.iPhoneSE,
        );

    testWidgets('HarborKeepVisible keeps itself clear of the keyboard as it opens; inactive, it does not', (
      final tester,
    ) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      final HarborTrial trial = await pumpField(tester, true, controller);
      expect(_rect(tester, 'field').bottom, 660, reason: 'in sight with the keyboard down');
      await trial.showKeyboard(settle: true);
      expect(_rect(tester, 'field').bottom, lessThanOrEqualTo(trial.keyboardTop - 16 + 0.5));
    });

    testWidgets('HarborKeepVisible(active: false) leaves its child where it scrolls', (final tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      final HarborTrial trial = await pumpField(tester, false, controller);
      await trial.showKeyboard(settle: true);
      expect(controller.offset, 0, reason: 'nothing scrolled it, so the keyboard covers it');
    });

    Future<void> pumpBoat(final WidgetTester tester, final bool active) => tester.pumpHarborTrial(
      _app(
        HarborFrame(
          bottom: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50))],
          body: HarborKeepVisibleRegion(
            animationStyle: AnimationStyle.noAnimation,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 800,
                  left: 100,
                  child: HarborLift(
                    active: active,
                    child: const SizedBox(key: ValueKey<String>('boat'), width: 60, height: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      device: HarborTrialDevice.iPhone17,
    );

    testWidgets('HarborLift lifts its child clear of the tab bar in its region; inactive, it settles', (
      final tester,
    ) async {
      await pumpBoat(tester, true);
      await tester.pumpAndSettle();
      expect(_rect(tester, 'boat').bottom, lessThanOrEqualTo(874 - 34 - 50 + 0.5));
      await pumpBoat(tester, false);
      await tester.pumpAndSettle();
      expect(_rect(tester, 'boat').top, 800, reason: 'back where it was placed');
    });

    testWidgets('the deprecated HarborKeepInSight still does all three', (final tester) async {
      final List<double> reports = <double>[];
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50))],
            body: HarborScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: HarborKeepInSight(onObscured: reports.add, child: const SizedBox(height: 100)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(reports.last, 0.0);
      expect(const HarborKeepInSightRegion(child: SizedBox()), isA<HarborKeepVisibleRegion>());
    });
  });
}
