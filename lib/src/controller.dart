import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'buoy.dart' show HarborAnchor, HarborAnchorClip, HarborFlareScope, HarborToastSlot;
import 'placement.dart';
import 'dock.dart';
import 'edge.dart';
import 'hinge.dart';
import 'tide.dart';

/// How a bar hides when content asks it to.
enum HarborYield {
  /// Lights out: the bar disappears but keeps its space.
  dark,

  /// The bar withdraws and gives its space back.
  withdraw,
}

/// A request that a bar hide, returned by [HarborController.hideBar].
/// Release it when the content no longer needs the edge.
class HarborClaim {
  HarborClaim._(this._controller, this.edge, this.mode);

  HarborController? _controller;
  final HarborEdge edge;
  final HarborYield mode;

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

  /// Whether the listenable holds the cover's top edge in global coordinates
  /// rather than how far it reaches up from the bottom of the screen.
  @Deprecated('A page cover is only removed; nothing outside harbor reads it. Deprecated after 0.9.1.')
  bool get measuresTop => _measuresTop;

  double get _reach => _controller == null || _measuresTop ? 0.0 : _coverage.value;

  double? get _top => _controller == null || !_measuresTop ? null : _coverage.value;

  /// How far the cover reaches up from the bottom of the screen.
  @Deprecated('A page cover is only removed; nothing outside harbor reads it. Deprecated after 0.9.1.')
  double get coverage => _reach;

  /// The cover's top edge in global coordinates, for a page cover that measures it.
  @Deprecated('A page cover is only removed; nothing outside harbor reads it. Deprecated after 0.9.1.')
  double? get topInGlobal => _top;

  /// Takes the cover away: call it when the cover leaves.
  void remove() {
    final HarborController? controller = _controller;
    _controller = null;
    controller?._removeBreakwater(this);
  }
}

/// Builds a toast's entrance and exit around [child] from [animation], which
/// runs from 0 to 1 as the toast is shown and back as it is hidden.
typedef HarborToastTransitionBuilder = Widget Function(BuildContext context, Animation<double> animation, Widget child);

/// Why a toast was closed, as [HarborToastEntry.closed] reports it.
enum HarborToastClosedReason {
  /// [HarborToastEntry.hide] was called.
  hide,

  /// A screen reader's dismiss action hid it.
  dismiss,

  /// Its [HarborToastEntry.duration] ran out.
  timeout,

  /// Nothing was left to show it: its frame or overlay went away with no other to move to.
  remove,

  /// A toast shown with [HarborToastQueue.replace] at its place took its turn.
  replaced;

  /// The old name of [hide].
  @Deprecated('Renamed hide. `dart fix` applies it.')
  static const HarborToastClosedReason lower = hide;
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

/// A transient float shown by `HarborToasts.show`, which returns it.
///
/// Toasts shown at the same alignment in one frame take turns, as a
/// `ScaffoldMessenger` shows its snack bars: each is shown once the one before
/// it has been hidden and has run its exit. Toasts shown by an [anchor] take
/// turns per anchor and [side].
class HarborToastEntry {
  /// Toasts are shown with `HarborToasts.show`.
  @internal
  HarborToastEntry({
    required this.builder,
    required this.placement,
    required this._duration,
    this.persist = false,
    final Rect? avoidInGlobal,
    this.shownFrom,
    this.animationStyle,
    this.transitionBuilder,
    this.liveRegion = true,
    this.countsEntrance = false,
    this.reachesSystemEdges = false,
    this.hinge,
    this.countsWhileCovered = false,
    this.queue = HarborToastQueue.wait,
  }) : _avoidAtRaise = avoidInGlobal;

  static const Duration _defaultTransition = Duration(milliseconds: 220);
  static const Duration _minimumLinger = Duration(milliseconds: 300);

  final WidgetBuilder builder;

  /// Where the toast sits: at a point of the room, or by an anchor. Its directional
  /// values are resolved in the reading direction of the page that showed it.
  final HarborPlacement placement;

  /// Where an aligned toast sits in the room; [HarborToastSlot.high]'s point for an
  /// anchored one.
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  Alignment get alignment => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => alignment as Alignment,
    HarborAnchored() => HarborToastSlot.high.alignment,
  };

  /// What an anchored toast sits by; null for one at a slot or an alignment. With [side], what a
  /// transition reads to clip at the anchor ([HarborAnchorClip]).
  HarborAnchor? get anchor => switch (placement) {
    HarborAnchored(:final HarborAnchor? anchor) => anchor,
    HarborAligned() => null,
  };

  /// Which side of its [anchor] the toast sits on; an anchored toast never flips, so this is the
  /// side it hangs on.
  HarborAnchorSide get side => switch (placement) {
    HarborAnchored(:final HarborAnchorSide side) => side,
    HarborAligned() => HarborAnchorSide.below,
  };

  /// How far the toast sits from its [anchor].
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  double get gap => switch (placement) {
    HarborAnchored(:final double gap) => gap,
    HarborAligned() => HarborAnchored.defaultGap,
  };

  /// How the toast lines up with its [anchor] across its [side].
  @Deprecated('Read placement. Deprecated after 0.7.0.')
  HarborCrossAlignment get crossAlignment => switch (placement) {
    HarborAnchored(:final HarborCrossAlignment crossAlignment) => crossAlignment,
    HarborAligned() => HarborCrossAlignment.center,
  };

  /// How far the toast keeps in from the room's edges.
  @Deprecated('Read placement.margin. Deprecated after 0.7.0.')
  EdgeInsets? get margin => placement.margin as EdgeInsets;

  /// Where the toast takes its turn: toasts at one place are shown one at a time.
  Object get _place => switch (placement) {
    HarborAligned(:final AlignmentGeometry alignment) => alignment,
    HarborAnchored(:final HarborAnchor? anchor, :final HarborAnchorSide side) => (anchor, side),
  };

  /// How long the toast stays once it is in sight: from the end of its
  /// entrance (or its start, with [countsEntrance]), while no other route
  /// covers its frame. Counted again from the start each time it comes back
  /// into sight. Null never times out, the same as [persist].
  ///
  /// Setting it starts the time over with the new duration, as coming back
  /// into sight or releasing a [hold] does: give a toast longer once a screen
  /// reader turns on, or less once it turns off. Null stops it timing out.
  Duration? get duration => _duration;
  Duration? _duration;
  set duration(final Duration? value) {
    _duration = value;
    _timing.value++;
  }

  /// Whether the toast may reach over the system edges (the home indicator, the status bar, a
  /// side cutout) on the edges it is against, still off the bars and the keyboard. Its content is
  /// handed the system edges it covers as `MediaQuery.padding`.
  final bool reachesSystemEdges;

  /// The old name of [reachesSystemEdges].
  @Deprecated('Renamed reachesSystemEdges. `dart fix` applies it.')
  bool get reachesCoast => reachesSystemEdges;

  /// Which hinges and folds the toast keeps to one side of; the showing page's when shown.
  final HarborHinge? hinge;

  /// Whether the toast's time keeps running while another route covers its page, so a toast
  /// confirming an action goes on schedule even if a page is pushed over it. A [hold] still stops
  /// it. Its time starts once its entrance has run, which it cannot while its page is covered.
  final bool countsWhileCovered;

  /// Whether it waits its turn at its place or takes it at once. See [HarborToastQueue].
  final HarborToastQueue queue;

  /// Whether [duration] counts from the start of the toast's entrance rather
  /// than its end, so a 4 s toast is on screen 4 s, entrance included. With
  /// reduced motion there is no entrance, and the two are the same.
  final bool countsEntrance;

  /// Ticks when [duration] is set, so a showing toast starts its time over.
  ValueListenable<int> get timing => _timing;
  final ValueNotifier<int> _timing = ValueNotifier<int>(0);

  /// Whether the toast stays up after [duration] until it is hidden, as a
  /// `SnackBar` with `persist` does. Give it to a toast with a button (an
  /// Undo), so a screen-reader user has time to reach it.
  final bool persist;

  /// The duration and curve of the entrance and exit, 220 ms each way by
  /// default; [AnimationStyle.noAnimation] shows and removes the toast as it is.
  final AnimationStyle? animationStyle;

  /// Builds the entrance and exit; a fade and a slight scale when null.
  final HarborToastTransitionBuilder? transitionBuilder;

  /// Whether harbor makes the toast a live region with a dismiss action, as
  /// a `SnackBar` makes itself. False leaves the semantics to [builder]'s widget.
  final bool liveRegion;

  /// How long the entrance takes.
  Duration get transitionDuration => animationStyle?.duration ?? _defaultTransition;

  /// How long the exit takes.
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

  /// The old name of [shownFrom].
  @Deprecated('Renamed shownFrom. `dart fix` applies it.')
  HarborController? get raisedIn => shownFrom;

  final Rect? _avoidAtRaise;

  /// The room of the frame the toast was shown from, in global
  /// coordinates: the toast stays inside it too, so it clears that frame's
  /// bars (a tab's own header) as well as its target's.
  ///
  /// Read from that frame's latest layout, not kept from the moment it was shown: a stored
  /// rectangle boxed the toast into a foldable's cover screen after the device opened. The
  /// rectangle from the show is the fallback once that frame has gone.
  Rect? get avoidInGlobal => shownFrom?.roomInGlobal() ?? _avoidAtRaise;

  /// Whether the toast is still up: false from the moment it is hidden.
  ValueListenable<bool> get showing => _showing;
  final ValueNotifier<bool> _showing = ValueNotifier<bool>(true);

  /// The frame showing the toast.
  HarborController? get owner => _owner;
  HarborController? _owner;

  final Completer<HarborToastClosedReason> _closed = Completer<HarborToastClosedReason>();
  HarborToastClosedReason? _reason;

  /// Completes once the toast has left the screen, after its exit, with why
  /// it was hidden; at once for a toast hidden before its turn came.
  Future<HarborToastClosedReason> get closed => _closed.future;

  /// The toast whose builder or transition [context] is in, or null outside one: for a toast
  /// that takes a [hold] on itself, or a transition that reads its [anchor] and [side].
  static HarborToastEntry? maybeOf(final BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarborFlareScope>()?.entry;

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

  /// Hides the toast. The first [reason] given is the one [closed] reports.
  void hide({final HarborToastClosedReason reason = HarborToastClosedReason.hide}) {
    if (_showing.value) {
      _reason = reason;
      _showing.value = false;
    }
  }

  /// The old name of [hide].
  @Deprecated('Renamed hide. `dart fix` applies it.')
  void lower({final HarborToastClosedReason reason = HarborToastClosedReason.hide}) => hide(reason: reason);

  void _left() {
    _phase = HarborToastPhase.closed;
    if (!_closed.isCompleted) {
      _closed.complete(_reason ?? HarborToastClosedReason.hide);
    }
  }
}

/// A hold on a toast's time, returned by [HarborToastEntry.hold].
class HarborToastHold {
  HarborToastHold._(this._flare);

  HarborToastEntry? _flare;

  /// Lets the toast's time run again once no other hold is on it. Releasing twice does nothing.
  /// Returns null, so `hold = hold?.release()` clears the variable it is kept in.
  HarborToastHold? release() {
    _flare?._release();
    _flare = null;
    return null;
  }
}

/// Marks the toast [flare] built on screen, for [HarborToastEntry.phase].
void flareShown(final HarborToastEntry flare) => flare._shownNow();

/// Completes the toast [flare]'s [HarborToastEntry.closed]: it has left the screen.
void flareLeft(final HarborToastEntry flare) => flare._left();

/// Adds [entry] to [toasts] by its [HarborToastEntry.queue]: at the end to wait its turn, or
/// ahead of every toast still showing at its place, which are hidden as replaced.
void queueFlare(final List<HarborToastEntry> toasts, final HarborToastEntry entry) {
  if (entry.queue == HarborToastQueue.wait) {
    toasts.add(entry);
    return;
  }
  final int first = toasts.indexWhere((final HarborToastEntry f) => f._place == entry._place && f.showing.value);
  if (first < 0) {
    toasts.add(entry);
    return;
  }
  final List<HarborToastEntry> ahead = <HarborToastEntry>[
    for (final HarborToastEntry f in toasts)
      if (f._place == entry._place && f.showing.value) f,
  ];
  toasts.insert(first, entry);
  for (final HarborToastEntry f in ahead) {
    f.hide(reason: HarborToastClosedReason.replaced);
  }
}

/// The toasts of [toasts] that are in sight: the first at each alignment, or at each anchor and
/// side. The others wait their turn behind it.
List<HarborToastEntry> flaresInSight(final Iterable<HarborToastEntry> toasts) {
  final Set<Object> taken = <Object>{};
  return <HarborToastEntry>[
    for (final HarborToastEntry flare in toasts)
      if (taken.add(flare._place)) flare,
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

  /// The old name of [room].
  @Deprecated('Renamed room. `dart fix` applies it.')
  Rect get clearWater => room;
  final List<HarborBarRecord> bars;

  /// The old name of [bars].
  @Deprecated('Renamed bars. `dart fix` applies it.')
  List<HarborBarRecord> get docks => bars;
  final EdgeInsetsDirectional obstruction;
  final double keyboard;

  /// The old name of [keyboard].
  @Deprecated('Renamed keyboard. `dart fix` applies it.')
  double get tide => keyboard;
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

  /// The old name of [keyboard].
  @Deprecated('Renamed keyboard. `dart fix` applies it.')
  HarborKeyboardStance get tide => keyboard;
}

/// The old name of [HarborBarRecord], which takes the old name of its keyboard stance.
///
/// A subclass rather than a typedef, so the new constructor can keep [HarborBarRecord.keyboard]
/// required.
@Deprecated('Renamed HarborBarRecord. `dart fix` applies it.')
class HarborDockRecord extends HarborBarRecord {
  /// The old name of [HarborBarRecord.new].
  @Deprecated('Renamed HarborBarRecord. `dart fix` applies it.')
  const HarborDockRecord({
    required super.edge,
    required super.kind,
    required super.rect,
    required super.extent,
    required super.restingExtent,
    required super.state,
    @Deprecated('Renamed keyboard. `dart fix` applies it.') final HarborKeyboardStance? tide,
    super.label,
  }) : assert(tide != null, 'tide is required.'),
       super(keyboard: tide ?? HarborKeyboardStance.stays);
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
  final List<HarborController> _harbors = <HarborController>[];

  /// Every frame mounted in this view, outermost first.
  List<HarborController> get frames => List<HarborController>.unmodifiable(_harbors);

  /// The old name of [frames].
  @Deprecated('Renamed frames. `dart fix` applies it.')
  List<HarborController> get harbors => frames;

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
    _harbors.add(controller);
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
    for (final (HarborController harbor, bool joined) in events) {
      for (final HarborFrameObserver observer in List<HarborFrameObserver>.of(_observers)) {
        if (joined) {
          observer.didJoin(harbor);
        } else {
          observer.didLeave(harbor);
        }
      }
    }
  }

  void _leave(final HarborController controller) {
    _harbors.remove(controller);
    _queue(controller, joined: false);
    // Toasts on a frame that is leaving move to the one now on top. With no
    // frame left to show them, they are hidden, which stops their timers. An
    // anchored toast's anchor left with its page, so it is hidden too.
    final List<HarborToastEntry> orphans = controller._releaseFlares();
    final HarborController? top = topmost;
    for (final HarborToastEntry flare in orphans) {
      if (top != null && flare.anchor == null) {
        top._raiseFlare(flare);
      } else {
        flare
          ..hide(reason: HarborToastClosedReason.remove)
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
    for (int i = _harbors.length - 1; i >= 0; i--) {
      final HarborController candidate = _harbors[i];
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
    return fallback ?? (_harbors.isEmpty ? null : _harbors.first);
  }

  /// The outermost frame, where toasts go when asked to stay put.
  HarborController? get root => _harbors.isEmpty ? null : _harbors.first;

  /// The old name of [root].
  @Deprecated('Renamed root. `dart fix` applies it.')
  HarborController? get sea => root;
}

/// A frame's handle on itself, for its bars, its content and its neighbors.
///
/// Get it with `HarborFrame.of`, as a `Scaffold`'s is got with `Scaffold.of`. The
/// frame makes it; claims, attached bars and page covers registered here change
/// what the frame builds, and are applied on the next frame drawn when they
/// arrive during one.
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
  final HarborController? parent;

  /// Every frame under the same root as this one.
  final HarborFrameRegistry registry;

  /// The old name of [registry].
  @Deprecated('Renamed registry. `dart fix` applies it.')
  HarborFrameRegistry get fleet => registry;

  /// Whether this frame is a page (the root, a route or a sheet) rather than a
  /// component inside one. Reserved and not yet read: toasts find their page
  /// with [isRouteLevel] instead.
  final bool isPage;

  /// The old name of [isPage].
  @Deprecated('Renamed isPage. `dart fix` applies it.')
  bool get isPort => isPage;

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
  Set<HarborEdge> get edgesWithBars => Set<HarborEdge>.unmodifiable(_dockedEdges);
  @internal
  set edgesWithBars(final Set<HarborEdge> value) => _dockedEdges = value;
  Set<HarborEdge> _dockedEdges = <HarborEdge>{};

  /// The old name of [edgesWithBars].
  @Deprecated('Renamed edgesWithBars. `dart fix` applies it.')
  Set<HarborEdge> get dockedEdges => edgesWithBars;

  /// The route this frame is in, if any.
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
  bool get isRouteLevel {
    final HarborController? parent = this.parent;
    if (parent == null || !identical(route, parent.route)) {
      return true;
    }
    return parent.parent == null && parent.isRoot;
  }

  /// The last layout, in this frame's coordinates.
  @Deprecated(
    'Read HarborInspector.nearest(context), which has the same rectangles in global coordinates, or listen to '
    'room. This getter goes in a later release.',
  )
  HarborLayoutRecord? get lastLayout => _layoutRecord;

  /// The render object of the frame.
  @Deprecated(
    'Read HarborInspector.nearest(context) for the harbor\'s rectangles in global coordinates, or roomInGlobal(). '
    'This getter goes in a later release.',
  )
  RenderBox? get renderBox => layoutBox;

  /// The last layout, for the inspector and for overlays that need the room.
  @internal
  HarborLayoutRecord? get layoutRecord => _layoutRecord;
  HarborLayoutRecord? _layoutRecord;

  /// The render object of the frame, to map the last layout into global coordinates.
  @internal
  RenderBox? layoutBox;

  final List<HarborClaim> _claims = <HarborClaim>[];
  final List<HarborAttachedBarHandle> _pontoons = <HarborAttachedBarHandle>[];
  final List<HarborPageCover> _breakwaters = <HarborPageCover>[];
  final List<HarborToastEntry> _flares = <HarborToastEntry>[];
  final Map<HarborToastEntry, VoidCallback> _flareListeners = <HarborToastEntry, VoidCallback>{};
  final Map<HarborToastEntry, Timer> _flareRemovals = <HarborToastEntry, Timer>{};
  final _BreakwaterNotifier _breakwaterChanges = _BreakwaterNotifier();

  /// The nearest frame above [context].
  static HarborController? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborScope>()?.controller;

  /// The nearest frame above [context]. Throws a [FlutterError], in release
  /// builds too, when there is none; [maybeOf] returns null instead.
  static HarborController of(final BuildContext context) =>
      maybeOf(context) ?? (throw harborNotFound(context, 'HarborController'));

  /// The nearest frame, from this one outward, that has a bar on [edge].
  HarborController? withBarOn(final HarborEdge edge) {
    HarborController? candidate = this;
    while (candidate != null) {
      if (candidate._dockedEdges.contains(edge)) {
        return candidate;
      }
      candidate = candidate.parent;
    }
    return null;
  }

  /// The old name of [withBarOn].
  @Deprecated('Renamed withBarOn. `dart fix` applies it.')
  HarborController? withDockOn(final HarborEdge edge) => withBarOn(edge);

  // Claims.

  /// Asks the bars on [edge] to hide: go [HarborYield.dark] or
  /// [HarborYield.withdraw]. Claims are counted, so the bar comes back only
  /// when every claim is released. The claim goes to the nearest frame, from
  /// this one outward, that has a bar on [edge].
  HarborClaim hideBar(final HarborEdge edge, {final HarborYield mode = HarborYield.withdraw}) {
    final HarborController target = withBarOn(edge) ?? this;
    final HarborClaim claim = HarborClaim._(target, edge, mode);
    target._claims.add(claim);
    target._changed();
    return claim;
  }

  /// The old name of [hideBar].
  @Deprecated('Renamed hideBar. `dart fix` applies it.')
  HarborClaim makeWay(final HarborEdge edge, {final HarborYield mode = HarborYield.withdraw}) =>
      hideBar(edge, mode: mode);

  void _releaseClaim(final HarborClaim claim) {
    if (_claims.remove(claim)) {
      _changed();
    }
  }

  /// The state claims impose on [edge], or null when nothing has asked.
  HarborBarState? claimedStateOf(final HarborEdge edge) {
    bool dark = false;
    for (final HarborClaim claim in _claims) {
      if (claim.edge != edge) {
        continue;
      }
      if (claim.mode == HarborYield.withdraw) {
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
    final HarborAttachedBarHandle pontoon = HarborAttachedBarHandle._(edge, bar);
    _pontoons.add(pontoon);
    _changed();
    return pontoon;
  }

  /// The old name of [attachBar].
  @Deprecated('Renamed attachBar. `dart fix` applies it.')
  HarborAttachedBarHandle addPontoon(final HarborEdge edge, final HarborBar dock) => attachBar(edge, dock);

  /// Moves the attached bar [handle] stands for to [edge] and rebuilds it as [bar].
  void updateAttachedBar(final HarborAttachedBarHandle handle, final HarborEdge edge, final HarborBar bar) {
    if (handle._edge == edge && identical(handle._dock, bar)) {
      return;
    }
    handle
      .._edge = edge
      .._dock = bar;
    _changed();
  }

  /// The old name of [updateAttachedBar].
  @Deprecated('Renamed updateAttachedBar. `dart fix` applies it.')
  void updatePontoon(final HarborAttachedBarHandle handle, final HarborEdge edge, final HarborBar dock) =>
      updateAttachedBar(handle, edge, dock);

  /// Takes the attached bar [handle] stands for out of this frame.
  void detachBar(final HarborAttachedBarHandle handle) {
    if (_pontoons.remove(handle)) {
      _changed();
    }
  }

  /// The old name of [detachBar].
  @Deprecated('Renamed detachBar. `dart fix` applies it.')
  void removePontoon(final HarborAttachedBarHandle handle) => detachBar(handle);

  /// Bars attached here from deeper in the tree, by edge, in arrival order.
  List<HarborBar> attachedBarsOn(final HarborEdge edge) => <HarborBar>[
    for (final HarborAttachedBarHandle p in _pontoons)
      if (p._edge == edge) p._dock,
  ];

  /// The old name of [attachedBarsOn].
  @Deprecated('Renamed attachedBarsOn. `dart fix` applies it.')
  List<HarborBar> pontoonsOn(final HarborEdge edge) => attachedBarsOn(edge);

  // Page covers.

  /// Reports that something now covers [coverage] of this frame's bottom edge
  /// (measured from the bottom of the screen). Content keeps clear of it until
  /// the page cover is removed.
  HarborPageCover addPageCover(final ValueListenable<double> coverage) {
    final HarborPageCover coversPage = HarborPageCover._(this, coverage);
    _breakwaters.add(coversPage);
    coverage.addListener(_breakwaterChanges.ping);
    _breakwaterChanges.ping();
    return coversPage;
  }

  /// The old name of [addPageCover].
  @Deprecated('Renamed addPageCover. `dart fix` applies it.')
  HarborPageCover addBreakwater(final ValueListenable<double> coverage) => addPageCover(coverage);

  void _removeBreakwater(final HarborPageCover coversPage) {
    if (_breakwaters.remove(coversPage)) {
      coversPage._coverage.removeListener(_breakwaterChanges.ping);
      _breakwaterChanges.ping();
    }
  }

  /// Reports that something covers this frame's bottom up to [topInGlobal], a
  /// top edge in global coordinates. Unlike [addPageCover] it holds under any
  /// scale between the cover and the screen (a preview, a scaled screen).
  HarborPageCover addPageCoverEdge(final ValueListenable<double> topInGlobal) {
    final HarborPageCover coversPage = HarborPageCover._(this, topInGlobal, measuresTop: true);
    _breakwaters.add(coversPage);
    topInGlobal.addListener(_breakwaterChanges.ping);
    _breakwaterChanges.ping();
    return coversPage;
  }

  /// The old name of [addPageCoverEdge].
  @Deprecated('Renamed addPageCoverEdge. `dart fix` applies it.')
  HarborPageCover addBreakwaterEdge(final ValueListenable<double> topInGlobal) => addPageCoverEdge(topInGlobal);

  /// The old name of [pageCoverTopsInGlobal].
  @Deprecated('Renamed pageCoverTopsInGlobal. `dart fix` applies it.')
  Iterable<double> get breakwaterTopsInGlobal => pageCoverTopsInGlobal;

  /// The top edges, in global coordinates, of page covers that measure one.
  Iterable<double> get pageCoverTopsInGlobal sync* {
    for (final HarborPageCover coversPage in _breakwaters) {
      final double? top = coversPage._top;
      if (top != null && top.isFinite) {
        yield top;
      }
    }
  }

  /// How far page covers cover the bottom of the screen, the largest of them.
  double get pageCoverage {
    double largest = 0.0;
    for (final HarborPageCover coversPage in _breakwaters) {
      if (coversPage._reach > largest) {
        largest = coversPage._reach;
      }
    }
    return largest;
  }

  /// Fires when a page cover moves, so the frame can lay out again without rebuilding.
  Listenable get pageCoverChanges => _breakwaterChanges;

  /// The old name of [pageCoverage].
  @Deprecated('Renamed pageCoverage. `dart fix` applies it.')
  double get breakwaterCoverage => pageCoverage;

  /// The old name of [pageCoverChanges].
  @Deprecated('Renamed pageCoverChanges. `dart fix` applies it.')
  Listenable get breakwaterChanges => pageCoverChanges;

  // Toasts.

  /// The toasts shown on this frame, in the order they were shown.
  List<HarborToastEntry> get toasts => List<HarborToastEntry>.unmodifiable(_flares);

  /// The old name of [toasts].
  @Deprecated('Renamed toasts. `dart fix` applies it.')
  List<HarborToastEntry> get flares => toasts;

  /// The flares raised on this harbor: the old name of [toasts].
  @Deprecated('Use toasts. Signals were renamed toasts before 1.0, so they are not mistaken for the signals package.')
  List<HarborToastEntry> get signals => toasts;

  void _raiseFlare(final HarborToastEntry flare) {
    flare._owner = this;
    queueFlare(_flares, flare);
    void lowered() {
      if (flare.showing.value) {
        return;
      }
      if (!flaresInSight(_flares).contains(flare)) {
        // Hidden while it waited its turn: it has no exit to run.
        _forgetFlare(flare);
        flare._left();
        return;
      }
      if (!flare.wasShown) {
        // Hidden before the frame ever built it (shown and cancelled in one drawn frame): it has no
        // exit to run either, so it goes now rather than being built once, unseen, to linger.
        _forgetFlare(flare);
        flare._left();
        _changed();
        return;
      }
      // Leave time for the toast's own exit animation.
      _flareRemovals[flare] ??= Timer(flare.lingers, () {
        _flareRemovals.remove(flare);
        _forgetFlare(flare);
        flare._left();
        _changed();
      });
    }

    _flareListeners[flare] = lowered;
    flare.showing.addListener(lowered);
    _changed();
  }

  void _forgetFlare(final HarborToastEntry flare) {
    _flares.remove(flare);
    final VoidCallback? listener = _flareListeners.remove(flare);
    if (listener != null) {
      flare.showing.removeListener(listener);
    }
  }

  /// Lets go of every toast, cancelling pending removals, and returns those
  /// still showing, in the order they were shown.
  List<HarborToastEntry> _releaseFlares() {
    final List<HarborToastEntry> showing = _flares.where((final HarborToastEntry s) => s.showing.value).toList();
    for (final Timer removal in _flareRemovals.values) {
      removal.cancel();
    }
    _flareRemovals.clear();
    for (final HarborToastEntry flare in List<HarborToastEntry>.of(_flares)) {
      _forgetFlare(flare);
      if (!flare.showing.value) {
        flare._left();
      }
    }
    return showing;
  }

  /// Shows the toast [flare] on this frame.
  @internal
  void showToast(final HarborToastEntry flare) => _raiseFlare(flare);

  // Lifecycle.

  /// Called by the frame as it mounts.
  @internal
  void join() => registry._join(this);

  final List<VoidCallback> _leaveListeners = <VoidCallback>[];

  /// Calls [listener] once when this frame leaves the tree.
  void addLeaveListener(final VoidCallback listener) => _leaveListeners.add(listener);

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
    for (final HarborPageCover coversPage in List<HarborPageCover>.of(_breakwaters)) {
      coversPage._coverage.removeListener(_breakwaterChanges.ping);
      coversPage._controller = null;
    }
    _breakwaters.clear();
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

  final ValueNotifier<Rect> _clearWater = ValueNotifier<Rect>(Rect.zero);
  bool _clearWaterPending = false;

  /// The room nothing covers, in this frame's coordinates, a drawn frame after
  /// each layout. For content that follows the bars by transform rather than
  /// relayout (a card that slides as a drawer rises).
  ValueListenable<Rect> get room => _clearWater;

  /// The old name of [room].
  @Deprecated('Renamed room. `dart fix` applies it.')
  ValueListenable<Rect> get clearWater => room;

  /// Called by the frame's layout.
  @internal
  void recordLayout(final HarborLayoutRecord record) {
    _layoutRecord = record;
    if (_clearWater.value == record.room || _clearWaterPending) {
      return;
    }
    _clearWaterPending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _clearWaterPending = false;
      final HarborLayoutRecord? latest = _layoutRecord;
      if (latest != null) {
        _clearWater.value = latest.room;
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

  /// The old name of [roomInGlobal].
  @Deprecated('Renamed roomInGlobal. `dart fix` applies it.')
  Rect? clearWaterInGlobal() => roomInGlobal();
}

/// A bar attached to a frame by [HarborController.attachBar]; give it to
/// [HarborController.updateAttachedBar] and [HarborController.detachBar].
class HarborAttachedBarHandle {
  HarborAttachedBarHandle._(this._edge, this._dock);

  HarborEdge _edge;
  HarborBar _dock;

  /// The edge the bar is attached to.
  HarborEdge get edge => _edge;

  /// The bar it is attached as.
  HarborBar get bar => _dock;

  /// The old name of [bar].
  @Deprecated('Renamed bar. `dart fix` applies it.')
  HarborBar get dock => bar;
}

class _BreakwaterNotifier extends ChangeNotifier {
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
class HarborFleetScope extends InheritedWidget {
  const HarborFleetScope({super.key, required this.registry, required super.child});

  final HarborFrameRegistry registry;

  static HarborFrameRegistry? maybeOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<HarborFleetScope>()?.registry;

  @override
  bool updateShouldNotify(final HarborFleetScope oldWidget) => registry != oldWidget.registry;
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
