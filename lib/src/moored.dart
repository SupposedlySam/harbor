import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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

/// What a moored widget keeps clear of: the old spelling of `bars:`.
///
/// [coast] is `bars: false`, and [everything] is `bars: true`, the default. The name is going to
/// [HarborMoored], which becomes `HarborClear` in the rename (#120).
@Deprecated(
  'Use bars: false for HarborClear.coast, and leave bars out for HarborClear.everything. '
  'The name HarborClear goes to the widget HarborMoored. Deprecated after 0.6.3.',
)
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
///
/// See also:
///
///  * [SafeArea], the closest Flutter widget, which keeps clear of `MediaQuery.padding` alone and so
///    misses the keyboard.
class HarborMoored extends StatelessWidget {
  const HarborMoored({
    super.key,
    this.edges = HarborEdge.all,
    final bool bars = true,
    @Deprecated(
      'Use bars: false for HarborClear.coast, and leave bars out for HarborClear.everything. '
      'Deprecated after 0.6.3.',
    )
    final HarborClear? clear,
    this.follow = HarborFollow.live,
    this.tide = true,
    this.mooringLine = false,
    this.minimum = EdgeInsetsDirectional.zero,
    this.extra = EdgeInsetsDirectional.zero,
    required this.child,
  }) : assert(clear == null || bars || clear == HarborClear.coast, _barsConflict),
       bars = bars && clear != HarborClear.coast;

  /// The edges kept clear of and cast off.
  final Set<HarborEdge> edges;

  /// Whether [edges] keep clear of the bars (the docks: headers, tab bars, rails) as well as the
  /// coast. True, the default, keeps clear of everything in the way.
  ///
  /// False keeps clear of the coast (the system edges: the status bar, the home indicator, a
  /// cutout) alone, and leaves the bars **and the keyboard** out: [tide] is not read. [edges] are
  /// still cast off, the docks with the coast, but the keyboard is not, so content inside can keep
  /// clear of it itself. For something that sits under a translucent header on purpose but must not
  /// touch the status bar, like a hero image's title. To keep clear of the coast and the keyboard
  /// but not a header, moor the bottom edge alone. (A fairway's `bars: false` keeps the keyboard
  /// while its `tide` is true; this one does not.)
  final bool bars;

  /// The old spelling of [bars]: [HarborClear.coast] where [bars] is false.
  @Deprecated('Use bars. Deprecated after 0.6.3.')
  HarborClear get clear => bars ? HarborClear.everything : HarborClear.coast;

  final HarborFollow follow;

  /// Whether the bottom keeps clear of the keyboard too. Not read where [bars] is false, which
  /// leaves the keyboard to the content.
  final bool tide;

  /// Whether the harbor's margin is added on [edges].
  final bool mooringLine;

  /// A floor on each edge: the clearance or this, whichever is larger.
  final EdgeInsetsGeometry minimum;

  /// Your own spacing, added on top.
  final EdgeInsetsGeometry extra;

  final Widget child;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<HarborEdge>('edges', edges, defaultValue: HarborEdge.all));
    properties.add(FlagProperty('bars', value: bars, ifFalse: 'bars not cleared'));
    properties.add(EnumProperty<HarborFollow>('follow', follow, defaultValue: HarborFollow.live));
    properties.add(FlagProperty('tide', value: tide, ifFalse: 'tide ignored'));
    properties.add(FlagProperty('mooringLine', value: mooringLine, ifTrue: 'mooring line'));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('minimum', minimum, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('extra', extra, defaultValue: EdgeInsetsDirectional.zero),
    );
  }

  /// What a [HarborMoored] with these settings would pad [context] by.
  static EdgeInsetsDirectional clearanceOf(
    final BuildContext context, {
    final Set<HarborEdge> edges = HarborEdge.all,
    final bool bars = true,
    @Deprecated(
      'Use bars: false for HarborClear.coast, and leave bars out for HarborClear.everything. '
      'Deprecated after 0.6.3.',
    )
    final HarborClear? clear,
    final HarborFollow follow = HarborFollow.live,
    final bool tide = true,
    final bool mooringLine = false,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry extra = EdgeInsetsDirectional.zero,
  }) {
    assert(clear == null || bars || clear == HarborClear.coast, _barsConflict);
    final bool clearsBars = bars && clear != HarborClear.coast;
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
      double value = switch ((clearsBars, follow)) {
        (false, _) => HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.coast).coast, edge),
        (true, HarborFollow.resting) => math.max(
          HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.coast).coast, edge),
          HarborEdges.of(HarborWaters.of(context, aspect: HarborWatersAspect.docks).docksResting, edge),
        ),
        (true, HarborFollow.live) => HarborWaters.clearanceOf(context, edge, tide: false),
      };
      if (tide && clearsBars && edge == HarborEdge.bottom) {
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
      bars: bars,
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
        tide: tide && bars && edges.contains(HarborEdge.bottom),
        margin: mooringLine,
        child: child,
      ),
    );
  }
}

/// What `bars:` and the deprecated `clear:` say when both are given and disagree.
const String _barsConflict = 'clear: HarborClear.everything and bars: false disagree. Give bars: alone.';

/// Moors [child] to the mooring line on its sides: the harbor's margin plus
/// whatever is in the way there (a side cutout, a rail). For a row in a list,
/// a heading, a tile grid: anything that should line up with the page margin
/// while the list itself runs to the frame's edge.
///
/// See also:
///
///  * [Padding], which a page margin is in Flutter; a mooring line adds whatever is in the way on the
///    sides.
class HarborMooringLine extends StatelessWidget {
  const HarborMooringLine({super.key, this.follow = HarborFollow.live, required this.child});

  final HarborFollow follow;
  final Widget child;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborFollow>('follow', follow, defaultValue: HarborFollow.live));
  }

  @override
  Widget build(final BuildContext context) => HarborMoored(
    edges: HarborEdge.horizontal,
    follow: follow,
    tide: false,
    mooringLine: true,
    child: child,
  );
}

/// The signature of [HarborOpenWater.builder]: builds open water from the
/// [waters] it lies in, as a `LayoutWidgetBuilder` builds from its constraints.
typedef HarborWatersWidgetBuilder = Widget Function(BuildContext context, HarborWatersData waters);

/// Open water: content that ignores the docks and the coast (a background, a
/// map, a full-bleed image), told how far each of them reaches so it can place
/// what it draws.
///
/// See also:
///
///  * [MediaQuery.paddingOf], which adds the coast and the docks together; these waters keep them
///    apart.
class HarborOpenWater extends StatelessWidget {
  const HarborOpenWater({super.key, required this.builder});

  final HarborWatersWidgetBuilder builder;

  @override
  Widget build(final BuildContext context) => builder(context, HarborWaters.of(context));
}
