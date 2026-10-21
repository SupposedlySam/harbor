// The inspector names the widgets that took an inset out of what lies beneath them, on each edge,
// and how much each took, from the values it laid out with (#160).

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor/src/inspector.dart' show debugHarborConsumerLine;

const double _statusBar = 47;
const double _homeIndicator = 34;
const double _header = 56;

Widget _app(final Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(
      size: Size(400, 800),
      padding: EdgeInsets.only(top: _statusBar, bottom: _homeIndicator),
      viewPadding: EdgeInsets.only(top: _statusBar, bottom: _homeIndicator),
    ),
    child: HarborRoot(child: child),
  ),
);

Widget _page({required final Widget body}) => HarborFrame(
  debugLabel: 'page',
  top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: _header))],
  body: body,
);

HarborInspectorEntry _entry(final String label) =>
    HarborInspector.snapshotAll().firstWhere((final HarborInspectorEntry e) => e.label == label);

void main() {
  group('consumers', () {
    testWidgets('a HarborClear is listed on each edge it cleared, with what it laid out', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborClear(
              debugLabel: 'form',
              child: SizedBox.expand(key: ValueKey<String>('in')),
            ),
          ),
        ),
      );
      final HarborInspectorEntry page = _entry('page');
      final List<HarborConsumerRecord> top = page.consumersOn(HarborEdge.top);
      expect(top, hasLength(1));
      expect(top.single.type, 'HarborClear');
      expect(top.single.label, 'form');
      expect(top.single.amount, _statusBar + _header);
      // The amount is what the content was moved by, measured.
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('in'))).dy, top.single.amount);
      expect(page.consumersOn(HarborEdge.bottom).single.amount, _homeIndicator);
      // Its rect is the HarborClear's own box, in global coordinates.
      expect(top.single.rect, tester.getRect(find.byType(HarborClear)));
      // Every edge it handles is listed, zero or not.
      expect(page.consumersOn(HarborEdge.start).single.amount, 0);
    });

    testWidgets('an edge cleared twice shows two entries, outermost first', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborClear(
              debugLabel: 'outer',
              edges: <HarborEdge>{HarborEdge.top},
              child: HarborClear(
                debugLabel: 'inner',
                edges: <HarborEdge>{HarborEdge.top},
                minimum: EdgeInsetsDirectional.only(top: 24),
                child: SizedBox.expand(key: ValueKey<String>('in')),
              ),
            ),
          ),
        ),
      );
      final List<HarborConsumerRecord> top = _entry('page').consumersOn(HarborEdge.top);
      expect(top.map((final HarborConsumerRecord c) => c.label), <String>['outer', 'inner']);
      expect(top.map((final HarborConsumerRecord c) => c.amount), <double>[_statusBar + _header, 24]);
      // The two amounts together are where the content landed: 24 lower than the header's face.
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('in'))).dy, _statusBar + _header + 24);
    });

    testWidgets('a HarborScrollView is listed on both its ends, with where each end rests', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: HarborScrollView(
              debugLabel: 'inbox',
              slivers: <Widget>[
                SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (final BuildContext context, final int i) => SizedBox(key: ValueKey<int>(i), height: 40),
                ),
              ],
            ),
          ),
        ),
      );
      final HarborInspectorEntry page = _entry('page');
      final HarborConsumerRecord top = page.consumersOn(HarborEdge.top).single;
      expect(top.type, 'HarborScrollView');
      expect(top.label, 'inbox');
      expect(tester.getTopLeft(find.byKey(const ValueKey<int>(0))).dy, top.amount);
      expect(page.consumersOn(HarborEdge.bottom).single.amount, _homeIndicator);
      expect(page.consumersOn(HarborEdge.start), isEmpty);
    });

    testWidgets('a HarborScrollView inside a HarborClear finds its ends already cleared', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborClear(child: HarborScrollView(slivers: <Widget>[SliverToBoxAdapter()])),
          ),
        ),
      );
      final List<HarborConsumerRecord> top = _entry('page').consumersOn(HarborEdge.top);
      expect(top.map((final HarborConsumerRecord c) => c.type), <String>['HarborClear', 'HarborScrollView']);
      expect(top.last.amount, 0);
    });

    testWidgets('HarborHandled is listed with what it removed; a key stands in for a label', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborHandled(
              key: ValueKey<String>('by hand'),
              edges: <HarborEdge>{HarborEdge.top},
              child: SizedBox.expand(),
            ),
          ),
        ),
      );
      final HarborConsumerRecord top = _entry('page').consumersOn(HarborEdge.top).single;
      expect(top.type, 'HarborHandled');
      expect(top.label, isNull);
      expect(top.key, "[<'by hand'>]");
      expect(top.amount, _statusBar + _header);
    });

    testWidgets('a HarborSliverClear is listed on the ends it cleared', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const CustomScrollView(
              slivers: <Widget>[
                HarborSliverClear(
                  debugLabel: 'mine',
                  clearTrailing: false,
                  sliver: SliverToBoxAdapter(child: SizedBox(key: ValueKey<String>('first'), height: 40)),
                ),
              ],
            ),
          ),
        ),
      );
      final HarborInspectorEntry page = _entry('page');
      final HarborConsumerRecord top = page.consumersOn(HarborEdge.top).single;
      expect(top.type, 'HarborSliverClear');
      expect(top.label, 'mine');
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('first'))).dy, top.amount);
      expect(page.consumersOn(HarborEdge.bottom), isEmpty);
    });

    testWidgets('a frame nested in a body is listed on the edges its bars cleared', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborFrame(
              debugLabel: 'panel',
              top: <HarborBar>[HarborBar.solid(child: SizedBox(height: 30))],
              body: SizedBox.expand(),
            ),
          ),
        ),
      );
      final HarborInspectorEntry page = _entry('page');
      final HarborConsumerRecord top = page.consumersOn(HarborEdge.top).single;
      expect(top.type, 'HarborFrame');
      expect(top.label, 'panel');
      // Its header took the status bar and the page's header, as its system edge.
      expect(top.amount, _statusBar + _header);
      // No bar on the bottom: the panel's body is handed that edge, so the panel took nothing there.
      expect(page.consumersOn(HarborEdge.bottom), isEmpty);
      // A page right under the root is not nested: the root lists no consumers.
      expect(_entry('sea').consumers, isEmpty);
    });

    testWidgets('a consumer that leaves the tree leaves the entry', (final tester) async {
      await tester.pumpWidget(_app(_page(body: const HarborClear(child: SizedBox.expand()))));
      expect(_entry('page').consumers, isNotEmpty);
      await tester.pumpWidget(_app(_page(body: const SizedBox.expand())));
      expect(_entry('page').consumers, isEmpty);
    });

    testWidgets('toJson lists them, and keeps every key it had', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborClear(debugLabel: 'form', child: SizedBox.expand()),
          ),
        ),
      );
      final Map<String, Object?> json = jsonDecode(jsonEncode(_entry('page').toJson())) as Map<String, Object?>;
      expect(
        json.keys,
        containsAll(<String>['label', 'depth', 'isolated', 'frame', 'body', 'room', 'keyboard', 'obstruction', 'bars']),
      );
      final List<Object?> consumers = json['consumers']! as List<Object?>;
      expect(consumers.first, <String, Object?>{
        'type': 'HarborClear',
        'label': 'form',
        'key': null,
        'edge': 'top',
        'amount': _statusBar + _header,
        // The test view's own size: the MediaQuery above only reports a phone's.
        'rect': <String, Object?>{'left': 0.0, 'top': 0.0, 'width': 800.0, 'height': 600.0},
      });
    });
  });

  group('the overlay', () {
    testWidgets('writes one line per edge, grouping alike consumers and leaving out zeros', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: HarborScrollView(
              debugLabel: 'inbox',
              slivers: <Widget>[
                SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (final BuildContext context, final int i) =>
                      const HarborClear.rowInsets(child: SizedBox(height: 40)),
                ),
              ],
            ),
          ),
        ),
      );
      final HarborInspectorEntry page = _entry('page');
      expect(debugHarborConsumerLine(page, HarborEdge.top), 'top: HarborScrollView "inbox" 103');
      // Row insets on a frame with no margin clear nothing, so the sides have no line.
      expect(debugHarborConsumerLine(page, HarborEdge.start), isNull);
    });

    testWidgets('groups the rows of a list on the margin', (final tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: HarborRoot(
              margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: _page(
                body: HarborScrollView(
                  slivers: <Widget>[
                    SliverList.builder(
                      itemCount: 3,
                      itemBuilder: (final BuildContext context, final int i) =>
                          const HarborClear.rowInsets(child: SizedBox(height: 40)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(debugHarborConsumerLine(_entry('page'), HarborEdge.start), 'start: HarborClear.rowInsets ×3 16');
    });

    testWidgets('paints the lines inside the room, clear of the bars', (final tester) async {
      await tester.pumpWidget(
        _app(
          _page(
            body: const HarborClear(debugLabel: 'form', child: SizedBox.expand()),
          ),
        ).wrapInOverlay(),
      );
      // One paragraph for the bar's label, one each for the top and bottom lines.
      expect(
        find.byType(HarborInspectorOverlay),
        paints
          ..paragraph()
          ..paragraph()
          ..paragraph(),
      );
    });

    testWidgets("moves a line off a bar's label it would land on", (final tester) async {
      // A 4-high bar and no status bar: the room starts at 4, inside the bar's own label.
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: HarborInspectorOverlay(
            child: MediaQuery(
              data: MediaQueryData(size: Size(800, 600)),
              child: HarborRoot(
                child: HarborFrame(
                  top: <HarborBar>[HarborBar.overlay(child: SizedBox(height: 4))],
                  body: HarborClear(edges: <HarborEdge>{HarborEdge.top}, child: SizedBox.expand()),
                ),
              ),
            ),
          ),
        ),
      );
      Rect? barLabel;
      expect(
        find.byType(HarborInspectorOverlay),
        paints
          ..something((final Symbol method, final List<dynamic> args) {
            if (method != #drawParagraph) {
              return false;
            }
            final ui.Paragraph p = args[0] as ui.Paragraph;
            barLabel = (args[1] as Offset) & Size(p.maxIntrinsicWidth, p.height);
            return true;
          })
          ..something((final Symbol method, final List<dynamic> args) {
            if (method != #drawParagraph) {
              return false;
            }
            final ui.Paragraph p = args[0] as ui.Paragraph;
            final Rect line = (args[1] as Offset) & Size(p.maxIntrinsicWidth, p.height);
            expect(line.overlaps(barLabel!), isFalse, reason: 'line $line, bar label $barLabel');
            return true;
          }),
      );
    });
  });
}

extension on Widget {
  Widget wrapInOverlay() => Directionality(
    textDirection: TextDirection.ltr,
    child: HarborInspectorOverlay(child: this),
  );
}
