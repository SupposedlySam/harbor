import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import '../showcase/caption.dart';
import '../showcase/phone.dart';
import '../showcase/plates.dart';
import '../showcase/timeline.dart';
import 'timeline.dart';
import 'tv.dart';

/// The wide-format video: what harbor does when the screen is not a phone held upright. A tablet
/// with a rail, the same in a right-to-left language, a phone on its side, a dual-screen phone and
/// a television, each running a real harbor page beside the field guide's drawing of the idea.
///
/// Laid out at 1280 × 720 and scaled to fit, as the phone tour is, and driven by [WideTimeline].
class WideShowcase extends StatelessWidget {
  const WideShowcase({super.key, required this.time});

  /// Seconds into the video, from 0 to [WideTimeline.duration].
  final double time;

  static const Size frame = Size(1280, 720);

  static const double _captionHeight = 112;
  static const double _plateWidth = 440;

  /// The field guide entries each chapter shows, one per line of its narration.
  static const Map<String, List<String>> plates = <String, List<String>>{
    'intro': <String>['frame-harbor'],
    'rail': <String>['edge'],
    'reading': <String>['edge'],
    'landscape': <String>['coast'],
    'hinge': <String>['frame-new-port'],
    'tv': <String>['coast-title-safe', 'scale-model'],
    'outro': <String>['frame-harbor'],
  };

  @override
  Widget build(final BuildContext context) {
    final ShowcaseChapter chapter = WideTimeline.chapterAt(time);
    return FittedBox(
      child: SizedBox.fromSize(
        size: frame,
        child: Material(
          color: Palette.night,
          child: Column(
            children: <Widget>[
              Expanded(
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: _plateWidth,
                      child: ClipRect(
                        child: FittedBox(
                          child: SizedBox(
                            width: 760,
                            height: 608,
                            child: ShowcasePlate(chapter: chapter, time: time, script: WideTimeline.script, entries: plates),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 20, 28, 20),
                        child: Center(child: _device(chapter)),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: _captionHeight,
                child: ShowcaseCaption(
                  term: chapter.term,
                  line: WideTimeline.lineAt(time),
                  install: chapter.key == 'outro',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _device(final ShowcaseChapter chapter) => switch (chapter.key) {
    'landscape' => const _Screen(
      key: ValueKey<String>('landscape phone'),
      size: Size(874, 402),
      padding: EdgeInsets.only(left: 62, right: 62, bottom: 21),
      radius: 54,
      island: _Island.left,
      child: _LandscapePage(),
    ),
    'hinge' => _Screen(
      key: const ValueKey<String>('dual screen'),
      size: const Size(1114, 720),
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      radius: 28,
      displayFeatures: const <DisplayFeature>[
        DisplayFeature(bounds: Rect.fromLTRB(540, 0, 574, 720), type: DisplayFeatureType.hinge, state: DisplayFeatureState.postureFlat),
      ],
      child: _HingePage(time: time),
    ),
    'tv' => WideTvSet(time: time),
    _ => _Screen(
      key: const ValueKey<String>('tablet'),
      size: const Size(1180, 820),
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      radius: 36,
      child: _RailPage(
        rightToLeft: chapter.key == 'reading' && time >= WideTimeline.cue('reading', 'right') - 0.4,
      ),
    ),
  };
}

enum _Island { none, left }

/// A device's screen: its size, its insets as the platform reports them, and any hinge, around a
/// harbor page. Drawn at its logical size and scaled to fit the stage.
class _Screen extends StatelessWidget {
  const _Screen({
    super.key,
    required this.size,
    required this.padding,
    required this.radius,
    required this.child,
    this.displayFeatures = const <DisplayFeature>[],
    this.island = _Island.none,
  });

  final Size size;
  final EdgeInsets padding;
  final double radius;
  final List<DisplayFeature> displayFeatures;
  final _Island island;
  final Widget child;

  @override
  Widget build(final BuildContext context) => FittedBox(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF15181C),
        borderRadius: BorderRadius.circular(radius + 12),
        border: Border.all(color: const Color(0xFF3A3F45), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox.fromSize(
          size: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: size,
                devicePixelRatio: 2,
                padding: padding,
                viewPadding: padding,
                viewInsets: EdgeInsets.zero,
                displayFeatures: displayFeatures,
                textScaler: TextScaler.noScaling,
              ),
              child: Theme(
                data: ThemeData(useMaterial3: true, colorSchemeSeed: Palette.shallows, fontFamily: 'Georgia'),
                child: Material(
                  color: const Color(0xFFF4F7FA),
                  child: Stack(
                    children: <Widget>[
                      HarborSea(margin: const EdgeInsetsDirectional.symmetric(horizontal: ShowcasePhone.margin), child: child),
                      for (final DisplayFeature feature in displayFeatures)
                        Positioned.fromRect(rect: feature.bounds, child: const ColoredBox(color: Color(0xFF15181C))),
                      if (island == _Island.left)
                        Positioned(
                          left: 14,
                          top: size.height / 2 - 62,
                          width: 34,
                          height: 124,
                          child: DecoratedBox(decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(17))),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A header pier. Docks span the whole frame, so a header's corner sits under a rail at the start
/// edge; [besideRail] keeps its title clear of that rail.
HarborDock _header(final String title, {final double besideRail = 0}) => HarborDock.pier(
  wake: const HarborWake.fade(length: 18, blurSigma: 14),
  backdrop: ColoredBox(color: Colors.white.withValues(alpha: 0.78)),
  child: SizedBox(
    height: 60,
    child: HarborMooringLine(
      child: Container(
        padding: EdgeInsetsDirectional.only(start: besideRail),
        alignment: AlignmentDirectional.centerStart,
        child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.deepSea)),
      ),
    ),
  ),
);

Widget _rows(final int count) => HarborFairway(
  slivers: <Widget>[
    SliverList.builder(
      itemCount: count,
      itemBuilder: (final BuildContext _, final int i) => HarborMooringLine(child: BoatRow(index: i)),
    ),
  ],
);

/// A tablet's page: a navigation rail docked at the start edge, a header, and a list moored beside
/// the rail. Turned right-to-left, the start edge is the right, and the rail goes with it.
class _RailPage extends StatelessWidget {
  const _RailPage({required this.rightToLeft});

  final bool rightToLeft;

  @override
  Widget build(final BuildContext context) => Directionality(
    textDirection: rightToLeft ? TextDirection.rtl : TextDirection.ltr,
    child: Harbor(
      start: const <HarborDock>[
        HarborDock.quay(
          backdrop: ColoredBox(color: Palette.deepSea),
          child: _Rail(),
        ),
      ],
      top: <HarborDock>[_header('Harbor Master', besideRail: _Rail.width)],
      body: _rows(16),
    ),
  );
}

class _Rail extends StatelessWidget {
  const _Rail();

  static const double width = 92;

  @override
  Widget build(final BuildContext context) => const SizedBox(
    key: ValueKey<String>('rail'),
    width: width,
    child: Column(
      children: <Widget>[
        SizedBox(height: 28),
        Icon(Icons.anchor, color: Palette.brass, size: 30),
        SizedBox(height: 34),
        Icon(Icons.map_outlined, color: Colors.white70, size: 30),
        SizedBox(height: 34),
        Icon(Icons.forum_outlined, color: Colors.white70, size: 30),
        SizedBox(height: 34),
        Icon(Icons.settings_outlined, color: Colors.white70, size: 30),
      ],
    ),
  );
}

/// A phone on its side: the header's backdrop runs under the island to the screen's edge, and the
/// rows keep their margin from the coast at each side.
class _LandscapePage extends StatelessWidget {
  const _LandscapePage();

  @override
  Widget build(final BuildContext context) => Harbor(top: <HarborDock>[_header('Harbor Master')], body: _rows(12));
}

/// A dual-screen phone, open: sheets, dialogs and flares keep to one screen, never across the hinge.
class _HingePage extends StatefulWidget {
  const _HingePage({required this.time});

  final double time;

  @override
  State<_HingePage> createState() => _HingePageState();
}

class _HingePageState extends State<_HingePage> {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  BuildContext? _page;
  bool _sheet = false;
  bool _dialog = false;
  HarborFlareEntry? _flare;

  double get _sheetOpens => WideTimeline.cue('hinge', 'sheets') - 0.3;
  double get _dialogOpens => WideTimeline.cue('hinge', 'dialogs') - 0.2;
  double get _flareRises => WideTimeline.cue('hinge', 'flares') - 0.2;
  double get _ends => WideTimeline.of('hinge').end - 0.6;

  @override
  void didUpdateWidget(final _HingePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  // As a tap would, after the frame: open the sheet on "sheets", swap it for the dialog on
  // "dialogs", then for a flare on "flares", and close everything before the chapter ends.
  void _follow() {
    final double t = widget.time;
    final bool wantSheet = t >= _sheetOpens && t < _dialogOpens;
    final bool wantDialog = t >= _dialogOpens && t < _flareRises;
    final bool wantFlare = t >= _flareRises && t < _ends;
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      final BuildContext? page = _page;
      if (!mounted || page == null) {
        return;
      }
      if (_sheet && !wantSheet) {
        _sheet = false;
        Navigator.of(page).pop();
      }
      if (_dialog && !wantDialog) {
        _dialog = false;
        Navigator.of(page).pop();
      }
      if (_flare != null && !wantFlare) {
        _flare!.lower();
        _flare = null;
      }
      if (wantFlare && _flare == null) {
        _flare = HarborFlares.raise(
          page,
          slot: HarborFlareSlot.low,
          duration: null,
          builder: (final BuildContext _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: Palette.night, borderRadius: BorderRadius.circular(24)),
            child: const Text('Berth 4 booked', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        );
      }
      if (wantSheet && !_sheet) {
        _sheet = true;
        showHarborSheet<void>(
          page,
          builder: (final BuildContext _) => const HarborSheet(
            surface: ColoredBox(color: Color(0xFFF4F7FA)),
            body: SizedBox(
              height: 260,
              child: Center(child: Text('Book a berth', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.deepSea))),
            ),
          ),
        );
      }
      if (wantDialog && !_dialog) {
        _dialog = true;
        showHarborDialog<void>(
          page,
          useRootNavigator: false,
          builder: (final BuildContext _) => Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: const Text(
                'Sea Breeze is asking to come alongside berth 4.',
                style: TextStyle(fontSize: 17, height: 1.35, color: Palette.deepSea),
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(final BuildContext context) => Navigator(
    key: _navigator,
    onGenerateRoute: (final RouteSettings settings) => PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) => Harbor(
        top: <HarborDock>[_header('Harbor Master')],
        body: Builder(
          builder: (final BuildContext context) {
            _page = context;
            return _rows(12);
          },
        ),
      ),
    ),
  );
}
