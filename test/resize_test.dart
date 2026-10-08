// What a resize (a turn, a foldable opening) must leave behind: nothing laid out against the
// old shape. Found by the rotation audit; each test failed on the code before its fix.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// Puts the view in [device]'s shape, keyboard down, as a resize would.
void _resizeTo(final WidgetTester tester, final HarborTrialDevice device) {
  tester.view
    ..physicalSize = device.size
    ..padding = FakeViewPadding(left: device.coast.left, top: device.coast.top, right: device.coast.right, bottom: device.coast.bottom)
    ..viewPadding = FakeViewPadding(left: device.coast.left, top: device.coast.top, right: device.coast.right, bottom: device.coast.bottom)
    ..viewInsets = FakeViewPadding.zero;
}

void main() {
  // Failed before: for the first frame after a turn, the page under a breakwater sheet was laid out
  // against the cover the sheet had in the old orientation, in pixels: 365 of portrait's 874 is
  // nearly all of landscape's 402, and the page's content overflowed by 83.
  testWidgets('a page under a breakwater sheet is not laid out against the old orientation after a turn', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const HarborMoored(child: Column(children: <Widget>[SizedBox(key: ValueKey<String>('title'), height: 120)]));
            },
          ),
        ),
      ),
    );
    unawaited(showHarborSheet<void>(
      page,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext _) => HarborSheet.draggable(
        extent: const HarborSheetExtent(rest: 0.45),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'positive control: portrait lays out cleanly');

    _resizeTo(tester, HarborTrialDevice.iPhone17Landscape);
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'the first landscape frame does not overflow');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // Failed before: the signal kept the clear water captured when it was raised, so after the
  // foldable opened it stayed boxed into the old 382-wide cover screen.
  testWidgets('a signal follows the clear water of the harbor that raised it when the screen grows', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          top: const <HarborDock>[HarborDock.pier(child: SizedBox(width: double.infinity, height: 50))],
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
      device: HarborTrialDevice.dualScreenCover,
    );
    HarborSignals.raise(
      page,
      slot: HarborSignalSlot.low,
      duration: null,
      builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('toast'), width: 100, height: 30),
    );
    await tester.pumpAndSettle();
    final double coverCenter = tester.getRect(find.byKey(const ValueKey<String>('toast'))).center.dx;

    _resizeTo(tester, HarborTrialDevice.foldableOpen);
    await tester.pumpAndSettle();
    final double openCenter = tester.getRect(find.byKey(const ValueKey<String>('toast'))).center.dx;
    final double width = HarborTrialDevice.foldableOpen.size.width;
    expect(openCenter, isNot(coverCenter), reason: 'it moved with the screen');
    expect(openCenter, moreOrLessEquals(width / 2, epsilon: 1), reason: 'centred in the open screen, coast and all');
  });
}
