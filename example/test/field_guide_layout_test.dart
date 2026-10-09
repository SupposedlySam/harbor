// The field guide on the web: on a wide screen the controls sit beside the stage, on a phone they
// are a quay along the bottom, under it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/field_guide.dart';
import 'package:harbor_example/field_guide/guide_page.dart';

Future<void> _pumpPage(final WidgetTester tester, final Size screen) async {
  tester.view
    ..physicalSize = screen
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final GuideEntry entry = fieldGuideEntries.firstWhere((final GuideEntry e) => e.id == 'dock-pier');
  await tester.pumpWidget(
    MaterialApp(
      theme: Palette.theme(),
      builder: (final BuildContext context, final Widget? child) =>
          HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
      home: Builder(builder: entry.page),
    ),
  );
  // The seas never settle, so step rather than settle.
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

void main() {
  testWidgets('on a wide screen the controls are a panel beside the stage, below the header', (final tester) async {
    await _pumpPage(tester, const Size(1280, 800));
    expect(find.byKey(const ValueKey<String>('control quay')), findsNothing, reason: 'no quay along the bottom');
    final Rect panel = _rect(tester, 'control panel');
    final Rect stage = _rect(tester, 'stage');
    expect(panel.left, greaterThanOrEqualTo(stage.right), reason: 'beside the stage, after it');
    expect(panel.top, lessThan(stage.bottom), reason: 'side by side, not stacked');
    final Rect header = tester.getRect(find.text('HarborDock.pier').first);
    expect(panel.top, greaterThan(header.bottom), reason: 'clear of the header pier');
    expect(panel.bottom, lessThanOrEqualTo(800), reason: 'on screen');
  });

  testWidgets('on a phone the controls are a quay along the bottom, under the stage', (final tester) async {
    await _pumpPage(tester, const Size(402, 874));
    expect(find.byKey(const ValueKey<String>('control panel')), findsNothing, reason: 'no panel beside it');
    final Rect quay = _rect(tester, 'control quay');
    expect(quay.top, greaterThanOrEqualTo(_rect(tester, 'stage').bottom), reason: 'under the stage');
  });

  testWidgets('the switch is at Material\'s expanded width', (final tester) async {
    await _pumpPage(tester, const Size(GuidePage.sideBySideWidth - 1, 800));
    expect(find.byKey(const ValueKey<String>('control quay')), findsOneWidget);
    await _pumpPage(tester, const Size(GuidePage.sideBySideWidth, 800));
    expect(find.byKey(const ValueKey<String>('control panel')), findsOneWidget);
  });
}
