// Records the README showcase frame by frame. Skipped unless SHOWCASE_OUT names a directory;
// tool/render_showcase.sh sets it and turns the frames into the video.
//
//   SHOWCASE_OUT=build/showcase                  every frame, at SHOWCASE_FPS (default 30)
//   SHOWCASE_OUT=build/showcase SHOWCASE_AT=5,20  only the stills at those seconds
//
// The clock is the test's own, stepped one frame at a time, so dock animations inside the real
// harbor run in step with the timeline and every recording is identical.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harbor_example/showcase/showcase.dart';
import 'package:harbor_example/showcase/timeline.dart';

final String? _out = Platform.environment['SHOWCASE_OUT'];

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
            builder: (final BuildContext context, final double t, final Widget? _) => HarborShowcase(time: t),
          ),
        ),
      ),
    );

    final Duration step = Duration(microseconds: 1000000 ~/ fps);
    final int frames = (ShowcaseTimeline.duration * fps).floor();
    for (int i = 0; i < frames; i++) {
      final double t = i / fps;
      time.value = t;
      // Two pumps: the first lays out at the new time, the second lets the list follow the
      // timeline after that layout, as it does one frame later in the running app.
      await tester.pump(step);
      await tester.pump();
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
  }, skip: _out == null);
}
