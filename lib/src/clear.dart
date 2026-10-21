import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'consumer.dart';
import 'edge.dart';
import 'room.dart';

/// Which bars a [HarborClear] keeps up with.
enum HarborFollow {
  /// The bars as they are now: content moves as a bar grows or withdraws.
  live,

  /// The bars at rest: content holds still while a bar expands over it, such
  /// as a rail that opens when it takes focus.
  resting,
}

/// Keeps [child] clear of everything in the way on [edges], then marks those edges handled so
/// nothing beneath keeps clear of them a second time.
///
/// What's in the way is the system edges (the status bar, the home indicator, a cutout), the bars
/// (headers, tab bars, rails) and, at the bottom, the keyboard. The frame's margin is added on
/// [edges] when [rowInsets] is set. A fixed Save button, a form, a block of static text.
///
/// [HarborClear.rowInsets] keeps a row in a list on the page margin.
///
/// See also:
///
///  * [SafeArea], the closest Flutter widget, which keeps clear of `MediaQuery.padding` alone and so
///    misses the keyboard. A [HarborClear] keeps clear of the keyboard too, can leave the bars to
///    the page ([clearsBars]), and keeps up with the bars at rest ([follow]).
class HarborClear extends StatelessWidget {
  const HarborClear({
    super.key,
    this.edges = HarborEdge.all,
    this.clearsBars = true,
    this.follow = HarborFollow.live,
    this.clearsKeyboard = true,
    this.rowInsets = false,
    this.minimum = EdgeInsetsDirectional.zero,
    this.padding = EdgeInsetsDirectional.zero,
    this.debugLabel,
    required this.child,
  });

  /// Keeps [child], a row in a list, a heading or a tile grid, on the page margin at its sides:
  /// the frame's margin plus whatever is in the way there (a side cutout, a rail). The list itself
  /// still runs to the frame's edge.
  ///
  /// It is a [HarborClear] on [HarborEdge.horizontal] with [rowInsets] and without [clearsKeyboard].
  ///
  /// See also:
  ///
  ///  * [Padding], which a page margin is in Flutter; this adds whatever is in the way on the
  ///    sides.
  const HarborClear.rowInsets({super.key, this.follow = HarborFollow.live, this.debugLabel, required this.child})
    : edges = HarborEdge.horizontal,
      clearsBars = true,
      clearsKeyboard = false,
      rowInsets = true,
      minimum = EdgeInsetsDirectional.zero,
      padding = EdgeInsetsDirectional.zero;

  /// The edges kept clear of and marked handled.
  final Set<HarborEdge> edges;

  /// Whether [edges] keep clear of the bars (headers, tab bars, rails) as well as the system
  /// edges. True, the default, keeps clear of everything in the way.
  ///
  /// False keeps clear of the system edges (the status bar, the home indicator, a cutout) alone,
  /// and leaves the bars **and the keyboard** out: [clearsKeyboard] is not read. [edges] are still
  /// handled, the bars with the system edges, but the keyboard is not, so content inside can keep
  /// clear of it itself. For something that sits under a translucent header on purpose but must
  /// not touch the status bar, like a hero image's title. To keep clear of the system edges and the
  /// keyboard but not a header, clear the bottom edge alone. (A [HarborScrollView]'s `clearsBars: false`
  /// keeps the keyboard while its `clearsKeyboard` is true; this one does not.)
  final bool clearsBars;

  final HarborFollow follow;

  /// Whether the bottom keeps clear of the keyboard too. Not read where [clearsBars] is false, which
  /// leaves the keyboard to the content.
  final bool clearsKeyboard;

  /// Whether the frame's margin is added on [edges], so the content lines up with the page.
  final bool rowInsets;

  /// A floor on each edge: the clearance or this, whichever is larger.
  final EdgeInsetsGeometry minimum;

  /// Your own spacing, added on top of the clearance.
  final EdgeInsetsGeometry padding;

  /// Its name in the inspector, among the frame's consumers (`HarborInspectorEntry.consumers`).
  final String? debugLabel;

  final Widget child;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<HarborEdge>('edges', edges, defaultValue: HarborEdge.all));
    properties.add(FlagProperty('clearsBars', value: clearsBars, ifFalse: 'bars not cleared'));
    properties.add(EnumProperty<HarborFollow>('follow', follow, defaultValue: HarborFollow.live));
    properties.add(FlagProperty('clearsKeyboard', value: clearsKeyboard, ifFalse: 'keyboard ignored'));
    properties.add(FlagProperty('rowInsets', value: rowInsets, ifTrue: 'row insets'));
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('minimum', minimum, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(
      DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding, defaultValue: EdgeInsetsDirectional.zero),
    );
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  /// What a [HarborClear] with these settings would pad [context] by.
  static EdgeInsetsDirectional clearanceOf(
    final BuildContext context, {
    final Set<HarborEdge> edges = HarborEdge.all,
    final bool clearsBars = true,
    final HarborFollow follow = HarborFollow.live,
    final bool clearsKeyboard = true,
    final bool rowInsets = false,
    final EdgeInsetsGeometry minimum = EdgeInsetsDirectional.zero,
    final EdgeInsetsGeometry padding = EdgeInsetsDirectional.zero,
  }) {
    EdgeInsetsDirectional resolved(final EdgeInsetsGeometry insets) =>
        insets is EdgeInsetsDirectional ? insets : HarborEdges.resolve(insets, Directionality.of(context));
    final EdgeInsetsDirectional minimumHere = resolved(minimum);
    final EdgeInsetsDirectional paddingHere = resolved(padding);
    // Each part of the room is read only where it is used, so a row on the page margin in a list
    // under the keyboard does not rebuild as the keyboard moves.
    double clearance(final HarborEdge edge) {
      if (!edges.contains(edge)) {
        return HarborEdges.of(paddingHere, edge);
      }
      double value = switch ((clearsBars, follow)) {
        (false, _) => HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.systemEdges).systemEdges, edge),
        (true, HarborFollow.resting) => math.max(
          HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.systemEdges).systemEdges, edge),
          HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.bars).barsResting, edge),
        ),
        (true, HarborFollow.live) => HarborRoom.clearanceOf(context, edge, clearsKeyboard: false),
      };
      if (clearsKeyboard && clearsBars && edge == HarborEdge.bottom) {
        value = math.max(value, MediaQuery.viewInsetsOf(context).bottom);
      }
      if (rowInsets) {
        value += HarborEdges.of(HarborRoom.of(context, aspect: HarborRoomAspect.margin).margin, edge);
      }
      return math.max(value, HarborEdges.of(minimumHere, edge)) + HarborEdges.of(paddingHere, edge);
    }

    return HarborEdges.build(clearance);
  }

  @override
  Widget build(final BuildContext context) {
    final EdgeInsetsDirectional padding = clearanceOf(
      context,
      edges: edges,
      clearsBars: clearsBars,
      follow: follow,
      clearsKeyboard: clearsKeyboard,
      rowInsets: rowInsets,
      minimum: minimum,
      padding: this.padding,
    );
    return HarborConsumerReport.wrap(
      type: rowInsets && edges == HarborEdge.horizontal ? 'HarborClear.rowInsets' : 'HarborClear',
      edges: edges,
      amounts: padding,
      label: debugLabel,
      widgetKey: key,
      child: Padding(
        padding: padding,
        child: HarborHandled.unreported(
          edges: edges,
          clearsKeyboard: clearsKeyboard && clearsBars && edges.contains(HarborEdge.bottom),
          margin: rowInsets,
          child: child,
        ),
      ),
    );
  }
}
