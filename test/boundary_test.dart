// harbor's core is a layout package on Flutter's widgets layer and imports no design library.
//
// Flutter 3.47 moved Material and Cupertino out of the framework into packages of their own
// (material_ui, cupertino_ui), and the in-framework libraries are frozen for removal. A layout
// package that imported one would choose it for every app that uses harbor, Cupertino and custom
// design systems included, and would need a pub dependency once the framework copy is gone. So
// the Material conveniences are values the caller passes (a barrier label, a max width) and a
// builder the caller fills (HarborSheet.contentBuilder), with the recipes in the README.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final RegExp _designLibrary = RegExp(r'''import\s+['"]package:(flutter/(material|cupertino)\.dart|material_ui/|cupertino_ui/)''');

List<String> _offenders(final String dir) => <String>[
  for (final FileSystemEntity file in Directory(dir).listSync(recursive: true))
    if (file is File && file.path.endsWith('.dart') && _designLibrary.hasMatch(file.readAsStringSync())) file.path,
];

void main() {
  test('nothing in lib/ imports a design library', () {
    final List<String> scanned = Directory('lib').listSync(recursive: true).whereType<File>().where((final File f) => f.path.endsWith('.dart')).map((final File f) => f.path).toList();
    expect(scanned.length, greaterThan(10), reason: 'positive control: the scan saw the library');
    expect(_offenders('lib'), isEmpty);
  });

  test('nor does harbor_test', () {
    expect(_offenders('harbor_test/lib'), isEmpty);
  });

  test('the pattern catches the imports it is meant to (positive control)', () {
    expect(_designLibrary.hasMatch("import 'package:flutter/material.dart';"), isTrue);
    expect(_designLibrary.hasMatch("import 'package:flutter/cupertino.dart' show CupertinoPageRoute;"), isTrue);
    expect(_designLibrary.hasMatch("import 'package:material_ui/material_ui.dart';"), isTrue);
    expect(_designLibrary.hasMatch("import 'package:flutter/widgets.dart';"), isFalse);
  });
}
