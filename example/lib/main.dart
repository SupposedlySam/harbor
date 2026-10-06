import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import 'art/palette.dart';
import 'game/settings.dart';
import 'scenes/tv.dart';
import 'shell.dart';

void main() => runApp(const HarborMasterApp());

/// Harbor Master: a small harbor game that puts every harbor pattern
/// through its paces. Each scene says which pattern it shows and what to try.
class HarborMasterApp extends StatefulWidget {
  const HarborMasterApp({super.key});

  @override
  State<HarborMasterApp> createState() => _HarborMasterAppState();
}

class _HarborMasterAppState extends State<HarborMasterApp> {
  final HarborSettings _settings = HarborSettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => HarborSettingsScope(
    settings: _settings,
    child: ListenableBuilder(
      listenable: _settings,
      builder: (final BuildContext context, final Widget? _) => MaterialApp(
        key: ValueKey<bool>(_settings.tv),
        title: 'Harbor Master',
        debugShowCheckedModeBanner: false,
        theme: Palette.theme(),
        builder: (final BuildContext context, final Widget? child) {
          final Widget sea = HarborChartOverlay(
            enabled: _settings.chart,
            child: HarborSea(
              margin: EdgeInsetsDirectional.symmetric(horizontal: _settings.tv ? 32 : 16),
              child: child!,
            ),
          );
          final Widget directed = Directionality(
            textDirection: _settings.rtl ? TextDirection.rtl : TextDirection.ltr,
            child: sea,
          );
          if (!_settings.tv) {
            return directed;
          }
          // A TV: a 1200×675 reference screen with a 5% title-safe coast.
          return HarborScaleModel(
            referenceSize: const Size(1200, 675),
            coast: const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)),
            child: directed,
          );
        },
        home: _settings.tv ? const TvHarborTown() : const HarborTown(),
      ),
    ),
  );
}
