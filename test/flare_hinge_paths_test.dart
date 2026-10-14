// A flare's hinge policy on every path it can be placed by: in a harbor or an overlay, at an
// alignment or by an anchor. Before 0.6.2 two of the four ignored it: an anchored flare in a
// harbor (and every HarborBuoy.anchored, which it is shown as) sat across a hinge by an anchor
// near one, and an aligned flare with no harbor around it took the whole width of both screens.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _toast(final String key) => SizedBox(key: ValueKey<String>(key), width: 200, height: 30);

/// A 40 x 40 anchor whose right edge is 20 short of the hinge, so a 200-wide toast centred
/// below it reaches across.
Widget _anchored(final HarborAnchor anchor) => Stack(
  children: <Widget>[
    Positioned(
      left: 480,
      top: 300,
      child: HarborAnchorPoint(anchor: anchor, child: const SizedBox(width: 40, height: 40)),
    ),
  ],
);

Future<void> _settle(final WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late HarborAnchor anchor;
  setUp(() => anchor = HarborAnchor(debugLabel: 'anchor'));
  tearDown(() => anchor.dispose());

  group('in a harbor, by an anchor', () {
    Future<BuildContext> pump(
      final WidgetTester tester, {
      final List<HarborFloat> buoys = const <HarborFloat>[],
    }) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            floats: buoys,
            body: Builder(
              builder: (final BuildContext context) {
                page = context;
                return _anchored(anchor);
              },
            ),
          ),
        ),
        device: _dual,
      );
      await tester.pump();
      return page;
    }

    testWidgets('an anchored buoy keeps to the screen its anchor is on, 8 in from the hinge', (final tester) async {
      await pump(
        tester,
        buoys: <HarborFloat>[
          HarborFloat(
            placement: HarborAnchored(anchor, side: HarborAnchorSide.below),
            child: _toast('buoy'),
          ),
        ],
      );
      final Rect buoy = _rect(tester, 'buoy');
      expect(buoy.right, 532);
      expect(buoy.top, 348, reason: 'still below its anchor, 8 away');
    });

    testWidgets('with never, an anchored buoy is centred on its anchor across the hinge', (final tester) async {
      await pump(
        tester,
        buoys: <HarborFloat>[
          HarborFloat(
            placement: HarborAnchored(anchor, side: HarborAnchorSide.below),
            hinge: HarborHinge.never,
            child: _toast('buoy'),
          ),
        ],
      );
      expect(_rect(tester, 'buoy').center.dx, 500);
    });

    testWidgets('an anchored flare keeps to its anchor\'s screen, and spans with never', (final tester) async {
      final BuildContext page = await pump(tester);
      final HarborToastEntry kept = HarborToasts.show(
        page,
        placement: HarborAnchored(anchor),
        duration: null,
        builder: (final BuildContext _) => _toast('kept'),
      );
      await _settle(tester);
      expect(_rect(tester, 'kept').right, 532);
      kept.hide();
      await _settle(tester);
      HarborToasts.show(
        page,
        placement: HarborAnchored(anchor),
        hinge: HarborHinge.never,
        duration: null,
        builder: (final BuildContext _) => _toast('spans'),
      );
      await _settle(tester);
      expect(_rect(tester, 'spans').center.dx, 500);
    });
  });

  group('in an overlay, with no harbor', () {
    Future<BuildContext> pump(final WidgetTester tester, {final bool withAnchor = false}) async {
      late BuildContext page;
      await tester.pumpHarborTrial(
        MaterialApp(
          home: Builder(
            builder: (final BuildContext context) {
              page = context;
              return withAnchor ? _anchored(anchor) : const SizedBox.expand();
            },
          ),
        ),
        device: _dual,
      );
      return page;
    }

    bool oneScreen(final Rect r) => r.right <= 540 || r.left >= 574;

    for (final bool reachesCoast in <bool>[false, true]) {
      testWidgets('an aligned flare keeps to one screen, and spans with never (reachesCoast: $reachesCoast)', (
        final tester,
      ) async {
        final BuildContext page = await pump(tester);
        final HarborToastEntry kept = HarborToasts.show(
          page,
          slot: HarborToastSlot.low,
          reachesSystemEdges: reachesCoast,
          duration: null,
          builder: (final BuildContext _) => _toast('kept'),
        );
        await _settle(tester);
        final Rect rect = _rect(tester, 'kept');
        expect(oneScreen(rect), isTrue, reason: '$rect');
        expect(rect.bottom, lessThanOrEqualTo(_dual.size.height - 16), reason: 'still at the low slot, off the bottom');
        expect(rect.bottom, greaterThan(_dual.size.height / 2));
        kept.hide();
        await _settle(tester);
        HarborToasts.show(
          page,
          slot: HarborToastSlot.low,
          reachesSystemEdges: reachesCoast,
          hinge: HarborHinge.never,
          duration: null,
          builder: (final BuildContext _) => _toast('spans'),
        );
        await _settle(tester);
        expect(_rect(tester, 'spans').center.dx, 557);
      });
    }

    testWidgets('an anchored flare keeps to its anchor\'s screen (positive control: already did)', (
      final tester,
    ) async {
      final BuildContext page = await pump(tester, withAnchor: true);
      HarborToasts.show(
        page,
        placement: HarborAnchored(anchor),
        duration: null,
        builder: (final BuildContext _) => _toast('kept'),
      );
      await _settle(tester);
      expect(_rect(tester, 'kept').right, 532);
    });
  });
}
