// HarborTideSource (#71): a keyboard the platform does not report, fed into the tide through
// MediaQuery, put through sea trials as a platform keyboard would be.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _composer = 44;
const double _tabs = 50;
const HarborTrialDevice _device = HarborTrialDevice.iPhone17; // 874 tall, a 34 home indicator, a 336 keyboard

int _builds = 0;

/// Counts its builds; it reads nothing, so only a rebuild from above builds it again.
class _Counted extends StatelessWidget {
  const _Counted();

  @override
  Widget build(final BuildContext context) {
    _builds++;
    return const SizedBox.expand(key: ValueKey<String>('body'));
  }
}

Widget _app(final ValueListenable<double> source) => HarborTideSource(
  height: source,
  child: const HarborSea(
    child: Harbor(
      bottom: <HarborDock>[
        HarborDock.quay(
          tide: HarborTideStance.float,
          child: SizedBox(key: ValueKey<String>('composer'), height: _composer),
        ),
        HarborDock.quay(child: SizedBox(key: ValueKey<String>('tabs'), height: _tabs)),
      ],
      body: _Counted(),
    ),
  ),
);

Rect _rect(final WidgetTester tester, final String key) => tester.getRect(find.byKey(ValueKey<String>(key)));

Future<void> _follow(final WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('a source raises the tide: the floating composer rides it and the tab bar on pilings is covered', (
    final tester,
  ) async {
    final ValueNotifier<double> source = ValueNotifier<double>(0);
    addTearDown(source.dispose);
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(source), device: _device);
    final double screen = _device.size.height;
    expect(_rect(tester, 'composer').bottom, screen - 34 - _tabs);
    expect(_rect(tester, 'tabs').bottom, screen - 34);

    source.value = 280;
    await _follow(tester);
    expect(_rect(tester, 'composer').bottom, screen - 280, reason: 'the composer floats on the source');
    expect(_rect(tester, 'tabs').bottom, screen - 34, reason: 'the tab bar stands on pilings under it');
    expect(trial.clearWaterAround(find.byKey(const ValueKey<String>('body'))).bottom, screen - 280 - _composer);
    expect(HarborTide.of(tester.element(find.byKey(const ValueKey<String>('body')))).height, 280);

    source.value = 0;
    await _follow(tester);
    expect(_rect(tester, 'composer').bottom, screen - 34 - _tabs);
  });

  testWidgets('the tide is the larger of the platform keyboard and the source, never their sum', (final tester) async {
    final ValueNotifier<double> source = ValueNotifier<double>(200);
    addTearDown(source.dispose);
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_app(source), device: _device);
    final double screen = _device.size.height;
    await _follow(tester);
    expect(_rect(tester, 'composer').bottom, screen - 200);

    await trial.raiseTide(); // the platform's 336 is larger
    expect(_rect(tester, 'composer').bottom, screen - _device.tideHeight);

    source.value = 400; // now the source is
    await _follow(tester);
    expect(_rect(tester, 'composer').bottom, screen - 400);

    source.value = 100; // and the platform again
    await _follow(tester);
    expect(_rect(tester, 'composer').bottom, screen - _device.tideHeight);

    await trial.lowerTide();
    expect(_rect(tester, 'composer').bottom, screen - 100);
  });

  testWidgets('a source that changes rebuilds the MediaQuery, not the app under it', (final tester) async {
    final ValueNotifier<double> source = ValueNotifier<double>(0);
    addTearDown(source.dispose);
    await tester.pumpSeaTrial(_app(source), device: _device);
    final int before = _builds;

    source.value = 280;
    await _follow(tester);
    expect(_builds, before);
  });
}
