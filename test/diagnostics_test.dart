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
      expect(const HarborBar.overlay(child: _child).toString(), 'HarborBar.overlay');
      expect(
        const HarborBar.solid(
          keyboard: HarborKeyboardStance.rides,
          state: HarborBarState.withdrawn,
          minimum: 16.0,
          withdrawsAtHighTide: true,
          debugLabel: 'tab bar',
          backdrop: _child,
          child: _child,
        ).toString(),
        'HarborBar.solid(keyboard: rides, state: withdrawn, has backdrop, withdraws while the keyboard is up, minimum: 16.0, '
        'debugLabel: "tab bar")',
      );
    });

    test('a wake names its kind and shows its non-default sizes', () {
      expect(HarborEdgeEffect.none.toString(), 'HarborEdgeEffect.none');
      expect(const HarborEdgeEffect.fade().toString(), 'HarborEdgeEffect.fade');
      expect(
        const HarborEdgeEffect.fade(length: 12.0, blurSigma: 8.0).toString(),
        'HarborEdgeEffect.fade(length: 12.0, blurSigma: 8.0)',
      );
      expect(const HarborEdgeEffect.hairline(thickness: 0.5).toString(), 'HarborEdgeEffect.hairline(thickness: 0.5)');
    });

    test('a coast names where it comes from', () {
      expect(HarborSystemEdges.ambient.toString(), 'HarborSystemEdges.ambient');
      expect(HarborSystemEdges.none.toString(), 'HarborSystemEdges.none');
      expect(
        const HarborSystemEdges.fixed(EdgeInsetsDirectional.only(top: 24.0), ignoresKeyboard: true).toString(),
        'HarborSystemEdges.fixed(fixedInsets: EdgeInsets(0.0, 24.0, 0.0, 0.0), ignores the keyboard)',
      );
      expect(
        const HarborSystemEdges.titleSafe(HarborTitleSafe.fraction(0.05)).toString(),
        'HarborSystemEdges.titleSafe(titleSafe: HarborTitleSafe.fraction(fraction: 5.0%))',
      );
    });

    test('a buoy shows how it is placed', () {
      expect(const HarborFloat(child: _child).toString(), 'HarborFloat');
      final HarborAnchor anchor = HarborAnchor(debugLabel: 'more button');
      addTearDown(anchor.dispose);
      // The deprecated spelling, which still describes itself as it did; placement_test.dart covers
      // how a buoy given a placement describes itself.
      // ignore: deprecated_member_use_from_same_package
      final HarborFloat menu = HarborFloat.anchored(
        // ignore: deprecated_member_use_from_same_package
        anchor: anchor,
        side: HarborAnchorSide.below,
        modal: true,
        onDismiss: () {},
        requestFocus: false,
        barrierLabel: 'Close menu',
        child: _child,
      );
      expect(menu.toStringShort(), 'HarborFloat.anchored');
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
      expect(_shown(const HarborFrame(body: _child)), isEmpty);
      expect(
        _shown(
          const HarborFrame(
            top: <HarborBar>[HarborBar.overlay(debugLabel: 'header', child: _child)],
            bottom: <HarborBar>[HarborBar.solid(keyboard: HarborKeyboardStance.rides, child: _child)],
            floats: <HarborFloat>[HarborFloat(child: _child)],
            isPage: true,
            bodyClearsKeyboard: false,
            sizing: HarborSizing.hug(maxFraction: 0.9),
            debugLabel: 'settings',
            body: _child,
          ),
        ),
        <String>[
          'top: HarborBar.overlay(debugLabel: "header")',
          'bottom: HarborBar.solid(keyboard: rides)',
          'floats: HarborFloat',
          'page',
          'body runs under the keyboard',
          'sizing: HarborSizing.hug(maxFraction: 90.0%)',
          'debugLabel: "settings"',
        ],
      );
    });

    test('a root shows its system edges and margin', () {
      expect(_shown(const HarborRoot(child: _child)), isEmpty);
      expect(
        _shown(
          const HarborRoot(
            systemEdges: HarborSystemEdges.none,
            margin: EdgeInsetsDirectional.symmetric(horizontal: 16.0),
            child: _child,
          ),
        ),
        <String>['systemEdges: HarborSystemEdges.none', 'margin: EdgeInsetsDirectional(16.0, 0.0, 16.0, 0.0)'],
      );
    });

    test('a fairway reads as a scroll view does, plus its clearance', () {
      expect(_shown(const HarborScrollView(slivers: <Widget>[])), <String>['scrollDirection: vertical']);
      expect(
        _shown(
          const HarborScrollView(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            rowInsets: false,
            bars: false,
            clearsKeyboard: false,
            revealMargin: 24.0,
            startsUnderBars: true,
            slivers: <Widget>[],
          ),
        ),
        <String>[
          'scrollDirection: horizontal',
          'shrinkWrap: shrink-wrapping',
          'no row insets',
          'bars not cleared',
          'keyboard ignored',
          'revealMargin: 24.0',
          'starts under bars',
        ],
      );
    });

    test('moored content shows what it keeps clear of', () {
      expect(_shown(const HarborClear(child: _child)), isEmpty);
      expect(
        _shown(
          const HarborClear(
            edges: HarborEdge.vertical,
            bars: false,
            follow: HarborFollow.resting,
            rowInsets: true,
            minimum: EdgeInsetsDirectional.only(bottom: 16.0),
            child: _child,
          ),
        ),
        <String>[
          'edges: HarborEdge.top, HarborEdge.bottom',
          'bars not cleared',
          'follow: resting',
          'row insets',
          'minimum: EdgeInsets(0.0, 0.0, 0.0, 16.0)',
        ],
      );
    });

    test('a beacon, a scale model and a portal buoy show their settings', () {
      expect(_shown(const HarborKeepInSight(child: _child)), isEmpty);
      expect(
        _shown(const HarborKeepInSight(edge: HarborEdge.bottom, keepInSight: true, clearance: 8.0, child: _child)),
        <String>['edge: bottom', 'keep in sight', 'clearance: 8.0'],
      );

      expect(_shown(const HarborScaledScreen(referenceSize: Size(1200.0, 675.0), child: _child)), <String>[
        'referenceSize: Size(1200.0, 675.0)',
      ]);

      final OverlayPortalController controller = OverlayPortalController(debugLabel: 'row menu');
      final List<String> portal = _shown(
        // The deprecated spelling, which still describes itself as it did; placement_test.dart covers
        // how a portal buoy given a placement describes itself.
        HarborPopover(
          controller: controller,
          // ignore: deprecated_member_use_from_same_package
          side: HarborAnchorSide.below,
          // ignore: deprecated_member_use_from_same_package
          flips: false,
          popoverBuilder: (final BuildContext context) => _child,
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
    await tester.pumpHarborTrial(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: HarborRoot(
          child: HarborFrame(
            top: <HarborBar>[HarborBar.overlay(debugLabel: 'header', child: SizedBox(height: 56.0))],
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
    final String tree = tester.element(find.byType(HarborFrame).last).toStringDeep();
    expect(tree.split('\n').first, contains('top: [HarborBar.overlay(debugLabel: "header")]'));
  });
}
