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
//  * A renamed enum value is a deprecated `static const` on the new enum: a `field` `inClass`.
//  * A class whose named constructors are renamed is a deprecated subclass (HarborDock), renamed
//    with `class:`; each of its constructors is `replacedBy` the new one.
//  * An extension cannot be aliased, so the old one (HarborSeaTrials) is an extension of its own,
//    holding only the old method names, renamed with `extension:`. Its method matches `inExtension:`
//    only where the extension is applied by name; an implicit `tester.pumpSeaTrial()` matches by
//    the target's type, `inClass: 'WidgetTester'`, so it is keyed both ways.

import 'dart:io';

const String _date = '2026-10-14';

/// Where an element is declared: `inClass: 'HarborBar'`, `inExtension: 'HarborSeaTrials'`, or at
/// the top level.
class _In {
  const _In.cls(this.name) : key = 'inClass';

  const _In.ext(this.name) : key = 'inExtension';

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

/// Renames of members of one class: getters, methods and enum values.
List<_Transform> _members(
  final String cls, {
  final Map<String, String> getters = const <String, String>{},
  final Map<String, String> methods = const <String, String>{},
  final Map<String, String> values = const <String, String>{},
}) => <_Transform>[
  for (final MapEntry<String, String> e in values.entries) _Rename(_Element('field', e.key, _In.cls(cls)), e.value),
  for (final MapEntry<String, String> e in getters.entries) _Rename(_Element('getter', e.key, _In.cls(cls)), e.value),
  for (final MapEntry<String, String> e in methods.entries) _Rename(_Element('method', e.key, _In.cls(cls)), e.value),
];

/// Every old type name that is now a deprecated typedef of the new one (lib/src/deprecated.dart).
const List<(String, String)> _typedefs = <(String, String)>[
  ('HarborSea', 'HarborRoot'),
  ('Harbor', 'HarborFrame'),
  ('HarborDockKind', 'HarborBarKind'),
  ('HarborDockState', 'HarborBarState'),
  ('HarborCoastStance', 'HarborSystemEdgeStance'),
  ('HarborDockRecord', 'HarborBarRecord'),
  ('HarborSliverDock', 'HarborSliverBar'),
  ('HarborPontoon', 'HarborAttachedBar'),
  ('HarborPontoonHandle', 'HarborAttachedBarHandle'),
  ('HarborMakeWay', 'HarborHideBar'),
  ('HarborCoastFeature', 'HarborSystemEdgeFeature'),
  ('HarborTide', 'HarborKeyboard'),
  ('HarborTideState', 'HarborKeyboardState'),
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
  ('HarborWakeBand', 'HarborFadeBand'),
  ('HarborWakePainter', 'HarborEdgeEffectPainter'),
  ('HarborWakeMask', 'HarborFadeMask'),
  ('HarborPortalBuoy', 'HarborPopover'),
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
  ('HarborChartEntry', 'HarborInspectorEntry'),
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
    'wakes': 'edgeEffects',
    'hasDocks': 'hasBars',
    'wakesPainted': 'edgeEffectsPainted',
  };
  const Map<String, String> scrollView = <String, String>{
    'mooringLine': 'rowInsets',
    'tide': 'keyboard',
    'wake': 'edgeEffects',
    'startsInOpenWater': 'startsUnderBars',
  };
  const Map<String, String> clear = <String, String>{
    'tide': 'keyboard',
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
  return <_Transform>[
    for (final (String old, String now) in _typedefs) _Rename(_Element('typedef', old), now),

    // HarborDock is a deprecated subclass of HarborBar, so its renamed constructors can be replaced.
    const _Rename(_Element('class', 'HarborDock'), 'HarborBar'),
    for (final (String old, String now) in <(String, String)>[
      ('pier', 'overlay'),
      ('quay', 'solid'),
      ('reserve', 'reserve'),
    ]) ...<_Transform>[
      _ReplacedBy(_ctor('HarborDock', old), _ctor('HarborBar', now)),
      _Parameters(
        _ctor('HarborDock', old),
        old == 'reserve' ? const <String, String>{'tide': 'keyboard', 'coast': 'systemEdges'} : dockParameters,
      ),
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
    _Parameters(_method('HarborFairway', 'paddingOf'), const <String, String>{
      'mooringLine': 'rowInsets',
      'tide': 'keyboard',
    }),
    // HarborMooringLine(follow:, child:) is HarborClear.rowInsets(follow:, child:).
    _ReplacedBy(_ctor('HarborMooringLine'), _ctor('HarborClear', 'rowInsets')),

    // The frame and the root.
    _Parameters(_ctor('HarborFrame'), frame),
    ..._members('HarborFrame', getters: frame),
    _Parameters(_ctor('HarborRoot'), const <String, String>{'coast': 'systemEdges'}),
    ..._members('HarborRoot', getters: const <String, String>{'coast': 'systemEdges'}),

    // Bars.
    ..._members('HarborBarKind', values: const <String, String>{'pier': 'overlay', 'quay': 'solid'}),
    ..._members('HarborBar', getters: <String, String>{...dockParameters, 'effectiveCoast': 'effectiveSystemEdges'}),
    _Parameters(_method('HarborBar', 'copyWith'), const <String, String>{'tide': 'keyboard'}),
    _Parameters(_ctor('HarborBarRecord'), const <String, String>{'tide': 'keyboard'}),
    ..._members('HarborBarRecord', getters: const <String, String>{'tide': 'keyboard'}),
    _Parameters(_ctor('HarborAttachedBar'), const <String, String>{'dock': 'bar'}),
    ..._members('HarborAttachedBar', getters: const <String, String>{'dock': 'bar'}),
    ..._members('HarborAttachedBarHandle', getters: const <String, String>{'dock': 'bar'}),

    // The system edges and the keyboard.
    _Parameters(_ctor('HarborSystemEdges', 'fixed'), const <String, String>{'calmTide': 'ignoresKeyboard'}),
    ..._members('HarborSystemEdges', getters: const <String, String>{'calmTide': 'ignoresKeyboard'}),
    ..._members('HarborKeyboard', methods: const <String, String>{'isInOf': 'isShownOf'}),
    _Parameters(_ctor('HarborKeyboardState'), const <String, String>{
      'highWater': 'settledHeight',
      'highWaterIsEstimate': 'settledHeightIsEstimate',
    }),
    ..._members(
      'HarborKeyboardState',
      getters: const <String, String>{
        'highWater': 'settledHeight',
        'highWaterIsEstimate': 'settledHeightIsEstimate',
        'isIn': 'isShown',
      },
    ),
    ..._members(
      'HarborKeyboardPhase',
      values: const <String, String>{'low': 'hidden', 'rising': 'opening', 'high': 'shown', 'falling': 'closing'},
    ),
    ..._members(
      'HarborKeyboardStance',
      values: const <String, String>{'float': 'rides', 'pilings': 'stays', 'dryDock': 'reserves'},
    ),
    _Parameters(_ctor('HarborKeyboardSpace'), const <String, String>{'showsChildAtHighTide': 'showsChildWhileShown'}),
    ..._members('HarborKeyboardSpace', getters: const <String, String>{'showsChildAtHighTide': 'showsChildWhileShown'}),

    // The room.
    ..._members(
      'HarborRoom',
      methods: const <String, String>{'steadyCoastOf': 'steadySystemEdgeOf', 'dockFaceOf': 'barFaceOf'},
    ),
    _Parameters(_method('HarborRoom', 'clearanceOf'), const <String, String>{'tide': 'keyboard'}),
    _Parameters(_ctor('HarborRoomData'), roomData),
    _Parameters(_method('HarborRoomData', 'copyWith'), roomData),
    ..._members(
      'HarborRoomData',
      getters: roomData,
      methods: const <String, String>{'castOff': 'handled', 'wakeOf': 'edgeEffectOf'},
    ),
    ..._members('HarborRoomAspect', values: const <String, String>{'coast': 'systemEdges', 'docks': 'bars'}),
    _Parameters(_ctor('HarborHandled'), const <String, String>{'tide': 'keyboard', 'docks': 'bars'}),
    ..._members('HarborHandled', getters: const <String, String>{'tide': 'keyboard', 'docks': 'bars'}),
    _Parameters(_ctor('HarborLayoutRecord'), records),
    ..._members('HarborLayoutRecord', getters: records),
    ..._members(
      'HarborController',
      getters: const <String, String>{
        'clearWater': 'room',
        'fleet': 'registry',
        'isPort': 'isPage',
        'dockedEdges': 'edgesWithBars',
        'breakwaterTopsInGlobal': 'pageCoverTopsInGlobal',
        'breakwaterCoverage': 'pageCoverage',
        'breakwaterChanges': 'pageCoverChanges',
        'flares': 'toasts',
      },
      methods: const <String, String>{
        'clearWaterInGlobal': 'roomInGlobal',
        'withDockOn': 'withBarOn',
        'makeWay': 'hideBar',
        'addPontoon': 'attachBar',
        'updatePontoon': 'updateAttachedBar',
        'removePontoon': 'detachBar',
        'pontoonsOn': 'attachedBarsOn',
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
    _Parameters(_method('HarborScrollView', 'paddingOf'), const <String, String>{
      'mooringLine': 'rowInsets',
      'tide': 'keyboard',
    }),
    ..._members('HarborScrollView', getters: scrollView),
    _Parameters(_ctor('HarborSliverClear'), const <String, String>{'tide': 'keyboard'}),
    ..._members('HarborSliverClear', getters: const <String, String>{'tide': 'keyboard'}),

    // The edge effect.
    _Parameters(_ctor('HarborEdgeEffect', 'fade'), const <String, String>{'dockOpacity': 'faceOpacity'}),
    ..._members('HarborEdgeEffect', getters: const <String, String>{'dockOpacity': 'faceOpacity'}),
    ..._members('HarborRest', values: const <String, String>{'wakeEnd': 'fadeEnd', 'dockEdge': 'barFace'}),
    _Parameters(_ctor('HarborFadeBand'), const <String, String>{
      'dockEdge': 'barFace',
      'wakeEnd': 'fadeEnd',
      'dockOpacity': 'faceOpacity',
    }),
    ..._members(
      'HarborFadeBand',
      getters: const <String, String>{'dockEdge': 'barFace', 'wakeEnd': 'fadeEnd', 'dockOpacity': 'faceOpacity'},
    ),
    _Parameters(_ctor('HarborFadeMask'), const <String, String>{'wakes': 'edgeEffects', 'dockOpacity': 'faceOpacity'}),
    ..._members(
      'HarborFadeMask',
      getters: const <String, String>{'wakes': 'edgeEffects', 'dockOpacity': 'faceOpacity'},
      methods: const <String, String>{'alphaWake': 'alphaFade'},
    ),

    // Popovers and toasts.
    _Parameters(_ctor('HarborPopover'), const <String, String>{'buoyBuilder': 'popoverBuilder'}),
    ..._members('HarborPopover', getters: const <String, String>{'buoyBuilder': 'popoverBuilder'}),
    ..._members('HarborToasts', methods: const <String, String>{'raise': 'show'}),
    _Parameters(_method('HarborToasts', 'raise'), const <String, String>{'reachesCoast': 'reachesSystemEdges'}),
    ..._members('HarborToastTarget', values: const <String, String>{'sea': 'root'}),
    ..._members('HarborToastClosedReason', values: const <String, String>{'lower': 'hide'}),
    ..._members(
      'HarborToastEntry',
      getters: const <String, String>{'raisedIn': 'shownFrom', 'reachesCoast': 'reachesSystemEdges'},
      methods: const <String, String>{'lower': 'hide'},
    ),
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
    _Parameters(_ctor('HarborInspectorEntry'), records),
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
    const _Rename(_Element('extension', 'HarborSeaTrials'), 'HarborTrials'),
    // `tester.pumpSeaTrial(...)` matches by the target's type, WidgetTester; only the explicit
    // `HarborSeaTrials(tester).pumpSeaTrial(...)` matches by the extension. Both are needed, or the
    // explicit form is left calling a method HarborTrials does not have.
    for (final _In container in const <_In>[_In.ext('HarborSeaTrials'), _In.cls('WidgetTester')]) ...<_Transform>[
      _Rename(_Element('method', 'pumpSeaTrial', container), 'pumpHarborTrial'),
      _Parameters(_Element('method', 'pumpSeaTrial', container), const <String, String>{'tideIn': 'keyboardShown'}),
    ],
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
