import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'dock.dart';
import 'edge.dart';
import 'wake.dart';

/// Builds one dock in its harbor: its coast padding, backdrop, frosting,
/// hairline, and its dark and withdraw animations.
class HarborDockSlot extends StatefulWidget {
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

  final HarborDock dock;
  final HarborEdge edge;

  /// The state after claims and the tide are applied.
  final HarborDockState state;

  /// What this dock pads its child by for the coast on its edge.
  final EdgeInsetsDirectional coastPadding;

  /// The `MediaQuery` its child sees: its own edge absorbed, the sides left in.
  final MediaQueryData mediaQuery;

  /// Whether this dock is the innermost on its edge, the one that leaves a wake.
  final bool leavesWake;

  /// Called when a withdraw or return animation finishes.
  final VoidCallback onSettled;

  @override
  State<HarborDockSlot> createState() => _HarborDockSlotState();
}

class _HarborDockSlotState extends State<HarborDockSlot> with TickerProviderStateMixin {
  late final AnimationController _presence = AnimationController(
    vsync: this,
    duration: widget.dock.duration,
    value: widget.state == HarborDockState.withdrawn ? 0.0 : 1.0,
  );
  late final AnimationController _light = AnimationController(
    vsync: this,
    duration: widget.dock.duration,
    value: widget.state == HarborDockState.dark ? 0.0 : 1.0,
  );
  late final CurvedAnimation _presenceCurve = CurvedAnimation(parent: _presence, curve: _curve, reverseCurve: _reverseCurve);
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

  /// The dock's own durations, or none when the platform asks for reduced motion.
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

  void _apply(final HarborDockState state) {
    switch (state) {
      case HarborDockState.open:
        _presence.forward();
        _light.forward();
      case HarborDockState.dark:
        _presence.forward();
        _light.reverse();
      case HarborDockState.withdrawn:
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
    final HarborDock dock = widget.dock;
    final HarborWake wake = widget.leavesWake ? dock.wake : HarborWake.none;
    final Widget content = Padding(
      padding: widget.coastPadding,
      child: MediaQuery(data: widget.mediaQuery, child: dock.child),
    );
    final Widget dockBody = Stack(
      children: <Widget>[
        Positioned.fill(child: _Frosting(sigma: wake.blurSigma)),
        // A backdrop is the dock's surface, never a tap target: the dock's
        // hitTestBehavior alone decides whether taps stop here.
        Positioned.fill(child: IgnorePointer(child: dock.backdrop ?? const SizedBox.shrink())),
        content,
      ],
    );
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_presence, _light]),
      builder: (final BuildContext context, final Widget? child) {
        final double presence = _presenceCurve.value;
        final double light = _lightCurve.value;
        final bool hidden = widget.state != HarborDockState.open;
        return _DockFrame(
          edge: widget.edge,
          kind: dock.kind,
          visualFactor: presence,
          extentFactor: _extentFactor(presence),
          restingExtent: dock.restingExtent,
          hairline: wake.kind == HarborWakeKind.hairline ? wake : null,
          // A dock that is dark or leaving is out of reach in every way, not only for taps:
          // keyboard focus and screen readers skip it too. Opacity alone hid a dark dock from
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
      child: Listener(behavior: dock.hitTestBehavior, child: dockBody),
    );
  }

  double _extentFactor(final double presence) {
    final bool leaving = widget.state == HarborDockState.withdrawn;
    return switch (widget.dock.extentPolicy) {
      HarborExtentPolicy.follow => presence,
      HarborExtentPolicy.hold => leaving ? (_presence.isDismissed ? 0.0 : 1.0) : presence,
      HarborExtentPolicy.release => leaving ? 0.0 : presence,
    };
  }
}

/// Frosts the water under a dock. Always in the tree; draws nothing at zero.
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

/// The render side of a dock: lays its child out at full size, sizes itself to
/// the visible share of it, and reports how much ground it takes.
class _DockFrame extends SingleChildRenderObjectWidget {
  const _DockFrame({
    required this.edge,
    required this.kind,
    required this.visualFactor,
    required this.extentFactor,
    required this.restingExtent,
    required this.hairline,
    super.child,
  });

  final HarborEdge edge;
  final HarborDockKind kind;
  final double visualFactor;
  final double extentFactor;
  final double? restingExtent;
  final HarborWake? hairline;

  @override
  RenderHarborDockFrame createRenderObject(final BuildContext context) => RenderHarborDockFrame(
    edge: edge,
    kind: kind,
    visualFactor: visualFactor,
    extentFactor: extentFactor,
    restingExtent: restingExtent,
    hairline: hairline,
    textDirection: Directionality.of(context),
  );

  @override
  void updateRenderObject(final BuildContext context, final RenderHarborDockFrame renderObject) {
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

class RenderHarborDockFrame extends RenderProxyBox {
  RenderHarborDockFrame({
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

  HarborDockKind _kind;
  HarborDockKind get kind => _kind;
  set kind(final HarborDockKind value) {
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

  HarborWake? _hairline;
  set hairline(final HarborWake? value) {
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

  /// The child's full size along the dock's axis, from the last layout.
  double get fullExtent => _fullExtent;

  /// How much ground the dock takes right now.
  double get extent => fullExtent * _extentFactor;

  /// How much ground the dock takes at rest.
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
    // Slide toward the dock's own edge as it withdraws.
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
      hitTest: (final BoxHitTestResult result, final Offset transformed) => child.hitTest(result, position: transformed),
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
    final HarborWake? hairline = _hairline;
    if (hairline != null && _visualFactor > 0) {
      final Paint paint = Paint()..color = hairline.color ?? const Color(0x33FFFFFF);
      final bool ltr = _textDirection == TextDirection.ltr;
      final Rect box = offset & size;
      final double t = hairline.length;
      final Rect line = switch (_edge) {
        HarborEdge.top => Rect.fromLTWH(box.left, box.bottom - t, box.width, t),
        HarborEdge.bottom => Rect.fromLTWH(box.left, box.top, box.width, t),
        HarborEdge.start => ltr ? Rect.fromLTWH(box.right - t, box.top, t, box.height) : Rect.fromLTWH(box.left, box.top, t, box.height),
        HarborEdge.end => ltr ? Rect.fromLTWH(box.left, box.top, t, box.height) : Rect.fromLTWH(box.right - t, box.top, t, box.height),
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
