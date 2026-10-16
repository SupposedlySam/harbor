// HarborSheet(headerBar:, footerBar:): a sheet's header and footer are bars, and until this step
// four of a bar's options were copied onto the sheet (headerEdgeEffect, footerEdgeEffect,
// footerMinimum, footerKeyboard) while the rest could not be set at all: a sheet's footer could not
// withdraw while the keyboard is up, as a page's tool strip can. The plain header: and footer: keep
// the sheet's own bars, published as HarborSheet.defaultHeaderBar and defaultFooterBar.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<(HarborTrial, BuildContext)> _page(
  final WidgetTester tester, {
  final HarborTrialDevice device = HarborTrialDevice.iPhone17,
}) async {
  late BuildContext page;
  final HarborTrial trial = await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final c, final child) => HarborRoot(child: child!),
      home: HarborFrame(
        body: Builder(
          builder: (final c) {
            page = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
    device: device,
  );
  return (trial, page);
}

Future<void> _open(final WidgetTester tester, final BuildContext page, final Widget sheet) async {
  unawaited(showHarborSheet<void>(page, builder: (final BuildContext _) => sheet));
  await tester.pumpAndSettle();
}

const Widget _title = SizedBox(key: ValueKey<String>('title'), width: double.infinity, height: 40);
const Widget _actions = ColoredBox(
  key: ValueKey<String>('actions'),
  color: Color(0xFF000000),
  child: SizedBox(width: double.infinity, height: 48),
);
const Widget _body = SizedBox(key: ValueKey<String>('body'), width: double.infinity, height: 200);

void main() {
  test('the default bars are the sheet look: a faded overlay header, a solid footer that rides', () {
    final HarborBar header = HarborSheet.defaultHeaderBar(_title);
    expect(header.kind, HarborBarKind.overlay);
    expect(header.edgeEffect, const HarborEdgeEffect.fade(length: 12));
    expect(header.child, same(_title));
    final HarborBar footer = HarborSheet.defaultFooterBar(_actions);
    expect(footer.kind, HarborBarKind.solid);
    expect(footer.keyboard, HarborKeyboardStance.rides);
    expect(footer.edgeEffect, const HarborEdgeEffect.hairline());
    expect(footer.minimum, 16);
  });

  testWidgets('a plain header and footer sit where the default bars do', (final tester) async {
    final (_, BuildContext page) = await _page(tester, device: HarborTrialDevice.iPhoneSE);
    await _open(tester, page, const HarborSheet(header: _title, footer: _actions, body: _body));
    final (Rect title, Rect actions, Rect body) = (
      _rect(tester, 'title'),
      _rect(tester, 'actions'),
      _rect(tester, 'body'),
    );
    Navigator.of(page).pop();
    await tester.pumpAndSettle();

    await _open(
      tester,
      page,
      HarborSheet(
        headerBar: HarborSheet.defaultHeaderBar(_title),
        footerBar: HarborSheet.defaultFooterBar(_actions),
        body: _body,
      ),
    );
    expect(_rect(tester, 'title'), title);
    expect(_rect(tester, 'actions'), actions);
    expect(_rect(tester, 'body'), body);
    // Positive control: on a phone with no home indicator the footer keeps its minimum, 16.
    expect(actions.bottom, 667 - 16);
  });

  testWidgets("a footerBar takes any bar option: one that withdraws while the keyboard is up", (final tester) async {
    final (HarborTrial trial, BuildContext page) = await _page(tester);
    await _open(
      tester,
      page,
      const HarborSheet(
        footerBar: HarborBar.solid(keyboard: HarborKeyboardStance.withdraws, child: _actions),
        body: _body,
      ),
    );
    expect(find.byKey(const ValueKey<String>('actions')).hitTestable(), findsOneWidget);
    await trial.showKeyboard(settle: true);
    expect(
      find.byKey(const ValueKey<String>('actions')).hitTestable(),
      findsNothing,
      reason: 'it withdrew, which no footer option could say before',
    );
    await trial.hideKeyboard(settle: true);
    expect(find.byKey(const ValueKey<String>('actions')).hitTestable(), findsOneWidget);
  });

  testWidgets('a headerBar with no fade: the body starts under the header, not past a fade', (final tester) async {
    final (_, BuildContext page) = await _page(tester);
    await _open(
      tester,
      page,
      HarborSheet(
        headerBar: const HarborBar.overlay(child: _title),
        body: HarborScrollView.box(child: _body),
      ),
    );
    expect(_rect(tester, 'body').top, _rect(tester, 'title').bottom);
    Navigator.of(page).pop();
    await tester.pumpAndSettle();
    await _open(
      tester,
      page,
      HarborSheet(
        header: _title,
        body: HarborScrollView.box(child: _body),
      ),
    );
    expect(_rect(tester, 'body').top, _rect(tester, 'title').bottom + 12, reason: 'positive control: the default fade');
  });

  testWidgets("a draggable sheet's headerBar is its handle, whatever bar it is", (final tester) async {
    final (_, BuildContext page) = await _page(tester);
    await _open(
      tester,
      page,
      HarborSheet.draggable(
        headerBar: const HarborBar.solid(child: _title),
        builder: (final BuildContext context, final ScrollController controller) =>
            ListView(controller: controller, children: const <Widget>[_body]),
      ),
    );
    final double top = _rect(tester, 'title').top;
    await tester.drag(find.byKey(const ValueKey<String>('title')), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(_rect(tester, 'title').top, lessThan(top), reason: 'dragging the header raised the sheet');
  });

  test('a header and a headerBar, or a footer and a footerBar, are an assert', () {
    expect(
      () => HarborSheet(
        header: _title,
        headerBar: const HarborBar.overlay(child: _title),
        body: _body,
      ),
      throwsAssertionError,
    );
    expect(
      () => HarborSheet(
        footer: _actions,
        footerBar: const HarborBar.solid(child: _actions),
        body: _body,
      ),
      throwsAssertionError,
    );
  });
}
