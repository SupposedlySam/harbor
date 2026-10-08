// Which sources the README video was rendered from, so a test can tell when it is stale.
//
// Found the hard way: the showcase's captions and a pronunciation sign were committed with the
// video left as it was, and the stale video was what got shown. Code and video each looked fine
// alone; nothing compared them. The recorder writes this stamp beside the video, and
// test/showcase_media_test.dart recomputes it and fails when they disagree.
//
// WHAT IT COVERS, in two parts:
//   own       lib/showcase/: the showcase's code, script and timings. A change here without a
//             re-render FAILS, since only the showcase's owner edits these, and re-rendering is
//             part of finishing that change.
//   borrowed  what the showcase draws with but does not own: the palette, the stage and scenery
//             art, and the field guide's drawings and entries (the plates). A change here is
//             REPORTED, not failed: those files belong to other work, much of it pull requests
//             that cannot re-render the video (that needs macOS, Kass and whisper), and a stale
//             plate must never block them (Jonah, 2026-10-08: the video must not block anything).
//             The owner re-renders afterwards.
// WHAT IT DOES NOT: harbor's lib/ (the phone runs the real package). Including it would demand a
// re-render on every library change, most of which move nothing in the video; a change that does
// should be re-rendered by hand, and the reason this is a floor rather than a guarantee is said here.

import 'dart:io';

/// The showcase's own sources, relative to example/: a change without a re-render fails.
List<File> showcaseSources(final String example) =>
    Directory('$example/lib/showcase').listSync().whereType<File>().toList()..sort(_byPath);

/// What the showcase draws with but does not own: a change is reported, not failed.
List<File> borrowedSources(final String example) => <File>[
  File('$example/lib/art/palette.dart'),
  File('$example/lib/field_guide/stage.dart'),
  File('$example/lib/field_guide/entry.dart'),
  ...Directory('$example/lib/field_guide/art').listSync().whereType<File>(),
  ...Directory('$example/lib/field_guide').listSync().whereType<File>().where((final File f) => f.path.contains('/entries_')),
]..sort(_byPath);

int _byPath(final File a, final File b) => a.path.compareTo(b.path);

/// FNV-1a over every file's name and bytes: no dependency, and the same on every machine.
String stampOf(final String example, final List<File> files) {
  int hash = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  void add(final List<int> bytes) {
    for (final int b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
  }

  for (final File file in files) {
    add(file.path.substring(example.length).codeUnits);
    add(file.readAsBytesSync());
  }
  // Two halves, since a 64-bit int is signed on the VM and toUnsigned(64) leaves it so.
  return (hash >>> 32).toRadixString(16).padLeft(8, '0') + (hash & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
}

/// The stamp file's content for the sources as they are now.
String showcaseStamp(final String example) =>
    'own ${stampOf(example, showcaseSources(example))}\nborrowed ${stampOf(example, borrowedSources(example))}';

/// One part of a stamp file's content, or null when it has no such line.
String? stampPart(final String stamp, final String part) {
  for (final String line in stamp.split('\n')) {
    if (line.startsWith('$part ')) {
      return line.substring(part.length + 1).trim();
    }
  }
  return null;
}

/// Where the stamp of the committed video lives.
File stampFile(final String example) => File('$example/../doc/media/showcase.stamp');
