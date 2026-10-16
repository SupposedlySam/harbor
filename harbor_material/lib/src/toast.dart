import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

/// A toast in a `SnackBar`'s look, for [HarborToasts.show]: Material's colours, text style, shape
/// and elevation, from the theme's `SnackBarThemeData` and then Material's defaults, with an optional
/// action.
///
/// It is the snack bar's surface only. Where it sits, how long it stays and how it comes and goes
/// are the toast's: a toast keeps clear of the page's bars and the keyboard, and harbor makes it a
/// live region, so this widget adds none. [HarborSnackToasts.showSnackToast] shows one.
///
/// A long action does not wrap below the message as a `SnackBar`'s does; keep its label short.
class HarborSnackToast extends StatelessWidget {
  const HarborSnackToast({
    super.key,
    required this.content,
    this.actionLabel,
    this.onAction,
    this.backgroundColor,
    this.elevation,
    this.shape,
  }) : assert((actionLabel == null) == (onAction == null), 'Give an action both a label and onAction, or neither.');

  /// The message, usually a [Text], in the snack bar's text style.
  final Widget content;

  /// The action's label, as `SnackBarAction.label`.
  final String? actionLabel;

  /// Called when the action is pressed. The toast is hidden after it, as a `SnackBar` is.
  final VoidCallback? onAction;

  /// As `SnackBar.backgroundColor`: the theme's `SnackBarThemeData.backgroundColor` when null, then
  /// Material's.
  final Color? backgroundColor;

  /// As `SnackBar.elevation`: the theme's, then 6.
  final double? elevation;

  /// As `SnackBar.shape`: the theme's, then rounded by 4, a floating snack bar's.
  final ShapeBorder? shape;

  @override
  Widget build(final BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SnackBarThemeData snackBarTheme = SnackBarTheme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool m3 = theme.useMaterial3;
    final bool dark = theme.brightness == Brightness.dark;

    final Color background =
        backgroundColor ??
        snackBarTheme.backgroundColor ??
        (m3
            ? colors.inverseSurface
            : (dark ? colors.onSurface : Color.alphaBlend(colors.onSurface.withValues(alpha: 0.8), colors.surface)));
    final TextStyle? textStyle =
        snackBarTheme.contentTextStyle ??
        (m3
            ? theme.textTheme.bodyMedium?.copyWith(color: colors.onInverseSurface)
            : ThemeData(
                useMaterial3: false,
                brightness: dark ? Brightness.light : Brightness.dark,
              ).textTheme.titleMedium);
    final Color actionColor =
        WidgetStateProperty.resolveAs<Color?>(snackBarTheme.actionTextColor, <WidgetState>{}) ??
        (m3 ? colors.inversePrimary : (dark ? colors.primary : colors.secondary));

    final String? actionLabel = this.actionLabel;
    return Material(
      color: background,
      elevation: elevation ?? snackBarTheme.elevation ?? 6.0,
      shape:
          shape ??
          snackBarTheme.shape ??
          const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: 16, end: actionLabel == null ? 16 : 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: DefaultTextStyle.merge(style: textStyle, child: content),
                ),
              ),
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: actionColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {
                      onAction!();
                      HarborToastEntry.maybeOf(context)?.hide();
                    },
                    child: Text(actionLabel),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a [HarborSnackToast] from a `BuildContext`, as `ScaffoldMessenger.of(context).showSnackBar`
/// shows a `SnackBar`.
extension HarborSnackToasts on BuildContext {
  /// Shows [content] in a [HarborSnackToast] at [slot], low on the page by default, where a snack bar
  /// sits, clear of the page's bars and the keyboard.
  ///
  /// With an action, the toast stays until it is hidden ([HarborToastTiming.untilHidden]), as a
  /// `SnackBar` with an action persists, so a screen reader reaches it in time; otherwise for
  /// [timing], or the defaults' (4 s). The other arguments are [HarborToasts.show]'s.
  ///
  /// ```dart
  /// context.showSnackToast(const Text('Archived'), actionLabel: 'Undo', onAction: restore);
  /// ```
  HarborToastEntry showSnackToast(
    final Widget content, {
    final String? actionLabel,
    final VoidCallback? onAction,
    final HarborToastSlot slot = HarborToastSlot.low,
    final HarborToastTiming? timing,
    final HarborToastQueue? queue,
    final HarborToastTarget target = HarborToastTarget.topmost,
    final AnimationStyle? animationStyle,
    final HarborToastTransitionBuilder? transitionBuilder,
    final HarborHinge? hinge,
  }) => HarborToasts.show(
    this,
    slot: slot,
    timing: timing ?? (actionLabel != null ? HarborToastTiming.untilHidden : null),
    queue: queue,
    target: target,
    animationStyle: animationStyle,
    transitionBuilder: transitionBuilder,
    hinge: hinge,
    builder: (final BuildContext context) =>
        HarborSnackToast(content: content, actionLabel: actionLabel, onAction: onAction),
  );
}
