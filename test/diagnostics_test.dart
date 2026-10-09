import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// The properties the inspector shows by default: everything not filtered out
/// at [DiagnosticLevel.info], which is where a property equal to its default goes.
List<String> _shown(final Diagnosticable subject) => subject
    .toDiagnosticsNode()
    .getProperties()
    .where((final DiagnosticsNode property) => !property.isFiltered(DiagnosticLevel.info))
    .map((final DiagnosticsNode property) => property.toString())
    .toList();

const Widget _child = SizedBox.shrink();

void main() {
  group('value classes describe themselves', () {
    test('a dock names its kind and shows only what differs from the defaults', () {
      expect(const HarborDock.pier(child: _child).toString(), 'HarborDock.pier');
      expect(
        const HarborDock.quay(
          tide: HarborTideStance.float,
          state: HarborDockState.withdrawn,
          minimum: 16.0,
          withdrawsAtHighTide: true,
          debugLabel: 'tab bar',
          backdrop: _child,
          child: _child,
        ).toString(),
        'HarborDock.quay(tide: float, state: withdrawn, has backdrop, withdraws at high tide, minimum: 16.0, '
        'debugLabel: "tab bar")',
      );
    });

    test('a wake names its kind and shows its non-default sizes', () {
      expect(HarborWake.none.toString(), 'HarborWake.none');
      expect(const HarborWake.fade().toString(), 'HarborWake.fade');
      expect(
        const HarborWake.fade(length: 12.0, blurSigma: 8.0).toString(),
        'HarborWake.fade(length: 12.0, blurSigma: 8.0)',
      );
      expect(const HarborWake.hairline(thickness: 0.5).toString(), 'HarborWake.hairline(thickness: 0.5)');
    });

    test('a coast names where it comes from', () {
      expect(HarborCoast.ambient.toString(), 'HarborCoast.ambient');
      expect(HarborCoast.none.toString(), 'HarborCoast.none');
      expect(
        const HarborCoast.fixed(EdgeInsetsDirectional.only(top: 24.0), calmTide: true).toString(),
        'HarborCoast.fixed(fixedInsets: EdgeInsets(0.0, 24.0, 0.0, 0.0), calm tide)',
      );
      expect(
        const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)).toString(),
        'HarborCoast.titleSafe(titleSafe: HarborTitleSafe.fraction(fraction: 5.0%))',
      );
    });

    test('a buoy shows how it is placed', () {
      expect(const HarborBuoy(child: _child).toString(), 'HarborBuoy');
      final HarborAnchor anchor = HarborAnchor(debugLabel: 'more button');
      addTearDown(anchor.dispose);
      final HarborBuoy menu = HarborBuoy.anchored(
        anchor: anchor,
        side: HarborBuoySide.below,
        modal: true,
        onDismiss: () {},
        requestFocus: false,
        barrierLabel: 'Close menu',
        child: _child,
      );
      expect(menu.toStringShort(), 'HarborBuoy.anchored');
      expect(_shown(menu), <String>[
        'anchor: ${describeIdentity(anchor)}(more button)',
        'side: below',
        'modal',
        'has onDismiss',
        'does not take focus',
        'barrierLabel: "Close menu"',
      ]);
    });

    test('a sheet extent shows its non-default heights and is equal by value', () {
      expect(const HarborSheetExtent().toString(), 'HarborSheetExtent');
      expect(
        const HarborSheetExtent(rest: 0.4, snap: false, snapSizes: <double>[0.4, 0.6]).toString(),
        'HarborSheetExtent(rest: 40.0%, no snapping, snapSizes: [0.4, 0.6])',
      );
      final List<double> sizes = <double>[0.4, 0.6];
      expect(
        HarborSheetExtent(rest: 0.4, snapSizes: sizes),
        const HarborSheetExtent(rest: 0.4, snapSizes: <double>[0.4, 0.6]),
      );
      expect(
        HarborSheetExtent(rest: 0.4, snapSizes: sizes).hashCode,
        const HarborSheetExtent(rest: 0.4, snapSizes: <double>[0.4, 0.6]).hashCode,
      );
      expect(const HarborSheetExtent(rest: 0.4), isNot(const HarborSheetExtent(rest: 0.5)));
    });
  });

  group('widgets describe their configuration', () {
    test('a harbor shows its docks, buoys and sizing, and nothing at its defaults', () {
      expect(_shown(const Harbor(body: _child)), isEmpty);
      expect(
        _shown(
          const Harbor(
            top: <HarborDock>[HarborDock.pier(debugLabel: 'header', child: _child)],
            bottom: <HarborDock>[HarborDock.quay(tide: HarborTideStance.float, child: _child)],
            buoys: <HarborBuoy>[HarborBuoy(child: _child)],
            newPort: true,
            bodyClearsTide: false,
            sizing: HarborSizing.hugBody,
            maxExtentFraction: 0.9,
            debugLabel: 'settings',
            body: _child,
          ),
        ),
        <String>[
          'top: HarborDock.pier(debugLabel: "header")',
          'bottom: HarborDock.quay(tide: float)',
          'buoys: HarborBuoy',
          'new port',
          'body runs under the tide',
          'sizing: hugBody',
          'maxExtentFraction: 90.0%',
          'debugLabel: "settings"',
        ],
      );
    });

    test('a sea shows its coast and mooring line', () {
      expect(_shown(const HarborSea(child: _child)), isEmpty);
      expect(
        _shown(
          const HarborSea(
            coast: HarborCoast.none,
            margin: EdgeInsetsDirectional.symmetric(horizontal: 16.0),
            child: _child,
          ),
        ),
        <String>['coast: HarborCoast.none', 'margin: EdgeInsetsDirectional(16.0, 0.0, 16.0, 0.0)'],
      );
    });

    test('a fairway reads as a scroll view does, plus its clearance', () {
      expect(_shown(const HarborFairway(slivers: <Widget>[])), <String>['scrollDirection: vertical']);
      expect(
        _shown(
          const HarborFairway(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            mooringLine: false,
            revealMargin: 24.0,
            startsInOpenWater: true,
            slivers: <Widget>[],
          ),
        ),
        <String>[
          'scrollDirection: horizontal',
          'shrinkWrap: shrink-wrapping',
          'no mooring line',
          'revealMargin: 24.0',
          'starts in open water',
        ],
      );
    });

    test('moored content shows what it keeps clear of', () {
      expect(_shown(const HarborMoored(child: _child)), isEmpty);
      expect(
        _shown(
          const HarborMoored(
            edges: HarborEdge.vertical,
            clear: HarborClear.coast,
            follow: HarborFollow.resting,
            mooringLine: true,
            minimum: EdgeInsetsDirectional.only(bottom: 16.0),
            child: _child,
          ),
        ),
        <String>[
          'edges: HarborEdge.top, HarborEdge.bottom',
          'clear: coast',
          'follow: resting',
          'mooring line',
          'minimum: EdgeInsets(0.0, 0.0, 0.0, 16.0)',
        ],
      );
    });

    test('a beacon, a scale model and a portal buoy show their settings', () {
      expect(_shown(const HarborBeacon(child: _child)), isEmpty);
      expect(
        _shown(const HarborBeacon(edge: HarborEdge.bottom, keepInSight: true, clearance: 8.0, child: _child)),
        <String>['edge: bottom', 'keep in sight', 'clearance: 8.0'],
      );

      expect(_shown(const HarborScaleModel(referenceSize: Size(1200.0, 675.0), child: _child)), <String>[
        'referenceSize: Size(1200.0, 675.0)',
      ]);

      final OverlayPortalController controller = OverlayPortalController(debugLabel: 'row menu');
      final List<String> portal = _shown(
        HarborPortalBuoy(
          controller: controller,
          side: HarborBuoySide.below,
          flips: false,
          buoyBuilder: (final BuildContext context) => _child,
          child: _child,
        ),
      );
      expect(portal, <String>['controller: $controller', 'side: below', 'no flip']);
    });

    test('a sheet shows its extent and what differs from a default sheet', () {
      expect(_shown(const HarborSheet(body: _child)), isEmpty);
      expect(
        _shown(
          HarborSheet.draggable(
            extent: const HarborSheetExtent(rest: 0.6),
            footerMinimum: 0.0,
            debugLabel: 'comments',
            builder: (final BuildContext context, final ScrollController controller) => _child,
          ),
        ),
        <String>['extent: HarborSheetExtent(rest: 60.0%)', 'footerMinimum: 0.0', 'debugLabel: "comments"'],
      );
    });
  });

  testWidgets('the widget tree dump shows a mounted harbor\'s docks', (final WidgetTester tester) async {
    await tester.pumpSeaTrial(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: HarborSea(
          child: Harbor(
            top: <HarborDock>[HarborDock.pier(debugLabel: 'header', child: SizedBox(height: 56.0))],
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
    final String tree = tester.element(find.byType(Harbor).last).toStringDeep();
    expect(tree.split('\n').first, contains('top: [HarborDock.pier(debugLabel: "header")]'));
  });
}
