// Who owns the corners: the side bars. A rail runs the frame's full height, and a header or a tab
// bar runs between the rails, as a tablet's navigation rail sits beside its app bar. What keeps clear
// in the header keeps its margin from the rail's edge and the system edge on the side no rail holds.
// Before 0.4.0 the header ran the full width, under the rail, and its title sat under it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Widget _line(final String key) => HarborClear.rowInsets(
  child: SizedBox(key: ValueKey<String>(key), height: 40, width: double.infinity),
);

Widget _page({
  final List<HarborBar> start = const <HarborBar>[],
  final List<HarborBar> end = const <HarborBar>[],
  final TextDirection direction = TextDirection.ltr,
  final Widget? header,
}) => MaterialApp(
  builder: (final c, final child) => Directionality(
    textDirection: direction,
    child: HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  ),
  home: HarborFrame(
    top: <HarborBar>[HarborBar.overlay(child: header ?? _line('title'))],
    bottom: <HarborBar>[HarborBar.solid(child: _line('tabs'))],
    start: start,
    end: end,
    body: const HarborClear.rowInsets(
      child: SizedBox(key: ValueKey<String>('row'), height: 40, width: double.infinity),
    ),
  ),
);

HarborBar _rail(final double width, {final HarborBarState state = HarborBarState.open}) => HarborBar.solid(
  state: state,
  duration: Duration.zero,
  child: SizedBox(key: const ValueKey<String>('rail'), width: width),
);

void main() {
  testWidgets('positive control: with no side bars, a header lines up with the margin', (final tester) async {
    await tester.pumpHarborTrial(_page());
    expect(_rect(tester, 'title').left, 16);
    expect(_rect(tester, 'title').right, 402 - 16);
  });

  testWidgets('a header kept clear beside a rail lines up with the body, past the rail', (final tester) async {
    await tester.pumpHarborTrial(_page(start: <HarborBar>[_rail(80)]));
    expect(_rect(tester, 'rail').left, 0);
    expect(_rect(tester, 'title').left, 80 + 16);
    expect(_rect(tester, 'title').left, _rect(tester, 'row').left, reason: 'lined up with the body');
    expect(_rect(tester, 'title').right, 402 - 16);
    expect(_rect(tester, 'tabs').left, 80 + 16, reason: 'a bottom dock too');
  });

  testWidgets('the header runs between the rails, not under them', (final tester) async {
    await tester.pumpHarborTrial(
      _page(
        start: <HarborBar>[_rail(80)],
        end: <HarborBar>[_rail(40)],
        header: const SizedBox(key: ValueKey<String>('band'), height: 40, width: double.infinity),
      ),
    );
    expect(_rect(tester, 'band').left, 80);
    expect(_rect(tester, 'band').right, 402 - 40);
  });

  testWidgets('on a phone on its side the rail takes the system edge, and the header clears both', (
    final tester,
  ) async {
    await tester.pumpHarborTrial(_page(start: <HarborBar>[_rail(80)]), device: HarborTrialDevice.iPhone17Landscape);
    final double rail = _rect(tester, 'rail').right;
    expect(_rect(tester, 'title').left, rail + 16);
    expect(_rect(tester, 'title').left, _rect(tester, 'row').left);
    expect(_rect(tester, 'title').right, 874 - 62 - 16, reason: 'the end side keeps the coast it had');
  });

  testWidgets('right to left, a start rail is on the right and the header clears it there', (final tester) async {
    await tester.pumpHarborTrial(_page(start: <HarborBar>[_rail(80)], direction: TextDirection.rtl));
    expect(_rect(tester, 'rail').right, 402);
    expect(_rect(tester, 'title').right, 402 - 80 - 16);
    expect(_rect(tester, 'title').left, 16);
  });

  testWidgets('an end rail is cleared on its side', (final tester) async {
    await tester.pumpHarborTrial(_page(end: <HarborBar>[_rail(72)]));
    expect(_rect(tester, 'title').right, 402 - 72 - 16);
    expect(_rect(tester, 'title').left, 16);
  });

  testWidgets('a withdrawn rail gives its ground back to the header too', (final tester) async {
    await tester.pumpHarborTrial(_page(start: <HarborBar>[_rail(80, state: HarborBarState.withdrawn)]));
    expect(_rect(tester, 'title').left, 16);
  });

  testWidgets('beside a rail, a header is not handed the system edge the rail took, and keeps the other side\'s', (
    final tester,
  ) async {
    late EdgeInsets padding;
    await tester.pumpHarborTrial(
      _page(
        start: <HarborBar>[_rail(80)],
        header: Builder(
          builder: (final c) {
            padding = MediaQuery.paddingOf(c);
            return const SizedBox(height: 40, width: double.infinity);
          },
        ),
      ),
      device: HarborTrialDevice.iPhone17Landscape,
    );
    expect(padding.left, 0, reason: 'the rail absorbed the 62 there');
    expect(padding.right, 62);
  });

  testWidgets('positive control: with no rail, the header is handed the side system edges on both sides', (
    final tester,
  ) async {
    late EdgeInsets padding;
    await tester.pumpHarborTrial(
      _page(
        header: Builder(
          builder: (final c) {
            padding = MediaQuery.paddingOf(c);
            return const SizedBox(height: 40, width: double.infinity);
          },
        ),
      ),
      device: HarborTrialDevice.iPhone17Landscape,
    );
    expect(padding.left, 62);
    expect(padding.right, 62);
  });
}
