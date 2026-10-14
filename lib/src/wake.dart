import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';
import 'waters.dart';

/// Where content comes to rest under a bar with a fade.
enum HarborRest {
  /// Past the end of the fade, so the first row at rest is fully clear of it. The default.
  fadeEnd,

  /// At the bar's inner face, with the last stretch of the fade over the first row.
  barFace;

  /// The old name of [fadeEnd].
  @Deprecated('Renamed fadeEnd. `dart fix` applies it.')
  static const HarborRest wakeEnd = fadeEnd;

  /// The old name of [barFace].
  @Deprecated('Renamed barFace. `dart fix` applies it.')
  static const HarborRest dockEdge = barFace;
}

enum HarborEdgeEffectKind { none, fade, hairline }

/// What a bar draws at its edge: how the boundary between the
/// bar and the content passing under it is drawn.
///
/// A fade makes content dissolve as it passes under the bar, and its length
/// counts toward how far content rests from the bar ([restsAt]), so the band
/// and the resting line can never drift apart. A hairline draws a line on the
/// bar's inner face, for a bar that content scrolls up to rather than under.
///
/// See also:
///
///  * [ShaderMask] and [BackdropFilter], which a fade paints with.
@immutable
class HarborEdgeEffect with Diagnosticable {
  const HarborEdgeEffect._(
    this.kind, {
    this.length = 0.0,
    this.blurSigma = 0.0,
    this.color,
    this.restsAt = HarborRest.fadeEnd,
    this.faceOpacity = 0.25,
    this.curve = Curves.linear,
  }) : assert(faceOpacity >= 0.0 && faceOpacity <= 1.0, 'faceOpacity is an opacity, from 0 to 1.');

  /// No boundary at all.
  static const HarborEdgeEffect none = HarborEdgeEffect._(HarborEdgeEffectKind.none);

  /// Content fades out over [length] past the bar's inner face, and the
  /// content under the bar is frosted by [blurSigma] if it is above zero.
  ///
  /// Content is [faceOpacity] opaque at the bar's inner face, rises to fully
  /// opaque where the fade ends along [curve], and fades from [faceOpacity] to
  /// clear under the bar itself. The defaults, a quarter opaque and a
  /// straight line, are the ramp every fade had before these were options.
  /// `faceOpacity: 1` makes a band that still counts toward where content
  /// rests ([restsAt]) but does not fade anything past the bar.
  ///
  /// A fade is an alpha mask, so it takes no colour: it shows whatever is
  /// behind the content. For a tint, colour that background or give the bar
  /// a `backdrop`; for a scrim drawn over the content, give the `HarborFrame` a
  /// `edgeEffectPainter`, which is handed the measured bands.
  const HarborEdgeEffect.fade({
    this.length = 16.0,
    this.blurSigma = 0.0,
    this.restsAt = HarborRest.fadeEnd,
    final double faceOpacity = 0.25,
    @Deprecated('Renamed faceOpacity. `dart fix` applies it.') final double? dockOpacity,
    this.curve = Curves.linear,
  }) : assert(
         dockOpacity == null || faceOpacity == 0.25 || dockOpacity == faceOpacity,
         'faceOpacity and the deprecated dockOpacity disagree. Give faceOpacity alone.',
       ),
       assert(
         (dockOpacity ?? faceOpacity) >= 0.0 && (dockOpacity ?? faceOpacity) <= 1.0,
         'faceOpacity is an opacity, from 0 to 1.',
       ),
       kind = HarborEdgeEffectKind.fade,
       color = null,
       faceOpacity = dockOpacity ?? faceOpacity;

  /// A line of [thickness] on the bar's inner face.
  ///
  /// [color] is a translucent black by default, a shade of whatever bar it is
  /// drawn on, as `BorderSide`'s default is black. A dark bar passes its own.
  const HarborEdgeEffect.hairline({final double thickness = 1.0, final Color color = const Color(0x1F000000)})
    : this._(HarborEdgeEffectKind.hairline, length: thickness, color: color, restsAt: HarborRest.barFace);

  final HarborEdgeEffectKind kind;

  /// How far past the bar's inner face the fade runs, or the hairline's thickness.
  final double length;

  /// Frosting of the content under the bar; zero for none.
  final double blurSigma;

  /// The hairline's color.
  final Color? color;

  final HarborRest restsAt;

  /// How opaque content is at the bar's inner face, for a fade.
  final double faceOpacity;

  /// The old name of [faceOpacity].
  @Deprecated('Renamed faceOpacity. `dart fix` applies it.')
  double get dockOpacity => faceOpacity;

  /// The shape of a fade's ramp from [faceOpacity] at the bar's inner face to
  /// fully opaque where the fade ends.
  final Curve curve;

  /// How much of [length] adds to the distance content rests from the bar.
  double get clearance => kind == HarborEdgeEffectKind.fade && restsAt == HarborRest.fadeEnd ? length : 0.0;

  @override
  bool operator ==(final Object other) =>
      other is HarborEdgeEffect &&
      other.kind == kind &&
      other.length == length &&
      other.blurSigma == blurSigma &&
      other.color == color &&
      other.restsAt == restsAt &&
      other.faceOpacity == faceOpacity &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(kind, length, blurSigma, color, restsAt, faceOpacity, curve);

  @override
  String toStringShort() => '${objectRuntimeType(this, 'HarborEdgeEffect')}.${kind.name}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    switch (kind) {
      case HarborEdgeEffectKind.none:
        break;
      case HarborEdgeEffectKind.fade:
        properties.add(DoubleProperty('length', length, defaultValue: 16.0));
        properties.add(DoubleProperty('blurSigma', blurSigma, defaultValue: 0.0));
        properties.add(EnumProperty<HarborRest>('restsAt', restsAt, defaultValue: HarborRest.fadeEnd));
        properties.add(DoubleProperty('faceOpacity', faceOpacity, defaultValue: 0.25));
        properties.add(DiagnosticsProperty<Curve>('curve', curve, defaultValue: Curves.linear));
      case HarborEdgeEffectKind.hairline:
        properties.add(DoubleProperty('thickness', length, defaultValue: 1.0));
        properties.add(ColorProperty('color', color, defaultValue: const Color(0x1F000000)));
    }
  }
}

/// The old name of [HarborEdgeEffect], whose constructors keep their names.
///
/// A subclass rather than a typedef: `dart fix` renames `fade(dockOpacity:)`, and a typedef cannot
/// carry a fix on a named constructor's call.
@Deprecated('Renamed HarborEdgeEffect. `dart fix` applies it.')
class HarborWake extends HarborEdgeEffect {
  const HarborWake._none() : super._(HarborEdgeEffectKind.none);

  /// The old name of [HarborEdgeEffect.none].
  static const HarborWake none = HarborWake._none();

  /// The old name of [HarborEdgeEffect.fade].
  @Deprecated('Renamed HarborEdgeEffect.fade. `dart fix` applies it.')
  const HarborWake.fade({
    super.length = 16.0,
    super.blurSigma,
    super.restsAt,
    final double faceOpacity = 0.25,
    @Deprecated('Renamed faceOpacity. `dart fix` applies it.') final double? dockOpacity,
    super.curve,
  }) : assert(
         dockOpacity == null || faceOpacity == 0.25 || dockOpacity == faceOpacity,
         'faceOpacity and the deprecated dockOpacity disagree. Give faceOpacity alone.',
       ),
       super._(HarborEdgeEffectKind.fade, faceOpacity: dockOpacity ?? faceOpacity);

  /// The old name of [HarborEdgeEffect.hairline].
  @Deprecated('Renamed HarborEdgeEffect.hairline. `dart fix` applies it.')
  const HarborWake.hairline({final double thickness = 1.0, final Color color = const Color(0x1F000000)})
    : super._(HarborEdgeEffectKind.hairline, length: thickness, color: color, restsAt: HarborRest.barFace);
}

/// Wraps a frame's body so content fades out as it passes under the bars.
///
/// Give a [HarborFrame] your own to draw the edge effect differently (a progressive blur
/// shader, say). [bands] holds every edge with a fade, measured from the
/// body's edge.
typedef HarborEdgeEffectPainter =
    Widget Function(BuildContext context, Map<HarborEdge, HarborFadeBand> bands, Widget body);

/// The default [HarborEdgeEffectPainter]: an alpha mask over the body, transparent
/// at the body's edge, a quarter opaque at the bar's inner face, and fully
/// opaque where the fade ends.
@Deprecated('Use HarborFadeMask.alphaFade instead. Deprecated after 0.2.0.')
Widget harborAlphaWake(final BuildContext context, final Map<HarborEdge, HarborFadeBand> bands, final Widget body) =>
    HarborFadeMask.alphaFade(context, bands, body);

/// An alpha mask that fades [child] out along its fade [bands]. Paints
/// nothing extra when there are none, so it can always be in the tree.
class HarborFadeMask extends SingleChildRenderObjectWidget {
  const HarborFadeMask({super.key, required this.bands, this.faceOpacity = 0.25, super.child});

  /// The default [HarborEdgeEffectPainter]: an alpha mask over the body, transparent
  /// at the body's edge, a quarter opaque at the bar's inner face (or the
  /// band's own [HarborFadeBand.faceOpacity]), and fully opaque where the fade
  /// ends, along the band's [HarborFadeBand.curve]. Give it to
  /// `HarborFrame(edgeEffectPainter:)` to fade the whole body.
  static Widget alphaFade(final BuildContext context, final Map<HarborEdge, HarborFadeBand> bands, final Widget body) =>
      HarborFadeMask(bands: bands, child: body);

  /// The old name of [alphaFade].
  @Deprecated('Renamed alphaFade. `dart fix` applies it.')
  static Widget alphaWake(final BuildContext context, final Map<HarborEdge, HarborFadeBand> bands, final Widget body) =>
      alphaFade(context, bands, body);

  /// The fade bands, by edge, measured from the body's edge.
  final Map<HarborEdge, HarborFadeBand> bands;

  /// The old name of [bands].
  @Deprecated('Renamed bands. `dart fix` applies it.')
  Map<HarborEdge, HarborFadeBand> get wakes => bands;

  /// How visible content is at the bar's inner face, for a band that does
  /// not say ([HarborFadeBand.faceOpacity] is null, as it is for a
  /// `HarborEdgeEffect.fade` at its default).
  final double faceOpacity;

  /// The old name of [faceOpacity].
  @Deprecated('Renamed faceOpacity. `dart fix` applies it.')
  double get dockOpacity => faceOpacity;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Map<HarborEdge, HarborFadeBand>>('bands', bands));
    properties.add(DoubleProperty('faceOpacity', faceOpacity, defaultValue: 0.25));
  }

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      RenderHarborWakeMask(bands: bands, faceOpacity: faceOpacity, textDirection: Directionality.of(context));

  @override
  void updateRenderObject(final BuildContext context, final RenderHarborWakeMask renderObject) {
    renderObject
      ..bands = bands
      ..faceOpacity = faceOpacity
      ..textDirection = Directionality.of(context);
  }
}

/// The old name of [HarborFadeMask], which takes the old names of its parameters.
///
/// A subclass rather than a typedef, so the new constructor can keep its parameters required.
@Deprecated('Renamed HarborFadeMask. `dart fix` applies it.')
class HarborWakeMask extends HarborFadeMask {
  /// The old name of [HarborFadeMask.new].
  @Deprecated('Renamed HarborFadeMask. `dart fix` applies it.')
  const HarborWakeMask({
    super.key,
    @Deprecated('Renamed bands. `dart fix` applies it.') final Map<HarborEdge, HarborFadeBand>? wakes,
    @Deprecated('Renamed faceOpacity. `dart fix` applies it.') final double? dockOpacity,
    super.child,
  }) : assert(wakes != null, 'wakes is required.'),
       super(bands: wakes ?? const <HarborEdge, HarborFadeBand>{}, faceOpacity: dockOpacity ?? 0.25);

  /// The old name of [HarborFadeMask.alphaFade].
  @Deprecated('Renamed HarborFadeMask.alphaFade. `dart fix` applies it.')
  static Widget alphaWake(final BuildContext context, final Map<HarborEdge, HarborFadeBand> wakes, final Widget body) =>
      HarborFadeMask.alphaFade(context, wakes, body);
}

class RenderHarborWakeMask extends RenderProxyBox {
  RenderHarborWakeMask({required this._bands, required this._faceOpacity, required this._textDirection});

  Map<HarborEdge, HarborFadeBand> _bands;
  set bands(final Map<HarborEdge, HarborFadeBand> value) {
    _bands = value;
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  double _faceOpacity;
  set faceOpacity(final double value) {
    if (_faceOpacity != value) {
      _faceOpacity = value;
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

  /// How many steps a curved ramp is drawn in.
  static const int _rampSamples = 12;

  final LayerHandle<ShaderMaskLayer> _vertical = LayerHandle<ShaderMaskLayer>();
  final LayerHandle<ShaderMaskLayer> _horizontal = LayerHandle<ShaderMaskLayer>();

  @override
  bool get alwaysNeedsCompositing => child != null && _bands.values.any((final HarborFadeBand b) => b.fadeEnd > 0);

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    final HarborFadeBand top = _bands[HarborEdge.top] ?? HarborFadeBand.none;
    final HarborFadeBand bottom = _bands[HarborEdge.bottom] ?? HarborFadeBand.none;
    final bool ltr = _textDirection == TextDirection.ltr;
    final HarborFadeBand left = _bands[ltr ? HarborEdge.start : HarborEdge.end] ?? HarborFadeBand.none;
    final HarborFadeBand right = _bands[ltr ? HarborEdge.end : HarborEdge.start] ?? HarborFadeBand.none;
    final bool vertical = top.fadeEnd > 0 || bottom.fadeEnd > 0;
    final bool horizontal = left.fadeEnd > 0 || right.fadeEnd > 0;

    void paintHorizontal(final PaintingContext context, final Offset offset) {
      if (!horizontal) {
        _horizontal.layer = null;
        context.paintChild(child, offset);
        return;
      }
      final Rect rect = offset & size;
      _horizontal.layer = (_horizontal.layer ?? ShaderMaskLayer())
        ..shader = _gradient(
          left,
          right,
          size.width,
          Alignment.centerLeft,
          Alignment.centerRight,
        ).createShader(Offset.zero & size)
        ..maskRect = rect
        ..blendMode = BlendMode.dstIn;
      context.pushLayer(
        _horizontal.layer!,
        (final PaintingContext c, final Offset o) => c.paintChild(child, o),
        offset,
      );
    }

    if (!vertical) {
      _vertical.layer = null;
      paintHorizontal(context, offset);
      return;
    }
    final Rect rect = offset & size;
    _vertical.layer = (_vertical.layer ?? ShaderMaskLayer())
      ..shader = _gradient(
        top,
        bottom,
        size.height,
        Alignment.topCenter,
        Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..maskRect = rect
      ..blendMode = BlendMode.dstIn;
    context.pushLayer(_vertical.layer!, paintHorizontal, offset);
  }

  LinearGradient _gradient(
    final HarborFadeBand near,
    final HarborFadeBand far,
    final double extent,
    final Alignment begin,
    final Alignment end,
  ) {
    if (extent <= 0) {
      return const LinearGradient(colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFFFFFF)]);
    }
    double at(final double distance) => (distance / extent).clamp(0.0, 1.0);
    Color alpha(final double value) => const Color(0xFFFFFFFF).withValues(alpha: value);
    final Color clear = alpha(0.0);
    const Color solid = Color(0xFFFFFFFF);
    final List<Color> colors = <Color>[];
    final List<double> stops = <double>[];
    void add(final Color color, final double stop) {
      colors.add(color);
      stops.add(stops.isEmpty ? stop : (stop < stops.last ? stops.last : stop));
    }

    // A curved ramp is sampled into stops between the bar's face and the
    // fade's end; a straight one needs none, so the default ramp is the three
    // stops it always was.
    Iterable<(double, double)> ramp(final HarborFadeBand band) sync* {
      final Curve curve = band.curve ?? Curves.linear;
      if (curve == Curves.linear) {
        return;
      }
      final double dock = band.faceOpacity ?? _faceOpacity;
      for (int i = 1; i < _rampSamples; i++) {
        final double t = i / _rampSamples;
        yield (band.barFace + band.length * t, dock + (1.0 - dock) * curve.transform(t));
      }
    }

    if (near.fadeEnd > 0) {
      add(clear, 0.0);
      add(alpha(near.faceOpacity ?? _faceOpacity), at(near.barFace));
      for (final (double distance, double opacity) in ramp(near)) {
        add(alpha(opacity), at(distance));
      }
      add(solid, at(near.fadeEnd));
    } else {
      add(solid, 0.0);
    }
    if (far.fadeEnd > 0) {
      add(solid, at(extent - far.fadeEnd));
      for (final (double distance, double opacity) in ramp(far).toList().reversed) {
        add(alpha(opacity), at(extent - distance));
      }
      add(alpha(far.faceOpacity ?? _faceOpacity), at(extent - far.barFace));
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
