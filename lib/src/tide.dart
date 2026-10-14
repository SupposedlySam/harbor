import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// How a bar meets the keyboard.
enum HarborKeyboardStance {
  /// Rides up on the keyboard, staying on top of it (a composer).
  rides,

  /// Stays put; the keyboard covers it (a tab bar).
  stays,

  /// Keeps the keyboard's space whether the keyboard is shown or not, so nothing moves (a styling
  /// panel).
  ///
  /// The bar holds the keyboard's settled height either way, so nothing moves when the keyboard
  /// comes and goes. Its child holds a [HarborKeyboardSpace] that fills that space while the
  /// keyboard is hidden.
  reserves;

  /// The old name of [rides].
  @Deprecated('Renamed rides. `dart fix` applies it.')
  static const HarborKeyboardStance float = rides;

  /// The old name of [stays].
  @Deprecated('Renamed stays. `dart fix` applies it.')
  static const HarborKeyboardStance pilings = stays;

  /// The old name of [reserves].
  @Deprecated('Renamed reserves. `dart fix` applies it.')
  static const HarborKeyboardStance dryDock = reserves;
}

/// Where the keyboard is in its cycle: [hidden], [opening], [shown] or [closing].
enum HarborKeyboardPhase {
  hidden,
  opening,
  shown,
  closing;

  /// The old name of [hidden].
  @Deprecated('Renamed hidden. `dart fix` applies it.')
  static const HarborKeyboardPhase low = hidden;

  /// The old name of [opening].
  @Deprecated('Renamed opening. `dart fix` applies it.')
  static const HarborKeyboardPhase rising = opening;

  /// The old name of [shown].
  @Deprecated('Renamed shown. `dart fix` applies it.')
  static const HarborKeyboardPhase high = shown;

  /// The old name of [closing].
  @Deprecated('Renamed closing. `dart fix` applies it.')
  static const HarborKeyboardPhase falling = closing;
}

/// The keyboard as a frame sees it.
///
/// Despite its name, this is not a [State]: it is an immutable snapshot, as [MediaQueryData] is.
@immutable
class HarborKeyboardState {
  const HarborKeyboardState({
    required this.height,
    required this.remaining,
    required this.settledHeight,
    required this.settledHeightIsEstimate,
    required this.phase,
  });

  /// How far the keyboard reaches up from the bottom of the screen, before any
  /// frame moved out of its way. For information, never for layout.
  final double height;

  /// How far the keyboard still reaches into this area, after the layers above
  /// kept clear of it. What layout uses.
  final double remaining;

  /// The last settled height of the keyboard in this orientation: what a bar that
  /// [HarborKeyboardStance.reserves] holds. Falls as well as rises when the keyboard settles lower.
  final double settledHeight;

  /// Whether [settledHeight] is a guess because no keyboard has settled here yet.
  final bool settledHeightIsEstimate;

  final HarborKeyboardPhase phase;

  /// The old name of [settledHeight].
  @Deprecated('Renamed settledHeight. `dart fix` applies it.')
  double get highWater => settledHeight;

  /// The old name of [settledHeightIsEstimate].
  @Deprecated('Renamed settledHeightIsEstimate. `dart fix` applies it.')
  bool get highWaterIsEstimate => settledHeightIsEstimate;

  /// Whether the keyboard is shown at all.
  bool get isShown => height > 0.0;

  /// The old name of [isShown].
  @Deprecated('Renamed isShown. `dart fix` applies it.')
  bool get isIn => isShown;

  bool get isSettled => phase == HarborKeyboardPhase.hidden || phase == HarborKeyboardPhase.shown;

  /// How much of the keyboard the frames above this point already kept clear of.
  double get avoidedAbove => height - remaining;

  @override
  bool operator ==(final Object other) =>
      other is HarborKeyboardState &&
      other.height == height &&
      other.remaining == remaining &&
      other.settledHeight == settledHeight &&
      other.settledHeightIsEstimate == settledHeightIsEstimate &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(height, remaining, settledHeight, settledHeightIsEstimate, phase);

  @override
  String toString() =>
      'HarborKeyboardState(height: $height, remaining: $remaining, settledHeight: $settledHeight, phase: $phase)';
}

/// The old name of [HarborKeyboardState], which takes the old names of its parameters.
///
/// A subclass rather than a typedef, so the new constructor can keep its parameters required.
@Deprecated('Renamed HarborKeyboardState. `dart fix` applies it.')
class HarborTideState extends HarborKeyboardState {
  /// The old name of [HarborKeyboardState.new].
  @Deprecated('Renamed HarborKeyboardState. `dart fix` applies it.')
  const HarborTideState({
    required super.height,
    required super.remaining,
    @Deprecated('Renamed settledHeight. `dart fix` applies it.') final double? highWater,
    @Deprecated('Renamed settledHeightIsEstimate. `dart fix` applies it.') final bool? highWaterIsEstimate,
    required super.phase,
  }) : assert(highWater != null, 'highWater is required.'),
       assert(highWaterIsEstimate != null, 'highWaterIsEstimate is required.'),
       super(settledHeight: highWater ?? 0.0, settledHeightIsEstimate: highWaterIsEstimate ?? true);
}

/// Keeps the keyboard's phase and its settled heights for one view. Owned by
/// the outermost frame ([HarborRoot], or the first [HarborFrame]).
class HarborTideGauge extends ChangeNotifier {
  HarborTideGauge({this.estimateFraction = 0.4});

  /// The share of the screen's height a reserving bar holds before any keyboard
  /// has settled in that orientation.
  final double estimateFraction;

  double _height = 0.0;
  HarborKeyboardPhase _phase = HarborKeyboardPhase.hidden;
  final Map<Orientation, double> _highWater = <Orientation, double>{};

  /// Counts changes to [_highWater], so a scope can tell a new settled height from a moving keyboard.
  int _marks = 0;
  Size _size = Size.zero;
  int _observation = 0;
  bool _disposed = false;

  double get height => _height;
  HarborKeyboardPhase get phase => _phase;

  double highWaterFor(final Size size) => _highWater[_orientationOf(size)] ?? (size.height * estimateFraction);

  bool highWaterIsEstimateFor(final Size size) => !_highWater.containsKey(_orientationOf(size));

  /// Records the keyboard's [height] on a screen of [size]. Called from build,
  /// so listeners hear about it after the frame drawn.
  void observe(final double height, final Size size) {
    if (height == _height && size == _size) {
      return;
    }
    final double previous = _height;
    _height = height;
    _size = size;
    if (height != previous) {
      _phase = height > previous ? HarborKeyboardPhase.opening : HarborKeyboardPhase.closing;
    }
    final int observation = ++_observation;
    // Settled once a whole drawn frame passes with no new height.
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      if (_disposed) {
        return;
      }
      notifyListeners();
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
        if (_disposed || observation != _observation) {
          return;
        }
        _settle();
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    });
  }

  void _settle() {
    final HarborKeyboardPhase settled = _height > 0.0 ? HarborKeyboardPhase.shown : HarborKeyboardPhase.hidden;
    final bool phaseChanged = settled != _phase;
    _phase = settled;
    bool markChanged = false;
    if (_height > 0.0) {
      final Orientation orientation = _orientationOf(_size);
      if (_highWater[orientation] != _height) {
        _highWater[orientation] = _height;
        _marks++;
        markChanged = true;
      }
    }
    if (phaseChanged || markChanged) {
      notifyListeners();
    }
  }

  static Orientation _orientationOf(final Size size) =>
      size.width > size.height ? Orientation.landscape : Orientation.portrait;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The part of the keyboard a reader depends on, so it is not rebuilt for the rest.
enum _HarborTideAspect {
  /// Whether the keyboard is shown: changes when the keyboard comes or goes.
  isShown,

  /// The settled heights: change when the keyboard settles at a new height.
  settledHeight,
}

/// Carries the [HarborTideGauge] down from the outermost frame.
class HarborTideScope extends InheritedNotifier<HarborTideGauge> {
  const HarborTideScope({super.key, required HarborTideGauge gauge, required super.child}) : super(notifier: gauge);

  static HarborTideGauge? maybeGaugeOf(final BuildContext context, {final bool listen = true}) => listen
      ? context.dependOnInheritedWidgetOfExactType<HarborTideScope>()?.notifier
      : context.getInheritedWidgetOfExactType<HarborTideScope>()?.notifier;

  static HarborTideGauge? _gaugeOf(final BuildContext context, final _HarborTideAspect aspect) =>
      context.dependOnInheritedWidgetOfExactType<HarborTideScope>(aspect: aspect)?.notifier;

  @override
  InheritedElement createElement() => _HarborTideScopeElement(this);
}

/// What a keyboard gauge's readers were told, aspect by aspect.
typedef _TideReading = ({bool isShown, int marks});

_TideReading? _readingOf(final HarborTideGauge? gauge) =>
    gauge == null ? null : (isShown: gauge.height > 0.0, marks: gauge._marks);

/// Hears the gauge as `InheritedNotifier` does, but tells a reader that
/// depends on one aspect only when that aspect changed. The gauge notifies on
/// every drawn frame the keyboard moves, and most readers care only whether it is shown.
class _HarborTideScopeElement extends InheritedElement {
  _HarborTideScopeElement(final HarborTideScope widget) : _told = _readingOf(widget.notifier), super(widget) {
    widget.notifier?.addListener(_gaugeChanged);
  }

  bool _dirty = false;
  _TideReading? _told;
  _TideReading? _now;

  HarborTideGauge? get _gauge => (widget as HarborTideScope).notifier;

  void _gaugeChanged() {
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void update(final HarborTideScope newWidget) {
    final HarborTideGauge? oldGauge = _gauge;
    if (oldGauge != newWidget.notifier) {
      oldGauge?.removeListener(_gaugeChanged);
      newWidget.notifier?.addListener(_gaugeChanged);
    }
    super.update(newWidget);
  }

  @override
  Widget build() {
    if (_dirty) {
      notifyClients(widget as HarborTideScope);
    }
    return super.build();
  }

  // As `InheritedModelElement` keeps them: an empty set depends on everything.
  @override
  void updateDependencies(final Element dependent, final Object? aspect) {
    final Set<_HarborTideAspect>? dependencies = getDependencies(dependent) as Set<_HarborTideAspect>?;
    if (dependencies != null && dependencies.isEmpty) {
      return;
    }
    if (aspect == null) {
      setDependencies(dependent, HashSet<_HarborTideAspect>());
    } else {
      setDependencies(dependent, (dependencies ?? HashSet<_HarborTideAspect>())..add(aspect as _HarborTideAspect));
    }
  }

  @override
  void notifyClients(final HarborTideScope oldWidget) {
    _now = _readingOf(_gauge);
    super.notifyClients(oldWidget);
    _told = _now;
    _dirty = false;
  }

  @override
  void notifyDependent(final HarborTideScope oldWidget, final Element dependent) {
    final Set<_HarborTideAspect>? dependencies = getDependencies(dependent) as Set<_HarborTideAspect>?;
    if (dependencies == null) {
      return;
    }
    final bool changed =
        dependencies.isEmpty ||
        !identical(oldWidget.notifier, _gauge) ||
        dependencies.any(
          (final _HarborTideAspect aspect) => switch (aspect) {
            _HarborTideAspect.isShown => _told?.isShown != _now?.isShown,
            _HarborTideAspect.settledHeight => _told?.marks != _now?.marks,
          },
        );
    if (changed) {
      dependent.didChangeDependencies();
    }
  }

  @override
  void unmount() {
    _gauge?.removeListener(_gaugeChanged);
    super.unmount();
  }
}

/// Reads the keyboard, as the frame sees it.
///
/// See also:
///
///  * [MediaQueryData.viewInsets], where the keyboard stays: harbor never moves it into `padding`.
abstract final class HarborKeyboard {
  /// The keyboard at [context]: its full height, how much of it still reaches this
  /// area, its settled height and its phase.
  static HarborKeyboardState of(final BuildContext context) {
    final double remaining = MediaQuery.viewInsetsOf(context).bottom;
    final HarborTideGauge? gauge = HarborTideScope.maybeGaugeOf(context);
    final Size size = MediaQuery.sizeOf(context);
    if (gauge == null) {
      return HarborKeyboardState(
        height: remaining,
        remaining: remaining,
        settledHeight: size.height * 0.4,
        settledHeightIsEstimate: true,
        phase: remaining > 0.0 ? HarborKeyboardPhase.shown : HarborKeyboardPhase.hidden,
      );
    }
    return HarborKeyboardState(
      height: gauge.height < remaining ? remaining : gauge.height,
      remaining: remaining,
      settledHeight: gauge.highWaterFor(size),
      settledHeightIsEstimate: gauge.highWaterIsEstimateFor(size),
      phase: gauge.phase,
    );
  }

  /// Whether the keyboard is shown, rebuilding the caller only when that flips.
  static bool isShownOf(final BuildContext context) =>
      (HarborTideScope._gaugeOf(context, _HarborTideAspect.isShown)?.height ??
          MediaQuery.viewInsetsOf(context).bottom) >
      0.0;

  /// The old name of [isShownOf].
  @Deprecated('Renamed isShownOf. `dart fix` applies it.')
  static bool isInOf(final BuildContext context) => isShownOf(context);

  /// The keyboard's settled height at [context], rebuilding the caller only when
  /// a new height settles or the screen turns.
  static double _highWaterOf(final BuildContext context) {
    final HarborTideGauge? gauge = HarborTideScope._gaugeOf(context, _HarborTideAspect.settledHeight);
    final Size size = MediaQuery.sizeOf(context);
    return gauge == null ? size.height * 0.4 : gauge.highWaterFor(size);
  }
}

/// The space a bar that [HarborKeyboardStance.reserves] keeps: a box exactly as tall as the
/// keyboard's settled height. While the keyboard is hidden it shows [child] (a panel that takes the
/// keyboard's place); while it is shown the keyboard covers it. Neither moves when they trade.
///
/// Flutter has no equivalent: nothing in the SDK reserves the keyboard's height while it is down.
class HarborKeyboardSpace extends StatelessWidget {
  const HarborKeyboardSpace({
    super.key,
    this.child,
    final bool showsChildWithKeyboard = false,
    @Deprecated('Renamed showsChildWithKeyboard. `dart fix` applies it.') final bool? showsChildAtHighTide,
  }) : assert(
         showsChildAtHighTide == null || !showsChildWithKeyboard || showsChildAtHighTide == showsChildWithKeyboard,
         'showsChildWithKeyboard and the deprecated showsChildAtHighTide disagree. Give showsChildWithKeyboard alone.',
       ),
       showsChildWithKeyboard = showsChildAtHighTide ?? showsChildWithKeyboard;

  /// What fills the space while the keyboard is hidden.
  final Widget? child;

  /// Whether [child] stays visible under a keyboard that does not cover it,
  /// such as a floating one.
  final bool showsChildWithKeyboard;

  /// The old name of [showsChildWithKeyboard].
  @Deprecated('Renamed showsChildWithKeyboard. `dart fix` applies it.')
  bool get showsChildAtHighTide => showsChildWithKeyboard;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('showsChildWithKeyboard', value: showsChildWithKeyboard, ifTrue: 'shows child with keyboard'),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // Not `HarborKeyboard.of`, which rebuilds on every drawn frame the keyboard moves.
    final bool isShown = HarborKeyboard.isShownOf(context) || MediaQuery.viewInsetsOf(context).bottom > 0.0;
    final bool show = showsChildWithKeyboard || !isShown;
    return SizedBox(
      height: HarborKeyboard._highWaterOf(context),
      width: double.infinity,
      child: Visibility(visible: show, maintainState: true, child: child ?? const SizedBox.shrink()),
    );
  }
}

/// Feeds a keyboard height the platform does not report into harbor: a
/// keyboard drawn by a plugin or a platform view, a TV's on-screen keyboard
/// reported over a channel, or a panel of your own that should push content
/// up as a keyboard does.
///
/// harbor reads the keyboard from `MediaQuery.viewInsets.bottom` alone, as
/// `Scaffold` and `EditableText` do, so this rebuilds the `MediaQuery` below it
/// with that inset raised to [height] while [height] is the larger. Every
/// frame, keyboard reader and Flutter widget below then sees the same keyboard. It
/// rebuilds only its `MediaQuery` when [height] changes, not [child].
///
/// Mount it above the `HarborRoot` (in `MaterialApp.builder`, around the root):
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => HarborKeyboardSource(
///     height: imeHeight, // a ValueNotifier<double> your channel sets
///     child: HarborRoot(child: child!),
///   ),
/// );
/// ```
///
/// Things to know:
///
///  * [height] is in **logical pixels**. A platform channel usually reports
///    physical pixels: divide by `MediaQuery.devicePixelRatioOf(context)` first.
///  * The inset is the **larger** of the platform's and [height], never their
///    sum, so a keyboard the platform does report is not counted twice.
///  * A **floating** keyboard (an iPad's, a split one) covers no edge: leave
///    [height] at zero for it, as the platform reports no inset for one.
///  * Above a `HarborScaledScreen`, the height is re-based into the scaled screen's
///    coordinates with the rest of the insets. Below one it would be read as
///    the scaled screen's coordinates, so mount it above.
///
/// See also:
///
///  * `MediaQueryData.viewInsets`, which this rewrites.
class HarborKeyboardSource extends StatelessWidget {
  const HarborKeyboardSource({super.key, required this.height, required this.child});

  /// The keyboard's height from the source, in logical pixels. Zero, a
  /// negative value or a non-finite one adds nothing.
  final ValueListenable<double> height;

  final Widget child;

  @override
  Widget build(final BuildContext context) => ValueListenableBuilder<double>(
    valueListenable: height,
    builder: (final BuildContext context, final double value, final Widget? child) {
      final MediaQueryData data = MediaQuery.of(context);
      final double source = value.isFinite && value > 0.0 ? value : 0.0;
      return MediaQuery(
        data: source > data.viewInsets.bottom
            ? data.copyWith(viewInsets: data.viewInsets.copyWith(bottom: source))
            : data,
        child: child!,
      );
    },
    child: child,
  );

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ValueListenable<double>>('height', height));
  }
}
