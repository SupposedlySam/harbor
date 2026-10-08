import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';

const double _composerHeight = 44;

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
  testWidgets('puts the device on the view and moves its tide', (final tester) async {
    const HarborTrialDevice device = HarborTrialDevice.iPhone17;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_page(), device: device);

    expect(tester.view.physicalSize, device.size);
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

  testWidgets('pumps only as long as asked after the tide moves', (final tester) async {
    late AnimationController rise;
    final HarborSeaTrial trial = await tester.pumpSeaTrial(_RiseOnInsets(onController: (final c) => rise = c));

    await trial.raiseTide(pumpFor: Duration.zero);

    expect(trial.tideIn, isTrue);
    expect(MediaQuery.viewInsetsOf(tester.element(find.byType(_RiseOnInsets))).bottom, trial.device.tideHeight);
    expect(rise.status, AnimationStatus.forward);
    expect(rise.value, 0.0);

    await trial.lowerTide(pumpFor: const Duration(milliseconds: 150));

    expect(rise.value, 0.5);

    await trial.raiseTide();

    expect(rise.status, AnimationStatus.completed);
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
}
