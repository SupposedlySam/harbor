// What a fairway keeps clear of at its ends, and what it leaves to the content beneath.
//
// On an iPhone 17: status bar 62, home indicator 34, 874 tall, a keyboard of 336.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _statusBar = 62;
const double _homeIndicator = 34;
const double _screen = 874;

Widget _bar(final String label, final double height) =>
    SizedBox(key: ValueKey<String>(label), height: height, width: double.infinity, child: Text(label));

Widget _rows({final int count = 30}) => SliverList.builder(
  itemCount: count,
  itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 50),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<void> _scrollBy(final WidgetTester tester, final double dy) async {
  await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
  await tester.pumpAndSettle();
}

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: Material(child: home),
);

/// Captures the [BuildContext] it is built in.
class _Probe extends StatelessWidget {
  const _Probe(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(final BuildContext context) {
    onBuild(context);
    return const SizedBox(width: 50, height: 50);
  }
}

void main() {
  group('HarborFairwaySliver casts off what it cleared (#67)', () {
    // Breaks if: the sliver returns its padding alone again, without casting the ends off.
    testWidgets('a reader in the sliver does not clear the header and status bar a second time', (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            body: CustomScrollView(
              slivers: <Widget>[
                HarborFairwaySliver(sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byType(_Probe)).dy,
        _statusBar + 50,
        reason: 'positive control: the sliver still pads',
      );
      expect(MediaQuery.paddingOf(item).top, 0);
      expect(MediaQuery.paddingOf(item).bottom, 0);
      expect(MediaQuery.viewPaddingOf(item).top, 0);
      expect(HarborWaters.of(item).docks.top, 0);
      expect(HarborWaters.of(item).coast.top, 0);
    });

    // Breaks if: the sliver casts off an end it was told not to clear.
    testWidgets('an end it does not clear is left to the content beneath', (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        _app(
          CustomScrollView(
            slivers: <Widget>[
              HarborFairwaySliver(
                clearTrailing: false,
                sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
              ),
            ],
          ),
        ),
      );
      expect(MediaQuery.paddingOf(item).top, 0);
      expect(MediaQuery.paddingOf(item).bottom, _homeIndicator);
    });

    // Breaks if: the sliver casts off the keyboard it did not clear, or keeps the one it did.
    testWidgets('it casts off the keyboard with the bottom it cleared', (final tester) async {
      late BuildContext item;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            body: CustomScrollView(
              slivers: <Widget>[
                HarborFairwaySliver(sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))),
              ],
            ),
          ),
        ),
      );
      await trial.raiseTide();
      expect(MediaQuery.viewInsetsOf(item).bottom, 0);
    });
  });

  group('With startsInOpenWater, the first sliver gets back its leading end alone (#60)', () {
    // Breaks if: the first sliver is handed the fairway's own MediaQuery and waters again, from
    // above its cast-off, trailing end and keyboard included.
    testWidgets('a vertical fairway hands its first sliver neither the trailing end nor the keyboard', (final tester) async {
      final List<double> bottomPadding = <double>[];
      final List<double> keyboard = <double>[];
      late BuildContext item;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bodyClearsTide: false,
            top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
            bottom: <HarborDock>[HarborDock.pier(child: _bar('tabs', 50))],
            body: HarborFairway(
              startsInOpenWater: true,
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: _Probe((final BuildContext c) {
                    item = c;
                    bottomPadding.add(MediaQuery.paddingOf(c).bottom);
                    keyboard.add(MediaQuery.viewInsetsOf(c).bottom);
                  }),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(_Probe)).dy, 0, reason: 'positive control: it starts in open water');
      expect(MediaQuery.paddingOf(item).top, _statusBar + 50, reason: 'the leading end is given back');
      expect(HarborWaters.of(item).docks.top, _statusBar + 50);
      expect(bottomPadding.last, 0);
      expect(HarborWaters.of(item).docks.bottom, 0);
      expect(HarborWaters.of(item).coast.bottom, 0);
      await trial.raiseTide();
      expect(keyboard.last, 0);
    });

    // Breaks if: a horizontal fairway's first item is handed the trailing end's mooring line.
    testWidgets("a horizontal fairway hands its first item the leading side's mooring line alone", (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            body: SizedBox(
              height: 100,
              child: HarborFairway(
                scrollDirection: Axis.horizontal,
                startsInOpenWater: true,
                slivers: <Widget>[
                  SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
                ],
              ),
            ),
          ),
        ),
      );
      expect(HarborWaters.of(item).margin.start, 16, reason: 'positive control: the leading end is given back');
      expect(HarborWaters.of(item).margin.end, 0);
    });
  });

  group('A fairway that clears the coast alone (#57)', () {
    // A 50 header and a 60 tab bar, both piers: the body runs under them.
    const double headerFace = _statusBar + 50;
    const double tabsFace = _screen - _homeIndicator - 60;
    Widget page(final Widget body) => _app(
      Harbor(
        top: <HarborDock>[HarborDock.pier(child: _bar('header', 50))],
        bottom: <HarborDock>[HarborDock.pier(child: _bar('tabs', 60))],
        body: body,
      ),
    );

    // Breaks if: a coast-only fairway's ends clear the docks too.
    testWidgets('its ends rest clear of the status bar and home indicator, under the docks', (final tester) async {
      await tester.pumpSeaTrial(page(HarborFairway(clear: HarborClear.coast, slivers: <Widget>[_rows()])));
      expect(_rect(tester, 'row0').top, _statusBar);
      await _scrollBy(tester, -5000);
      expect(_rect(tester, 'row29').bottom, _screen - _homeIndicator);
    });

    // Breaks if: the fairway casts off the docks with the coast, or the coast is left in.
    testWidgets('its rows read the docks, measured from its edge, and no coast', (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        page(
          HarborFairway(
            clear: HarborClear.coast,
            slivers: <Widget>[SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))],
          ),
        ),
      );
      expect(MediaQuery.paddingOf(item).top, 50);
      expect(MediaQuery.paddingOf(item).bottom, 60);
      expect(HarborWaters.of(item).docks.top, 50);
      expect(HarborWaters.of(item).docks.bottom, 60);
      expect(HarborWaters.of(item).coast.top, 0);
      expect(HarborWaters.of(item).coast.bottom, 0);
    });

    // Breaks if: the cover is taken from the coast-only end, so a pinned header pins under the
    // status bar, behind the header.
    testWidgets("a pinned sliver dock still pins at the docks' face", (final tester) async {
      await tester.pumpSeaTrial(
        page(
          HarborFairway(
            clear: HarborClear.coast,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              HarborSliverDock(child: _bar('pinned', 40)),
              _rows(),
            ],
          ),
        ),
      );
      await _scrollBy(tester, -600);
      expect(_rect(tester, 'pinned').top, headerFace);
    });

    // Breaks if: reveals are widened by the coast-only ends rather than by what is over the viewport.
    testWidgets('reveals still keep clear of the header and the tab bar', (final tester) async {
      await tester.pumpSeaTrial(page(HarborFairway(clear: HarborClear.coast, slivers: <Widget>[_rows()])));
      // Row 14 starts at 62 + 14 * 50 = 762, under the tab bar's face at 780.
      tester.renderObject(find.byKey(const ValueKey<String>('row14'))).showOnScreen();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row14').bottom, tabsFace);
      await _scrollBy(tester, -800);
      tester.renderObject(find.byKey(const ValueKey<String>('row14'))).showOnScreen();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row14').top, headerFace);
    });

    // Breaks if: a horizontal fairway clears the rail at its ends or casts it off.
    testWidgets('a horizontal one rests under a rail, and its items read how far the rail reaches', (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        _app(
          Harbor(
            start: const <HarborDock>[HarborDock.pier(child: SizedBox(key: ValueKey<String>('rail'), width: 80))],
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 100,
                child: HarborFairway(
                  scrollDirection: Axis.horizontal,
                  clear: HarborClear.coast,
                  slivers: <Widget>[SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))],
                ),
              ),
            ),
          ),
        ),
      );
      expect(_rect(tester, 'rail').right, 80, reason: 'positive control: the rail is there');
      expect(tester.getTopLeft(find.byType(_Probe)).dx, 0);
      expect(MediaQuery.paddingOf(item).left, 80);
      expect(HarborWaters.of(item).docks.start, 80);
    });

    // Breaks if: paddingOf ignores clear.
    testWidgets('paddingOf gives the coast alone', (final tester) async {
      late EdgeInsets padding;
      await tester.pumpSeaTrial(
        page(
          Builder(
            builder: (final BuildContext context) {
              padding = HarborFairway.paddingOf(context, clear: HarborClear.coast);
              return const SizedBox.expand();
            },
          ),
        ),
      );
      expect(padding, const EdgeInsets.only(top: _statusBar, bottom: _homeIndicator));
    });

    // Breaks if: the sliver ignores clear, or casts off the docks with the coast.
    testWidgets('so does a fairway sliver, and its sliver reads the docks', (final tester) async {
      late BuildContext item;
      await tester.pumpSeaTrial(
        page(
          CustomScrollView(
            slivers: <Widget>[
              HarborFairwaySliver(
                clear: HarborClear.coast,
                sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
              ),
            ],
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(_Probe)).dy, _statusBar);
      expect(MediaQuery.paddingOf(item).top, 50);
      expect(HarborWaters.of(item).coast.top, 0);
    });
  });
}
