// The audit's smaller steps (#120, DECISIONS.md): the new spellings, with the defaults the old ones
// had.

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
  group('a hidden bar takes a HarborBarState', () {
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
      expect(_rect(tester, 'body').bottom, 874 - 34);
      withdrawn.release();
      dark.release();
    });

    test('open is not a way to hide', () {
      expect(
        () => HarborHideBar(edge: HarborEdge.bottom, state: HarborBarState.open, child: const SizedBox()),
        throwsAssertionError,
      );
    });
  });

  group('HarborKeyboardStance.withdraws', () {
    Future<HarborTrial> pumpStrip(final WidgetTester tester, final HarborBar strip) => tester.pumpHarborTrial(
      _app(
        HarborFrame(
          bottom: <HarborBar>[strip],
          body: const SizedBox.expand(key: ValueKey<String>('body')),
        ),
      ),
      device: HarborTrialDevice.iPhone17,
    );

    HarborBar strip({final HarborKeyboardStance keyboard = HarborKeyboardStance.withdraws}) => HarborBar.solid(
      keyboard: keyboard,
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
    });

    testWidgets('the inspector reads it as withdraws', (final tester) async {
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
      expect(strip().toDiagnosticsNode().toStringDeep(), contains('keyboard: withdraws'));
    });
  });

  group('a bar moves as its animationStyle says', () {
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

    HarborBar nav(final HarborBarState state, {final AnimationStyle? style}) => HarborBar.solid(
      state: state,
      animationStyle: style,
      child: const SizedBox(key: ValueKey<String>('nav'), height: _navHeight),
    );

    testWidgets('left unset, a bar still moves over 250 ms', (final tester) async {
      expect(await slidAfter(tester, nav, const Duration(milliseconds: 200)), lessThan(_navHeight + 34));
      await tester.pump(const Duration(milliseconds: 60));
      expect(_rect(tester, 'nav').top, greaterThanOrEqualTo(874 - 0.5), reason: 'gone by 260 ms');
    });

    testWidgets('AnimationStyle(duration:) sets it', (final tester) async {
      HarborBar styled(final HarborBarState s) =>
          nav(s, style: const AnimationStyle(duration: Duration(milliseconds: 100)));
      await slidAfter(tester, styled, const Duration(milliseconds: 110));
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

    testWidgets('hug() is as tall as its body, and maxFraction caps it', (final tester) async {
      expect(await heightOf(tester, const HarborFrame(sizing: HarborSizing.hug(), body: short)), 120);
      expect(await heightOf(tester, const HarborFrame(sizing: HarborSizing.hug(maxFraction: 0.5), body: tall)), 437);
    });
  });

  group('keeping in sight is three widgets, one per job', () {
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
  });

  group('a page under the root: isPage changes nothing there', () {
    // Measured for the audit's step on newPort (DECISIONS.md): a frame on a route right under
    // HarborRoot lays out the same whether it starts a page or not, since the root has no bars to
    // reach in. So HarborFrame.page is for a frame inside another frame, not for a route.
    Future<(Rect, HarborRoomData, Rect, HarborRoomData)> measure(
      final WidgetTester tester, {
      required final bool isPage,
    }) async {
      late HarborRoomData room;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            isPage: isPage,
            top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: 50))],
            bottom: const <HarborBar>[HarborBar.solid(child: SizedBox(height: 56))],
            body: Builder(
              builder: (final BuildContext context) {
                room = HarborRoom.of(context);
                return const HarborClear(child: SizedBox.expand(key: ValueKey<String>('probe')));
              },
            ),
          ),
        ),
        device: HarborTrialDevice.iPhone17,
      );
      final Rect down = _rect(tester, 'probe');
      final HarborRoomData roomDown = room;
      await trial.showKeyboard(settle: true);
      final Rect up = _rect(tester, 'probe');
      final HarborRoomData roomUp = room;
      await trial.hideKeyboard(settle: true);
      return (down, roomDown, up, roomUp);
    }

    testWidgets('the same rectangles and room data, keyboard down and up', (final tester) async {
      final (Rect down, HarborRoomData roomDown, Rect up, HarborRoomData roomUp) = await measure(tester, isPage: false);
      final (Rect pageDown, HarborRoomData pageRoomDown, Rect pageUp, HarborRoomData pageRoomUp) = await measure(
        tester,
        isPage: true,
      );
      expect(down, const Rect.fromLTRB(0, 112, 402, 784));
      expect(pageDown, down);
      expect(pageUp, up);
      for (final (HarborRoomData a, HarborRoomData b) in <(HarborRoomData, HarborRoomData)>[
        (roomDown, pageRoomDown),
        (roomUp, pageRoomUp),
      ]) {
        expect(b.systemEdges, a.systemEdges);
        expect(b.systemEdgesSteady, a.systemEdgesSteady);
        expect(b.bars, a.bars);
        expect(b.fadeBands, a.fadeBands);
        expect(b.frameSize, a.frameSize);
      }
    });
  });
}
