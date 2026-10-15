// What a scroll view keeps clear of at its ends, and what it leaves to the content beneath.
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
  builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
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
  group('HarborSliverClear marks what it cleared as handled (#67)', () {
    // Breaks if: the sliver returns its padding alone again, without marking the ends handled.
    testWidgets('a reader in the sliver does not clear the header and status bar a second time', (final tester) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            body: CustomScrollView(
              slivers: <Widget>[
                HarborSliverClear(sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))),
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
      expect(HarborRoom.of(item).bars.top, 0);
      expect(HarborRoom.of(item).systemEdges.top, 0);
    });

    // Breaks if: the sliver marks handled an end it was told not to clear.
    testWidgets('an end it does not clear is left to the content beneath', (final tester) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        _app(
          CustomScrollView(
            slivers: <Widget>[
              HarborSliverClear(
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

    // Breaks if: the sliver marks handled the keyboard it did not clear, or keeps the one it did.
    testWidgets('it marks the keyboard handled with the bottom it cleared', (final tester) async {
      late BuildContext item;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: CustomScrollView(
              slivers: <Widget>[
                HarborSliverClear(sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))),
              ],
            ),
          ),
        ),
      );
      await trial.showKeyboard();
      expect(MediaQuery.viewInsetsOf(item).bottom, 0);
    });
  });

  group('With startsUnderBars, the first sliver gets back its leading end alone (#60)', () {
    // Breaks if: starting under the bars zeroes the whole leading spacer again, the caller's padding and minimum
    // with the clearance (#74).
    testWidgets('starting under the bars skips the leading clearance but keeps its own padding and minimum', (
      final tester,
    ) async {
      Future<double> firstRowTop(final EdgeInsetsDirectional padding, final EdgeInsetsDirectional minimum) async {
        await tester.pumpHarborTrial(
          _app(
            HarborFrame(
              top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
              body: HarborScrollView(
                startsUnderBars: true,
                padding: padding,
                minimum: minimum,
                slivers: <Widget>[SliverToBoxAdapter(child: _Probe((final BuildContext _) {}))],
              ),
            ),
          ),
        );
        return tester.getTopLeft(find.byType(_Probe)).dy;
      }

      expect(
        await firstRowTop(EdgeInsetsDirectional.zero, EdgeInsetsDirectional.zero),
        0,
        reason: 'positive control: open water, no padding',
      );
      expect(
        await firstRowTop(const EdgeInsetsDirectional.only(top: 16), EdgeInsetsDirectional.zero),
        16,
        reason: 'its own padding stays',
      );
      expect(
        await firstRowTop(EdgeInsetsDirectional.zero, const EdgeInsetsDirectional.only(top: 24)),
        24,
        reason: 'its minimum stays',
      );
    });

    // Breaks if: the first sliver is handed the scroll view's own MediaQuery and room again, from
    // above where it marks them handled, trailing end and keyboard included.
    testWidgets('a vertical scroll view hands its first sliver neither the trailing end nor the keyboard', (
      final tester,
    ) async {
      final List<double> bottomPadding = <double>[];
      final List<double> keyboard = <double>[];
      late BuildContext item;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
            bottom: <HarborBar>[HarborBar.overlay(child: _bar('tabs', 50))],
            body: HarborScrollView(
              startsUnderBars: true,
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
      expect(HarborRoom.of(item).bars.top, _statusBar + 50);
      expect(bottomPadding.last, 0);
      expect(HarborRoom.of(item).bars.bottom, 0);
      expect(HarborRoom.of(item).systemEdges.bottom, 0);
      await trial.showKeyboard();
      expect(keyboard.last, 0);
    });

    // Breaks if: a horizontal scroll view's first item is handed the trailing end's row insets.
    testWidgets("a horizontal scroll view hands its first item the leading side's row insets alone", (
      final tester,
    ) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            body: SizedBox(
              height: 100,
              child: HarborScrollView(
                scrollDirection: Axis.horizontal,
                startsUnderBars: true,
                slivers: <Widget>[SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))],
              ),
            ),
          ),
        ),
      );
      expect(HarborRoom.of(item).margin.start, 16, reason: 'positive control: the leading end is given back');
      expect(HarborRoom.of(item).margin.end, 0);
    });
  });

  group('A scroll view that clears the system edges alone (#57)', () {
    // A 50 header and a 60 tab bar, both overlay bars: the body runs under them.
    const double headerFace = _statusBar + 50;
    const double tabsFace = _screen - _homeIndicator - 60;
    Widget page(final Widget body) => _app(
      HarborFrame(
        top: <HarborBar>[HarborBar.overlay(child: _bar('header', 50))],
        bottom: <HarborBar>[HarborBar.overlay(child: _bar('tabs', 60))],
        body: body,
      ),
    );

    // Breaks if: a system-edges-only scroll view's ends clear the bars too.
    testWidgets('its ends rest clear of the status bar and home indicator, under the bars', (final tester) async {
      await tester.pumpHarborTrial(page(HarborScrollView(bars: false, slivers: <Widget>[_rows()])));
      expect(_rect(tester, 'row0').top, _statusBar);
      await _scrollBy(tester, -5000);
      expect(_rect(tester, 'row29').bottom, _screen - _homeIndicator);
    });

    // Breaks if: the scroll view marks the bars handled with the system edges, or the system edges are left in.
    testWidgets('its rows read the bars, measured from its edge, and no system edges', (final tester) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        page(
          HarborScrollView(
            bars: false,
            slivers: <Widget>[SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c))],
          ),
        ),
      );
      expect(MediaQuery.paddingOf(item).top, 50);
      expect(MediaQuery.paddingOf(item).bottom, 60);
      expect(HarborRoom.of(item).bars.top, 50);
      expect(HarborRoom.of(item).bars.bottom, 60);
      expect(HarborRoom.of(item).systemEdges.top, 0);
      expect(HarborRoom.of(item).systemEdges.bottom, 0);
    });

    // Breaks if: the cover is taken from the system-edges-only end, so a pinned header pins under the
    // status bar, behind the header.
    testWidgets("a pinned sliver bar still pins at the bars' face", (final tester) async {
      await tester.pumpHarborTrial(
        page(
          HarborScrollView(
            bars: false,
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
              HarborSliverBar(child: _bar('pinned', 40)),
              _rows(),
            ],
          ),
        ),
      );
      await _scrollBy(tester, -600);
      expect(_rect(tester, 'pinned').top, headerFace);
    });

    // Breaks if: reveals are widened by the system-edges-only ends rather than by what is over the viewport.
    testWidgets('reveals still keep clear of the header and the tab bar', (final tester) async {
      await tester.pumpHarborTrial(page(HarborScrollView(bars: false, slivers: <Widget>[_rows()])));
      // Row 14 starts at 62 + 14 * 50 = 762, under the tab bar's face at 780.
      tester.renderObject(find.byKey(const ValueKey<String>('row14'))).showOnScreen();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row14').bottom, tabsFace);
      await _scrollBy(tester, -800);
      tester.renderObject(find.byKey(const ValueKey<String>('row14'))).showOnScreen();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row14').top, headerFace);
    });

    // Breaks if: a horizontal scroll view clears the rail at its ends or marks it handled.
    testWidgets('a horizontal one rests under a rail, and its items read how far the rail reaches', (
      final tester,
    ) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            start: const <HarborBar>[HarborBar.overlay(child: SizedBox(key: ValueKey<String>('rail'), width: 80))],
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 100,
                child: HarborScrollView(
                  scrollDirection: Axis.horizontal,
                  bars: false,
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
      expect(HarborRoom.of(item).bars.start, 80);
    });

    // Breaks if: paddingOf ignores bars.
    testWidgets('paddingOf gives the system edges alone', (final tester) async {
      late EdgeInsets padding;
      await tester.pumpHarborTrial(
        page(
          Builder(
            builder: (final BuildContext context) {
              padding = HarborScrollView.paddingOf(context, bars: false);
              return const SizedBox.expand();
            },
          ),
        ),
      );
      expect(padding, const EdgeInsets.only(top: _statusBar, bottom: _homeIndicator));
    });

    // Breaks if: the sliver ignores bars, or marks the bars handled with the system edges.
    testWidgets('so does a sliver clear, and its sliver reads the bars', (final tester) async {
      late BuildContext item;
      await tester.pumpHarborTrial(
        page(
          CustomScrollView(
            slivers: <Widget>[
              HarborSliverClear(
                bars: false,
                sliver: SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
              ),
            ],
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(_Probe)).dy, _statusBar);
      expect(MediaQuery.paddingOf(item).top, 50);
      expect(HarborRoom.of(item).systemEdges.top, 0);
    });
  });

  group('A scroll view that leaves the keyboard to someone else (#59)', () {
    // An iPhone SE has no bottom system edge, so the keyboard is all that is in the way at the bottom.
    const HarborTrialDevice phone = HarborTrialDevice.iPhoneSE;
    const double keyboardTop = 667 - 260;

    // Breaks if: clearsKeyboard: false still adds the keyboard to the bottom end, or marks it handled.
    testWidgets('its last row rests at the bottom with the keyboard up, and its rows still read the keyboard', (
      final tester,
    ) async {
      late BuildContext item;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: HarborScrollView(
              clearsKeyboard: false,
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
                _rows(),
              ],
            ),
          ),
        ),
        device: phone,
      );
      await trial.showKeyboard();
      expect(trial.keyboardTop, keyboardTop, reason: 'positive control: the keyboard is up');
      expect(MediaQuery.viewInsetsOf(item).bottom, 260);
      await _scrollBy(tester, -5000);
      expect(_rect(tester, 'row29').bottom, 667);
    });

    // Breaks if: reveals still widen by the keyboard.
    testWidgets('reveals leave the keyboard out', (final tester) async {
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(bodyClearsKeyboard: false, body: HarborScrollView(clearsKeyboard: false, slivers: <Widget>[_rows()])),
        ),
        device: phone,
      );
      await trial.showKeyboard();
      // Row 8 is at 20 + 8 * 50 = 420, under the keyboard but on the screen.
      tester.renderObject(find.byKey(const ValueKey<String>('row8'))).showOnScreen();
      await tester.pumpAndSettle();
      expect(_rect(tester, 'row8').bottom, 470);
    });

    // Breaks if: paddingOf ignores clearsKeyboard.
    testWidgets('paddingOf leaves the keyboard out', (final tester) async {
      late EdgeInsets padding;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: Builder(
              builder: (final BuildContext context) {
                padding = HarborScrollView.paddingOf(context, clearsKeyboard: false);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        device: phone,
      );
      await trial.showKeyboard();
      expect(padding, const EdgeInsets.only(top: 20));
    });

    // Breaks if: the sliver ignores clearsKeyboard, or marks handled the keyboard it left.
    testWidgets('so does a sliver clear, and its sliver still reads the keyboard', (final tester) async {
      late BuildContext item;
      final HarborTrial trial = await tester.pumpHarborTrial(
        _app(
          HarborFrame(
            bodyClearsKeyboard: false,
            body: CustomScrollView(
              slivers: <Widget>[
                HarborSliverClear(
                  clearsKeyboard: false,
                  sliver: SliverMainAxisGroup(
                    slivers: <Widget>[
                      SliverToBoxAdapter(child: _Probe((final BuildContext c) => item = c)),
                      _rows(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        device: phone,
      );
      await trial.showKeyboard();
      expect(MediaQuery.viewInsetsOf(item).bottom, 260);
      await _scrollBy(tester, -5000);
      expect(_rect(tester, 'row29').bottom, 667);
    });
  });

  // The README's answer to #58, held: no per-end flags, a HarborHandled around the scroll view.
  // Breaks if: a scroll view's spacer or cover keeps a top that a HarborHandled above it zeroed.
  testWidgets("under a HarborHandled of the top, a scroll view leaves the top to the header that already cleared it", (
    final tester,
  ) async {
    await tester.pumpHarborTrial(
      _app(
        HarborFrame(
          top: <HarborBar>[
            HarborBar.overlay(edgeEffect: const HarborEdgeEffect.fade(length: 12), child: _bar('header', 50)),
          ],
          body: HarborHandled(
            edges: const <HarborEdge>{HarborEdge.top},
            child: HarborScrollView(
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 200)),
                HarborSliverBar(child: _bar('pinned', 40)),
                _rows(),
              ],
            ),
          ),
        ),
      ),
    );
    expect(_rect(tester, 'pinned').top, 200, reason: 'the first sliver starts at the top');
    await _scrollBy(tester, -600);
    expect(_rect(tester, 'pinned').top, 0, reason: 'the cover is zero too');
  });
}
