// HarborMaterialDefaults.of fills harbor's defaults from MaterialLocalizations and the theme, read
// where an app calls it: MaterialApp.builder.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

late HarborDefaults _read;
late MaterialLocalizations _localizations;

Future<void> _pump(final WidgetTester tester, {final ThemeData? theme, final HarborDefaults? also}) async {
  // A fresh app each time: no sheet or toast left from the last pump, and no theme change to animate.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpHarborTrial(
    MaterialApp(
      theme: theme,
      builder: (final BuildContext context, final Widget? child) =>
          HarborRoot(defaults: HarborMaterialDefaults.of(context).merge(also), child: child!),
      home: HarborFrame(
        body: Builder(
          builder: (final BuildContext context) {
            _read = HarborDefaults.of(context);
            _localizations = MaterialLocalizations.of(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the barrier label and the sheet tap hint are Material\'s words', (final WidgetTester tester) async {
    await _pump(tester);
    expect(_read.barrierLabel, _localizations.modalBarrierDismissLabel);
    expect(_read.barrierLabel, 'Dismiss');
    expect(_read.sheetBarrierOnTapHint, _localizations.scrimOnTapHint(_localizations.bottomSheetLabel));
    expect(_read.sheetBarrierOnTapHint, 'Close Bottom Sheet');
  });

  testWidgets('the sheet width is Material 3\'s 640, the theme\'s, or none in Material 2', (
    final WidgetTester tester,
  ) async {
    await _pump(tester, theme: ThemeData());
    expect(_read.sheetMaxWidth, 640.0);

    await _pump(tester, theme: ThemeData(useMaterial3: false));
    expect(_read.sheetMaxWidth, isNull);

    await _pump(
      tester,
      theme: ThemeData(bottomSheetTheme: const BottomSheetThemeData(constraints: BoxConstraints(maxWidth: 500))),
    );
    expect(_read.sheetMaxWidth, 500.0);

    await _pump(
      tester,
      theme: ThemeData(bottomSheetTheme: const BottomSheetThemeData(constraints: BoxConstraints())),
    );
    expect(_read.sheetMaxWidth, isNull, reason: 'a theme that sets no finite width asks for none');
  });

  testWidgets('the rest stay harbor\'s, and merge adds to them', (final WidgetTester tester) async {
    await _pump(tester, also: const HarborDefaults(toastQueue: HarborToastQueue.replace));
    expect(_read.toastQueue, HarborToastQueue.replace);
    expect(_read.barrierLabel, 'Dismiss');
    expect(_read.hinge, HarborDefaults.fallback.hinge);
    expect(_read.toastTiming, HarborDefaults.fallback.toastTiming);
  });

  testWidgets('a Material sheet opened under them is announced as a modal bottom sheet\'s', (
    final WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    late BuildContext page;
    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (final BuildContext context, final Widget? child) =>
            HarborRoot(defaults: HarborMaterialDefaults.of(context), child: child!),
        home: HarborFrame(
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    unawaited(
      showHarborSheet<void>(page, builder: (final _) => const HarborMaterialSheet(body: SizedBox(height: 200))),
    );
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Dismiss'),
      findsOneWidget,
      reason: 'the barrier, labelled with modalBarrierDismissLabel',
    );
    semantics.dispose();
  });
}
