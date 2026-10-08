// What an app gets in its own dependency graph by depending on harbor.
//
// Sea trials live in package:harbor_test, a dev_dependency, so the test framework never reaches
// an app's main graph. Some dependency policies reject a package that brings flutter_test along.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The package names listed directly under [section] in a pubspec, in order.
List<String> _section(final String pubspec, final String section) {
  final List<String> names = <String>[];
  bool inSection = false;
  for (final String line in pubspec.split('\n')) {
    if (!line.startsWith(' ') && line.trim().isNotEmpty) {
      inSection = line.trimRight() == '$section:';
      continue;
    }
    final RegExpMatch? entry = RegExp(r'^  ([a-z_][a-z0-9_]*):').firstMatch(line);
    if (inSection && entry != null) {
      names.add(entry.group(1)!);
    }
  }
  return names;
}

void main() {
  test('harbor depends on the Flutter SDK only', () {
    expect(_section(File('pubspec.yaml').readAsStringSync(), 'dependencies'), <String>['flutter']);
  });

  test('harbor_test brings harbor and flutter_test, for use as a dev_dependency', () {
    expect(_section(File('harbor_test/pubspec.yaml').readAsStringSync(), 'dependencies'), <String>[
      'flutter',
      'flutter_test',
      'harbor',
    ]);
  });
}
