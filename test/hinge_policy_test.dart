// HarborHinge: which hinges and folds harbor's overlays keep off, set on the sea, a page or one
// overlay, the nearest winning, with MediaQuery.displayFeatures left as the platform reports it.

import 'dart:async';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540
const HarborTrialDevice _flat = HarborTrialDevice.foldableOpen; // 750 wide, a flat fold at 375
final HarborTrialDevice _halfOpen = _flat.copyWith(
  name: 'foldable half open',
  displayFeatures: const <DisplayFeature>[
    DisplayFeature(
      bounds: Rect.fromLTRB(375, 0, 375, 832),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureHalfOpened,
    ),
  ],
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<BuildContext> _pump(
  final WidgetTester tester, {
  required final HarborTrialDevice device,
  final HarborHinge sea = HarborHinge.avoidSeparating,
  final HarborHinge? page,
  final List<HarborFloat> buoys = const <HarborFloat>[],
}) async {
  late BuildContext inside;
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(hinge: sea, child: child!),
      home: HarborFrame(
        hinge: page,
        floats: buoys,
        body: Builder(
          builder: (final BuildContext context) {
            inside = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
    device: device,
  );
  return inside;
}

Future<Rect> _sheet(final WidgetTester tester, final BuildContext page, {final HarborHinge? hinge}) async {
  unawaited(
    showHarborSheet<void>(
      page,
      hinge: hinge,
      builder: (final BuildContext _) => const HarborSheet(body: SizedBox(key: ValueKey<String>('sheet'), height: 120)),
    ),
  );
  await tester.pumpAndSettle();
  return _rect(tester, 'sheet');
}

void main() {
  group('which features each policy keeps off', () {
    const DisplayFeature hinge = DisplayFeature(
      bounds: Rect.fromLTRB(540, 0, 574, 720),
      type: DisplayFeatureType.hinge,
      state: DisplayFeatureState.postureFlat,
    );
    const DisplayFeature flatFold = DisplayFeature(
      bounds: Rect.fromLTRB(375, 0, 375, 832),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureFlat,
    );
    const DisplayFeature halfFold = DisplayFeature(
      bounds: Rect.fromLTRB(375, 0, 375, 832),
      type: DisplayFeatureType.fold,
      state: DisplayFeatureState.postureHalfOpened,
    );
    const DisplayFeature cutout = DisplayFeature(
      bounds: Rect.fromLTRB(0, 0, 100, 30),
      type: DisplayFeatureType.cutout,
      state: DisplayFeatureState.unknown,
    );
    const List<DisplayFeature> all = <DisplayFeature>[hinge, flatFold, halfFold, cutout];
    Set<Rect> keptOff(final HarborHinge policy) =>
        policy.keptOff(all).map((final DisplayFeature f) => f.bounds).toSet();

    test('avoidSeparating: a hinge and a half-open fold', () {
      expect(HarborHinge.avoidSeparating.keptOff(all), <DisplayFeature>[hinge, halfFold]);
    });
    test('avoidOccluding: only a hinge', () {
      expect(HarborHinge.avoidOccluding.keptOff(all), <DisplayFeature>[hinge]);
    });
    test('always: every hinge and fold, a flat one reported half open so it splits', () {
      final List<DisplayFeature> kept = HarborHinge.always.keptOff(all);
      expect(keptOff(HarborHinge.always), <Rect>{hinge.bounds, flatFold.bounds});
      expect(kept.length, 3);
      expect(kept.every((final DisplayFeature f) => f.type != DisplayFeatureType.cutout), isTrue);
      expect(kept[1].state, DisplayFeatureState.postureHalfOpened);
    });
    test('never: nothing', () {
      expect(HarborHinge.never.keptOff(all), isEmpty);
    });
  });

  group('the nearest policy wins', () {
    testWidgets('positive control: by default a sheet keeps to one screen of a dual-screen device', (
      final tester,
    ) async {
      final Rect sheet = await _sheet(tester, await _pump(tester, device: _dual));
      expect(sheet.right, lessThanOrEqualTo(540));
    });

    testWidgets('the sea: never runs a sheet across the hinge, and leaves displayFeatures alone', (final tester) async {
      final BuildContext page = await _pump(tester, device: _dual, sea: HarborHinge.never);
      expect(MediaQuery.displayFeaturesOf(page), isNotEmpty, reason: 'a policy, not a change to the screen');
      final Rect sheet = await _sheet(tester, page);
      expect(sheet.left, 0);
      expect(sheet.right, 1114);
    });

    testWidgets('a page overrides the sea', (final tester) async {
      final Rect sheet = await _sheet(tester, await _pump(tester, device: _dual, page: HarborHinge.never));
      expect(sheet.right, 1114);
    });

    testWidgets('an overlay overrides its page and the sea', (final tester) async {
      final Rect sheet = await _sheet(
        tester,
        await _pump(tester, device: _dual, sea: HarborHinge.never),
        hinge: HarborHinge.avoidSeparating,
      );
      expect(sheet.right, lessThanOrEqualTo(540));
    });
  });

  group('each kind of fold', () {
    testWidgets('a flat fold: spanned by default, kept off with always', (final tester) async {
      expect((await _sheet(tester, await _pump(tester, device: _flat))).width, 750);
      Navigator.of(tester.element(find.byKey(const ValueKey<String>('sheet')))).pop();
      await tester.pumpAndSettle();
      expect((await _sheet(tester, await _pump(tester, device: _flat, sea: HarborHinge.always))).width, 375);
    });

    testWidgets('a half-open fold: kept off by default, spanned with avoidOccluding', (final tester) async {
      expect((await _sheet(tester, await _pump(tester, device: _halfOpen))).width, 375);
      Navigator.of(tester.element(find.byKey(const ValueKey<String>('sheet')))).pop();
      await tester.pumpAndSettle();
      expect(
        (await _sheet(tester, await _pump(tester, device: _halfOpen, sea: HarborHinge.avoidOccluding))).width,
        750,
      );
    });
  });

  group('dialogs, buoys and flares', () {
    testWidgets('a dialog: one screen by default, centred across the hinge with never', (final tester) async {
      final BuildContext page = await _pump(tester, device: _dual);
      unawaited(
        showHarborDialog<void>(
          page,
          builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('dialog'), width: 200, height: 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'dialog').right, lessThanOrEqualTo(540));
      Navigator.of(page).pop();
      await tester.pumpAndSettle();
      unawaited(
        showHarborDialog<void>(
          page,
          hinge: HarborHinge.never,
          builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('dialog'), width: 200, height: 100),
        ),
      );
      await tester.pumpAndSettle();
      expect(_rect(tester, 'dialog').center.dx, 557);
    });

    testWidgets('a buoy and a flare with never sit across the hinge; without, on one screen', (final tester) async {
      final BuildContext page = await _pump(
        tester,
        device: _dual,
        buoys: const <HarborFloat>[
          HarborFloat(
            placement: HarborAligned(alignment: Alignment.center),
            hinge: HarborHinge.never,
            child: SizedBox(key: ValueKey<String>('spanning'), width: 100, height: 40),
          ),
          HarborFloat(
            placement: HarborAligned(alignment: Alignment.topCenter),
            child: SizedBox(key: ValueKey<String>('kept'), width: 100, height: 40),
          ),
        ],
      );
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        hinge: HarborHinge.never,
        builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('flare'), width: 100, height: 20),
        duration: null,
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_rect(tester, 'spanning').center.dx, 557);
      expect(_rect(tester, 'flare').center.dx, 557);
      expect(
        _rect(tester, 'kept').right,
        lessThanOrEqualTo(540),
        reason: 'positive control: the default keeps to one screen',
      );
    });

    testWidgets('a flare takes the policy of where it was raised, not of the harbor that shows it', (
      final tester,
    ) async {
      late BuildContext raiser;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          // The page keeps the default; a harbor inside it, which is not a port, spans the hinge.
          home: HarborFrame(
            body: HarborFrame(
              hinge: HarborHinge.never,
              body: Builder(
                builder: (final BuildContext context) {
                  raiser = context;
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
        device: _dual,
      );
      HarborToasts.show(
        raiser,
        slot: HarborToastSlot.middle,
        builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('flare'), width: 100, height: 20),
        duration: null,
      );
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(_rect(tester, 'flare').center.dx, 557);
    });
  });
}
