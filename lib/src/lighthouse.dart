import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'edge.dart';
import 'tide.dart';
import 'waters.dart';

/// The lighthouse keeps things in sight.
///
/// See also:
///
///  * [Scrollable.ensureVisible] and [RenderObject.showOnScreen], which [reveal] calls.
abstract final class HarborLighthouse {
  /// Brings the widget at [context] into sight, [clearance] clear of whatever
  /// covers the edges of the scroll views it is in (docks and keyboard
  /// included, when those scroll views are fairways).
  static void reveal(
    final BuildContext context, {
    final double clearance = 0.0,
    final Duration duration = const Duration(milliseconds: 250),
    final Curve curve = Curves.easeOutCubic,
  }) {
    final RenderObject? target = context.findRenderObject();
    if (target == null || !target.attached) {
      return;
    }
    final Rect bounds = target.paintBounds.inflate(clearance);
    target.showOnScreen(rect: bounds, duration: duration, curve: curve);
  }

  /// How much of [box] (0 to 1) the docks and coast on [edge] of its nearest
  /// harbor cover, from the last layout.
  static double coverageOf(final RenderBox box, final HarborController harbor, final HarborEdge edge) {
    final Rect? clear = harbor.clearWaterInGlobal();
    if (clear == null || !box.attached || !box.hasSize || box.size.isEmpty) {
      return 0.0;
    }
    final Rect rect = MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);
    final double covered = switch (edge) {
      HarborEdge.top => clear.top - rect.top,
      HarborEdge.bottom => rect.bottom - clear.bottom,
      HarborEdge.start || HarborEdge.end => 0.0,
    };
    final double extent = edge.isVertical ? rect.height : rect.width;
    return (covered / extent).clamp(0.0, 1.0);
  }
}

/// A beacon: marks a widget the lighthouse watches.
///
/// With [onObscured], it reports how much of itself the docks on [edge] cover
/// (0 in clear water, 1 entirely under them) whenever that changes: the hero
/// title that hands off to the header as it scrolls under it.
///
/// With [keepInSight] set, it brings itself back into sight, [clearance] clear
/// of the docks and the keyboard, once the keyboard has risen or what covers
/// the bottom has grown: a field and the button under it. With
/// [onlyWhileFocused], only while focus is inside it, so a form full of
/// beacons reveals just the field being typed in. Inside a [HarborLighthouseRegion] it can [lift] instead:
/// the region moves its content up until the beacon clears what covers it, and
/// settles back when that goes away.
///
/// See also:
///
///  * `TextField.scrollPadding`, the closest Flutter setting to [keepInSight]. [onObscured] and [lift]
///    have no Flutter equivalent.
class HarborBeacon extends StatefulWidget {
  const HarborBeacon({
    super.key,
    this.edge = HarborEdge.top,
    this.onObscured,
    this.keepInSight = false,
    this.onlyWhileFocused = false,
    this.lift = false,
    this.clearance = 0.0,
    this.holdPosition = false,
    required this.child,
  });

  final HarborEdge edge;
  final ValueChanged<double>? onObscured;

  /// Whether to scroll this widget back into sight when what covers the bottom grows.
  final bool keepInSight;

  /// Whether [keepInSight] applies only while focus is inside this beacon.
  final bool onlyWhileFocused;

  /// Whether the enclosing [HarborLighthouseRegion] should lift its content to
  /// keep this widget clear of what covers the bottom.
  final bool lift;

  /// How far clear of what covers it this widget is kept.
  final double clearance;

  /// While true, a lift holds where it is (an element being dragged).
  final bool holdPosition;

  final Widget child;

  @override
  State<HarborBeacon> createState() => _HarborBeaconState();
}

class _HarborBeaconState extends State<HarborBeacon> {
  ScrollPosition? _position;
  double _lastObscured = -1.0;
  double _lastWaterline = -1.0;
  bool _checkPending = false;
  _LighthouseRegionState? _region;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_scheduleCheck);
      _position = position;
      _position?.addListener(_scheduleCheck);
    }
    // Either the keyboard covers this area (the body runs under it), or the
    // body shrank to end at it; watch both.
    final double bottom = HarborWaters.clearanceOf(context, HarborEdge.bottom) + HarborTide.of(context).height;
    // The WATERLINE, not the covered height: reveal when the water above the bottom drops. Watching
    // the covered height alone missed a turn to landscape with the keyboard up, where that number
    // shrinks (336 to 200) while the water above it falls from 538 to 202, leaving the beacon
    // under the keyboard.
    final double waterline = MediaQuery.sizeOf(context).height - bottom;
    if (widget.keepInSight && _lastWaterline >= 0 && waterline < _lastWaterline - 0.5) {
      _scheduleReveal();
    }
    _lastWaterline = waterline;
    final _LighthouseRegionState? region = _LighthouseRegionScope.maybeOf(context);
    if (!identical(region, _region)) {
      _region?._unregister(this);
      _region = region;
    }
    _region?._register(this);
    _scheduleCheck();
  }

  int _revealRequest = 0;

  /// Reveals once the bottom has stopped moving for a frame, so a rising
  /// keyboard is followed once, to where it settles.
  void _scheduleReveal() {
    final int request = ++_revealRequest;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
        if (!mounted || request != _revealRequest) {
          return;
        }
        if (widget.onlyWhileFocused && !_hasFocusInside()) {
          return;
        }
        HarborLighthouse.reveal(context, clearance: widget.clearance);
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  bool _hasFocusInside() {
    final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
    if (focused == null) {
      return false;
    }
    bool inside = identical(focused, context);
    if (!inside) {
      focused.visitAncestorElements((final Element ancestor) {
        if (identical(ancestor, context)) {
          inside = true;
          return false;
        }
        return true;
      });
    }
    return inside;
  }

  @override
  void didUpdateWidget(final HarborBeacon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _region?._register(this);
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_checkPending || widget.onObscured == null) {
      return;
    }
    _checkPending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _checkPending = false;
      if (!mounted) {
        return;
      }
      final RenderObject? box = context.findRenderObject();
      final HarborController? harbor = HarborController.maybeOf(context);
      if (box is! RenderBox || harbor == null) {
        return;
      }
      final double obscured = HarborLighthouse.coverageOf(box, harbor, widget.edge);
      if ((obscured - _lastObscured).abs() > 0.001) {
        _lastObscured = obscured;
        widget.onObscured?.call(obscured);
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _region?._unregister(this);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

/// A region the lighthouse can lift: when a [HarborBeacon] inside it with
/// `lift` set would be covered by what covers the bottom (a sheet, a
/// breakwater, the keyboard), the region moves its content up just far enough,
/// and back down when the cover goes. Content already clear stays where it is.
class HarborLighthouseRegion extends StatefulWidget {
  const HarborLighthouseRegion({
    super.key,
    this.duration = const Duration(milliseconds: 280),
    this.curve = Curves.easeOutCubic,
    required this.child,
  });

  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  State<HarborLighthouseRegion> createState() => _LighthouseRegionState();
}

class _LighthouseRegionState extends State<HarborLighthouseRegion> with SingleTickerProviderStateMixin {
  final Set<_HarborBeaconState> _beacons = <_HarborBeaconState>{};
  late final AnimationController _lift = AnimationController(vsync: this, duration: widget.duration);
  double _from = 0.0;
  double _to = 0.0;
  bool _pending = false;
  final GlobalKey _contentKey = GlobalKey();

  double get _offset => _from + (_to - _from) * widget.curve.transform(_lift.value);

  void _register(final _HarborBeaconState beacon) {
    _beacons.add(beacon);
    _schedule();
  }

  void _unregister(final _HarborBeaconState beacon) {
    _beacons.remove(beacon);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depend on what covers the bottom, so a sheet or the keyboard rising re-checks.
    HarborWaters.clearanceOf(context, HarborEdge.bottom);
    _schedule();
  }

  void _schedule() {
    if (_pending) {
      return;
    }
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _pending = false;
      if (mounted) {
        _measure();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _measure() {
    final RenderObject? region = context.findRenderObject();
    final RenderObject? content = _contentKey.currentContext?.findRenderObject();
    if (region is! RenderBox || content is! RenderBox || !region.hasSize) {
      return;
    }
    final double cover = HarborWaters.clearanceOf(context, HarborEdge.bottom);
    double needed = 0.0;
    bool hold = false;
    for (final _HarborBeaconState beacon in _beacons) {
      if (!beacon.widget.lift || !beacon.mounted) {
        continue;
      }
      hold = hold || beacon.widget.holdPosition;
      final RenderObject? box = beacon.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        continue;
      }
      // Measured where it would be with no lift applied.
      final Rect rect = MatrixUtils.transformRect(box.getTransformTo(content), Offset.zero & box.size);
      final double visibleBottom = region.size.height - cover - beacon.widget.clearance;
      needed = math.max(needed, rect.bottom - visibleBottom);
    }
    if (hold) {
      return;
    }
    final double target = -math.max(0.0, needed);
    if ((target - _to).abs() < 0.5) {
      return;
    }
    _from = _offset;
    _to = target;
    _lift
      ..value = 0.0
      ..forward();
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => _LighthouseRegionScope(
    state: this,
    child: AnimatedBuilder(
      animation: _lift,
      builder: (final BuildContext context, final Widget? child) =>
          Transform.translate(offset: Offset(0.0, _offset), child: child),
      child: KeyedSubtree(key: _contentKey, child: widget.child),
    ),
  );
}

class _LighthouseRegionScope extends InheritedWidget {
  const _LighthouseRegionScope({required this.state, required super.child});

  final _LighthouseRegionState state;

  static _LighthouseRegionState? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<_LighthouseRegionScope>()?.state;

  @override
  bool updateShouldNotify(final _LighthouseRegionScope oldWidget) => false;
}
