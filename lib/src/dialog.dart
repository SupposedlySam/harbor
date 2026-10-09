import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'barrier_label.dart';
import 'controller.dart';

/// Opens [builder]'s dialog over [context].
///
/// A dialog is a new port: by default it sees only the coast. With
/// [inheritClearWater], it sees the opening harbor's docks as coast too, so a
/// contextual menu opened from a message stays between that page's header and
/// its composer rather than only clear of the status bar.
///
/// The dialog is a [RawDialogRoute], as one from `showGeneralDialog` is: a
/// popup route, so a `Hero` does not fly into it and a `RouteObserver` of
/// page routes does not see it as a page. Its content is a route of its own
/// for screen readers, and [semanticLabel] is the name they announce for it.
///
/// [routeSettings] reach navigator observers and route-name analytics, and
/// the barrier is announced with [barrierLabel] ('Dismiss' when none is
/// given, the English Material and Cupertino fall back to; a Material app
/// passes `MaterialLocalizations.of(context).modalBarrierDismissLabel` for the
/// localized one). [barrierColor] is `showGeneralDialog`'s, as a sheet's is. [anchorPoint], [traversalEdgeBehavior] and [requestFocus]
/// are as on `showDialog`: the screen of a foldable the dialog opens on, what
/// Tab does past its last control (the navigator's choice when null), and
/// whether it takes focus. [animationStyle] sets the fade, 180 ms by default;
/// with reduced motion the dialog is simply there.
///
/// See also:
///
///  * [showGeneralDialog], the closest Flutter function.
Future<T?> showHarborDialog<T>(
  final BuildContext context, {
  required final WidgetBuilder builder,
  final bool inheritClearWater = false,
  final Color barrierColor = const Color(0x80000000),
  final bool barrierDismissible = true,
  final String? barrierLabel,
  final String? semanticLabel,
  final bool useRootNavigator = true,
  final RouteSettings? routeSettings,
  final Offset? anchorPoint,
  final TraversalEdgeBehavior? traversalEdgeBehavior,
  final bool? requestFocus,
  final AnimationStyle? animationStyle,
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
    _HarborDialogRoute<T>(
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel ?? harborBarrierDismissLabel,
      settings: routeSettings,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      requestFocus: requestFocus,
      animationStyle: animationStyle,
      pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) {
        // A Builder, so the builder's own context sees the captured themes (as for sheets and flares).
        Widget dialog = themes.wrap(Builder(builder: builder));
        if (semanticLabel != null) {
          dialog = Semantics(container: true, explicitChildNodes: true, namesRoute: true, label: semanticLabel, child: dialog);
        }
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
        return dialog;
      },
    ),
  );
}

class _HarborDialogRoute<T> extends RawDialogRoute<T> {
  _HarborDialogRoute({
    required super.pageBuilder,
    required super.barrierColor,
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.settings,
    required super.anchorPoint,
    required super.traversalEdgeBehavior,
    required super.requestFocus,
    required final AnimationStyle? animationStyle,
  }) : _animationStyle = animationStyle,
       super(transitionDuration: animationStyle?.duration ?? _duration);

  static const Duration _duration = Duration(milliseconds: 180);

  final AnimationStyle? _animationStyle;
  CurvedAnimation? _curved;

  @override
  Duration get reverseTransitionDuration => _animationStyle?.reverseDuration ?? transitionDuration;

  @override
  Widget buildTransitions(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return FadeTransition(opacity: kAlwaysCompleteAnimation, child: child);
    }
    if (_curved?.parent != animation) {
      _curved?.dispose();
      _curved = CurvedAnimation(
        parent: animation,
        curve: _animationStyle?.curve ?? Curves.linear,
        reverseCurve: _animationStyle?.reverseCurve,
      );
    }
    return FadeTransition(opacity: _curved!, child: child);
  }

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }
}
