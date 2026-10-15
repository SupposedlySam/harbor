import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'tide.dart';
import 'wake.dart';

/// How a bar meets the body of its frame.
enum HarborBarKind {
  /// The body runs under it, and comes to rest clear of it. A translucent header over a scrolling
  /// list.
  overlay,

  /// The body stops at it: it takes its space, and the body starts where it ends. A tab bar the
  /// list ends above.
  ///
  /// Solid bars are always nearer the edge than overlay bars on the same edge.
  solid;

  /// The old name of [overlay].
  @Deprecated('Renamed overlay. `dart fix` applies it.')
  static const HarborBarKind pier = overlay;

  /// The old name of [solid].
  @Deprecated('Renamed solid. `dart fix` applies it.')
  static const HarborBarKind quay = solid;
}

/// How a bar takes the system edge it is built against.
enum HarborSystemEdgeStance {
  /// It absorbs the system edge as it is now, which goes to zero at the bottom while
  /// the keyboard is up. The default for a bar that [HarborKeyboardStance.rides].
  ///
  /// At the bottom it gives the system edge up only as the keyboard covers it, so a
  /// riding bar never dips while a keyboard is still shorter than the
  /// home indicator: it sits at the larger of the two.
  live,

  /// It absorbs the system edge as it is with the keyboard down, so it keeps its
  /// height while the keyboard covers it. The default for a bar that [HarborKeyboardStance.stays].
  steady,

  /// It leaves the system edge alone, because what it holds already runs to the
  /// screen's edge, and takes no minimum either. The default for a bar that
  /// [HarborKeyboardStance.reserves].
  none,
}

/// Whether a bar is in service.
///
/// Despite its name, this is not a [State]: it is an enum, as [AnimationStatus] is.
enum HarborBarState {
  /// In service: drawn, tappable, and its space is taken.
  open,

  /// Lights out: not drawn and not tappable, but it keeps its space, so
  /// nothing moves. For a header that steps aside while a panel is up.
  dark,

  /// Withdrawn: it slides out toward its edge and gives its space back, so
  /// content flows into the space. For a tab bar that hides for a panel.
  withdrawn,
}

/// How a withdrawing bar gives its space back.
enum HarborExtentPolicy {
  /// The space shrinks with the bar as it slides out.
  follow,

  /// The space is held until the bar has fully left, so content reflows once,
  /// after the bar is gone, and never under a bar that is still visible.
  hold,

  /// The space is given back at once, while the bar is still sliding out.
  release,
}

/// A bar: something built against one edge of a [HarborFrame], such as a header, a tab bar, a rail
/// or a composer. Its size is measured, never declared, and it claims that much of the edge.
///
/// A bar absorbs the system edge it is against (it pads its [child] below the status bar, or above
/// the home indicator) and paints its [backdrop] under the whole of its space, system edge
/// included. The insets across it (a top bar's sides) are left in its child's `MediaQuery` for the
/// child to keep clear of, so a horizontal [HarborScrollView] in a header can still run to the
/// screen's edge.
///
/// Bars on the same edge stack in the order they are listed, the way a `Column` or `Row` would lay
/// them out.
///
/// A bar is a value, not a widget: a frame lays it out from its `top`, `bottom`, `start` and `end`
/// lists.
///
/// See also:
///
///  * `Scaffold.appBar` and `Scaffold.bottomNavigationBar`, which are solid bars; under
///    `Scaffold(extendBodyBehindAppBar: true)` an app bar is an overlay bar.
@immutable
class HarborBar with Diagnosticable {
  /// The body runs under it, as under an app bar with `extendBodyBehindAppBar`, and is told through
  /// `MediaQuery.padding` how far it reaches.
  const HarborBar.overlay({
    this.key,
    required this.child,
    this.edgeEffect = HarborEdgeEffect.none,
    this.keyboard = HarborKeyboardStance.stays,
    this.systemEdges,
    this.state = HarborBarState.open,
    this.extentPolicy = HarborExtentPolicy.hold,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutCubic,
    this.animationStyle,
    this.backdrop,
    this.hitTestBehavior = HitTestBehavior.opaque,
    @Deprecated('Use keyboard: HarborKeyboardStance.withdraws. `dart fix` applies it. Deprecated after 0.9.1.')
    this._withdrawsAtHighTide = false,
    this.restingExtent,
    this.minimum = 0.0,
    this.debugLabel,
  }) : kind = HarborBarKind.overlay,
       reserved = null;

  /// The body stops at it, as at `Scaffold.appBar`: the body starts where it ends, as in a `Column`.
  const HarborBar.solid({
    this.key,
    required this.child,
    this.edgeEffect = HarborEdgeEffect.none,
    this.keyboard = HarborKeyboardStance.stays,
    this.systemEdges,
    this.state = HarborBarState.open,
    this.extentPolicy = HarborExtentPolicy.hold,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutCubic,
    this.animationStyle,
    this.backdrop,
    this.hitTestBehavior = HitTestBehavior.opaque,
    @Deprecated('Use keyboard: HarborKeyboardStance.withdraws. `dart fix` applies it. Deprecated after 0.9.1.')
    this._withdrawsAtHighTide = false,
    this.restingExtent,
    this.minimum = 0.0,
    this.debugLabel,
  }) : kind = HarborBarKind.solid,
       reserved = null;

  /// A bar with nothing to lay out that holds [extent] against its edge, for
  /// something drawn elsewhere that the body must still keep clear of (a footer
  /// in an overlay, a bar a parent paints). It reaches [extent] in from the
  /// edge, system edge included: the larger of the system edge and [extent] when it is the
  /// outermost bar on its edge, and [extent] past the bars outside it when it
  /// is not. It paints nothing and takes no taps, so whatever it stands in for
  /// gets them.
  ///
  /// [kind] is [HarborBarKind.overlay] by default, so the body runs under it and keeps clear of
  /// it through its padding; [HarborBarKind.solid] makes the body stop at it. [keyboard] is how it
  /// meets the keyboard, as for any bar: [HarborKeyboardStance.stays] keeps it at the edge, and
  /// [HarborKeyboardStance.rides] lifts it with the keyboard.
  ///
  /// Before this, the way to say it was an overlay bar whose child was
  /// `SizedBox.shrink()` with `minimum: extent`, which reserved nothing when
  /// another bar sat outside it, since only the outermost bar takes the system edge
  /// and its minimum.
  const HarborBar.reserve({
    this.key,
    required final double extent,
    this.kind = HarborBarKind.overlay,
    this.keyboard = HarborKeyboardStance.stays,
    this.systemEdges,
    this.state = HarborBarState.open,
    this.extentPolicy = HarborExtentPolicy.hold,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeInOutCubic,
    this.animationStyle,
    @Deprecated('Use keyboard: HarborKeyboardStance.withdraws. `dart fix` applies it. Deprecated after 0.9.1.')
    this._withdrawsAtHighTide = false,
    this.debugLabel,
  }) : assert(extent >= 0.0, 'A reserved extent cannot be negative.'),
       reserved = extent,
       child = const SizedBox.shrink(),
       edgeEffect = HarborEdgeEffect.none,
       backdrop = null,
       hitTestBehavior = HitTestBehavior.translucent,
       restingExtent = null,
       minimum = 0.0;

  /// Keeps the bar's state (its slide animation) when the bars around it change.
  final Key? key;

  /// The extent a [HarborBar.reserve] holds; null for a bar with a child.
  final double? reserved;

  final Widget child;
  final HarborBarKind kind;

  /// How the boundary between this bar and the content beyond it is drawn: a fade, a hairline or
  /// nothing. Only the innermost bar on an edge draws one.
  final HarborEdgeEffect edgeEffect;

  /// The old name of [edgeEffect].
  @Deprecated('Renamed edgeEffect. `dart fix` applies it.')
  HarborEdgeEffect get wake => edgeEffect;

  /// How the bar meets the keyboard. Matters on the bottom edge.
  final HarborKeyboardStance keyboard;

  /// The old name of [keyboard].
  @Deprecated('Renamed keyboard. `dart fix` applies it.')
  HarborKeyboardStance get tide => keyboard;

  /// How the bar takes the system edge on its edge; null picks the default for [keyboard].
  final HarborSystemEdgeStance? systemEdges;

  /// The old name of [systemEdges].
  @Deprecated('Renamed systemEdges. `dart fix` applies it.')
  HarborSystemEdgeStance? get coast => systemEdges;

  final HarborBarState state;

  /// How a withdrawing bar gives its space back.
  final HarborExtentPolicy extentPolicy;

  /// How long the bar takes to go dark, withdraw or return.
  final Duration duration;
  final Curve curve;

  /// Overrides [duration] and [curve], as `MaterialApp.themeAnimationStyle` overrides its
  /// duration and curve. Its `duration` and `curve` are for returning and lighting up, and its
  /// `reverseDuration` and `reverseCurve` for withdrawing and going dark; each falls back to the
  /// forward one, then to [duration] and [curve]. [AnimationStyle.noAnimation] changes the bar's
  /// state at once.
  final AnimationStyle? animationStyle;

  /// Painted under the bar's whole space, system edge included: its surface, or a
  /// frosted glass. It never takes taps itself.
  final Widget? backdrop;

  /// Whether taps on the bar's space stop at the bar. Opaque by default, so
  /// a tap on a header never reaches a row scrolled under it.
  final HitTestBehavior hitTestBehavior;

  /// Whether the bar withdraws while the keyboard is up: [keyboard] is
  /// [HarborKeyboardStance.withdraws], or the deprecated flag was given.
  @Deprecated('Read keyboard == HarborKeyboardStance.withdraws. Deprecated after 0.9.1.')
  bool get withdrawsAtHighTide => withdrawsWithKeyboard;

  /// Whether the bar withdraws while the keyboard is up, by its [keyboard] or the deprecated flag.
  @internal
  bool get withdrawsWithKeyboard => keyboard == HarborKeyboardStance.withdraws || _withdrawsAtHighTide;

  /// The deprecated `withdrawsAtHighTide:`, which a bar of any stance could be given.
  final bool _withdrawsAtHighTide;

  /// How far the bar reaches at rest, for a bar whose child grows (a rail that
  /// opens on focus). Content that follows the bar at rest keeps this
  /// distance while the bar grows over it. Null means its measured size.
  final double? restingExtent;

  /// The least room the bar gives the system edge on its edge: the system edge, or this,
  /// whichever is larger. A bottom bar keeps 16 above the edge of a phone with
  /// no home indicator.
  final double minimum;

  /// The bar's name in the [HarborInspector].
  final String? debugLabel;

  /// [systemEdges], or the default for [keyboard].
  HarborSystemEdgeStance get effectiveSystemEdges =>
      systemEdges ??
      switch (keyboard) {
        HarborKeyboardStance.rides => HarborSystemEdgeStance.live,
        HarborKeyboardStance.stays || HarborKeyboardStance.withdraws => HarborSystemEdgeStance.steady,
        HarborKeyboardStance.reserves => HarborSystemEdgeStance.none,
      };

  /// The old name of [effectiveSystemEdges].
  @Deprecated('Renamed effectiveSystemEdges. `dart fix` applies it.')
  HarborSystemEdgeStance get effectiveCoast => effectiveSystemEdges;

  /// This bar with a new [state], [child] or [keyboard].
  HarborBar copyWith({
    final HarborBarState? state,
    final Widget? child,
    final HarborKeyboardStance? keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final HarborKeyboardStance? tide,
  }) {
    assert(tide == null || keyboard == null, 'Give keyboard or the deprecated tide, not both.');
    return _copyWith(state: state, child: child, keyboard: keyboard ?? tide);
  }

  HarborBar _copyWith({final HarborBarState? state, final Widget? child, final HarborKeyboardStance? keyboard}) =>
      reserved != null
      ? HarborBar.reserve(
          key: key,
          extent: reserved!,
          kind: kind,
          keyboard: keyboard ?? this.keyboard,
          systemEdges: systemEdges,
          state: state ?? this.state,
          extentPolicy: extentPolicy,
          duration: duration,
          curve: curve,
          animationStyle: animationStyle,
          withdrawsAtHighTide: _withdrawsAtHighTide,
          debugLabel: debugLabel,
        )
      : kind == HarborBarKind.overlay
      ? HarborBar.overlay(
          key: key,
          child: child ?? this.child,
          edgeEffect: edgeEffect,
          keyboard: keyboard ?? this.keyboard,
          systemEdges: systemEdges,
          state: state ?? this.state,
          extentPolicy: extentPolicy,
          duration: duration,
          curve: curve,
          animationStyle: animationStyle,
          backdrop: backdrop,
          hitTestBehavior: hitTestBehavior,
          withdrawsAtHighTide: _withdrawsAtHighTide,
          restingExtent: restingExtent,
          minimum: minimum,
          debugLabel: debugLabel,
        )
      : HarborBar.solid(
          key: key,
          child: child ?? this.child,
          edgeEffect: edgeEffect,
          keyboard: keyboard ?? this.keyboard,
          systemEdges: systemEdges,
          state: state ?? this.state,
          extentPolicy: extentPolicy,
          duration: duration,
          curve: curve,
          animationStyle: animationStyle,
          backdrop: backdrop,
          hitTestBehavior: hitTestBehavior,
          withdrawsAtHighTide: _withdrawsAtHighTide,
          restingExtent: restingExtent,
          minimum: minimum,
          debugLabel: debugLabel,
        );

  @override
  String toStringShort() => '${objectRuntimeType(this, 'HarborBar')}.${reserved != null ? 'reserve' : kind.name}';

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Key>('key', key, defaultValue: null));
    properties.add(
      DiagnosticsProperty<HarborEdgeEffect>('edgeEffect', edgeEffect, defaultValue: HarborEdgeEffect.none),
    );
    properties.add(EnumProperty<HarborKeyboardStance>('keyboard', keyboard, defaultValue: HarborKeyboardStance.stays));
    properties.add(EnumProperty<HarborSystemEdgeStance>('systemEdges', systemEdges, defaultValue: null));
    properties.add(EnumProperty<HarborBarState>('state', state, defaultValue: HarborBarState.open));
    properties.add(
      EnumProperty<HarborExtentPolicy>('extentPolicy', extentPolicy, defaultValue: HarborExtentPolicy.hold),
    );
    properties.add(
      DiagnosticsProperty<Duration>('duration', duration, defaultValue: const Duration(milliseconds: 250)),
    );
    properties.add(DiagnosticsProperty<Curve>('curve', curve, defaultValue: Curves.easeInOutCubic));
    properties.add(ObjectFlagProperty<Widget>.has('backdrop', backdrop));
    properties.add(
      EnumProperty<HitTestBehavior>('hitTestBehavior', hitTestBehavior, defaultValue: HitTestBehavior.opaque),
    );
    properties.add(
      FlagProperty('withdrawsAtHighTide', value: _withdrawsAtHighTide, ifTrue: 'withdraws while the keyboard is up'),
    );
    properties.add(DoubleProperty('restingExtent', restingExtent, defaultValue: null));
    properties.add(DoubleProperty('minimum', minimum, defaultValue: 0.0));
    properties.add(DoubleProperty('reserved', reserved, defaultValue: null));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

/// The old name of [HarborBar], whose constructors were renamed too: [HarborDock.pier] is
/// [HarborBar.overlay] and [HarborDock.quay] is [HarborBar.solid].
///
/// A subclass rather than a typedef, so `dart fix` can rename the constructors with the class.
@Deprecated('Renamed HarborBar. `dart fix` applies it.')
class HarborDock extends HarborBar {
  /// The old name of [HarborBar.overlay].
  @Deprecated('Renamed HarborBar.overlay. `dart fix` applies it.')
  const HarborDock.pier({
    super.key,
    required super.child,
    final HarborEdgeEffect? edgeEffect,
    @Deprecated('Renamed edgeEffect. `dart fix` applies it.') final HarborEdgeEffect? wake,
    final HarborKeyboardStance? keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final HarborKeyboardStance? tide,
    final HarborSystemEdgeStance? systemEdges,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdgeStance? coast,
    super.state,
    super.extentPolicy,
    super.duration,
    super.curve,
    super.animationStyle,
    super.backdrop,
    super.hitTestBehavior,
    super.withdrawsAtHighTide,
    super.restingExtent,
    super.minimum,
    super.debugLabel,
  }) : assert(wake == null || edgeEffect == null, 'Give edgeEffect or the deprecated wake, not both.'),
       assert(tide == null || keyboard == null, 'Give keyboard or the deprecated tide, not both.'),
       assert(coast == null || systemEdges == null, 'Give systemEdges or the deprecated coast, not both.'),
       super.overlay(
         edgeEffect: edgeEffect ?? wake ?? HarborEdgeEffect.none,
         keyboard: keyboard ?? tide ?? HarborKeyboardStance.stays,
         systemEdges: systemEdges ?? coast,
       );

  /// The old name of [HarborBar.solid].
  @Deprecated('Renamed HarborBar.solid. `dart fix` applies it.')
  const HarborDock.quay({
    super.key,
    required super.child,
    final HarborEdgeEffect? edgeEffect,
    @Deprecated('Renamed edgeEffect. `dart fix` applies it.') final HarborEdgeEffect? wake,
    final HarborKeyboardStance? keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final HarborKeyboardStance? tide,
    final HarborSystemEdgeStance? systemEdges,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdgeStance? coast,
    super.state,
    super.extentPolicy,
    super.duration,
    super.curve,
    super.animationStyle,
    super.backdrop,
    super.hitTestBehavior,
    super.withdrawsAtHighTide,
    super.restingExtent,
    super.minimum,
    super.debugLabel,
  }) : assert(wake == null || edgeEffect == null, 'Give edgeEffect or the deprecated wake, not both.'),
       assert(tide == null || keyboard == null, 'Give keyboard or the deprecated tide, not both.'),
       assert(coast == null || systemEdges == null, 'Give systemEdges or the deprecated coast, not both.'),
       super.solid(
         edgeEffect: edgeEffect ?? wake ?? HarborEdgeEffect.none,
         keyboard: keyboard ?? tide ?? HarborKeyboardStance.stays,
         systemEdges: systemEdges ?? coast,
       );

  /// The old name of [HarborBar.reserve].
  @Deprecated('Renamed HarborBar.reserve. `dart fix` applies it.')
  const HarborDock.reserve({
    super.key,
    required super.extent,
    super.kind,
    final HarborKeyboardStance? keyboard,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final HarborKeyboardStance? tide,
    final HarborSystemEdgeStance? systemEdges,
    @Deprecated('Renamed systemEdges. `dart fix` applies it.') final HarborSystemEdgeStance? coast,
    super.state,
    super.extentPolicy,
    super.duration,
    super.curve,
    super.animationStyle,
    super.withdrawsAtHighTide,
    super.debugLabel,
  }) : assert(tide == null || keyboard == null, 'Give keyboard or the deprecated tide, not both.'),
       assert(coast == null || systemEdges == null, 'Give systemEdges or the deprecated coast, not both.'),
       super.reserve(keyboard: keyboard ?? tide ?? HarborKeyboardStance.stays, systemEdges: systemEdges ?? coast);

  /// `HarborDock.pier`, `.quay` or `.reserve`, as the deprecated constructors were named, though
  /// [kind] says `overlay` or `solid`.
  @override
  String toStringShort() =>
      '${objectRuntimeType(this, 'HarborDock')}.${reserved != null
          ? 'reserve'
          : kind == HarborBarKind.overlay
          ? 'pier'
          : 'quay'}';
}
