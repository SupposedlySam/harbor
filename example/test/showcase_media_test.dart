// The committed README video must have been rendered from the showcase as it is now.
// Breaks if: the showcase's code or script changed and tool/render_showcase.sh was not re-run.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'showcase_stamp.dart';

void main() {
  test('the README video was rendered from the current showcase', () {
    final String example = Directory.current.path;
    final File stamp = stampFile(example);
    expect(stamp.existsSync(), isTrue, reason: 'no stamp beside the video: run example/tool/render_showcase.sh');
    expect(showcaseSources(example).length, greaterThan(5), reason: 'positive control: the sources were found');
    expect(
      stamp.readAsStringSync().trim(),
      showcaseStamp(example),
      reason: 'the showcase changed since the video was rendered: run example/tool/render_showcase.sh and commit doc/media',
    );
  });
}
