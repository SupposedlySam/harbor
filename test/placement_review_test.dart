// Owner review of the placement engine (0.7.0): a flare never flips, and a flare's content reads
// the MediaQuery of the one screen it is on when a hinge splits the screen, as it did before the
// engine.

import 'dart:ui' show DisplayFeature;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// The dual-screen device with a coast on the right and the bottom only, so a flare on the left
/// screen has no right coast of its own: the right one belongs to the other screen.
final HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen.copyWith(
  systemEdges: const EdgeInsets.only(right: 40, bottom: 20),
);

Future<void> _settle(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('a flare never flips', () {
    testWidgets('raise asserts on an anchored placement that asks to flip', (final tester) async {
      final HarborAnchor anchor = HarborAnchor();
      addTearDown(anchor.dispose);
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40));
              },
            ),
          ),
        ),
      );
      expect(
        () => HarborToasts.show(
          page,
          placement: HarborAnchored(anchor, side: HarborAnchorSide.above, flips: true),
          builder: (final BuildContext _) => const SizedBox(),
        ),
        throwsAssertionError,
      );
      // flips: false says what a flare does anyway, and is allowed.
      final HarborToastEntry entry = HarborToasts.show(
        page,
        placement: HarborAnchored(anchor, flips: false),
        duration: null,
        builder: (final BuildContext _) => const SizedBox(),
      );
      entry.hide();
      await _settle(tester);
    });
  });

  group('a flare\'s content reads the MediaQuery of its own screen', () {
    late EdgeInsets padding;
    late List<DisplayFeature> features;
    Widget toast(final BuildContext context) {
      padding = MediaQuery.paddingOf(context);
      features = MediaQuery.displayFeaturesOf(context);
      return const SizedBox(width: 100, height: 30);
    }

    testWidgets('with no harbor, a low flare on the left screen keeps the bottom coast and drops the right', (
      final tester,
    ) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
        device: _dual,
      );
      expect(MediaQuery.paddingOf(page), const EdgeInsets.only(right: 40, bottom: 20), reason: 'positive control');
      HarborToasts.show(page, slot: HarborToastSlot.low, duration: null, builder: toast);
      await _settle(tester);
      expect(padding, const EdgeInsets.only(bottom: 20));
      expect(features, isEmpty);
    });

    testWidgets('in a harbor, the same', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        device: _dual,
      );
      HarborToasts.show(page, slot: HarborToastSlot.low, duration: null, builder: toast);
      await _settle(tester);
      expect(padding.right, 0);
      expect(features, isEmpty);
    });

    testWidgets('with hinge: never, a flare spans both screens and keeps the whole MediaQuery', (final tester) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
        device: _dual,
      );
      HarborToasts.show(page, slot: HarborToastSlot.low, hinge: HarborHinge.never, duration: null, builder: toast);
      await _settle(tester);
      expect(padding, const EdgeInsets.only(right: 40, bottom: 20));
      expect(features, hasLength(1));
    });
  });

  group('the moves the owner accepted, measured', () {
    Future<void> settle(final WidgetTester tester) => _settle(tester);

    testWidgets('right to left, a centred flare with no harbor goes to the screen where reading starts', (
      final tester,
    ) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
        device: HarborTrialDevice.dualScreenOpen,
      );
      HarborToasts.show(
        page,
        slot: HarborToastSlot.low,
        duration: null,
        builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('t'), width: 200, height: 30),
      );
      await settle(tester);
      final Rect toast = tester.getRect(find.byKey(const ValueKey<String>('t')));
      expect(toast.left, 744);
      expect(toast.right, 944);
    });

    testWidgets('a flare with no harbor by an anchor near the hinge keeps 8 off the hinge', (final tester) async {
      final HarborAnchor anchor = HarborAnchor();
      addTearDown(anchor.dispose);
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: Builder(
            builder: (final BuildContext context) {
              page = context;
              return Stack(
                children: <Widget>[
                  Positioned(
                    left: 480,
                    top: 300,
                    child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40)),
                  ),
                ],
              );
            },
          ),
        ),
        device: _dual,
      );
      HarborToasts.show(
        page,
        placement: HarborAnchored(anchor),
        duration: null,
        builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('t'), width: 200, height: 30),
      );
      await settle(tester);
      expect(tester.getRect(find.byKey(const ValueKey<String>('t'))).right, 532);
    });
  });
}
