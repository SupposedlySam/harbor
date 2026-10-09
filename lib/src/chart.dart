import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'dock.dart';
import 'edge.dart';

/// One harbor on a chart, in global coordinates.
@immutable
class HarborChartEntry {
  const HarborChartEntry({
    required this.label,
    required this.depth,
    required this.frame,
    required this.body,
    required this.clearWater,
    required this.docks,
    required this.obstruction,
    required this.tide,
    this.isolated = false,
  });

  final String label;

  /// How many harbors this one sits inside.
  final int depth;
  final Rect frame;
  final Rect body;
  final Rect clearWater;
  final List<HarborDockRecord> docks;
  final EdgeInsetsDirectional obstruction;
  final double tide;

  /// Whether this harbor floats on an isolated sea: a `HarborSea` mounted
  /// inside another harbor (a phone drawn inside a page, a preview), which
  /// keeps a fleet, a tide gauge and flares of its own. Its [depth] counts
  /// from that sea, not from the app's, and its rects are in global
  /// coordinates like every other harbor's.
  final bool isolated;

  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'depth': depth,
    'isolated': isolated,
    'frame': _rect(frame),
    'body': _rect(body),
    'clearWater': _rect(clearWater),
    'tide': tide,
    'obstruction': <String, double>{
      for (final HarborEdge e in HarborEdge.values) e.name: HarborEdges.of(obstruction, e),
    },
    'docks': <Map<String, Object?>>[
      for (final HarborDockRecord d in docks)
        <String, Object?>{
          'label': d.label,
          'edge': d.edge.name,
          'kind': d.kind.name,
          'state': d.state.name,
          'tide': '${d.tide}'.split('.').last,
          'extent': d.extent,
          'restingExtent': d.restingExtent,
          'rect': _rect(d.rect),
        },
    ],
  };

  static Map<String, double> _rect(final Rect r) => <String, double>{
    'left': r.left,
    'top': r.top,
    'width': r.width,
    'height': r.height,
  };
}

/// The harbor chart: who holds which edge, at which layer, in every harbor
/// in a view.
abstract final class HarborChart {
  /// Every harbor in [context]'s view, outermost first, from its last layout.
  static List<HarborChartEntry> snapshot(final BuildContext context) {
    final HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    return fleet == null ? const <HarborChartEntry>[] : snapshotOf(fleet);
  }

  /// Every harbor in [fleet], outermost first, from its last layout.
  static List<HarborChartEntry> snapshotOf(final HarborFleet fleet) => <HarborChartEntry>[
    for (final HarborController harbor in fleet.harbors)
      if (_entryOf(harbor) case final HarborChartEntry entry) entry,
  ];

  /// Every harbor of every live sea, with no context: for tooling (a debug
  /// panel, a log, an automation driver) that runs outside the widget tree.
  ///
  /// Seas are listed in the order they were mounted, each outermost first, as
  /// [snapshot] lists one. A sea mounted inside another harbor (a phone drawn
  /// in a page) is listed too, with [HarborChartEntry.isolated] set on each of
  /// its harbors. A sea that has been disposed is gone from the list, and a
  /// harbor that has not laid out yet is not in it.
  static List<HarborChartEntry> snapshotAll() => <HarborChartEntry>[
    for (final HarborFleet fleet in _seas.keys) ...snapshotOf(fleet),
  ];

  /// The harbor nearest [context], as [snapshot] has it: in global
  /// coordinates, from its last layout. Null when there is no harbor above
  /// [context] or it has not laid out yet.
  ///
  /// This is how a test or a tool reads a harbor's frame, clear water and
  /// docks, as `flutter_test` reads a widget's place through its render object.
  static HarborChartEntry? nearest(final BuildContext context) {
    final HarborController? harbor = HarborController.maybeOf(context);
    return harbor == null ? null : _entryOf(harbor);
  }

  static HarborChartEntry? _entryOf(final HarborController harbor) {
    final RenderBox? box = harbor.layoutBox;
    final HarborLayoutRecord? layout = harbor.layoutRecord;
    if (box == null || layout == null || !box.attached || !box.hasSize) {
      return null;
    }
    final Matrix4 toGlobal = box.getTransformTo(null);
    Rect global(final Rect r) => MatrixUtils.transformRect(toGlobal, r);
    int depth = 0;
    for (HarborController? p = harbor.parent; p != null; p = p.parent) {
      depth++;
    }
    return HarborChartEntry(
      label: harbor.debugLabel ?? 'harbor',
      depth: depth,
      isolated: _seas[harbor.fleet] ?? false,
      frame: global(layout.frame),
      body: global(layout.body),
      clearWater: global(layout.clearWater),
      docks: <HarborDockRecord>[
        for (final HarborDockRecord d in layout.docks)
          HarborDockRecord(
            edge: d.edge,
            kind: d.kind,
            rect: global(d.rect),
            extent: d.extent,
            restingExtent: d.restingExtent,
            state: d.state,
            tide: d.tide,
            label: d.label,
          ),
      ],
      obstruction: layout.obstruction,
      tide: layout.tide,
    );
  }

  /// The fleets of the live seas, in the order they were mounted, and whether
  /// each is isolated.
  static final Map<HarborFleet, bool> _seas = <HarborFleet, bool>{};
  static bool _registered = false;

  /// Lists [fleet] on the chart of live seas while its sea is mounted. Called
  /// by the harbor that makes a fleet; [unregister] it when that harbor goes.
  @internal
  static void register(final HarborFleet fleet, {required final bool isolated}) {
    _seas[fleet] = isolated;
    _registerExtension();
  }

  /// Takes [fleet] off the chart of live seas.
  @internal
  static void unregister(final HarborFleet fleet) => _seas.remove(fleet);

  /// Serves the chart over the VM service as `ext.harbor.chart`, so a tool
  /// driving the app can ask where everything is, and lists [fleet] on it.
  /// Debug and profile only.
  ///
  /// Every sea is served already: a harbor that makes a fleet lists it while
  /// it is mounted. A fleet served by hand stays listed. The extension answers
  /// `{"harbors": [...]}` for every sea that is not isolated, and with the
  /// parameter `isolated=true` for isolated seas too (see [snapshotAll]).
  static void serve(final HarborFleet fleet) {
    _seas.putIfAbsent(fleet, () => false);
    _registerExtension();
  }

  static void _registerExtension() {
    if (_registered || kReleaseMode) {
      return;
    }
    _registered = true;
    try {
      developer.registerExtension('ext.harbor.chart', (final String method, final Map<String, String> params) async {
        final bool withIsolated = params['isolated'] == 'true';
        final List<Map<String, Object?>> json = <Map<String, Object?>>[
          for (final HarborChartEntry e in snapshotAll())
            if (withIsolated || !e.isolated) e.toJson(),
        ];
        return developer.ServiceExtensionResponse.result(jsonEncode(<String, Object?>{'harbors': json}));
      });
    } on Object {
      // Already registered in this isolate.
    }
  }
}

/// Draws the chart over [child]: every dock's ground (piers in teal, quays in
/// sand), each harbor's clear water outlined, and the tide in blue.
///
/// See also:
///
///  * `debugPaintSizeEnabled`, the closest Flutter debug paint, which draws every box rather than who
///    holds each edge.
class HarborChartOverlay extends StatefulWidget {
  const HarborChartOverlay({super.key, this.enabled = true, this.labelStyle, required this.child});

  final bool enabled;

  /// Merged over the dock labels' own style (9 pt, white on a dark band).
  ///
  /// Set a `fontFamily` the test has loaded to make the labels readable in
  /// widget tests and goldens: with none, `flutter_test` draws them in its box
  /// test font, and the labels carry each dock's extent.
  final TextStyle? labelStyle;

  final Widget child;

  @override
  State<HarborChartOverlay> createState() => _HarborChartOverlayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle, defaultValue: null));
  }
}

class _HarborChartOverlayState extends State<HarborChartOverlay> with SingleTickerProviderStateMixin {
  /// The fleet the harbors beneath join, when this overlay sits above the
  /// outermost harbor (as it does in `MaterialApp.builder`).
  HarborFleet? _ownFleet;

  late final Ticker _ticker = createTicker((final Duration _) => _repaint.value++);
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(final HarborChartOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    if (_ownFleet case final HarborFleet fleet) {
      HarborChart.unregister(fleet);
    }
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    HarborFleet? fleet = HarborFleetScope.maybeOf(context);
    if (fleet == null) {
      if (_ownFleet == null) {
        _ownFleet = HarborFleet();
        HarborChart.register(_ownFleet!, isolated: false);
      }
      fleet = _ownFleet;
    }
    final Widget painted = CustomPaint(
      foregroundPainter: widget.enabled ? _ChartPainter(context, fleet!, _repaint, labelStyle: widget.labelStyle) : null,
      child: widget.child,
    );
    return _ownFleet == null ? painted : HarborFleetScope(fleet: _ownFleet!, child: painted);
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.context, this.fleet, final Listenable repaint, {final TextStyle? labelStyle})
    : labelStyle = _labelStyle.merge(labelStyle),
      super(repaint: repaint);

  static const TextStyle _labelStyle = TextStyle(fontSize: 9, color: Color(0xFFFFFFFF), backgroundColor: Color(0x99000000));

  final BuildContext context;
  final HarborFleet fleet;
  final TextStyle labelStyle;

  @override
  void paint(final Canvas canvas, final Size size) {
    final RenderObject? self = context.findRenderObject();
    if (self is! RenderBox || !self.attached) {
      return;
    }
    // Global rects mapped into this overlay's own coordinates, so a scale
    // between the overlay and the screen (a preview, a scale model) is honored.
    Rect local(final Rect global) => Rect.fromPoints(self.globalToLocal(global.topLeft), self.globalToLocal(global.bottomRight));
    for (final HarborChartEntry entry in HarborChart.snapshotOf(fleet)) {
      final Rect clear = local(entry.clearWater);
      canvas.drawRect(
        clear.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xCCFFD54F),
      );
      for (final HarborDockRecord dock in entry.docks) {
        final Rect r = local(dock.rect);
        final Color color = dock.kind == HarborDockKind.pier ? const Color(0x5526C6DA) : const Color(0x55E0B070);
        canvas.drawRect(r, Paint()..color = color);
        canvas.drawRect(
          r.deflate(0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color.withValues(alpha: 1.0),
        );
        final TextPainter label = TextPainter(
          text: TextSpan(
            text: '${dock.label ?? dock.kind.name} ${dock.extent.toStringAsFixed(0)}',
            style: labelStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, r.topLeft + const Offset(2, 2));
      }
      if (entry.tide > 0) {
        final Rect frame = local(entry.frame);
        canvas.drawRect(
          Rect.fromLTRB(frame.left, frame.bottom - entry.tide, frame.right, frame.bottom),
          Paint()..color = const Color(0x332196F3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(final _ChartPainter oldDelegate) => true;
}
