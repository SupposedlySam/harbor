import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

// On an iPhone 17 (status bar 62, home indicator 34, 874 tall): a 50 header
// pier ends at 112, and a 60 tab bar quay starts at 874 - 34 - 60.
const double _headerBottom = 62 + 50;
const double _quayTop = 874 - 34 - 60;

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Widget _app(final Widget home, {final String? restorationScopeId}) => MaterialApp(
  restorationScopeId: restorationScopeId,
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: Material(child: home),
);

Widget _rows(final String prefix, {final int count = 20, final Key? key}) => SliverList.builder(
  key: key,
  itemCount: count,
  itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('$prefix$i'), height: 50),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<void> _scrollBy(final WidgetTester tester, final double dy) async {
  await tester.drag(find.byType(Scrollable), Offset(0, dy));
  await tester.pumpAndSettle();
}

class _DismissOnDrag extends ScrollBehavior {
  const _DismissOnDrag();

  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(final BuildContext context) =>
      ScrollViewKeyboardDismissBehavior.onDrag;
}

int _built = 0;

class _Remembers extends StatefulWidget {
  const _Remembers({super.key});

  @override
  State<_Remembers> createState() => _RemembersState();
}

class _RemembersState extends State<_Remembers> {
  final int id = _built++;

  @override
  Widget build(final BuildContext context) => const SizedBox(height: 50);
}

void main() {
  group('keyboardDismissBehavior', () {
    Future<FocusNode> pumpFocusedField(
      final WidgetTester tester,
      final HarborFairway Function(Widget field) fairway,
    ) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpSeaTrial(
        _app(
          ScrollConfiguration(
            behavior: const _DismissOnDrag(),
            child: Harbor(body: fairway(TextField(focusNode: focus))),
          ),
        ),
      );
      focus.requestFocus();
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pump();
      return focus;
    }

    testWidgets('left unset, follows the scroll behavior above the fairway', (final tester) async {
      final FocusNode focus = await pumpFocusedField(
        tester,
        (final Widget field) => HarborFairway(
          slivers: <Widget>[
            SliverToBoxAdapter(child: field),
            const SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
      );
      expect(focus.hasFocus, isFalse);
    });

    testWidgets('given, overrides the scroll behavior above the fairway', (final tester) async {
      final FocusNode focus = await pumpFocusedField(
        tester,
        (final Widget field) => HarborFairway(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          slivers: <Widget>[
            SliverToBoxAdapter(child: field),
            const SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
      );
      expect(focus.hasFocus, isTrue);
    });

    testWidgets('left unset on a box fairway, follows the scroll behavior above it', (final tester) async {
      final FocusNode focus = await pumpFocusedField(
        tester,
        (final Widget field) =>
            HarborFairway.box(child: Column(children: <Widget>[field, const SizedBox(height: 2000)])),
      );
      expect(focus.hasFocus, isFalse);
    });
  });

  group('reverse', () {
    // A chat: a header pier on top, a composer pier that floats on the
    // keyboard, and the newest message at the bottom.
    Widget chat({final List<Widget> before = const <Widget>[]}) => Harbor(
      bodyClearsTide: false,
      top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
      bottom: <HarborDock>[HarborDock.pier(tide: HarborTideStance.float, child: _bar('composer', 60))],
      body: HarborFairway(reverse: true, slivers: <Widget>[...before, _rows('message', count: 40)]),
    );

    testWidgets('rests the newest message on the composer and the oldest below the header', (final tester) async {
      await tester.pumpSeaTrial(_app(chat()));
      expect(_rect(tester, 'message0').bottom, _rect(tester, 'composer').top);
      await _scrollBy(tester, 5000);
      expect(_rect(tester, 'message39').top, _headerBottom);
    });

    testWidgets('keeps the newest message on the composer as it rides the keyboard', (final tester) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(chat()));
      await trial.raiseTide(settle: true);
      expect(_rect(tester, 'composer').bottom, trial.waterline);
      expect(_rect(tester, 'message0').bottom, _rect(tester, 'composer').top);
    });

    testWidgets('pins a sliver dock at the composer, the leading end', (final tester) async {
      await tester.pumpSeaTrial(_app(chat(before: <Widget>[HarborSliverDock(child: _bar('day', 30))])));
      expect(_rect(tester, 'day').bottom, _rect(tester, 'composer').top);
      await _scrollBy(tester, 600);
      expect(_rect(tester, 'day').bottom, _rect(tester, 'composer').top);
    });
  });

  testWidgets('keyed slivers keep their state when they move', (final tester) async {
    Widget sliver(final String name) => SliverToBoxAdapter(
      key: ValueKey<String>(name),
      child: _Remembers(key: ValueKey<String>('$name state')),
    );
    int idOf(final String name) => tester.state<_RemembersState>(find.byKey(ValueKey<String>('$name state'))).id;
    Widget page(final List<String> order) =>
        _app(Harbor(body: HarborFairway(slivers: <Widget>[for (final String name in order) sliver(name)])));

    await tester.pumpSeaTrial(page(<String>['first', 'second']));
    final (int first, int second) = (idOf('first'), idOf('second'));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery.fromView(view: tester.view, child: page(<String>['second', 'first'])),
      ),
    );
    expect((idOf('first'), idOf('second')), (first, second));
  });

  group("the rest of CustomScrollView's parameters", () {
    testWidgets('reach the scroll view and its viewport', (final tester) async {
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: HarborFairway(
              scrollBehavior: const _DismissOnDrag(),
              paintOrder: SliverPaintOrder.lastIsTop,
              dragStartBehavior: DragStartBehavior.down,
              restorationId: 'list',
              hitTestBehavior: HitTestBehavior.translucent,
              slivers: <Widget>[_rows('row')],
            ),
          ),
        ),
      );
      final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
      expect(scrollable.scrollBehavior, isA<_DismissOnDrag>());
      expect(scrollable.dragStartBehavior, DragStartBehavior.down);
      expect(scrollable.restorationId, 'list');
      expect(scrollable.hitTestBehavior, HitTestBehavior.translucent);
      expect(
        tester.widget<Viewport>(find.byWidgetPredicate((final Widget w) => w is Viewport)).paintOrder,
        SliverPaintOrder.lastIsTop,
      );
    });

    testWidgets('reach the scroll view of a box fairway', (final tester) async {
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: HarborFairway.box(
              scrollBehavior: const _DismissOnDrag(),
              dragStartBehavior: DragStartBehavior.down,
              restorationId: 'form',
              hitTestBehavior: HitTestBehavior.translucent,
              child: const SizedBox(height: 2000),
            ),
          ),
        ),
      );
      final Scrollable scrollable = tester.widget<Scrollable>(find.byType(Scrollable));
      expect(scrollable.scrollBehavior, isA<_DismissOnDrag>());
      expect(scrollable.dragStartBehavior, DragStartBehavior.down);
      expect(scrollable.restorationId, 'form');
      expect(scrollable.hitTestBehavior, HitTestBehavior.translucent);
    });

    testWidgets('restorationId brings the scroll position back after a restart', (final tester) async {
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            body: HarborFairway(restorationId: 'list', slivers: <Widget>[_rows('row', count: 60)]),
          ),
          restorationScopeId: 'app',
        ),
      );
      await _scrollBy(tester, -600);
      final double scrolled = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
      expect(scrolled, greaterThan(0));
      await tester.restartAndRestore();
      expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, scrolled);
    });
  });

  group('center and anchor', () {
    const Key newer = ValueKey<String>('newer');

    Widget page(final List<Widget> slivers, {final Key? center = newer, final double anchor = 0.0}) => Harbor(
      top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
      bottom: <HarborDock>[HarborDock.quay(child: _bar('tabs', 60))],
      body: HarborFairway(center: center, anchor: anchor, slivers: slivers),
    );

    testWidgets('rest the center sliver clear of the header, and both ends clear of the docks', (final tester) async {
      await tester.pumpSeaTrial(_app(page(<Widget>[_rows('older'), _rows('newer', key: newer)])));
      expect(_rect(tester, 'newer0').top, moreOrLessEquals(_headerBottom));
      expect(_rect(tester, 'older0').bottom, moreOrLessEquals(_headerBottom));
      await _scrollBy(tester, 5000);
      expect(_rect(tester, 'older19').top, moreOrLessEquals(_headerBottom));
      await _scrollBy(tester, -10000);
      expect(_rect(tester, 'newer19').bottom, moreOrLessEquals(_quayTop));
    });

    testWidgets("pin a sliver dock after the center at the header's face", (final tester) async {
      await tester.pumpSeaTrial(
        _app(
          page(<Widget>[
            _rows('older'),
            HarborSliverDock(key: newer, child: _bar('day', 30)),
            _rows('later', count: 40),
          ]),
        ),
      );
      expect(_rect(tester, 'day').top, moreOrLessEquals(_headerBottom));
      await _scrollBy(tester, -600);
      expect(_rect(tester, 'day').top, moreOrLessEquals(_headerBottom));
      expect(_rect(tester, 'later11').top, lessThan(_headerBottom));
    });

    testWidgets('reveal rows on either side of the center clear of the header', (final tester) async {
      await tester.pumpSeaTrial(_app(page(<Widget>[_rows('older'), _rows('newer', key: newer)])));
      // Grows away from the center, toward the header.
      expect(_rect(tester, 'older2').top, lessThan(0));
      await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey<String>('older2'))));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'older2').top, moreOrLessEquals(_headerBottom));

      await _scrollBy(tester, -350);
      expect(_rect(tester, 'newer2').top, lessThan(_headerBottom));
      await Scrollable.ensureVisible(tester.element(find.byKey(const ValueKey<String>('newer2'))));
      await tester.pumpAndSettle();
      expect(_rect(tester, 'newer2').top, moreOrLessEquals(_headerBottom));
    });

    testWidgets('anchor is a fraction of the water between the docks', (final tester) async {
      await tester.pumpSeaTrial(_app(page(<Widget>[_rows('row')], center: null, anchor: 0.5)));
      expect(_rect(tester, 'row0').top, moreOrLessEquals(_headerBottom + (_quayTop - _headerBottom) / 2));
    });

    testWidgets('anchored at the end, keep the center on the composer as it rides the keyboard', (final tester) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            bottom: <HarborDock>[HarborDock.pier(tide: HarborTideStance.float, child: _bar('composer', 60))],
            body: HarborFairway(
              center: newer,
              anchor: 1.0,
              slivers: <Widget>[
                _rows('older'),
                _rows('newer', key: newer),
              ],
            ),
          ),
        ),
      );
      expect(_rect(tester, 'older0').bottom, moreOrLessEquals(_rect(tester, 'composer').top));
      expect(_rect(tester, 'newer0').top, moreOrLessEquals(_rect(tester, 'composer').top));
      await trial.raiseTide(settle: true);
      expect(_rect(tester, 'composer').bottom, trial.waterline);
      expect(_rect(tester, 'older0').bottom, moreOrLessEquals(_rect(tester, 'composer').top));
    });

    testWidgets('reversed, rest the center on the composer and both ends clear of the docks', (final tester) async {
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            bottom: <HarborDock>[HarborDock.pier(tide: HarborTideStance.float, child: _bar('composer', 60))],
            body: HarborFairway(
              reverse: true,
              center: newer,
              slivers: <Widget>[
                _rows('older'),
                _rows('newer', key: newer),
              ],
            ),
          ),
        ),
      );
      final double composerTop = _rect(tester, 'composer').top;
      expect(_rect(tester, 'newer0').bottom, moreOrLessEquals(composerTop));
      await _scrollBy(tester, 5000);
      expect(_rect(tester, 'newer19').top, moreOrLessEquals(_headerBottom));
      await _scrollBy(tester, -10000);
      expect(_rect(tester, 'older19').bottom, moreOrLessEquals(composerTop));
    });

    testWidgets('a center that names none of the slivers asserts', (final tester) async {
      await tester.pumpSeaTrial(_app(page(<Widget>[_rows('row')], center: const ValueKey<String>('missing'))));
      expect(tester.takeException(), isAssertionError);
    });
  });
}
