import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'edge.dart';
import 'waters.dart';

/// Keeps [child] in sight at the top of the clear water while the item it is
/// in scrolls under the docks: a pill that rides with its card and then sticks
/// just below the header, until the card itself has scrolled away.
///
/// It never leaves its parent's box, so it goes once the item does.
class HarborSticky extends SingleChildRenderObjectWidget {
  const HarborSticky({super.key, this.gap = 8.0, super.child});

  /// How far below the docks it sticks.
  final double gap;

  @override
  RenderObject createRenderObject(final BuildContext context) =>
      _RenderHarborSticky(HarborController.maybeOf(context), gap);

  @override
  void updateRenderObject(final BuildContext context, final RenderObject renderObject) {
    (renderObject as _RenderHarborSticky)
      ..harbor = HarborController.maybeOf(context)
      ..gap = gap;
  }
}

class _RenderHarborSticky extends RenderProxyBox {
  _RenderHarborSticky(this._harbor, this._gap);

  HarborController? _harbor;
  HarborController? get harbor => _harbor;
  set harbor(final HarborController? value) {
    if (value != _harbor) {
      _harbor = value;
      markNeedsPaint();
    }
  }

  double _gap;
  double get gap => _gap;
  set gap(final double value) {
    if (value != _gap) {
      // The shift is worked out in paint, so a new gap only needs a repaint.
      _gap = value;
      markNeedsPaint();
    }
  }
  double _shift = 0.0;

  @override
  void paint(final PaintingContext context, final Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    _shift = 0.0;
    final double? line = _stickLine();
    final RenderObject? parentBox = parent;
    if (line != null && parentBox is RenderBox && parentBox.hasSize) {
      // Measured in this box's own coordinates, so a scale anywhere above
      // (a scale model, a preview) moves the child by the right amount.
      final double wanted = globalToLocal(Offset(0.0, line)).dy + gap;
      final double top = MatrixUtils.transformPoint(getTransformTo(parentBox), Offset.zero).dy;
      final double room = parentBox.size.height - (top + size.height);
      _shift = wanted.clamp(0.0, math.max(0.0, room));
    }
    context.paintChild(child, offset + Offset(0.0, _shift));
  }

  /// Where the top of the clear water is, in global coordinates: below the
  /// harbor's docks and below any sliver docks pinned in the scroll view.
  double? _stickLine() {
    double? line = harbor?.clearWaterInGlobal()?.top;
    RenderObject? node = parent;
    while (node != null && node is! RenderSliver) {
      node = node.parent;
    }
    // The sliver that sits in the viewport, past any padding slivers.
    while (node is RenderSliver && node.parent is RenderSliver) {
      node = node.parent;
    }
    if (node is RenderSliver && node.parent is RenderViewportBase) {
      final RenderViewportBase viewport = node.parent! as RenderViewportBase;
      if (viewport.axisDirection == AxisDirection.down && viewport.hasSize) {
        // The overlap is measured from this sliver's own leading edge, which
        // sits below the viewport's top until the sliver scrolls up to it.
        final double pinned = MatrixUtils.transformPoint(node.getTransformTo(null), Offset(0.0, node.constraints.overlap)).dy;
        line = line == null ? pinned : math.max(line, pinned);
      }
    }
    return line;
  }

  @override
  void applyPaintTransform(final RenderBox child, final Matrix4 transform) =>
      transform.translateByDouble(0.0, _shift, 0.0, 1.0);

  @override
  bool hitTestChildren(final BoxHitTestResult result, {required final Offset position}) => result.addWithPaintOffset(
    offset: Offset(0.0, _shift),
    position: position,
    hitTest: (final BoxHitTestResult result, final Offset transformed) => child?.hitTest(result, position: transformed) ?? false,
  );

  @override
  bool hitTest(final BoxHitTestResult result, {required final Offset position}) {
    // The child may be painted below this box while it sticks.
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Centers [child] in the harbor's frame, then nudges it just far enough that
/// it overlaps the docks and the keyboard by no more than [overlapBudget]: a
/// canvas's controls that should sit in the middle of the screen, not the
/// middle of whatever water is left, but never mostly under a sheet.
///
/// When the child is too tall for both limits, the top one wins: it stays
/// clear of the header and lets the bottom run past the budget.
class HarborCenter extends StatelessWidget {
  const HarborCenter({super.key, this.overlapBudget = 0.0, required this.child});

  final double overlapBudget;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    final double top = HarborWaters.clearanceOf(context, HarborEdge.top);
    final double bottom = HarborWaters.clearanceOf(context, HarborEdge.bottom);
    return CustomSingleChildLayout(
      delegate: _CenterDelegate(top: top, bottom: bottom, budget: overlapBudget),
      child: child,
    );
  }
}

class _CenterDelegate extends SingleChildLayoutDelegate {
  const _CenterDelegate({required this.top, required this.bottom, required this.budget});

  final double top;
  final double bottom;
  final double budget;

  @override
  BoxConstraints getConstraintsForChild(final BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(final Size size, final Size childSize) {
    double y = (size.height - childSize.height) / 2;
    final double minTop = top - budget;
    final double maxBottom = size.height - bottom + budget;
    if (y + childSize.height > maxBottom) {
      y = maxBottom - childSize.height;
    }
    if (y < minTop) {
      y = minTop;
    }
    return Offset((size.width - childSize.width) / 2, y);
  }

  @override
  bool shouldRelayout(final _CenterDelegate oldDelegate) =>
      oldDelegate.top != top || oldDelegate.bottom != bottom || oldDelegate.budget != budget;
}
