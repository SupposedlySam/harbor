part of 'float.dart';

/// A point a float can be anchored to: give it to a [HarborAnchorPoint] around
/// the widget to anchor to (a button in a bar, a row in a list), and to the
/// [HarborAnchored] placement that should sit by it.
class HarborAnchor extends ChangeNotifier {
  HarborAnchor({this.debugLabel});

  final String? debugLabel;

  @override
  String toString() => debugLabel == null ? describeIdentity(this) : '${describeIdentity(this)}($debugLabel)';

  RenderBox? _box;
  bool _disposed = false;

  /// The anchored widget's box, while it is in the tree and laid out.
  RenderBox? get box => (_box != null && _box!.attached && _box!.hasSize) ? _box : null;

  void _attach(final RenderBox box) {
    assert(() {
      final RenderBox? previous = _box;
      if (previous != null && !identical(previous, box)) {
        (_debugPreviousBoxes ??= <RenderBox>{}).add(previous);
        _debugScheduleSharedCheck();
      }
      return true;
    }());
    _box = box;
    _moved();
  }

  void _detach(final RenderBox box) {
    if (identical(_box, box)) {
      _box = null;
      _moved();
    }
    assert(() {
      _debugPreviousBoxes?.remove(box);
      return true;
    }());
  }

  // The boxes a later attach replaced. As with a LayerLink's leaders, each one
  // must detach by the end of the frame, or two points share this anchor.
  Set<RenderBox>? _debugPreviousBoxes;
  bool _debugSharedCheckScheduled = false;

  void _debugScheduleSharedCheck() {
    if (_debugSharedCheckScheduled) {
      return;
    }
    _debugSharedCheckScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _debugSharedCheckScheduled = false;
      final Set<RenderBox> stillAttached = <RenderBox>{
        for (final RenderBox previous in _debugPreviousBoxes ?? const <RenderBox>{})
          if (previous.attached && !identical(previous, _box)) previous,
      };
      _debugPreviousBoxes = null;
      if (stillAttached.isEmpty || _disposed) {
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
              'More than one HarborAnchorPoint is using the same HarborAnchor${debugLabel == null ? '' : ' "$debugLabel"'}.',
            ),
            ErrorDescription(
              'An anchor refers to one point. With several attached, a float anchored to it sits by whichever '
              'laid out last, and when that one leaves the anchor has no point while the others are still there.',
            ),
            ErrorHint(
              'Give each HarborAnchorPoint its own HarborAnchor, for example one per row of a list, '
              'or wrap only the row whose float or popover is showing.',
            ),
            if (_box case final RenderBox current) current.describeForError('The point the anchor is using'),
            for (final RenderBox previous in stillAttached) previous.describeForError('Also attached'),
          ]),
          library: 'harbor',
        ),
      );
    }, debugLabel: 'HarborAnchor.sharedCheck');
  }

  bool _pending = false;

  void _moved() {
    if (_pending || _disposed || !hasListeners) {
      return;
    }
    _pending = true;
    SchedulerBinding.instance.addPostFrameCallback((final Duration _) {
      _pending = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Marks [child] as the point [anchor] refers to.
class HarborAnchorPoint extends SingleChildRenderObjectWidget {
  const HarborAnchorPoint({super.key, required this.anchor, super.child});

  final HarborAnchor anchor;

  @override
  RenderObject createRenderObject(final BuildContext context) => _RenderAnchorPoint(anchor);

  @override
  void updateRenderObject(final BuildContext context, final RenderObject renderObject) {
    (renderObject as _RenderAnchorPoint).anchor = anchor;
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<HarborAnchor>('anchor', anchor));
  }
}

class _RenderAnchorPoint extends RenderProxyBox {
  _RenderAnchorPoint(this._anchor);

  HarborAnchor _anchor;
  set anchor(final HarborAnchor value) {
    if (!identical(_anchor, value)) {
      _anchor._detach(this);
      _anchor = value;
      if (attached) {
        value._attach(this);
      }
    }
  }

  Offset? _lastGlobal;

  @override
  void attach(final PipelineOwner owner) {
    super.attach(owner);
    _anchor._attach(this);
  }

  @override
  void detach() {
    _anchor._detach(this);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    _anchor._moved();
  }

  @override
  void paint(final PaintingContext context, final Offset offset) {
    super.paint(context, offset);
    final Offset global = localToGlobal(Offset.zero);
    if (global != _lastGlobal) {
      _lastGlobal = global;
      _anchor._moved();
    }
  }
}

/// Clips its child at the edge of [anchor] facing [side]: below an anchor, nothing above the
/// anchor's bottom edge is drawn. For a toast or float that emerges from under the field it hangs
/// from, slid in from that edge while this keeps it hidden until it clears it.
///
/// The anchor is measured each time this paints, so the clip follows an anchor that scrolls. An
/// anchored toast never flips, so its [HarborToastEntry.side] is the side to give; read it in the
/// toast's transition with [HarborToastEntry.maybeOf]:
///
/// ```dart
/// HarborToasts.show(
///   context,
///   placement: HarborAnchored(searchField),
///   transitionBuilder: (context, animation, child) {
///     final HarborToastEntry entry = HarborToastEntry.maybeOf(context)!;
///     return HarborAnchorClip(
///       anchor: entry.anchor!,
///       side: entry.side,
///       child: SlideTransition(
///         position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(animation),
///         child: child,
///       ),
///     );
///   },
///   builder: (context) => const Text('No results'),
/// );
/// ```
///
/// With no box for its anchor (the anchor is out of the tree), it draws its child unclipped.
class HarborAnchorClip extends SingleChildRenderObjectWidget {
  const HarborAnchorClip({super.key, required this.anchor, required this.side, super.child});

  final HarborAnchor anchor;
  final HarborAnchorSide side;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderAnchorClip(anchor, side, Directionality.maybeOf(context) ?? TextDirection.ltr);

  @override
  void updateRenderObject(final BuildContext context, final RenderObject renderObject) {
    (renderObject as _RenderAnchorClip)
      ..anchor = anchor
      ..side = side
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

class _RenderAnchorClip extends RenderProxyBox {
  _RenderAnchorClip(this._anchor, this._side, this._textDirection);

  HarborAnchor _anchor;
  set anchor(final HarborAnchor value) {
    if (!identical(value, _anchor)) {
      _anchor = value;
      markNeedsPaint();
    }
  }

  HarborAnchorSide _side;
  set side(final HarborAnchorSide value) {
    if (value != _side) {
      _side = value;
      markNeedsPaint();
    }
  }

  TextDirection _textDirection;
  set textDirection(final TextDirection value) {
    if (value != _textDirection) {
      _textDirection = value;
      markNeedsPaint();
    }
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? anchorBox = _anchor.box;
    if (child == null || anchorBox == null || !anchorBox.attached || !anchorBox.hasSize) {
      _clip.layer = null;
      super.paint(context, offset);
      return;
    }
    final Rect at = MatrixUtils.transformRect(anchorBox.getTransformTo(this), Offset.zero & anchorBox.size);
    const double far = 1e6;
    final bool ltr = _textDirection == TextDirection.ltr;
    final Rect beyond = switch (_side) {
      HarborAnchorSide.below => Rect.fromLTRB(-far, at.bottom, far, far),
      HarborAnchorSide.above => Rect.fromLTRB(-far, -far, far, at.top),
      HarborAnchorSide.start => ltr ? Rect.fromLTRB(-far, -far, at.left, far) : Rect.fromLTRB(at.right, -far, far, far),
      HarborAnchorSide.end => ltr ? Rect.fromLTRB(at.right, -far, far, far) : Rect.fromLTRB(-far, -far, at.left, far),
    };
    _clip.layer = context.pushClipRect(needsCompositing, offset, beyond, super.paint, oldLayer: _clip.layer);
  }

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
