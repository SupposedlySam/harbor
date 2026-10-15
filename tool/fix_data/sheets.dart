// Writes lib/fix_data/sheets.yaml, the `dart fix` transforms for the sheets step (#120,
// doc/design/sheets.md): HarborBarrier in place of the loose barrier parameters of sheets, dialogs
// and floats, and headerBar:/footerBar: in place of a sheet's header and footer knobs.
//
//   dart run tool/fix_data/sheets.dart           writes it
//   dart run tool/fix_data/sheets.dart --check   fails if the committed file differs
//
// As in placement.dart, a template cannot leave out an argument the call did not give, so every
// combination of the old arguments is a branch of its own. Edit this file, not the YAML.
//
// What each branch keeps (doc/design/DECISIONS.md, "How every change ships"): a migrated call does
// exactly what the old one did. So an argument that did nothing in the old call (`barrierColor`
// with a clear or no barrier, a float's `barrierColor` without `modal`, a footer knob with no
// footer) is removed rather than carried into the new value, where it would mean something or
// assert. A call the branches do not cover (a barrier or `modal` given as a variable) is left as it
// is: it still compiles, and its deprecation says what to write.
//
// What is NOT here, because a transform would break code that compiles (found by running it on
// this repo's example):
//  * HarborSheetBarrier.none on its own. A `replacedBy` HarborBarrier.none rewrites it wherever it
//    is written, and a variable typed HarborSheetBarrier then holds a HarborBarrier, which does not
//    compile; a comparison with it compiles and is never true. Only inside a showHarborSheet call
//    whose loose arguments fire the transform below is it rewritten, where its type is HarborBarrier.
//  * HarborDialogRoute(barrierColor: c) for any c but the literal `null`. The parameter is a Color?,
//    and a nullable colour cannot go in HarborBarrier.dimmed(color:); a fix compares text, not types.
//
// One transform here CAN break code that compiled, and is kept because it is right far more often
// than not (owner review): a sheet's header and footer knobs. The template puts the header or footer
// in a bar's `child:`, which is not nullable, so `footer: done ? actions : null` with a knob comes out
// as argument_type_not_assignable, a compile error that names the line, fixed by hand with
// `footerBar: done ? HarborBar.solid(...) : null`. The CHANGELOG says so.

import 'dart:io';

const String _harbor = 'package:harbor/harbor.dart';
const String _date = '2026-10-14';

/// One branch: the condition it matches, the arguments it removes, and the argument it adds.
class _Branch {
  _Branch({
    required this.present,
    required this.absent,
    this.equal = const <String, String>{},
    required this.remove,
    this.add,
    this.expression,
  });

  /// Arguments the call gives, and arguments it does not.
  final List<String> present;
  final List<String> absent;

  /// Arguments the call gives with exactly this text.
  final Map<String, String> equal;

  /// Arguments removed: the old ones, and any the new one replaces.
  final List<String> remove;

  /// The argument added, and its value; none when the old arguments only go.
  final String? add;
  final String? expression;

  /// Where the new argument goes among the parameters.
  int index = 0;

  String get condition => <String>[
    for (final MapEntry<String, String> e in equal.entries) "${e.key} == '${e.value}'",
    for (final String p in present) "$p != ''",
    for (final String a in absent) "$a == ''",
  ].join(' && ');

  String yaml(final Set<String> imports) {
    final StringBuffer b = StringBuffer()
      ..writeln('      - if: "$condition"')
      ..writeln('        changes:');
    for (final String r in remove) {
      b
        ..writeln("          - kind: 'removeParameter'")
        ..writeln("            name: '$r'");
    }
    final String? add = this.add;
    final String? expression = this.expression;
    if (add != null && expression != null) {
      b
        ..writeln("          - kind: 'addParameter'")
        ..writeln('            index: $index')
        ..writeln("            name: '$add'")
        ..writeln('            style: optional_named')
        ..writeln('            argumentValue:')
        ..writeln("              expression: \"$expression\"")
        ..writeln('              requiredIf: "$condition"');
      final List<String> used = <String>[
        for (final String name in imports)
          if (expression.contains('{% $name %}')) name,
      ];
      if (used.isNotEmpty) {
        b.writeln('              variables:');
        for (final String name in used) {
          b
            ..writeln('                $name:')
            ..writeln("                  kind: 'import'")
            ..writeln("                  uris: [ '$_harbor' ]")
            ..writeln("                  name: '$name'");
        }
      }
    }
    return b.toString();
  }
}

/// Every subset of [items], smallest first, in [items]' order.
List<List<T>> _subsets<T>(final List<T> items) {
  final List<List<T>> all = <List<T>>[
    for (int mask = 0; mask < 1 << items.length; mask++)
      <T>[
        for (int i = 0; i < items.length; i++)
          if (mask & (1 << i) != 0) items[i],
      ],
  ];
  return all..sort((final List<T> a, final List<T> b) => a.length.compareTo(b.length));
}

String _transform({
  required final String title,
  required final String comment,
  required final String element,
  required final List<_Branch> branches,
  required final List<String> variables,
  required final int index,
  final Set<String> imports = const <String>{'HarborBarrier', 'HarborBar', 'HarborEdgeEffect', 'HarborKeyboardStance'},
}) {
  final StringBuffer b = StringBuffer();
  for (final String line in comment.split('\n')) {
    b.writeln('  # $line');
  }
  b
    ..writeln('  - title: "$title"')
    ..writeln('    date: $_date')
    ..writeln('    element:')
    ..writeln("      uris: [ 'harbor.dart' ]")
    ..write(element)
    ..writeln('    oneOf:');
  for (final _Branch branch in branches) {
    b.write((branch..index = index).yaml(imports));
  }
  b.writeln('    variables:');
  for (final String v in variables) {
    b
      ..writeln('      $v:')
      ..writeln("        kind: 'fragment'")
      ..writeln("        value: 'arguments[$v]'");
  }
  return b.toString();
}

/// An old loose argument and the field of a HarborBarrier it becomes.
typedef _Field = ({String arg, String field});

/// `{% HarborBarrier %}.kind(field: {% arg %}, ...)` for the [given] fields.
String _barrier(final String kind, final List<_Field> given) =>
    '{% HarborBarrier %}.$kind(${given.map((final _Field f) => '${f.field}: {% ${f.arg} %}').join(', ')})';

/// The branches that fold a host's loose barrier arguments into `barrier:`. [enumValues] are the
/// literal `barrier:` values the host took before (a sheet's HarborSheetBarrier); a call without
/// one is a dimmed barrier. The color only ever tinted a dimmed barrier, so with a clear one it goes.
List<_Branch> _barrierBranches(final List<_Field> fields, {required final bool sheet}) {
  final List<String> args = <String>[for (final _Field f in fields) f.arg];
  final List<_Branch> branches = <_Branch>[];
  for (final List<_Field> given in _subsets(fields)) {
    if (given.isEmpty) {
      continue;
    }
    final List<String> present = <String>[for (final _Field f in given) f.arg];
    final List<String> absent = <String>[
      for (final String a in args)
        if (!present.contains(a)) a,
    ];
    final List<_Field> tints = given;
    final List<_Field> clears = <_Field>[
      for (final _Field f in given)
        if (f.field != 'color') f,
    ];
    branches.add(
      _Branch(
        present: present,
        absent: <String>[...absent, 'barrier'],
        remove: present,
        add: 'barrier',
        expression: _barrier('dimmed', tints),
      ),
    );
    if (sheet) {
      branches
        ..add(
          _Branch(
            equal: const <String, String>{'barrier': 'HarborSheetBarrier.dismissible'},
            present: present,
            absent: absent,
            remove: <String>[...present, 'barrier'],
            add: 'barrier',
            expression: _barrier('dimmed', tints),
          ),
        )
        ..add(
          _Branch(
            equal: const <String, String>{'barrier': 'HarborSheetBarrier.clear'},
            present: present,
            absent: absent,
            remove: <String>[...present, 'barrier'],
            add: 'barrier',
            expression: _barrier('clear', clears),
          ),
        )
        // No barrier: none of them did anything, and with HarborBarrier.none they assert.
        ..add(
          _Branch(
            equal: const <String, String>{'barrier': 'HarborSheetBarrier.none'},
            present: present,
            absent: absent,
            remove: <String>[...present, 'barrier'],
            add: 'barrier',
            expression: '{% HarborBarrier %}.none',
          ),
        )
        // The same, where the transform above has already replaced HarborSheetBarrier.none in this
        // pass: the loose arguments still go.
        ..add(
          _Branch(
            equal: const <String, String>{'barrier': 'HarborBarrier.none'},
            present: present,
            absent: absent,
            remove: present,
          ),
        );
    }
  }
  return branches;
}

/// The branches that turn a float's `modal:`, `barrierColor:` and `barrierLabel:` into `barrier:`.
List<_Branch> _floatBranches() {
  const List<String> loose = <String>['barrierColor', 'barrierLabel'];
  final List<_Branch> branches = <_Branch>[];
  for (final List<String> given in _subsets(loose)) {
    final List<String> absent = <String>[
      for (final String a in loose)
        if (!given.contains(a)) a,
    ];
    // modal: true is a clear barrier, or one tinted by barrierColor.
    final bool tinted = given.contains('barrierColor');
    final String expression = '{% HarborBarrier %}.${tinted ? 'dimmed' : 'clear'}(${<String>[if (tinted) 'color: {% barrierColor %}', if (given.contains('barrierLabel')) 'label: {% barrierLabel %}'].join(', ')})';
    branches
      ..add(
        _Branch(
          equal: const <String, String>{'modal': 'true'},
          present: given,
          absent: <String>[...absent, 'barrier'],
          remove: <String>['modal', ...given],
          add: 'barrier',
          expression: expression,
        ),
      )
      // modal: false, the default: the float is not modal, and the barrier's colour and label
      // did nothing.
      ..add(
        _Branch(
          equal: const <String, String>{'modal': 'false'},
          present: given,
          absent: absent,
          remove: <String>['modal', ...given],
        ),
      );
    if (given.isNotEmpty) {
      // No modal: the float is not modal, and the barrier's colour and label did nothing.
      branches.add(_Branch(present: given, absent: <String>[...absent, 'modal'], remove: given));
    }
  }
  return branches;
}

/// The branches that put a sheet's plain header in its own bar when a call sets the header's knob.
List<_Branch> _headerBranches() => <_Branch>[
  _Branch(
    present: <String>['header', 'headerEdgeEffect'],
    absent: <String>['headerBar'],
    remove: <String>['header', 'headerEdgeEffect'],
    add: 'headerBar',
    expression: "{% HarborBar %}.overlay(edgeEffect: {% headerEdgeEffect %}, debugLabel: 'sheet header', child: {% header %})",
  ),
  // No header: the knob did nothing.
  _Branch(present: <String>['headerEdgeEffect'], absent: <String>['header'], remove: <String>['headerEdgeEffect']),
];

/// The branches that put a sheet's plain footer in its own bar when a call sets its knobs. A knob
/// the call leaves out is written with the sheet's default (HarborSheet.defaultFooterBar: a
/// hairline, a minimum of 16, riding the keyboard), so the bar is the one the footer had.
List<_Branch> _footerBranches() {
  const List<(String, String, String)> knobs = <(String, String, String)>[
    ('footerEdgeEffect', 'edgeEffect', '{% HarborEdgeEffect %}.hairline()'),
    ('footerMinimum', 'minimum', '16.0'),
    ('footerKeyboard', 'keyboard', '{% HarborKeyboardStance %}.rides'),
  ];
  final List<_Branch> branches = <_Branch>[];
  for (final List<(String, String, String)> given in _subsets(knobs)) {
    if (given.isEmpty) {
      continue;
    }
    final List<String> names = <String>[for (final (String name, _, _) in given) name];
    final List<String> absent = <String>[
      for (final (String name, _, _) in knobs)
        if (!names.contains(name)) name,
    ];
    final String fields = <String>[
      for (final (String name, String field, String byDefault) in knobs)
        '$field: ${names.contains(name) ? '{% $name %}' : byDefault}',
    ].join(', ');
    branches
      ..add(
        _Branch(
          present: <String>['footer', ...names],
          absent: <String>[...absent, 'footerBar'],
          remove: <String>['footer', ...names],
          add: 'footerBar',
          expression: "{% HarborBar %}.solid($fields, debugLabel: 'sheet footer', child: {% footer %})",
        ),
      )
      // No footer: the knobs did nothing.
      ..add(_Branch(present: names, absent: <String>[...absent, 'footer'], remove: names));
  }
  return branches;
}

String generate() {
  final StringBuffer out = StringBuffer()
    ..writeln('# GENERATED by tool/fix_data/sheets.dart; edit that, then run it. tool/check.sh fails while')
    ..writeln('# this file and the generator disagree.')
    ..writeln('#')
    ..writeln('# `dart fix` transforms for the sheets step (doc/design/sheets.md): HarborBarrier in place of')
    ..writeln('# the barrier parameters of showHarborSheet, showHarborDialog, HarborDialogRoute and HarborFloat.')
    ..writeln('# Checked by test_fixes/sheets.dart.')
    ..writeln('version: 1')
    ..writeln('transforms:');

  out.write(
    _transform(
      title: "Migrate to 'barrier'",
      comment:
          'showHarborSheet(isDismissible:, barrierColor:, barrierLabel:, barrierOnTapHint:) becomes\n'
          'barrier: HarborBarrier.dimmed(...), or .clear(...) with barrier: HarborSheetBarrier.clear, whose colour\n'
          'was never used. With HarborSheetBarrier.none they did nothing, and go.',
      element: "      function: 'showHarborSheet'\n",
      index: 1,
      branches: _barrierBranches(const <_Field>[
        (arg: 'barrierColor', field: 'color'),
        (arg: 'isDismissible', field: 'dismissible'),
        (arg: 'barrierLabel', field: 'label'),
        (arg: 'barrierOnTapHint', field: 'onTapHint'),
      ], sheet: true),
      variables: const <String>['barrier', 'barrierColor', 'isDismissible', 'barrierLabel', 'barrierOnTapHint'],
    ),
  );

  const List<_Field> dialog = <_Field>[
    (arg: 'barrierColor', field: 'color'),
    (arg: 'barrierDismissible', field: 'dismissible'),
    (arg: 'barrierLabel', field: 'label'),
  ];
  out
    ..write(
      _transform(
        title: "Migrate to 'barrier'",
        comment: 'showHarborDialog(barrierColor:, barrierDismissible:, barrierLabel:) becomes barrier: HarborBarrier.dimmed(...).',
        element: "      function: 'showHarborDialog'\n",
        index: 1,
        branches: _barrierBranches(dialog, sheet: false),
        variables: const <String>['barrier', 'barrierColor', 'barrierDismissible', 'barrierLabel'],
      ),
    )
    ..write(
      _transform(
        title: "Migrate to 'barrier'",
        comment:
            'HarborDialogRoute(barrierDismissible:, barrierLabel:) becomes barrier: HarborBarrier.dimmed(...), and with the\n'
            'literal barrierColor: null, a barrier with no colour, HarborBarrier.clear(...). Its barrierColor is a\n'
            'Color?, so any other colour is left for you: a fix compares text, not types.',
        element: "      constructor: ''\n      inClass: 'HarborDialogRoute'\n",
        index: 3,
        branches: <_Branch>[
          for (final _Branch b in _barrierBranches(dialog.sublist(1), sheet: false))
            _Branch(
              present: b.present,
              absent: <String>[...b.absent, 'barrierColor'],
              remove: b.remove,
              add: b.add,
              expression: b.expression,
            ),
          for (final List<_Field> given in _subsets(dialog.sublist(1)))
            _Branch(
              equal: const <String, String>{'barrierColor': 'null'},
              present: <String>[for (final _Field f in given) f.arg],
              absent: <String>[
                'barrier',
                for (final _Field f in dialog.sublist(1))
                  if (!given.contains(f)) f.arg,
              ],
              remove: <String>['barrierColor', for (final _Field f in given) f.arg],
              add: 'barrier',
              expression: _barrier('clear', given),
            ),
        ],
        variables: const <String>['barrier', 'barrierColor', 'barrierDismissible', 'barrierLabel'],
      ),
    );

  // HarborBuoy is a deprecated subclass of HarborFloat, so a call spelled with either name is keyed
  // on the class that declares its constructor; .anchored is deprecated, and placement.yaml moves
  // it to the unnamed constructor, but either may be what the code says when this runs.
  for (final String float in <String>['HarborFloat', 'HarborBuoy']) {
    for (final String constructor in <String>['', 'anchored']) {
      out.write(
        _transform(
          title: "Migrate to 'barrier'",
          comment:
              '$float${constructor.isEmpty ? '' : '.$constructor'}(modal: true, barrierColor:, barrierLabel:) becomes barrier: HarborBarrier.clear(label:),\n'
              'or HarborBarrier.dimmed(color:, label:) with a barrierColor. modal: false, and the colour and label\n'
              'without modal, did nothing, and go. modal: given anything else is left for you.',
          element: "      constructor: '$constructor'\n      inClass: '$float'\n",
          index: 5,
          branches: _floatBranches(),
          variables: const <String>['barrier', 'modal', 'barrierColor', 'barrierLabel'],
        ),
      );
    }
  }

  for (final String constructor in <String>['', 'draggable']) {
    final String name = constructor.isEmpty ? 'HarborSheet' : 'HarborSheet.$constructor';
    out
      ..write(
        _transform(
          title: "Migrate to 'headerBar'",
          comment:
              '$name(header: h, headerEdgeEffect: e) becomes headerBar: HarborBar.overlay(edgeEffect: e, ..., child: h),\n'
              'the bar a plain header is put in. Without a header the knob did nothing, and goes. A nullable header\n'
              'comes out as a type error, fixed by hand (tool/fix_data/sheets.dart says why).',
          element: "      constructor: '$constructor'\n      inClass: 'HarborSheet'\n",
          index: 2,
          branches: _headerBranches(),
          variables: const <String>['header', 'headerBar', 'headerEdgeEffect'],
        ),
      )
      ..write(
        _transform(
          title: "Migrate to 'footerBar'",
          comment:
              '$name(footer: f, footerEdgeEffect:, footerMinimum:, footerKeyboard:) becomes\n'
              'footerBar: HarborBar.solid(..., child: f), the bar a plain footer is put in, with the knobs the call\n'
              'left out at the sheet\'s defaults. Without a footer the knobs did nothing, and go.',
          element: "      constructor: '$constructor'\n      inClass: 'HarborSheet'\n",
          index: 3,
          branches: _footerBranches(),
          variables: const <String>['footer', 'footerBar', 'footerEdgeEffect', 'footerMinimum', 'footerKeyboard'],
        ),
      );
  }
  return out.toString();
}

void main(final List<String> args) {
  final File file = File.fromUri(Platform.script.resolve('../../lib/fix_data/sheets.yaml'));
  final String yaml = generate();
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != yaml) {
      stderr.writeln('${file.path} is out of date: run dart run tool/fix_data/sheets.dart');
      exit(1);
    }
    return;
  }
  file.writeAsStringSync(yaml);
}
