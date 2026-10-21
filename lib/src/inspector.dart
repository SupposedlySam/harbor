import 'dart:convert';
import 'dart:math' as math;
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bar.dart';
import 'controller.dart';
import 'clear.dart';
import 'edge.dart';
import 'frame.dart';
import 'room.dart';
import 'scroll_view.dart';

/// One frame in the inspector, in global coordinates.
@immutable
class HarborInspectorEntry {
  const HarborInspectorEntry({
    required this.label,
    required this.depth,
    required this.frame,
    required this.body,
    required this.room,
    required this.bars,
    required this.obstruction,
    required this.keyboard,
    this.isolated = false,
    this.consumers = const <HarborConsumerRecord>[],
  });

  final String label;

  /// How many frames this one sits inside.
  final int depth;
  final Rect frame;
  final Rect body;
  final Rect room;

  final List<HarborBarRecord> bars;

  final EdgeInsetsDirectional obstruction;
  final double keyboard;

  /// Whether this frame is under an isolated root: a `HarborRoot` mounted
  /// inside another frame (a phone drawn inside a page, a preview), which
  /// keeps a frame registry, a keyboard gauge and toasts of its own. Its
  /// [depth] counts from that root, not from the app's, and its rects are in
  /// global coordinates like every other frame's.
  final bool isolated;

  /// The widgets beneath this frame that took an inset out of what lies beneath them, one record
  /// per edge each handled, outermost first: [HarborClear] (and [HarborClear.rowInsets]),
  /// [HarborScrollView]'s two ends, [HarborSliverClear], a [HarborSliverBar] that takes the status
  /// bar, [HarborHandled], and a [HarborFrame] nested in a frame's body whose bars took its system
  /// edges. An edge cleared twice has two records on it, and a consumer that found its edge already
  /// cleared has one with an amount of zero.
  ///
  /// Collected in debug and profile builds; empty in release, where nothing reads it. A frame
  /// right under a [HarborRoot] (a route's page) is not nested, so the root lists none.
  final List<HarborConsumerRecord> consumers;

  /// [consumers] on [edge], outermost first.
  List<HarborConsumerRecord> consumersOn(final HarborEdge edge) => <HarborConsumerRecord>[
    for (final HarborConsumerRecord c in consumers)
      if (c.edge == edge) c,
  ];

  /// This entry as JSON, as `ext.harbor.inspector` serves it.
  Map<String, Object?> toJson() => <String, Object?>{
    'label': label,
    'depth': depth,
    'isolated': isolated,
    'frame': _rect(frame),
    'body': _rect(body),
    'room': _rect(room),
    'keyboard': keyboard,
    'obstruction': <String, double>{
      for (final HarborEdge e in HarborEdge.values) e.name: HarborEdges.of(obstruction, e),
    },
    'bars': <Map<String, Object?>>[
      for (final HarborBarRecord d in bars)
        <String, Object?>{
          'label': d.label,
          'edge': d.edge.name,
          'kind': d.kind.name,
          'state': d.state.name,
          'keyboard': d.keyboard.name,
          'extent': d.extent,
          'restingExtent': d.restingExtent,
          'rect': _rect(d.rect),
        },
    ],
    'consumers': <Map<String, Object?>>[
      for (final HarborConsumerRecord c in consumers)
        <String, Object?>{
          'type': c.type,
          'label': c.label,
          'key': c.key,
          'edge': c.edge.name,
          'amount': c.amount,
          'rect': _rect(c.rect),
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

/// The inspector: who holds which edge, at which layer, in every frame in a
/// view. A debug overlay and a snapshot API, unrelated to Flutter's

/// `WidgetInspector`.
abstract final class HarborInspector {
  /// Every frame in [context]'s view, outermost first, from its last layout.
  static List<HarborInspectorEntry> snapshot(final BuildContext context) {
    final HarborFrameRegistry? registry = HarborFrameRegistryScope.maybeOf(context);
    return registry == null ? const <HarborInspectorEntry>[] : snapshotOf(registry);
  }

  /// Every frame in [registry], outermost first, from its last layout.
  static List<HarborInspectorEntry> snapshotOf(final HarborFrameRegistry registry) => <HarborInspectorEntry>[
    for (final HarborController frame in registry.frames)
      if (_entryOf(frame) case final HarborInspectorEntry entry) entry,
  ];

  /// Every frame of every live root, with no context: for tooling (a debug
  /// panel, a log, an automation driver) that runs outside the widget tree.
  ///
  /// Roots are listed in the order they were mounted, each outermost first, as
  /// [snapshot] lists one. A root mounted inside another frame (a phone drawn
  /// in a page) is listed too, with [HarborInspectorEntry.isolated] set on each of
  /// its frames. A root that has been disposed is gone from the list, and a
  /// frame that has not laid out yet is not in it.
  static List<HarborInspectorEntry> snapshotAll() => <HarborInspectorEntry>[
    for (final HarborFrameRegistry registry in _registries.keys) ...snapshotOf(registry),
  ];

  /// The frame nearest [context], as [snapshot] has it: in global
  /// coordinates, from its last layout. Null when there is no frame above
  /// [context] or it has not laid out yet.
  ///
  /// This is how a test or a tool reads a frame's rect, room and bars, as
  /// `flutter_test` reads a widget's place through its render object.
  static HarborInspectorEntry? nearest(final BuildContext context) {
    final HarborController? frame = HarborController.maybeOf(context);
    return frame == null ? null : _entryOf(frame);
  }

  static HarborInspectorEntry? _entryOf(final HarborController frame) {
    final RenderBox? box = frame.layoutBox;
    final HarborLayoutRecord? layout = frame.layoutRecord;
    if (box == null || layout == null || !box.attached || !box.hasSize) {
      return null;
    }
    final Matrix4 toGlobal = box.getTransformTo(null);
    Rect global(final Rect r) => MatrixUtils.transformRect(toGlobal, r);
    int depth = 0;
    for (HarborController? p = frame.parent; p != null; p = p.parent) {
      depth++;
    }
    return HarborInspectorEntry(
      label: frame.debugLabel ?? 'harbor',
      depth: depth,
      isolated: _registries[frame.registry] ?? false,
      frame: global(layout.frame),
      body: global(layout.body),
      room: global(layout.room),
      bars: <HarborBarRecord>[
        for (final HarborBarRecord d in layout.bars)
          HarborBarRecord(
            edge: d.edge,
            kind: d.kind,
            rect: global(d.rect),
            extent: d.extent,
            restingExtent: d.restingExtent,
            state: d.state,
            keyboard: d.keyboard,
            label: d.label,
          ),
      ],
      obstruction: layout.obstruction,
      keyboard: layout.keyboard,
      consumers: _consumersOf(frame),
    );
  }

  static List<HarborConsumerRecord> _consumersOf(final HarborController frame) {
    if (frame.consumers.isEmpty) {
      return const <HarborConsumerRecord>[];
    }
    // Outermost first; siblings (the rows of a list) keep the order they were built in.
    final List<(int, HarborConsumerSource)> sources = <(int, HarborConsumerSource)>[
      for (final HarborConsumerSource source in frame.consumers) (source.depth, source),
    ];
    mergeSort(
      sources,
      compare: (final (int, HarborConsumerSource) a, final (int, HarborConsumerSource) b) => a.$1 - b.$1,
    );
    final List<HarborConsumerRecord> records = <HarborConsumerRecord>[];
    for (final (int, HarborConsumerSource) source in sources) {
      source.$2.collect(records);
    }
    return records;
  }

  /// The frame registries of the live roots, in the order they were mounted,
  /// and whether each is isolated.
  static final Map<HarborFrameRegistry, bool> _registries = <HarborFrameRegistry, bool>{};
  static bool _registered = false;

  /// Lists [registry] among the live roots while its root is mounted. Called
  /// by the frame that makes a registry; [unregister] it when that frame goes.
  @internal
  static void register(final HarborFrameRegistry registry, {required final bool isolated}) {
    _registries[registry] = isolated;
    _registerExtension();
  }

  /// Takes [registry] off the list of live roots.
  @internal
  static void unregister(final HarborFrameRegistry registry) => _registries.remove(registry);

  /// Serves the inspector over the VM service as `ext.harbor.inspector`, so a tool driving the app
  /// can ask where everything is, and lists [registry] on it.
  /// Debug and profile only.
  ///
  /// Every root is served already: a frame that makes a registry lists it while
  /// it is mounted. A registry served by hand stays listed. The extension answers
  /// `{"frames": [...]}` for every root that is not isolated, and with the
  /// parameter `isolated=true` for isolated roots too (see [snapshotAll]).
  static void serve(final HarborFrameRegistry registry) {
    _registries.putIfAbsent(registry, () => false);
    _registerExtension();
  }

  static void _registerExtension() {
    if (_registered || kReleaseMode) {
      return;
    }
    _registered = true;
    try {
      developer.registerExtension('ext.harbor.inspector', (
        final String method,
        final Map<String, String> params,
      ) async {
        final bool withIsolated = params['isolated'] == 'true';
        final List<Map<String, Object?>> json = <Map<String, Object?>>[
          for (final HarborInspectorEntry e in snapshotAll())
            if (withIsolated || !e.isolated) e.toJson(),
        ];
        return developer.ServiceExtensionResponse.result(jsonEncode(<String, Object?>{'frames': json}));
      });
    } on Object {
      // Already registered in this isolate.
    }
  }
}

/// Draws the inspector over [child]: every bar's space (overlay bars in teal,
/// solid bars in sand), each frame's room outlined, and the keyboard in blue.
/// Inside each room, a line on each edge names the widgets that took an inset out of what lies
/// beneath them there and how much ([HarborInspectorEntry.consumers]): `top: HarborScrollView
/// "inbox" 103`, alike ones grouped (`start: HarborClear.rowInsets ×12 16`) and those that took
/// nothing left out.
///
/// See also:
///
///  * `debugPaintSizeEnabled`, the closest Flutter debug paint, which draws every box rather than who
///    holds each edge.
class HarborInspectorOverlay extends StatefulWidget {
  const HarborInspectorOverlay({
    super.key,
    this.enabled = true,
    this.showsConsumers = true,
    this.labelStyle,
    required this.child,
  });

  final bool enabled;

  /// Whether each room carries its lines of consumers, one per edge.
  final bool showsConsumers;

  /// Merged over the bar labels' own style (9 pt, white on a dark band).
  ///
  /// Set a `fontFamily` the test has loaded to make the labels readable in
  /// widget tests and goldens: with none, `flutter_test` draws them in its box
  /// test font, and the labels carry each bar's extent.
  final TextStyle? labelStyle;

  final Widget child;

  @override
  State<HarborInspectorOverlay> createState() => _HarborInspectorOverlayState();

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
    properties.add(FlagProperty('showsConsumers', value: showsConsumers, ifFalse: 'consumers not shown'));
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle, defaultValue: null));
  }
}

class _HarborInspectorOverlayState extends State<HarborInspectorOverlay> with SingleTickerProviderStateMixin {
  /// The registry the frames beneath join, when this overlay sits above the
  /// outermost frame (as it does in `MaterialApp.builder`).
  HarborFrameRegistry? _ownRegistry;

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
  void didUpdateWidget(final HarborInspectorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_ticker.isActive) {
      _ticker.start();
    } else if (!widget.enabled && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    if (_ownRegistry case final HarborFrameRegistry registry) {
      HarborInspector.unregister(registry);
    }
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    HarborFrameRegistry? registry = HarborFrameRegistryScope.maybeOf(context);
    if (registry == null) {
      if (_ownRegistry == null) {
        _ownRegistry = HarborFrameRegistry();
        HarborInspector.register(_ownRegistry!, isolated: false);
      }
      registry = _ownRegistry;
    }
    final Widget painted = CustomPaint(
      foregroundPainter: widget.enabled
          ? _InspectorPainter(
              context,
              registry!,
              _repaint,
              labelStyle: widget.labelStyle,
              showsConsumers: widget.showsConsumers,
            )
          : null,
      child: widget.child,
    );
    return _ownRegistry == null ? painted : HarborFrameRegistryScope(registry: _ownRegistry!, child: painted);
  }
}

class _InspectorPainter extends CustomPainter {
  _InspectorPainter(
    this.context,
    this.registry,
    final Listenable repaint, {
    final TextStyle? labelStyle,
    required this.showsConsumers,
  }) : labelStyle = _labelStyle.merge(labelStyle),
       super(repaint: repaint);

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 9,
    color: Color(0xFFFFFFFF),
    backgroundColor: Color(0x99000000),
  );

  final BuildContext context;
  final HarborFrameRegistry registry;
  final TextStyle labelStyle;
  final bool showsConsumers;

  @override
  void paint(final Canvas canvas, final Size size) {
    final RenderObject? self = context.findRenderObject();
    if (self is! RenderBox || !self.attached) {
      return;
    }
    // Global rects mapped into this overlay's own coordinates, so a scale
    // between the overlay and the screen (a preview, a scaled screen) is honored.
    Rect local(final Rect global) =>
        Rect.fromPoints(self.globalToLocal(global.topLeft), self.globalToLocal(global.bottomRight));
    final TextDirection direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
    // Every label drawn so far, so a consumer line never lands on a bar's label.
    final List<Rect> drawn = <Rect>[];
    final List<HarborInspectorEntry> entries = HarborInspector.snapshotOf(registry);
    for (final HarborInspectorEntry entry in entries) {
      final Rect clear = local(entry.room);
      canvas.drawRect(
        clear.deflate(1),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xCCFFD54F),
      );
      for (final HarborBarRecord bar in entry.bars) {
        final Rect r = local(bar.rect);
        final Color color = bar.kind == HarborBarKind.overlay ? const Color(0x5526C6DA) : const Color(0x55E0B070);
        canvas.drawRect(r, Paint()..color = color);
        canvas.drawRect(
          r.deflate(0.5),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color.withValues(alpha: 1.0),
        );
        final TextPainter label = TextPainter(
          text: TextSpan(text: '${bar.label ?? bar.kind.name} ${bar.extent.toStringAsFixed(0)}', style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(canvas, r.topLeft + const Offset(2, 2));
        drawn.add((r.topLeft + const Offset(2, 2)) & label.size);
      }
      if (showsConsumers) {
        for (final HarborEdge edge in HarborEdge.values) {
          if (debugHarborConsumerLine(entry, edge) case final String line) {
            _paintConsumerLine(canvas, line, edge, clear, direction, drawn);
          }
        }
      }
      if (entry.keyboard > 0) {
        final Rect frame = local(entry.frame);
        canvas.drawRect(
          Rect.fromLTRB(frame.left, frame.bottom - entry.keyboard, frame.right, frame.bottom),
          Paint()..color = const Color(0x332196F3),
        );
      }
    }
  }

  // [line] inside [room] against [edge]: along the top or the bottom, or halfway down a side,
  // moved inward past any label already drawn where it would go.
  void _paintConsumerLine(
    final Canvas canvas,
    final String line,
    final HarborEdge edge,
    final Rect room,
    final TextDirection direction,
    final List<Rect> drawn,
  ) {
    final bool left = switch (edge) {
      HarborEdge.start => direction == TextDirection.ltr,
      HarborEdge.end => direction == TextDirection.rtl,
      HarborEdge.top || HarborEdge.bottom => true,
    };
    final double maxWidth = math.max(0.0, (edge.isVertical ? room.width : room.width / 2) - 4);
    final TextPainter painter = TextPainter(
      text: TextSpan(text: line, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final Size size = painter.size;
    Offset at = switch (edge) {
      HarborEdge.top => room.topLeft + const Offset(2, 2),
      HarborEdge.bottom => room.bottomLeft + Offset(2, -2 - size.height),
      _ => Offset(left ? room.left + 2 : room.right - 2 - size.width, room.center.dy - size.height / 2),
    };
    // Inward: down from the top, up from the bottom, and down along a side.
    for (int i = 0; i < drawn.length; i++) {
      final Rect other = drawn[i];
      if (!(at & size).overlaps(other)) {
        continue;
      }
      at = edge == HarborEdge.bottom ? Offset(at.dx, other.top - size.height) : Offset(at.dx, other.bottom);
      i = -1;
    }
    painter.paint(canvas, at);
    drawn.add(at & size);
  }

  @override
  bool shouldRepaint(final _InspectorPainter oldDelegate) => true;
}

/// The overlay's line for [edge] of [entry]: each consumer on that edge that took something, by
/// type, label and amount, alike ones grouped; null when none took anything.
@visibleForTesting
String? debugHarborConsumerLine(final HarborInspectorEntry entry, final HarborEdge edge) {
  final Map<String, int> counts = <String, int>{};
  for (final HarborConsumerRecord c in entry.consumers) {
    if (c.edge != edge || c.amount.round() == 0) {
      continue;
    }
    final String name = <String>[
      c.type,
      if (c.label case final String label) '"$label"',
      c.amount.toStringAsFixed(0),
    ].join(' ');
    counts[name] = (counts[name] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return null;
  }
  final String consumers = <String>[
    for (final MapEntry<String, int> e in counts.entries)
      if (e.value == 1) e.key else e.key.replaceFirst(RegExp(r' (?=\S+$)'), ' ×${e.value} '),
  ].join(' · ');
  return '${edge.name}: $consumers';
}
