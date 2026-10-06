import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/palette.dart';
import '../game/fleet.dart';

/// Small parts for building what goes on a stage, so every entry's demo looks
/// alike and the class being shown is what stands out.

/// A header for a dock on the stage: a centered label, naming what it is.
class StageHeader extends StatelessWidget {
  const StageHeader({super.key, required this.title, this.height = 52, this.color = Palette.foam});

  final String title;
  final double height;
  final Color color;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: height,
    child: HarborMooringLine(
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontFamily: 'Menlo', fontSize: 15, fontWeight: FontWeight.w700, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// A bar for a bottom dock on the stage.
class StageBar extends StatelessWidget {
  const StageBar({super.key, required this.label, this.height = 56, this.icon = Icons.anchor_rounded});

  final String label;
  final double height;
  final IconData icon;

  @override
  Widget build(final BuildContext context) => SizedBox(
    height: height,
    child: HarborMooringLine(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: Palette.brass, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, fontWeight: FontWeight.w700, color: Palette.foam),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A row in a stage's list: a boat and its name.
class StageRow extends StatelessWidget {
  const StageRow({super.key, required this.index});

  final int index;

  @override
  Widget build(final BuildContext context) {
    final Boat boat = Fleet.boats[index % Fleet.boats.length];
    return HarborMooringLine(
      child: Container(
        key: ValueKey<String>('stage row $index'),
        height: 56,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Palette.foam.withValues(alpha: 0.08)))),
        child: Row(
          children: <Widget>[
            SizedBox(width: 52, child: BoatArt(kind: boat.kind, hull: boat.hull, bob: false)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${index + 1}. ${boat.name}',
                style: const TextStyle(color: Palette.foam, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labeled box that marks a widget on the stage, for showing where
/// something landed.
class StageMarker extends StatelessWidget {
  const StageMarker({super.key, required this.label, this.color = Palette.buoyRed, this.width, this.height = 48});

  final String label;
  final Color color;
  final double? width;
  final double height;

  @override
  Widget build(final BuildContext context) => Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(fontFamily: 'Menlo', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
  );
}
