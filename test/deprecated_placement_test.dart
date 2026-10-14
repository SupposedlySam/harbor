// The spellings HarborPlacement replaced in 0.7.0, which stay until 1.0: each forwards to a
// placement and keeps the defaults it had. Every use here is deliberate, so each is marked.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

void main() {
  late HarborAnchor anchor;
  setUp(() => anchor = HarborAnchor(debugLabel: 'anchor'));
  tearDown(() => anchor.dispose());

  test('the old enum names are the new enums', () {
    expect(HarborBuoySide.above, same(HarborAnchorSide.above));
    expect(HarborBuoyCrossAlignment.end, same(HarborCrossAlignment.end));
    expect(HarborAnchorSide.before, HarborAnchorSide.start);
  });

  test('HarborBuoy(alignment:, margin:) is an aligned placement', () {
    expect(const HarborBuoy(child: SizedBox()).placement, const HarborAligned());
    expect(
      const HarborBuoy(alignment: Alignment.topLeft, margin: EdgeInsets.zero, child: SizedBox()).placement,
      const HarborAligned(alignment: Alignment.topLeft, margin: EdgeInsets.zero),
    );
    expect(const HarborBuoy(margin: EdgeInsets.zero, child: SizedBox()).alignment, Alignment.bottomCenter);
  });

  test('HarborBuoy.anchored keeps its side above, unlike a HarborAnchored', () {
    final HarborBuoy buoy = HarborBuoy.anchored(anchor: anchor, overlap: 6, child: const SizedBox());
    expect(buoy.placement, HarborAnchored(anchor, side: HarborAnchorSide.above, overlap: 6));
    expect(buoy.side, HarborAnchorSide.above);
    expect(buoy.anchor, anchor);
    expect(buoy.margin, const EdgeInsets.all(8));
  });

  test('a portal buoy keeps its side above, and flips', () {
    final HarborPortalBuoy portal = HarborPortalBuoy(
      controller: OverlayPortalController(),
      gap: 4,
      buoyBuilder: (final BuildContext _) => const SizedBox(),
      child: const SizedBox(),
    );
    expect(portal.placement, const HarborAnchored(null, side: HarborAnchorSide.above, gap: 4));
    expect(portal.flips, isTrue);
    expect(
      HarborPortalBuoy(
        controller: OverlayPortalController(),
        buoyBuilder: (final BuildContext _) => const SizedBox(),
        child: const SizedBox(),
      ).placement.side,
      HarborAnchorSide.above,
      reason: 'given nothing at all, as before placements',
    );
  });

  test('a placement and the old parameters are not given together', () {
    expect(
      () => HarborBuoy(placement: const HarborAligned(), alignment: Alignment.center, child: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => HarborPortalBuoy(
        controller: OverlayPortalController(),
        placement: const HarborAnchored(null),
        side: HarborAnchorSide.end,
        buoyBuilder: (final BuildContext _) => const SizedBox(),
        child: const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  testWidgets('raise forwards the old parameters to a placement, with their old defaults', (final tester) async {
    late BuildContext page;
    await tester.pumpSeaTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
        home: Harbor(
          body: Builder(builder: (final BuildContext context) {
            page = context;
            return Center(child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40)));
          }),
        ),
      ),
    );
    final HarborFlareEntry anchored = HarborFlares.raise(page, anchor: anchor, gap: 2, duration: null, builder: (final BuildContext _) => const SizedBox());
    expect(anchored.placement, HarborAnchored(anchor, gap: 2));
    expect(anchored.side, HarborAnchorSide.below);
    expect(anchored.gap, 2);
    expect(anchored.margin, const EdgeInsets.all(8));
    final HarborFlareEntry low = HarborFlares.raise(
      page,
      slot: HarborFlareSlot.low,
      margin: const EdgeInsetsDirectional.only(start: 4),
      duration: null,
      builder: (final BuildContext _) => const SizedBox(),
    );
    expect(low.placement, const HarborAligned(margin: EdgeInsets.only(left: 4)));
    expect(low.alignment, Alignment.bottomCenter);
    expect(
      () => HarborFlares.raise(page, placement: const HarborAligned(), margin: EdgeInsets.zero, builder: (final BuildContext _) => const SizedBox()),
      throwsAssertionError,
    );
    anchored.lower();
    low.lower();
    await tester.pump(const Duration(seconds: 1));
  });
}
