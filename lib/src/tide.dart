import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// How a dock behaves when the tide (the keyboard) comes in.
enum HarborTideStance {
  /// Rides up on the keyboard, staying on top of it (a composer).
  ///
  /// The dock floats: it rides up with the tide and sits on the waterline.
  float,

  /// Stays put; the keyboard covers it (a tab bar).
  ///
  /// The dock stands on pilings: it stays where it is and the tide covers it.
  pilings,

  /// Keeps the keyboard's space whether the keyboard is up or down, so nothing moves (a styling panel).
  ///
  /// The dock is a dry dock: it keeps the tide's ground at high-water height
  /// whether the tide is in or out, so nothing moves when the keyboard comes
  /// and goes. Its child holds a [HarborDryDock] that fills that ground at low
  /// tide.
  dryDock,
}

/// Where the tide is in its cycle.
enum HarborTidePhase { low, rising, high, falling }

/// The tide as a harbor sees it.
///
/// Despite its name, this is not a [State]: it is an immutable snapshot, as [MediaQueryData] is.
@immutable
class HarborTideState {
  const HarborTideState({
    required this.height,
    required this.remaining,
    required this.highWater,
    required this.highWaterIsEstimate,
    required this.phase,
  });

  /// How far the keyboard reaches up from the bottom of the screen, before any
  /// harbor moved out of its way. For information, never for layout.
  final double height;

  /// How far the keyboard still reaches into this area, after the layers above
  /// kept clear of it. What layout uses.
  final double remaining;

  /// The last settled height of the keyboard in this orientation: what a dry
  /// dock reserves. Falls as well as rises when the keyboard settles lower.
  final double highWater;

  /// Whether [highWater] is a guess because no keyboard has settled here yet.
  final bool highWaterIsEstimate;

  final HarborTidePhase phase;

  bool get isIn => height > 0.0;

  bool get isSettled => phase == HarborTidePhase.low || phase == HarborTidePhase.high;

  /// How much of the keyboard the harbors above this point already kept clear of.
  double get avoidedAbove => height - remaining;

  @override
  bool operator ==(final Object other) =>
      other is HarborTideState &&
      other.height == height &&
      other.remaining == remaining &&
      other.highWater == highWater &&
      other.highWaterIsEstimate == highWaterIsEstimate &&
      other.phase == phase;

  @override
  int get hashCode => Object.hash(height, remaining, highWater, highWaterIsEstimate, phase);

  @override
  String toString() => 'HarborTideState(height: $height, remaining: $remaining, highWater: $highWater, phase: $phase)';
}

/// Keeps the tide's cycle and its high-water marks for one view. Owned by the
/// outermost harbor ([HarborSea], or the first [Harbor]).
class HarborTideGauge extends ChangeNotifier {
  HarborTideGauge({this.estimateFraction = 0.4});

  /// The share of the screen's height a dry dock reserves before any keyboard
  /// has settled in that orientation.
  final double estimateFraction;

  double _height = 0.0;
  HarborTidePhase _phase = HarborTidePhase.low;
  final Map<Orientation, double> _highWater = <Orientation, double>{};

  /// Counts changes to [_highWater], so a scope can tell a new mark from a moving tide.
  int _marks = 0;
  Size _size = Size.zero;
  int _observation = 0;
  bool _disposed = false;

  double get height => _height;
  HarborTidePhase get phase => _phase;

  double highWaterFor(final Size size) =>
      _highWater[_orientationOf(size)] ?? (size.height * estimateFraction);

  bool highWaterIsEstimateFor(final Size size) => !_highWater.containsKey(_orientationOf(size));

  /// Records the keyboard's [height] on a screen of [size]. Called from build,
  /// so listeners hear about it after the frame.
  void observe(final double height, final Size size) {
    if (height == _height && size == _size) {
      return;
    }
    final double previous = _height;
    _height = height;
    _size = size;
    if (height != previous) {
      _phase = height > previous ? HarborTidePhase.rising : HarborTidePhase.falling;
    }
    final int observation = ++_observation;
    // Settled once a whole frame passes with no new height.
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
    final HarborTidePhase settled = _height > 0.0 ? HarborTidePhase.high : HarborTidePhase.low;
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

/// The part of the tide a reader depends on, so it is not rebuilt for the rest.
enum _HarborTideAspect {
  /// Whether the tide is in: changes when the keyboard comes or goes.
  isIn,

  /// The high-water marks: change when the keyboard settles at a new height.
  highWater,
}

/// Carries the [HarborTideGauge] down from the outermost harbor.
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

/// What a tide gauge's readers were told, aspect by aspect.
typedef _TideReading = ({bool isIn, int marks});

_TideReading? _readingOf(final HarborTideGauge? gauge) =>
    gauge == null ? null : (isIn: gauge.height > 0.0, marks: gauge._marks);

/// Hears the gauge as `InheritedNotifier` does, but tells a reader that
/// depends on one aspect only when that aspect changed. The gauge notifies on
/// every frame the keyboard moves, and most readers care only whether it is in.
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
            _HarborTideAspect.isIn => _told?.isIn != _now?.isIn,
            _HarborTideAspect.highWater => _told?.marks != _now?.marks,
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

/// Reads the tide: the keyboard, as the harbor sees it.
///
/// See also:
///
///  * [MediaQueryData.viewInsets], where the keyboard stays: harbor never moves it into `padding`.
abstract final class HarborTide {
  /// The tide at [context]: its full height, how much of it still reaches this
  /// area, its high-water mark and its phase.
  static HarborTideState of(final BuildContext context) {
    final double remaining = MediaQuery.viewInsetsOf(context).bottom;
    final HarborTideGauge? gauge = HarborTideScope.maybeGaugeOf(context);
    final Size size = MediaQuery.sizeOf(context);
    if (gauge == null) {
      return HarborTideState(
        height: remaining,
        remaining: remaining,
        highWater: size.height * 0.4,
        highWaterIsEstimate: true,
        phase: remaining > 0.0 ? HarborTidePhase.high : HarborTidePhase.low,
      );
    }
    return HarborTideState(
      height: gauge.height < remaining ? remaining : gauge.height,
      remaining: remaining,
      highWater: gauge.highWaterFor(size),
      highWaterIsEstimate: gauge.highWaterIsEstimateFor(size),
      phase: gauge.phase,
    );
  }

  /// Whether the tide is in, rebuilding the caller only when that flips.
  static bool isInOf(final BuildContext context) =>
      (HarborTideScope._gaugeOf(context, _HarborTideAspect.isIn)?.height ?? MediaQuery.viewInsetsOf(context).bottom) > 0.0;

  /// The tide's high-water mark at [context], rebuilding the caller only when
  /// a new mark is set or the screen turns.
  static double _highWaterOf(final BuildContext context) {
    final HarborTideGauge? gauge = HarborTideScope._gaugeOf(context, _HarborTideAspect.highWater);
    final Size size = MediaQuery.sizeOf(context);
    return gauge == null ? size.height * 0.4 : gauge.highWaterFor(size);
  }
}

/// The ground a dry dock keeps: a box exactly as tall as the tide's high-water
/// mark. At low tide it shows [child] (a panel that takes the keyboard's
/// place); at high tide the keyboard covers it. Neither moves when they trade.
///
/// Flutter has no equivalent: nothing in the SDK reserves the keyboard's height while it is down.
class HarborDryDock extends StatelessWidget {
  const HarborDryDock({super.key, this.child, this.showsChildAtHighTide = false});

  /// What fills the dry dock while the tide is out.
  final Widget? child;

  /// Whether [child] stays visible under a keyboard that does not cover it,
  /// such as a floating one.
  final bool showsChildAtHighTide;

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('showsChildAtHighTide', value: showsChildAtHighTide, ifTrue: 'shows child at high tide'),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // Not `HarborTide.of`, which rebuilds on every frame the keyboard moves.
    final bool isIn = HarborTide.isInOf(context) || MediaQuery.viewInsetsOf(context).bottom > 0.0;
    final bool show = showsChildAtHighTide || !isIn;
    return SizedBox(
      height: HarborTide._highWaterOf(context),
      width: double.infinity,
      child: Visibility(visible: show, maintainState: true, child: child ?? const SizedBox.shrink()),
    );
  }
}
