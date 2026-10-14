import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor/harbor.dart';
import 'package:harbor_test/harbor_test.dart';
import 'package:harbor_example/art/palette.dart';
import 'package:harbor_example/game/widgets.dart';
import 'package:harbor_example/scenes/registration.dart';

Widget _app() => MaterialApp(
  theme: Palette.theme(),
  builder: (final BuildContext context, final Widget? child) =>
      HarborRoot(margin: const EdgeInsetsDirectional.symmetric(horizontal: 16), child: child!),
  home: const HarborPage(child: RegistrationPage()),
);

final Finder _footer = find.byKey(RegistrationPage.footerKey);
final Finder _crest = find.byKey(RegistrationPage.crestKey);

Finder _field(final Key key) => find.descendant(of: find.byKey(key), matching: find.byType(EditableText));

/// Scrolls the field with [key] into sight and taps it, as a sailor would.
Future<void> _tapField(final WidgetTester tester, final Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.pump();
  await tester.tap(_field(key));
  await tester.pump();
}

Future<HarborTrial> _pumpForm(final WidgetTester tester, final HarborTrialDevice device) async {
  final HarborTrial trial = await tester.pumpHarborTrial(_app(), device: device);
  await tester.pump();
  return trial;
}

void main() {
  for (final HarborTrialDevice device in HarborTrialDevice.phones) {
    group(device.name, () {
      testWidgets('the footer stays put while the keyboard covers it', (final WidgetTester tester) async {
        final HarborTrial trial = await _pumpForm(tester, device);
        final Rect before = tester.getRect(_footer);
        expect(before.bottom, device.size.height - device.systemEdges.bottom);

        await _tapField(tester, RegistrationPage.boatNameKey);
        await trial.showKeyboard();

        expect(tester.getRect(_footer), before);
        expect(find.text('At least 8 knots'), findsNothing);
      });

      testWidgets('the focused field is kept in sight above the keyboard', (final WidgetTester tester) async {
        final HarborTrial trial = await _pumpForm(tester, device);
        await _tapField(tester, RegistrationPage.emailKey);
        await trial.showKeyboard();

        final Rect field = tester.getRect(find.byKey(RegistrationPage.emailKey));
        expect(field.bottom, lessThanOrEqualTo(trial.keyboardTop));
        expect(field.top, greaterThanOrEqualTo(trial.roomAround(_footer).top));
      });

      testWidgets('the footer rides the keyboard while the password has focus', (final WidgetTester tester) async {
        final HarborTrial trial = await _pumpForm(tester, device);
        await _tapField(tester, RegistrationPage.passwordKey);
        expect(find.text('At least 8 knots'), findsOneWidget);

        await trial.showKeyboard();

        expect(tester.getRect(_footer).bottom, trial.keyboardTop);
        final Rect field = tester.getRect(find.byKey(RegistrationPage.passwordKey));
        expect(field.bottom, lessThanOrEqualTo(tester.getRect(_footer).top));

        // Back to another field: the same bar stays put again.
        await _tapField(tester, RegistrationPage.homePortKey);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('At least 8 knots'), findsNothing);
        expect(tester.getRect(_footer).bottom, device.size.height - device.systemEdges.bottom);
      });

      testWidgets('the crest shrinks as the keyboard comes in', (final WidgetTester tester) async {
        final HarborTrial trial = await _pumpForm(tester, device);
        expect(tester.getSize(_crest).height, 120);

        await _tapField(tester, RegistrationPage.boatNameKey);
        await trial.showKeyboard();

        expect(tester.getSize(_crest).height, 48);
        expect(HarborKeyboard.of(tester.element(_crest)).height, device.keyboardHeight);
      });
    });
  }
}
