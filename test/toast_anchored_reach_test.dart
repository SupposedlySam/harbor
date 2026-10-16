// HarborFlares.raise(anchor:, reachesCoast: true) in a frame. An anchored toast sits by its
// anchor in the room, so it covers no system edge, and reachesCoast has no effect on it, as with
// no frame above it. Before 0.6.3 the frame's float layer still treated it as reaching: it was
// laid out under the system edges, wider than the room it is placed in, and its content was
// handed the system edges it reached over as its padding. That spelling is gone: an anchored toast
// given reachesSystemEdges is an assert (placement_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _landscape = HarborTrialDevice.iPhone17Landscape;

/// A toast as wide as it may be, so the room it is laid out in shows in its rect.
Widget _toast(final String key, final ValueSetter<EdgeInsets> onPadding) => Builder(
  builder: (final BuildContext context) {
    onPadding(MediaQuery.paddingOf(context));
    return SizedBox(key: ValueKey<String>(key), width: double.infinity, height: 30);
  },
);

void main() {
  late HarborAnchor anchor;
  setUp(() => anchor = HarborAnchor(debugLabel: 'anchor'));
  tearDown(() => anchor.dispose());

  Future<BuildContext> pump(final WidgetTester tester) async {
    late BuildContext page;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
        home: HarborFrame(
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return Center(
                child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40)),
              );
            },
          ),
        ),
      ),
      device: _landscape,
    );
    await tester.pump();
    return page;
  }

  Future<void> settle(final WidgetTester tester) async {
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('the device has a side system edge to cover', (final tester) async {
    final BuildContext page = await pump(tester);
    final EdgeInsets padding = MediaQuery.paddingOf(page);
    expect(padding.left, greaterThan(0));
    expect(padding.right, greaterThan(0));
  });

  testWidgets('an aligned low toast with reachesSystemEdges and no margin is still handed the whole side system edges', (
    final tester,
  ) async {
    final BuildContext page = await pump(tester);
    final EdgeInsets systemEdges = MediaQuery.paddingOf(page);
    EdgeInsets? padding;
    HarborToasts.show(
      page,
      placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
      reachesSystemEdges: true,
      builder: (final BuildContext _) => _toast('low', (final EdgeInsets p) => padding = p),
      timing: HarborToastTiming.untilHidden,
    );
    await settle(tester);
    expect(padding!.left, systemEdges.left);
    expect(padding!.right, systemEdges.right);
  });
}
