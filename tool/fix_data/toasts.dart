// Writes lib/fix_data/toasts.yaml, the `dart fix` transforms for the toast timing value (0.10).
//
//   dart run tool/fix_data/toasts.dart           writes it
//   dart run tool/fix_data/toasts.dart --check   fails if the committed file differs
//
// `HarborToasts.show(timing:)` takes a `HarborToastTiming` in place of four loose arguments:
// `duration:`, `persist:`, `countsEntrance:` and `countsWhileCovered:`. A data-driven fix rewrites
// a call through one template per shape of call (placement.dart says why), so every combination of
// the four is a branch of its own, and this generates them. Edit this file, not the YAML.
//
// What the old arguments meant, and so what each branch writes:
//  * The time ran only while `duration != null && !persist`. So `persist: true` is a null duration
//    whatever `duration:` says, and `duration: null` is the same; either, alone, is
//    `HarborToastTiming.untilHidden`.
//  * `persist: false` and a left-out `persist:` are the same, so `persist: false` just goes.
//  * A condition can compare an argument's text, as bars.yaml does, so `persist:` is fixed when it
//    is the literal `true` or `false`. Given anything else (a variable), no branch matches and the
//    call is left for you: its deprecation message says what to write.
//  * A call that already gives `timing:` with an old argument asserts; it is left alone.

import 'dart:io';

const String _harbor = 'package:harbor/harbor.dart';
const String _date = '2026-10-14';

/// The index of `timing` among `show`'s parameters, context included.
const int _timingIndex = 5;

enum _Duration { absent, isNull, value }

enum _Persist { absent, isTrue, isFalse }

/// One shape of call: which old arguments it gives, and how.
class _Shape {
  const _Shape(this.duration, this.persist, this.countsEntrance, this.countsWhileCovered);

  final _Duration duration;
  final _Persist persist;
  final bool countsEntrance;
  final bool countsWhileCovered;

  bool get isEmpty =>
      duration == _Duration.absent && persist == _Persist.absent && !countsEntrance && !countsWhileCovered;

  String get condition => <String>[
    "timing == ''",
    switch (duration) {
      _Duration.absent => "duration == ''",
      _Duration.isNull => "duration == 'null'",
      _Duration.value => "duration != '' && duration != 'null'",
    },
    switch (persist) {
      _Persist.absent => "persist == ''",
      _Persist.isTrue => "persist == 'true'",
      _Persist.isFalse => "persist == 'false'",
    },
    if (countsEntrance) "countsEntrance != ''" else "countsEntrance == ''",
    if (countsWhileCovered) "countsWhileCovered != ''" else "countsWhileCovered == ''",
  ].join(' && ');

  /// The old arguments this call gives, all removed.
  List<String> get given => <String>[
    if (duration != _Duration.absent) 'duration',
    if (persist != _Persist.absent) 'persist',
    if (countsEntrance) 'countsEntrance',
    if (countsWhileCovered) 'countsWhileCovered',
  ];

  /// The timing that replaces them; null where nothing needs saying (`persist: false` alone).
  String? get expression {
    final bool untilHidden = persist == _Persist.isTrue || duration == _Duration.isNull;
    final List<String> args = <String>[
      if (untilHidden)
        'duration: null'
      else if (duration == _Duration.value)
        'duration: {% duration %}',
      if (countsEntrance) 'countsEntrance: {% countsEntrance %}',
      if (countsWhileCovered) 'countsWhileCovered: {% countsWhileCovered %}',
    ];
    if (untilHidden && args.length == 1) {
      return '{% HarborToastTiming %}.untilHidden';
    }
    return args.isEmpty ? null : '{% HarborToastTiming %}(${args.join(', ')})';
  }

  String yaml() {
    final StringBuffer b = StringBuffer()
      ..writeln('      - if: "$condition"')
      ..writeln('        changes:');
    final String? timing = expression;
    if (timing != null) {
      b
        ..writeln("          - kind: 'addParameter'")
        ..writeln('            index: $_timingIndex')
        ..writeln("            name: 'timing'")
        ..writeln('            style: optional_named')
        ..writeln('            argumentValue:')
        ..writeln("              expression: '$timing'")
        ..writeln('              requiredIf: "$condition"')
        ..writeln('              variables:')
        ..writeln('                HarborToastTiming:')
        ..writeln("                  kind: 'import'")
        ..writeln("                  uris: [ '$_harbor' ]")
        ..writeln("                  name: 'HarborToastTiming'");
    }
    for (final String p in given) {
      b
        ..writeln("          - kind: 'removeParameter'")
        ..writeln("            name: '$p'");
    }
    return b.toString();
  }
}

String generate() {
  final List<_Shape> shapes = <_Shape>[
    for (final _Duration d in _Duration.values)
      for (final _Persist p in _Persist.values)
        for (final bool e in <bool>[false, true])
          for (final bool c in <bool>[false, true])
            if (!_Shape(d, p, e, c).isEmpty) _Shape(d, p, e, c),
  ];

  final StringBuffer out = StringBuffer()
    ..writeln('# GENERATED by tool/fix_data/toasts.dart; edit that, then run it. tool/check.sh fails while')
    ..writeln('# this file and the generator disagree.')
    ..writeln('#')
    ..writeln('# `dart fix` transforms for the toast timing value: HarborToastTiming, given as')
    ..writeln('# HarborToasts.show(timing:), replaces duration:, persist:, countsEntrance: and')
    ..writeln('# countsWhileCovered:. persist: is fixed when it is the literal true or false. Checked by')
    ..writeln('# test_fixes/toasts.dart.')
    ..writeln('version: 1')
    ..writeln('transforms:');

  // `raise` is the 0.8 name of `show` (and HarborFlares and HarborSignals resolve to HarborToasts),
  // so either may be the name in the code when this runs.
  for (final String method in <String>['raise', 'show']) {
    out
      ..writeln('  # HarborToasts.$method(duration:, persist:, countsEntrance:, countsWhileCovered:) becomes')
      ..writeln('  # $method(timing: HarborToastTiming(...)).')
      ..writeln('  - title: "Migrate to \'timing\'"')
      ..writeln('    date: $_date')
      ..writeln('    element:')
      ..writeln("      uris: [ 'harbor.dart' ]")
      ..writeln("      method: '$method'")
      ..writeln("      inClass: 'HarborToasts'")
      ..writeln('    oneOf:');
    for (final _Shape shape in shapes) {
      out.write(shape.yaml());
    }
    out.writeln('    variables:');
    for (final String v in <String>['timing', 'duration', 'persist', 'countsEntrance', 'countsWhileCovered']) {
      out
        ..writeln('      $v:')
        ..writeln("        kind: 'fragment'")
        ..writeln("        value: 'arguments[$v]'");
    }
  }
  return out.toString();
}

void main(final List<String> args) {
  final File file = File.fromUri(Platform.script.resolve('../../lib/fix_data/toasts.yaml'));
  final String yaml = generate();
  if (args.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync() != yaml) {
      stderr.writeln('${file.path} is out of date: run dart run tool/fix_data/toasts.dart');
      exit(1);
    }
    return;
  }
  file.writeAsStringSync(yaml);
}
