import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import '../showcase/phone.dart';

/// A television running a harbor in a scale model: laid out on a 1200 × 675 reference screen,
/// scaled to the set, with the title-safe band as its coast.
class WideTvSet extends StatelessWidget {
  const WideTvSet({super.key, required this.time});

  final double time;

  static const Size _screen = Size(720, 405);

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF15181C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3A3F45), width: 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox.fromSize(
            size: _screen,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: _screen,
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                textScaler: TextScaler.noScaling,
              ),
              child: Theme(
                data: ThemeData(useMaterial3: true, colorSchemeSeed: Palette.shallows, fontFamily: 'Georgia'),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    const HarborScaleModel(
                      referenceSize: Size(1200, 675),
                      coast: HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
                      child: HarborSea(child: _TvPage()),
                    ),
                    // The title-safe band, marked as a broadcast monitor marks it.
                    IgnorePointer(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: _screen.width * 0.05, vertical: _screen.height * 0.05),
                        child: DecoratedBox(
                          decoration: BoxDecoration(border: Border.all(color: Palette.brass.withValues(alpha: 0.9), width: 2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Container(width: 120, height: 14, color: const Color(0xFF2A2F35)),
      Container(width: 220, height: 8, decoration: BoxDecoration(color: const Color(0xFF2A2F35), borderRadius: BorderRadius.circular(4))),
      const SizedBox(height: 14),
      const Text('title-safe', style: TextStyle(fontFamily: 'Georgia', fontSize: 16, fontWeight: FontWeight.w700, color: Palette.brass)),
    ],
  );
}

class _TvPage extends StatelessWidget {
  const _TvPage();

  @override
  Widget build(final BuildContext context) => Material(
    color: const Color(0xFF0E2233),
    child: Harbor(
      top: const <HarborDock>[
        HarborDock.quay(
          backdrop: ColoredBox(color: Color(0xFF0E2233)),
          // On the mooring line, which on a television keeps to the title-safe band.
          child: HarborMooringLine(
            child: SizedBox(
              height: 90,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text('Harbor TV', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: Palette.brass)),
              ),
            ),
          ),
        ),
      ],
      body: HarborMoored(
        child: GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 24,
          crossAxisSpacing: 24,
          childAspectRatio: 1.5,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (int i = 0; i < 8; i++)
              Container(
                decoration: BoxDecoration(color: showcaseBoats[i].$4, borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Icon(showcaseBoats[i].$3, color: Colors.white, size: 64),
              ),
          ],
        ),
      ),
    ),
  );
}

