import 'package:flutter/widgets.dart';

/// An edge of a harbor. Directional, so a side follows the reading direction
/// rather than the physical side of the screen.
enum HarborEdge {
  top,
  bottom,
  start,
  end;

  static const Set<HarborEdge> all = {top, bottom, start, end};
  static const Set<HarborEdge> vertical = {top, bottom};
  static const Set<HarborEdge> horizontal = {start, end};

  /// Whether docks on this edge stack along the vertical axis.
  bool get isVertical => this == top || this == bottom;

  /// The edge across from this one.
  HarborEdge get opposite => switch (this) {
    top => bottom,
    bottom => top,
    start => end,
    end => start,
  };
}

/// Arithmetic on [EdgeInsetsDirectional] by [HarborEdge], shared by every layer.
abstract final class HarborEdges {
  static double of(final EdgeInsetsDirectional insets, final HarborEdge edge) => switch (edge) {
    HarborEdge.top => insets.top,
    HarborEdge.bottom => insets.bottom,
    HarborEdge.start => insets.start,
    HarborEdge.end => insets.end,
  };

  static EdgeInsetsDirectional build(final double Function(HarborEdge edge) value) =>
      EdgeInsetsDirectional.fromSTEB(value(HarborEdge.start), value(HarborEdge.top), value(HarborEdge.end), value(HarborEdge.bottom));

  static EdgeInsetsDirectional only(final HarborEdge edge, final double value) =>
      build((final HarborEdge e) => e == edge ? value : 0.0);

  static EdgeInsetsDirectional without(final EdgeInsetsDirectional insets, final Set<HarborEdge> edges) =>
      build((final HarborEdge e) => edges.contains(e) ? 0.0 : of(insets, e));

  static EdgeInsetsDirectional keep(final EdgeInsetsDirectional insets, final Set<HarborEdge> edges) =>
      build((final HarborEdge e) => edges.contains(e) ? of(insets, e) : 0.0);

  static EdgeInsetsDirectional max(final EdgeInsetsDirectional a, final EdgeInsetsDirectional b) =>
      build((final HarborEdge e) => of(a, e) > of(b, e) ? of(a, e) : of(b, e));

  static EdgeInsetsDirectional min(final EdgeInsetsDirectional a, final EdgeInsetsDirectional b) =>
      build((final HarborEdge e) => of(a, e) < of(b, e) ? of(a, e) : of(b, e));

  /// [insets] with its left and right read as start and end under [direction].
  static EdgeInsetsDirectional directional(final EdgeInsets insets, final TextDirection direction) {
    final bool ltr = direction == TextDirection.ltr;
    return EdgeInsetsDirectional.fromSTEB(
      ltr ? insets.left : insets.right,
      insets.top,
      ltr ? insets.right : insets.left,
      insets.bottom,
    );
  }

  /// The physical sides [edges] land on under [direction].
  static ({bool left, bool top, bool right, bool bottom}) physical(
    final Set<HarborEdge> edges,
    final TextDirection direction,
  ) {
    final bool ltr = direction == TextDirection.ltr;
    return (
      left: edges.contains(ltr ? HarborEdge.start : HarborEdge.end),
      top: edges.contains(HarborEdge.top),
      right: edges.contains(ltr ? HarborEdge.end : HarborEdge.start),
      bottom: edges.contains(HarborEdge.bottom),
    );
  }
}
