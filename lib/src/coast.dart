import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'edge.dart';

/// What the coast is made of: the part of the screen the platform keeps for
/// itself. A chart shows which feature put each inset there.
enum HarborCoastFeature {
  statusBar,
  homeIndicator,
  cutout,
  titleSafe,
  fixed,

  /// A fold or hinge. Reserved and not yet read: [HarborCoast.features] never
  /// reports it, and no layout splits around a fold yet.
  hinge,
}

/// A TV's title-safe area: the band at each edge a television may crop or
/// overscan, which content must stay out of.
@immutable
class HarborTitleSafe with Diagnosticable {
  /// The same fraction of the screen's width on the sides and of its height
  /// at the top and bottom, as broadcast title-safe guides are given.
  const HarborTitleSafe.fraction(final double fraction) : _fraction = fraction, _fixed = null;

  /// A fixed band on each edge, in logical pixels.
  const HarborTitleSafe.fixed(final EdgeInsetsDirectional insets) : _fraction = null, _fixed = insets;

  final double? _fraction;
  final EdgeInsetsDirectional? _fixed;

  EdgeInsetsDirectional resolve(final Size size) {
    final double? fraction = _fraction;
    if (fraction == null) {
      return _fixed!;
    }
    return EdgeInsetsDirectional.symmetric(horizontal: size.width * fraction, vertical: size.height * fraction);
  }

  @override
  bool operator ==(final Object other) =>
      other is HarborTitleSafe && other._fraction == _fraction && other._fixed == _fixed;

  @override
  int get hashCode => Object.hash(_fraction, _fixed);

  @override
  String toStringShort() => '${objectRuntimeType(this, 'HarborTitleSafe')}.${_fraction == null ? 'fixed' : 'fraction'}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      PercentProperty('fraction', _fraction, level: _fraction == null ? DiagnosticLevel.fine : DiagnosticLevel.info),
    );
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('insets', _fixed, defaultValue: null));
  }
}

/// Where a harbor's coast comes from. Set it once, on [HarborSea] or on the
/// first [Harbor]; everything beneath inherits it.
///
/// See also:
///
///  * [MediaQueryData.padding] and [MediaQueryData.viewPadding], the insets the ambient coast is read
///    from.
@immutable
class HarborCoast with Diagnosticable {
  const HarborCoast._({this.titleSafe, this.fixedInsets, this.calmTide = false});

  /// The platform's insets, as `MediaQuery` reports them. The default.
  static const HarborCoast ambient = HarborCoast._();

  /// No coast and no tide at all: for a postcard frame that must render the
  /// same everywhere (golden tests, embeds, headless rendering).
  static const HarborCoast none = HarborCoast._(fixedInsets: EdgeInsetsDirectional.zero, calmTide: true);

  /// A coast of exactly [insets], whatever the platform reports. The tide still
  /// comes in unless [calmTide] is set.
  const HarborCoast.fixed(final EdgeInsetsDirectional insets, {final bool calmTide = false})
    : this._(fixedInsets: insets, calmTide: calmTide);

  /// A TV's title-safe band on top of what the platform reports, edge by edge
  /// whichever is larger.
  const HarborCoast.titleSafe(final HarborTitleSafe titleSafe) : this._(titleSafe: titleSafe);

  final HarborTitleSafe? titleSafe;
  final EdgeInsetsDirectional? fixedInsets;

  /// Whether the keyboard is kept out entirely.
  final bool calmTide;

  /// [mediaQuery] with its padding and view padding replaced by this coast.
  MediaQueryData apply(final MediaQueryData mediaQuery, final TextDirection direction) {
    if (identical(this, ambient) || this == ambient) {
      return mediaQuery;
    }
    final EdgeInsets padding;
    final EdgeInsets viewPadding;
    final EdgeInsetsDirectional? fixed = fixedInsets;
    if (fixed != null) {
      padding = fixed.resolve(direction);
      viewPadding = padding;
    } else {
      final EdgeInsets band = titleSafe!.resolve(mediaQuery.size).resolve(direction);
      padding = _atLeast(mediaQuery.padding, band);
      viewPadding = _atLeast(mediaQuery.viewPadding, band);
    }
    return mediaQuery.copyWith(
      padding: padding,
      viewPadding: viewPadding,
      viewInsets: calmTide ? EdgeInsets.zero : mediaQuery.viewInsets,
    );
  }

  /// The features each edge of [mediaQuery] is made of under this coast, for a chart.
  Map<HarborEdge, HarborCoastFeature?> features(final MediaQueryData mediaQuery, final TextDirection direction) {
    final EdgeInsetsDirectional platform = HarborEdges.directional(mediaQuery.padding, direction);
    final EdgeInsetsDirectional? band = titleSafe?.resolve(mediaQuery.size);
    HarborCoastFeature? featureOf(final HarborEdge edge) {
      if (fixedInsets != null) {
        return HarborEdges.of(fixedInsets!, edge) > 0 ? HarborCoastFeature.fixed : null;
      }
      final double fromPlatform = HarborEdges.of(platform, edge);
      if (band != null && HarborEdges.of(band, edge) >= fromPlatform && HarborEdges.of(band, edge) > 0) {
        return HarborCoastFeature.titleSafe;
      }
      if (fromPlatform <= 0) {
        return null;
      }
      return switch (edge) {
        HarborEdge.top => HarborCoastFeature.statusBar,
        HarborEdge.bottom => HarborCoastFeature.homeIndicator,
        HarborEdge.start || HarborEdge.end => HarborCoastFeature.cutout,
      };
    }

    return {for (final HarborEdge edge in HarborEdge.values) edge: featureOf(edge)};
  }

  static EdgeInsets _atLeast(final EdgeInsets a, final EdgeInsets b) => EdgeInsets.fromLTRB(
    math.max(a.left, b.left),
    math.max(a.top, b.top),
    math.max(a.right, b.right),
    math.max(a.bottom, b.bottom),
  );

  @override
  bool operator ==(final Object other) =>
      other is HarborCoast &&
      other.titleSafe == titleSafe &&
      other.fixedInsets == fixedInsets &&
      other.calmTide == calmTide;

  @override
  int get hashCode => Object.hash(titleSafe, fixedInsets, calmTide);

  @override
  String toStringShort() {
    final String name = this == ambient
        ? 'ambient'
        : this == none
        ? 'none'
        : fixedInsets != null
        ? 'fixed'
        : 'titleSafe';
    return '${objectRuntimeType(this, 'HarborCoast')}.$name';
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (this == none) {
      return;
    }
    properties.add(DiagnosticsProperty<EdgeInsetsDirectional>('fixedInsets', fixedInsets, defaultValue: null));
    properties.add(DiagnosticsProperty<HarborTitleSafe>('titleSafe', titleSafe, defaultValue: null));
    properties.add(FlagProperty('calmTide', value: calmTide, ifTrue: 'calm tide'));
  }
}
