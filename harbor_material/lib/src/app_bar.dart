import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

/// Material's app bars as harbor bars.
///
/// A bar pads its child below the status bar and paints its `backdrop` under the whole of its space,
/// status bar included. Under a `Scaffold` an `AppBar` runs up under the status bar itself, so its
/// colour fills it; in a bar, the backdrop has to. [appBar] gives the bar a backdrop that is the
/// `AppBar`'s own surface, resolved by the `AppBar`'s rules, so the status bar and the toolbar read
/// as one bar, as they do under a `Scaffold`.
abstract final class HarborMaterialBar {
  /// [appBar] in a bar against the top edge, its surface run up behind the status bar.
  ///
  /// The backdrop is a `Material` given what the `AppBar` gives its own: its background colour,
  /// elevation, surface tint and shape, from the `AppBar` itself, then `AppBarTheme`, then
  /// Material's defaults (Material 2: the primary colour, or the surface in a dark theme; Material 3:
  /// the surface). In Material 3 it changes with the `AppBar` when content scrolls under it
  /// (`scrolledUnderElevation`, `surfaceContainer`), heard from the `ScrollNotificationObserver`
  /// above the frame that [HarborMaterialFrame] puts there, as `Scaffold` does. It casts no shadow:
  /// the `AppBar` casts its own. With `forceMaterialTransparency` it paints nothing. A
  /// `PreferredSizeWidget` that is not an `AppBar` (a `PreferredSize` around a custom bar) gets
  /// `AppBarTheme`'s and Material's colours.
  ///
  /// The `AppBar`'s `systemOverlayStyle` sets the status bar's icons from here as it does under a
  /// `Scaffold`: a harbor bar carries its child's style over the system edge it pads.
  ///
  /// [kind] is [HarborBarKind.solid] by default, as `Scaffold.appBar` is: the body starts below it.
  /// [HarborBarKind.overlay] runs the body under it, as `extendBodyBehindAppBar` does. The other
  /// arguments are [HarborBar.solid]'s.
  ///
  /// A translucent `AppBar` colour is painted twice over the toolbar, once by the backdrop and once
  /// by the `AppBar`; for a frosted header, give a [HarborBar] a `backdrop:` of your own.
  static HarborBar appBar(
    final PreferredSizeWidget appBar, {
    final Key? key,
    final HarborBarKind kind = HarborBarKind.solid,
    final HarborEdgeEffect edgeEffect = HarborEdgeEffect.none,
    final HarborBarState state = HarborBarState.open,
    final HarborExtentPolicy extentPolicy = HarborExtentPolicy.hold,
    final AnimationStyle? animationStyle,
    final HitTestBehavior hitTestBehavior = HitTestBehavior.opaque,
    final double minimum = 0.0,
    final String? debugLabel = 'app bar',
  }) {
    final Widget backdrop = HarborMaterialAppBarSurface(appBar: appBar);
    return switch (kind) {
      HarborBarKind.solid => HarborBar.solid(
        key: key,
        edgeEffect: edgeEffect,
        state: state,
        extentPolicy: extentPolicy,
        animationStyle: animationStyle,
        backdrop: backdrop,
        hitTestBehavior: hitTestBehavior,
        minimum: minimum,
        debugLabel: debugLabel,
        child: appBar,
      ),
      HarborBarKind.overlay => HarborBar.overlay(
        key: key,
        edgeEffect: edgeEffect,
        state: state,
        extentPolicy: extentPolicy,
        animationStyle: animationStyle,
        backdrop: backdrop,
        hitTestBehavior: hitTestBehavior,
        minimum: minimum,
        debugLabel: debugLabel,
        child: appBar,
      ),
    };
  }
}

/// The surface an `AppBar` paints, as a widget of its own: the backdrop [HarborMaterialBar.appBar]
/// puts under the whole bar, status bar included.
///
/// It resolves the colour, elevation, surface tint and shape as the `AppBar` does, and follows the
/// `AppBar`'s scrolled-under state from the nearest `ScrollNotificationObserver`, with the `AppBar`'s
/// `notificationPredicate`. It casts no shadow.
class HarborMaterialAppBarSurface extends StatefulWidget {
  const HarborMaterialAppBarSurface({super.key, required this.appBar});

  /// The app bar whose surface this is. Read only where it is an `AppBar`.
  final PreferredSizeWidget appBar;

  @override
  State<HarborMaterialAppBarSurface> createState() => _HarborMaterialAppBarSurfaceState();
}

class _HarborMaterialAppBarSurfaceState extends State<HarborMaterialAppBarSurface> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  AppBar? get _appBar => switch (widget.appBar) {
    final AppBar appBar => appBar,
    _ => null,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_handleScrollNotification);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    _observer?.removeListener(_handleScrollNotification);
    _observer = null;
    super.dispose();
  }

  // As AppBar's own: a vertical scroll that the predicate accepts, scrolled past its start.
  void _handleScrollNotification(final ScrollNotification notification) {
    final ScrollNotificationPredicate predicate = _appBar?.notificationPredicate ?? defaultScrollNotificationPredicate;
    if (notification is! ScrollUpdateNotification || !predicate(notification)) {
      return;
    }
    final ScrollMetrics metrics = notification.metrics;
    final bool scrolledUnder = switch (metrics.axisDirection) {
      AxisDirection.up => metrics.extentAfter > 0,
      AxisDirection.down => metrics.extentBefore > 0,
      AxisDirection.left || AxisDirection.right => _scrolledUnder,
    };
    if (scrolledUnder != _scrolledUnder) {
      setState(() => _scrolledUnder = scrolledUnder);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final AppBar? appBar = _appBar;
    final ThemeData theme = Theme.of(context);
    final AppBarThemeData appBarTheme = AppBarTheme.of(context);
    final bool m3 = theme.useMaterial3;
    final ColorScheme colors = theme.colorScheme;
    final Set<WidgetState> states = <WidgetState>{if (_scrolledUnder) WidgetState.scrolledUnder};

    Color resolve(final Color fallback) =>
        WidgetStateProperty.resolveAs<Color?>(appBar?.backgroundColor, states) ??
        WidgetStateProperty.resolveAs<Color?>(appBarTheme.backgroundColor, states) ??
        fallback;

    final Color background = resolve(
      m3 ? colors.surface : (colors.brightness == Brightness.dark ? colors.surface : colors.primary),
    );
    final Color color = m3 && _scrolledUnder ? resolve(colors.surfaceContainer) : background;
    final double elevation = appBar?.elevation ?? appBarTheme.elevation ?? (m3 ? 0.0 : 4.0);
    final double effectiveElevation = _scrolledUnder
        ? appBar?.scrolledUnderElevation ?? appBarTheme.scrolledUnderElevation ?? (m3 ? 3.0 : elevation)
        : elevation;

    return Material(
      type: appBar?.forceMaterialTransparency ?? false ? MaterialType.transparency : MaterialType.canvas,
      color: color,
      elevation: effectiveElevation,
      shadowColor: Colors.transparent,
      // As AppBar has it: the theme's surface tint in Material 3 unless the app bar or its theme
      // says otherwise, not the transparent tint of its defaults.
      surfaceTintColor: appBar?.surfaceTintColor ?? appBarTheme.surfaceTintColor ?? (m3 ? colors.surfaceTint : null),
      shape: appBar?.shape ?? appBarTheme.shape,
      animateColor: appBar?.animateColor ?? false,
    );
  }
}
