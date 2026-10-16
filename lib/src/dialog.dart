import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'barrier_label.dart';
import 'clear.dart';
import 'controller.dart';
import 'defaults.dart';
import 'hinge.dart';

/// Opens [builder]'s dialog over [context].
///
/// It pushes a [HarborDialogRoute] built from these options onto the navigator
/// above [context] (the root one unless [useRootNavigator] is false), as
/// `showDialog` pushes a `DialogRoute`. Push a [HarborDialogRoute] yourself to
/// keep the route, or to push it with a navigator of your choosing.
///
/// A dialog is a new page: by default it sees only the system edges. With
/// [inheritRoom], it sees the opening frame's bars as system edges too, so a
/// contextual menu opened from a message stays between that page's header and
/// its composer rather than only clear of the status bar.
///
/// The dialog keeps clear of those system edges (the status bar, the home indicator, a cutout), as
/// one from `showDialog` does with its `useSafeArea`, so a tall Material `Dialog` stops short of
/// them as it stops short of the keyboard. They are marked handled, so a [HarborClear] inside does
/// not clear them again. With [clearsSystemEdges] false the dialog runs under them and reads them
/// in `MediaQuery.padding`, for a dialog that lays out against the whole screen.
///
/// The dialog is a [RawDialogRoute], as one from `showGeneralDialog` is: a
/// popup route, so a `Hero` does not fly into it and a `RouteObserver` of
/// page routes does not see it as a page. Its content is a route of its own
/// for screen readers, and [semanticLabel] is the name they announce for it.
///
/// [barrier] is what the dialog puts over the page: [HarborBarrier.dimmed] by default, with
/// `showGeneralDialog`'s half-black, as a sheet's is, or [HarborBarrier.clear]. A dialog is always
/// a route with a barrier, so [HarborBarrier.none] is an assert. A tap on the barrier closes the
/// dialog unless it is not `dismissible`; back still closes it. It is announced with its `label`
/// ('Dismiss' when none is given, the English Material and Cupertino fall back to; a Material app
/// passes `MaterialLocalizations.of(context).modalBarrierDismissLabel` for the localized one), and
/// its `onTapHint` says what tapping it does.
///
/// [routeSettings] reach navigator observers and route-name analytics. [anchorPoint], [traversalEdgeBehavior] and [requestFocus]
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
  final bool inheritRoom = false,
  final HarborBarrier barrier = const HarborBarrier.dimmed(),
  final String? semanticLabel,
  final bool useRootNavigator = true,
  final RouteSettings? routeSettings,
  final Offset? anchorPoint,
  final TraversalEdgeBehavior? traversalEdgeBehavior,
  final bool? requestFocus,
  final AnimationStyle? animationStyle,
  final RouteTransitionsBuilder? transitionBuilder,
  final HarborHinge? hinge,
  final bool clearsSystemEdges = true,
}) {
  final NavigatorState navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    HarborDialogRoute<T>(
      context: context,
      builder: builder,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
      inheritRoom: inheritRoom,
      barrier: barrier,
      semanticLabel: semanticLabel,
      settings: routeSettings,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      requestFocus: requestFocus,
      animationStyle: animationStyle,
      transitionBuilder: transitionBuilder,
      hinge: hinge,
      clearsSystemEdges: clearsSystemEdges,
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
/// [inheritRoom] it keeps clear of the bars of the frame around it.
/// Both are read when the route is installed, as it is pushed, not when it is
/// constructed, since the room is measured against the overlay of the
/// navigator it is pushed onto. So `context` must still be mounted when the
/// route is pushed; if it is not, the dialog opens with neither.
class HarborDialogRoute<T> extends RawDialogRoute<T> {
  /// A route that builds [builder]'s dialog over the page at [context].
  HarborDialogRoute({
    required final BuildContext context,
    required final WidgetBuilder builder,
    final CapturedThemes? themes,
    final bool inheritRoom = false,
    final HarborBarrier barrier = const HarborBarrier.dimmed(),
    final String? semanticLabel,
    final RouteSettings? settings,
    final Offset? anchorPoint,
    final TraversalEdgeBehavior? traversalEdgeBehavior,
    final bool? requestFocus,
    final AnimationStyle? animationStyle,
    final RouteTransitionsBuilder? transitionBuilder,
    final HarborHinge? hinge,
    final bool clearsSystemEdges = true,
  }) : this._(
         builder: builder,
         inheritRoom: inheritRoom,
         barrier: barrier,
         semanticLabel: semanticLabel,
         settings: settings,
         anchorPoint: anchorPoint,
         traversalEdgeBehavior: traversalEdgeBehavior,
         requestFocus: requestFocus,
         animationStyle: animationStyle,
         transitionBuilder: transitionBuilder,
         defaults: HarborDefaults.read(context),
         hinge: hinge,
         clearsSystemEdges: clearsSystemEdges,
         page: _HarborDialogPage(context, themes),
       );

  HarborDialogRoute._({
    required final WidgetBuilder builder,
    required this.inheritRoom,
    required this.barrier,
    required final String? semanticLabel,
    required super.settings,
    required super.anchorPoint,
    required super.traversalEdgeBehavior,
    required super.requestFocus,
    required final AnimationStyle? animationStyle,
    required this.transitionBuilder,
    required final HarborDefaults defaults,
    required final HarborHinge? hinge,
    required this.clearsSystemEdges,
    required final _HarborDialogPage page,
  }) : hinge = hinge ?? defaults.hinge ?? HarborHinge.avoidSeparating,
       assert(barrier.blocks, 'A dialog is a route with a barrier: give it HarborBarrier.dimmed or .clear, not none.'),
       _animationStyle = animationStyle,
       _page = page,
       super(
         barrierColor: barrier.color,
         barrierDismissible: barrier.isDismissible,
         barrierLabel: barrier.label ?? defaults.barrierLabel ?? harborBarrierDismissLabel,
         transitionDuration: animationStyle?.duration ?? _duration,
         pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) =>
             page.build(context, builder, semanticLabel, clearsSystemEdges: clearsSystemEdges),
       );

  static const Duration _duration = Duration(milliseconds: 180);

  /// What the dialog puts over the page: a dimmed barrier unless it is given another.
  final HarborBarrier barrier;

  /// Which hinges and folds the dialog keeps off: the one given, or the opening page's
  /// [HarborDefaults.hinge], read as the route is made. [anchorPoint] picks the side.
  final HarborHinge hinge;

  // The side of the screen is chosen by the DisplayFeatureSubScreen RawDialogRoute puts around
  // the page, from the display features it reads here: only those the policy keeps off.
  @override
  Widget buildPage(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
  ) => MediaQuery(
    data: hinge.splitting(MediaQuery.of(context)),
    child: super.buildPage(context, animation, secondaryAnimation),
  );

  /// Whether the dialog keeps clear of the system edges (the status bar, the home indicator, a
  /// cutout) and marks them handled, as [showHarborDialog]'s `clearsSystemEdges` does. True by
  /// default. With [inheritRoom] those include the opening frame's bars.
  final bool clearsSystemEdges;

  /// Whether the dialog sees the opening frame's bars as system edges, as
  /// [showHarborDialog]'s `inheritRoom` does. Measured when the route is
  /// installed.
  final bool inheritRoom;

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
      if (inheritRoom) {
        _page.inherited = _roomInOverlay(context, navigator);
      }
    }
    super.install();
  }

  /// The opening frame's room as insets of [navigator]'s overlay,
  /// where the dialog will be, so a scaled screen between the two is accounted
  /// for.
  static EdgeInsets? _roomInOverlay(final BuildContext context, final NavigatorState navigator) {
    final Rect? clear = HarborController.maybeOf(context)?.roomInGlobal();
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
    return transitionBuilder?.call(context, curved, secondaryAnimation, child) ??
        FadeTransition(opacity: curved, child: child);
  }

  // ModalRoute's barrier, with the barrier's tap hint, which ModalRoute has no field for. Without
  // one the route's own barrier is built, as it always was.
  @override
  Widget buildModalBarrier() {
    final String? onTapHint = barrier.onTapHint;
    if (onTapHint == null) {
      return super.buildModalBarrier();
    }
    final Color? color = barrierColor;
    if (color != null && color.a != 0 && !offstage) {
      return AnimatedModalBarrier(
        color: animation!.drive(
          ColorTween(begin: color.withValues(alpha: 0.0), end: color).chain(CurveTween(curve: barrierCurve)),
        ),
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
        semanticsOnTapHint: onTapHint,
      );
    }
    return ModalBarrier(
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
      semanticsOnTapHint: onTapHint,
    );
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

  Widget build(
    final BuildContext context,
    final WidgetBuilder builder,
    final String? semanticLabel, {
    required final bool clearsSystemEdges,
  }) {
    // A Builder, so the builder's own context sees the captured themes (as for sheets and toasts).
    final Widget content = Builder(builder: builder);
    Widget dialog = themes?.wrap(content) ?? content;
    if (semanticLabel != null) {
      dialog = Semantics(
        container: true,
        explicitChildNodes: true,
        namesRoute: true,
        label: semanticLabel,
        child: dialog,
      );
    }
    if (clearsSystemEdges) {
      // As showDialog's SafeArea, but marked handled, so a HarborClear inside does not clear them
      // again. Inside the inherited room below, so the opener's bars are cleared in their place.
      // The keyboard is left in `viewInsets`, where a Material Dialog already keeps off it.
      dialog = HarborClear(clearsKeyboard: false, child: dialog);
    }
    final EdgeInsets? insets = inherited;
    if (insets != null) {
      final MediaQueryData mediaQuery = MediaQuery.of(context);
      dialog = MediaQuery(
        data: mediaQuery.copyWith(padding: insets, viewPadding: insets, viewInsets: EdgeInsets.zero),
        child: dialog,
      );
    }
    return dialog;
  }
}
