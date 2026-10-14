import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// What an overlay puts between itself and the page: how it looks, whether a tap on it dismisses
/// the overlay, and what a screen reader says about it. Sheets ([showHarborSheet]), dialogs
/// ([showHarborDialog], [HarborDialogRoute]) and floats ([HarborFloat]) all take one, so a barrier
/// means the same everywhere.
///
/// * [HarborBarrier.dimmed]: a tinted barrier, `showGeneralDialog`'s half-black by default. The
///   default for sheets and dialogs.
/// * [HarborBarrier.clear]: a barrier you can see through. The page shows as it is but takes no
///   taps.
/// * [HarborBarrier.none]: no barrier. A sheet with none is not a route and leaves the page live,
///   as `showBottomSheet` does; a float with none is not modal (the default for floats). A dialog
///   is always a route with a barrier, so it cannot take none (asserted).
///
/// Back and Escape close an overlay whatever its barrier; [isDismissible] is only about a tap on the
/// barrier, as `ModalRoute.barrierDismissible` is.
///
/// Through 0.9 the barrier was loose parameters on each host (`isDismissible`, `barrierColor`,
/// `barrierLabel` and `barrierOnTapHint` on a sheet, `barrierDismissible` on a dialog, `modal` on a
/// float) and a sheet's `HarborSheetBarrier` enum. Those still work, deprecated, until 1.0.
///
/// See also:
///
///  * [ModalBarrier], which draws it.
@immutable
sealed class HarborBarrier with Diagnosticable {
  const HarborBarrier._();

  /// `showGeneralDialog`'s half-black: a dimmed barrier's colour unless it is given one.
  static const Color defaultColor = Color(0x80000000);

  /// A tinted barrier: [color] over the page, `showGeneralDialog`'s half-black by default. A tap on
  /// it closes the overlay unless [dismissible] is false. [label] is what a screen reader announces
  /// for it ('Dismiss' when null), and [onTapHint] what tapping it does, read as 'Double tap to …'.
  const factory HarborBarrier.dimmed({
    Color color,
    bool dismissible,
    String? label,
    String? onTapHint,
  }) = _DimmedBarrier;

  /// A barrier you can see through: the page shows as it is, but takes no taps. A tap on it closes
  /// the overlay unless [dismissible] is false. [label] and [onTapHint] are as on
  /// [HarborBarrier.dimmed].
  const factory HarborBarrier.clear({bool dismissible, String? label, String? onTapHint}) = _ClearBarrier;

  /// No barrier. On a sheet, the sheet is not a route and the page stays live, as under
  /// `showBottomSheet`; on a float, the float is not modal. A dialog cannot take it (asserted).
  static const HarborBarrier none = _NoBarrier();

  /// Its colour: transparent for [HarborBarrier.clear] and [none].
  Color get color;

  /// Whether a tap on it closes the overlay: the `dismissible` it was made with. Back and Escape
  /// close the overlay either way. True by default; false for [none], which has nothing to tap.
  ///
  /// Named apart from the `dismissible` it is made with because the deprecated
  /// [HarborSheetBarrier] implements this type, and its value `dismissible` holds the name.
  bool get isDismissible;

  /// What a screen reader announces for it. Null announces 'Dismiss', the English Material and
  /// Cupertino fall back to; a Material app passes
  /// `MaterialLocalizations.of(context).modalBarrierDismissLabel`.
  String? get label;

  /// What tapping it does, read by a screen reader as 'Double tap to …', as
  /// `ModalBottomSheetRoute.barrierOnTapHint` is. Null reads 'Double tap to activate'.
  String? get onTapHint;

  /// Whether there is a barrier at all: false only for [none].
  bool get blocks;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (!blocks) {
      return;
    }
    properties.add(FlagProperty('dismissible', value: isDismissible, ifFalse: 'not dismissible', defaultValue: true));
    properties.add(StringProperty('label', label, defaultValue: null));
    properties.add(StringProperty('onTapHint', onTapHint, defaultValue: null));
  }
}

final class _DimmedBarrier extends HarborBarrier {
  const _DimmedBarrier({
    this.color = HarborBarrier.defaultColor,
    final bool dismissible = true,
    this.label,
    this.onTapHint,
  }) : isDismissible = dismissible,
       super._();

  @override
  final Color color;

  @override
  final bool isDismissible;

  @override
  final String? label;

  @override
  final String? onTapHint;

  @override
  bool get blocks => true;

  @override
  bool operator ==(final Object other) =>
      other is _DimmedBarrier &&
      other.color == color &&
      other.isDismissible == isDismissible &&
      other.label == label &&
      other.onTapHint == onTapHint;

  @override
  int get hashCode => Object.hash(_DimmedBarrier, color, isDismissible, label, onTapHint);

  @override
  String toStringShort() => 'HarborBarrier.dimmed';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    properties.add(ColorProperty('color', color, defaultValue: HarborBarrier.defaultColor));
    super.debugFillProperties(properties);
  }
}

final class _ClearBarrier extends HarborBarrier {
  const _ClearBarrier({final bool dismissible = true, this.label, this.onTapHint})
    : isDismissible = dismissible,
      super._();

  @override
  Color get color => const Color(0x00000000);

  @override
  final bool isDismissible;

  @override
  final String? label;

  @override
  final String? onTapHint;

  @override
  bool get blocks => true;

  @override
  bool operator ==(final Object other) =>
      other is _ClearBarrier && other.isDismissible == isDismissible && other.label == label && other.onTapHint == onTapHint;

  @override
  int get hashCode => Object.hash(_ClearBarrier, isDismissible, label, onTapHint);

  @override
  String toStringShort() => 'HarborBarrier.clear';
}

final class _NoBarrier extends HarborBarrier {
  const _NoBarrier() : super._();

  @override
  Color get color => const Color(0x00000000);

  @override
  bool get isDismissible => false;

  @override
  String? get label => null;

  @override
  String? get onTapHint => null;

  @override
  bool get blocks => false;

  @override
  String toStringShort() => 'HarborBarrier.none';
}

/// How a sheet sits over the page that opened it.
///
/// Its values are barriers: `barrier: HarborSheetBarrier.none` still compiles where a
/// [HarborBarrier] is taken, and means what it did.
@Deprecated(
  'Use HarborBarrier: HarborSheetBarrier.dismissible is const HarborBarrier.dimmed(), .clear is '
  'const HarborBarrier.clear(), and .none is HarborBarrier.none. `dart fix` applies it to a showHarborSheet '
  'call that also gives isDismissible, barrierColor, barrierLabel or barrierOnTapHint. Deprecated after 0.9.0.',
)
enum HarborSheetBarrier implements HarborBarrier {
  /// A dimmed barrier that closes the sheet when tapped, unless the sheet is opened with
  /// `isDismissible: false`. `const HarborBarrier.dimmed()`.
  @Deprecated('Use const HarborBarrier.dimmed(). Deprecated after 0.9.0.')
  dismissible,

  /// A clear barrier: the page stays visible, and taps on it close the sheet, unless the sheet is
  /// opened with `isDismissible: false`. `const HarborBarrier.clear()`.
  @Deprecated('Use const HarborBarrier.clear(). Deprecated after 0.9.0.')
  clear,

  /// No barrier at all: the page stays live underneath. [HarborBarrier.none].
  @Deprecated('Use HarborBarrier.none. Deprecated after 0.9.0.')
  none;

  /// The [HarborBarrier] this value stands for.
  // ignore: deprecated_member_use_from_same_package
  HarborBarrier get _barrier => switch (this) {
    // ignore: deprecated_member_use_from_same_package
    HarborSheetBarrier.dismissible => const HarborBarrier.dimmed(),
    // ignore: deprecated_member_use_from_same_package
    HarborSheetBarrier.clear => const HarborBarrier.clear(),
    // ignore: deprecated_member_use_from_same_package
    HarborSheetBarrier.none => HarborBarrier.none,
  };

  @override
  Color get color => _barrier.color;

  @override
  bool get isDismissible => _barrier.isDismissible;

  @override
  String? get label => null;

  @override
  String? get onTapHint => null;

  @override
  bool get blocks => _barrier.blocks;

  @override
  String toStringShort() => 'HarborSheetBarrier.$name';

  @override
  String toString({final DiagnosticLevel minLevel = DiagnosticLevel.info}) => 'HarborSheetBarrier.$name';

  @override
  DiagnosticsNode toDiagnosticsNode({final String? name, final DiagnosticsTreeStyle? style}) =>
      DiagnosticsProperty<HarborSheetBarrier>(name, this, style: style ?? DiagnosticsTreeStyle.singleLine);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {}
}

/// [barrier] with the fields a host's deprecated loose parameters give overriding its own: the
/// spelling of a barrier through 0.9. [color] only tints a dimmed barrier, as `barrierColor` only
/// ever did; a clear one stays clear. A deprecated [HarborSheetBarrier] comes back as the
/// [HarborBarrier] it stands for.
@internal
HarborBarrier harborBarrierWith(
  final HarborBarrier barrier, {
  final Color? color,
  final bool? dismissible,
  final String? label,
  final String? onTapHint,
}) {
  final HarborBarrier plain = switch (barrier) {
    // ignore: deprecated_member_use_from_same_package
    final HarborSheetBarrier sheet => sheet._barrier,
    _ => barrier,
  };
  if (color == null && dismissible == null && label == null && onTapHint == null) {
    return plain;
  }
  return switch (plain) {
    _DimmedBarrier() => HarborBarrier.dimmed(
      color: color ?? plain.color,
      dismissible: dismissible ?? plain.isDismissible,
      label: label ?? plain.label,
      onTapHint: onTapHint ?? plain.onTapHint,
    ),
    _ClearBarrier() => HarborBarrier.clear(
      dismissible: dismissible ?? plain.isDismissible,
      label: label ?? plain.label,
      onTapHint: onTapHint ?? plain.onTapHint,
    ),
    _ => plain,
  };
}
