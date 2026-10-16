// An AppBar's systemOverlayStyle sets the status bar from a top bar, as it does from a Scaffold.
//
// The platform reads the status bar's style from the SystemUiOverlayStyle annotation at the
// middle of the status bar (RenderView._updateSystemChrome), and an AppBar annotates its own box.
// Under a Scaffold that box runs under the status bar; a bar pads its child below it, so through
// 1.0.0-dev.1 the lookup found nothing there and the app's style was never applied. A bar now
// answers a lookup in the system edge it pads from the nearest point of its child.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

/// What the platform would read for the status bar: the annotation at the screen's horizontal
/// centre, halfway down the status bar, in the view's physical pixels, as RenderView looks it up.
SystemUiOverlayStyle? _statusBarStyle(final WidgetTester tester) {
  final RenderView view = tester.binding.renderViews.first;
  return view.debugLayer!.find<SystemUiOverlayStyle>(Offset(view.paintBounds.center.dx, tester.view.padding.top / 2.0));
}

/// What Android would read for its navigation bar: halfway up the bottom system edge.
SystemUiOverlayStyle? _navigationBarStyle(final WidgetTester tester) {
  final RenderView view = tester.binding.renderViews.first;
  return view.debugLayer!.find<SystemUiOverlayStyle>(
    Offset(view.paintBounds.center.dx, view.paintBounds.bottom - 1.0 - tester.view.padding.bottom / 2.0),
  );
}

const SystemUiOverlayStyle _style = SystemUiOverlayStyle.light;

Widget _app({required final Widget home}) => MaterialApp(
  builder: (final BuildContext context, final Widget? child) => HarborRoot(child: child!),
  home: home,
);

void main() {
  testWidgets('a Scaffold app bar sets the status bar (the reference)', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(systemOverlayStyle: _style, title: const Text('Inbox')),
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(_statusBarStyle(tester), _style);
  });

  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    for (final HarborBarKind kind in HarborBarKind.values) {
      testWidgets('an AppBar in a top bar (${kind.name}) sets the status bar on ${device.name}', (
        final WidgetTester tester,
      ) async {
        final AppBar appBar = AppBar(systemOverlayStyle: _style, title: const Text('Inbox'));
        await tester.pumpHarborTrial(
          _app(
            home: HarborFrame(
              top: <HarborBar>[
                switch (kind) {
                  HarborBarKind.solid => HarborBar.solid(child: appBar),
                  HarborBarKind.overlay => HarborBar.overlay(child: appBar),
                },
              ],
              body: const SizedBox.expand(),
            ),
          ),
          device: device,
        );
        expect(tester.getTopLeft(find.byType(AppBar)).dy, device.systemEdges.top, reason: 'padded below it');
        expect(_statusBarStyle(tester), _style);
      });
    }
  }

  testWidgets('a bar whose child sets no style leaves the status bar to the page', (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        home: const AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: HarborFrame(
            top: <HarborBar>[HarborBar.solid(child: SizedBox(width: double.infinity, height: 56))],
            body: SizedBox.expand(),
          ),
        ),
      ),
    );
    expect(_statusBarStyle(tester), SystemUiOverlayStyle.dark);
  });

  testWidgets("a bottom bar's style reaches Android's navigation bar", (final WidgetTester tester) async {
    await tester.pumpHarborTrial(
      _app(
        home: const HarborFrame(
          bottom: <HarborBar>[
            HarborBar.solid(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: _style,
                child: SizedBox(width: double.infinity, height: 56),
              ),
            ),
          ],
          body: SizedBox.expand(),
        ),
      ),
      device: HarborTrialDevice.androidThreeButton,
    );
    expect(_navigationBarStyle(tester), _style);
    expect(_statusBarStyle(tester), isNull, reason: 'the bottom bar says nothing about the top');
  });

  testWidgets('a top bar inside another takes no system edge and carries nothing over it', (
    final WidgetTester tester,
  ) async {
    await tester.pumpHarborTrial(
      _app(
        home: HarborFrame(
          top: <HarborBar>[
            const HarborBar.solid(child: SizedBox(width: double.infinity, height: 40)),
            HarborBar.solid(
              child: AppBar(systemOverlayStyle: _style, title: const Text('Inbox')),
            ),
          ],
          body: const SizedBox.expand(),
        ),
      ),
    );
    expect(_statusBarStyle(tester), isNull);
  });
}
