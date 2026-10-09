import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'barrier_label.dart';
import 'controller.dart';

/// Opens [builder]'s dialog over [context].
///
/// It pushes a [HarborDialogRoute] built from these options onto the navigator
/// above [context] (the root one unless [useRootNavigator] is false), as
/// `showDialog` pushes a `DialogRoute`. Push a [HarborDialogRoute] yourself to
/// keep the route, or to push it with a navigator of your choosing.
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
/// with reduced motion the dialog is simply there. [transitionBuilder] brings
/// an entrance and exit of your own in place of the fade, as
/// `showGeneralDialog`'s does; see [HarborDialogRoute.transitionBuilder].
///
/// See also:
///
///  * [showGeneralDialog], the closest Flutter function.
///  * [HarborDialogRoute], the route this pushes.
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
  final RouteTransitionsBuilder? transitionBuilder,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    HarborDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      inheritClearWater: inheritClearWater,
      barrierColor: barrierColor,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      semanticLabel: semanticLabel,
      settings: routeSettings,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      requestFocus: requestFocus,
      animationStyle: animationStyle,
      transitionBuilder: transitionBuilder,
    ),
  );
}

/// The route [showHarborDialog] pushes: a [RawDialogRoute] that builds a
/// harbor dialog, as Material's `DialogRoute` is the route `showDialog`
/// pushes.
///
/// Push it yourself to keep the route (to ask `isActive`, or to
/// `Navigator.removeRoute` it), or to push it with a navigator of your
/// choosing:
///
/// ```dart
/// final HarborDialogRoute<bool> confirm = HarborDialogRoute<bool>(
///   context: context,
///   builder: (context) => const ConfirmDelete(),
/// );
/// final bool? delete = await Navigator.of(context).push(confirm);
/// ```
///
/// It takes [showHarborDialog]'s options, with `settings` for its
/// `routeSettings`. `context` is the page that opens it: the dialog keeps its
/// themes (unless `themes` are given, as `DialogRoute` takes them), and with
/// [inheritClearWater] it keeps clear of the docks of the harbor around it.
/// Both are read when the route is installed, as it is pushed, not when it is
/// constructed, since the clear water is measured against the overlay of the
/// navigator it is pushed onto. So `context` must still be mounted when the
/// route is pushed; if it is not, the dialog opens with neither.
class HarborDialogRoute<T> extends RawDialogRoute<T> {
  /// A route that builds [builder]'s dialog over the page at [context].
  HarborDialogRoute({
    required final BuildContext context,
    required final WidgetBuilder builder,
    final CapturedThemes? themes,
    final bool inheritClearWater = false,
    final Color? barrierColor = const Color(0x80000000),
    final bool barrierDismissible = true,
    final String? barrierLabel,
    final String? semanticLabel,
    final RouteSettings? settings,
    final Offset? anchorPoint,
    final TraversalEdgeBehavior? traversalEdgeBehavior,
    final bool? requestFocus,
    final AnimationStyle? animationStyle,
    final RouteTransitionsBuilder? transitionBuilder,
  }) : this._(
         builder: builder,
         inheritClearWater: inheritClearWater,
         barrierColor: barrierColor,
         barrierDismissible: barrierDismissible,
         barrierLabel: barrierLabel,
         semanticLabel: semanticLabel,
         settings: settings,
         anchorPoint: anchorPoint,
         traversalEdgeBehavior: traversalEdgeBehavior,
         requestFocus: requestFocus,
         animationStyle: animationStyle,
         transitionBuilder: transitionBuilder,
         page: _HarborDialogPage(context, themes),
       );

  HarborDialogRoute._({
    required final WidgetBuilder builder,
    required this.inheritClearWater,
    required super.barrierColor,
    required super.barrierDismissible,
    required final String? barrierLabel,
    required final String? semanticLabel,
    required super.settings,
    required super.anchorPoint,
    required super.traversalEdgeBehavior,
    required super.requestFocus,
    required final AnimationStyle? animationStyle,
    required this.transitionBuilder,
    required final _HarborDialogPage page,
  }) : _animationStyle = animationStyle,
       _page = page,
       super(
         barrierLabel: barrierLabel ?? harborBarrierDismissLabel,
         transitionDuration: animationStyle?.duration ?? _duration,
         pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) =>
             page.build(context, builder, semanticLabel),
       );

  static const Duration _duration = Duration(milliseconds: 180);

  /// Whether the dialog sees the opening harbor's docks as coast, as
  /// [showHarborDialog]'s `inheritClearWater` does. Measured when the route is
  /// installed.
  final bool inheritClearWater;

  /// Builds the dialog's entrance and exit, in place of its fade, as
  /// `showGeneralDialog`'s `transitionBuilder` does. Null keeps the fade.
  ///
  /// `animation` is the route's animation curved by the `animationStyle`'s
  /// `curve` and `reverseCurve`, over the style's durations. With reduced
  /// motion (`MediaQuery.disableAnimations`) `animation` is
  /// [kAlwaysCompleteAnimation] and `secondaryAnimation`
  /// [kAlwaysDismissedAnimation], so the dialog is simply there whatever the
  /// builder does with them.
  final RouteTransitionsBuilder? transitionBuilder;

  final AnimationStyle? _animationStyle;
  final _HarborDialogPage _page;
  CurvedAnimation? _curved;

  @override
  Duration get reverseTransitionDuration => _animationStyle?.reverseDuration ?? transitionDuration;

  @override
  void install() {
    final BuildContext? context = _page.opener;
    // The opening page is read once, as the route goes in, and not held after.
    _page.opener = null;
    final NavigatorState navigator = this.navigator!;
    if (context != null && context.mounted) {
      _page.themes ??= InheritedTheme.capture(from: context, to: navigator.context);
      if (inheritClearWater) {
        _page.inherited = _clearWaterInOverlay(context, navigator);
      }
    }
    super.install();
  }

  /// The opening harbor's clear water as insets of [navigator]'s overlay,
  /// where the dialog will be, so a scale model between the two is accounted
  /// for.
  static EdgeInsets? _clearWaterInOverlay(final BuildContext context, final NavigatorState navigator) {
    final Rect? clear = HarborController.maybeOf(context)?.clearWaterInGlobal();
    final RenderObject? overlay = navigator.overlay?.context.findRenderObject();
    if (clear == null || overlay is! RenderBox || !overlay.hasSize) {
      return null;
    }
    final Offset topLeft = overlay.globalToLocal(clear.topLeft);
    final Offset bottomRight = overlay.globalToLocal(clear.bottomRight);
    final Size size = overlay.size;
    return EdgeInsets.fromLTRB(
      math.max(0.0, topLeft.dx),
      math.max(0.0, topLeft.dy),
      math.max(0.0, size.width - bottomRight.dx),
      math.max(0.0, size.height - bottomRight.dy),
    );
  }

  @override
  Widget buildTransitions(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child,
  ) {
    final RouteTransitionsBuilder? transitionBuilder = this.transitionBuilder;
    if (MediaQuery.disableAnimationsOf(context)) {
      return transitionBuilder?.call(context, kAlwaysCompleteAnimation, kAlwaysDismissedAnimation, child) ??
          FadeTransition(opacity: kAlwaysCompleteAnimation, child: child);
    }
    if (_curved?.parent != animation) {
      _curved?.dispose();
      _curved = CurvedAnimation(
        parent: animation,
        curve: _animationStyle?.curve ?? Curves.linear,
        reverseCurve: _animationStyle?.reverseCurve,
      );
    }
    final CurvedAnimation curved = _curved!;
    return transitionBuilder?.call(context, curved, secondaryAnimation, child) ?? FadeTransition(opacity: curved, child: child);
  }

  @override
  void dispose() {
    _curved?.dispose();
    super.dispose();
  }
}

/// What a [HarborDialogRoute] reads from the opening page as it is installed,
/// shared with the page builder the route hands its superclass (which cannot
/// refer to the route itself).
class _HarborDialogPage {
  _HarborDialogPage(this.opener, this.themes);

  BuildContext? opener;
  CapturedThemes? themes;
  EdgeInsets? inherited;

  Widget build(final BuildContext context, final WidgetBuilder builder, final String? semanticLabel) {
    // A Builder, so the builder's own context sees the captured themes (as for sheets and flares).
    final Widget content = Builder(builder: builder);
    Widget dialog = themes?.wrap(content) ?? content;
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
  }
}
