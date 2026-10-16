import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'edge.dart';
import 'float.dart' show HarborAnchor, HarborAnchorClip, HarborToastScope;
import 'hinge.dart';
import 'keyboard.dart';
import 'placement.dart';

/// A request that a bar hide, returned by [HarborController.hideBar].
/// Release it when the content no longer needs the edge.
class HarborClaim {
  HarborClaim._(this._controller, this.edge, this.state);

  HarborController? _controller;
  final HarborEdge edge;

  /// How the bar hides: [HarborBarState.dark] or [HarborBarState.withdrawn].
  final HarborBarState state;

  bool get isActive => _controller != null;

  void release() {
    final HarborController? controller = _controller;
    _controller = null;
    controller?._releaseClaim(this);
  }
}

/// A page cover: a sheet (or any overlay) reporting how far it covers the
/// bottom of the frame that opened it, so that frame's content keeps clear
/// of it while it is up.
///
/// Flutter has no equivalent: a `Scaffold` lifts its floating action button over a bottom sheet but
/// leaves the body under it.
class HarborPageCover {
  HarborPageCover._(this._controller, this._coverage, {this._measuresTop = false});

  HarborController? _controller;
  final ValueListenable<double> _coverage;
  final bool _measuresTop;

  double get _reach => _controller == null || _measuresTop ? 0.0 : _coverage.value;

  double? get _top => _controller == null || !_measuresTop ? null : _coverage.value;

  /// Takes the cover away: call it when the cover leaves.
  void remove() {
    final HarborController? controller = _controller;
    _controller = null;
    controller?._removePageCover(this);
  }
}

/// Builds a toast's entrance and exit around [child] from [animation], which
/// runs from 0 to 1 as the toast is shown and back as it is hidden.
typedef HarborToastTransitionBuilder = Widget Function(BuildContext context, Animation<double> animation, Widget child);

/// Why a toast was closed, as [HarborToastEntry.closed] reports it.
enum HarborToastClosedReason {
  /// [HarborToastEntry.hide] was called.
  hide,

  /// The user dismissed it: [HarborToastEntry.dismiss] was called, or a screen reader's dismiss
  /// action hid it.
  dismiss,

  /// Its [HarborToastEntry.duration] ran out.
  timeout,

  /// Nothing was left to show it: its frame or overlay went away with no other to move to.
  remove,

  /// A toast shown with [HarborToastQueue.replace] at its place took its turn.
  replaced,
}

/// Where a toast is in its life, read synchronously with [HarborToastEntry.phase].
enum HarborToastPhase {
  /// Shown, and waiting its turn or for the frame to build it.
  waiting,

  /// Built and on screen, entrance included.
  shown,

  /// Gone: hidden and left, or hidden before it ever showed.
  closed,
}

/// What a toast does when one is already up at its slot, alignment or anchor.
enum HarborToastQueue {
  /// Waits its turn, as a `ScaffoldMessenger`'s snack bars do: it comes in once the one up has
  /// left. The default.
  wait,

  /// Takes the turn at once: it goes to the front, and the toast up is hidden with
  /// [HarborToastClosedReason.replaced] and leaves at once, so the new one shows in its place. For an Undo whose window is
  /// tied to a pending action, or quick toggles on a remote-driven screen that read better
  /// replaced than late.
  replace,
}

/// How long a toast stays up, and what counts toward that time: `HarborToasts.show(timing:)`.
///
/// ```dart
/// HarborToasts.show(context, builder: (_) => const Toast('Saved'));                       // 4 s in sight
/// HarborToasts.show(context, timing: HarborToastTiming.untilHidden, builder: undoToast); // until hidden
/// HarborToasts.show(
///   context,
///   timing: const HarborToastTiming(countsWhileCovered: true), // gone when the user comes back
///   builder: (_) => const Toast('Saved'),
/// );
/// ```
@immutable
final class HarborToastTiming with Diagnosticable {
  /// A toast that stays [duration] in sight, counted from the end of its entrance unless
  /// [countsEntrance], and not while another route covers its page unless [countsWhileCovered].
  const HarborToastTiming({
    this.duration = defaultDuration,
    this.countsEntrance = false,
    this.countsWhileCovered = false,
  });

  /// How long a toast stays by default: 4 s, a `SnackBar`'s.
  static const Duration defaultDuration = Duration(seconds: 4);

  /// Stays until it is hidden, as `SnackBar(persist: true)` does: for a toast with a button (an
  /// Undo), so a screen-reader user has time to reach it.
  static const HarborToastTiming untilHidden = HarborToastTiming(duration: null);

  /// How long the toast stays in sight; null stays until it is hidden. Counted again from the
  /// start each time it comes back into sight, or a [HarborToastEntry.hold] is released.
  final Duration? duration;

  /// Whether [duration] counts from the start of the toast's entrance rather than its end, so a
  /// 4 s toast is on screen 4 s, entrance included. With reduced motion there is no entrance, and
  /// the two are the same.
  final bool countsEntrance;

  /// Whether the toast's time keeps running while another route covers its page, so a toast
  /// confirming an action goes on schedule even if a page is pushed over it. A hold still stops it.
  /// Its time starts once its entrance has run, which it cannot while its page is covered.
  final bool countsWhileCovered;

  @override
  bool operator ==(final Object other) =>
      other is HarborToastTiming &&
      other.duration == duration &&
      other.countsEntrance == countsEntrance &&
      other.countsWhileCovered == countsWhileCovered;

  @override
  int get hashCode => Object.hash(duration, countsEntrance, countsWhileCovered);

  @override
  String toStringShort() => objectRuntimeType(this, 'HarborToastTiming');

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('duration', duration, ifNull: 'until hidden', defaultValue: defaultDuration))
      ..add(FlagProperty('countsEntrance', value: countsEntrance, ifTrue: 'counts entrance'))
      ..add(FlagProperty('countsWhileCovered', value: countsWhileCovered, ifTrue: 'counts while covered'));
  }
}

/// A shown toast, returned by `HarborToasts.show`: what a caller may do with it.
///
/// Inside the toast's builder or transition, [maybeOf] finds it.
///
/// Toasts shown at the same alignment in one frame take turns, as a
/// `ScaffoldMessenger` shows its snack bars: each is shown once the one before
/// it has been hidden and has run its exit. Toasts shown by an [anchor] take
/// turns per anchor and [side].
///
/// harbor makes every entry, so a test fake cannot implement this class; show a toast and read the
/// entry it returns instead.
abstract final class HarborToastEntry {
  HarborToastEntry._({required this.placement, required this._duration});

  /// The toast whose builder or transition [context] is in, or null outside one: for a toast
  /// that takes a [hold] on itself, or a transition that reads its [anchor] and [side].
  static HarborToastEntry? maybeOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborToastScope>()?.entry;

  /// Where the toast sits: at a point of the room, or by an anchor. Its directional
  /// values are resolved in the reading direction of the page that showed it. A slot is a
  /// [HarborAligned] at the slot's point.
  final HarborPlacement placement;

  /// What an anchored toast sits by; null for one at a slot or an alignment. With [side], what a
  /// transition reads to clip at the anchor ([HarborAnchorClip]).
  HarborAnchor? get anchor => switch (placement) {
    HarborAnchored(:final HarborAnchor? anchor) => anchor,
    HarborAligned() => null,
  };

  /// Which side of its [anchor] the toast sits on; an anchored toast never flips, so this is the
  /// side it hangs on. [HarborAnchorSide.below], the anchored default, for a toast with no anchor.
  HarborAnchorSide get side => switch (placement) {
    HarborAnchored(:final HarborAnchorSide side) => side,
    HarborAligned() => HarborAnchorSide.below,
  };

  /// How long the toast stays once it is in sight: from the end of its
  /// entrance (or its start, with [HarborToastTiming.countsEntrance]), while no other route
  /// covers its frame. Counted again from the start each time it comes back
  /// into sight. Null never times out: it stays until it is hidden.
  ///
  /// Setting it starts the time over with the new duration, as coming back
  /// into sight or releasing a [hold] does: give a toast longer once a screen
  /// reader turns on, or less once it turns off. Null stops it timing out.
  Duration? get duration => _duration;
  Duration? _duration;
  set duration(final Duration? value) {
    _duration = value;
    _restarts.value++;
  }

  /// Ticks when [duration] is set, so a showing toast starts its time over.
  final ValueNotifier<int> _restarts = ValueNotifier<int>(0);

  /// Whether the toast is still up: false from the moment it is hidden.
  ValueListenable<bool> get showing => _showing;
  final ValueNotifier<bool> _showing = ValueNotifier<bool>(true);

  final Completer<HarborToastClosedReason> _closed = Completer<HarborToastClosedReason>();
  HarborToastClosedReason? _reason;

  /// Completes once the toast has left the screen, after its exit, with why
  /// it was hidden; at once for a toast hidden before its turn came.
  Future<HarborToastClosedReason> get closed => _closed.future;

  /// Whether the toast's time is stopped by a [hold].
  ValueListenable<bool> get held => _held;
  final ValueNotifier<bool> _held = ValueNotifier<bool>(false);
  int _holds = 0;

  /// Stops the toast's time until the returned hold is released: for a toast under the user's
  /// finger, or one a screen reader or the keyboard has focused. Holds are counted, as hide-bar
  /// claims are: time runs again once every hold is released, counted from the start, as it is
  /// when the toast comes back into sight. Hiding a held toast still hides it.
  ///
  /// The toast's builder reaches its own entry with [maybeOf]:
  ///
  /// ```dart
  /// HarborToasts.show(
  ///   context,
  ///   builder: (context) {
  ///     HarborToastHold? hold;
  ///     return Listener(
  ///       onPointerDown: (_) => hold ??= HarborToastEntry.maybeOf(context)?.hold(),
  ///       onPointerUp: (_) => hold = hold?.release(),
  ///       onPointerCancel: (_) => hold = hold?.release(),
  ///       child: const Text('Saved'),
  ///     );
  ///   },
  /// );
  /// ```
  HarborToastHold hold() {
    _holds++;
    _held.value = true;
    return HarborToastHold._(this);
  }

  void _release() {
    _holds--;
    if (_holds == 0) {
      _held.value = false;
    }
  }

  /// Where the toast is in its life, updated as it happens, before [closed] completes: a toast
  /// hidden while it waits is [HarborToastPhase.closed] by the time [hide] returns, and
  /// [wasShown] says whether anyone saw it.
  HarborToastPhase get phase => _phase;
  HarborToastPhase _phase = HarborToastPhase.waiting;

  /// Whether the toast was ever built on screen; stays true once it has.
  bool get wasShown => _wasShown;
  bool _wasShown = false;

  /// The toast was built on screen.
  void _shownNow() {
    _wasShown = true;
    if (_phase == HarborToastPhase.waiting) {
      _phase = HarborToastPhase.shown;
    }
  }

  /// Hides the toast; [closed] reports [HarborToastClosedReason.hide]. Hiding it again does
  /// nothing: the first reason is the one [closed] reports.
  void hide() => _hideAs(HarborToastClosedReason.hide);

  /// Hides the toast because the user dismissed it; [closed] reports
  /// [HarborToastClosedReason.dismiss], as it does when a screen reader dismisses it.
  ///
  /// For a toast with its own close button, or one in a `Dismissible`, so analytics can tell a
  /// toast the user dismissed from one the app hid with [hide]. Once hidden, it does nothing.
  void dismiss() => _hideAs(HarborToastClosedReason.dismiss);

  void _hideAs(final HarborToastClosedReason reason) {
    if (_showing.value) {
      _reason = reason;
      _showing.value = false;
    }
  }

  void _left() {
    _phase = HarborToastPhase.closed;
    if (!_closed.isCompleted) {
      _closed.complete(_reason ?? HarborToastClosedReason.hide);
    }
  }
}

/// A toast as harbor runs it: the [HarborToastEntry] a caller holds, with how it was shown.
///
/// Not exported: `HarborToasts.show` makes it, and harbor's frames and overlays run it.
final class ShownToast extends HarborToastEntry {
  ShownToast({
    required this.builder,
    required super.placement,
    required final HarborToastTiming timing,
    final Rect? avoidInGlobal,
    this.shownFrom,
    this.animationStyle,
    this.transitionBuilder,
    this.liveRegion = true,
    this.reachesSystemEdges = false,
    this.hinge,
    this.queue = HarborToastQueue.wait,
  }) : countsEntrance = timing.countsEntrance,
       countsWhileCovered = timing.countsWhileCovered,
       _avoidAtShow = avoidInGlobal,
       super._(duration: timing.duration);

  static const Duration _defaultTransition = Duration(milliseconds: 220);
  static const Duration _minimumLinger = Duration(milliseconds: 300);

  final WidgetBuilder builder;

  final bool reachesSystemEdges;

  /// Which hinges and folds the toast keeps to one side of; the showing page's when shown.
  final HarborHinge? hinge;

  /// Whether the toast's time keeps running while another route covers its page.
  final bool countsWhileCovered;

  /// Whether it waits its turn at its place or takes it at once. See [HarborToastQueue].
  final HarborToastQueue queue;

  /// Whether [duration] counts from the start of the toast's entrance rather than its end.
  final bool countsEntrance;

  /// Ticks when [duration] is set, so a showing toast starts its time over.
  ValueListenable<int> get restarts => _restarts;

  /// The duration and curve of the entrance and exit, 220 ms each way by
  /// default; [AnimationStyle.noAnimation] shows and removes the toast as it is.
  final AnimationStyle? animationStyle;

  /// Builds the entrance and exit; a fade and a slight scale when null.
  final HarborToastTransitionBuilder? transitionBuilder;

  /// Whether harbor makes the toast a live region with a dismiss action, as
  /// a `SnackBar` makes itself. False leaves the semantics to [builder]'s widget.
  final bool liveRegion;

  Duration get transitionDuration => animationStyle?.duration ?? _defaultTransition;

  Duration get reverseTransitionDuration => animationStyle?.reverseDuration ?? transitionDuration;

  /// How long a hidden toast stays in the tree: its exit, and never less
  /// than 300 ms, so a child that runs an exit of its own has time to.
  Duration get lingers => _reason == HarborToastClosedReason.replaced
      // Replaced, it leaves at once, so it is never drawn under the toast that took its place.
      ? Duration.zero
      : reverseTransitionDuration > _minimumLinger
      ? reverseTransitionDuration
      : _minimumLinger;

  /// The frame the toast was shown from, whose room it also keeps inside.
  final HarborController? shownFrom;

  final Rect? _avoidAtShow;

  /// The room of the frame the toast was shown from, in global
  /// coordinates: the toast stays inside it too, so it clears that frame's
  /// bars (a tab's own header) as well as its target's.
  ///
  /// Read from that frame's latest layout, not kept from the moment it was shown: a stored
  /// rectangle boxed the toast into a foldable's cover screen after the device opened. The
  /// rectangle from the show is the fallback once that frame has gone.
  Rect? get avoidInGlobal => shownFrom?.roomInGlobal() ?? _avoidAtShow;

  /// The frame showing the toast.
  HarborController? get owner => _owner;
  HarborController? _owner;

  /// Where the toast takes its turn: toasts at one place are shown one at a time.
  Object get _place => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => alignment,
    HarborAnchored(:final HarborAnchor? anchor, :final HarborAnchorSide side) => (anchor, side),
  };

  /// Hides the toast for [reason], which [closed] reports unless it was already hidden.
  void hideAs(final HarborToastClosedReason reason) => _hideAs(reason);
}

/// A hold on a toast's time, returned by [HarborToastEntry.hold].
class HarborToastHold {
  HarborToastHold._(this._toast);

  HarborToastEntry? _toast;

  /// Lets the toast's time run again once no other hold is on it. Releasing twice does nothing.
  /// Returns null, so `hold = hold?.release()` clears the variable it is kept in.
  HarborToastHold? release() {
    _toast?._release();
    _toast = null;
    return null;
  }
}

/// Marks the toast [toast] built on screen, for [HarborToastEntry.phase].
void toastShown(final ShownToast toast) => toast._shownNow();

/// Completes the toast [toast]'s [HarborToastEntry.closed]: it has left the screen.
void toastLeft(final ShownToast toast) => toast._left();

/// Adds [entry] to [toasts] by its [ShownToast.queue]: at the end to wait its turn, or
/// ahead of every toast still showing at its place, which are hidden as replaced.
void queueToast(final List<ShownToast> toasts, final ShownToast entry) {
  if (entry.queue == HarborToastQueue.wait) {
    toasts.add(entry);
    return;
  }
  final int first = toasts.indexWhere((final ShownToast f) => f._place == entry._place && f.showing.value);
  if (first < 0) {
    toasts.add(entry);
    return;
  }
  final List<ShownToast> ahead = <ShownToast>[
    for (final ShownToast f in toasts)
      if (f._place == entry._place && f.showing.value) f,
  ];
  toasts.insert(first, entry);
  for (final ShownToast f in ahead) {
    f.hideAs(HarborToastClosedReason.replaced);
  }
}

/// The toasts of [toasts] that are in sight: the first at each alignment, or at each anchor and
/// side. The others wait their turn behind it.
List<ShownToast> toastsInSight(final Iterable<ShownToast> toasts) {
  final Set<Object> taken = <Object>{};
  return <ShownToast>[
    for (final ShownToast toast in toasts)
      if (taken.add(toast._place)) toast,
  ];
}

/// The bar positions and clearances a frame laid out last, in its own coordinates.
@immutable
class HarborLayoutRecord {
  const HarborLayoutRecord({
    required this.frame,
    required this.body,
    required this.room,
    required this.bars,
    required this.obstruction,
    required this.keyboard,
  });

  final Rect frame;
  final Rect body;
  final Rect room;

  final List<HarborBarRecord> bars;

  final EdgeInsetsDirectional obstruction;
  final double keyboard;
}

/// One bar as it was last laid out.
@immutable
class HarborBarRecord {
  const HarborBarRecord({
    required this.edge,
    required this.kind,
    required this.rect,
    required this.extent,
    required this.restingExtent,
    required this.state,
    required this.keyboard,
    this.label,
  });

  final HarborEdge edge;
  final HarborBarKind kind;
  final Rect rect;
  final double extent;
  final double restingExtent;
  final HarborBarState state;
  final String? label;
  final HarborKeyboardStance keyboard;
}

/// Hears frames join and leave a [HarborFrameRegistry], as a `NavigatorObserver`
/// hears routes come and go.
///
/// Register one with `HarborRoot(observers:)`, or with
/// [HarborFrameRegistry.addObserver] on a registry you already have
/// (`HarborFrame.of(context).registry`). Both methods do nothing unless overridden.
///
/// A frame joins as it is first built, in the middle of a drawn frame, so both
/// events are delivered after that drawn frame, in the order they happened: by
/// then a frame that joined has laid out, and `HarborInspector.nearest` or
/// `HarborInspector.snapshotOf(harbor.registry)` can read where it is. A frame that
/// joins and leaves within one drawn frame is reported to nobody. Frames already
/// in the registry when an observer is added are not replayed: read
/// [HarborFrameRegistry.frames] for those.
///
/// See also:
///
///  * `NavigatorObserver`, the model for this one.
///  * `HarborInspector.snapshotAll`, every live frame of every root at once.
abstract class HarborFrameObserver {
  /// Const so that subclasses can be const.
  const HarborFrameObserver();

  /// [frame] has joined the registry: a page, a sheet, a dialog or a frame
  /// inside one has been built.
  void didJoin(final HarborController frame) {}

  /// [frame] has left the registry: it was removed from the tree. Its handle
  /// no longer changes anything.
  void didLeave(final HarborController frame) {}
}

/// Everything frames in one view know about each other: which is on top
/// (where a toast goes) and the list the inspector reads.
class HarborFrameRegistry {
  final List<HarborController> _frames = <HarborController>[];

  /// Every frame mounted in this view, outermost first.
  List<HarborController> get frames => List<HarborController>.unmodifiable(_frames);

  final List<HarborFrameObserver> _observers = <HarborFrameObserver>[];

  /// Events not yet delivered: a frame and whether it joined.
  final List<(HarborController, bool)> _pending = <(HarborController, bool)>[];

  /// Tells [observer] of every frame that joins or leaves from now on, after
  /// the drawn frame it happens in. Adding one observer twice reports to it twice,
  /// as a listener added twice to a `ChangeNotifier` is called twice.
  void addObserver(final HarborFrameObserver observer) => _observers.add(observer);

  /// Stops telling [observer]; one registration is removed. Events still
  /// waiting for the end of the drawn frame are not delivered to it.
  void removeObserver(final HarborFrameObserver observer) => _observers.remove(observer);

  void _join(final HarborController controller) {
    _frames.add(controller);
    _queue(controller, joined: true);
  }

  void _queue(final HarborController controller, {required final bool joined}) {
    if (!joined) {
      // A frame that leaves before its join was delivered was never seen.
      final int index = _pending.indexWhere(
        (final (HarborController, bool) event) => identical(event.$1, controller) && event.$2,
      );
      if (index >= 0) {
        _pending.removeAt(index);
        return;
      }
    }
    if (_observers.isEmpty && _pending.isEmpty) {
      return;
    }
    final bool first = _pending.isEmpty;
    _pending.add((controller, joined));
    if (first) {
      SchedulerBinding.instance.addPostFrameCallback(
        (final Duration _) => _deliver(),
        debugLabel: 'HarborFrameRegistry.observers',
      );
      SchedulerBinding.instance.ensureVisualUpdate();
    }
  }

  void _deliver() {
    final List<(HarborController, bool)> events = List<(HarborController, bool)>.of(_pending);
    _pending.clear();
    for (final (HarborController frame, bool joined) in events) {
      for (final HarborFrameObserver observer in List<HarborFrameObserver>.of(_observers)) {
        if (joined) {
          observer.didJoin(frame);
        } else {
          observer.didLeave(frame);
        }
      }
    }
  }

  void _leave(final HarborController controller) {
    _frames.remove(controller);
    _queue(controller, joined: false);
    // Toasts on a frame that is leaving move to the one now on top. With no
    // frame left to show them, they are hidden, which stops their timers. An
    // anchored toast's anchor left with its page, so it is hidden too.
    final List<ShownToast> orphans = controller._releaseToasts();
    final HarborController? top = topmost;
    for (final ShownToast toast in orphans) {
      if (top != null && toast.anchor == null) {
        top._addToast(toast);
      } else {
        toast
          ..hideAs(HarborToastClosedReason.remove)
          .._left();
      }
    }
  }

  /// The page on top: the frame a toast goes to. Only the first frame of
  /// each route (and of each sheet over the root) counts, so a frame embedded in
  /// a page never takes a page's toasts; among those, the most recently opened
  /// whose route is showing.
  HarborController? get topmost {
    HarborController? fallback;
    for (int i = _frames.length - 1; i >= 0; i--) {
      final HarborController candidate = _frames[i];
      if (!candidate.isRouteLevel) {
        continue;
      }
      final ModalRoute<Object?>? route = candidate.route;
      if (route == null || route.isCurrent) {
        return candidate;
      }
      if (route.isActive) {
        fallback ??= candidate;
      }
    }
    return fallback ?? (_frames.isEmpty ? null : _frames.first);
  }

  /// The outermost frame, where toasts go when asked to stay put.
  HarborController? get root => _frames.isEmpty ? null : _frames.first;
}

/// A frame's handle on itself, for what content asks of it.
///
/// Get it with `HarborFrame.of`, as a `Scaffold`'s is got with `Scaffold.of`. The
/// frame makes it; claims, attached bars and page covers registered here change
/// what the frame builds, and are applied on the next frame drawn when they
/// arrive during one.
///
/// What it offers: hiding bars ([hideBar]), attaching them ([attachBar], [updateAttachedBar],
/// [detachBar]), page covers ([addPageCover], [addPageCoverEdge]), the [room] and [roomInGlobal],
/// and the frame's [registry], [debugLabel] and [isPage]. The rest is harbor's own plumbing, marked
/// `@internal`; to read where a frame's bars are, use `HarborInspector.nearest`.
class HarborController {
  /// Made by the frame it belongs to.
  @internal
  HarborController({
    required this.parent,
    required this.registry,
    required this.isPage,
    this.isRoot = false,
    this._debugLabel,
  });

  /// The frame this one sits in, if any.
  @internal
  final HarborController? parent;

  /// Every frame under the same root as this one.
  final HarborFrameRegistry registry;

  /// Whether this frame was built as a page (`HarborFrame.page` or `isPage: true`, as a root, a
  /// sheet and a dialog build theirs) or has no frame above it. A frame built in a route without
  /// either reads false, though it is that route's page. For information: nothing in harbor reads
  /// it, and toasts find their page by route.
  final bool isPage;

  /// Whether this frame is a `HarborRoot`, whose children are each a page.
  @internal
  final bool isRoot;

  /// This frame's name in the [HarborInspector].
  String? get debugLabel => _debugLabel;
  @internal
  set debugLabel(final String? value) => _debugLabel = value;
  String? _debugLabel;

  /// Called when something registered here changes what the frame builds.
  @internal
  VoidCallback? onChanged;

  /// The edges this frame has bars on.
  @internal
  Set<HarborEdge> get edgesWithBars => Set<HarborEdge>.unmodifiable(_edgesWithBars);
  @internal
  set edgesWithBars(final Set<HarborEdge> value) => _edgesWithBars = value;
  Set<HarborEdge> _edgesWithBars = <HarborEdge>{};

  /// The route this frame is in, if any.
  @internal
  ModalRoute<Object?>? get route => _route;
  @internal
  set route(final ModalRoute<Object?>? value) => _route = value;
  ModalRoute<Object?>? _route;

  /// Whether this is the first frame of its route, or sits right on the root:
  /// a page toasts can go to.
  ///
  /// Only a `HarborRoot` makes the frames right inside it pages. With no root, the outermost frame
  /// is the route's page and the ones inside it are not: counting them too sent a toast shown
  /// from a header band's own frame into that band, 100 high, instead of the page (#86).
  @internal
  bool get isRouteLevel {
    final HarborController? parent = this.parent;
    if (parent == null || !identical(route, parent.route)) {
      return true;
    }
    return parent.parent == null && parent.isRoot;
  }

  /// The last layout, for the inspector and for overlays that need the room.
  @internal
  HarborLayoutRecord? get layoutRecord => _layoutRecord;
  HarborLayoutRecord? _layoutRecord;

  /// The render object of the frame, to map the last layout into global coordinates.
  @internal
  RenderBox? layoutBox;

  final List<HarborClaim> _claims = <HarborClaim>[];
  final List<HarborAttachedBarHandle> _attachedBars = <HarborAttachedBarHandle>[];
  final List<HarborPageCover> _pageCovers = <HarborPageCover>[];
  final List<ShownToast> _toasts = <ShownToast>[];
  final Map<ShownToast, VoidCallback> _toastListeners = <ShownToast, VoidCallback>{};
  final Map<ShownToast, Timer> _toastRemovals = <ShownToast, Timer>{};
  final _PageCoverNotifier _pageCoverChanges = _PageCoverNotifier();

  /// The nearest frame above [context].
  @internal
  static HarborController? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborScope>()?.controller;

  /// The nearest frame above [context]. Throws a [FlutterError], in release
  /// builds too, when there is none; [maybeOf] returns null instead.
  @internal
  static HarborController of(final BuildContext context) =>
      maybeOf(context) ?? (throw harborNotFound(context, 'HarborController'));

  /// The nearest frame, from this one outward, that has a bar on [edge].
  @internal
  HarborController? withBarOn(final HarborEdge edge) {
    HarborController? candidate = this;
    while (candidate != null) {
      if (candidate._edgesWithBars.contains(edge)) {
        return candidate;
      }
      candidate = candidate.parent;
    }
    return null;
  }

  // Claims.

  /// Asks the bars on [edge] to hide: go [HarborBarState.dark] (keep their space) or
  /// [HarborBarState.withdrawn] (give it back), the default. Claims are counted, so the bar comes
  /// back only when every claim is released. The claim goes to the nearest frame, from this one
  /// outward, that has a bar on [edge].
  ///
  /// [state] is never [HarborBarState.open]: releasing the claim is what opens the bar again.
  HarborClaim hideBar(final HarborEdge edge, {final HarborBarState state = HarborBarState.withdrawn}) {
    assert(state != HarborBarState.open, 'hideBar hides a bar dark or withdrawn; release the claim to open it again.');
    final HarborController target = withBarOn(edge) ?? this;
    final HarborClaim claim = HarborClaim._(target, edge, state);
    target._claims.add(claim);
    target._changed();
    return claim;
  }

  void _releaseClaim(final HarborClaim claim) {
    if (_claims.remove(claim)) {
      _changed();
    }
  }

  /// The state claims impose on [edge], or null when nothing has asked.
  @internal
  HarborBarState? claimedStateOf(final HarborEdge edge) {
    bool dark = false;
    for (final HarborClaim claim in _claims) {
      if (claim.edge != edge) {
        continue;
      }
      if (claim.state == HarborBarState.withdrawn) {
        return HarborBarState.withdrawn;
      }
      dark = true;
    }
    return dark ? HarborBarState.dark : null;
  }

  // Attached bars.

  /// Attaches [bar] to [edge] of this frame, as a [HarborAttachedBar] does, until
  /// the returned handle is given to [detachBar].
  HarborAttachedBarHandle attachBar(final HarborEdge edge, final HarborBar bar) {
    final HarborAttachedBarHandle attached = HarborAttachedBarHandle._(edge, bar);
    _attachedBars.add(attached);
    _changed();
    return attached;
  }

  /// Moves the attached bar [handle] stands for to [edge] and rebuilds it as [bar].
  void updateAttachedBar(final HarborAttachedBarHandle handle, final HarborEdge edge, final HarborBar bar) {
    if (handle._edge == edge && identical(handle._bar, bar)) {
      return;
    }
    handle
      .._edge = edge
      .._bar = bar;
    _changed();
  }

  /// Takes the attached bar [handle] stands for out of this frame.
  void detachBar(final HarborAttachedBarHandle handle) {
    if (_attachedBars.remove(handle)) {
      _changed();
    }
  }

  /// Bars attached here from deeper in the tree, by edge, in arrival order.
  @internal
  List<HarborBar> attachedBarsOn(final HarborEdge edge) => <HarborBar>[
    for (final HarborAttachedBarHandle p in _attachedBars)
      if (p._edge == edge) p._bar,
  ];

  // Page covers.

  /// Reports that something now covers [coverage] of this frame's bottom edge
  /// (measured from the bottom of the screen). Content keeps clear of it until
  /// the page cover is removed.
  HarborPageCover addPageCover(final ValueListenable<double> coverage) {
    final HarborPageCover coversPage = HarborPageCover._(this, coverage);
    _pageCovers.add(coversPage);
    coverage.addListener(_pageCoverChanges.ping);
    _pageCoverChanges.ping();
    return coversPage;
  }

  void _removePageCover(final HarborPageCover coversPage) {
    if (_pageCovers.remove(coversPage)) {
      coversPage._coverage.removeListener(_pageCoverChanges.ping);
      _pageCoverChanges.ping();
    }
  }

  /// Reports that something covers this frame's bottom up to [topInGlobal], a
  /// top edge in global coordinates. Unlike [addPageCover] it holds under any
  /// scale between the cover and the screen (a preview, a scaled screen).
  HarborPageCover addPageCoverEdge(final ValueListenable<double> topInGlobal) {
    final HarborPageCover coversPage = HarborPageCover._(this, topInGlobal, measuresTop: true);
    _pageCovers.add(coversPage);
    topInGlobal.addListener(_pageCoverChanges.ping);
    _pageCoverChanges.ping();
    return coversPage;
  }

  /// The top edges, in global coordinates, of page covers that measure one.
  @internal
  Iterable<double> get pageCoverTopsInGlobal sync* {
    for (final HarborPageCover coversPage in _pageCovers) {
      final double? top = coversPage._top;
      if (top != null && top.isFinite) {
        yield top;
      }
    }
  }

  /// How far page covers cover the bottom of the screen, the largest of them.
  @internal
  double get pageCoverage {
    double largest = 0.0;
    for (final HarborPageCover coversPage in _pageCovers) {
      if (coversPage._reach > largest) {
        largest = coversPage._reach;
      }
    }
    return largest;
  }

  /// Fires when a page cover moves, so the frame can lay out again without rebuilding.
  @internal
  Listenable get pageCoverChanges => _pageCoverChanges;

  // Toasts.

  /// The toasts shown on this frame, in the order they were shown.
  @internal
  List<HarborToastEntry> get toasts => List<HarborToastEntry>.unmodifiable(_toasts);

  /// [toasts], as harbor runs them.
  @internal
  List<ShownToast> get shownToasts => List<ShownToast>.unmodifiable(_toasts);

  void _addToast(final ShownToast toast) {
    toast._owner = this;
    queueToast(_toasts, toast);
    void lowered() {
      if (toast.showing.value) {
        return;
      }
      if (!toastsInSight(_toasts).contains(toast)) {
        // Hidden while it waited its turn: it has no exit to run.
        _forgetToast(toast);
        toast._left();
        return;
      }
      if (!toast.wasShown) {
        // Hidden before the frame ever built it (shown and cancelled in one drawn frame): it has no
        // exit to run either, so it goes now rather than being built once, unseen, to linger.
        _forgetToast(toast);
        toast._left();
        _changed();
        return;
      }
      // Leave time for the toast's own exit animation.
      _toastRemovals[toast] ??= Timer(toast.lingers, () {
        _toastRemovals.remove(toast);
        _forgetToast(toast);
        toast._left();
        _changed();
      });
    }

    _toastListeners[toast] = lowered;
    toast.showing.addListener(lowered);
    _changed();
  }

  void _forgetToast(final ShownToast toast) {
    _toasts.remove(toast);
    final VoidCallback? listener = _toastListeners.remove(toast);
    if (listener != null) {
      toast.showing.removeListener(listener);
    }
  }

  /// Lets go of every toast, cancelling pending removals, and returns those
  /// still showing, in the order they were shown.
  List<ShownToast> _releaseToasts() {
    final List<ShownToast> showing = _toasts.where((final ShownToast s) => s.showing.value).toList();
    for (final Timer removal in _toastRemovals.values) {
      removal.cancel();
    }
    _toastRemovals.clear();
    for (final ShownToast toast in List<ShownToast>.of(_toasts)) {
      _forgetToast(toast);
      if (!toast.showing.value) {
        toast._left();
      }
    }
    return showing;
  }

  /// Shows the toast [toast] on this frame.
  @internal
  void showToast(final HarborToastEntry toast) => _addToast(toast as ShownToast);

  // Lifecycle.

  /// Called by the frame as it mounts.
  @internal
  void join() => registry._join(this);

  final List<VoidCallback> _leaveListeners = <VoidCallback>[];

  /// Calls [listener] once when this frame leaves the tree.
  @internal
  void addLeaveListener(final VoidCallback listener) => _leaveListeners.add(listener);

  @internal
  void removeLeaveListener(final VoidCallback listener) => _leaveListeners.remove(listener);

  /// Called by the frame as it leaves the tree.
  @internal
  void leave() {
    for (final VoidCallback listener in List<VoidCallback>.of(_leaveListeners)) {
      listener();
    }
    _leaveListeners.clear();
    for (final HarborClaim claim in List<HarborClaim>.of(_claims)) {
      claim._controller = null;
    }
    _claims.clear();
    for (final HarborPageCover coversPage in List<HarborPageCover>.of(_pageCovers)) {
      coversPage._coverage.removeListener(_pageCoverChanges.ping);
      coversPage._controller = null;
    }
    _pageCovers.clear();
    registry._leave(this);
    onChanged = null;
  }

  void _changed() {
    final VoidCallback? callback = onChanged;
    if (callback == null) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final Duration _) => onChanged?.call());
      SchedulerBinding.instance.ensureVisualUpdate();
    } else {
      callback();
    }
  }

  final ValueNotifier<Rect> _room = ValueNotifier<Rect>(Rect.zero);
  bool _roomPending = false;

  /// The room nothing covers, in this frame's coordinates, a drawn frame after
  /// each layout. For content that follows the bars by transform rather than
  /// relayout (a card that slides as a drawer rises).
  ValueListenable<Rect> get room => _room;

  /// Called by the frame's layout.
  @internal
  void recordLayout(final HarborLayoutRecord record) {
    _layoutRecord = record;
    if (_room.value == record.room || _roomPending) {
      return;
    }
    _roomPending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _roomPending = false;
      final HarborLayoutRecord? latest = _layoutRecord;
      if (latest != null) {
        _room.value = latest.room;
      }
    });
  }

  /// The room nothing covers, in global coordinates, from the last layout.
  Rect? roomInGlobal() {
    final RenderBox? box = layoutBox;
    final HarborLayoutRecord? layout = _layoutRecord;
    if (box == null || layout == null || !box.attached || !box.hasSize) {
      return null;
    }
    return MatrixUtils.transformRect(box.getTransformTo(null), layout.room);
  }
}

/// A bar attached to a frame by [HarborController.attachBar]; give it to
/// [HarborController.updateAttachedBar] and [HarborController.detachBar].
class HarborAttachedBarHandle {
  HarborAttachedBarHandle._(this._edge, this._bar);

  HarborEdge _edge;
  HarborBar _bar;

  /// The edge the bar is attached to.
  HarborEdge get edge => _edge;

  /// The bar it is attached as.
  HarborBar get bar => _bar;
}

class _PageCoverNotifier extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Carries a [HarborController] down to the frame's bars and content.
class HarborScope extends InheritedWidget {
  const HarborScope({super.key, required this.controller, required super.child});

  final HarborController controller;

  @override
  bool updateShouldNotify(final HarborScope oldWidget) => controller != oldWidget.controller;
}

/// Carries the [HarborFrameRegistry] down from the outermost frame.
class HarborFrameRegistryScope extends InheritedWidget {
  const HarborFrameRegistryScope({super.key, required this.registry, required super.child});

  final HarborFrameRegistry registry;

  static HarborFrameRegistry? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborFrameRegistryScope>()?.registry;

  @override
  bool updateShouldNotify(final HarborFrameRegistryScope oldWidget) => registry != oldWidget.registry;
}

/// The error `of` throws when no frame is above [context], naming [owner]'s
/// `of` and `maybeOf`, as `Scaffold.of` names its own.
FlutterError harborNotFound(final BuildContext context, final String owner) => FlutterError.fromParts(<DiagnosticsNode>[
  ErrorSummary('$owner.of() called with a context that has no HarborFrame above it.'),
  ErrorDescription(
    'No HarborFrame ancestor could be found starting from the context that was passed to $owner.of(). '
    'This usually happens when the context is from the widget whose build method creates the HarborFrame, '
    'or when the widget is outside every HarborRoot.',
  ),
  ErrorHint(
    'Use a Builder, or a widget of its own, below the HarborFrame to get a context inside it. '
    'For a widget that may be used outside a frame, call $owner.maybeOf() and handle null.',
  ),
  context.describeElement('The context used was'),
]);
