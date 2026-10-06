import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves every screenshot the play-through takes to `PLAY_SHOTS` (or `build/play`).
Future<void> main() => integrationDriver(
  onScreenshot: (final String name, final List<int> bytes, [final Map<String, Object?>? args]) async {
    final String dir = Platform.environment['PLAY_SHOTS'] ?? 'build/play';
    final File file = File('$dir/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
