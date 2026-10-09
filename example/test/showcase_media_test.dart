// The committed README video must have been rendered from the showcase as it is now.
// Breaks if: the showcase's own code or script changed and tool/render_showcase.sh was not re-run.
// Reports, without failing, a change to what the showcase borrows (see showcase_stamp.dart).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'showcase_stamp.dart';

void main() {
  for (final ShowcaseCut cut in ShowcaseCut.values) {
    test('the README ${cut.name} video was rendered from its current sources', () {
      final String example = Directory.current.path;
      final File stamp = stampFile(example, cut);
      expect(stamp.existsSync(), isTrue, reason: 'no stamp beside the video: run example/tool/render_showcase.sh ${cut.directory}');
      expect(showcaseSources(example, cut).length, greaterThan(5), reason: 'positive control: the video\'s sources were found');
      expect(borrowedSources(example).length, greaterThan(10), reason: 'positive control: the borrowed sources were found');
      // The README links the video through jsDelivr, which serves it as video/mp4 so a browser
      // plays it instead of downloading it (GitHub's raw link is application/octet-stream).
      // jsDelivr will not serve a file over 20 MB from a GitHub repo, so a bigger render would
      // turn the README's link into an error.
      final File video = File('$example/../doc/media/${cut.directory}.mp4');
      expect(video.existsSync(), isTrue, reason: 'no doc/media/${cut.directory}.mp4');
      expect(video.lengthSync(), lessThan(20 * 1000 * 1000), reason: 'jsDelivr serves files under 20 MB; raise -crf in render_showcase.sh');
      final String committed = stamp.readAsStringSync();
      final String now = showcaseStamp(example, cut);
      expect(
        stampPart(committed, 'own'),
        stampPart(now, 'own'),
        reason: 'the ${cut.name} video\'s sources changed since it was rendered: run example/tool/render_showcase.sh ${cut.directory} and commit doc/media',
      );
      if (stampPart(committed, 'borrowed') != stampPart(now, 'borrowed')) {
        // Reported, never failed: these files belong to other work (see showcase_stamp.dart).
        // ignore: avoid_print
        print('NOTE: art or field guide entries the README ${cut.name} video draws on changed since it was rendered; '
            're-render with example/tool/render_showcase.sh ${cut.directory} when convenient.');
      }
    });
  }
}
