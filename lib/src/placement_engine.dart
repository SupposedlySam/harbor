part of 'float.dart';

/// Places one overlay in the room of the box it fills: a popover by its anchor in the room of the
/// frame around it, or a toast with no frame above it in the room its overlay's padding and
/// keyboard leave.
class _PlacedLayout extends SingleChildRenderObjectWidget {
  const _PlacedLayout({
    this.frame,
    this.covered = EdgeInsets.zero,
    this.keyboard,
    this.hinges = const <Rect>[],
    required this.placement,
    this.anchor,
    this.flips = false,
    required this.textDirection,
    this.landed,
    super.child,
  }) : assert(keyboard == null || placement is HarborAligned, 'Only an aligned overlay reaches over the system edges.'),
       assert(
         frame == null || placement is HarborAnchored,
         'An aligned overlay in a frame is placed by its float layer.',
       ),
       assert(placement is HarborAligned || anchor != null, 'An anchored overlay needs its anchor.');

  /// The frame whose room the overlay keeps to; with none, the box less [covered].
  final HarborController? frame;

  /// What covers each edge of the box when there is no [frame]: the larger of the padding and
  /// the keyboard.
  final EdgeInsets covered;

  /// The keyboard, for an aligned overlay that reaches over the system edges: its room is the box less
  /// this alone. Null for one that does not.
  final EdgeInsets? keyboard;

  /// The hinges and folds the overlay keeps off, in the box's coordinates.
  final List<Rect> hinges;
  final HarborPlacement placement;

  /// The anchor an anchored overlay sits by: its placement's, or a popover's own around its child.
  final HarborAnchor? anchor;

  /// Whether an anchored overlay goes to the opposite side when its own has no room.
  final bool flips;
  final TextDirection textDirection;

  /// Told the side an anchored overlay landed on, the frame drawn after it changes.
  final ValueNotifier<HarborAnchorSide>? landed;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderPlaced(this);

  @override
  void updateRenderObject(final BuildContext context, final _RenderPlaced renderObject) {
    renderObject.config = this;
  }
}

/// Fills its box and places its child: an aligned one as it lays out, an anchored one when it
/// paints, once the frame's room and the anchor are laid out for this frame drawn.
class _RenderPlaced extends RenderShiftedBox {
  _RenderPlaced(this._config) : super(null);

  _PlacedLayout _config;
  set config(final _PlacedLayout value) {
    final _PlacedLayout old = _config;
    _config = value;
    if (attached) {
      _unlisten(old);
      _listen(value);
    }
    markNeedsLayout();
  }

  bool _placed = false;

  void _listen(final _PlacedLayout c) {
    c.frame?.room.addListener(markNeedsLayout);
  }

  void _unlisten(final _PlacedLayout c) {
    c.frame?.room.removeListener(markNeedsLayout);
  }

  // Its own layer, since an anchored one is painted again every frame drawn.
  @override
  bool get isRepaintBoundary => true;

  final _FollowEveryFrame _follow = _FollowEveryFrame();

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _listen(_config);
  }

  @override
  void detach() {
    _follow.cancel();
    _unlisten(_config);
    super.detach();
  }

  /// The frame's room in this box's coordinates, or the box less what covers it when there
  /// is no frame.
  Rect _room() {
    final HarborController? frame = _config.frame;
    final RenderBox? box = frame?.layoutBox;
    final HarborLayoutRecord? layout = frame?.layoutRecord;
    return box == null || layout == null || !box.attached || !box.hasSize
        ? _config.covered.deflateRect(Offset.zero & size)
        : MatrixUtils.transformRect(box.getTransformTo(this), layout.room);
  }

  @override
  Size computeDryLayout(final BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = constraints.biggest;
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    // Only the size of the frame's room is known while laying out: its last one. A change to it lays
    // the overlay out again.
    final EdgeInsets? keyboard = _config.keyboard;
    final HarborPlacementArea area = HarborPlacementEngine.area(
      clear: _config.frame?.layoutRecord?.room ?? _config.covered.deflateRect(Offset.zero & size),
      open: keyboard?.deflateRect(Offset.zero & size),
      placement: _config.placement,
      textDirection: _config.textDirection,
      hinges: _config.hinges,
    );
    final Size room = Size(math.max(0.0, area.rect.width), math.max(0.0, area.rect.height));
    child.layout(
      keyboard != null ? _SystemEdgeConstraints(room, area.systemEdgesCovered) : BoxConstraints.loose(room),
      parentUsesSize: true,
    );
    if (_config.placement is HarborAligned) {
      (child.parentData! as BoxParentData).offset = HarborPlacementEngine.place(
        placement: _config.placement,
        area: area.rect,
        size: child.size,
        textDirection: _config.textDirection,
      ).offset;
    }
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    final HarborPlacement placement = _config.placement;
    if (placement is HarborAligned) {
      _setPlaced(child != null);
      if (child != null) {
        context.paintChild(child, (child.parentData! as BoxParentData).offset + offset);
      }
      return;
    }
    _follow.next(markNeedsPaint);
    final RenderBox? anchorBox = _config.anchor?.box;
    _setPlaced(child != null && anchorBox != null);
    if (!_placed) {
      return;
    }
    final BoxParentData data = child!.parentData! as BoxParentData;
    final Offset was = data.offset;
    final Rect at = MatrixUtils.transformRect(anchorBox!.getTransformTo(this), Offset.zero & anchorBox.size);
    final HarborLanding landed = HarborPlacementEngine.place(
      placement: placement,
      area: HarborPlacementEngine.area(
        clear: _room(),
        placement: placement,
        textDirection: _config.textDirection,
        hinges: _config.hinges,
        holding: at.center,
      ).rect,
      size: child.size,
      textDirection: _config.textDirection,
      anchorRect: at,
      flips: _config.flips,
    );
    data.offset = landed.offset;
    _report(landed.side!);
    // Layout refreshes semantics, but the overlay is placed here, after it, so a move refreshes them too.
    if (data.offset != was) {
      markNeedsSemanticsUpdate();
    }
    context.paintChild(child, data.offset + offset);
  }

  void _setPlaced(final bool placed) {
    if (placed != _placed) {
      _placed = placed;
      markNeedsSemanticsUpdate();
    }
  }

  HarborAnchorSide? _reporting;

  // The side is only known here, and nothing may be rebuilt while painting, so the popover hears it
  // the frame drawn after, as an anchor reports that it moved.
  void _report(final HarborAnchorSide side) {
    final ValueNotifier<HarborAnchorSide>? landed = _config.landed;
    if (landed == null || side == (_reporting ?? landed.value)) {
      return;
    }
    final bool scheduled = _reporting != null;
    _reporting = side;
    if (scheduled) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      final HarborAnchorSide? reported = _reporting;
      _reporting = null;
      if (reported != null && attached) {
        _config.landed?.value = reported;
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  bool paintsChild(final RenderBox child) => _placed;

  @override
  void visitChildrenForSemantics(final RenderObjectVisitor visitor) {
    if (_placed) {
      super.visitChildrenForSemantics(visitor);
    }
  }

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) =>
      _placed && super.hitTestChildren(result, position: position);
}

/// Paints an anchored float again at the start of every frame that is drawn, as
/// `OverlayPortal.overlayChildLayoutBuilder` lays its child out again, so the
/// float is placed by where its anchor is in that frame drawn. An anchor that scrolls
/// is moved without being laid out or painted (a list row is its own layer), so
/// it cannot say that it moved in time, or at all. Asks for no frame itself.
class _FollowEveryFrame {
  int? _id;

  void next(final VoidCallback repaint) {
    _id ??= SchedulerBinding.instance.scheduleFrameCallback((final Duration _) {
      _id = null;
      repaint();
    }, scheduleNewFrame: false);
  }

  void cancel() {
    if (_id case final int id) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(id);
      _id = null;
    }
  }
}

/// A toast's constraints when it reaches the system edges: loose, carrying the system edges it
/// covers, which the toast hands its content as `MediaQuery.padding`.
class _SystemEdgeConstraints extends BoxConstraints {
  _SystemEdgeConstraints(final Size room, this.systemEdges) : super(maxWidth: room.width, maxHeight: room.height);

  final EdgeInsets systemEdges;

  @override
  bool operator ==(final Object other) =>
      super == other && other is _SystemEdgeConstraints && other.systemEdges == systemEdges;

  @override
  int get hashCode => Object.hash(super.hashCode, systemEdges);
}
