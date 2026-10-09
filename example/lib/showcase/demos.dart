import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import 'phone.dart';
import 'timeline.dart';

/// The showcase's time, for the pages on the phone: each chapter's demo reads it here and is
/// rebuilt every frame, so what it shows is a pure function of the narration's clock.
class ShowcaseClock extends InheritedWidget {
  const ShowcaseClock({super.key, required this.time, required super.child});

  final double time;

  static double of(final BuildContext context) => context.dependOnInheritedWidgetOfExactType<ShowcaseClock>()!.time;

  @override
  bool updateShouldNotify(final ShowcaseClock oldWidget) => time != oldWidget.time;
}

/// The page each chapter shows on the phone, or null for the Harbor Master page the panorama
/// chapters share.
Widget? showcaseDemo(final String chapter) => switch (chapter) {
  'moored' => const _Port(page: _MooredDemo()),
  'mooring' => const _Port(page: _MooringDemo()),
  'fairway' => const _Port(page: _FairwayDemo()),
  'sliverdock' => const _Port(page: _SliverDockDemo()),
  'sticky' => const _Port(page: _StickyDemo()),
  'openwater' => const _Port(page: _OpenWaterDemo()),
  'drydock' => const _Port(page: _DryDockDemo()),
  'makeway' => const _Port(page: _MakeWayDemo()),
  'pontoon' => const _Port(page: _PontoonDemo()),
  'buoy' => const _Port(page: _BuoyDemo()),
  'portal' => const _Port(page: _PortalDemo()),
  'signal' => const _Port(page: _FlareDemo()),
  'sheet' => const _Port(page: _SheetDemo()),
  'breakwater' => const _Port(page: _BreakwaterDemo()),
  'dialog' => const _Port(page: _DialogDemo()),
  'lighthouse' => const _Port(page: _LighthouseDemo()),
  'trials' => const _Port(page: _TrialsDemo()),
  _ => null,
};

/// When [word] is said in [chapter], or [after] seconds into it if it never is.
double _cue(final String chapter, final String word, [final double after = 1.5]) =>
    ShowcaseTimeline.cue(chapter, word, ShowcaseTimeline.of(chapter).start + after);

double _end(final String chapter) => ShowcaseTimeline.of(chapter).end;

/// A navigator of the phone's own, so sheets, dialogs and menus open on the phone's screen and
/// not over the whole showcase. The page reads the time from [ShowcaseClock].
class _Port extends StatelessWidget {
  const _Port({required this.page});

  final Widget page;

  @override
  Widget build(final BuildContext context) => Navigator(
    onGenerateRoute: (final RouteSettings settings) => PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: Duration.zero,
      pageBuilder: (final BuildContext context, final Animation<double> _, final Animation<double> _) => page,
    ),
  );
}

/// Opens and closes something imperative (a sheet, a dialog, a flare, a menu) as the clock
/// passes [opens] and [closes], from a frame callback, as a tap would. Seeking backwards
/// closes it again, so any frame can be drawn on its own.
mixin _Cued<T extends StatefulWidget> on State<T> {
  bool _open = false;

  double get opens;
  double get closes;

  void open();
  void close();

  void follow(final double t) {
    final bool want = t >= opens && t < closes;
    if (want == _open) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (!mounted || want == _open) {
        return;
      }
      _open = want;
      want ? open() : close();
    });
  }
}

/// A list that scrolls to [fraction] of its extent at each frame, after harbor has laid it out.
class _TimedFairway extends StatefulWidget {
  const _TimedFairway({required this.fraction, required this.slivers});

  final double Function(double t) fraction;
  final List<Widget> slivers;

  @override
  State<_TimedFairway> createState() => _TimedFairwayState();
}

class _TimedFairwayState extends State<_TimedFairway> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (mounted && _scroll.hasClients) {
        _scroll.position.jumpTo(_scroll.position.maxScrollExtent * widget.fraction(t).clamp(0.0, 1.0));
      }
    });
    return HarborFairway(controller: _scroll, slivers: widget.slivers);
  }
}

// --- Pieces the demos share --------------------------------------------------------------------

HarborDock _header(final String title, {final double alpha = 0.72}) => HarborDock.pier(
  wake: const HarborWake.fade(length: 18, blurSigma: 14),
  backdrop: ColoredBox(color: Colors.white.withValues(alpha: alpha)),
  child: SizedBox(
    height: 64,
    child: Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.deepSea),
      ),
    ),
  ),
);

HarborDock _tabBar({final Widget? middle}) => HarborDock.quay(
  backdrop: const ColoredBox(color: Palette.deepSea),
  child: ShowcaseTabBar(middle: middle),
);

List<Widget> _boatRows(final int from, final int count) => <Widget>[
  for (int i = from; i < from + count; i++) HarborMooringLine(child: BoatRow(index: i)),
];

SliverList _boatList(final int count, {final int from = 0}) => SliverList.builder(
  itemCount: count,
  itemBuilder: (final BuildContext _, final int i) => HarborMooringLine(child: BoatRow(index: from + i)),
);

class _Strip extends StatelessWidget {
  const _Strip(this.label, {this.color = Palette.deepSea});

  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
    height: 40,
    color: color,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsetsDirectional.only(start: 18),
    child: Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.focused = false});

  final String label;
  final String value;
  final bool focused;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5B6B7A)),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: focused ? Palette.shallows : const Color(0xFFD5DDE5), width: focused ? 2.5 : 1),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, color: Palette.deepSea)),
        ),
      ],
    ),
  );
}

class _Button extends StatelessWidget {
  const _Button(this.label, {this.color = Palette.shallows});

  final String label;
  final Color color;

  @override
  Widget build(final BuildContext context) => Container(
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
    child: Text(
      label,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
    ),
  );
}

/// A finger's tap, drawn where the narration says one lands.
class _Tap extends StatelessWidget {
  const _Tap({required this.at, required this.when});

  final Offset at;
  final double when;

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double p = ((t - when) / 0.6).clamp(0.0, 1.0);
    if (t < when || p >= 1) {
      return const SizedBox.shrink();
    }
    final double size = 30 + 40 * p;
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      width: size,
      height: size,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Palette.brass.withValues(alpha: 0.5 * (1 - p)),
            border: Border.all(color: Palette.brass.withValues(alpha: 1 - p), width: 3),
          ),
        ),
      ),
    );
  }
}

// --- Content -----------------------------------------------------------------------------------

/// A form and its Save button moored: clear of the header, the tab bar, the coast, and the
/// keyboard when it comes.
class _MooredDemo extends StatelessWidget {
  const _MooredDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('New berth')],
    bottom: <HarborDock>[_tabBar()],
    body: const HarborMoored(
      mooringLine: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(height: 8),
          _Field('Boat', 'Sea Breeze', focused: true),
          _Field('Berth', '4'),
          Spacer(),
          _Button('Save berth'),
          SizedBox(height: 12),
        ],
      ),
    ),
  );
}

/// Rows keep the page margin; a carousel among them runs to the screen's edges.
class _MooringDemo extends StatelessWidget {
  const _MooringDemo();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double guides = ShowcaseTimeline.ease(t, _cue('mooring', 'margin'), _cue('mooring', 'margin') + 0.5);
    final double carousel = ShowcaseTimeline.ease(t, _cue('mooring', 'carousel'), _end('mooring') - 0.8);
    return Stack(
      children: <Widget>[
        Harbor(
          top: <HarborDock>[_header('Harbor Master')],
          bottom: <HarborDock>[_tabBar()],
          body: HarborFairway(
            slivers: <Widget>[
              SliverList.list(children: _boatRows(0, 2)),
              SliverToBoxAdapter(child: _Carousel(progress: carousel)),
              SliverList.list(children: _boatRows(2, 6)),
            ],
          ),
        ),
        if (guides > 0)
          Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _MarginGuides(guides))),
          ),
      ],
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.progress});

  final double progress;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (mounted && _scroll.hasClients) {
        _scroll.position.jumpTo(_scroll.position.maxScrollExtent * widget.progress);
      }
    });
    final double margin = HarborWaters.of(context).margin.start;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: margin, vertical: 8),
        itemCount: 6,
        separatorBuilder: (final BuildContext _, final int _) => const SizedBox(width: 12),
        itemBuilder: (final BuildContext _, final int i) {
          final (String name, String _, IconData icon, Color color) = showcaseBoats[i];
          return Container(
            width: 150,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 30),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dashed lines down the page margin, labelled.
class _MarginGuides extends CustomPainter {
  const _MarginGuides(this.opacity);

  final double opacity;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Paint paint = Paint()
      ..color = Palette.buoyRed.withValues(alpha: opacity)
      ..strokeWidth = 2;
    for (final double x in <double>[ShowcasePhone.margin, size.width - ShowcasePhone.margin]) {
      for (double y = 130; y < size.height - 100; y += 14) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(final _MarginGuides oldDelegate) => oldDelegate.opacity != opacity;
}

/// A list that runs under the header and the tab bar, and comes to rest clear of both.
class _FairwayDemo extends StatelessWidget {
  const _FairwayDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('Harbor Master')],
    bottom: <HarborDock>[_tabBar()],
    body: _TimedFairway(
      fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('fairway', 'channel') - 0.5, _cue('fairway', 'rest') + 0.4),
      slivers: <Widget>[_boatList(14)],
    ),
  );
}

/// Section headers pinned at the face of the header, the second stacking below the first.
class _SliverDockDemo extends StatelessWidget {
  const _SliverDockDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('Harbor Master')],
    bottom: <HarborDock>[_tabBar()],
    body: _TimedFairway(
      fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('sliverdock', 'header') - 0.4, _end('sliverdock') - 0.8),
      slivers: <Widget>[
        _boatList(2),
        const HarborSliverDock(child: _Strip('North pontoon')),
        _boatList(4, from: 2),
        const HarborSliverDock(child: _Strip('South pontoon', color: Color(0xFF2E7D5B))),
        _boatList(12, from: 6),
      ],
    ),
  );
}

/// A day's log with a pill that holds below the header until the log scrolls away.
class _StickyDemo extends StatelessWidget {
  const _StickyDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('Harbor log')],
    bottom: <HarborDock>[_tabBar()],
    body: _TimedFairway(
      fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('sticky', 'rides'), _end('sticky') - 0.6),
      slivers: <Widget>[
        _boatList(2),
        SliverToBoxAdapter(
          child: HarborMooringLine(
            child: Container(
              height: 680,
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  HarborSticky(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: Palette.buoyRed, borderRadius: BorderRadius.circular(20)),
                      child: const Text(
                        'Tuesday',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < 8; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Text(
                        '${(7 + i).toString().padLeft(2, '0')}:00   ${showcaseBoats[i % showcaseBoats.length].$1} came in',
                        style: const TextStyle(fontSize: 16, color: Palette.deepSea),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        _boatList(10, from: 2),
      ],
    ),
  );
}

/// A chart of the bay, full bleed under a see-through header; only the pin keeps clear.
class _OpenWaterDemo extends StatelessWidget {
  const _OpenWaterDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('Chart', alpha: 0.55)],
    bottom: <HarborDock>[_tabBar()],
    body: HarborOpenWater(
      builder: (final BuildContext context, final HarborWatersData waters) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const CustomPaint(painter: _BayMap()),
          Positioned(
            top: waters.docks.top + 18,
            left: waters.margin.start,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Palette.deepSea, borderRadius: BorderRadius.circular(16)),
              child: const Text(
                'Berth 4 · 0.3 nm',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BayMap extends CustomPainter {
  const _BayMap();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFBFE0EE));
    final Paint land = Paint()..color = const Color(0xFFE9DFC4);
    final Paint shore = Paint()
      ..color = const Color(0xFFB9A983)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final Path coast = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.18, size.width * 0.42, size.height * 0.34)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.5, size.width * 0.2, size.height * 0.62)
      ..quadraticBezierTo(0, size.height * 0.7, 0, size.height * 0.8)
      ..close();
    canvas
      ..drawPath(coast, land)
      ..drawPath(coast, shore);
    for (final (double x, double y, double r) in const <(double, double, double)>[(0.72, 0.42, 46), (0.82, 0.7, 30), (0.55, 0.82, 22)]) {
      canvas
        ..drawCircle(Offset(size.width * x, size.height * y), r, land)
        ..drawCircle(Offset(size.width * x, size.height * y), r, shore);
    }
    // Soundings, as a chart prints them.
    final TextPainter depth = TextPainter(textDirection: TextDirection.ltr);
    final math.Random random = math.Random(4);
    for (int i = 0; i < 26; i++) {
      final Offset at = Offset(size.width * (0.45 + random.nextDouble() * 0.5), size.height * random.nextDouble());
      depth
        ..text = TextSpan(
          text: '${3 + random.nextInt(18)}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF4F7C93)),
        )
        ..layout();
      depth.paint(canvas, at);
    }
    final Paint route = Paint()
      ..color = Palette.buoyRed
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final Path track = Path()
      ..moveTo(size.width * 0.9, size.height)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.6, size.width * 0.5, size.height * 0.22);
    for (final ui in track.computeMetrics()) {
      for (double d = 0; d < ui.length; d += 18) {
        canvas.drawPath(ui.extractPath(d, d + 10), route);
      }
    }
  }

  @override
  bool shouldRepaint(final _BayMap oldDelegate) => false;
}

// --- The tide ----------------------------------------------------------------------------------

/// A styling panel in a dry dock: it holds the keyboard's ground, so the tabs above it stay put
/// as the keyboard goes out and comes back.
class _DryDockDemo extends StatelessWidget {
  const _DryDockDemo();

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[_header('Notes')],
    bottom: const <HarborDock>[
      HarborDock.quay(
        tide: HarborTideStance.dryDock,
        backdrop: ColoredBox(color: Palette.deepSea),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Icon(Icons.format_bold, color: Colors.white70, size: 26),
                  Icon(Icons.format_italic, color: Colors.white70, size: 26),
                  Icon(Icons.palette, color: Palette.brass, size: 26),
                  Icon(Icons.keyboard, color: Colors.white70, size: 26),
                ],
              ),
            ),
            HarborDryDock(child: _Swatches()),
          ],
        ),
      ),
    ],
    body: const HarborMoored(
      mooringLine: true,
      child: Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Tuesday. Wind westerly, 12 knots. Sea Breeze took berth 4 at noon; Marigold went out on the evening ferry.',
          style: TextStyle(fontSize: 19, height: 1.5, color: Palette.deepSea),
        ),
      ),
    ),
  );
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(final BuildContext context) => ColoredBox(
    color: const Color(0xFF173247),
    child: GridView.count(
      crossAxisCount: 5,
      padding: const EdgeInsets.all(18),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        for (int i = 0; i < 15; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              color: <Color>[...Palette.hulls, Palette.brass, Palette.shallows, Palette.buoyRed][i % (Palette.hulls.length + 3)],
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
  );
}

/// A panel that asks the tab bar to go dark, then to withdraw and give its ground back.
class _MakeWayDemo extends StatelessWidget {
  const _MakeWayDemo();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double dark = _cue('makeway', 'dark') - 0.2;
    final double withdraw = _cue('makeway', 'withdraw') - 0.2;
    final HarborYield? mode = t >= withdraw && t < _end('makeway') - 0.9
        ? HarborYield.withdraw
        : t >= dark && t < withdraw
        ? HarborYield.dark
        : null;
    return Harbor(
      top: <HarborDock>[_header('Harbor Master')],
      bottom: <HarborDock>[_tabBar()],
      body: HarborMakeWay(
        key: ValueKey<HarborYield?>(mode),
        edge: HarborEdge.bottom,
        mode: mode ?? HarborYield.dark,
        active: mode != null,
        child: HarborFairway(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]),
      ),
    );
  }
}

/// An unsaved-changes bar docked from deep inside a form, once the form has changes.
class _PontoonDemo extends StatelessWidget {
  const _PontoonDemo();

  @override
  Widget build(final BuildContext context) {
    final bool edited = ShowcaseClock.of(context) >= _cue('pontoon', 'unsaved') - 0.3;
    return Harbor(
      top: <HarborDock>[_header('Edit berth')],
      bottom: <HarborDock>[_tabBar()],
      body: HarborFairway(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: HarborPontoon(
              edge: HarborEdge.bottom,
              active: edited,
              dock: const HarborDock.pier(
                backdrop: ColoredBox(color: Palette.brass),
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          'Unsaved changes',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.night),
                        ),
                      ),
                      Text(
                        'Save',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.deepSea),
                      ),
                      SizedBox(width: 18),
                    ],
                  ),
                ),
              ),
              child: HarborMooringLine(
                child: Column(
                  children: <Widget>[
                    _Field('Boat', edited ? 'Sea Breeze II' : 'Sea Breeze', focused: edited),
                    const _Field('Skipper', 'A. Marsh'),
                    const _Field('Berth', '4'),
                    const _Field('Length', '9.4 m'),
                    const _Field('Arrives', 'Tuesday, noon'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Afloat ------------------------------------------------------------------------------------

/// A floating button, a speech bubble anchored to the tab bar's middle button, then a modal
/// buoy that a tap beside it closes.
class _BuoyDemo extends StatefulWidget {
  const _BuoyDemo();

  @override
  State<_BuoyDemo> createState() => _BuoyDemoState();
}

class _BuoyDemoState extends State<_BuoyDemo> {
  final HarborAnchor _launch = HarborAnchor();

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double modal = _cue('buoy', 'modal') - 0.2;
    final double closes = _cue('buoy', 'closes') - 0.3;
    final double tap = _cue('buoy', 'tap');
    return Stack(
      children: <Widget>[
        Harbor(
          top: <HarborDock>[_header('Harbor Master')],
          bottom: <HarborDock>[
            _tabBar(
              middle: HarborAnchorPoint(
                anchor: _launch,
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Palette.brass,
                  child: Icon(Icons.add, color: Palette.night),
                ),
              ),
            ),
          ],
          buoys: <HarborBuoy>[
            if (t >= _cue('buoy', 'floating') - 0.2)
              const HarborBuoy(
                alignment: AlignmentDirectional.bottomEnd,
                child: FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Palette.shallows,
                  child: Icon(Icons.sailing, color: Colors.white),
                ),
              ),
            if (t >= _cue('buoy', 'speech') - 0.2 && t < modal)
              HarborBuoy.anchored(
                anchor: _launch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Palette.deepSea, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Book a berth here', style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
            if (t >= modal && t < closes)
              HarborBuoy(
                modal: true,
                onDismiss: () {},
                barrierColor: const Color(0x66000000),
                alignment: Alignment.center,
                child: Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ListTile(leading: Icon(Icons.anchor), title: Text('Book a berth')),
                      ListTile(leading: Icon(Icons.call), title: Text('Call the harbor master')),
                      ListTile(leading: Icon(Icons.local_gas_station), title: Text('Order fuel')),
                    ],
                  ),
                ),
              ),
          ],
          body: HarborFairway(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]),
        ),
        _Tap(at: const Offset(70, 640), when: tap),
      ],
    );
  }
}

/// Menus opened from list rows: one below its row, and one near the bottom that flips above.
class _PortalDemo extends StatefulWidget {
  const _PortalDemo();

  @override
  State<_PortalDemo> createState() => _PortalDemoState();
}

class _PortalDemoState extends State<_PortalDemo> {
  final OverlayPortalController _first = OverlayPortalController(debugLabel: 'first menu');
  final OverlayPortalController _flipped = OverlayPortalController(debugLabel: 'flipped menu');

  void _toggle(final OverlayPortalController menu, final bool show) {
    if (menu.isShowing != show) {
      WidgetsBinding.instance.addPostFrameCallback((final Duration _) => show ? menu.show() : menu.hide());
    }
  }

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double flips = _cue('portal', 'flips') - 0.5;
    _toggle(_first, t >= _cue('portal', 'menu') - 0.2 && t < flips);
    _toggle(_flipped, t >= flips && t < _end('portal') - 0.6);
    return Harbor(
      top: <HarborDock>[_header('Harbor Master')],
      bottom: <HarborDock>[_tabBar()],
      body: HarborFairway(
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 10,
            itemBuilder: (final BuildContext _, final int i) {
              final Widget row = HarborMooringLine(child: BoatRow(index: i));
              return switch (i) {
                1 => HarborPortalBuoy(
                  controller: _first,
                  side: HarborBuoySide.below,
                  buoyBuilder: (final BuildContext _) => const _RowMenu(),
                  child: row,
                ),
                6 => HarborPortalBuoy(
                  controller: _flipped,
                  side: HarborBuoySide.below,
                  buoyBuilder: (final BuildContext _) => const _RowMenu(),
                  child: row,
                ),
                _ => row,
              };
            },
          ),
        ],
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu();

  @override
  Widget build(final BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD5DDE5)),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(dense: true, leading: Icon(Icons.swap_horiz), title: Text('Move berth')),
          ListTile(dense: true, leading: Icon(Icons.call), title: Text('Call the skipper')),
          ListTile(dense: true, leading: Icon(Icons.logout), title: Text('Check out')),
        ],
      ),
    ),
  );
}

/// A toast raised clear of the tab bar, and what a screen reader hears.
class _FlareDemo extends StatefulWidget {
  const _FlareDemo();

  @override
  State<_FlareDemo> createState() => _FlareDemoState();
}

class _FlareDemoState extends State<_FlareDemo> with _Cued<_FlareDemo> {
  BuildContext? _page;
  HarborFlareEntry? _flare;

  @override
  double get opens => _cue('signal', 'toast') - 0.2;

  @override
  double get closes => _end('signal') - 0.8;

  @override
  void open() => _flare = HarborFlares.raise(
    _page!,
    slot: HarborFlareSlot.low,
    duration: null,
    builder: (final BuildContext _) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Palette.night, borderRadius: BorderRadius.circular(24)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.check_circle, color: Palette.brass),
          SizedBox(width: 10),
          Text('Berth 4 booked', style: TextStyle(fontSize: 17, color: Colors.white)),
        ],
      ),
    ),
  );

  @override
  void close() => _flare?.lower();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    follow(t);
    final bool heard = t >= _cue('signal', 'announce') - 0.2 && t < closes;
    return Stack(
      children: <Widget>[
        Harbor(
          top: <HarborDock>[_header('Harbor Master')],
          bottom: <HarborDock>[_tabBar()],
          body: Builder(
            builder: (final BuildContext page) {
              _page = page;
              return HarborFairway(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]);
            },
          ),
        ),
        if (heard)
          Positioned(
            left: 20,
            right: 20,
            top: 140,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Palette.brass, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.record_voice_over, color: Palette.night),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'VoiceOver: “Berth 4 booked”',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Palette.night),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// --- Sheets and dialogs ------------------------------------------------------------------------

/// The Harbor Master page, with a [_Cued] sheet or dialog opened over it from its own context.
abstract class _OverPageState<T extends StatefulWidget> extends State<T> with _Cued<T> {
  BuildContext? page;
  bool _shown = false;

  String get chapter;

  Future<void> show(final BuildContext context);

  @override
  void open() {
    _shown = true;
    show(page!).whenComplete(() => _shown = false);
  }

  @override
  void close() {
    if (_shown && page != null) {
      Navigator.of(page!).pop();
    }
  }

  Widget body() => HarborFairway(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]);

  @override
  Widget build(final BuildContext context) {
    follow(ShowcaseClock.of(context));
    return Harbor(
      top: <HarborDock>[_header('Harbor Master')],
      bottom: <HarborDock>[_tabBar()],
      body: Builder(
        builder: (final BuildContext context) {
          page = context;
          return body();
        },
      ),
    );
  }
}

/// A sheet: its own pier, a form, and a footer on a floating quay.
class _SheetDemo extends StatefulWidget {
  const _SheetDemo();

  @override
  State<_SheetDemo> createState() => _SheetDemoState();
}

class _SheetDemoState extends _OverPageState<_SheetDemo> {
  @override
  String get chapter => 'sheet';

  @override
  double get opens => _cue('sheet', 'sheet') - 0.3;

  @override
  double get closes => _end('sheet') - 0.7;

  @override
  Future<void> show(final BuildContext context) => showHarborSheet<void>(
    context,
    builder: (final BuildContext _) => HarborSheet(
      surface: const ColoredBox(color: Color(0xFFF4F7FA)),
      header: const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'Book a berth',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Palette.deepSea),
          ),
        ),
      ),
      footer: const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: _Button('Book berth 4')),
      body: HarborFairway(
        slivers: <Widget>[
          SliverList.list(
            children: const <Widget>[
              HarborMooringLine(child: _Field('Boat', 'Sea Breeze')),
              HarborMooringLine(child: _Field('Skipper', 'A. Marsh')),
              HarborMooringLine(child: _Field('Arrives', 'Tuesday, noon')),
              HarborMooringLine(child: _Field('Nights', '3')),
              HarborMooringLine(child: _Field('Shore power', 'Yes')),
              HarborMooringLine(child: _Field('Water', 'Yes')),
              HarborMooringLine(child: _Field('Notes', 'Arriving under sail')),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A breakwater sheet with no barrier: the page learns what it covers and scrolls clear of it.
class _BreakwaterDemo extends StatefulWidget {
  const _BreakwaterDemo();

  @override
  State<_BreakwaterDemo> createState() => _BreakwaterDemoState();
}

class _BreakwaterDemoState extends _OverPageState<_BreakwaterDemo> {
  @override
  String get chapter => 'breakwater';

  @override
  double get opens => _cue('breakwater', 'breakwater') - 0.3;

  @override
  double get closes => _end('breakwater') - 0.6;

  @override
  Future<void> show(final BuildContext context) => showHarborSheet<void>(
    context,
    breakwater: true,
    barrier: HarborSheetBarrier.none,
    builder: (final BuildContext _) => const HarborSheet(
      surface: ColoredBox(color: Palette.deepSea),
      body: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Route to berth 4',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text('0.3 nm · 6 min under power', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 16),
              _Button('Start', color: Palette.brass),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget body() => _TimedFairway(
    fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('breakwater', 'page') - 0.2, _end('breakwater') - 1.2),
    slivers: <Widget>[_boatList(10)],
  );
}

/// A dialog kept to the page's clear water: between the header and the tab bar.
class _DialogDemo extends StatefulWidget {
  const _DialogDemo();

  @override
  State<_DialogDemo> createState() => _DialogDemoState();
}

class _DialogDemoState extends _OverPageState<_DialogDemo> {
  @override
  String get chapter => 'dialog';

  @override
  double get opens => _cue('dialog', 'dialog') - 0.2;

  @override
  double get closes => _end('dialog') - 0.6;

  @override
  Future<void> show(final BuildContext context) => showHarborDialog<void>(
    context,
    useRootNavigator: false,
    inheritClearWater: true,
    builder: (final BuildContext _) => Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Radio call',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Palette.deepSea),
            ),
            SizedBox(height: 10),
            Text('Sea Breeze is asking to come alongside berth 4.', style: TextStyle(fontSize: 16, height: 1.35, color: Palette.deepSea)),
            SizedBox(height: 18),
            _Button('Answer'),
          ],
        ),
      ),
    ),
  );
}

// --- The lighthouse ----------------------------------------------------------------------------

/// A long form whose focused field is low on the page: when the keyboard rises, the beacon
/// scrolls it back into sight above it.
class _LighthouseDemo extends StatelessWidget {
  const _LighthouseDemo();

  @override
  Widget build(final BuildContext context) {
    final bool focused = ShowcaseClock.of(context) >= _cue('lighthouse', 'focused') - 0.3;
    return Harbor(
      top: <HarborDock>[_header('Log a sighting')],
      bottom: <HarborDock>[_tabBar()],
      body: HarborFairway(
        slivers: <Widget>[
          SliverList.list(
            children: <Widget>[
              const HarborMooringLine(child: _Field('Vessel', 'Northwind')),
              const HarborMooringLine(child: _Field('Seen at', 'Harbor mouth')),
              const HarborMooringLine(child: _Field('Heading', 'North-east')),
              const HarborMooringLine(child: _Field('Speed', '6 knots')),
              const HarborMooringLine(child: _Field('Flag', 'Red ensign')),
              const HarborMooringLine(child: _Field('Crew', '3')),
              HarborBeacon(
                keepInSight: true,
                clearance: 16,
                child: HarborMooringLine(child: _Field('Remarks', focused ? 'Under full sail|' : '', focused: focused)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Sea trials --------------------------------------------------------------------------------

/// The trials passing, device by device, as the narrator names them.
class _TrialsDemo extends StatelessWidget {
  const _TrialsDemo();

  static const List<(String, String)> _trials = <(String, String)>[
    ('phones', 'iPhone 16 · the composer rides the keyboard'),
    ('phones', 'Pixel 9, three-button nav · the tab bar clears it'),
    ('foldables', 'Galaxy Z Fold, open · sheets keep off the hinge'),
    ('televisions', 'Android TV · the header keeps title-safe'),
    ('keyboard', 'Every device, keyboard up · nothing covered'),
  ];

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    return Harbor(
      top: <HarborDock>[_header('sea_trial_test.dart')],
      body: HarborMoored(
        mooringLine: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 12),
            const Text(
              r'$ flutter test',
              style: TextStyle(fontFamily: 'Menlo', fontSize: 15, color: Palette.deepSea),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < _trials.length; i++)
              if (t >= _cue('trials', _trials[i].$1) - 0.3 + (i == 1 ? 0.5 : 0))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.check_circle, color: Color(0xFF2E7D5B), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _trials[i].$2,
                          style: const TextStyle(fontFamily: 'Menlo', fontSize: 13.5, height: 1.3, color: Palette.deepSea),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
