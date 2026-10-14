// The rename (0.9.0, #120) keeps every 0.8 name as a deprecated forwarder, so code written against
// 0.8 compiles and behaves as it did until `dart fix` moves it. These check that the forwarders
// forward; test_fixes/ checks what `dart fix` makes of them.

// Every use below is the deprecated spelling on purpose.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

void main() {
  group('old values are the new ones', () {
    // Breaks if: an alias names a different value, so a switch over the old names misses one.
    test('enum values', () {
      expect(HarborTideStance.float, same(HarborKeyboardStance.rides));
      expect(HarborTideStance.pilings, same(HarborKeyboardStance.stays));
      expect(HarborTideStance.dryDock, same(HarborKeyboardStance.reserves));
      expect(HarborTidePhase.low, same(HarborKeyboardPhase.hidden));
      expect(HarborTidePhase.rising, same(HarborKeyboardPhase.opening));
      expect(HarborTidePhase.high, same(HarborKeyboardPhase.shown));
      expect(HarborTidePhase.falling, same(HarborKeyboardPhase.closing));
      expect(HarborDockKind.pier, same(HarborBarKind.overlay));
      expect(HarborDockKind.quay, same(HarborBarKind.solid));
      expect(HarborFlareTarget.sea, same(HarborToastTarget.root));
      expect(HarborFlareClosedReason.lower, same(HarborToastClosedReason.hide));
      expect(HarborWatersAspect.coast, same(HarborRoomAspect.systemEdges));
      expect(HarborWatersAspect.docks, same(HarborRoomAspect.bars));
      expect(HarborRest.wakeEnd, same(HarborRest.fadeEnd));
      expect(HarborRest.dockEdge, same(HarborRest.barFace));
    });

    // Breaks if: an old subclass's value compares unequal to the same value spelled with the new class.
    test('the old subclasses build equal values', () {
      expect(
        const HarborDock.pier(tide: HarborTideStance.float, wake: HarborWake.none, child: SizedBox()).keyboard,
        HarborKeyboardStance.rides,
      );
      expect(const HarborDock.quay(child: SizedBox()).kind, HarborBarKind.solid);
      expect(
        const HarborDock.reserve(extent: 80, coast: HarborCoastStance.none).systemEdges,
        HarborSystemEdgeStance.none,
      );
      expect(HarborWake.none, HarborEdgeEffect.none);
      expect(
        const HarborWake.fade(length: 12, dockOpacity: 0.5),
        const HarborEdgeEffect.fade(length: 12, faceOpacity: 0.5),
      );
      expect(const HarborWake.hairline(), const HarborEdgeEffect.hairline());
      expect(HarborCoast.ambient, HarborSystemEdges.ambient);
      expect(HarborCoast.none, HarborSystemEdges.none);
      expect(
        const HarborCoast.fixed(EdgeInsets.zero, calmTide: true),
        const HarborSystemEdges.fixed(EdgeInsets.zero, ignoresKeyboard: true),
      );
      expect(const HarborFairway(tide: false, slivers: <Widget>[]).keyboard, isFalse);
      expect(HarborFairway.box(wake: false, child: const SizedBox()).edgeEffects, isFalse);
      expect(const HarborBuoy(child: SizedBox()).modal, isFalse);
    });
  });

  group('old parameters and getters forward', () {
    // Breaks if: a deprecated parameter is accepted and dropped.
    test('on the frame, the content and the effects', () {
      const HarborFrame frame = HarborFrame(
        newPort: true,
        bodyClearsTide: false,
        dockHinge: HarborHinge.never,
        body: SizedBox(),
      );
      expect(frame.isPage, isTrue);
      expect(frame.newPort, isTrue);
      expect(frame.bodyClearsKeyboard, isFalse);
      expect(frame.barHinge, HarborHinge.never);
      const HarborClear clear = HarborClear(
        tide: false,
        mooringLine: true,
        extra: EdgeInsets.all(4),
        child: SizedBox(),
      );
      expect(<Object>[clear.keyboard, clear.rowInsets, clear.padding], <Object>[false, true, const EdgeInsets.all(4)]);
      const HarborFadeBand band = HarborFadeBand(dockEdge: 10, wakeEnd: 30, dockOpacity: 0.5);
      expect(<double?>[band.barFace, band.fadeEnd, band.faceOpacity, band.dockEdge], <double?>[10, 30, 0.5, 10]);
      const HarborKeyboardState state = HarborKeyboardState(
        height: 300,
        remaining: 300,
        highWater: 300,
        highWaterIsEstimate: false,
        phase: HarborKeyboardPhase.shown,
      );
      expect(<Object>[state.settledHeight, state.isIn, state.highWaterIsEstimate], <Object>[300.0, true, false]);
    });

    // Breaks if: a renamed method, a renamed static or the old row widget lays out differently.
    testWidgets('on the handle, the room and the row', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) =>
              HarborSea(margin: const EdgeInsets.all(16), child: child!),
          home: Harbor(
            top: const <HarborDock>[HarborDock.pier(child: SizedBox(height: 50))],
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    HarborMooringLine(child: SizedBox(key: ValueKey<String>('old'), height: 10)),
                    HarborClear.rowInsets(child: SizedBox(key: ValueKey<String>('new'), height: 10)),
                  ],
                );
              },
            ),
          ),
        ),
      );
      Rect rect(final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));
      expect(rect('old').left, rect('new').left);
      expect(rect('old').left, 16, reason: 'positive control: the margin is applied');
      expect(HarborWaters.dockFaceOf(page, HarborEdge.top), HarborRoom.barFaceOf(page, HarborEdge.top));
      final HarborController controller = Harbor.of(page);
      expect(controller.fleet, same(controller.registry));
      expect(controller.clearWater, same(controller.room));
      final HarborClaim claim = controller.makeWay(HarborEdge.top, mode: HarborYield.dark);
      expect(controller.claimedStateOf(HarborEdge.top), HarborBarState.dark);
      claim.release();
      final HarborFlareEntry toast = HarborFlares.raise(page, reachesCoast: true, builder: (_) => const Text('toast'));
      expect(toast.reachesCoast, isTrue);
      toast.lower();
      expect(await toast.closed, HarborToastClosedReason.hide);
      await tester.pumpAndSettle();
    });
  });
}
