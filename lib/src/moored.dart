import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'waters.dart';

/// Which docks a moored widget keeps up with.
enum HarborFollow {
  /// The docks as they are now: content moves as a dock grows or withdraws.
  live,

  /// The docks at rest: content holds still while a dock expands over it, such
  /// as a rail that opens when it takes focus.
  resting,
}

/// What a moored widget keeps clear of.
enum HarborClear {
  /// The coast, the docks, and the tide. The default.
  everything,

  /// The coast alone: for something that sits under a translucent dock on
  /// purpose but must not be cut off by the status bar, like a hero image's title.
  coast,
}

/// Moored: kept clear of everything in the way on [edges], then casts those
/// edges off so nothing beneath keeps clear of them a second time.
///
/// What's in the way is the coast, the docks and, at the bottom, the tide.
/// The mooring line (the harbor's margin) is added on [edges] when
/// [mooringLine] is set. A fixed Save button, a form, a block of static text.
class HarborMoored extends StatelessWidget {
  const HarborMoored({
    super.key,
    this.edges = HarborEdge.all,
    this.clear = HarborClear.everything,
    this.follow = HarborFollow.live,
    this.tide = true,
    this.mooringLine = false,
    this.minimum = EdgeInsetsDirectional.zero,
    this.extra = EdgeInsetsDirectional.zero,
    required this.child,
  });

  /// The edges kept clear of and cast off.
  final Set<HarborEdge> edges;

  final HarborClear clear;
  final HarborFollow follow;

  /// Whether the bottom keeps clear of the keyboard too.
  final bool tide;

  /// Whether the harbor's margin is added on [edges].
  final bool mooringLine;

  /// A floor on each edge: the clearance or this, whichever is larger.
  final EdgeInsetsGeometry minimum;

  /// Your own spacing, added on top.
  final EdgeInsetsGeometry extra;

  final Widget child;

  /// What a [HarborMoored] with these settings would pad [context] by.
  static EdgeInsetsDirectional clearanceOf(
    final BuildContext context, {
    final Set<HarborEdge> edges = HarborEdge.all,
    final HarborClear clear = HarborClear.everything,
    final HarborFollow follow = HarborFollow.live,
    final bool tide = true,
    final bool mooringLine = false,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry extra = EdgeInsetsDirectional.zero,
  }) {
    EdgeInsetsDirectional resolved(final EdgeInsetsGeometry insets) =>
        insets is EdgeInsetsDirectional ? insets : HarborEdges.resolve(insets, Directionality.of(context));
    final EdgeInsetsDirectional minimumHere = resolved(minimum);
    final EdgeInsetsDirectional extraHere = resolved(extra);
    // Each part of the waters is read only where it is used, so a mooring line
    // in a list under the keyboard does not rebuild as the keyboard moves.
    double clearance(final HarborEdge edge) {
      if (!edges.contains(edge)) {
        return HarborEdges.of(extraHere, edge);
      }
      double value = switch ((clear, follow)) {
        (HarborClear.coast, _) => HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.coast).coast, edge),
        (HarborClear.everything, HarborFollow.resting) => math.max(
          HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.coast).coast, edge),
          HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.docks).docksResting, edge),
        ),
        (HarborClear.everything, HarborFollow.live) => HarborWaters.clearanceOf(context, edge, tide: false),
      };
      if (tide && clear == HarborClear.everything && edge == HarborEdge.bottom) {
        value = math.max(value, MediaQuery.viewInsetsOf(context).bottom);
      }
      if (mooringLine) {
        value += HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimumHere, edge)) + HarborEdges.of(extraHere, edge);
    }

    return HarborEdges.build(clearance);
  }

  @override
  Widget build(final BuildContext context) {
    final EdgeInsetsDirectional padding = clearanceOf(
      context,
      edges: edges,
      clear: clear,
      follow: follow,
      tide: tide,
      mooringLine: mooringLine,
      minimum: minimum,
      extra: extra,
    );
    return Padding(
      padding: padding,
      child: HarborCastOff(
        edges: edges,
        tide: tide && clear == HarborClear.everything && edges.contains(HarborEdge.bottom),
        margin: mooringLine,
        child: child,
      ),
    );
  }
}

/// Moors [child] to the mooring line on its sides: the harbor's margin plus
/// whatever is in the way there (a side cutout, a rail). For a row in a list,
/// a heading, a tile grid: anything that should line up with the page margin
/// while the list itself runs to the frame's edge.
class HarborMooringLine extends StatelessWidget {
  const HarborMooringLine({super.key, this.follow = HarborFollow.live, required this.child});

  final HarborFollow follow;
  final Widget child;

  @override
  Widget build(final BuildContext context) => HarborMoored(
    edges: HarborEdge.horizontal,
    follow: follow,
    tide: false,
    mooringLine: true,
    child: child,
  );
}

/// Open water: content that ignores the docks and the coast (a background, a
/// map, a full-bleed image), told how far each of them reaches so it can place
/// what it draws.
class HarborOpenWater extends StatelessWidget {
  const HarborOpenWater({super.key, required this.builder});

  final Widget Function(BuildContext context, HarborWatersData waters) builder;

  @override
  Widget build(final BuildContext context) => builder(context, HarborWaters.of(context));
}
