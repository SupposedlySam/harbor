// The committed README video must have been rendered from the showcase as it is now.
// Breaks if: the showcase's own code or script changed and tool/render_showcase.sh was not re-run.
// Reports, without failing, a change to what the showcase borrows (see showcase_stamp.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'showcase_stamp.dart';

void main() {
  test('the README video was rendered from the current showcase', () {
    final String example = Directory.current.path;
    final File stamp = stampFile(example);
    expect(stamp.existsSync(), isTrue, reason: 'no stamp beside the video: run example/tool/render_showcase.sh');
    expect(showcaseSources(example).length, greaterThan(5), reason: 'positive control: the showcase sources were found');
    expect(borrowedSources(example).length, greaterThan(10), reason: 'positive control: the borrowed sources were found');
    final String committed = stamp.readAsStringSync();
    final String now = showcaseStamp(example);
    expect(
      stampPart(committed, 'own'),
      stampPart(now, 'own'),
      reason: 'the showcase changed since the video was rendered: run example/tool/render_showcase.sh and commit doc/media',
    );
    if (stampPart(committed, 'borrowed') != stampPart(now, 'borrowed')) {
      // Reported, never failed: these files belong to other work (see showcase_stamp.dart).
      // ignore: avoid_print
      print('NOTE: art or field guide entries the README video draws on changed since it was rendered; '
          're-render with example/tool/render_showcase.sh when convenient.');
    }
  });
}
