// HarborDock.reserve (#92), and which reader gives a footer on the keyboard its bottom room (#93).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _page({required final List<HarborDock> bottom, final bool bodyClearsTide = true, final VoidCallback? onTap}) => MaterialApp(
  builder: (final c, final child) => HarborSea(child: child!),
  home: Harbor(
    bodyClearsTide: bodyClearsTide,
    bottom: bottom,
    body: Stack(
      children: <Widget>[
        Positioned.fill(child: GestureDetector(key: const ValueKey<String>('page'), behavior: HitTestBehavior.opaque, onTap: onTap)),
        const HarborMoored(child: SizedBox.expand(key: ValueKey<String>('moored'))),
      ],
    ),
  ),
);

void main() {
  group('#92 HarborDock.reserve', () {
    testWidgets('outermost, it reaches the larger of the coast and its extent', (final tester) async {
      await tester.pumpSeaTrial(_page(bottom: const <HarborDock>[HarborDock.reserve(extent: 80)]));
      expect(_rect(tester, 'moored').bottom, 874 - 80, reason: 'past the 34 home indicator');
      await tester.pumpSeaTrial(_page(bottom: const <HarborDock>[HarborDock.reserve(extent: 20)]));
      expect(_rect(tester, 'moored').bottom, 874 - 34, reason: 'the coast is larger');
    });

    testWidgets('inside another dock, it reaches its extent past that dock', (final tester) async {
      await tester.pumpSeaTrial(_page(
        bottom: const <HarborDock>[
          HarborDock.reserve(extent: 40),
          HarborDock.quay(child: SizedBox(key: ValueKey<String>('tabs'), height: 56)),
        ],
      ));
      expect(_rect(tester, 'tabs').bottom, 874 - 34, reason: 'the tab bar is outermost and takes the coast');
      expect(_rect(tester, 'moored').bottom, 874 - 34 - 56 - 40);
    });

    testWidgets('positive control: the minimum trick reserved nothing inside another dock', (final tester) async {
      await tester.pumpSeaTrial(_page(
        bottom: const <HarborDock>[
          HarborDock.pier(minimum: 40, hitTestBehavior: HitTestBehavior.deferToChild, child: SizedBox.shrink()),
          HarborDock.quay(child: SizedBox(key: ValueKey<String>('tabs'), height: 56)),
        ],
      ));
      expect(_rect(tester, 'moored').bottom, 874 - 34 - 56);
    });

    testWidgets('takes no taps: what it stands in for gets them', (final tester) async {
      int taps = 0;
      await tester.pumpSeaTrial(_page(bottom: const <HarborDock>[HarborDock.reserve(extent: 80)], onTap: () => taps++));
      await tester.tapAt(const Offset(200, 874 - 40));
      expect(taps, 1);
    });

    testWidgets('a pier lets the body run under it; a quay stops it', (final tester) async {
      await tester.pumpSeaTrial(_page(bottom: const <HarborDock>[HarborDock.reserve(extent: 80)]));
      expect(_rect(tester, 'page').bottom, 874);
      await tester.pumpSeaTrial(_page(bottom: const <HarborDock>[HarborDock.reserve(extent: 80, kind: HarborDockKind.quay)]));
      expect(_rect(tester, 'page').bottom, 874 - 80);
    });

    testWidgets('floating, it rides up on the keyboard', (final tester) async {
      final HarborSeaTrial trial = await tester.pumpSeaTrial(
        _page(bodyClearsTide: false, bottom: const <HarborDock>[HarborDock.reserve(extent: 50, tide: HarborTideStance.float)]),
      );
      await trial.raiseTide(settle: true);
      expect(_rect(tester, 'moored').bottom, 874 - 336 - 50);
    });

    test('says what it is', () {
      const HarborDock dock = HarborDock.reserve(extent: 50);
      expect(dock.toStringShort(), 'HarborDock.reserve');
      expect(dock.copyWith(state: HarborDockState.dark).reserved, 50, reason: 'copyWith keeps it a reserve');
    });
  });

  group('#93 a footer that sits on the keyboard', () {
    testWidgets('reads MediaQuery.viewPadding in a body that clears the tide: the home indicator down, 0 up', (final tester) async {
      late BuildContext body;
      final HarborSeaTrial trial = await tester.pumpSeaTrial(MaterialApp(
        builder: (final c, final child) => HarborSea(child: child!),
        home: Harbor(body: Builder(builder: (final c) {
          body = c;
          return const SizedBox.expand();
        })),
      ));
      expect(MediaQuery.viewPaddingOf(body).bottom, 34);
      await trial.raiseTide(settle: true);
      expect(MediaQuery.viewPaddingOf(body).bottom, 0);
      expect(HarborWaters.steadyCoastOf(body, HarborEdge.bottom), 34, reason: 'positive control: the steady coast holds, as documented');
    });
  });
}
