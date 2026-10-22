// #162: content that starts under a top bar, with a vertical scroll view nested further down it. The
// nested view must not clear the bar a second time, while readers that measure against the bar
// (`HarborRoom.barFaceOf`, `HarborRoom.of(context).bars`) still find it there.
// `HarborHandled(keepsGeometry: true)` marks an edge handled for clearing alone.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

const double _statusBar = 47;
const double _homeIndicator = 34;
const double _header = 56;
const double _hero = 300;

// The header's inner face, measured from the frame's top.
const double _face = _statusBar + _header;

const Key _row = ValueKey<String>('nested first row');
const Key _nestedView = ValueKey<String>('nested view');

Widget _app(final Widget body, {final HarborEdgeEffect edgeEffect = HarborEdgeEffect.none}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(
      size: Size(400, 800),
      padding: EdgeInsets.only(top: _statusBar, bottom: _homeIndicator),
      viewPadding: EdgeInsets.only(top: _statusBar, bottom: _homeIndicator),
    ),
    child: HarborRoot(
      child: HarborFrame(
        debugLabel: 'page',
        top: <HarborBar>[
          HarborBar.overlay(
            edgeEffect: edgeEffect,
            child: const SizedBox(height: _header),
          ),
        ],
        body: body,
      ),
    ),
  ),
);

/// A nested vertical scroll view in a screen-sized box, as a tab's grid is.
const Widget _nested = SizedBox(
  height: 800,
  child: HarborScrollView(
    key: _nestedView,
    debugLabel: 'nested',
    slivers: <Widget>[SliverToBoxAdapter(child: SizedBox(key: _row, height: 40))],
  ),
);

/// What a reader in the content sees, captured as it builds.
class _Reading {
  late BuildContext context;
  double get barFace => HarborRoom.barFaceOf(context, HarborEdge.top);
  HarborRoomData get room => HarborRoom.of(context);
  EdgeInsets get padding => MediaQuery.paddingOf(context);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(context);
}

Widget _reader(final _Reading into) => Builder(
  builder: (final BuildContext context) {
    into.context = context;
    return const SizedBox(height: 1);
  },
);

/// An outer view that starts under the bars, holding [content] below its hero in its first sliver.
Widget _underBars(final List<Widget> content) => HarborScrollView(
  debugLabel: 'outer',
  startsUnderBars: true,
  slivers: <Widget>[
    SliverToBoxAdapter(
      child: Column(
        children: <Widget>[
          const SizedBox(height: _hero),
          ...content,
        ],
      ),
    ),
  ],
);

double _rowOffset(final WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_row)).dy - tester.getTopLeft(find.byKey(_nestedView)).dy;

HarborInspectorEntry _page() =>
    HarborInspector.snapshotAll().firstWhere((final HarborInspectorEntry e) => e.label == 'page');

void main() {
  group('the case, before the mark', () {
    testWidgets('positive control: a nested view in a later sliver of startsUnderBars clears nothing again', (
      final tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const HarborScrollView(
            startsUnderBars: true,
            slivers: <Widget>[
              SliverToBoxAdapter(child: SizedBox(height: _hero)),
              SliverToBoxAdapter(child: _nested),
            ],
          ),
        ),
      );
      // Every sliver after the first is under the outer view's handled leading end.
      expect(_rowOffset(tester), 0);
    });

    testWidgets('in the first sliver of startsUnderBars, the nested view clears the bar a second time', (
      final tester,
    ) async {
      await tester.pumpWidget(_app(_underBars(const <Widget>[_nested])));
      expect(_rowOffset(tester), _face);
    });

    testWidgets('HarborHandled stops it, but takes the bar out of the room for readers that measure', (
      final tester,
    ) async {
      final _Reading reading = _Reading();
      await tester.pumpWidget(
        _app(
          _underBars(<Widget>[
            HarborHandled(
              edges: const <HarborEdge>{HarborEdge.top},
              child: Column(children: <Widget>[_reader(reading), _nested]),
            ),
          ]),
        ),
      );
      expect(_rowOffset(tester), 0);
      expect(reading.barFace, 0);
    });
  });

  group('HarborHandled(keepsGeometry: true)', () {
    testWidgets('the nested view rests its first row at its own top, and the bar is still measured', (
      final tester,
    ) async {
      final _Reading outside = _Reading();
      final _Reading inside = _Reading();
      await tester.pumpWidget(
        _app(
          _underBars(<Widget>[
            _reader(outside),
            HarborHandled(
              edges: const <HarborEdge>{HarborEdge.top},
              keepsGeometry: true,
              child: Column(children: <Widget>[_reader(inside), _nested]),
            ),
          ]),
        ),
      );
      expect(_rowOffset(tester), 0);

      // Geometry: what the room says about the bar is what it says just outside the mark.
      expect(outside.barFace, _face);
      expect(inside.barFace, _face);
      expect(inside.room.bars.top, outside.room.bars.top);
      expect(inside.room.systemEdges.top, _statusBar);
      expect(inside.room.geometryOnly, <HarborEdge>{HarborEdge.top});

      // Clearing: nothing is left to clear on that edge, as under any consumer.
      expect(inside.padding.top, 0);
      expect(inside.viewPadding.top, 0);
      expect(HarborRoom.clearanceOf(inside.context, HarborEdge.top), 0);
      expect(HarborScrollView.paddingOf(inside.context).top, 0);
      expect(HarborRoom.steadySystemEdgeOf(inside.context, HarborEdge.top), 0);
      // The other edges are as they were.
      expect(inside.padding.bottom, outside.padding.bottom);
      expect(inside.room.geometryOnly.contains(HarborEdge.bottom), isFalse);
    });

    testWidgets('every clearing widget reads zero on the edge', (final tester) async {
      const Key live = ValueKey<String>('live');
      const Key systemOnly = ValueKey<String>('system edges alone');
      const Key resting = ValueKey<String>('resting');
      const Key sliver = ValueKey<String>('sliver');
      await tester.pumpWidget(
        _app(
          _underBars(<Widget>[
            const HarborHandled(
              edges: <HarborEdge>{HarborEdge.top},
              keepsGeometry: true,
              child: Column(
                children: <Widget>[
                  HarborClear(
                    edges: <HarborEdge>{HarborEdge.top},
                    child: SizedBox(key: live, height: 10),
                  ),
                  HarborClear(
                    edges: <HarborEdge>{HarborEdge.top},
                    clearsBars: false,
                    child: SizedBox(key: systemOnly, height: 10),
                  ),
                  HarborClear(
                    edges: <HarborEdge>{HarborEdge.top},
                    follow: HarborFollow.resting,
                    child: SizedBox(key: resting, height: 10),
                  ),
                  SizedBox(
                    height: 100,
                    child: CustomScrollView(
                      slivers: <Widget>[
                        HarborSliverClear(
                          sliver: SliverToBoxAdapter(child: SizedBox(key: sliver, height: 10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );
      double padded(final Key key) =>
          tester.getTopLeft(find.byKey(key)).dy - tester.getTopLeft(find.byType(HarborClear).first).dy;
      expect(padded(live), 0);
      expect(padded(systemOnly), 10);
      expect(padded(resting), 20);
      expect(tester.getTopLeft(find.byKey(sliver)).dy, tester.getTopLeft(find.byType(CustomScrollView).last).dy);
    });

    testWidgets('the nested view does not fade under the bar again; the fade band is still measured', (
      final tester,
    ) async {
      final _Reading inside = _Reading();
      await tester.pumpWidget(
        _app(
          _underBars(<Widget>[
            HarborHandled(
              edges: const <HarborEdge>{HarborEdge.top},
              keepsGeometry: true,
              child: Column(children: <Widget>[_reader(inside), _nested]),
            ),
          ]),
          edgeEffect: const HarborEdgeEffect.fade(length: 12),
        ),
      );
      expect(inside.room.fadeBands[HarborEdge.top], isNotNull);
      expect(inside.barFace, _face);
      final HarborFadeMask nestedMask = tester.widget<HarborFadeMask>(
        find.descendant(of: find.byKey(_nestedView), matching: find.byType(HarborFadeMask)),
      );
      expect(nestedMask.bands.containsKey(HarborEdge.top), isFalse);
      expect(_rowOffset(tester), 0);
    });

    testWidgets('it works the same under a scroll view harbor did not build', (final tester) async {
      final _Reading inside = _Reading();
      await tester.pumpWidget(
        _app(
          CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: _hero),
                    HarborHandled(
                      edges: const <HarborEdge>{HarborEdge.top},
                      keepsGeometry: true,
                      child: Column(children: <Widget>[_reader(inside), _nested]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(_rowOffset(tester), 0);
      expect(inside.barFace, _face);
    });

    testWidgets('a plain HarborHandled beneath it takes the geometry out as always', (final tester) async {
      final _Reading inside = _Reading();
      await tester.pumpWidget(
        _app(
          _underBars(<Widget>[
            HarborHandled(
              edges: const <HarborEdge>{HarborEdge.top},
              keepsGeometry: true,
              child: HarborHandled(edges: const <HarborEdge>{HarborEdge.top}, child: _reader(inside)),
            ),
          ]),
        ),
      );
      expect(inside.barFace, 0);
      expect(inside.room.systemEdges.top, 0);
    });

    testWidgets('the inspector lists the mark and the nested view on the edge, each with zero', (final tester) async {
      await tester.pumpWidget(
        _app(
          _underBars(const <Widget>[
            HarborHandled(
              edges: <HarborEdge>{HarborEdge.top},
              keepsGeometry: true,
              debugLabel: 'content under the bar',
              child: _nested,
            ),
          ]),
        ),
      );
      final List<HarborConsumerRecord> top = _page().consumersOn(HarborEdge.top);
      expect(top.map((final HarborConsumerRecord r) => (r.type, r.label, r.amount)), <(String, String?, double)>[
        ('HarborScrollView', 'outer', 0),
        ('HarborHandled', 'content under the bar', 0),
        ('HarborScrollView', 'nested', 0),
      ]);
    });

    testWidgets('it handles the system edges and the bars together: clearsBars: false is refused', (
      final tester,
    ) async {
      expect(
        () => HarborHandled(clearsBars: false, keepsGeometry: true, child: const SizedBox()),
        throwsAssertionError,
      );
    });
  });
}
