import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../art/palette.dart';
import 'package:harbor/harbor.dart';

import 'harbor_scene.dart';
import 'narration.dart';
import 'phone.dart';
import 'plates.dart';
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
                    SizedBox(width: _sceneWidth, child: ClipRect(child: _Left(time: t))),
                    Expanded(
                      child: CustomPaint(
                        key: _stage,
                        foregroundPainter: _OutlinePainter(t, _parts, _stage),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: _onTv(t)
                                ? _TvSet(time: t)
                                : FittedBox(child: _Bezel(child: ShowcasePhone(time: t, parts: _parts))),
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

/// Whether the device on the right is a television: for the scale model, and for the coast's
/// line about a television's title-safe band.
bool _onTv(final double t) {
  final ShowcaseChapter chapter = ShowcaseTimeline.chapterAt(t);
  if (chapter.key == 'tv') {
    return true;
  }
  final List<NarrationLine> coast = Narration.of('coast');
  return chapter.key == 'coast' && coast.length > 1 && t >= coast[1].start - 0.3;
}

/// The left half: the panorama for the chapters it was drawn for, the field guide's plate for the
/// rest, dissolving from one to the next as a chapter starts.
class _Left extends StatelessWidget {
  const _Left({required this.time});

  final double time;

  static Widget _for(final ShowcaseChapter chapter, final double t) =>
      ShowcasePlate.shows(chapter) ? ShowcasePlate(chapter: chapter, time: t) : HarborScene(time: t);

  @override
  Widget build(final BuildContext context) {
    final List<ShowcaseChapter> chapters = ShowcaseTimeline.chapters;
    final ShowcaseChapter now = ShowcaseTimeline.chapterAt(time);
    final int index = chapters.indexOf(now);
    final double fade = ShowcaseTimeline.ease(time, now.start, now.start + 0.5);
    if (index <= 0 || fade >= 1 || ShowcasePlate.shows(now) == ShowcasePlate.shows(chapters[index - 1]) && !ShowcasePlate.shows(now)) {
      return _for(now, time);
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _for(chapters[index - 1], time),
        Opacity(opacity: fade, child: _for(now, time)),
      ],
    );
  }
}

/// A television running a harbor in a scale model: laid out on a 1200 × 675 reference screen,
/// scaled to the set, with the title-safe band as its coast.
class _TvSet extends StatelessWidget {
  const _TvSet({required this.time});

  final double time;

  static const Size _screen = Size(480, 270);

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF15181C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3F45), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox.fromSize(
            size: _screen,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: _screen,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
              ),
              child: Theme(
                data: ThemeData(useMaterial3: true, colorSchemeSeed: Palette.shallows, fontFamily: 'Georgia'),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    const HarborScaleModel(
                      referenceSize: Size(1200, 675),
                      coast: HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
                      child: HarborSea(child: _TvPage()),
                    ),
                    // The title-safe band, marked as a broadcast monitor marks it.
                    IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: _screen.width * 0.05, vertical: _screen.height * 0.05),
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: Border.all(color: Palette.brass.withValues(alpha: 0.9), width: 2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Container(width: 120, height: 14, color: const Color(0xFF2A2F35)),
      Container(width: 220, height: 8, decoration: BoxDecoration(color: const Color(0xFF2A2F35), borderRadius: BorderRadius.circular(4))),
      const SizedBox(height: 14),
      const Text('title-safe', style: TextStyle(fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w700, color: Palette.brass)),
    ],
  );
}

class _TvPage extends StatelessWidget {
  const _TvPage();

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF0E2233),
    child: Harbor(
      top: const <HarborDock>[
        HarborDock.quay(
          backdrop: ColoredBox(color: Color(0xFF0E2233)),
          // On the mooring line, which on a television keeps to the title-safe band.
          child: HarborMooringLine(
            child: SizedBox(
              height: 90,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('Harbor TV', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: Palette.brass)),
              ),
            ),
          ),
        ),
      ],
      body: HarborMoored(
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (int i = 0; i < 8; i++)
              Container(
                decoration: BoxDecoration(color: showcaseBoats[i].$4, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Icon(showcaseBoats[i].$3, color: Colors.white, size: 64),
              ),
          ],
        ),
      ),
    ),
  );
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

/// The caption: the harbor word, and the line the narrator is saying, word for word.
///
/// Lines swap at once as each is spoken, with no fade or scroll: the eye belongs on the harbor and
/// the phone, and someone watching without sound reads exactly what is being said.
class _Caption extends StatelessWidget {
  const _Caption({required this.time});

  final double time;

  @override
  Widget build(final BuildContext context) {
    final ShowcaseChapter chapter = ShowcaseTimeline.chapterAt(time);
    final bool install = chapter == ShowcaseTimeline.outro;
    return ColoredBox(
      color: Palette.deepSea,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // How the word is pronounced, for the words whose spelling does not tell you.
                  if (chapter.pronounced case final String pronounced)
                    Text(pronounced, style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontStyle: FontStyle.italic, color: Palette.foam.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(width: 28),
              Container(width: 2, height: 52, color: Palette.brass.withValues(alpha: 0.5)),
              const SizedBox(width: 28),
              Expanded(
                child: Text(
                  ShowcaseTimeline.lineAt(time),
                  key: const ValueKey<String>('caption line'),
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, height: 1.2, color: Palette.foam),
                ),
              ),
            ],
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
    // On the television the phone is not in the tree, and its parts' keys point at nothing.
    if (_onTv(t)) {
      return const <_Outline>[];
    }
    switch (ShowcaseTimeline.chapterAt(t).key) {
      case 'sea':
        return const <_Outline>[(part: PhonePart.screen, label: 'HarborSea', left: true, covered: false)];
      case 'coast':
        return const <_Outline>[
          (part: PhonePart.statusBar, label: 'status bar', left: true, covered: false),
          (part: PhonePart.homeIndicator, label: 'home\nindicator', left: true, covered: false),
        ];
      case 'wake':
        return const <_Outline>[(part: PhonePart.header, label: 'wake\nunder it', left: true, covered: false)];
    }
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
