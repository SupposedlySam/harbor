// #164: a nested frame's bars come and go (a bottom bar shown with the keyboard, say). In a debug
// build the frame used to add its inspector report only while a bar took a system edge, which
// changed the frame's root widget and remounted its body, so every State below it started over.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';

const double _header = 56;
const double _bottomBar = 40;
const double _homeIndicator = 34;

int _inits = 0;

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _inits++;
  }

  @override
  Widget build(final BuildContext context) => const SizedBox.expand();
}

Widget _app({required final bool withBar}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(
      size: Size(400, 800),
      padding: EdgeInsets.only(bottom: _homeIndicator),
      viewPadding: EdgeInsets.only(bottom: _homeIndicator),
    ),
    child: HarborRoot(
      child: HarborFrame(
        debugLabel: 'outer',
        top: const <HarborBar>[HarborBar.overlay(child: SizedBox(height: _header))],
        body: HarborFrame(
          debugLabel: 'inner',
          bottom: <HarborBar>[if (withBar) const HarborBar.overlay(child: SizedBox(height: _bottomBar))],
          body: const _Probe(),
        ),
      ),
    ),
  ),
);

List<HarborConsumerRecord> _nestedFramesUnderOuter() => HarborInspector.snapshotAll()
    .firstWhere((final HarborInspectorEntry e) => e.label == 'outer')
    .consumers
    .where((final HarborConsumerRecord r) => r.type == 'HarborFrame')
    .toList();

void main() {
  testWidgets('a nested frame keeps its body mounted while a bar comes and goes', (final tester) async {
    _inits = 0;
    await tester.pumpWidget(_app(withBar: false));
    await tester.pumpWidget(_app(withBar: true));
    await tester.pumpWidget(_app(withBar: false));
    await tester.pumpWidget(_app(withBar: true));
    expect(find.byType(_Probe), findsOneWidget);
    expect(_inits, 1);
  });

  testWidgets('the inspector lists the nested frame only while its bar took an edge', (final tester) async {
    await tester.pumpWidget(_app(withBar: true));
    final List<HarborConsumerRecord> withBar = _nestedFramesUnderOuter();
    expect(withBar.single.edge, HarborEdge.bottom);
    expect(withBar.single.amount, _homeIndicator);

    await tester.pumpWidget(_app(withBar: false));
    expect(_nestedFramesUnderOuter(), isEmpty);
  });
}
