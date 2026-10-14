// HarborPlacement (0.7.0): one placement value for buoys, portal buoys and flares, placed by one
// engine. The deprecated spellings it replaces are covered in deprecated_placement_test.dart.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _box(final String key, {final double width = 200, final double height = 30}) =>
    SizedBox(key: ValueKey<String>(key), width: width, height: height);

Future<void> _settle(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<BuildContext> _page(
  final WidgetTester tester, {
  final List<HarborBuoy> buoys = const <HarborBuoy>[],
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
  final Widget? body,
  final bool harbor = true,
}) async {
  late BuildContext page;
  final Widget content = Builder(builder: (final BuildContext context) {
    page = context;
    return body ?? const SizedBox.expand();
  });
  await tester.pumpSeaTrial(
    MaterialApp(
      builder: harbor ? (final BuildContext context, final Widget? child) => HarborSea(child: child!) : null,
      home: harbor ? Harbor(buoys: buoys, body: content) : content,
    ),
    device: device,
  );
  await tester.pump();
  return page;
}

void main() {
  group('the value', () {
    test('aligned and anchored placements are equal by value', () {
      final HarborAnchor anchor = HarborAnchor();
      addTearDown(anchor.dispose);
      expect(const HarborAligned(), const HarborPlacement.aligned());
      expect(const HarborAligned(alignment: Alignment.topLeft).hashCode, const HarborAligned(alignment: Alignment.topLeft).hashCode);
      expect(const HarborAligned(alignment: Alignment.topLeft), isNot(const HarborAligned()));
      expect(HarborAnchored(anchor, gap: 4), HarborPlacement.anchored(anchor, gap: 4));
      expect(HarborAnchored(anchor, gap: 4).hashCode, HarborAnchored(anchor, gap: 4).hashCode);
      expect(HarborAnchored(anchor), isNot(HarborAnchored(anchor, flips: true)));
      expect(HarborAnchored(anchor), isNot(HarborAnchored(HarborAnchor()..dispose())));
    });

    test('the defaults: aligned at bottom centre 16 in, anchored below 8 away and 8 in', () {
      const HarborAligned aligned = HarborAligned();
      expect(aligned.alignment, Alignment.bottomCenter);
      expect(aligned.margin, const EdgeInsets.all(16));
      const HarborAnchored anchored = HarborAnchored(null);
      expect(anchored.side, HarborAnchorSide.below);
      expect(anchored.gap, 8);
      expect(anchored.overlap, 0);
      expect(anchored.crossAlignment, HarborCrossAlignment.center);
      expect(anchored.crossOffset, 0);
      expect(anchored.flips, isNull);
      expect(anchored.margin, const EdgeInsets.all(8));
    });

    test('a placement shows only what differs from its defaults', () {
      expect(const HarborAligned().toString(), 'HarborAligned');
      expect(
        const HarborAligned(alignment: AlignmentDirectional.bottomEnd, margin: EdgeInsets.zero).toString(),
        'HarborAligned(alignment: AlignmentDirectional.bottomEnd, margin: EdgeInsets.zero)',
      );
      expect(const HarborAnchored(null).toString(), 'HarborAnchored');
      expect(
        const HarborAnchored(null, side: HarborAnchorSide.above, overlap: 6, flips: false).toString(),
        'HarborAnchored(side: above, overlap: 6.0, no flip)',
      );
    });

    test('a buoy and a portal buoy show their placement', () {
      expect(
        const HarborBuoy(placement: HarborAligned(alignment: Alignment.topCenter), child: SizedBox()).toString(),
        'HarborBuoy(placement: HarborAligned(alignment: Alignment.topCenter))',
      );
      final DiagnosticPropertiesBuilder portal = DiagnosticPropertiesBuilder();
      HarborPortalBuoy(
        controller: OverlayPortalController(),
        placement: const HarborAnchored(null, side: HarborAnchorSide.end),
        buoyBuilder: (final BuildContext _) => const SizedBox(),
        child: const SizedBox(),
      ).debugFillProperties(portal);
      expect(
        portal.properties.where((final DiagnosticsNode p) => !p.isFiltered(DiagnosticLevel.info)).map((final DiagnosticsNode p) => p.toString()),
        contains('placement: HarborAnchored(side: end)'),
      );
    });
  });

  group('one rule for the hinge: the screen first, then the margin', () {
    // Before 0.7.0 an aligned buoy in a harbor took its margin off the water before splitting it
    // at the hinge, so it kept no margin off the hinge, and was centred 8 nearer it than an aligned
    // flare with no harbor, an anchored buoy or a portal buoy, which all split first.
    testWidgets('right to left, an aligned buoy on the hinge goes to the right screen, where reading starts', (final tester) async {
      await tester.pumpSeaTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) =>
              Directionality(textDirection: TextDirection.rtl, child: HarborSea(child: child!)),
          home: const Harbor(
            buoys: <HarborBuoy>[HarborBuoy(placement: HarborAligned(), child: SizedBox(key: ValueKey<String>('buoy'), width: 200, height: 30))],
            body: SizedBox.expand(),
          ),
        ),
        device: _dual,
      );
      await tester.pump();
      // The right screen is 574 to 1114: 16 in from each side, 590 to 1098.
      expect(_rect(tester, 'buoy').center.dx, 844);
    });

    testWidgets('an aligned buoy keeps its margin off the hinge as off an edge', (final tester) async {
      await _page(tester, device: _dual, buoys: const <HarborBuoy>[HarborBuoy(placement: HarborAligned(), child: SizedBox(key: ValueKey<String>('buoy'), width: 200, height: 30))]);
      final Rect buoy = _rect(tester, 'buoy');
      // The left screen (reading starts there) is 0 to 540: 16 in from each side, 16 to 524.
      expect(buoy.center.dx, 270);
      expect(buoy.left, 170);
    });

    testWidgets('an aligned buoy as wide as it may be stops 16 short of the hinge', (final tester) async {
      await _page(tester, device: _dual, buoys: const <HarborBuoy>[
        HarborBuoy(placement: HarborAligned(), child: SizedBox(key: ValueKey<String>('buoy'), width: double.infinity, height: 30)),
      ]);
      final Rect buoy = _rect(tester, 'buoy');
      expect(buoy.left, 16);
      expect(buoy.right, 524);
    });

    testWidgets('an aligned flare in a harbor and one with no harbor land in the same place', (final tester) async {
      final BuildContext inHarbor = await _page(tester, device: _dual);
      HarborFlares.raise(inHarbor, slot: HarborFlareSlot.low, duration: null, builder: (final BuildContext _) => _box('flare'));
      await _settle(tester);
      final Rect harbor = _rect(tester, 'flare');
      final BuildContext bare = await _page(tester, device: _dual, harbor: false);
      HarborFlares.raise(bare, slot: HarborFlareSlot.low, duration: null, builder: (final BuildContext _) => _box('bare'));
      await _settle(tester);
      expect(_rect(tester, 'bare').center.dx, harbor.center.dx);
      expect(harbor.center.dx, 270);
    });
  });

  group('the new spellings', () {
    late HarborAnchor anchor;
    setUp(() => anchor = HarborAnchor(debugLabel: 'anchor'));
    tearDown(() => anchor.dispose());

    Widget anchored() => Stack(children: <Widget>[
      Positioned(left: 100, top: 300, child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40))),
    ]);

    testWidgets('an anchored buoy sits below its anchor by default', (final tester) async {
      await _page(tester, body: anchored(), buoys: <HarborBuoy>[HarborBuoy(placement: HarborAnchored(anchor), child: _box('buoy', width: 80))]);
      await tester.pump();
      final Rect buoy = _rect(tester, 'buoy');
      expect(buoy.top, 348);
      expect(buoy.center.dx, 120);
    });

    testWidgets('an anchored buoy keeps its side with no room on it: held in the water, not flipped', (final tester) async {
      await _page(
        tester,
        body: Stack(children: <Widget>[
          Positioned(left: 100, bottom: 60, child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40))),
        ]),
        buoys: <HarborBuoy>[HarborBuoy(placement: HarborAnchored(anchor), child: _box('buoy', width: 80, height: 100))],
      );
      await tester.pump();
      // No room below an anchor ending 60 from the bottom: it is pushed up to the clear water's
      // bottom, 8 in (874 less the 34 home indicator), where a portal buoy would flip above it.
      expect(_rect(tester, 'buoy').bottom, 874 - 34 - 8);
    });

    testWidgets('an anchored buoy honours within, as an aligned one does', (final tester) async {
      await _page(tester, body: anchored(), buoys: <HarborBuoy>[
        HarborBuoy(placement: HarborAnchored(anchor), within: const Rect.fromLTRB(110, 0, 400, 800), child: _box('buoy', width: 80)),
      ]);
      await tester.pump();
      // Centred under the anchor it would start at 80; kept 8 inside within, it starts at 118.
      expect(_rect(tester, 'buoy').left, 118);
    });

    testWidgets('an anchored flare can overlap its anchor and move across it', (final tester) async {
      final BuildContext page = await _page(tester, body: anchored());
      final HarborFlareEntry entry = HarborFlares.raise(
        page,
        placement: HarborAnchored(anchor, overlap: 4, crossOffset: 10),
        duration: null,
        builder: (final BuildContext _) => _box('flare', width: 80),
      );
      await _settle(tester);
      final Rect flare = _rect(tester, 'flare');
      expect(flare.top, 344);
      expect(flare.center.dx, 130);
      expect(entry.anchor, anchor);
      expect(entry.side, HarborAnchorSide.below);
      expect(entry.placement, HarborAnchored(anchor, overlap: 4, crossOffset: 10));
    });

    testWidgets('a flare resolves its placement in the reading direction of the page that raised it', (final tester) async {
      final BuildContext page = await _page(tester);
      final HarborFlareEntry entry = HarborFlares.raise(
        page,
        placement: const HarborAligned(
          alignment: AlignmentDirectional.bottomEnd,
          margin: EdgeInsetsDirectional.only(end: 30),
        ),
        duration: null,
        builder: (final BuildContext _) => _box('flare', width: 80),
      );
      await _settle(tester);
      expect(entry.placement, const HarborAligned(alignment: Alignment.bottomRight, margin: EdgeInsets.only(right: 30)));
      expect(_rect(tester, 'flare').right, 402 - 30);
    });

    testWidgets('a portal buoy with no placement still sits above its child, as before placements', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      await _page(
        tester,
        body: Center(
          child: HarborPortalBuoy(
            controller: menu,
            buoyBuilder: (final BuildContext _) => _box('menu', width: 80),
            child: _box('row', width: 120, height: 40),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      await tester.pump();
      expect(_rect(tester, 'menu').bottom, _rect(tester, 'row').top - 8);
    });

    testWidgets('a portal buoy placed by HarborAnchored(null) sits below its child', (final tester) async {
      final OverlayPortalController menu = OverlayPortalController();
      await _page(
        tester,
        body: Center(
          child: HarborPortalBuoy(
            controller: menu,
            placement: const HarborAnchored(null),
            buoyBuilder: (final BuildContext _) => _box('menu', width: 80),
            child: _box('row', width: 120, height: 40),
          ),
        ),
      );
      menu.show();
      await tester.pump();
      await tester.pump();
      expect(_rect(tester, 'menu').top, _rect(tester, 'row').bottom + 8);
    });

    testWidgets('a portal buoy flips by default, and not with flips: false', (final tester) async {
      Future<Rect> menuBy(final bool? flips) async {
        final OverlayPortalController menu = OverlayPortalController();
        await _page(
          tester,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HarborPortalBuoy(
              controller: menu,
              placement: HarborAnchored(null, flips: flips),
              buoyBuilder: (final BuildContext _) => _box('menu', width: 80, height: 200),
              child: _box('row', width: 120, height: 40),
            ),
          ),
        );
        menu.show();
        await tester.pump();
        await tester.pump();
        return _rect(tester, 'menu');
      }

      final Rect flipped = await menuBy(null);
      expect(flipped.bottom, _rect(tester, 'row').top - 8, reason: 'no room below, so above, 8 away');
      final Rect kept = await menuBy(false);
      expect(kept.bottom, 874 - 34 - 8, reason: 'held below, pushed up only as far as the clear water needs');
    });

    testWidgets('slot and placement are exclusive, and an anchored flare does not reach the coast', (final tester) async {
      final BuildContext page = await _page(tester, body: anchored());
      expect(
        () => HarborFlares.raise(page, slot: HarborFlareSlot.low, placement: const HarborAligned(), builder: (final BuildContext _) => const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => HarborFlares.raise(page, placement: HarborAnchored(anchor), reachesCoast: true, builder: (final BuildContext _) => const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => HarborFlares.raise(page, placement: const HarborAnchored(null), builder: (final BuildContext _) => const SizedBox()),
        throwsAssertionError,
      );
    });

    testWidgets('a buoy placed by an anchor needs one', (final tester) async {
      await _page(tester, buoys: const <HarborBuoy>[HarborBuoy(placement: HarborAnchored(null), child: SizedBox())]);
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('a flare with no harbor that reaches the coast', () {
    // Before 0.7.0 a flare with no harbor above it handed its content the whole coast on its
    // edges whatever its margin, though with a margin it covers less of it; in a harbor it was
    // handed only what it covers. Both now hand over what it covers.
    testWidgets('is handed only the coast it covers, its margin taken off', (final tester) async {
      EdgeInsets? padding;
      final BuildContext page = await _page(tester, harbor: false, device: HarborTrialDevice.iPhone17Landscape);
      HarborFlares.raise(
        page,
        placement: const HarborAligned(margin: EdgeInsets.all(10)),
        reachesCoast: true,
        duration: null,
        builder: (final BuildContext context) {
          padding = MediaQuery.paddingOf(context);
          return _box('bar', width: double.infinity);
        },
      );
      await _settle(tester);
      // The phone on its side has 62 at each side and 21 at the bottom.
      expect(_rect(tester, 'bar'), const Rect.fromLTRB(10, 402 - 10 - 30, 874 - 10, 402 - 10));
      expect(padding, const EdgeInsets.fromLTRB(52, 0, 52, 11));
    });
  });
}
