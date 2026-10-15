// Two hinge follow-ups: a popover keeps to the screen that holds its anchor, and a sheet a
// hinge keeps to one screen may fill that screen (fillsScreenAtHinge).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const HarborTrialDevice _dual = HarborTrialDevice.dualScreenOpen; // 540 | 34 hinge | 540, 720 high

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

class _Menu extends StatefulWidget {
  const _Menu({required this.left, this.hinge});

  final double left;
  final HarborHinge? hinge;

  @override
  State<_Menu> createState() => _MenuState();
}

class _MenuState extends State<_Menu> {
  final OverlayPortalController _menu = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    _menu.show();
  }

  @override
  Widget build(final BuildContext context) => Stack(
    children: <Widget>[
      Positioned(
        left: widget.left,
        top: 200,
        child: HarborPopover(
          placement: const HarborAnchored(null, side: HarborAnchorSide.below),
          controller: _menu,
          hinge: widget.hinge,
          popoverBuilder: (final BuildContext _) =>
              const SizedBox(key: ValueKey<String>('menu'), width: 200, height: 120),
          child: const SizedBox(key: ValueKey<String>('row button'), width: 60, height: 40),
        ),
      ),
    ],
  );
}

Future<void> _menu(final WidgetTester tester, {required final double left, final HarborHinge? hinge}) async {
  await tester.pumpHarborTrial(
    MaterialApp(
      builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
      home: HarborFrame(
        body: _Menu(left: left, hinge: hinge),
      ),
    ),
    device: _dual,
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('a popover keeps to the screen that holds its anchor', () {
    testWidgets("a menu from a button by the hinge stays on the button's screen", (final tester) async {
      await _menu(tester, left: 470);
      expect(_rect(tester, 'row button').right, 530, reason: 'positive control: the button is on the left screen');
      expect(_rect(tester, 'menu').right, lessThanOrEqualTo(540 - 8));
    });

    testWidgets('on the right screen, it stays right of the hinge', (final tester) async {
      await _menu(tester, left: 580);
      expect(_rect(tester, 'menu').left, greaterThanOrEqualTo(574 + 8));
    });

    testWidgets('with a policy that keeps off nothing, it is centred on its button across the hinge', (
      final tester,
    ) async {
      await _menu(tester, left: 470, hinge: HarborHinge.never);
      expect(_rect(tester, 'menu').center.dx, _rect(tester, 'row button').center.dx);
      expect(_rect(tester, 'menu').right, greaterThan(540));
    });
  });

  group('a sheet that fills the screen a hinge keeps it to', () {
    Future<BuildContext> page(final WidgetTester tester, {final HarborTrialDevice device = _dual}) async {
      late BuildContext inside;
      await tester.pumpHarborTrial(
        MaterialApp(
          builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
          home: HarborFrame(
            body: Builder(
              builder: (final BuildContext context) {
                inside = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
        device: device,
      );
      return inside;
    }

    late EdgeInsets bodyPadding;
    Widget sheet(final BuildContext _) => HarborSheet(
      body: Builder(
        builder: (final BuildContext context) {
          bodyPadding = MediaQuery.paddingOf(context);
          return const SizedBox(height: 100);
        },
      ),
    );

    testWidgets('positive control: by default it is as tall as its content', (final tester) async {
      unawaited(showHarborSheet<void>(await page(tester), builder: sheet));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(HarborSheet)).height, lessThan(300));
    });

    testWidgets('with fillsScreenAtHinge it takes its screen top to bottom, the status bar as a system edge', (
      final tester,
    ) async {
      unawaited(showHarborSheet<void>(await page(tester), fillsScreenAtHinge: true, builder: sheet));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(HarborSheet)), const Rect.fromLTRB(0, 0, 540, 720));
      expect(bodyPadding.top, 24, reason: 'its body still clears the status bar');
    });

    testWidgets('anchorPoint puts it on the other screen', (final tester) async {
      unawaited(
        showHarborSheet<void>(
          await page(tester),
          fillsScreenAtHinge: true,
          anchorPoint: const Offset(1000, 0),
          builder: sheet,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(HarborSheet)), const Rect.fromLTRB(574, 0, 1114, 720));
    });

    testWidgets('with no hinge it changes nothing', (final tester) async {
      unawaited(
        showHarborSheet<void>(
          await page(tester, device: HarborTrialDevice.iPhone17),
          fillsScreenAtHinge: true,
          builder: sheet,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(HarborSheet)).height, lessThan(300));
    });
  });
}
