// Every field guide page says what to try on it: Jonah, opening a page, could not tell what to
// poke at. Breaks if a page is added, or its steps removed, without directions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/field_guide/entry.dart';
import 'package:harbor_example/field_guide/field_guide.dart';
import 'package:harbor_example/field_guide/guide_page.dart';

void main() {
  test('positive control: the entries were found', () => expect(fieldGuideEntries.length, greaterThan(40)));
  for (final GuideEntry entry in fieldGuideEntries) {
    testWidgets('${entry.id} says what to try', (final tester) async {
      tester.view
        ..physicalSize = const Size(1280, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: Palette.theme(),
          builder: (final BuildContext context, final Widget? child) =>
              HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
          home: Builder(builder: entry.page),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final GuidePage page = tester.widget<GuidePage>(find.byType(GuidePage));
      expect(page.tryThis.length, inInclusiveRange(3, 6), reason: '3 to 6 steps');
      for (final TryStep step in page.tryThis) {
        expect(step.action.trim(), isNotEmpty);
        expect(step.watch.trim(), isNotEmpty);
      }
      expect(find.byKey(const ValueKey<String>('try this')), findsOneWidget, reason: 'the card is on the page');
    });
  }
}
