import 'package:flutter/material.dart';

import '../art/boats.dart';
import '../art/palette.dart';

/// A boat in the harbor's fleet.
@immutable
class Boat {
  const Boat({
    required this.id,
    required this.name,
    required this.kind,
    required this.hull,
    required this.captain,
    required this.homePort,
    required this.voyages,
    required this.knots,
    this.flag,
  });

  final int id;
  final String name;
  final BoatKind kind;
  final Color hull;
  final String captain;
  final String homePort;
  final int voyages;
  final double knots;
  final Color? flag;

  String get kindLabel => switch (kind) {
    BoatKind.sailboat => 'Sailboat',
    BoatKind.tug => 'Tugboat',
    BoatKind.ferry => 'Ferry',
    BoatKind.rowboat => 'Rowboat',
    BoatKind.trawler => 'Trawler',
    BoatKind.yacht => 'Yacht',
  };
}

/// A sailor who crews the fleet.
@immutable
class Sailor {
  const Sailor(this.name, this.role, this.color);

  final String name;
  final String role;
  final Color color;
}

/// A message on a radio channel.
@immutable
class RadioCall {
  const RadioCall({required this.from, required this.text, required this.mine, required this.minutesAgo});

  final String from;
  final String text;
  final bool mine;
  final int minutesAgo;
}

/// A channel boats talk on.
@immutable
class RadioChannel {
  const RadioChannel({required this.name, required this.frequency, required this.calls});

  final String name;
  final String frequency;
  final List<RadioCall> calls;
}

/// The harbor's ledger of everything afloat.
abstract final class Fleet {
  static const List<String> _names = <String>[
    'Saltwind',
    'Barnacle Belle',
    'Tidewalker',
    'Little Gull',
    'Northern Star',
    'Kelp Runner',
    'Mistral',
    'Driftwood',
    'Sea Biscuit',
    'Halyard',
    'Moonraker',
    'Brine Queen',
    'Puffin',
    'Old Faithful',
    'Squall',
    'Marigold',
    'Anchorage',
    'Skipjack',
    'Lantern',
    'Cormorant',
    'Fathom',
    'Bluefin',
    'Wanderlust',
    'Spindrift',
  ];

  static const List<String> _captains = <String>[
    'Captain Ada',
    'Captain Bo',
    'Captain Cyra',
    'Captain Dev',
    'Captain Esme',
    'Captain Fen',
    'Captain Gil',
    'Captain Hana',
  ];

  static const List<String> _ports = <String>['Gullhaven', 'Kelp Cove', 'Saltmarsh', 'Brinestead', 'Foghorn Bay'];

  static final List<Boat> boats = List<Boat>.generate(_names.length, (final int i) {
    return Boat(
      id: i,
      name: _names[i],
      kind: BoatKind.values[i % BoatKind.values.length],
      hull: Palette.hulls[i % Palette.hulls.length],
      captain: _captains[i % _captains.length],
      homePort: _ports[i % _ports.length],
      voyages: 3 + (i * 7) % 41,
      knots: 6 + (i * 3) % 19 + 0.5,
      flag: i.isEven ? Palette.hulls[(i + 3) % Palette.hulls.length] : null,
    );
  });

  static const List<Sailor> crew = <Sailor>[
    Sailor('Ada', 'Navigator', Color(0xFFE57373)),
    Sailor('Bo', 'Bosun', Color(0xFF81C784)),
    Sailor('Cyra', 'Cook', Color(0xFFFFD54F)),
    Sailor('Dev', 'Deckhand', Color(0xFF64B5F6)),
    Sailor('Esme', 'Engineer', Color(0xFFBA68C8)),
    Sailor('Fen', 'Lookout', Color(0xFF4DB6AC)),
    Sailor('Gil', 'Rigger', Color(0xFFFF8A65)),
    Sailor('Hana', 'Helm', Color(0xFFA1887F)),
    Sailor('Ivo', 'Purser', Color(0xFF90A4AE)),
    Sailor('Juno', 'Signaler', Color(0xFFF06292)),
  ];

  static final List<RadioChannel> channels = <RadioChannel>[
    RadioChannel(name: 'Harbor Control', frequency: 'Ch 16', calls: _calls('Harbor Control', 40)),
    RadioChannel(name: 'Fishing Fleet', frequency: 'Ch 9', calls: _calls('Skipjack', 25)),
    RadioChannel(name: 'Ferry Ops', frequency: 'Ch 12', calls: _calls('Old Faithful', 18)),
    RadioChannel(name: 'Regatta Chat', frequency: 'Ch 72', calls: _calls('Mistral', 32)),
  ];

  static const List<String> _lines = <String>[
    'Fog rolling in past the breakwater.',
    'Requesting a berth on the east quay.',
    'Copy that, berth four is clear.',
    'Anyone seen my spare oar?',
    'Tide turns at half past.',
    'Gulls are after the catch again!',
    'Lighthouse beam looks lovely tonight.',
    'Coming about, mind the wake.',
    'Cargo for Kelp Cove is loaded.',
    'Swell is picking up out west.',
  ];

  static List<RadioCall> _calls(final String from, final int count) => List<RadioCall>.generate(
    count,
    (final int i) => RadioCall(
      from: i % 3 == 0 ? 'You' : from,
      text: _lines[(i * 7 + from.length) % _lines.length],
      mine: i % 3 == 0,
      minutesAgo: i * 4 + 1,
    ),
  );
}
