import 'dart:math' as math;
import 'dart:ui' show DisplayFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'float.dart' show HarborAnchor, HarborAnchorClip, HarborFloat, HarborToasts, HarborPopover;
import 'hinge.dart';

/// Which side of its anchor an anchored float or toast sits on. [start] and [end] are in reading
/// order, as in `AlignmentDirectional.centerStart`: [start] is on the right under right-to-left.
///
/// Called `HarborBuoySide` through 0.6; toasts and [HarborAnchorClip] take it too.
enum HarborAnchorSide {
  above,
  below,
  start,
  end;

  @Deprecated('Use HarborAnchorSide.start, the reading-order name Flutter uses.')
  static const HarborAnchorSide before = start;

  @Deprecated('Use HarborAnchorSide.end, the reading-order name Flutter uses.')
  static const HarborAnchorSide after = end;

  HarborAnchorSide get _opposite => switch (this) {
    above => below,
    below => above,
    start => end,
    end => start,
  };
}

/// How an anchored float or toast lines up with its anchor across its side, as a `Row`'s or
/// `Column`'s `CrossAxisAlignment` lines up its children: above or below the anchor, [start] and
/// [end] are in reading order (a dropdown under its button's leading edge); at its start or end,
/// they are its top and bottom.
///
/// Called `HarborBuoyCrossAlignment` through 0.6.
enum HarborCrossAlignment { start, center, end }

/// Where an overlay sits in the room: at a point of it ([HarborAligned]) or by an anchor
/// ([HarborAnchored]). [HarborFloat], [HarborPopover] and [HarborToasts.show] all take one, so a
/// placement written for one means the same in the others.
///
/// Which area the overlay may use is the host's to say: the room of its frame, kept to one
/// screen by its [HarborHinge], and for a toast with `reachesSystemEdges` the system edges too. A placement
/// says where in that area it sits.
@immutable
sealed class HarborPlacement with Diagnosticable {
  const HarborPlacement({required this.margin});

  /// At [alignment] in the room. See [HarborAligned].
  const factory HarborPlacement.aligned({AlignmentGeometry alignment, EdgeInsetsGeometry margin}) = HarborAligned;

  /// By [anchor]. See [HarborAnchored].
  const factory HarborPlacement.anchored(
    HarborAnchor? anchor, {
    HarborAnchorSide side,
    double gap,
    double overlap,
    HarborCrossAlignment crossAlignment,
    double crossOffset,
    bool? flips,
    EdgeInsetsGeometry margin,
  }) = HarborAnchored;

  /// How far in from the edges of the area it is kept, a hinge's edge included; an
  /// [EdgeInsetsDirectional] follows the reading direction.
  final EdgeInsetsGeometry margin;
}

/// An overlay at [alignment] in the room, [margin] in from its edges: a floating button, a
/// toast.
final class HarborAligned extends HarborPlacement {
  const HarborAligned({this.alignment = defaultAlignment, super.margin = defaultMargin});

  /// Where an aligned overlay sits when none is given: bottom centre, a toast's place.
  static const Alignment defaultAlignment = Alignment.bottomCenter;

  /// How far an aligned overlay keeps in from the area's edges when no margin is given.
  static const EdgeInsets defaultMargin = EdgeInsets.all(16.0);

  /// The point of the area it sits at; an [AlignmentDirectional] follows the reading direction,
  /// as a Material floating action button does.
  final AlignmentGeometry alignment;

  @override
  String toStringShort() => objectRuntimeType(this, 'HarborAligned');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) || other is HarborAligned && other.alignment == alignment && other.margin == margin;

  @override
  int get hashCode => Object.hash(HarborAligned, alignment, margin);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment, defaultValue: defaultAlignment));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: defaultMargin));
  }
}

/// An overlay by [anchor]: on its [side], [gap] away, lined up with it by [crossAlignment], and
/// kept inside the room, [margin] in from its edges. A menu under its button, a bubble over
/// a tab, "Copied" by the button that copied.
///
/// Across its side it is kept inside the area; along it, it is never past the area's far edge.
final class HarborAnchored extends HarborPlacement {
  const HarborAnchored(
    this.anchor, {
    this.side = HarborAnchorSide.below,
    this.gap = defaultGap,
    this.overlap = 0.0,
    this.crossAlignment = HarborCrossAlignment.center,
    this.crossOffset = 0.0,
    this.flips,
    super.margin = defaultMargin,
  });

  /// How far an anchored overlay keeps in from the area's edges when no margin is given.
  static const EdgeInsets defaultMargin = EdgeInsets.all(8.0);

  /// The space between the anchor and an anchored overlay when no gap is given.
  static const double defaultGap = 8.0;

  /// What it sits by. Null only for a [HarborPopover], which then anchors to its child; a
  /// [HarborFloat] and a toast need one.
  final HarborAnchor? anchor;

  /// Which side of the anchor it sits on; [HarborAnchorSide.start] and [HarborAnchorSide.end] are in
  /// reading order. Below by default, a menu's and a toast's side.
  final HarborAnchorSide side;

  /// The space between the anchor's edge and the overlay.
  final double gap;

  /// How far it reaches back over the anchor, as a speech bubble's tail sits over its button.
  /// Taken off [gap].
  final double overlap;

  /// How it lines up with the anchor across [side]: its leading edge, its centre or its trailing
  /// edge in reading order (its top and bottom beside it).
  final HarborCrossAlignment crossAlignment;

  /// How far it moves on from where [crossAlignment] puts it: toward the reading end above or below
  /// its anchor, down beside it. The horizontal part of `MenuAnchor.alignmentOffset`; [gap] and
  /// [overlap] are the rest.
  final double crossOffset;

  /// Whether it goes to the opposite side of the anchor when [side] has no room and that side has.
  /// Null takes the host's way: a [HarborPopover] flips, a [HarborFloat] and a toast keep their
  /// side (a toast's transition needs to know which side it is on).
  final bool? flips;

  @override
  String toStringShort() => objectRuntimeType(this, 'HarborAnchored');

  @override
  bool operator ==(final Object other) =>
      identical(this, other) ||
      other is HarborAnchored &&
          identical(other.anchor, anchor) &&
          other.side == side &&
          other.gap == gap &&
          other.overlap == overlap &&
          other.crossAlignment == crossAlignment &&
          other.crossOffset == crossOffset &&
          other.flips == flips &&
          other.margin == margin;

  @override
  int get hashCode =>
      Object.hash(HarborAnchored, anchor, side, gap, overlap, crossAlignment, crossOffset, flips, margin);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborAnchor>('anchor', anchor, defaultValue: null));
    properties.add(EnumProperty<HarborAnchorSide>('side', side, defaultValue: HarborAnchorSide.below));
    properties.add(DoubleProperty('gap', gap, defaultValue: defaultGap));
    properties.add(DoubleProperty('overlap', overlap, defaultValue: 0.0));
    properties.add(
      EnumProperty<HarborCrossAlignment>('crossAlignment', crossAlignment, defaultValue: HarborCrossAlignment.center),
    );
    properties.add(DoubleProperty('crossOffset', crossOffset, defaultValue: 0.0));
    properties.add(FlagProperty('flips', value: flips, ifTrue: 'flips', ifFalse: 'no flip'));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin, defaultValue: defaultMargin));
  }
}

/// The area an overlay may occupy, and the system edges it covers there, from
/// [HarborPlacementEngine.area].
@internal
final class HarborPlacementArea {
  const HarborPlacementArea(this.rect, [this.systemEdgesCovered = EdgeInsets.zero]);

  /// Where the overlay may go, margin taken off.
  final Rect rect;

  /// For an overlay that reaches the system edges, how much of them [rect] covers on each edge:
  /// handed to its content as `MediaQuery.padding`.
  final EdgeInsets systemEdgesCovered;
}

/// Where an overlay landed, from [HarborPlacementEngine.place]: its top left, and for an anchored
/// one the side it ended on (its own, or the opposite after a flip).
@internal
final class HarborLanding {
  const HarborLanding(this.offset, [this.side]);

  final Offset offset;
  final HarborAnchorSide? side;
}

/// Answers "where does this overlay go in the room?" for every host: the float layer, the
/// popover and a toast with no frame around it. Each host says what area it has; the engine
/// runs the same steps in the same order for all of them.
@internal
abstract final class HarborPlacementEngine {
  /// The bounds of the hinges and folds [hinge] keeps off among [features].
  static List<Rect> hingeBounds(final HarborHinge hinge, final Iterable<DisplayFeature> features) => <Rect>[
    for (final DisplayFeature feature in hinge.keptOff(features)) feature.bounds,
  ];

  /// The area an overlay placed by [placement] may occupy: [clear] (or [open], the area that
  /// reaches over the system edges, for an aligned overlay that does), kept inside [within], cut
  /// down to one screen where [hinges] split it, and [HarborPlacement.margin] in from that screen's
  /// edges, the hinge's included.
  ///
  /// The screen is the one that holds the alignment point for an aligned overlay, or the screen
  /// where reading starts when the point is on a hinge. For an anchored one it is the screen that
  /// holds [holding], its anchor's centre, or the nearest when that is on a hinge; with no
  /// [holding] (laying out, before the anchor is known) the largest.
  static HarborPlacementArea area({
    required final Rect clear,
    final Rect? open,
    final Rect? within,
    required final HarborPlacement placement,
    required final TextDirection textDirection,
    final List<Rect> hinges = const <Rect>[],
    final Offset? holding,
  }) {
    assert(open == null || placement is HarborAligned, 'Only an aligned overlay reaches over the systemEdges.');
    final Rect base = open ?? clear;
    // Reaching the system edges, an edge of within that is the room's edge opens out to the system
    // edges; one set by bars holds.
    final Rect? bounds = within == null || open == null
        ? within
        : Rect.fromLTRB(
            within.left <= clear.left + 0.5 ? open.left : within.left,
            within.top <= clear.top + 0.5 ? open.top : within.top,
            within.right >= clear.right - 0.5 ? open.right : within.right,
            within.bottom >= clear.bottom - 0.5 ? open.bottom : within.bottom,
          );
    final Rect bounded = bounds == null || !bounds.overlaps(base) ? base : base.intersect(bounds);
    final Rect rect = placement.margin
        .resolve(textDirection)
        .deflateRect(_screen(bounded, hinges, placement, textDirection, holding));
    if (open == null) {
      return HarborPlacementArea(rect);
    }
    // The sides always; the top or bottom when it is placed against that edge.
    final Alignment alignment = (placement as HarborAligned).alignment.resolve(textDirection);
    return HarborPlacementArea(
      rect,
      EdgeInsets.fromLTRB(
        math.max(0.0, clear.left - rect.left),
        alignment.y <= -1.0 ? math.max(0.0, clear.top - rect.top) : 0.0,
        math.max(0.0, rect.right - clear.right),
        alignment.y >= 1.0 ? math.max(0.0, rect.bottom - clear.bottom) : 0.0,
      ),
    );
  }

  /// The screen of [area] an overlay placed by [placement] keeps to when [hinges] split it, by
  /// the rule [area] follows; [area] itself when they do not.
  static Rect screen({
    required final Rect area,
    required final HarborPlacement placement,
    required final TextDirection textDirection,
    final List<Rect> hinges = const <Rect>[],
    final Offset? holding,
  }) => _screen(area, hinges, placement, textDirection, holding);

  /// The screen of [area] the overlay keeps to when [hinges] split it.
  static Rect _screen(
    final Rect area,
    final List<Rect> hinges,
    final HarborPlacement placement,
    final TextDirection textDirection,
    final Offset? holding,
  ) {
    if (hinges.isEmpty) {
      return area;
    }
    final List<Rect> screens = DisplayFeatureSubScreen.subScreensInBounds(area, hinges).toList();
    if (screens.length < 2) {
      return screens.isEmpty ? area : screens.single;
    }
    switch (placement) {
      case HarborAligned(:final AlignmentGeometry alignment):
        final Offset point = alignment.resolve(textDirection).withinRect(area);
        for (final Rect screen in screens) {
          if (screen.contains(point)) {
            return screen;
          }
        }
        // On the hinge itself: the screen where reading starts, as a dialog opens there.
        screens.sort((final Rect a, final Rect b) => a.left.compareTo(b.left));
        return textDirection == TextDirection.rtl ? screens.last : screens.first;
      case HarborAnchored():
        if (holding == null) {
          return screens.reduce((final Rect a, final Rect b) => a.width * a.height >= b.width * b.height ? a : b);
        }
        Rect best = screens.first;
        double nearest = double.infinity;
        for (final Rect screen in screens) {
          if (screen.contains(holding)) {
            return screen;
          }
          final double distance = (screen.center - holding).distance;
          if (distance < nearest) {
            nearest = distance;
            best = screen;
          }
        }
        return best;
    }
  }

  /// Where an overlay of [size] placed by [placement] sits in [area] (from [area]), and for an
  /// anchored one the side it landed on.
  ///
  /// Aligned, it sits at its alignment in [area]. Anchored, it sits by [anchorRect] on its side,
  /// kept inside [area] across that side and never past its far edge along it. With [flips], it
  /// goes to the opposite side when its own has no room and that one has, and is never past the
  /// area's edge at the start or end of its anchor either.
  static HarborLanding place({
    required final HarborPlacement placement,
    required final Rect area,
    required final Size size,
    required final TextDirection textDirection,
    final Rect? anchorRect,
    final bool flips = false,
  }) => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => HarborLanding(
      alignment.resolve(textDirection).inscribe(size, area).topLeft,
    ),
    final HarborAnchored anchored => _anchored(anchored, area, anchorRect!, size, textDirection, flips),
  };

  static HarborLanding _anchored(
    final HarborAnchored placement,
    final Rect area,
    final Rect at,
    final Size size,
    final TextDirection textDirection,
    final bool flips,
  ) {
    final HarborAnchorSide side = placement.side;
    final double gap = placement.gap;
    final double overlap = placement.overlap;
    final double crossOffset = placement.crossOffset;
    final bool rtl = textDirection == TextDirection.rtl;
    final AxisDirection preferred = switch (side) {
      HarborAnchorSide.above => AxisDirection.up,
      HarborAnchorSide.below => AxisDirection.down,
      HarborAnchorSide.start => rtl ? AxisDirection.right : AxisDirection.left,
      HarborAnchorSide.end => rtl ? AxisDirection.left : AxisDirection.right,
    };
    double along(final AxisDirection d) => switch (d) {
      AxisDirection.up => at.top - gap - size.height + overlap,
      AxisDirection.down => at.bottom + gap - overlap,
      AxisDirection.left => at.left - gap - size.width + overlap,
      AxisDirection.right => at.right + gap - overlap,
    };
    bool fits(final AxisDirection d) => switch (d) {
      AxisDirection.up => along(d) >= area.top,
      AxisDirection.down => along(d) + size.height <= area.bottom,
      AxisDirection.left => along(d) >= area.left,
      AxisDirection.right => along(d) + size.width <= area.right,
    };
    final AxisDirection opposite = flipAxisDirection(preferred);
    final AxisDirection direction = flips && !fits(preferred) && fits(opposite) ? opposite : preferred;
    final bool vertical = axisDirectionToAxis(direction) == Axis.vertical;
    // Across a vertical side the start is the reading start; across a horizontal one, the top.
    final bool reversed = vertical && rtl;
    final (double low, double high, double extent) = vertical
        ? (at.left, at.right, size.width)
        : (at.top, at.bottom, size.height);
    final double cross =
        switch ((placement.crossAlignment, reversed)) {
          (HarborCrossAlignment.center, _) => (low + high - extent) / 2,
          (HarborCrossAlignment.start, false) || (HarborCrossAlignment.end, true) => low,
          (HarborCrossAlignment.end, false) || (HarborCrossAlignment.start, true) => high - extent,
        } +
        (reversed ? -crossOffset : crossOffset);
    double left = vertical ? cross : 0.0;
    double top = vertical ? 0.0 : cross;
    switch (direction) {
      case AxisDirection.up:
        top = math.max(along(direction), area.top);
      case AxisDirection.down:
        top = math.min(along(direction), area.bottom - size.height);
      case AxisDirection.left:
        left = flips ? math.max(along(direction), area.left) : along(direction);
      case AxisDirection.right:
        left = flips ? math.min(along(direction), area.right - size.width) : along(direction);
    }
    if (vertical) {
      left = left.clamp(area.left, math.max(area.left, area.right - size.width));
    } else {
      top = top.clamp(area.top, math.max(area.top, area.bottom - size.height));
    }
    return HarborLanding(Offset(left, top), direction == preferred ? side : side._opposite);
  }
}
