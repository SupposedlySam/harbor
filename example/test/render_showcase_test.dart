// Records the README showcase frame by frame. Skipped unless SHOWCASE_OUT names a directory;
// tool/render_showcase.sh sets it and turns the frames into the video.
//
//   SHOWCASE_OUT=build/showcase                  every frame, at SHOWCASE_FPS (default 30)
//   SHOWCASE_OUT=build/showcase SHOWCASE_AT=5,20  only the stills at those seconds
//   SHOWCASE_CUT=showcase_wide                    the wide-format video instead of the phone tour
//
// The clock is the test's own, stepped one frame at a time, so dock animations inside the real
// harbor run in step with the timeline and every recording is identical.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_example/showcase/showcase.dart';
import 'package:harbor_example/showcase/timeline.dart';
import 'package:harbor_example/showcase_wide/timeline.dart';
import 'package:harbor_example/showcase_wide/wide.dart';

import 'showcase_stamp.dart';

final String? _out = Platform.environment['SHOWCASE_OUT'];

/// Which video: the phone tour unless SHOWCASE_CUT names the wide one.
final ShowcaseCut _cut = ShowcaseCut.values.firstWhere(
  (final ShowcaseCut cut) => cut.directory == (Platform.environment['SHOWCASE_CUT'] ?? 'showcase'),
  orElse: () => throw StateError('SHOWCASE_CUT must be one of ${ShowcaseCut.values.map((final ShowcaseCut c) => c.directory)}'),
);

double get _duration => _cut == ShowcaseCut.wide ? WideTimeline.duration : ShowcaseTimeline.duration;

Widget _video(final double t) => _cut == ShowcaseCut.wide ? WideShowcase(time: t) : HarborShowcase(time: t);

/// flutter_test draws text in a box font unless real fonts are loaded under the names used.
Future<void> _loadFonts() async {
  final String flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
  final Map<String, List<String>> families = <String, List<String>>{
    'Georgia': <String>[
      '/System/Library/Fonts/Supplemental/Georgia.ttf',
      '/System/Library/Fonts/Supplemental/Georgia Bold.ttf',
    ],
    'Menlo': <String>['/System/Library/Fonts/SFNSMono.ttf'],
    'Helvetica': <String>['$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf'],
    'MaterialIcons': <String>['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry<String, List<String>> family in families.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String path in family.value) {
      final File file = File(path);
      if (!file.existsSync()) {
        throw StateError('Font for ${family.key} not found at $path. The showcase is recorded on macOS with FLUTTER_ROOT set.');
      }
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await loader.load();
  }
}

void main() {
  testWidgets('record the showcase', (final WidgetTester tester) async {
    final Directory out = Directory(_out!)..createSync(recursive: true);
    final int fps = int.tryParse(Platform.environment['SHOWCASE_FPS'] ?? '') ?? 30;
    final List<double>? stills = Platform.environment['SHOWCASE_AT']?.split(',').map(double.parse).toList();

    await tester.runAsync(_loadFonts);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = HarborShowcase.frame;
    addTearDown(tester.view.reset);

    final GlobalKey boundary = GlobalKey();
    final ValueNotifier<double> time = ValueNotifier<double>(0);
    addTearDown(time.dispose);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: boundary,
          child: ValueListenableBuilder<double>(
            valueListenable: time,
            builder: (final BuildContext context, final double t, final Widget? _) => _video(t),
          ),
        ),
      ),
    );

    final Duration step = Duration(microseconds: 1000000 ~/ fps);
    final int frames = (_duration * fps).floor();
    for (int i = 0; i < frames; i++) {
      final double t = i / fps;
      // Two pumps: the first lays out half a frame early, the second at the frame's time, which
      // lets the list follow the timeline after a layout, as it does one frame later in the
      // running app. Never twice at one time: harbor's tide gauge takes a keyboard that holds
      // still for a frame as settled, and would mark a keyboard caught mid-rise as high water.
      time.value = math.max(0, t - 0.5 / fps);
      await tester.pump(step ~/ 2);
      time.value = t;
      await tester.pump(step ~/ 2);
      // Drawn in the real fonts here, so this is where a caption too long for its area is caught:
      // the video would show it cut off.
      final Finder caption = find.byKey(const ValueKey<String>('caption line'));
      if (caption.evaluate().isNotEmpty) {
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.descendant(of: caption, matching: find.byType(RichText)));
        expect(paragraph.didExceedMaxLines, isFalse, reason: 'caption cut off at ${t.toStringAsFixed(1)} s: ${tester.widget<Text>(caption).data}');
      }
      if (stills != null && !stills.any((final double s) => (s - t).abs() < 0.5 / fps)) {
        continue;
      }
      final RenderRepaintBoundary box = tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
      await tester.runAsync(() async {
        final ui.Image image = await box.toImage();
        final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final String name = stills != null ? 'still_${t.toStringAsFixed(1)}.png' : 'frame_${i.toString().padLeft(5, '0')}.png';
        File('${out.path}/$name').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    // Every frame rendered and every caption fitted: stamp the sources this video came from, so
    // test/showcase_media_test.dart can tell when the committed video goes stale. Stills are not a
    // video, so only a full recording stamps.
    if (stills == null) {
      stampFile(Directory.current.path, _cut).writeAsStringSync('${showcaseStamp(Directory.current.path, _cut)}\n');
    }
  }, skip: _out == null);
}
