import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'edge.dart';

/// Lists [child], the output of a widget that took an inset out of what lies beneath it, among
/// the consumers of the nearest frame, for the inspector: [amounts] on each of [edges], from the
/// values that widget laid out with.
///
/// Debug and profile only: in a release build [wrap] returns the child as it is, so an app pays
/// nothing for it, and nothing reads it there (`ext.harbor.inspector` is not served either).
@internal
class HarborConsumerReport extends StatefulWidget {
  const HarborConsumerReport({
    super.key,
    required this.type,
    required this.edges,
    required this.amounts,
    this.label,
    this.widgetKey,
    required this.child,
  });

  /// [child] reported as a consumer named [type], unless this is a release build.
  static Widget wrap({
    required final String type,
    required final Iterable<HarborEdge> edges,
    required final EdgeInsetsDirectional amounts,
    final String? label,
    final Key? widgetKey,
    required final Widget child,
  }) => kReleaseMode
      ? child
      : HarborConsumerReport(
          type: type,
          edges: edges,
          amounts: amounts,
          label: label,
          widgetKey: widgetKey,
          child: child,
        );

  final String type;
  final Iterable<HarborEdge> edges;
  final EdgeInsetsDirectional amounts;
  final String? label;

  /// The key of the widget reported, which this report does not take as its own.
  final Key? widgetKey;
  final Widget child;

  @override
  State<HarborConsumerReport> createState() => _HarborConsumerReportState();
}

class _HarborConsumerReportState extends State<HarborConsumerReport> implements HarborConsumerSource {
  HarborController? _frame;

  @override
  void deactivate() {
    _frame?.consumers.remove(this);
    _frame = null;
    super.deactivate();
  }

  @override
  int get depth {
    int depth = 0;
    context.visitAncestorElements((final Element _) {
      depth++;
      return true;
    });
    return depth;
  }

  @override
  void collect(final List<HarborConsumerRecord> into) {
    final RenderObject? box = context.findRenderObject();
    if (box == null || !box.attached) {
      return;
    }
    final Rect rect = MatrixUtils.transformRect(box.getTransformTo(null), box.paintBounds);
    final String? key = widget.widgetKey?.toString();
    for (final HarborEdge edge in widget.edges) {
      into.add(
        HarborConsumerRecord(
          type: widget.type,
          edge: edge,
          amount: HarborEdges.of(widget.amounts, edge),
          rect: rect,
          label: widget.label,
          key: key,
        ),
      );
    }
  }

  @override
  Widget build(final BuildContext context) {
    // Looked up without depending: a report that moves to another frame is built again anyway.
    final HarborController? frame = HarborController.maybeOf(context);
    if (!identical(frame, _frame)) {
      _frame?.consumers.remove(this);
      _frame = frame?..consumers.add(this);
    }
    return widget.child;
  }
}
