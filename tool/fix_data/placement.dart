// Writes lib/fix_data/placement.yaml, the `dart fix` transforms for the placement API (0.7.0).
//
//   dart run tool/fix_data/placement.dart           writes it
//   dart run tool/fix_data/placement.dart --check   fails if the committed file differs
//
// A data-driven fix rewrites a call only through a template per shape of call: the template for
// `HarborBuoy.anchored(anchor: a, gap: 4)` cannot also serve `HarborBuoy.anchored(anchor: a)`,
// because a missing argument cannot be left out of a template. So every combination of the old
// optional arguments is a branch of its own, and writing them by hand would be hundreds of lines
// to keep in step. This generates them. Edit this file, not the YAML.
//
// Two things about the format, found by running it (Dart 3.13):
//  * Parameter changes do not fire from the diagnostic on a deprecated NAMED constructor, only
//    from one on a deprecated parameter or an undefined one. So `HarborBuoy.anchored` is fixed in
//    two passes, both made by one `dart fix --apply`: renamed to `HarborBuoy`, after which its old
//    arguments are undefined, and the unnamed constructor's transform rewrites them.
//  * A condition reads a missing argument as ''.

import 'dart:io';

const String _harbor = 'package:harbor/harbor.dart';
const String _date = '2026-10-14';

/// One old argument, written in the new placement under the same name.
class _Arg {
  const _Arg(this.name);

  final String name;

  String write() => '$name: {% $name %}';
}

/// One branch: the old arguments present in this shape of call (all others absent), and the
/// placement expression that replaces them.
class _Branch {
  _Branch(this.present, this.absent, this.expression);

  /// Where the placement goes among the arguments: after `raise`'s context, first otherwise.
  int index = 0;

  final List<String> present;
  final List<String> absent;
  final String expression;

  String yaml(final Set<String> imports) {
    final StringBuffer b = StringBuffer();
    final String condition = <String>[
      for (final String p in present) "$p != ''",
      for (final String a in absent) "$a == ''",
    ].join(' && ');
    b.writeln('      - if: "$condition"');
    b.writeln('        changes:');
    b.writeln("          - kind: 'addParameter'");
    b.writeln('            index: $index');
    b.writeln("            name: 'placement'");
    b.writeln('            style: optional_named');
    b.writeln('            argumentValue:');
    b.writeln("              expression: '$expression'");
    b.writeln('              requiredIf: "$condition"');
    final List<String> used = <String>[
      for (final String name in imports)
        if (expression.contains('{% $name %}')) name,
    ];
    if (used.isNotEmpty) {
      b.writeln('              variables:');
      for (final String name in used) {
        b.writeln('                $name:');
        b.writeln("                  kind: 'import'");
        b.writeln("                  uris: [ '$_harbor' ]");
        b.writeln("                  name: '$name'");
      }
    }
    for (final String p in present) {
      b.writeln("          - kind: 'removeParameter'");
      b.writeln("            name: '$p'");
    }
    return b.toString();
  }
}

/// Every subset of [items] with at most [max] members, smallest first, in [items]' order.
List<List<T>> _subsets<T>(final List<T> items, {final int? max}) {
  final List<List<T>> all = <List<T>>[
    for (int mask = 0; mask < 1 << items.length; mask++)
      <T>[
        for (int i = 0; i < items.length; i++)
          if (mask & (1 << i) != 0) items[i],
      ],
  ];
  return <List<T>>[
    for (final List<T> s in all)
      if (max == null || s.length <= max) s,
  ]..sort((final List<T> a, final List<T> b) => a.length.compareTo(b.length));
}

String _transform({
  required final String title,
  required final String comment,
  required final String element,
  required final List<_Branch> branches,
  required final List<String> variables,
  final int index = 0,
  final Set<String> imports = const <String>{'HarborAligned', 'HarborAnchored', 'HarborAnchorSide', 'HarborFlareSlot'},
}) {
  final StringBuffer b = StringBuffer();
  for (final String line in comment.split('\n')) {
    b.writeln('  # $line');
  }
  b.writeln('  - title: "$title"');
  b.writeln('    date: $_date');
  b.writeln('    element:');
  b.writeln("      uris: [ 'harbor.dart' ]");
  b.write(element);
  b.writeln('    oneOf:');
  for (final _Branch branch in branches) {
    b.write((branch..index = index).yaml(imports));
  }
  b.writeln('    variables:');
  for (final String v in variables) {
    b.writeln('      $v:');
    b.writeln("        kind: 'fragment'");
    b.writeln("        value: 'arguments[$v]'");
  }
  return b.toString();
}

/// The branches that turn an old anchored call into `HarborAnchored(anchor, ...)`. [anchorAlways]
/// is true where the old call had to give an anchor; otherwise an absent one becomes `null`.
/// [sideDefault] is written when the old call left its side out, so a migrated call sits where it
/// did; null where the old default is the new one.
List<_Branch> _anchored({
  required final List<_Arg> optional,
  required final bool anchorAlways,
  required final String? sideDefault,
  final int? max,
  final List<String> alsoAbsent = const <String>[],
}) {
  final List<String> names = <String>[for (final _Arg a in optional) a.name];
  final List<List<String>> anchorChoices = anchorAlways ? <List<String>>[<String>['anchor']] : <List<String>>[<String>[], <String>['anchor']];
  return <_Branch>[
    for (final List<String> anchor in anchorChoices)
      for (final List<_Arg> given in _subsets(optional, max: max == null ? null : max - anchor.length))
        if (anchor.isNotEmpty || given.isNotEmpty)
          _Branch(
            <String>[...anchor, for (final _Arg a in given) a.name],
            <String>[
              if (anchor.isEmpty) 'anchor',
              for (final String n in names)
                if (!given.any((final _Arg a) => a.name == n)) n,
              ...alsoAbsent,
            ],
            '{% HarborAnchored %}(${<String>[
              if (anchor.isEmpty) 'null' else '{% anchor %}',
              if (sideDefault != null && !given.any((final _Arg a) => a.name == 'side')) 'side: $sideDefault',
              for (final _Arg a in given) a.write(),
            ].join(', ')})',
          ),
  ];
}

String generate() {
  const List<_Arg> buoyAnchored = <_Arg>[
    _Arg('side'),
    _Arg('gap'),
    _Arg('overlap'),
    _Arg('crossAlignment'),
    _Arg('crossOffset'),
    _Arg('margin'),
  ];
  const List<_Arg> portal = <_Arg>[
    _Arg('side'),
    _Arg('gap'),
    _Arg('overlap'),
    _Arg('crossAlignment'),
    _Arg('crossOffset'),
    _Arg('margin'),
    _Arg('flips'),
  ];
  const List<_Arg> flareAnchored = <_Arg>[_Arg('side'), _Arg('gap'), _Arg('crossAlignment'), _Arg('margin')];
  const String above = '{% HarborAnchorSide %}.above';

  final StringBuffer out = StringBuffer()
    ..writeln('# GENERATED by tool/fix_data/placement.dart; edit that, then run it. tool/check.sh fails while')
    ..writeln('# this file and the generator disagree.')
    ..writeln('#')
    ..writeln('# `dart fix` transforms for the placement API (0.7.0): HarborPlacement, HarborAligned and')
    ..writeln('# HarborAnchored replace the placement parameters of HarborBuoy, HarborBuoy.anchored,')
    ..writeln('# HarborPortalBuoy and HarborFlares.raise. Each is checked by a golden in test_fixes/.')
    ..writeln('version: 1')
    ..writeln('transforms:');

  for (final (String old, String now) in <(String, String)>[
    ('HarborBuoySide', 'HarborAnchorSide'),
    ('HarborBuoyCrossAlignment', 'HarborCrossAlignment'),
  ]) {
    out
      ..writeln('  # $old was renamed $now: flares and HarborAnchorClip take it too.')
      ..writeln('  - title: "Rename to \'$now\'"')
      ..writeln('    date: $_date')
      ..writeln('    element:')
      ..writeln("      uris: [ 'harbor.dart' ]")
      ..writeln("      typedef: '$old'")
      ..writeln('    changes:')
      ..writeln("      - kind: 'rename'")
      ..writeln("        newName: '$now'");
  }

  out
    ..writeln('  # HarborBuoy.anchored(anchor: a, ...) becomes HarborBuoy(placement: HarborAnchored(a, ...)).')
    ..writeln('  # First pass: the rename. Its arguments are then undefined, and the next transform moves them.')
    ..writeln('  - title: "Migrate to \'placement\'"')
    ..writeln('    date: $_date')
    ..writeln('    element:')
    ..writeln("      uris: [ 'harbor.dart' ]")
    ..writeln("      constructor: 'anchored'")
    ..writeln("      inClass: 'HarborBuoy'")
    ..writeln('    changes:')
    ..writeln("      - kind: 'rename'")
    ..writeln("        newName: ''");

  out.write(
    _transform(
      title: "Migrate to 'placement'",
      comment:
          'HarborBuoy(alignment:, margin:) becomes HarborBuoy(placement: HarborAligned(...)), and the arguments a\n'
          'renamed HarborBuoy.anchored left behind become HarborBuoy(placement: HarborAnchored(anchor, ...)). The old\n'
          "anchored buoy's side was above, a HarborAnchored's is below, so side: above is written where it was left out.",
      element: "      constructor: ''\n      inClass: 'HarborBuoy'\n",
      branches: <_Branch>[
        for (final List<_Arg> given in _subsets(const <_Arg>[_Arg('alignment'), _Arg('margin')]))
          if (given.isNotEmpty)
            _Branch(
              <String>[for (final _Arg a in given) a.name],
              <String>[
                'anchor',
                for (final String n in <String>['alignment', 'margin'])
                  if (!given.any((final _Arg a) => a.name == n)) n,
              ],
              '{% HarborAligned %}(${given.map((final _Arg a) => a.write()).join(', ')})',
            ),
        ..._anchored(optional: buoyAnchored, anchorAlways: true, sideDefault: above),
      ],
      variables: <String>['anchor', 'alignment', for (final _Arg a in buoyAnchored) a.name],
    ),
  );

  out.write(
    _transform(
      title: "Migrate to 'placement'",
      comment:
          'HarborPortalBuoy(anchor:, side:, gap:, overlap:, crossAlignment:, crossOffset:, margin:, flips:) becomes\n'
          "HarborPortalBuoy(placement: HarborAnchored(anchor or null, ...)). A portal buoy's old side was above, so\n"
          'side: above is written where it was left out. Calls giving more than four of these are left for hand.',
      element: "      constructor: ''\n      inClass: 'HarborPortalBuoy'\n",
      branches: _anchored(optional: portal, anchorAlways: false, sideDefault: above, max: 4),
      variables: <String>['anchor', for (final _Arg a in portal) a.name],
    ),
  );

  out.write(
    _transform(
      title: "Migrate to 'placement'",
      comment:
          'HarborFlares.raise(alignment:, margin:) becomes raise(placement: HarborAligned(...)), slot: with margin:\n'
          "included, and raise(anchor:, side:, gap:, crossAlignment:, margin:) becomes placement: HarborAnchored(...).\n"
          "A flare's old side was below, as a HarborAnchored's is, so nothing is added for it. slot: alone stays.",
      element: "      method: 'raise'\n      inClass: 'HarborFlares'\n",
      index: 1,
      branches: <_Branch>[
        _Branch(<String>['alignment'], <String>['anchor', 'margin'], '{% HarborAligned %}(alignment: {% alignment %})'),
        _Branch(
          <String>['alignment', 'margin'],
          <String>['anchor'],
          '{% HarborAligned %}(alignment: {% alignment %}, margin: {% margin %})',
        ),
        _Branch(
          <String>['slot', 'margin'],
          <String>['anchor', 'alignment'],
          '{% HarborAligned %}(alignment: {% slot %}.alignment, margin: {% margin %})',
        ),
        _Branch(
          <String>['margin'],
          <String>['anchor', 'alignment', 'slot'],
          '{% HarborAligned %}(alignment: {% HarborFlareSlot %}.high.alignment, margin: {% margin %})',
        ),
        ..._anchored(optional: flareAnchored, anchorAlways: true, sideDefault: null, alsoAbsent: <String>['slot', 'alignment']),
      ],
      variables: <String>['anchor', 'alignment', 'slot', for (final _Arg a in flareAnchored) a.name],
    ),
  );
  return out.toString();
}

void main(final List<String> args) {
  final File file = File.fromUri(Platform.script.resolve('../../lib/fix_data/placement.yaml'));
  final String yaml = generate();
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != yaml) {
      stderr.writeln('${file.path} is out of date: run dart run tool/fix_data/placement.dart');
      exit(1);
    }
    return;
  }
  file.writeAsStringSync(yaml);
}
