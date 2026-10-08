// Which sources the README video was rendered from, so a test can tell when it is stale.
//
// Found the hard way: the showcase's captions and a pronunciation sign were committed with the
// video left as it was, and the stale video was what got shown. Code and video each looked fine
// alone; nothing compared them. The recorder writes this stamp beside the video, and
// test/showcase_media_test.dart recomputes it and fails when they disagree.
//
// WHAT IT COVERS: the showcase's own code and script, which decide what the video shows. WHAT IT
// DOES NOT: harbor's lib/ (the phone runs the real package). Including it would demand a re-render
// on every library change, most of which move nothing in the video; a change that does should be
// re-rendered by hand, and the reason this is a floor rather than a guarantee is said here.

import 'dart:io';

/// The files whose content decides what the video shows, relative to example/.
List<File> showcaseSources(final String example) {
  final List<File> files = <File>[
    ...Directory('$example/lib/showcase').listSync().whereType<File>(),
    File('$example/lib/art/palette.dart'),
    File('$example/lib/field_guide/art/scenery.dart'),
    File('$example/lib/field_guide/stage.dart'),
  ]..sort((final File a, final File b) => a.path.compareTo(b.path));
  return files;
}

/// FNV-1a over every source's name and bytes: no dependency, and the same on every machine.
String showcaseStamp(final String example) {
  int hash = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  void add(final List<int> bytes) {
    for (final int b in bytes) {
      hash ^= b;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
  }

  for (final File file in showcaseSources(example)) {
    add(file.path.substring(example.length).codeUnits);
    add(file.readAsBytesSync());
  }
  return hash.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

/// Where the stamp of the committed video lives.
File stampFile(final String example) => File('$example/../doc/media/showcase.stamp');
