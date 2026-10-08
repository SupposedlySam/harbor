// What harbor shows over a page keeps off a hinge, as Material's dialogs and bottom sheets do.
// Found by the foldables audit: every one of these crossed the hinge before, and the trial
// devices declared no hinge, so no test could have seen it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _device = HarborTrialDevice.dualScreenOpen;
final Rect _hinge = _device.displayFeatures.single.bounds;

Future<BuildContext> _pump(final WidgetTester tester, {final List<HarborBuoy> buoys = const <HarborBuoy>[]}) async {
  late BuildContext page;
  await tester.pumpSeaTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
      home: Harbor(
        buoys: buoys,
        body: Builder(
          builder: (final BuildContext context) {
            page = context;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
    device: _device,
  );
  return page;
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

void main() {
  testWidgets("the trial device declares its hinge, and Material's sheet keeps off it (positive control)", (final tester) async {
    final BuildContext page = await _pump(tester);
    expect(MediaQuery.displayFeaturesOf(page), isNotEmpty);
    unawaited(showModalBottomSheet<void>(context: page, builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('material'), height: 200)));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'material').overlaps(_hinge), isFalse);
  });

  for (final HarborSheetBarrier barrier in <HarborSheetBarrier>[HarborSheetBarrier.dismissible, HarborSheetBarrier.none]) {
    testWidgets('a sheet keeps off the hinge (barrier: ${barrier.name})', (final tester) async {
      final BuildContext page = await _pump(tester);
      unawaited(showHarborSheet<void>(
        page,
        barrier: barrier,
        builder: (final BuildContext _) => const HarborSheet(body: SizedBox(key: ValueKey<String>('sheet'), height: 200)),
      ));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'sheet').overlaps(_hinge), isFalse);
    });
  }

  testWidgets('a dialog keeps off the hinge', (final tester) async {
    final BuildContext page = await _pump(tester);
    unawaited(showHarborDialog<void>(page, builder: (final BuildContext _) => const Center(child: SizedBox(key: ValueKey<String>('dialog'), width: 280, height: 160))));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'dialog').overlaps(_hinge), isFalse);
  });

  testWidgets("a dialog opens on the screen nearest its anchorPoint, as showDialog's does", (final tester) async {
    final BuildContext page = await _pump(tester);
    unawaited(showHarborDialog<void>(
      page,
      anchorPoint: Offset(_hinge.right + 1, 0),
      builder: (final BuildContext _) => const Center(child: SizedBox(key: ValueKey<String>('dialog'), width: 280, height: 160)),
    ));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'dialog').left, greaterThanOrEqualTo(_hinge.right));
  });

  testWidgets('a signal keeps off the hinge', (final tester) async {
    final BuildContext page = await _pump(tester);
    HarborSignals.raise(page, slot: HarborSignalSlot.low, duration: null, builder: (final BuildContext _) => const SizedBox(key: ValueKey<String>('toast'), width: 200, height: 40));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'toast').overlaps(_hinge), isFalse);
  });

  testWidgets('a centred buoy keeps off the hinge', (final tester) async {
    await _pump(tester, buoys: const <HarborBuoy>[
      HarborBuoy(alignment: Alignment.center, child: SizedBox(key: ValueKey<String>('buoy'), width: 120, height: 40)),
    ]);
    expect(_rect(tester, 'buoy').overlaps(_hinge), isFalse);
  });

  testWidgets('on a flat fold, which has no width, a centred buoy is free to span it', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          buoys: const <HarborBuoy>[HarborBuoy(alignment: Alignment.center, child: SizedBox(key: ValueKey<String>('buoy'), width: 120, height: 40))],
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
      device: HarborTrialDevice.foldableOpen,
    );
    expect(MediaQuery.displayFeaturesOf(page), isNotEmpty, reason: 'the fold is reported');
    expect(_rect(tester, 'buoy').center.dx, HarborTrialDevice.foldableOpen.size.width / 2);
  });
}
