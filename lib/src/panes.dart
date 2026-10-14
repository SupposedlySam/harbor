import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'hinge.dart';

/// Which pane [HarborPanes] shows when there is room for only one.
enum HarborPanePriority {
  /// The start pane: a list before its detail.
  start,

  /// The end pane: the detail once something is chosen.
  end,
}

/// How [HarborPanes] laid its panes out.
enum HarborPanesMode {
  /// One pane, by [HarborPanes.priority].
  single,

  /// Side by side, start where reading starts.
  wide,

  /// One above the other, start on top.
  tall,
}

/// Two panes, one either side of a hinge or fold, or side by side on a screen wide enough, and
/// one alone otherwise: list and detail, two pages of a book, a canvas and its tools. Modelled on
/// Windows' and .NET MAUI's `TwoPaneView`, and on the `TwoPane` of Microsoft's `dual_screen`.
///
/// On a hinge or fold its [hinge] policy keeps off (the page's [HarborHinge.of] by default), the
/// panes go either side of it: a vertical hinge puts them side by side, a horizontal one (a
/// dual-screen device on its side, a foldable half open on a table) puts start on top. With no
/// such hinge, they go side by side when the width reaches [minWideWidth], one above the other
/// when the height reaches [minTallHeight] (never, by default), and otherwise [priority]'s pane
/// is shown alone. [startFraction] is the start pane's share of the width or height when no hinge
/// decides it.
///
/// Each pane is built as a screen of its own: its `MediaQuery` has the pane's size, keeps the
/// system edges only on the pane's outer edges, and lists only the display features inside it. So
/// each can hold a `HarborFrame` with bars of its own, kept clear of nothing the other pane has.
///
/// The display features are read from the `MediaQuery` above, which is taken to be in this
/// widget's coordinates, as `DisplayFeatureSubScreen` takes it: mount it where it fills the
/// screen (a route's page, or a frame's body that runs under no bars).
class HarborPanes extends StatelessWidget {
  const HarborPanes({
    super.key,
    required this.start,
    required this.end,
    this.priority = HarborPanePriority.start,
    this.minWideWidth = 840.0,
    this.minTallHeight = double.infinity,
    this.startFraction = 0.5,
    this.hinge,
  }) : assert(startFraction > 0.0 && startFraction < 1.0, 'startFraction is a share of the room, between 0 and 1.');

  final Widget start;
  final Widget end;
  final HarborPanePriority priority;

  /// The width from which two panes go side by side with no hinge between them: 840, Material's
  /// expanded width, by default.
  final double minWideWidth;

  /// The height from which two panes go one above the other with no hinge between them, when
  /// they are not side by side. Off by default.
  final double minTallHeight;

  /// The start pane's share when no hinge decides where the panes meet.
  final double startFraction;

  /// Which hinges and folds the panes are split at; the page's [HarborHinge.of] when null.
  final HarborHinge? hinge;

  /// How the nearest [HarborPanes] above [context] laid its panes out, or null outside one. A
  /// list reads it to decide what a tap does: show the item in the end pane when both are up,
  /// or open it as a page of its own when only the list is.
  static HarborPanesMode? modeOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_HarborPanesScope>()?.mode;

  /// The layout [HarborPanes] would choose for [size], with [hinges] (the bounds of the hinges and
  /// folds its policy keeps off) in the same coordinates.
  @visibleForTesting
  static ({HarborPanesMode mode, Rect startRect, Rect endRect}) layout({
    required final Size size,
    required final List<Rect> hinges,
    required final TextDirection direction,
    final double minWideWidth = 840.0,
    final double minTallHeight = double.infinity,
    final double startFraction = 0.5,
  }) {
    final Rect all = Offset.zero & size;
    for (final Rect hinge in hinges) {
      final bool vertical =
          hinge.top <= 0.5 && hinge.bottom >= size.height - 0.5 && hinge.left > 0 && hinge.right < size.width;
      final bool horizontal =
          hinge.left <= 0.5 && hinge.right >= size.width - 0.5 && hinge.top > 0 && hinge.bottom < size.height;
      if (vertical) {
        final Rect left = Rect.fromLTRB(0, 0, hinge.left, size.height);
        final Rect right = Rect.fromLTRB(hinge.right, 0, size.width, size.height);
        return direction == TextDirection.ltr
            ? (mode: HarborPanesMode.wide, startRect: left, endRect: right)
            : (mode: HarborPanesMode.wide, startRect: right, endRect: left);
      }
      if (horizontal) {
        return (
          mode: HarborPanesMode.tall,
          startRect: Rect.fromLTRB(0, 0, size.width, hinge.top),
          endRect: Rect.fromLTRB(0, hinge.bottom, size.width, size.height),
        );
      }
    }
    if (size.width >= minWideWidth) {
      final double split = size.width * (direction == TextDirection.ltr ? startFraction : 1 - startFraction);
      final Rect left = Rect.fromLTRB(0, 0, split, size.height);
      final Rect right = Rect.fromLTRB(split, 0, size.width, size.height);
      return direction == TextDirection.ltr
          ? (mode: HarborPanesMode.wide, startRect: left, endRect: right)
          : (mode: HarborPanesMode.wide, startRect: right, endRect: left);
    }
    if (size.height >= minTallHeight) {
      final double split = size.height * startFraction;
      return (
        mode: HarborPanesMode.tall,
        startRect: Rect.fromLTRB(0, 0, size.width, split),
        endRect: Rect.fromLTRB(0, split, size.width, size.height),
      );
    }
    return (mode: HarborPanesMode.single, startRect: all, endRect: all);
  }

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final TextDirection direction = Directionality.of(context);
    final List<Rect> hinges = <Rect>[
      for (final DisplayFeature feature in (hinge ?? HarborHinge.of(context)).keptOff(mediaQuery.displayFeatures))
        feature.bounds,
    ];
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final Size size = constraints.biggest;
        final ({HarborPanesMode mode, Rect startRect, Rect endRect}) panes = layout(
          size: size,
          hinges: hinges,
          direction: direction,
          minWideWidth: minWideWidth,
          minTallHeight: minTallHeight,
          startFraction: startFraction,
        );
        Widget pane(final Widget child, final Rect rect, final String label) => Positioned.fromRect(
          rect: rect,
          child: MediaQuery(
            data: _paneMediaQuery(mediaQuery, rect, size),
            child: KeyedSubtree(key: ValueKey<String>(label), child: child),
          ),
        );
        return _HarborPanesScope(
          mode: panes.mode,
          child: Stack(
            children: <Widget>[
              if (panes.mode == HarborPanesMode.single)
                pane(priority == HarborPanePriority.start ? start : end, panes.startRect, priority.name)
              else ...<Widget>[pane(start, panes.startRect, 'start'), pane(end, panes.endRect, 'end')],
            ],
          ),
        );
      },
    );
  }

  /// A pane's screen: its size, the system edges only on the edges it shares with the whole, and the
  /// display features inside it, moved into its coordinates.
  static MediaQueryData _paneMediaQuery(final MediaQueryData mediaQuery, final Rect rect, final Size whole) {
    EdgeInsets outer(final EdgeInsets insets) => EdgeInsets.fromLTRB(
      rect.left <= 0.5 ? insets.left : 0.0,
      rect.top <= 0.5 ? insets.top : 0.0,
      rect.right >= whole.width - 0.5 ? insets.right : 0.0,
      rect.bottom >= whole.height - 0.5 ? insets.bottom : 0.0,
    );
    return mediaQuery.copyWith(
      size: rect.size,
      padding: outer(mediaQuery.padding),
      viewPadding: outer(mediaQuery.viewPadding),
      viewInsets: outer(mediaQuery.viewInsets),
      systemGestureInsets: outer(mediaQuery.systemGestureInsets),
      displayFeatures: <DisplayFeature>[
        for (final DisplayFeature feature in mediaQuery.displayFeatures)
          if (rect.overlaps(feature.bounds) || rect.contains(feature.bounds.topLeft))
            DisplayFeature(
              bounds: feature.bounds.intersect(rect).shift(-rect.topLeft),
              type: feature.type,
              state: feature.state,
            ),
      ],
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborPanePriority>('priority', priority, defaultValue: HarborPanePriority.start));
    properties.add(DoubleProperty('minWideWidth', minWideWidth, defaultValue: 840.0));
    properties.add(DoubleProperty('minTallHeight', minTallHeight, defaultValue: double.infinity));
    properties.add(DoubleProperty('startFraction', startFraction, defaultValue: 0.5));
    properties.add(EnumProperty<HarborHinge>('hinge', hinge, defaultValue: null));
  }
}

class _HarborPanesScope extends InheritedWidget {
  const _HarborPanesScope({required this.mode, required super.child});

  final HarborPanesMode mode;

  @override
  bool updateShouldNotify(final _HarborPanesScope oldWidget) => mode != oldWidget.mode;
}
