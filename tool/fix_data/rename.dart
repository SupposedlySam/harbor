// Writes the `dart fix` transforms for the rename (0.9.0, #120): lib/fix_data/rename.yaml for
// harbor, and harbor_test/lib/fix_data.yaml for harbor_test.
//
//   dart run tool/fix_data/rename.dart           writes them
//   dart run tool/fix_data/rename.dart --check   fails if a committed file differs
//
// doc/design/naming.md is the table this follows; every row it marks T, T+S, T+E, SUB, RP, RB or
// rename is here, under the element the old name now resolves to. Edit this file, not the YAML.
//
// What the format does, found by running it (Dart 3.13), beyond what placement.dart records:
//  * An old name kept as a typedef resolves to the new class, so every member transform is keyed on
//    the NEW class (`inClass: 'HarborBar'`), whatever name the code spells the class with. Keyed on
//    the old one it never matches.
//  * A renamed enum value was a deprecated `static const` on the new enum, a `field` `inClass`. 1.0
//    removed them, and the analyzer offers no data-driven fix for an undefined enum constant, so
//    those renames are gone (DECISIONS.md, "Fix data after 1.0").
//  * A class whose named constructors are renamed was a deprecated subclass (HarborDock), renamed
//    with `class:`. With the subclass removed (1.0), a transform keyed on it never matches: the
//    class rename turns `HarborDock.pier(...)` into `HarborBar.pier(...)`, so the constructor
//    transforms are keyed on HarborBar, the class the call lands on, and fire on the next pass.
//  * An extension cannot be aliased, so the old one (HarborSeaTrials) was an extension of its own,
//    holding only the old method names, renamed with `extension:`. An implicit
//    `tester.pumpSeaTrial()` matches by the target's type, `inClass: 'WidgetTester'`.
//  * A call with no receiver (a bare `pumpSeaTrial()` inside an extension, implicit `this`) is keyed
//    on the type that declares the method, and also matches a one-name rename of that type: the
//    analyzer reads `Name(...)` as a possible renamed constructor. Where two transforms rename the
//    same name the one listed first is applied, so a type's own rename comes after its members'
//    (#143). An old name kept as a typedef is safe: its members are declared on the new class.

import 'dart:io';

const String _date = '2026-10-14';

/// Where an element is declared: `inClass: 'HarborBar'`, or at the top level.
class _In {
  const _In.cls(this.name) : key = 'inClass';

  final String key;
  final String name;
}

/// An element as a transform names it: `constructor: 'pier'` in [container].
class _Element {
  const _Element(this.kind, this.name, [this.container]);

  /// `typedef`, `class`, `extension`, `constructor`, `method`, `getter`, `field` or `function`.
  final String kind;
  final String name;
  final _In? container;

  String yaml(final String uri, final String indent) {
    final StringBuffer b = StringBuffer()
      ..writeln("${indent}uris: [ '$uri' ]")
      ..writeln("$indent$kind: '$name'");
    final _In? c = container;
    if (c != null) {
      b.writeln("$indent${c.key}: '${c.name}'");
    }
    return b.toString();
  }

  String describe() {
    final _In? c = container;
    final String member = kind == 'constructor' ? (name.isEmpty ? '' : '.$name') : '.$name';
    return c == null ? name : '${c.name}$member';
  }
}

sealed class _Transform {
  const _Transform(this.element);

  final _Element element;

  String changes();

  String title();

  String yaml(final String uri) {
    final StringBuffer b = StringBuffer()
      ..writeln('  # ${element.describe()}')
      ..writeln('  - title: "${title()}"')
      ..writeln('    date: $_date')
      ..writeln('    element:')
      ..write(element.yaml(uri, '      '))
      ..writeln('    changes:')
      ..write(changes());
    return b.toString();
  }
}

/// The element is renamed, wherever it is used: a type, a member, a value, a function.
class _Rename extends _Transform {
  const _Rename(super.element, this.newName);

  final String newName;

  @override
  String title() => "Rename to '$newName'";

  @override
  String changes() => "      - kind: 'rename'\n        newName: '$newName'\n";
}

/// Named arguments of the element are renamed: `tide:` becomes `keyboard:`.
class _Parameters extends _Transform {
  const _Parameters(super.element, this.renames);

  /// Old name to new.
  final Map<String, String> renames;

  @override
  String title() => renames.length == 1 ? "Rename to '${renames.values.single}'" : 'Rename parameters';

  @override
  String changes() => <String>[
    for (final MapEntry<String, String> r in renames.entries)
      "      - kind: 'renameParameter'\n        oldName: '${r.key}'\n        newName: '${r.value}'\n",
  ].join();
}

/// The element is replaced by another: a constructor of the old subclass by one of the new class.
class _ReplacedBy extends _Transform {
  const _ReplacedBy(super.element, this.replacement);

  final _Element replacement;

  @override
  String title() => "Replace with '${replacement.describe()}'";

  @override
  String changes() => "      - kind: 'replacedBy'\n        newElement:\n${replacement.yaml(_uri, '          ')}";

  static String _uri = '';
}

_Element _ctor(final String cls, [final String name = '']) => _Element('constructor', name, _In.cls(cls));
_Element _method(final String cls, final String name) => _Element('method', name, _In.cls(cls));
_Element _function(final String name) => _Element('function', name);

/// Renames of members of one class: getters and methods.
List<_Transform> _members(
  final String cls, {
  final Map<String, String> getters = const <String, String>{},
  final Map<String, String> methods = const <String, String>{},
}) => <_Transform>[
  for (final MapEntry<String, String> e in getters.entries) _Rename(_Element('getter', e.key, _In.cls(cls)), e.value),
  for (final MapEntry<String, String> e in methods.entries) _Rename(_Element('method', e.key, _In.cls(cls)), e.value),
];

/// A deprecated subclass [old] of [now] whose unnamed constructor takes [parameters]' old names.
List<_Transform> _subclass(final String old, final String now, final Map<String, String> parameters) => <_Transform>[
  _Rename(_Element('class', old), now),
  _ReplacedBy(_ctor(old), _ctor(now)),
  _Parameters(_ctor(old), parameters),
];

/// Every old type name that is now a deprecated typedef of the new one (lib/src/deprecated.dart).
const List<(String, String)> _typedefs = <(String, String)>[
  ('HarborSea', 'HarborRoot'),
  ('Harbor', 'HarborFrame'),
  ('HarborDockKind', 'HarborBarKind'),
  ('HarborDockState', 'HarborBarState'),
  ('HarborCoastStance', 'HarborSystemEdgeStance'),
  ('HarborSliverDock', 'HarborSliverBar'),
  ('HarborPontoonHandle', 'HarborAttachedBarHandle'),
  ('HarborMakeWay', 'HarborHideBar'),
  ('HarborCoastFeature', 'HarborSystemEdgeFeature'),
  ('HarborTide', 'HarborKeyboard'),
  ('HarborTidePhase', 'HarborKeyboardPhase'),
  ('HarborTideStance', 'HarborKeyboardStance'),
  ('HarborDryDock', 'HarborKeyboardSpace'),
  ('HarborTideSource', 'HarborKeyboardSource'),
  ('HarborWaters', 'HarborRoom'),
  ('HarborWatersData', 'HarborRoomData'),
  ('HarborWatersAspect', 'HarborRoomAspect'),
  ('HarborCastOff', 'HarborHandled'),
  ('HarborMoored', 'HarborClear'),
  ('HarborFairwaySliver', 'HarborSliverClear'),
  ('HarborWakeKind', 'HarborEdgeEffectKind'),
  ('HarborWakePainter', 'HarborEdgeEffectPainter'),
  ('HarborFlares', 'HarborToasts'),
  ('HarborFlareSlot', 'HarborToastSlot'),
  ('HarborFlareTarget', 'HarborToastTarget'),
  ('HarborFlareEntry', 'HarborToastEntry'),
  ('HarborFlareClosedReason', 'HarborToastClosedReason'),
  ('HarborFlarePhase', 'HarborToastPhase'),
  ('HarborFlareQueue', 'HarborToastQueue'),
  ('HarborFlareHold', 'HarborToastHold'),
  ('HarborFlareTransitionBuilder', 'HarborToastTransitionBuilder'),
  ('HarborBreakwater', 'HarborPageCover'),
  ('HarborBeacon', 'HarborKeepInSight'),
  ('HarborLighthouse', 'HarborKeepInSight'),
  ('HarborLighthouseRegion', 'HarborKeepInSightRegion'),
  ('HarborChart', 'HarborInspector'),
  ('HarborChartOverlay', 'HarborInspectorOverlay'),
  ('HarborFleet', 'HarborFrameRegistry'),
  ('HarborFleetObserver', 'HarborFrameObserver'),
  ('HarborScaleModel', 'HarborScaledScreen'),
];

List<_Transform> _harbor() {
  const Map<String, String> dockParameters = <String, String>{
    'wake': 'edgeEffect',
    'tide': 'keyboard',
    'coast': 'systemEdges',
  };
  const Map<String, String> roomData = <String, String>{
    'coast': 'systemEdges',
    'coastSteady': 'systemEdgesSteady',
    'docks': 'bars',
    'docksResting': 'barsResting',
    'wakes': 'fadeBands',
    'hasDocks': 'hasBars',
    'wakesPainted': 'fadeBandsPainted',
  };
  const Map<String, String> scrollView = <String, String>{
    'mooringLine': 'rowInsets',
    'bars': 'clearsBars',
    'tide': 'clearsKeyboard',
    'wake': 'edgeEffects',
    'startsInOpenWater': 'startsUnderBars',
  };
  const Map<String, String> clear = <String, String>{
    'bars': 'clearsBars',
    'tide': 'clearsKeyboard',
    'mooringLine': 'rowInsets',
    'extra': 'padding',
  };
  const Map<String, String> sheet = <String, String>{
    'headerWake': 'headerEdgeEffect',
    'footerWake': 'footerEdgeEffect',
    'footerTide': 'footerKeyboard',
    'clearsTopCoast': 'clearsTopSystemEdge',
    'bodyClearsTide': 'bodyClearsKeyboard',
  };
  const Map<String, String> frame = <String, String>{
    'buoys': 'floats',
    'coast': 'systemEdges',
    'newPort': 'isPage',
    'bodyClearsTide': 'bodyClearsKeyboard',
    'wakePainter': 'edgeEffectPainter',
    'dockHinge': 'barHinge',
  };
  const Map<String, String> records = <String, String>{'clearWater': 'room', 'docks': 'bars', 'tide': 'keyboard'};
  const Map<String, String> paddingOf = <String, String>{
    'mooringLine': 'rowInsets',
    'bars': 'clearsBars',
    'tide': 'clearsKeyboard',
  };
  return <_Transform>[
    for (final (String old, String now) in _typedefs) _Rename(_Element('typedef', old), now),

    // HarborDock was a deprecated subclass of HarborBar, removed at 1.0. Its class rename takes
    // `HarborDock.pier(...)` to `HarborBar.pier(...)`, and these, keyed on HarborBar, take that to
    // the constructor it is now, with its old parameters renamed.
    const _Rename(_Element('class', 'HarborDock'), 'HarborBar'),
    for (final (String old, String now) in <(String, String)>[
      ('pier', 'overlay'),
      ('quay', 'solid'),
      ('reserve', 'reserve'),
    ]) ...<_Transform>[
      _Parameters(
        _ctor('HarborBar', old),
        old == 'reserve' ? const <String, String>{'tide': 'keyboard', 'coast': 'systemEdges'} : dockParameters,
      ),
      if (old != now) _Rename(_ctor('HarborBar', old), now),
    ],
    // HarborBuoy is a deprecated subclass of HarborFloat too: placement.yaml renames its deprecated
    // anchored constructor to the unnamed one, which a typedef cannot carry. Its constructors keep
    // their names.
    const _Rename(_Element('class', 'HarborBuoy'), 'HarborFloat'),
    _ReplacedBy(_ctor('HarborBuoy'), _ctor('HarborFloat')),
    _ReplacedBy(_ctor('HarborBuoy', 'anchored'), _ctor('HarborFloat', 'anchored')),
    // HarborCoast, HarborWake and HarborFairway are deprecated subclasses too: a fix on a named
    // constructor's arguments (calmTide:, dockOpacity:, box's tide:) reached through a typedef lands
    // the typedef's rename on the constructor. Their statics (ambient, none, paddingOf) are on the
    // subclass too, and the class rename takes them to the new class.
    const _Rename(_Element('class', 'HarborCoast'), 'HarborSystemEdges'),
    _ReplacedBy(_ctor('HarborCoast', 'fixed'), _ctor('HarborSystemEdges', 'fixed')),
    _Parameters(_ctor('HarborCoast', 'fixed'), const <String, String>{'calmTide': 'ignoresKeyboard'}),
    _ReplacedBy(_ctor('HarborCoast', 'titleSafe'), _ctor('HarborSystemEdges', 'titleSafe')),
    const _Rename(_Element('class', 'HarborWake'), 'HarborEdgeEffect'),
    _ReplacedBy(_ctor('HarborWake', 'fade'), _ctor('HarborEdgeEffect', 'fade')),
    _Parameters(_ctor('HarborWake', 'fade'), const <String, String>{'dockOpacity': 'faceOpacity'}),
    _ReplacedBy(_ctor('HarborWake', 'hairline'), _ctor('HarborEdgeEffect', 'hairline')),
    const _Rename(_Element('class', 'HarborFairway'), 'HarborScrollView'),
    _ReplacedBy(_ctor('HarborFairway'), _ctor('HarborScrollView')),
    _Parameters(_ctor('HarborFairway'), scrollView),
    _ReplacedBy(_ctor('HarborFairway', 'box'), _ctor('HarborScrollView', 'box')),
    _Parameters(_ctor('HarborFairway', 'box'), scrollView),
    _Parameters(_method('HarborFairway', 'paddingOf'), paddingOf),
    // Seven more are deprecated subclasses that take the old names of their parameters, so the new
    // constructors keep them required: each is renamed with `class:`, its constructor replaced, and
    // its old parameters renamed, keyed on the old class that declares them.
    ..._subclass('HarborTideState', 'HarborKeyboardState', const <String, String>{
      'highWater': 'settledHeight',
      'highWaterIsEstimate': 'settledHeightIsEstimate',
    }),
    ..._subclass('HarborWakeBand', 'HarborFadeBand', const <String, String>{
      'dockEdge': 'barFace',
      'wakeEnd': 'fadeEnd',
      'dockOpacity': 'faceOpacity',
    }),
    ..._subclass('HarborWakeMask', 'HarborFadeMask', const <String, String>{
      'wakes': 'bands',
      'dockOpacity': 'faceOpacity',
    }),
    // HarborWakeMask.alphaWake is a static of the subclass; HarborFadeMask keeps one too, so the
    // rename lands whichever class the expression names by the time it runs.
    ..._members('HarborWakeMask', methods: const <String, String>{'alphaWake': 'alphaFade'}),
    ..._subclass('HarborPortalBuoy', 'HarborPopover', const <String, String>{'buoyBuilder': 'popoverBuilder'}),
    ..._subclass('HarborPontoon', 'HarborAttachedBar', const <String, String>{'dock': 'bar'}),
    ..._subclass('HarborDockRecord', 'HarborBarRecord', const <String, String>{'tide': 'keyboard'}),
    ..._subclass('HarborChartEntry', 'HarborInspectorEntry', records),
    // HarborMooringLine(follow:, child:) is HarborClear.rowInsets(follow:, child:).
    _ReplacedBy(_ctor('HarborMooringLine'), _ctor('HarborClear', 'rowInsets')),

    // The frame and the root.
    _Parameters(_ctor('HarborFrame'), frame),
    ..._members('HarborFrame', getters: frame),
    _Parameters(_ctor('HarborRoot'), const <String, String>{'coast': 'systemEdges'}),
    ..._members('HarborRoot', getters: const <String, String>{'coast': 'systemEdges'}),

    // Bars.
    ..._members('HarborBar', getters: <String, String>{...dockParameters, 'effectiveCoast': 'effectiveSystemEdges'}),
    _Parameters(_method('HarborBar', 'copyWith'), const <String, String>{'tide': 'keyboard'}),
    ..._members('HarborBarRecord', getters: const <String, String>{'tide': 'keyboard'}),
    ..._members('HarborAttachedBar', getters: const <String, String>{'dock': 'bar'}),
    ..._members('HarborAttachedBarHandle', getters: const <String, String>{'dock': 'bar'}),

    // The system edges and the keyboard.
    _Parameters(_ctor('HarborSystemEdges', 'fixed'), const <String, String>{'calmTide': 'ignoresKeyboard'}),
    ..._members('HarborSystemEdges', getters: const <String, String>{'calmTide': 'ignoresKeyboard'}),
    ..._members('HarborKeyboard', methods: const <String, String>{'isInOf': 'isShownOf'}),
    ..._members(
      'HarborKeyboardState',
      getters: const <String, String>{
        'highWater': 'settledHeight',
        'highWaterIsEstimate': 'settledHeightIsEstimate',
        'isIn': 'isShown',
      },
    ),
    _Parameters(_ctor('HarborKeyboardSpace'), const <String, String>{'showsChildAtHighTide': 'showsChildWithKeyboard'}),
    ..._members(
      'HarborKeyboardSpace',
      getters: const <String, String>{'showsChildAtHighTide': 'showsChildWithKeyboard'},
    ),

    // The room.
    ..._members(
      'HarborRoom',
      methods: const <String, String>{'steadyCoastOf': 'steadySystemEdgeOf', 'dockFaceOf': 'barFaceOf'},
    ),
    _Parameters(_method('HarborRoom', 'clearanceOf'), const <String, String>{'tide': 'clearsKeyboard'}),
    _Parameters(_ctor('HarborRoomData'), roomData),
    _Parameters(_method('HarborRoomData', 'copyWith'), roomData),
    ..._members(
      'HarborRoomData',
      getters: roomData,
      methods: const <String, String>{'castOff': 'handled', 'wakeOf': 'fadeBandOf'},
    ),
    _Parameters(_ctor('HarborHandled'), const <String, String>{'tide': 'clearsKeyboard', 'docks': 'clearsBars'}),
    ..._members('HarborHandled', getters: const <String, String>{'tide': 'clearsKeyboard', 'docks': 'clearsBars'}),
    _Parameters(_ctor('HarborLayoutRecord'), records),
    ..._members('HarborLayoutRecord', getters: records),
    // The controller's internals (edgesWithBars, withBarOn, attachedBarsOn, the page-cover readings,
    // toasts) went @internal after 0.9.1, so their 0.8 names are not renamed onto them: a fix would
    // trade a deprecation for invalid_use_of_internal_member. They stay deprecated until 1.0.
    ..._members(
      'HarborController',
      getters: const <String, String>{'clearWater': 'room', 'fleet': 'registry', 'isPort': 'isPage'},
      methods: const <String, String>{
        'clearWaterInGlobal': 'roomInGlobal',
        'makeWay': 'hideBar',
        'addPontoon': 'attachBar',
        'updatePontoon': 'updateAttachedBar',
        'removePontoon': 'detachBar',
        'addBreakwater': 'addPageCover',
        'addBreakwaterEdge': 'addPageCoverEdge',
      },
    ),

    // Content that keeps clear.
    _Parameters(_ctor('HarborClear'), clear),
    _Parameters(_method('HarborClear', 'clearanceOf'), clear),
    ..._members('HarborClear', getters: clear),

    // Scroll views.
    _Parameters(_ctor('HarborScrollView'), scrollView),
    _Parameters(_ctor('HarborScrollView', 'box'), scrollView),
    _Parameters(_method('HarborScrollView', 'paddingOf'), paddingOf),
    ..._members('HarborScrollView', getters: scrollView),
    _Parameters(_ctor('HarborSliverClear'), const <String, String>{'bars': 'clearsBars', 'tide': 'clearsKeyboard'}),
    ..._members('HarborSliverClear', getters: const <String, String>{'bars': 'clearsBars', 'tide': 'clearsKeyboard'}),

    // The edge effect.
    _Parameters(_ctor('HarborEdgeEffect', 'fade'), const <String, String>{'dockOpacity': 'faceOpacity'}),
    ..._members('HarborEdgeEffect', getters: const <String, String>{'dockOpacity': 'faceOpacity'}),
    ..._members(
      'HarborFadeBand',
      getters: const <String, String>{'dockEdge': 'barFace', 'wakeEnd': 'fadeEnd', 'dockOpacity': 'faceOpacity'},
    ),
    ..._members(
      'HarborFadeMask',
      getters: const <String, String>{'wakes': 'bands', 'dockOpacity': 'faceOpacity'},
      methods: const <String, String>{'alphaWake': 'alphaFade'},
    ),

    // Popovers and toasts.
    ..._members('HarborPopover', getters: const <String, String>{'buoyBuilder': 'popoverBuilder'}),
    ..._members('HarborToasts', methods: const <String, String>{'raise': 'show'}),
    _Parameters(_method('HarborToasts', 'raise'), const <String, String>{'reachesCoast': 'reachesSystemEdges'}),
    // raisedIn and reachesCoast went with shownFrom and reachesSystemEdges at 1.0: no rename left.
    ..._members('HarborToastEntry', methods: const <String, String>{'lower': 'hide'}),
    ..._members('HarborFrameRegistry', getters: const <String, String>{'harbors': 'frames', 'sea': 'root'}),

    // Sheets and dialogs.
    _Parameters(_function('showHarborSheet'), const <String, String>{
      'breakwater': 'coversPage',
      'keepsTopCoast': 'reachesTop',
    }),
    _Parameters(_ctor('HarborSheet'), sheet),
    _Parameters(_ctor('HarborSheet', 'draggable'), sheet),
    ..._members('HarborSheet', getters: sheet),
    _Parameters(_function('showHarborDialog'), const <String, String>{'inheritClearWater': 'inheritRoom'}),
    _Parameters(_ctor('HarborDialogRoute'), const <String, String>{'inheritClearWater': 'inheritRoom'}),
    ..._members('HarborDialogRoute', getters: const <String, String>{'inheritClearWater': 'inheritRoom'}),

    // The inspector and the scaled screen.
    ..._members('HarborInspectorEntry', getters: records),
    _Parameters(_ctor('HarborScaledScreen'), const <String, String>{'coast': 'systemEdges'}),
    ..._members('HarborScaledScreen', getters: const <String, String>{'coast': 'systemEdges'}),
  ];
}

List<_Transform> _harborTest() {
  const Map<String, String> device = <String, String>{
    'coast': 'systemEdges',
    'tideHeight': 'keyboardHeight',
    'reportsCoastUnderTide': 'reportsSystemEdgesUnderKeyboard',
  };
  return <_Transform>[
    // `tester.pumpSeaTrial(...)`, and a bare `pumpSeaTrial(...)` inside an extension on WidgetTester,
    // match by the target's type. The explicit `HarborSeaTrials(tester).pumpSeaTrial(...)` matched
    // `inExtension: 'HarborSeaTrials'` until 1.0 removed it; the extension rename below still takes
    // it to `HarborTrials(tester).pumpSeaTrial(...)`, and keyed on HarborTrials (`inExtension:` or
    // `inClass:`) the method is not matched: the analyzer offers no data-driven fix for a method an
    // extension override does not have (measured, Dart 3.13; DECISIONS.md, "Fix data after 1.0").
    const _Rename(_Element('method', 'pumpSeaTrial', _In.cls('WidgetTester')), 'pumpHarborTrial'),
    const _Parameters(_Element('method', 'pumpSeaTrial', _In.cls('WidgetTester')), <String, String>{
      'tideIn': 'keyboardShown',
    }),
    // After the method renames, never before (#143): a bare `pumpSeaTrial(...)` inside an extension
    // on WidgetTester matches this transform too, so both rename the same name and the first one
    // listed is the one applied. Listed first, this turned it into `HarborTrials(...)`.
    const _Rename(_Element('extension', 'HarborSeaTrials'), 'HarborTrials'),
    const _Rename(_Element('typedef', 'HarborSeaTrial'), 'HarborTrial'),
    ..._members(
      'HarborTrial',
      getters: const <String, String>{'tideIn': 'keyboardShown', 'waterline': 'keyboardTop'},
      methods: const <String, String>{
        'raiseTide': 'showKeyboard',
        'lowerTide': 'hideKeyboard',
        'setTide': 'setKeyboard',
        'clearWaterAround': 'roomAround',
        'docksAround': 'barsAround',
      },
    ),
    _Parameters(_method('HarborTrial', 'setTide'), const <String, String>{'tideIn': 'shown'}),
    _Rename(_function('isInClearWater'), 'isInRoom'),
    _Parameters(_ctor('HarborTrialDevice'), device),
    _Parameters(_method('HarborTrialDevice', 'copyWith'), device),
    ..._members('HarborTrialDevice', getters: device, methods: const <String, String>{'coastWhen': 'systemEdgesWhen'}),
    _Parameters(_method('HarborTrialDevice', 'coastWhen'), const <String, String>{'tideIn': 'keyboardShown'}),
  ];
}

String _file(final String uri, final String about, final List<_Transform> transforms) {
  _ReplacedBy._uri = uri;
  final StringBuffer out = StringBuffer()
    ..writeln('# GENERATED by tool/fix_data/rename.dart; edit that, then run it. tool/check.sh fails while')
    ..writeln('# this file and the generator disagree.')
    ..writeln('#')
    ..writeln('# `dart fix` transforms for the rename (0.9.0, #120): $about')
    ..writeln('# doc/design/naming.md is the table. Each family is checked by a golden in test_fixes/.')
    ..writeln('version: 1')
    ..writeln('transforms:');
  for (final _Transform t in transforms) {
    out.write(t.yaml(uri));
  }
  return out.toString();
}

void main(final List<String> args) {
  final Map<String, String> files = <String, String>{
    '../../lib/fix_data/rename.yaml': _file(
      'harbor.dart',
      "harbor's harbour words became the layout model's.",
      _harbor(),
    ),
    '../../harbor_test/lib/fix_data.yaml': _file(
      'harbor_test.dart',
      "harbor_test's sea trials became trials.",
      _harborTest(),
    ),
  };
  bool stale = false;
  for (final MapEntry<String, String> f in files.entries) {
    final File file = File.fromUri(Platform.script.resolve(f.key));
    if (args.contains('--check')) {
      if (!file.existsSync() || file.readAsStringSync() != f.value) {
        stderr.writeln('${file.path} is out of date: run dart run tool/fix_data/rename.dart');
        stale = true;
      }
    } else {
      file.writeAsStringSync(f.value);
    }
  }
  if (stale) {
    exit(1);
  }
}
