import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'waters.dart';

/// Where content comes to rest under a dock with a wake.
enum HarborRest {
  /// Past the end of the wake, so the first row at rest is fully clear of the
  /// fade. The default.
  wakeEnd,

  /// At the dock's inner face, with the last stretch of the wake over the
  /// first row.
  dockEdge,
}

enum HarborWakeKind { none, fade, hairline }

/// What a dock leaves behind it on the water: how the boundary between the
/// dock and the content passing under it is drawn.
///
/// A fade makes content dissolve as it passes under the dock, and its length
/// counts toward how far content rests from the dock ([restsAt]), so the band
/// and the resting line can never drift apart. A hairline draws a line on the
/// dock's inner face, for a bar that content scrolls up to rather than under.
@immutable
class HarborWake with Diagnosticable {
  const HarborWake._(this.kind, {this.length = 0.0, this.blurSigma = 0.0, this.color, this.restsAt = HarborRest.wakeEnd});

  /// No boundary at all.
  static const HarborWake none = HarborWake._(HarborWakeKind.none);

  /// Content fades out over [length] past the dock's inner face, and the
  /// water under the dock is frosted by [blurSigma] if it is above zero.
  const HarborWake.fade({final double length = 16.0, final double blurSigma = 0.0, final HarborRest restsAt = HarborRest.wakeEnd})
    : this._(HarborWakeKind.fade, length: length, blurSigma: blurSigma, restsAt: restsAt);

  /// A line of [thickness] on the dock's inner face.
  ///
  /// [color] is a translucent black by default, a shade of whatever bar it is
  /// drawn on, as `BorderSide`'s default is black. A dark bar passes its own.
  const HarborWake.hairline({final double thickness = 1.0, final Color color = const Color(0x1F000000)})
    : this._(HarborWakeKind.hairline, length: thickness, color: color, restsAt: HarborRest.dockEdge);

  final HarborWakeKind kind;

  /// How far past the dock's inner face the fade runs, or the hairline's thickness.
  final double length;

  /// Frosting of the water under the dock; zero for none.
  final double blurSigma;

  /// The hairline's color.
  final Color? color;

  final HarborRest restsAt;

  /// How much of [length] adds to the distance content rests from the dock.
  double get clearance => kind == HarborWakeKind.fade && restsAt == HarborRest.wakeEnd ? length : 0.0;

  @override
  bool operator ==(final Object other) =>
      other is HarborWake &&
      other.kind == kind &&
      other.length == length &&
      other.blurSigma == blurSigma &&
      other.color == color &&
      other.restsAt == restsAt;

  @override
  int get hashCode => Object.hash(kind, length, blurSigma, color, restsAt);

  @override
  String toStringShort() => '${objectRuntimeType(this, 'HarborWake')}.${kind.name}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    switch (kind) {
      case HarborWakeKind.none:
        break;
      case HarborWakeKind.fade:
        properties.add(DoubleProperty('length', length, defaultValue: 16.0));
        properties.add(DoubleProperty('blurSigma', blurSigma, defaultValue: 0.0));
        properties.add(EnumProperty<HarborRest>('restsAt', restsAt, defaultValue: HarborRest.wakeEnd));
      case HarborWakeKind.hairline:
        properties.add(DoubleProperty('thickness', length, defaultValue: 1.0));
        properties.add(ColorProperty('color', color, defaultValue: const Color(0x1F000000)));
    }
  }
}

/// Wraps a harbor's body so content fades out as it passes under the docks.
///
/// Give a [Harbor] your own to draw the wake differently (a progressive blur
/// shader, say). [wakes] holds every edge with a fade wake, measured from the
/// body's edge.
typedef HarborWakePainter = Widget Function(BuildContext context, Map<HarborEdge, HarborWakeBand> wakes, Widget body);

/// The default [HarborWakePainter]: an alpha mask over the body, transparent
/// at the body's edge, a quarter opaque at the dock's inner face, and fully
/// opaque where the wake ends.
@Deprecated('Use HarborWakeMask.alphaWake instead. Deprecated after 0.2.0.')
Widget harborAlphaWake(final BuildContext context, final Map<HarborEdge, HarborWakeBand> wakes, final Widget body) =>
    HarborWakeMask.alphaWake(context, wakes, body);

/// An alpha mask that fades [child] out along the [wakes] bands. Paints
/// nothing extra when there are none, so it can always be in the tree.
class HarborWakeMask extends SingleChildRenderObjectWidget {
  const HarborWakeMask({super.key, required this.wakes, this.dockOpacity = 0.25, super.child});

  /// The default [HarborWakePainter]: an alpha mask over the body, transparent
  /// at the body's edge, a quarter opaque at the dock's inner face, and fully
  /// opaque where the wake ends. Give it to `Harbor(wakePainter:)` to fade the
  /// whole body.
  static Widget alphaWake(final BuildContext context, final Map<HarborEdge, HarborWakeBand> wakes, final Widget body) =>
      HarborWakeMask(wakes: wakes, child: body);

  final Map<HarborEdge, HarborWakeBand> wakes;

  /// How visible content is at the dock's inner face.
  final double dockOpacity;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<HarborEdge, HarborWakeBand>>('wakes', wakes));
    properties.add(DoubleProperty('dockOpacity', dockOpacity, defaultValue: 0.25));
  }

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      RenderHarborWakeMask(wakes: wakes, dockOpacity: dockOpacity, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(final BuildContext context, final RenderHarborWakeMask renderObject) {
    renderObject
      ..wakes = wakes
      ..dockOpacity = dockOpacity
      ..textDirection = Directionality.of(context);
  }
}

class RenderHarborWakeMask extends RenderProxyBox {
  RenderHarborWakeMask({
    required this._wakes,
    required this._dockOpacity,
    required this._textDirection,
  });

  Map<HarborEdge, HarborWakeBand> _wakes;
  set wakes(final Map<HarborEdge, HarborWakeBand> value) {
    _wakes = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  double _dockOpacity;
  set dockOpacity(final double value) {
    if (_dockOpacity != value) {
      _dockOpacity = value;
      markNeedsPaint();
    }
  }

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsPaint();
    }
  }

  final LayerHandle<ShaderMaskLayer> _vertical = LayerHandle<ShaderMaskLayer>();
  final LayerHandle<ShaderMaskLayer> _horizontal = LayerHandle<ShaderMaskLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null && _wakes.values.any((final HarborWakeBand b) => b.wakeEnd > 0);

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    final HarborWakeBand top = _wakes[HarborEdge.top] ?? HarborWakeBand.none;
    final HarborWakeBand bottom = _wakes[HarborEdge.bottom] ?? HarborWakeBand.none;
    final bool ltr = _textDirection == TextDirection.ltr;
    final HarborWakeBand left = _wakes[ltr ? HarborEdge.start : HarborEdge.end] ?? HarborWakeBand.none;
    final HarborWakeBand right = _wakes[ltr ? HarborEdge.end : HarborEdge.start] ?? HarborWakeBand.none;
    final bool vertical = top.wakeEnd > 0 || bottom.wakeEnd > 0;
    final bool horizontal = left.wakeEnd > 0 || right.wakeEnd > 0;

    void paintHorizontal(final PaintingContext context, final Offset offset) {
      if (!horizontal) {
        _horizontal.layer = null;
        context.paintChild(child, offset);
        return;
      }
      final Rect rect = offset & size;
      _horizontal.layer = (_horizontal.layer ?? ShaderMaskLayer())
        ..shader = _gradient(left, right, size.width, Alignment.centerLeft, Alignment.centerRight).createShader(Offset.zero & size)
        ..maskRect = rect
        ..blendMode = BlendMode.dstIn;
      context.pushLayer(_horizontal.layer!, (final PaintingContext c, final Offset o) => c.paintChild(child, o), offset);
    }

    if (!vertical) {
      _vertical.layer = null;
      paintHorizontal(context, offset);
      return;
    }
    final Rect rect = offset & size;
    _vertical.layer = (_vertical.layer ?? ShaderMaskLayer())
      ..shader = _gradient(top, bottom, size.height, Alignment.topCenter, Alignment.bottomCenter).createShader(Offset.zero & size)
      ..maskRect = rect
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(_vertical.layer!, paintHorizontal, offset);
  }

  LinearGradient _gradient(
    final HarborWakeBand near,
    final HarborWakeBand far,
    final double extent,
    final Alignment begin,
    final Alignment end,
  ) {
    if (extent <= 0) {
      return const LinearGradient(colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFFFFF)]);
    }
    double at(final double distance) => (distance / extent).clamp(0.0, 1.0);
    final Color clear = const Color(0xFFFFFFFF).withValues(alpha: 0.0);
    final Color dock = const Color(0xFFFFFFFF).withValues(alpha: _dockOpacity);
    const Color solid = Color(0xFFFFFFFF);
    final List<Color> colors = <Color>[];
    final List<double> stops = <double>[];
    void add(final Color color, final double stop) {
      colors.add(color);
      stops.add(stops.isEmpty ? stop : (stop < stops.last ? stops.last : stop));
    }

    if (near.wakeEnd > 0) {
      add(clear, 0.0);
      add(dock, at(near.dockEdge));
      add(solid, at(near.wakeEnd));
    } else {
      add(solid, 0.0);
    }
    if (far.wakeEnd > 0) {
      add(solid, at(extent - far.wakeEnd));
      add(dock, at(extent - far.dockEdge));
      add(clear, 1.0);
    } else {
      add(solid, 1.0);
    }
    return LinearGradient(begin: begin, end: end, colors: colors, stops: stops);
  }

  @override
  void dispose() {
    _vertical.layer = null;
    _horizontal.layer = null;
    super.dispose();
  }
}
