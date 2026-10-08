import 'package:flutter/widgets.dart';

import 'tide.dart';
import 'wake.dart';

/// How a dock meets the content of its harbor.
enum HarborDockKind {
  /// A pier is built out over the water: content sails under it, and comes to
  /// rest clear of it. A translucent header over a scrolling list.
  pier,

  /// A quay is built on the shore: it takes its ground, and the water (the
  /// body) starts where it ends. A tab bar the list ends above.
  ///
  /// Quays are always nearer the edge than piers on the same edge.
  quay,
}

/// How a dock takes the coast on the edge it is built against.
enum HarborCoastStance {
  /// It absorbs the coast as it is now, which goes to zero at the bottom while
  /// the keyboard is up. The default for floating docks.
  ///
  /// At the bottom it gives the coast up only as the keyboard covers it, so a
  /// floating dock never dips while a keyboard is still shorter than the
  /// home indicator: it sits at the larger of the two.
  live,

  /// It absorbs the coast as it is with the keyboard down, so it keeps its
  /// height while the tide covers it. The default for docks on pilings.
  steady,

  /// It leaves the coast alone, because what it holds already runs to the
  /// screen's edge, and takes no minimum either. The default for dry docks.
  none,
}

/// Whether a dock is in service.
enum HarborDockState {
  /// In service: drawn, tappable, and its ground is taken.
  open,

  /// Lights out: not drawn and not tappable, but it keeps its ground, so
  /// nothing moves. For a header that steps aside while a panel is up.
  dark,

  /// Withdrawn: it slides out toward its edge and gives its ground back, so
  /// content flows into the space. For a tab bar that makes way for a panel.
  withdrawn,
}

/// How a withdrawing dock gives its ground back.
enum HarborExtentPolicy {
  /// The ground shrinks with the dock as it slides out.
  follow,

  /// The ground is held until the dock has fully left, so content reflows once,
  /// after the dock is gone, and never under a dock that is still visible.
  hold,

  /// The ground is given back at once, while the dock is still sliding out.
  release,
}

/// A dock: something built against one edge of a [Harbor]. Its size is
/// measured, never declared, and it claims that much of the edge.
///
/// A dock absorbs the coast on the edge it is against (it pads its [child]
/// below the status bar, or above the home indicator) and paints its
/// [backdrop] under the whole of its ground, coast included. The insets across
/// it (a top dock's sides) are left in its child's `MediaQuery` for the child
/// to keep clear of, so a horizontal fairway in a header can still run to the
/// screen's edge.
///
/// Docks on the same edge stack in the order they are listed, the way a
/// `Column` or `Row` would lay them out.
@immutable
class HarborDock {
  /// A dock built out over the water: content sails under it.
  const HarborDock.pier({
    this.key,
    required this.child,
    this.wake = HarborWake.none,
    this.tide = HarborTideStance.pilings,
    this.coast,
    this.state = HarborDockState.open,
    this.extentPolicy = HarborExtentPolicy.hold,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutCubic,
    this.animationStyle,
    this.backdrop,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.withdrawsAtHighTide = false,
    this.restingExtent,
    this.minimum = 0.0,
    this.debugLabel,
  }) : kind = HarborDockKind.pier;

  /// A dock built on the shore: the body starts where it ends. A quay is pronounced "key".
  const HarborDock.quay({
    this.key,
    required this.child,
    this.wake = HarborWake.none,
    this.tide = HarborTideStance.pilings,
    this.coast,
    this.state = HarborDockState.open,
    this.extentPolicy = HarborExtentPolicy.hold,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutCubic,
    this.animationStyle,
    this.backdrop,
    this.hitTestBehavior = HitTestBehavior.opaque,
    this.withdrawsAtHighTide = false,
    this.restingExtent,
    this.minimum = 0.0,
    this.debugLabel,
  }) : kind = HarborDockKind.quay;

  /// Keeps the dock's state (its slide animation) when the docks around it change.
  final Key? key;

  final Widget child;
  final HarborDockKind kind;

  /// How the boundary between this dock and the content beyond it is drawn.
  /// Only the innermost dock on an edge leaves a wake.
  final HarborWake wake;

  /// How the dock behaves when the keyboard comes in. Matters on the bottom edge.
  final HarborTideStance tide;

  /// How the dock takes the coast on its edge; null picks the default for [tide].
  final HarborCoastStance? coast;

  final HarborDockState state;

  /// How a withdrawing dock gives its ground back.
  final HarborExtentPolicy extentPolicy;

  /// How long the dock takes to go dark, withdraw or return.
  final Duration duration;
  final Curve curve;

  /// Overrides [duration] and [curve], as `MaterialApp.themeAnimationStyle` overrides its
  /// duration and curve. Its `duration` and `curve` are for returning and lighting up, and its
  /// `reverseDuration` and `reverseCurve` for withdrawing and going dark; each falls back to the
  /// forward one, then to [duration] and [curve]. [AnimationStyle.noAnimation] changes the dock's
  /// state at once.
  final AnimationStyle? animationStyle;

  /// Painted under the dock's whole ground, coast included: its surface, or a
  /// frosted glass. It never takes taps itself.
  final Widget? backdrop;

  /// Whether taps on the dock's ground stop at the dock. Opaque by default, so
  /// a tap on a header never reaches a row scrolled under it.
  final HitTestBehavior hitTestBehavior;

  /// Whether the dock withdraws while the keyboard is up (a tool strip that
  /// would otherwise park mid-screen).
  final bool withdrawsAtHighTide;

  /// How far the dock reaches at rest, for a dock whose child grows (a rail that
  /// opens on focus). Content that follows the dock at rest keeps this
  /// distance while the dock grows over it. Null means its measured size.
  final double? restingExtent;

  /// The least room the dock gives the coast on its edge: the coast, or this,
  /// whichever is larger. A bottom bar keeps 16 above the edge of a phone with
  /// no home indicator.
  final double minimum;

  /// The dock's name on a harbor chart.
  final String? debugLabel;

  /// [coast], or the default for [tide].
  HarborCoastStance get effectiveCoast =>
      coast ??
      switch (tide) {
        HarborTideStance.float => HarborCoastStance.live,
        HarborTideStance.pilings => HarborCoastStance.steady,
        HarborTideStance.dryDock => HarborCoastStance.none,
      };

  HarborDock copyWith({final HarborDockState? state, final Widget? child, final HarborTideStance? tide}) => kind == HarborDockKind.pier
      ? HarborDock.pier(
          key: key,
          child: child ?? this.child,
          wake: wake,
          tide: tide ?? this.tide,
          coast: coast,
          state: state ?? this.state,
          extentPolicy: extentPolicy,
          duration: duration,
          curve: curve,
          animationStyle: animationStyle,
          backdrop: backdrop,
          hitTestBehavior: hitTestBehavior,
          withdrawsAtHighTide: withdrawsAtHighTide,
          restingExtent: restingExtent,
          minimum: minimum,
          debugLabel: debugLabel,
        )
      : HarborDock.quay(
          key: key,
          child: child ?? this.child,
          wake: wake,
          tide: tide ?? this.tide,
          coast: coast,
          state: state ?? this.state,
          extentPolicy: extentPolicy,
          duration: duration,
          curve: curve,
          animationStyle: animationStyle,
          backdrop: backdrop,
          hitTestBehavior: hitTestBehavior,
          withdrawsAtHighTide: withdrawsAtHighTide,
          restingExtent: restingExtent,
          minimum: minimum,
          debugLabel: debugLabel,
        );
}
