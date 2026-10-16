import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

/// [HarborDefaults] filled in from Material, as `showModalBottomSheet` and `showDialog` fill them in
/// for themselves.
abstract final class HarborMaterialDefaults {
  /// What Material says for the parts of [HarborDefaults] it has an opinion on, read from
  /// `context`'s `MaterialLocalizations` and `Theme`:
  ///
  ///  * [HarborDefaults.barrierLabel]: `modalBarrierDismissLabel`, what Material's barriers are
  ///    announced as ('Dismiss' in English, and translated).
  ///  * [HarborDefaults.sheetBarrierOnTapHint]: `scrimOnTapHint(bottomSheetLabel)`, as a modal
  ///    bottom sheet's barrier has it ('Close Bottom Sheet').
  ///  * [HarborDefaults.sheetMaxWidth]: the `maxWidth` of the theme's `bottomSheetTheme.constraints`,
  ///    or Material 3's 640 when it sets none; Material 2 sets none, and a sheet spans the screen.
  ///
  /// The rest stay unset, so harbor's own apply. Set more with [HarborDefaults.merge]:
  ///
  /// ```dart
  /// MaterialApp(
  ///   builder: (context, child) => HarborRoot(
  ///     defaults: HarborMaterialDefaults.of(context).merge(const HarborDefaults(toastQueue: HarborToastQueue.replace)),
  ///     child: child!,
  ///   ),
  /// )
  /// ```
  ///
  /// `MaterialApp.builder`'s context is below the app's `Theme` and `Localizations`, so call it
  /// there. Calling it registers `context` with both, so the root is rebuilt with the new words when
  /// the locale changes and the new width when the theme does.
  static HarborDefaults of(final BuildContext context) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    return HarborDefaults(
      barrierLabel: localizations.modalBarrierDismissLabel,
      sheetBarrierOnTapHint: localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      sheetMaxWidth: switch (theme.bottomSheetTheme.constraints) {
        // A theme that sets constraints with no finite width asks for none.
        final BoxConstraints constraints => constraints.maxWidth.isFinite ? constraints.maxWidth : null,
        null => theme.useMaterial3 ? 640.0 : null,
      },
    );
  }
}
