import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _headerHeight = 50;
const double _navHeight = 56;
const double _composerHeight = 44;

Widget _bar(final String label, final double height) => SizedBox(
  key: ValueKey<String>(label),
  height: height,
  child: Text(label),
);

Widget _app(final Widget home) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborSea(child: child!),
  home: home,
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

void main() {
  group('A pier header over a fairway, above a quay tab bar', () {
    Widget page() => Harbor(
      debugLabel: 'page',
      top: <HarborDock>[
        HarborDock.pier(wake: const HarborWake.fade(length: 8), child: _bar('header', _headerHeight)),
      ],
      bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', _navHeight))],
      body: HarborFairway(
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 60,
            itemBuilder: (final BuildContext context, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 40),
          ),
        ],
      ),
    );

    for (final HarborTrialDevice device in HarborTrialDevice.phones) {
      testWidgets('rests the first row past the wake and absorbs the coast once on ${device.name}', (final tester) async {
        await tester.pumpSeaTrial(_app(page()), device: device);
        final Rect header = _rect(tester, 'header');
        final Rect nav = _rect(tester, 'nav');
        // The header is padded below the status bar, once.
        expect(header.top, device.coast.top);
        // The tab bar sits above the home indicator, once.
        expect(nav.bottom, device.size.height - device.coast.bottom);
        // The first row rests below the header and its wake.
        expect(_rect(tester, 'row0').top, header.bottom + 8);
      });

      testWidgets('ends the last row above the tab bar on ${device.name}', (final tester) async {
        await tester.pumpSeaTrial(_app(page()), device: device);
        await tester.dragUntilVisible(find.byKey(const ValueKey<String>('row59')), find.byType(Scrollable), const Offset(0, -400));
        await tester.drag(find.byType(Scrollable), const Offset(0, -2000));
        await tester.pumpAndSettle();
        final Rect last = _rect(tester, 'row59');
        final Rect nav = _rect(tester, 'nav');
        expect(last.bottom, moreOrLessEquals(nav.top - (device.size.height - device.coast.bottom - nav.bottom)));
        expect(last.bottom, lessThanOrEqualTo(nav.top + 0.5));
      });

      testWidgets('keeps the tab bar behind the keyboard on ${device.name}', (final tester) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(page()), device: device);
        final Rect before = _rect(tester, 'nav');
        await trial.raiseTide();
        final Rect after = _rect(tester, 'nav');
        // Pilings: the bar holds its place and its height; the keyboard covers it.
        expect(after.top, before.top);
        expect(after.height, before.height);
      });
    }
  });

  group('A composer that floats', () {
    Widget page() => Harbor(
      bottom: <HarborDock>[
        HarborDock.quay(tide: HarborTideStance.float, child: _bar('composer', _composerHeight)),
      ],
      body: const HarborMoored(child: SizedBox.expand(key: ValueKey<String>('body'))),
    );

    for (final HarborTrialDevice device in HarborTrialDevice.phones) {
      testWidgets('rides the waterline and the body ends above it on ${device.name}', (final tester) async {
        final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(page()), device: device);
        expect(_rect(tester, 'composer').bottom, device.size.height - device.coast.bottom);
        await trial.raiseTide();
        expect(_rect(tester, 'composer').bottom, trial.waterline);
        expect(_rect(tester, 'body').bottom, trial.waterline - _composerHeight);
      });
    }

    testWidgets('stacks above a tab bar on pilings, and rides past it when the keyboard is up', (final tester) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _app(
          Harbor(
            bottom: <HarborDock>[
              HarborDock.quay(tide: HarborTideStance.float, child: _bar('composer', _composerHeight)),
              HarborDock.quay(child: _bar('nav', _navHeight)),
            ],
            body: const SizedBox.expand(),
          ),
        ),
      );
      final Rect nav = _rect(tester, 'nav');
      expect(_rect(tester, 'composer').bottom, nav.top);
      await trial.raiseTide();
      expect(_rect(tester, 'composer').bottom, trial.waterline);
      expect(_rect(tester, 'nav').top, nav.top);
    });
  });

  testWidgets('a moored button with no docks clears the coast and the keyboard', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        const Harbor(
          bodyClearsTide: false,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: HarborMoored(edges: <HarborEdge>{HarborEdge.bottom}, child: SizedBox(key: ValueKey<String>('save'), height: 40)),
          ),
        ),
      ),
      device: HarborTrialDevice.androidThreeButton,
    );
    expect(_rect(tester, 'save').bottom, 915 - 48);
    await trial.raiseTide();
    expect(_rect(tester, 'save').bottom, trial.waterline);
  });

  testWidgets('a minimum keeps a bottom bar off the edge of a phone with no home indicator', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          bottom: <HarborDock>[HarborDock.quay(minimum: 16, child: _bar('footer', 40))],
          body: const SizedBox.expand(),
        ),
      ),
      device: HarborTrialDevice.iPhoneSE,
    );
    expect(_rect(tester, 'footer').bottom, 667 - 16);
  });

  testWidgets('a make-way claim withdraws the tab bar and the body takes its ground', (final tester) async {
    final ValueNotifier<bool> claim = ValueNotifier<bool>(false);
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', _navHeight))],
          body: ValueListenableBuilder<bool>(
            valueListenable: claim,
            builder: (final BuildContext context, final bool active, final Widget? _) => HarborMakeWay(
              edge: HarborEdge.bottom,
              active: active,
              child: const HarborMoored(child: SizedBox.expand(key: ValueKey<String>('body'))),
            ),
          ),
        ),
      ),
    );
    final double withBar = _rect(tester, 'body').bottom;
    expect(withBar, 874 - 34 - _navHeight);
    claim.value = true;
    await tester.pumpAndSettle();
    // The bar is gone; the body still keeps clear of the home indicator.
    expect(_rect(tester, 'body').bottom, 874 - 34);
    claim.value = false;
    await tester.pumpAndSettle();
    expect(_rect(tester, 'body').bottom, withBar);
  });

  testWidgets('a pontoon from deep in the body joins the bottom docks', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          bottom: <HarborDock>[HarborDock.quay(child: _bar('nav', _navHeight))],
          body: HarborPontoon(
            edge: HarborEdge.bottom,
            dock: HarborDock.pier(child: _bar('pill', 30)),
            child: const HarborMoored(child: SizedBox.expand(key: ValueKey<String>('body'))),
          ),
        ),
      ),
    );
    await tester.pump();
    final Rect nav = _rect(tester, 'nav');
    final Rect pill = _rect(tester, 'pill');
    expect(pill.bottom, nav.top);
    expect(_rect(tester, 'body').bottom, pill.top);
  });

  testWidgets('a new port sees only the coast, not the docks around it', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', _headerHeight))],
          body: Harbor(
            newPort: true,
            body: Builder(
              builder: (final BuildContext context) => Text(
                'top ${MediaQuery.paddingOf(context).top}',
                key: const ValueKey<String>('probe'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('top 62.0'), findsOneWidget);
  });

  testWidgets('a component harbor sees the docks around it as coast', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          top: <HarborDock>[HarborDock.pier(child: _bar('header', _headerHeight))],
          body: Harbor(
            top: <HarborDock>[HarborDock.pier(child: _bar('inner', 20))],
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(_rect(tester, 'inner').top, _rect(tester, 'header').bottom);
  });

  testWidgets('a start dock lands on the right under right-to-left', (final tester) async {
    await tester.pumpSeaTrial(
      _app(
        const Directionality(
          textDirection: TextDirection.rtl,
          child: Harbor(
            start: <HarborDock>[HarborDock.quay(child: SizedBox(key: ValueKey<String>('rail'), width: 80))],
            body: SizedBox.expand(key: ValueKey<String>('body')),
          ),
        ),
      ),
    );
    expect(_rect(tester, 'rail').right, 402);
    expect(_rect(tester, 'body').right, 402 - 80);
  });

  testWidgets('a field under the keyboard in an overlay body is revealed clear of it', (final tester) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Harbor(
            bodyClearsTide: false,
            top: <HarborDock>[HarborDock.pier(child: _bar('header', _headerHeight))],
            body: HarborFairway(
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 700)),
                SliverToBoxAdapter(child: TextField(key: const ValueKey<String>('field'), focusNode: focus)),
                const SliverToBoxAdapter(child: SizedBox(height: 400)),
              ],
            ),
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await trial.raiseTide();
    await tester.pumpAndSettle();
    expect(_rect(tester, 'field').bottom, lessThanOrEqualTo(trial.waterline + 0.5));
  });

  testWidgets('a breakwater sheet extends the opening page\'s fairway', (final tester) async {
    late BuildContext pageContext;
    await tester.pumpSeaTrial(
      _app(
        Harbor(
          body: Builder(
            builder: (final BuildContext context) {
              pageContext = context;
              return HarborFairway(
                slivers: <Widget>[
                  SliverList.builder(itemCount: 40, itemBuilder: (final BuildContext c, final int i) => SizedBox(key: ValueKey<String>('row$i'), height: 40)),
                ],
              );
            },
          ),
        ),
      ),
    );
    final double before = MediaQuery.paddingOf(pageContext).bottom;
    unawaited(showHarborSheet<void>(
      pageContext,
      breakwater: true,
      barrier: HarborSheetBarrier.none,
      builder: (final BuildContext context) => const HarborSheet(body: SizedBox(height: 200)),
    ));
    await tester.pumpAndSettle();
    final double after = MediaQuery.paddingOf(pageContext).bottom;
    expect(after, greaterThanOrEqualTo(200));
    expect(after, greaterThan(before));
  });

  testWidgets('a dry dock reserves the high-water mark once the keyboard has settled', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _app(
        const Harbor(
          bodyClearsTide: false,
          bottom: <HarborDock>[
            HarborDock.quay(
              tide: HarborTideStance.dryDock,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[SizedBox(height: 40), HarborDryDock(child: SizedBox.expand(key: ValueKey<String>('tabs')))],
              ),
            ),
          ],
          body: SizedBox.expand(),
        ),
      ),
    );
    await trial.raiseTide();
    await tester.pump();
    await trial.lowerTide();
    await tester.pump();
    expect(_rect(tester, 'tabs').height, trial.device.tideHeight);
    expect(_rect(tester, 'tabs').bottom, 874);
  });
}
