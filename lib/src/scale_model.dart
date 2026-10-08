import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'coast.dart';
import 'controller.dart';

/// A scale model: lays [child] out on a fixed reference screen (a TV's
/// 1200×675, say) and scales it to fit the real one, letterboxed.
///
/// Everything inside sees the reference size, and the real screen's insets
/// re-based into the model: cut to the part of the model they actually reach
/// and scaled into its coordinates. A notch beside a letterboxed model doesn't
/// reach it, so the model's coast there is zero. Then [coast] applies, so a
/// model can add a title-safe band of its own.
///
/// Mount it above the `Navigator` (in `MaterialApp.builder`) so routes, dialogs
/// and sheets are all inside the model.
class HarborScaleModel extends StatelessWidget {
  const HarborScaleModel({
    super.key,
    required this.referenceSize,
    this.devicePixelRatio,
    this.coast = HarborCoast.ambient,
    this.letterbox = const Color(0xFF000000),
    required this.child,
  });

  final Size referenceSize;

  /// The pixel ratio the model reports; null scales the real one.
  final double? devicePixelRatio;

  final HarborCoast coast;
  final Color letterbox;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData outer = MediaQuery.of(context);
    return ColoredBox(
      color: letterbox,
      child: LayoutBuilder(
        builder: (final BuildContext context, final BoxConstraints constraints) {
          final Size host = constraints.biggest;
          final double scale = math.min(host.width / referenceSize.width, host.height / referenceSize.height);
          final Size rendered = referenceSize * scale;
          final Offset origin = Offset((host.width - rendered.width) / 2, (host.height - rendered.height) / 2);
          EdgeInsets reach(final EdgeInsets insets) => EdgeInsets.fromLTRB(
            math.max(0.0, insets.left - origin.dx) / scale,
            math.max(0.0, insets.top - origin.dy) / scale,
            math.max(0.0, insets.right - (host.width - origin.dx - rendered.width)) / scale,
            math.max(0.0, insets.bottom - (host.height - origin.dy - rendered.height)) / scale,
          );
          final MediaQueryData model = outer.copyWith(
            size: referenceSize,
            devicePixelRatio: devicePixelRatio ?? outer.devicePixelRatio * scale,
            padding: reach(outer.padding),
            viewPadding: reach(outer.viewPadding),
            viewInsets: reach(outer.viewInsets),
          );
          return Center(
            child: SizedBox.fromSize(
              size: rendered,
              child: FittedBox(
                child: SizedBox.fromSize(
                  size: referenceSize,
                  child: MediaQuery(
                    data: coast.apply(model, Directionality.of(context)),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Opens [builder]'s dialog over [context].
///
/// A dialog is a new port: by default it sees only the coast. With
/// [inheritClearWater], it sees the opening harbor's docks as coast too, so a
/// contextual menu opened from a message stays between that page's header and
/// its composer rather than only clear of the status bar.
Future<T?> showHarborDialog<T>(
  final BuildContext context, {
  required final WidgetBuilder builder,
  final bool inheritClearWater = false,
  final Color barrierColor = const Color(0x88000000),
  final bool barrierDismissible = true,
  final bool useRootNavigator = true,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final CapturedThemes themes = InheritedTheme.capture(from: context, to: navigator.context);
  EdgeInsets? inherited;
  if (inheritClearWater) {
    final Rect? clear = HarborController.maybeOf(context)?.clearWaterInGlobal();
    // Measured against the navigator's overlay, where the dialog will be, so a
    // scale model between the two is accounted for.
    final RenderObject? overlay = navigator.overlay?.context.findRenderObject();
    if (clear != null && overlay is RenderBox && overlay.hasSize) {
      final Offset topLeft = overlay.globalToLocal(clear.topLeft);
      final Offset bottomRight = overlay.globalToLocal(clear.bottomRight);
      final Size size = overlay.size;
      inherited = EdgeInsets.fromLTRB(
        math.max(0.0, topLeft.dx),
        math.max(0.0, topLeft.dy),
        math.max(0.0, size.width - bottomRight.dx),
        math.max(0.0, size.height - bottomRight.dy),
      );
    }
  }
  return navigator.push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Close dialog',
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (final BuildContext context, final Animation<double> animation, final Animation<double> _) {
        // A Builder, so the builder's own context sees the captured themes (as for sheets and signals).
        Widget dialog = themes.wrap(Builder(builder: builder));
        final EdgeInsets? insets = inherited;
        if (insets != null) {
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          dialog = MediaQuery(
            data: mediaQuery.copyWith(
              padding: insets,
              viewPadding: insets,
              viewInsets: EdgeInsets.zero,
            ),
            child: dialog,
          );
        }
        // Kept to one screen of a foldable, never across its hinge, as a Material dialog is; and with
        // reduced motion it is simply there.
        return DisplayFeatureSubScreen(
          child: FadeTransition(opacity: MediaQuery.disableAnimationsOf(context) ? kAlwaysCompleteAnimation : animation, child: dialog),
        );
      },
    ),
  );
}
