import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'edge.dart';
import 'keyboard.dart';
import 'room.dart';

/// Reports how much of its child the bars and system edges on [edge] of the frame it is in cover:
/// 0 in the room, 1 entirely under them, called with each change. The hero title that hands off to
/// the header as it scrolls under it.
///
/// [HarborKeepVisible.coverageOf] reads the same once, from code.
///
/// See also:
///
///  * [HarborKeepVisible], which scrolls its child back clear of what covers it.
class HarborCoverageListener extends StatelessWidget {
  const HarborCoverageListener({super.key, this.edge = HarborEdge.top, required this.onCoverage, required this.child});

  /// The edge whose bars and system edges are measured: [HarborEdge.top] or [HarborEdge.bottom].
  final HarborEdge edge;

  /// Called with how much of [child] is covered, 0 to 1, whenever that changes.
  final ValueChanged<double> onCoverage;

  final Widget child;

  @override
  Widget build(final BuildContext context) => _KeepInSight(edge: edge, onObscured: onCoverage, child: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HarborEdge>('edge', edge, defaultValue: HarborEdge.top));
  }
}

/// Keeps its child scrolled clear of the bars and the keyboard that cover the edges of the frame
/// it is in.
///
/// It brings the whole child back into sight, [clearance] clear of the bars and the keyboard, once
/// the keyboard has opened or what covers the bottom has grown, and when focus moves into it: a
/// field and the button under it, reached by a tap or the keyboard's next action. A focused text
/// field reveals its own caret, as [EditableText] does; this reveals the whole widget, so what sits
/// under the field comes with it. With [onlyWhileFocused], only while focus is inside it, so a form
/// full of them reveals just the field being typed in.
///
/// [reveal] and [coverageOf] do the same from code.
///
/// See also:
///
///  * `TextField.scrollPadding`, the closest Flutter setting.
///  * [RenderObject.showOnScreen], which [reveal] calls, and [Scrollable.ensureVisible], its widget-level cousin.
///  * [HarborLift], for content that does not scroll.
class HarborKeepVisible extends StatelessWidget {
  const HarborKeepVisible({
    super.key,
    this.active = true,
    this.onlyWhileFocused = false,
    this.clearance = 0.0,
    required this.child,
  });

  /// Whether it keeps its child in sight. False leaves the child where it scrolls, without
  /// rebuilding it as a different widget, as [HarborHideBar.active] does for a claim.
  final bool active;

  /// Whether it keeps its child in sight only while focus is inside it.
  final bool onlyWhileFocused;

  /// How far clear of what covers it the child is kept.
  final double clearance;

  final Widget child;

  /// Brings the widget at [context] into sight, [clearance] clear of whatever
  /// covers the edges of the scroll views it is in (bars and keyboard
  /// included, when those scroll views are [HarborScrollView]s). With reduced motion
  /// ([MediaQueryData.disableAnimations]) it jumps there, whatever [duration] says.
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
    final bool still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    target.showOnScreen(rect: bounds, duration: still ? Duration.zero : duration, curve: curve);
  }

  /// How much of [box] (0 to 1) the bars and system edges on [edge] of [frame] cover, from its last
  /// layout.
  static double coverageOf(final RenderBox box, final HarborController frame, final HarborEdge edge) {
    final Rect? clear = frame.roomInGlobal();
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

  @override
  Widget build(final BuildContext context) =>
      _KeepInSight(keepInSight: active, onlyWhileFocused: onlyWhileFocused, clearance: clearance, child: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
    properties.add(FlagProperty('onlyWhileFocused', value: onlyWhileFocused, ifTrue: 'only while focused'));
    properties.add(DoubleProperty('clearance', clearance, defaultValue: 0.0));
  }
}

/// Lifts its child over what covers the bottom (a sheet, a page cover, the keyboard), for content
/// that does not scroll: the [HarborKeepVisibleRegion] around it moves its content up just far
/// enough that this widget is [clearance] clear, and settles back when the cover goes. Outside a
/// region it does nothing.
class HarborLift extends StatelessWidget {
  const HarborLift({
    super.key,
    this.active = true,
    this.clearance = 0.0,
    this.holdPosition = false,
    required this.child,
  });

  /// Whether it asks to be lifted. False lets the region settle back without rebuilding the child as
  /// a different widget: a boat that lifts only while it is selected.
  final bool active;

  /// How far clear of what covers the bottom the child is lifted.
  final double clearance;

  /// While true, the lift holds where it is (an element being dragged).
  final bool holdPosition;

  final Widget child;

  @override
  Widget build(final BuildContext context) =>
      _KeepInSight(lift: active, clearance: clearance, holdPosition: holdPosition, child: child);

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('active', value: active, ifFalse: 'inactive'));
    properties.add(DoubleProperty('clearance', clearance, defaultValue: 0.0));
    properties.add(FlagProperty('holdPosition', value: holdPosition, ifTrue: 'holding position'));
  }
}

/// What all three jobs share: one widget that can report its coverage, keep itself in sight and
/// lift, so the three public widgets behave alike.
class _KeepInSight extends StatefulWidget {
  const _KeepInSight({
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
  final bool keepInSight;
  final bool onlyWhileFocused;
  final bool lift;
  final double clearance;
  final bool holdPosition;
  final Widget child;

  @override
  State<_KeepInSight> createState() => _KeepInSightState();
}

class _KeepInSightState extends State<_KeepInSight> {
  ScrollPosition? _position;
  double _lastObscured = -1.0;
  double _lastKeyboardTop = -1.0;
  bool _checkPending = false;
  _KeepVisibleRegionState? _region;

  // Neither focusable nor traversable: it only tells the widget whether focus is inside it.
  final FocusNode _focus = FocusNode(debugLabel: 'HarborKeepInSight', canRequestFocus: false, skipTraversal: true);

  void _handleFocusChange(final bool hasFocus) {
    if (hasFocus && widget.keepInSight) {
      _scheduleReveal();
    }
  }

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
    final double bottom = HarborRoom.clearanceOf(context, HarborEdge.bottom) + HarborKeyboard.of(context).height;
    // The KEYBOARD'S TOP, not the covered height: reveal when the room above the bottom drops.
    // Watching the covered height alone missed a turn to landscape with the keyboard up, where that
    // number shrinks (336 to 200) while the room above it falls from 538 to 202, leaving the widget
    // under the keyboard.
    final double keyboardTop = MediaQuery.sizeOf(context).height - bottom;
    if (widget.keepInSight && _lastKeyboardTop >= 0 && keyboardTop < _lastKeyboardTop - 0.5) {
      _scheduleReveal();
    }
    _lastKeyboardTop = keyboardTop;
    final _KeepVisibleRegionState? region = _KeepVisibleRegionScope.maybeOf(context);
    if (!identical(region, _region)) {
      _region?._unregister(this);
      _region = region;
    }
    _region?._register(this);
    _scheduleCheck();
  }

  int _revealRequest = 0;

  /// Reveals once the bottom has stopped moving for one drawn frame, so a rising
  /// keyboard is followed once, to where it settles.
  void _scheduleReveal() {
    final int request = ++_revealRequest;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
        if (!mounted || request != _revealRequest) {
          return;
        }
        if (widget.onlyWhileFocused && !_focus.hasFocus) {
          return;
        }
        HarborKeepVisible.reveal(context, clearance: widget.clearance);
      });
      SchedulerBinding.instance.ensureVisualUpdate();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void didUpdateWidget(final _KeepInSight oldWidget) {
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
      final HarborController? frame = HarborController.maybeOf(context);
      if (box is! RenderBox || frame == null) {
        return;
      }
      final double obscured = HarborKeepVisible.coverageOf(box, frame, widget.edge);
      if ((obscured - _lastObscured).abs() > 0.001) {
        _lastObscured = obscured;
        widget.onObscured?.call(obscured);
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _focus.dispose();
    _position?.removeListener(_scheduleCheck);
    _region?._unregister(this);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) =>
      Focus(focusNode: _focus, includeSemantics: false, onFocusChange: _handleFocusChange, child: widget.child);
}

/// A region that can lift its content: when a [HarborLift] inside it would be covered by what covers the bottom (a sheet, a
/// page cover, the keyboard), the region moves its content up just far enough,
/// and back down when the cover goes. Content already clear stays where it is.
/// With reduced motion ([MediaQueryData.disableAnimations]) it moves at once.
class HarborKeepVisibleRegion extends StatefulWidget {
  const HarborKeepVisibleRegion({super.key, this.animationStyle, required this.child});

  /// How the content moves, as `AnimationStyle` sets it on Flutter's routes: its `duration` and
  /// `curve` are for lifting, and its `reverseDuration` and `reverseCurve` for settling back down;
  /// each reverse one falls back to the forward one. Left unset, the content moves over 280 ms along
  /// [Curves.easeOutCubic]. [AnimationStyle.noAnimation] moves it at once.
  final AnimationStyle? animationStyle;
  final Widget child;

  @override
  State<HarborKeepVisibleRegion> createState() => _KeepVisibleRegionState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AnimationStyle>('animationStyle', animationStyle, defaultValue: null));
  }
}

/// How a region's content moves where its `animationStyle` does not say.
const Duration _liftDuration = Duration(milliseconds: 280);
const Curve _liftCurve = Curves.easeOutCubic;

class _KeepVisibleRegionState extends State<HarborKeepVisibleRegion> with SingleTickerProviderStateMixin {
  final Set<_KeepInSightState> _keepers = <_KeepInSightState>{};
  late final AnimationController _lift = AnimationController(vsync: this, duration: _liftDuration);
  double _from = 0.0;
  double _to = 0.0;
  bool _pending = false;
  final GlobalKey _contentKey = GlobalKey();
  late Curve _moveCurve = _liftCurve;

  double get _offset => _from + (_to - _from) * _moveCurve.transform(_lift.value);

  void _register(final _KeepInSightState keeper) {
    _keepers.add(keeper);
    _schedule();
  }

  void _unregister(final _KeepInSightState keeper) {
    _keepers.remove(keeper);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depend on what covers the bottom, so a sheet or the keyboard rising re-checks.
    HarborRoom.clearanceOf(context, HarborEdge.bottom);
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
    final double cover = HarborRoom.clearanceOf(context, HarborEdge.bottom);
    double needed = 0.0;
    bool hold = false;
    for (final _KeepInSightState keeper in _keepers) {
      if (!keeper.widget.lift || !keeper.mounted) {
        continue;
      }
      hold = hold || keeper.widget.holdPosition;
      final RenderObject? box = keeper.context.findRenderObject();
      if (box is! RenderBox || !box.hasSize) {
        continue;
      }
      // Measured where it would be with no lift applied.
      final Rect rect = MatrixUtils.transformRect(box.getTransformTo(content), Offset.zero & box.size);
      final double visibleBottom = region.size.height - cover - keeper.widget.clearance;
      needed = math.max(needed, rect.bottom - visibleBottom);
    }
    if (hold) {
      return;
    }
    final double target = -math.max(0.0, needed);
    if ((target - _to).abs() < 0.5) {
      return;
    }
    final AnimationStyle? style = widget.animationStyle;
    final Duration liftDuration = style?.duration ?? _liftDuration;
    final Curve liftCurve = style?.curve ?? _liftCurve;
    final bool lifting = target < _offset;
    _from = _offset;
    _to = target;
    _moveCurve = lifting ? liftCurve : style?.reverseCurve ?? liftCurve;
    _lift
      ..duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : lifting
          ? liftDuration
          : style?.reverseDuration ?? liftDuration
      ..value = 0.0
      ..forward();
  }

  @override
  void dispose() {
    _lift.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => _KeepVisibleRegionScope(
    state: this,
    child: AnimatedBuilder(
      animation: _lift,
      builder: (final BuildContext context, final Widget? child) =>
          Transform.translate(offset: Offset(0.0, _offset), child: child),
      child: KeyedSubtree(key: _contentKey, child: widget.child),
    ),
  );
}

class _KeepVisibleRegionScope extends InheritedWidget {
  const _KeepVisibleRegionScope({required this.state, required super.child});

  final _KeepVisibleRegionState state;

  static _KeepVisibleRegionState? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KeepVisibleRegionScope>()?.state;

  @override
  bool updateShouldNotify(final _KeepVisibleRegionScope oldWidget) => false;
}
