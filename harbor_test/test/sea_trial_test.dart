import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _composerHeight = 44;
const double _headerFontSize = 10;

Widget _page() => const HarborSea(
  child: Harbor(
    bottom: <HarborDock>[
      HarborDock.quay(
        tide: HarborTideStance.float,
        child: SizedBox(key: ValueKey<String>('composer'), height: _composerHeight),
      ),
    ],
    body: SizedBox.expand(key: ValueKey<String>('body')),
  ),
);

Widget _pageWithHeader() => const HarborSea(
  child: Harbor(
    top: <HarborDock>[
      HarborDock.quay(
        child: Text(
          'Settings',
          key: ValueKey<String>('header'),
          style: TextStyle(fontSize: _headerFontSize),
        ),
      ),
    ],
    body: SizedBox.expand(key: ValueKey<String>('body')),
  ),
);

void main() {
  testWidgets('puts the device on the view and moves its tide', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_page(), device: device);

    expect(tester.view.physicalSize / tester.view.devicePixelRatio, device.size);
    expect(trial.waterline, device.size.height);
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom,
      device.size.height - device.coast.bottom,
    );

    await trial.raiseTide();

    expect(trial.tideIn, isTrue);
    expect(trial.waterline, device.size.height - device.tideHeight);
    expect(tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom, trial.waterline);
  });

  testWidgets('reports the clear water and the docks around a widget', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_page(), device: device);
    final Finder body = find.byKey(const ValueKey<String>('body'));

    final Rect clearWater = trial.clearWaterAround(body);

    expect(clearWater.top, device.coast.top);
    expect(clearWater.bottom, device.size.height - device.coast.bottom - _composerHeight);
    expect(trial.docksAround(body).single.edge, HarborEdge.bottom);
    expect(find.byKey(const ValueKey<String>('composer')), isNot(isInClearWater(clearWater)));
  });

  test('lists every device preset in all', () {
    const List<HarborTrialDevice> presets = <HarborTrialDevice>[
      HarborTrialDevice.iPhone17,
      HarborTrialDevice.iPhoneSE,
      HarborTrialDevice.androidThreeButton,
      HarborTrialDevice.androidGesture,
      HarborTrialDevice.iPhone17Landscape,
      HarborTrialDevice.foldableOpen,
      HarborTrialDevice.dualScreenOpen,
      HarborTrialDevice.dualScreenCover,
      HarborTrialDevice.television,
    ];

    expect(HarborTrialDevice.all, orderedEquals(presets));
  });

  testWidgets('puts the device on the view at its pixel ratio', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_page(), device: device);
    final MediaQueryData media = MediaQueryData.fromView(tester.view);

    expect(tester.view.devicePixelRatio, 3.0);
    expect(tester.view.physicalSize, device.size * 3.0);
    expect(media.size, device.size);
    expect(media.viewPadding, device.coast);

    await trial.raiseTide();

    expect(MediaQueryData.fromView(tester.view).viewInsets.bottom, device.tideHeight);
    expect(tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom, trial.waterline);
  });

  testWidgets('puts a copied device on the view at the pixel ratio it was given', (final tester) async {
    final HarborTrialDevice device = HarborTrialDevice.iPhone17.copyWith(devicePixelRatio: 1.0);
    await tester.pumpSeaTrial(_page(), device: device);

    expect(tester.view.devicePixelRatio, 1.0);
    expect(tester.view.physicalSize, HarborTrialDevice.iPhone17.size);
    expect(MediaQueryData.fromView(tester.view).viewPadding, HarborTrialDevice.iPhone17.coast);
  });

  testWidgets('clears a dock at the size its text grew to', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    const double textScaleFactor = 2.0;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(
      _pageWithHeader(),
      device: device,
      textScaleFactor: textScaleFactor,
    );
    final Finder body = find.byKey(const ValueKey<String>('body'));

    expect(MediaQuery.textScalerOf(tester.element(body)).scale(_headerFontSize), _headerFontSize * textScaleFactor);
    expect(tester.getSize(find.byKey(const ValueKey<String>('header'))).height, _headerFontSize * textScaleFactor);
    expect(trial.clearWaterAround(body).top, device.coast.top + _headerFontSize * textScaleFactor);
  });

  testWidgets('leaves the text scale as it found it once a trial ends', (final tester) async {
    expect(tester.platformDispatcher.textScaleFactor, 1.0);
  });

  testWidgets('fails the test when no harbor is around a widget', (final tester) async {
    final HarborSeaTrial trial = await tester.pumpSeaTrial(const SizedBox(key: ValueKey<String>('alone')));

    expect(
      () => trial.clearWaterAround(find.byKey(const ValueKey<String>('alone'))),
      throwsA(isA<TestFailure>().having((final e) => e.message, 'message', contains("[<'alone'>]"))),
    );
  });
}
