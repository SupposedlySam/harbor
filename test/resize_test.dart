// What a resize (a turn, a foldable opening) must leave behind: nothing laid out against the
// old shape. Found by the rotation audit; each test failed on the code before its fix.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// Puts the view in [device]'s shape, keyboard down, as a resize would. The view takes physical pixels, at
/// the pixel ratio the trial put on it.
void _resizeTo(final WidgetTester tester, final HarborTrialDevice device) {
  final double ratio = tester.view.devicePixelRatio;
  final EdgeInsets edges = device.systemEdges * ratio;
  tester.view
    ..physicalSize = device.size * ratio
    ..padding = FakeViewPadding(left: edges.left, top: edges.top, right: edges.right, bottom: edges.bottom)
    ..viewPadding = FakeViewPadding(left: edges.left, top: edges.top, right: edges.right, bottom: edges.bottom)
    ..viewInsets = FakeViewPadding.zero;
}

void main() {
  // Failed before: for the first frame after a turn, the page under a sheet that covers it was laid out
  // against the cover the sheet had in the old orientation, in pixels: 365 of portrait's 874 is
  // nearly all of landscape's 402, and the page's content overflowed by 83.
  testWidgets('a page under a sheet that covers it is not laid out against the old orientation after a turn', (
    final tester,
  ) async {
    late BuildContext page;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const HarborClear(
                child: Column(children: <Widget>[SizedBox(key: ValueKey<String>('title'), height: 120)]),
              );
            },
          ),
        ),
      ),
    );
    unawaited(
      showHarborSheet<void>(
        page,
        coversPage: true,
        barrier: HarborBarrier.none,
        builder: (final BuildContext _) => HarborSheet.draggable(
          extent: const HarborSheetExtent(rest: 0.45),
          builder: (final BuildContext context, final ScrollController controller) => HarborScrollView(
            controller: controller,
            slivers: const <Widget>[SliverToBoxAdapter(child: SizedBox(height: 2000))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'positive control: portrait lays out cleanly');

    _resizeTo(tester, HarborTrialDevice.iPhone17Landscape);
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'the first landscape frame does not overflow');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // Failed before: the toast kept the room captured when it was shown, so after the
  // foldable opened it stayed boxed into the old 382-wide cover screen.
  testWidgets('a toast follows the room of the frame that showed it when the screen grows', (
    final tester,
  ) async {
    late BuildContext page;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          top: const <HarborBar>[HarborBar.overlay(child: SizedBox(width: double.infinity, height: 50))],
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
    HarborToasts.show(
      page,
      slot: HarborToastSlot.low,
      builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('toast'), width: 100, height: 30),
      timing: HarborToastTiming.untilHidden,
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
