// HarborFlares.raise(anchor:, reachesCoast: true) in a harbor. An anchored flare sits by its
// anchor in the clear water, so it covers no coast, and reachesCoast has no effect on it, as with
// no harbor above it. Before 0.6.3 the harbor's buoy layer still treated it as reaching: it was
// laid out in the open water, wider than the clear water it is placed in, and its content was
// handed the coast that open water reached over as its padding.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _landscape = HarborTrialDevice.iPhone17Landscape;

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

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

  testWidgets('the device has a side coast to cover', (final tester) async {
    final BuildContext page = await pump(tester);
    final EdgeInsets padding = MediaQuery.paddingOf(page);
    expect(padding.left, greaterThan(0));
    expect(padding.right, greaterThan(0));
  });

  testWidgets('an anchored flare with reachesCoast is laid out and padded as without it', (final tester) async {
    final BuildContext page = await pump(tester);
    EdgeInsets? plain;
    final HarborToastEntry first = HarborToasts.show(
      page,
      placement: HarborAnchored(anchor),
      builder: (final BuildContext _) => _toast('plain', (final EdgeInsets p) => plain = p),
      timing: HarborToastTiming.untilHidden,
    );
    await settle(tester);
    final Rect without = _rect(tester, 'plain');
    first.hide();
    await settle(tester);

    EdgeInsets? reaching;
    // The deprecated spelling, on purpose: reachesCoast with an anchor stays a no-op there, as it was
    // since 0.6.3. Spelled with a HarborAnchored placement it is an assert (placement_test.dart).
    // ignore: deprecated_member_use_from_same_package
    HarborToasts.raise(
      page,
      // ignore: deprecated_member_use_from_same_package
      anchor: anchor,
      // ignore: deprecated_member_use_from_same_package
      reachesCoast: true,
      builder: (final BuildContext _) => _toast('reaching', (final EdgeInsets p) => reaching = p),
      timing: HarborToastTiming.untilHidden,
    );
    await settle(tester);

    // Its content keeps the page's padding, as the flare raised without reachesCoast does, rather
    // than being handed a coast it covers.
    expect(reaching, plain);
    expect(_rect(tester, 'reaching'), without);
  });

  testWidgets('an aligned low flare with reachesCoast and no margin is still handed the whole side coast', (
    final tester,
  ) async {
    final BuildContext page = await pump(tester);
    final EdgeInsets coast = MediaQuery.paddingOf(page);
    EdgeInsets? padding;
    HarborToasts.show(
      page,
      placement: HarborAligned(alignment: HarborToastSlot.low.alignment, margin: EdgeInsets.zero),
      reachesSystemEdges: true,
      builder: (final BuildContext _) => _toast('low', (final EdgeInsets p) => padding = p),
      timing: HarborToastTiming.untilHidden,
    );
    await settle(tester);
    expect(padding!.left, coast.left);
    expect(padding!.right, coast.right);
  });
}
