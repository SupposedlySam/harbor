// HarborSheet(bodyClearsTide: false) (#95): a sheet whose body manages the keyboard itself.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<(HarborSeaTrial, BuildContext)> _page(final WidgetTester tester) async {
  late BuildContext page;
  final HarborSeaTrial trial = await tester.pumpSeaTrial(MaterialApp(
    builder: (final c, final child) => HarborSea(child: child!),
    home: Harbor(body: Builder(builder: (final c) {
      page = c;
      return const SizedBox.expand();
    })),
  ));
  return (trial, page);
}

Future<void> _open(final WidgetTester tester, final BuildContext page, final HarborSheet sheet) async {
  unawaited(showHarborSheet<void>(page, builder: (final BuildContext _) => sheet));
  await tester.pumpAndSettle();
}

void main() {
  late double insets;
  Widget body(final double height) => Builder(builder: (final c) {
    insets = MediaQuery.viewInsetsOf(c).bottom;
    return SizedBox(key: const ValueKey<String>('body'), height: height);
  });

  testWidgets('positive control: by default the body ends at the keyboard and is not told about it', (final tester) async {
    final (HarborSeaTrial trial, BuildContext page) = await _page(tester);
    await trial.raiseTide(settle: true);
    await _open(tester, page, HarborSheet(body: body(200)));
    expect(_rect(tester, 'body').bottom, 874 - 336);
    expect(insets, 0);
  });

  testWidgets('false: the body runs under the keyboard and reads it in its view insets', (final tester) async {
    final (HarborSeaTrial trial, BuildContext page) = await _page(tester);
    await trial.raiseTide(settle: true);
    await _open(tester, page, HarborSheet(bodyClearsTide: false, body: body(200)));
    expect(_rect(tester, 'body').bottom, 874);
    expect(insets, 336);
  });

  testWidgets('false: a floating footer still rides up on the keyboard', (final tester) async {
    final (HarborSeaTrial trial, BuildContext page) = await _page(tester);
    await trial.raiseTide(settle: true);
    await _open(
      tester,
      page,
      HarborSheet(bodyClearsTide: false, body: body(200), footer: const SizedBox(key: ValueKey<String>('footer'), height: 48)),
    );
    // Its footerMinimum, 16, above the keyboard, as without the flag.
    expect(_rect(tester, 'footer').bottom, 874 - 336 - 16);
  });

  testWidgets('the height cap is a share of the space above the keyboard, or of the whole with false', (final tester) async {
    // The sheet's box stops short of the status bar: 874 - 62 = 812.
    final (HarborSeaTrial trial, BuildContext page) = await _page(tester);
    await trial.raiseTide(settle: true);
    await _open(tester, page, HarborSheet(body: body(2000)));
    expect(tester.getRect(find.byType(HarborSheet)).height, closeTo((812 - 336) * 0.9 + 336, 0.5));
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
    await _open(tester, page, HarborSheet(bodyClearsTide: false, body: body(2000)));
    expect(tester.getRect(find.byType(HarborSheet)).height, closeTo(812 * 0.9, 0.5));
  });

  testWidgets('a draggable sheet\'s extents are of the whole height with false', (final tester) async {
    final (HarborSeaTrial trial, BuildContext page) = await _page(tester);
    await trial.raiseTide(settle: true);
    Widget list(final BuildContext _, final ScrollController controller) =>
        ListView(key: const ValueKey<String>('list'), controller: controller, children: const <Widget>[SizedBox(height: 2000)]);
    await _open(tester, page, HarborSheet.draggable(extent: const HarborSheetExtent(rest: 0.5), builder: list));
    expect(_rect(tester, 'list').bottom, 874 - 336, reason: 'positive control: above the keyboard');
    final double above = _rect(tester, 'list').height;
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
    await _open(tester, page, HarborSheet.draggable(bodyClearsTide: false, extent: const HarborSheetExtent(rest: 0.5), builder: list));
    expect(_rect(tester, 'list').bottom, 874);
    expect(_rect(tester, 'list').height, greaterThan(above + 100), reason: 'half of the whole, not of the space above the keyboard');
  });
}
