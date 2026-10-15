import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _composerHeight = 44;
const double _headerFontSize = 10;

Widget _page() => const HarborRoot(
  child: HarborFrame(
    bottom: <HarborBar>[
      HarborBar.solid(
        keyboard: HarborKeyboardStance.rides,
        child: SizedBox(key: ValueKey<String>('composer'), height: _composerHeight),
      ),
    ],
    body: SizedBox.expand(key: ValueKey<String>('body')),
  ),
);

Widget _pageWithHeader() => const HarborRoot(
  child: HarborFrame(
    top: <HarborBar>[
      HarborBar.solid(
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
const Duration _riseTime = Duration(milliseconds: 300);

/// Plays a [_riseTime] animation each time the keyboard's inset changes, as a
/// composer that slides its toolbar in would.
class _RiseOnInsets extends StatefulWidget {
  const _RiseOnInsets({required this.onController});

  final ValueChanged<AnimationController> onController;

  @override
  State<_RiseOnInsets> createState() => _RiseOnInsetsState();
}

class _RiseOnInsetsState extends State<_RiseOnInsets> with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(vsync: this, duration: _riseTime);
  EdgeInsets? _insets;

  @override
  void initState() {
    super.initState();
    widget.onController(_rise);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);
    if (_insets != null && insets != _insets) {
      _rise.forward(from: 0.0);
    }
    _insets = insets;
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => const SizedBox.expand();
}

void main() {
  testWidgets('puts the device on the view and moves its keyboard', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborTrial trial = await tester.pumpHarborTrial(_page(), device: device);

    expect(tester.view.physicalSize / tester.view.devicePixelRatio, device.size);
    expect(trial.keyboardTop, device.size.height);
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom,
      device.size.height - device.systemEdges.bottom,
    );

    await trial.showKeyboard();

    expect(trial.keyboardShown, isTrue);
    expect(trial.keyboardTop, device.size.height - device.keyboardHeight);
    expect(tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom, trial.keyboardTop);
  });

  testWidgets('pumps only as long as asked after the keyboard moves', (final tester) async {
    late AnimationController rise;
    final HarborTrial trial = await tester.pumpHarborTrial(_RiseOnInsets(onController: (final c) => rise = c));

    await trial.showKeyboard(pumpFor: Duration.zero);

    expect(trial.keyboardShown, isTrue);
    expect(MediaQuery.viewInsetsOf(tester.element(find.byType(_RiseOnInsets))).bottom, trial.device.keyboardHeight);
    expect(rise.status, AnimationStatus.forward);
    expect(rise.value, 0.0);

    await trial.hideKeyboard(pumpFor: const Duration(milliseconds: 150));

    expect(rise.value, 0.5);

    await trial.showKeyboard();

    expect(rise.status, AnimationStatus.completed);
  });

  testWidgets('reports the room and the bars around a widget', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborTrial trial = await tester.pumpHarborTrial(_page(), device: device);
    final Finder body = find.byKey(const ValueKey<String>('body'));

    final Rect room = trial.roomAround(body);

    expect(room.top, device.systemEdges.top);
    expect(room.bottom, device.size.height - device.systemEdges.bottom - _composerHeight);
    expect(trial.barsAround(body).single.edge, HarborEdge.bottom);
    expect(find.byKey(const ValueKey<String>('composer')), isNot(isInRoom(room)));
  });

  test('lists every device preset in all', () {
    const List<HarborTrialDevice> presets = <HarborTrialDevice>[
      HarborTrialDevice.iPhone17,
      HarborTrialDevice.iPhoneSE,
      HarborTrialDevice.androidThreeButton,
      HarborTrialDevice.androidGesture,
      HarborTrialDevice.iPhone17Landscape,
      HarborTrialDevice.androidThreeButtonLandscape,
      HarborTrialDevice.androidGestureLandscape,
      HarborTrialDevice.foldableOpen,
      HarborTrialDevice.dualScreenOpen,
      HarborTrialDevice.dualScreenCover,
      HarborTrialDevice.television,
    ];

    expect(HarborTrialDevice.all, orderedEquals(presets));
  });

  testWidgets('puts the device on the view at its pixel ratio', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborTrial trial = await tester.pumpHarborTrial(_page(), device: device);
    final MediaQueryData media = MediaQueryData.fromView(tester.view);

    expect(tester.view.devicePixelRatio, 3.0);
    expect(tester.view.physicalSize, device.size * 3.0);
    expect(media.size, device.size);
    expect(media.viewPadding, device.systemEdges);

    await trial.showKeyboard();

    expect(MediaQueryData.fromView(tester.view).viewInsets.bottom, device.keyboardHeight);
    expect(tester.getRect(find.byKey(const ValueKey<String>('composer'))).bottom, trial.keyboardTop);
  });

  testWidgets('puts a copied device on the view at the pixel ratio it was given', (final tester) async {
    final HarborTrialDevice device = HarborTrialDevice.iPhone17.copyWith(devicePixelRatio: 1.0);
    await tester.pumpHarborTrial(_page(), device: device);

    expect(tester.view.devicePixelRatio, 1.0);
    expect(tester.view.physicalSize, HarborTrialDevice.iPhone17.size);
    expect(MediaQueryData.fromView(tester.view).viewPadding, HarborTrialDevice.iPhone17.systemEdges);
  });

  group('an Android phone on its side', () {
    test('is its portrait self turned: the width and height swapped, at the same ratio', () {
      expect(HarborTrialDevice.androidThreeButtonLandscape.size, HarborTrialDevice.androidThreeButton.size.flipped);
      expect(HarborTrialDevice.androidGestureLandscape.size, HarborTrialDevice.androidGesture.size.flipped);
      expect(
        HarborTrialDevice.androidThreeButtonLandscape.devicePixelRatio,
        HarborTrialDevice.androidThreeButton.devicePixelRatio,
      );
      expect(
        HarborTrialDevice.androidGestureLandscape.devicePixelRatio,
        HarborTrialDevice.androidGesture.devicePixelRatio,
      );
    });

    testWidgets('with three buttons, keeps the status bar on top and the navigation bar on the right', (
      final tester,
    ) async {
      const HarborTrialDevice device = HarborTrialDevice.androidThreeButtonLandscape;
      final HarborTrial trial = await tester.pumpHarborTrial(_page(), device: device);
      MediaQueryData media() => MediaQueryData.fromView(tester.view);

      expect(media().size, const Size(915.0, 412.0));
      expect(media().padding, const EdgeInsets.only(top: 24.0, right: 48.0));
      expect(media().viewPadding, device.systemEdges);

      await trial.showKeyboard();

      expect(media().viewInsets.bottom, 200.0);
      expect(
        media().padding,
        const EdgeInsets.only(top: 24.0, right: 48.0),
        reason: 'the side bar stays under the keyboard',
      );
    });

    testWidgets(
      'with gestures, keeps the status bar on top, the camera on the left and the gesture bar at the bottom',
      (final tester) async {
        const HarborTrialDevice device = HarborTrialDevice.androidGestureLandscape;
        final HarborTrial trial = await tester.pumpHarborTrial(_page(), device: device);
        MediaQueryData media() => MediaQueryData.fromView(tester.view);

        expect(media().size, const Size(915.0, 412.0));
        expect(media().padding, const EdgeInsets.only(top: 24.0, left: 24.0, bottom: 24.0));
        expect(media().viewPadding, device.systemEdges);

        await trial.showKeyboard();

        expect(media().viewInsets.bottom, 200.0);
        expect(
          media().padding,
          const EdgeInsets.only(top: 24.0, left: 24.0),
          reason: 'the keyboard covers the gesture bar',
        );
      },
    );
  });

  testWidgets('clears a bar at the size its text grew to', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    const double textScaleFactor = 2.0;
    final HarborTrial trial = await tester.pumpHarborTrial(
      _pageWithHeader(),
      device: device,
      textScaleFactor: textScaleFactor,
    );
    final Finder body = find.byKey(const ValueKey<String>('body'));

    expect(MediaQuery.textScalerOf(tester.element(body)).scale(_headerFontSize), _headerFontSize * textScaleFactor);
    expect(tester.getSize(find.byKey(const ValueKey<String>('header'))).height, _headerFontSize * textScaleFactor);
    expect(trial.roomAround(body).top, device.systemEdges.top + _headerFontSize * textScaleFactor);
  });

  testWidgets('leaves the text scale as it found it once a trial ends', (final tester) async {
    expect(tester.platformDispatcher.textScaleFactor, 1.0);
  });

  testWidgets('fails the test when no frame is around a widget', (final tester) async {
    final HarborTrial trial = await tester.pumpHarborTrial(const SizedBox(key: ValueKey<String>('alone')));

    expect(
      () => trial.roomAround(find.byKey(const ValueKey<String>('alone'))),
      throwsA(isA<TestFailure>().having((final e) => e.message, 'message', contains("[<'alone'>]"))),
    );
  });
}
