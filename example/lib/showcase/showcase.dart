import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import 'harbor_scene.dart';
import 'phone.dart';
import 'timeline.dart';

/// The README's showcase: an illustrated harbor beside a phone running the real thing, one clock
/// driving both. Laid out at a fixed 1280 × 720 and scaled to fit, so a recording and the app
/// show the same picture.
class HarborShowcase extends StatefulWidget {
  const HarborShowcase({super.key, required this.time});

  /// Seconds into the showcase, from 0 to [ShowcaseTimeline.duration].
  final double time;

  static const Size frame = Size(1280, 720);

  @override
  State<HarborShowcase> createState() => _HarborShowcaseState();
}

class _HarborShowcaseState extends State<HarborShowcase> {
  final Map<PhonePart, GlobalKey> _parts = <PhonePart, GlobalKey>{for (final PhonePart p in PhonePart.values) p: GlobalKey(debugLabel: p.name)};
  final GlobalKey _stage = GlobalKey(debugLabel: 'stage');

  static const double _captionHeight = 112;
  static const double _sceneWidth = 760;

  @override
  Widget build(final BuildContext context) {
    final double t = widget.time;
    return FittedBox(
      child: SizedBox.fromSize(
        size: HarborShowcase.frame,
        child: Material(
          color: Palette.night,
          child: Column(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    SizedBox(width: _sceneWidth, child: ClipRect(child: HarborScene(time: t))),
                    Expanded(
                      child: CustomPaint(
                        key: _stage,
                        foregroundPainter: _OutlinePainter(t, _parts, _stage),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: FittedBox(child: _Bezel(child: ShowcasePhone(time: t, parts: _parts))),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: _captionHeight, child: _Caption(time: t)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bezel extends StatelessWidget {
  const _Bezel({required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFF15181C),
      borderRadius: BorderRadius.circular(66),
      border: Border.all(color: const Color(0xFF3A3F45), width: 3),
    ),
    child: Padding(padding: const EdgeInsets.all(12), child: child),
  );
}

/// The caption: the harbor word, and the plain word for it.
class _Caption extends StatelessWidget {
  const _Caption({required this.time});

  final double time;

  @override
  Widget build(final BuildContext context) {
    final ShowcaseChapter chapter = ShowcaseTimeline.chapterAt(time);
    // Fade in at the start of each chapter and out at its end, so captions never cut.
    final double opacity = ShowcaseTimeline.ease(time, chapter.start, chapter.start + 0.5) *
        (1 - ShowcaseTimeline.ease(time, chapter.end - 0.4, chapter.end));
    final bool install = chapter == ShowcaseTimeline.outro;
    return ColoredBox(
      color: Palette.deepSea,
      child: Opacity(
        opacity: chapter == ShowcaseTimeline.outro ? ShowcaseTimeline.ease(time, chapter.start, chapter.start + 0.5) : opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: <Widget>[
              Text(
                chapter.term,
                style: TextStyle(
                  fontFamily: install ? 'Menlo' : 'Georgia',
                  fontSize: install ? 34 : 46,
                  fontWeight: FontWeight.w700,
                  color: Palette.brass,
                ),
              ),
              const SizedBox(width: 28),
              Container(width: 2, height: 52, color: Palette.brass.withValues(alpha: 0.5)),
              const SizedBox(width: 28),
              Expanded(
                child: Text(chapter.meaning, style: const TextStyle(fontFamily: 'Georgia', fontSize: 26, height: 1.25, color: Palette.foam)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One outline on the phone: which part, what to call it, which side its tag sits on, and
/// whether it is dashed because something covers it.
typedef _Outline = ({PhonePart part, String label, bool left, bool covered});

/// Outlines the parts of the phone the current chapter is about, wherever harbor laid them out.
/// Tags sit outside the phone with a leader line, so they never cover what they name.
class _OutlinePainter extends CustomPainter {
  _OutlinePainter(this.t, this.parts, this.stage);

  final double t;
  final Map<PhonePart, GlobalKey> parts;
  final GlobalKey stage;

  List<_Outline> get _lit {
    if (ShowcaseTimeline.pier.contains(t)) {
      return const <_Outline>[(part: PhonePart.header, label: 'header', left: true, covered: false)];
    }
    if (ShowcaseTimeline.quay.contains(t)) {
      return const <_Outline>[(part: PhonePart.tabBar, label: 'tab bar', left: true, covered: false)];
    }
    if (!ShowcaseTimeline.tide.contains(t)) {
      return const <_Outline>[];
    }
    final bool up = ShowcaseTimeline.keyboard(t) > 40;
    return <_Outline>[
      (part: PhonePart.composer, label: 'composer\nafloat', left: false, covered: false),
      // The tab bar is still laid out where it was: the keyboard covers it, as the tide covers a jetty on pilings.
      (part: PhonePart.tabBar, label: up ? 'tab bar\non pilings,\nunder it' : 'tab bar\non pilings', left: true, covered: up),
      if (up) (part: PhonePart.keyboard, label: 'keyboard', left: false, covered: false),
    ];
  }

  @override
  void paint(final Canvas canvas, final Size size) {
    final RenderObject? self = stage.currentContext?.findRenderObject();
    if (self is! RenderBox || !self.attached) {
      return;
    }
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Palette.brass;
    for (final _Outline outline in _lit) {
      final RenderObject? box = parts[outline.part]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize || box.size.height < 1) {
        continue;
      }
      final Rect rect = MatrixUtils.transformRect(box.getTransformTo(self), Offset.zero & box.size).inflate(3);
      final RRect outlineShape = RRect.fromRectAndRadius(rect, const Radius.circular(8));
      if (outline.covered) {
        _dashed(canvas, Path()..addRRect(outlineShape), stroke);
      } else {
        canvas.drawRRect(outlineShape, stroke);
      }
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: outline.label,
          style: const TextStyle(fontFamily: 'Georgia', fontSize: 15, height: 1.15, fontWeight: FontWeight.w700, color: Palette.night),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      final double width = text.width + 16;
      final double height = text.height + 10;
      final double x = outline.left ? 10 : size.width - 10 - width;
      final double y = (rect.center.dy - height / 2).clamp(8.0, size.height - height - 8);
      final Rect tag = Rect.fromLTWH(x, y, width, height);
      final Offset from = outline.left ? tag.centerRight : tag.centerLeft;
      final Offset to = Offset(outline.left ? rect.left : rect.right, rect.center.dy.clamp(rect.top + 6, rect.bottom - 6));
      canvas
        ..drawLine(from, to, Paint()
          ..color = Palette.brass
          ..strokeWidth = 2)
        ..drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(7)), Paint()..color = Palette.brass);
      text.paint(canvas, tag.topLeft + const Offset(8, 5));
    }
  }

  static void _dashed(final Canvas canvas, final Path path, final Paint paint) {
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(final _OutlinePainter oldDelegate) => true;
}
