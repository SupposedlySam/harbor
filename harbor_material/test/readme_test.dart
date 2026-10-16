// The README's "after" page, built as written: it compiles, and each piece lands where the README
// says.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_material/harbor_material.dart';
import 'package:harbor_test/harbor_test.dart';

const List<NavigationDestination> destinations = <NavigationDestination>[
  NavigationDestination(icon: Icon(Icons.inbox), label: 'Inbox'),
  NavigationDestination(icon: Icon(Icons.send), label: 'Sent'),
];

final List<Widget> messages = <Widget>[for (int i = 0; i < 40; i++) ListTile(title: Text('Message $i'))];

class ReplyForm extends StatelessWidget {
  const ReplyForm({super.key});

  @override
  Widget build(final BuildContext context) => const HarborClear(child: TextField());
}

void main() {
  testWidgets('the README page', (final WidgetTester tester) async {
    void compose() {}
    void restore() {}
    late BuildContext page;

    await tester.pumpHarborTrial(
      MaterialApp(
        builder: (context, child) => HarborRoot(defaults: HarborMaterialDefaults.of(context), child: child!),
        home: HarborMaterialFrame(
          appBar: AppBar(title: const Text('Inbox')),
          bottom: [HarborBar.solid(child: NavigationBar(destinations: destinations))],
          floats: [
            HarborFloat(
              placement: const HarborAligned(alignment: AlignmentDirectional.bottomEnd),
              child: FloatingActionButton(onPressed: compose, child: const Icon(Icons.edit)),
            ),
          ],
          body: Builder(
            builder: (final BuildContext context) {
              page = context;
              return HarborScrollView(slivers: [SliverList.list(children: messages)]);
            },
          ),
        ),
      ),
    );

    final Rect appBar = tester.getRect(find.byType(AppBar));
    final Rect navigation = tester.getRect(find.byType(NavigationBar));
    final Rect fab = tester.getRect(find.byType(FloatingActionButton));
    expect(appBar.top, HarborTrialDevice.iPhone17.systemEdges.top);
    expect(tester.getRect(find.text('Message 0')).top, greaterThanOrEqualTo(appBar.bottom));
    expect(fab.bottom, lessThanOrEqualTo(navigation.top));

    final BuildContext context = page;
    context.showSnackToast(const Text('Archived'), actionLabel: 'Undo', onAction: restore);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(HarborSnackToast)).bottom, lessThanOrEqualTo(navigation.top));

    // The README leaves the future alone; here the lints ask for it to be said.
    unawaited(
      showHarborSheet(
        context,
        semanticLabel: HarborMaterialSheet.semanticLabelOf(context),
        builder: (_) => const HarborMaterialSheet(showDragHandle: true, elevation: 2, body: ReplyForm()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HarborMaterialDragHandle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
