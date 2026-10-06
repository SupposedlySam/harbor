import 'package:flutter/widgets.dart';

/// The harbor master's switches: the chart overlay, reading direction and TV mode.
class HarborSettings extends ChangeNotifier {
  bool _chart = false;
  bool _rtl = false;
  bool _tv = false;

  bool get chart => _chart;
  bool get rtl => _rtl;
  bool get tv => _tv;

  set chart(final bool value) => _set(() => _chart = value);
  set rtl(final bool value) => _set(() => _rtl = value);
  set tv(final bool value) => _set(() => _tv = value);

  void _set(final VoidCallback change) {
    change();
    notifyListeners();
  }

  static HarborSettings of(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborSettingsScope>()!.notifier!;
}

class HarborSettingsScope extends InheritedNotifier<HarborSettings> {
  const HarborSettingsScope({super.key, required HarborSettings settings, required super.child}) : super(notifier: settings);
}
