import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'edge.dart';
import 'edge_effect.dart';

/// Builds one bar in its frame: its system edge padding, backdrop, frosting,
/// hairline, and its dark and withdraw animations.
@Deprecated(
  'HarborDockSlot is how a harbor builds a dock, and stops being exported in a later release. Read where bars '
  'are with HarborInspector.nearest(context).bars (or barsAround in harbor_test), or find the dock\'s child.',
)
class HarborDockSlot extends StatefulWidget {
  /// Made by the frame for each of its bars.
  @internal
  const HarborDockSlot({
    super.key,
    required this.dock,
    required this.edge,
    required this.state,
    required this.coastPadding,
    required this.mediaQuery,
    required this.leavesWake,
    required this.onSettled,
  });

  final HarborBar dock;
  final HarborEdge edge;

  /// The state after claims and the keyboard are applied.
  final HarborBarState state;

  /// What this bar pads its child by for the system edge on its edge.
  final EdgeInsetsDirectional coastPadding;

  /// The `MediaQuery` its child sees: its own edge absorbed, the sides left in.
  final MediaQueryData mediaQuery;

  /// Whether this bar is the innermost on its edge, the one that draws an edge effect.
  final bool leavesWake;

  /// Called when a withdraw or return animation finishes.
  final VoidCallback onSettled;

  @override
  State<HarborDockSlot> createState() => _HarborDockSlotState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborBar>('dock', dock));
    properties.add(EnumProperty<HarborEdge>('edge', edge));
    properties.add(EnumProperty<HarborBarState>('state', state));
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('coastPadding', coastPadding));
    properties.add(FlagProperty('leavesWake', value: leavesWake, ifTrue: 'draws edge effect'));
  }
}

class _HarborDockSlotState extends State<HarborDockSlot> with TickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: widget.dock.duration,
    value: widget.state == HarborBarState.withdrawn ? 0.0 : 1.0,
  );
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: widget.dock.duration,
    value: widget.state == HarborBarState.dark ? 0.0 : 1.0,
  );
  late final CurvedAnimation _presenceCurve = CurvedAnimation(
    parent: _presence,
    curve: _curve,
    reverseCurve: _reverseCurve,
  );
  late final CurvedAnimation _lightCurve = CurvedAnimation(parent: _light, curve: _curve, reverseCurve: _reverseCurve);

  Curve get _curve => widget.dock.animationStyle?.curve ?? widget.dock.curve;
  Curve get _reverseCurve => widget.dock.animationStyle?.reverseCurve ?? _curve;

  @override
  void initState() {
    super.initState();
    _presence.addStatusListener((final AnimationStatus status) {
      if (status.isCompleted || status.isDismissed) {
        widget.onSettled();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setDurations();
  }

  @override
  void didUpdateWidget(final HarborDockSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setDurations();
    for (final CurvedAnimation curved in <CurvedAnimation>[_presenceCurve, _lightCurve]) {
      curved
        ..curve = _curve
        ..reverseCurve = _reverseCurve;
    }
    if (widget.state != oldWidget.state) {
      _apply(widget.state);
    }
  }

  /// The bar's own durations, or none when the platform asks for reduced motion.
  void _setDurations() {
    final bool still = MediaQuery.disableAnimationsOf(context);
    final AnimationStyle? style = widget.dock.animationStyle;
    final Duration duration = still ? Duration.zero : style?.duration ?? widget.dock.duration;
    final Duration reverseDuration = still ? Duration.zero : style?.reverseDuration ?? duration;
    for (final AnimationController controller in <AnimationController>[_presence, _light]) {
      controller
        ..duration = duration
        ..reverseDuration = reverseDuration;
    }
  }

  void _apply(final HarborBarState state) {
    switch (state) {
      case HarborBarState.open:
        _presence.forward();
        _light.forward();
      case HarborBarState.dark:
        _presence.forward();
        _light.reverse();
      case HarborBarState.withdrawn:
        _presence.reverse();
    }
  }

  @override
  void dispose() {
    _presenceCurve.dispose();
    _lightCurve.dispose();
    _presence.dispose();
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final HarborBar bar = widget.dock;
    final HarborEdgeEffect edgeEffect = widget.leavesWake ? bar.edgeEffect : HarborEdgeEffect.none;
    final double? reserved = bar.reserved;
    final Widget content = Padding(
      padding: widget.coastPadding,
      child: reserved == null
          ? MediaQuery(data: widget.mediaQuery, child: _preferredHeight(bar.child))
          // Whatever system edge it took counts toward its extent, so it reaches the larger of the two.
          : SizedBox.square(dimension: math.max(0.0, reserved - HarborEdges.of(widget.coastPadding, widget.edge))),
    );
    final Widget barBody = Stack(
      children: <Widget>[
        Positioned.fill(child: _Frosting(sigma: edgeEffect.blurSigma)),
        // A backdrop is the bar's surface, never a tap target: the bar's
        // hitTestBehavior alone decides whether taps stop here.
        Positioned.fill(child: IgnorePointer(child: bar.backdrop ?? const SizedBox.shrink())),
        content,
      ],
    );
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_presence, _light]),
      builder: (final BuildContext context, final Widget? child) {
        final double presence = _presenceCurve.value;
        final double light = _lightCurve.value;
        final bool hidden = widget.state != HarborBarState.open;
        return _BarFrame(
          edge: widget.edge,
          kind: bar.kind,
          visualFactor: presence,
          extentFactor: _extentFactor(presence),
          restingExtent: bar.restingExtent,
          hairline: edgeEffect.kind == HarborEdgeEffectKind.hairline ? edgeEffect : null,
          // A bar that is dark or leaving is out of reach in every way, not only for taps:
          // keyboard focus and screen readers skip it too. Opacity alone hid a dark bar from
          // screen readers but not from Tab, and a withdrawn one was still read out and focused.
          child: ExcludeFocus(
            excluding: hidden,
            child: ExcludeSemantics(
              excluding: hidden,
              child: IgnorePointer(
                ignoring: hidden,
                child: Opacity(opacity: light, child: child),
              ),
            ),
          ),
        );
      },
      child: reserved != null ? IgnorePointer(child: barBody) : Listener(behavior: bar.hitTestBehavior, child: barBody),
    );
  }

  /// A top or bottom bar's child held to its own height when it is a [PreferredSizeWidget], as
  /// `Scaffold` bounds its app bar. A side bar's child is left alone: a preferred size is a height
  /// (`Size.fromHeight`), and no Flutter slot reads its width.
  Widget _preferredHeight(final Widget child) => widget.edge.isVertical && child is PreferredSizeWidget
      ? _PreferredHeight(preferredHeight: child.preferredSize.height, child: child)
      : child;

  double _extentFactor(final double presence) {
    final bool leaving = widget.state == HarborBarState.withdrawn;
    return switch (widget.dock.extentPolicy) {
      HarborExtentPolicy.follow => presence,
      HarborExtentPolicy.hold => leaving ? (_presence.isDismissed ? 0.0 : 1.0) : presence,
      HarborExtentPolicy.release => leaving ? 0.0 : presence,
    };
  }
}

/// Frosts the content under a bar. Always in the tree; draws nothing at zero.
class _Frosting extends StatelessWidget {
  const _Frosting({required this.sigma});

  final double sigma;

  @override
  Widget build(final BuildContext context) {
    if (sigma <= 0) {
      return const SizedBox.expand();
    }
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// The render side of a bar: lays its child out at full size, sizes itself to
/// the visible share of it, and reports how much space it takes.
class _BarFrame extends SingleChildRenderObjectWidget {
  const _BarFrame({
    required this.edge,
    required this.kind,
    required this.visualFactor,
    required this.extentFactor,
    required this.restingExtent,
    required this.hairline,
    super.child,
  });

  final HarborEdge edge;
  final HarborBarKind kind;
  final double visualFactor;
  final double extentFactor;
  final double? restingExtent;
  final HarborEdgeEffect? hairline;

  @override
  RenderHarborBarFrame createRenderObject(final BuildContext context) => RenderHarborBarFrame(
    edge: edge,
    kind: kind,
    visualFactor: visualFactor,
    extentFactor: extentFactor,
    restingExtent: restingExtent,
    hairline: hairline,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(final BuildContext context, final RenderHarborBarFrame renderObject) {
    renderObject
      ..edge = edge
      ..kind = kind
      ..visualFactor = visualFactor
      ..extentFactor = extentFactor
      ..restingExtent = restingExtent
      ..hairline = hairline
      ..textDirection = Directionality.of(context);
  }
}

class RenderHarborBarFrame extends RenderProxyBox {
  RenderHarborBarFrame({
    required this._edge,
    required this._kind,
    required this._visualFactor,
    required this._extentFactor,
    required this._restingExtent,
    required this._hairline,
    required this._textDirection,
  });

  HarborEdge _edge;
  HarborEdge get edge => _edge;
  set edge(final HarborEdge value) {
    if (_edge != value) {
      _edge = value;
      markNeedsLayout();
    }
  }

  HarborBarKind _kind;
  HarborBarKind get kind => _kind;
  set kind(final HarborBarKind value) {
    if (_kind != value) {
      _kind = value;
      markNeedsLayout();
    }
  }

  double _visualFactor;
  set visualFactor(final double value) {
    if (_visualFactor != value) {
      _visualFactor = value;
      markNeedsLayout();
    }
  }

  double _extentFactor;
  set extentFactor(final double value) {
    if (_extentFactor != value) {
      _extentFactor = value;
      markNeedsLayout();
    }
  }

  double? _restingExtent;
  set restingExtent(final double? value) {
    if (_restingExtent != value) {
      _restingExtent = value;
      markNeedsLayout();
    }
  }

  HarborEdgeEffect? _hairline;
  set hairline(final HarborEdgeEffect? value) {
    if (_hairline != value) {
      _hairline = value;
      markNeedsPaint();
    }
  }

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  Offset _childOffset = Offset.zero;

  double _fullExtent = 0.0;

  /// The child's full size along the bar's axis, from the last layout.
  double get fullExtent => _fullExtent;

  /// How much space the bar takes right now.
  double get extent => fullExtent * _extentFactor;

  /// How much space the bar takes at rest.
  double get restingExtent => (_restingExtent ?? fullExtent) * _extentFactor;

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      _fullExtent = 0.0;
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    final Size full = child.size;
    _fullExtent = _edge.isVertical ? full.height : full.width;
    final double visible = (_edge.isVertical ? full.height : full.width) * _visualFactor;
    size = constraints.constrain(_edge.isVertical ? Size(full.width, visible) : Size(visible, full.height));
    final double hidden = (_edge.isVertical ? full.height : full.width) - visible;
    final bool ltr = _textDirection == TextDirection.ltr;
    // Slide toward the bar's own edge as it withdraws.
    _childOffset = switch (_edge) {
      HarborEdge.top => Offset(0.0, -hidden),
      HarborEdge.bottom => Offset.zero,
      HarborEdge.start => ltr ? Offset(-hidden, 0.0) : Offset.zero,
      HarborEdge.end => ltr ? Offset.zero : Offset(-hidden, 0.0),
    };
  }

  @override
  void applyPaintTransform(final RenderBox child, final Matrix4 transform) {
    transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0.0, 1.0);
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) {
    final RenderBox? child = this.child;
    if (child == null || !size.contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (final BoxHitTestResult result, final Offset transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    if (child == null || size.isEmpty) {
      _clip.layer = null;
      return;
    }
    if (_visualFactor < 1.0) {
      _clip.layer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        (final PaintingContext c, final Offset o) => c.paintChild(child, o + _childOffset),
        oldLayer: _clip.layer,
      );
    } else {
      _clip.layer = null;
      context.paintChild(child, offset + _childOffset);
    }
    final HarborEdgeEffect? hairline = _hairline;
    if (hairline != null && _visualFactor > 0) {
      final Paint paint = Paint()..color = hairline.color ?? const HarborEdgeEffect.hairline().color!;
      final bool ltr = _textDirection == TextDirection.ltr;
      final Rect box = offset & size;
      final double t = hairline.length;
      final Rect line = switch (_edge) {
        HarborEdge.top => Rect.fromLTWH(box.left, box.bottom - t, box.width, t),
        HarborEdge.bottom => Rect.fromLTWH(box.left, box.top, box.width, t),
        HarborEdge.start =>
          ltr ? Rect.fromLTWH(box.right - t, box.top, t, box.height) : Rect.fromLTWH(box.left, box.top, t, box.height),
        HarborEdge.end =>
          ltr ? Rect.fromLTWH(box.left, box.top, t, box.height) : Rect.fromLTWH(box.right - t, box.top, t, box.height),
      };
      context.canvas.drawRect(line, paint);
    }
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}

/// Bounds a [PreferredSizeWidget] in a top or bottom bar at the height it would take.
///
/// A bar leaves its child's height unbounded, as a `Column` does, and an `AppBar` with a `bottom:`
/// lays its toolbar out in a `Column` with a `Flexible`, which needs a bound. `Scaffold` bounds its
/// app bar at `AppBar.preferredHeightFor`, which corrects the `AppBar`'s `preferredSize` for
/// `AppBarTheme.toolbarHeight`; harbor imports no Material, so it asks the child for its maximum
/// intrinsic height instead, which takes the theme's toolbar height and the `bottom:` both. The
/// `preferredSize` is the fallback, for a child whose intrinsic height is zero or infinite, or one
/// that cannot be asked (see [_answersIntrinsics]).
///
/// The bar pads the child for the system edge and takes that edge out of its `MediaQuery`, so
/// neither is in the bound. Under a bounded height (none, in a bar today) the child is laid out as
/// it is given.
class _PreferredHeight extends SingleChildRenderObjectWidget {
  const _PreferredHeight({required this.preferredHeight, required super.child});

  final double preferredHeight;

  @override
  _RenderPreferredHeight createRenderObject(final BuildContext context) =>
      _RenderPreferredHeight(preferredHeight: preferredHeight);

  @override
  void updateRenderObject(final BuildContext context, final _RenderPreferredHeight renderObject) {
    renderObject.preferredHeight = preferredHeight;
  }
}

class _RenderPreferredHeight extends RenderProxyBox {
  _RenderPreferredHeight({required this._preferredHeight});

  double _preferredHeight;
  set preferredHeight(final double value) {
    if (_preferredHeight != value) {
      _preferredHeight = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null || constraints.hasBoundedHeight) {
      super.performLayout();
      return;
    }
    double height = _answersIntrinsics(child) ? child.getMaxIntrinsicHeight(constraints.maxWidth) : 0.0;
    if (height <= 0.0 || !height.isFinite) {
      height = _preferredHeight;
    }
    if (!height.isFinite) {
      super.performLayout();
      return;
    }
    child.layout(constraints.copyWith(maxHeight: math.max(height, constraints.minHeight)), parentUsesSize: true);
    size = constraints.constrain(child.size);
  }

  /// Whether [box] can be asked for its intrinsic size without an assertion: nothing in it is one of
  /// the framework's render objects that refuse to answer. Those are a `LayoutBuilder`'s (a
  /// `FlexibleSpaceBar` is built in one), a sliver viewport's and a two-dimensional viewport's. A
  /// `SingleChildScrollView`, which a scrolling `TabBar` is built in, answers, so it is asked.
  ///
  /// It walks the child's render tree, which is small for a bar, on each layout. A render object
  /// from another package that refuses to answer is not known here, and asserts as it would under
  /// an `IntrinsicHeight`.
  static bool _answersIntrinsics(final RenderObject box) {
    if (box is RenderAbstractLayoutBuilderMixin || box is RenderViewportBase || box is RenderTwoDimensionalViewport) {
      return false;
    }
    bool answers = true;
    box.visitChildren((final RenderObject child) => answers = answers && _answersIntrinsics(child));
    return answers;
  }
}
