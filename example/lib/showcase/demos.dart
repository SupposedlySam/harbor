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
  'clear' => const _OwnNavigator(page: _ClearDemo()),
  'rowinsets' => const _OwnNavigator(page: _RowInsetsDemo()),
  'scrollview' => const _OwnNavigator(page: _ScrollViewDemo()),
  'sliverbar' => const _OwnNavigator(page: _SliverBarDemo()),
  'sticky' => const _OwnNavigator(page: _StickyDemo()),
  'room' => const _OwnNavigator(page: _RoomDemo()),
  'reserves' => const _OwnNavigator(page: _ReservesDemo()),
  'hidebar' => const _OwnNavigator(page: _HideBarDemo()),
  'attachedbar' => const _OwnNavigator(page: _AttachedBarDemo()),
  'float' => const _OwnNavigator(page: _FloatDemo()),
  'popover' => const _OwnNavigator(page: _PopoverDemo()),
  'toast' => const _OwnNavigator(page: _ToastDemo()),
  'sheet' => const _OwnNavigator(page: _SheetDemo()),
  'coverspage' => const _OwnNavigator(page: _CoversPageDemo()),
  'dialog' => const _OwnNavigator(page: _DialogDemo()),
  'keepvisible' => const _OwnNavigator(page: _KeepVisibleDemo()),
  'trials' => const _OwnNavigator(page: _TrialsDemo()),
  _ => null,
};

/// When [word] is said in [chapter], or [after] seconds into it if it never is.
double _cue(final String chapter, final String word, [final double after = 1.5]) =>
    ShowcaseTimeline.cue(chapter, word, ShowcaseTimeline.of(chapter).start + after);

double _end(final String chapter) => ShowcaseTimeline.of(chapter).end;

/// A navigator of the phone's own, so sheets, dialogs and menus open on the phone's screen and
/// not over the whole showcase. The page reads the time from [ShowcaseClock].
class _OwnNavigator extends StatelessWidget {
  const _OwnNavigator({required this.page});

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

/// Opens and closes something imperative (a sheet, a dialog, a toast, a menu) as the clock
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
class _TimedScrollView extends StatefulWidget {
  const _TimedScrollView({required this.fraction, required this.slivers});

  final double Function(double t) fraction;
  final List<Widget> slivers;

  @override
  State<_TimedScrollView> createState() => _TimedScrollViewState();
}

class _TimedScrollViewState extends State<_TimedScrollView> {
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
    return HarborScrollView(controller: _scroll, slivers: widget.slivers);
  }
}

// --- Pieces the demos share --------------------------------------------------------------------

HarborBar _header(final String title, {final double alpha = 0.72}) => HarborBar.overlay(
  edgeEffect: const HarborEdgeEffect.fade(length: 18, blurSigma: 14),
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

HarborBar _tabBar({final Widget? middle}) => HarborBar.solid(
  backdrop: const ColoredBox(color: Palette.deepSea),
  child: ShowcaseTabBar(middle: middle),
);

List<Widget> _boatRows(final int from, final int count) => <Widget>[
  for (int i = from; i < from + count; i++) HarborClear.rowInsets(child: BoatRow(index: i)),
];

SliverList _boatList(final int count, {final int from = 0}) => SliverList.builder(
  itemCount: count,
  itemBuilder: (final BuildContext _, final int i) => HarborClear.rowInsets(child: BoatRow(index: from + i)),
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

/// A form and its Save button kept clear of the header, the tab bar, the system edges, and the
/// keyboard when it comes.
class _ClearDemo extends StatelessWidget {
  const _ClearDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('New berth')],
    bottom: <HarborBar>[_tabBar()],
    body: const HarborClear(
      rowInsets: true,
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
class _RowInsetsDemo extends StatelessWidget {
  const _RowInsetsDemo();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double guides = ShowcaseTimeline.ease(t, _cue('rowinsets', 'margin'), _cue('rowinsets', 'margin') + 0.5);
    final double carousel = ShowcaseTimeline.ease(t, _cue('rowinsets', 'carousel'), _end('rowinsets') - 0.8);
    return Stack(
      children: <Widget>[
        HarborFrame(
          top: <HarborBar>[_header('Harbor Master')],
          bottom: <HarborBar>[_tabBar()],
          body: HarborScrollView(
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
    final double margin = HarborRoom.of(context).margin.start;
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
class _ScrollViewDemo extends StatelessWidget {
  const _ScrollViewDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('Harbor Master')],
    bottom: <HarborBar>[_tabBar()],
    body: _TimedScrollView(
      fraction: (final double t) =>
          ShowcaseTimeline.ease(t, _cue('scrollview', 'list') - 0.5, _cue('scrollview', 'rest') + 0.4),
      slivers: <Widget>[_boatList(14)],
    ),
  );
}

/// Section headers pinned at the face of the header, the second stacking below the first.
class _SliverBarDemo extends StatelessWidget {
  const _SliverBarDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('Harbor Master')],
    bottom: <HarborBar>[_tabBar()],
    body: _TimedScrollView(
      fraction: (final double t) =>
          ShowcaseTimeline.ease(t, _cue('sliverbar', 'header') - 0.4, _end('sliverbar') - 0.8),
      slivers: <Widget>[
        _boatList(2),
        const HarborSliverBar(child: _Strip('North pontoon')),
        _boatList(4, from: 2),
        const HarborSliverBar(child: _Strip('South pontoon', color: Color(0xFF2E7D5B))),
        _boatList(12, from: 6),
      ],
    ),
  );
}

/// A day's log with a pill that holds below the header until the log scrolls away.
class _StickyDemo extends StatelessWidget {
  const _StickyDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('Harbor log')],
    bottom: <HarborBar>[_tabBar()],
    body: _TimedScrollView(
      fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('sticky', 'rides'), _end('sticky') - 0.6),
      slivers: <Widget>[
        _boatList(2),
        SliverToBoxAdapter(
          child: HarborClear.rowInsets(
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
class _RoomDemo extends StatelessWidget {
  const _RoomDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('Chart', alpha: 0.55)],
    bottom: <HarborBar>[_tabBar()],
    body: Builder(
      builder: (final BuildContext context) {
        final HarborRoomData room = HarborRoom.of(context);
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const CustomPaint(painter: _BayMap()),
            Positioned(
              top: room.bars.top + 18,
              left: room.margin.start,
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
        );
      },
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
    for (final (double x, double y, double r) in const <(double, double, double)>[
      (0.72, 0.42, 46),
      (0.82, 0.7, 30),
      (0.55, 0.82, 22),
    ]) {
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

// --- The keyboard ------------------------------------------------------------------------------

/// A styling panel in a bar that reserves the keyboard's space, so the tabs above it stay put as
/// the keyboard goes out and comes back.
class _ReservesDemo extends StatelessWidget {
  const _ReservesDemo();

  @override
  Widget build(final BuildContext context) => HarborFrame(
    top: <HarborBar>[_header('Notes')],
    bottom: const <HarborBar>[
      HarborBar.solid(
        keyboard: HarborKeyboardStance.reserves,
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
            HarborKeyboardSpace(child: _Swatches()),
          ],
        ),
      ),
    ],
    body: const HarborClear(
      rowInsets: true,
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
              color: <Color>[
                ...Palette.hulls,
                Palette.brass,
                Palette.shallows,
                Palette.buoyRed,
              ][i % (Palette.hulls.length + 3)],
              shape: BoxShape.circle,
            ),
          ),
      ],
    ),
  );
}

/// A panel that asks the tab bar to go dark, then to withdraw and give its space back.
class _HideBarDemo extends StatelessWidget {
  const _HideBarDemo();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double dark = _cue('hidebar', 'dark') - 0.2;
    final double withdraw = _cue('hidebar', 'withdraw') - 0.2;
    final HarborBarState? state = t >= withdraw && t < _end('hidebar') - 0.9
        ? HarborBarState.withdrawn
        : t >= dark && t < withdraw
        ? HarborBarState.dark
        : null;
    return HarborFrame(
      top: <HarborBar>[_header('Harbor Master')],
      bottom: <HarborBar>[_tabBar()],
      body: HarborHideBar(
        key: ValueKey<HarborBarState?>(state),
        edge: HarborEdge.bottom,
        state: state ?? HarborBarState.dark,
        active: state != null,
        child: HarborScrollView(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]),
      ),
    );
  }
}

/// An unsaved-changes bar attached from deep inside a form, once the form has changes.
class _AttachedBarDemo extends StatelessWidget {
  const _AttachedBarDemo();

  @override
  Widget build(final BuildContext context) {
    final bool edited = ShowcaseClock.of(context) >= _cue('attachedbar', 'unsaved') - 0.3;
    return HarborFrame(
      top: <HarborBar>[_header('Edit berth')],
      bottom: <HarborBar>[_tabBar()],
      body: HarborScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: HarborAttachedBar(
              edge: HarborEdge.bottom,
              active: edited,
              bar: const HarborBar.overlay(
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
              child: HarborClear.rowInsets(
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

// --- Floats ----------------------------------------------------------------------------------

/// A floating button, a speech bubble anchored to the tab bar's middle button, then a modal
/// float that a tap beside it closes.
class _FloatDemo extends StatefulWidget {
  const _FloatDemo();

  @override
  State<_FloatDemo> createState() => _FloatDemoState();
}

class _FloatDemoState extends State<_FloatDemo> {
  final HarborAnchor _launch = HarborAnchor();

  @override
  void dispose() {
    _launch.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    final double modal = _cue('float', 'modal') - 0.2;
    final double closes = _cue('float', 'closes') - 0.3;
    final double tap = _cue('float', 'tap');
    return Stack(
      children: <Widget>[
        HarborFrame(
          top: <HarborBar>[_header('Harbor Master')],
          bottom: <HarborBar>[
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
          floats: <HarborFloat>[
            if (t >= _cue('float', 'floating') - 0.2)
              const HarborFloat(
                placement: HarborAligned(alignment: AlignmentDirectional.bottomEnd),
                child: FloatingActionButton(
                  onPressed: null,
                  backgroundColor: Palette.shallows,
                  child: Icon(Icons.sailing, color: Colors.white),
                ),
              ),
            if (t >= _cue('float', 'speech') - 0.2 && t < modal)
              HarborFloat(
                placement: HarborAnchored(_launch, side: HarborAnchorSide.above),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Palette.deepSea, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Book a berth here', style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
            if (t >= modal && t < closes)
              HarborFloat(
                placement: const HarborAligned(alignment: Alignment.center),
                barrier: const HarborBarrier.dimmed(color: Color(0x66000000)),
                onDismiss: () {},
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
          body: HarborScrollView(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]),
        ),
        _Tap(at: const Offset(70, 640), when: tap),
      ],
    );
  }
}

/// Menus opened from list rows: one below its row, and one near the bottom that flips above.
class _PopoverDemo extends StatefulWidget {
  const _PopoverDemo();

  @override
  State<_PopoverDemo> createState() => _PopoverDemoState();
}

class _PopoverDemoState extends State<_PopoverDemo> {
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
    final double flips = _cue('popover', 'flips') - 0.5;
    _toggle(_first, t >= _cue('popover', 'menu') - 0.2 && t < flips);
    _toggle(_flipped, t >= flips && t < _end('popover') - 0.6);
    return HarborFrame(
      top: <HarborBar>[_header('Harbor Master')],
      bottom: <HarborBar>[_tabBar()],
      body: HarborScrollView(
        slivers: <Widget>[
          SliverList.builder(
            itemCount: 10,
            itemBuilder: (final BuildContext _, final int i) {
              final Widget row = HarborClear.rowInsets(child: BoatRow(index: i));
              return switch (i) {
                1 => HarborPopover(
                  placement: const HarborAnchored(null, side: HarborAnchorSide.below),
                  controller: _first,
                  popoverBuilder: (final BuildContext _) => const _RowMenu(),
                  child: row,
                ),
                6 => HarborPopover(
                  placement: const HarborAnchored(null, side: HarborAnchorSide.below),
                  controller: _flipped,
                  popoverBuilder: (final BuildContext _) => const _RowMenu(),
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

/// A toast shown clear of the tab bar, and what a screen reader hears.
class _ToastDemo extends StatefulWidget {
  const _ToastDemo();

  @override
  State<_ToastDemo> createState() => _ToastDemoState();
}

class _ToastDemoState extends State<_ToastDemo> with _Cued<_ToastDemo> {
  BuildContext? _page;
  HarborToastEntry? _toast;

  @override
  double get opens => _cue('toast', 'toast') - 0.2;

  @override
  double get closes => _end('toast') - 0.8;

  @override
  void open() => _toast = HarborToasts.show(
    _page!,
    slot: HarborToastSlot.low,
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
    timing: HarborToastTiming.untilHidden,
  );

  @override
  void close() => _toast?.hide();

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    follow(t);
    final bool heard = t >= _cue('toast', 'announce') - 0.2 && t < closes;
    return Stack(
      children: <Widget>[
        HarborFrame(
          top: <HarborBar>[_header('Harbor Master')],
          bottom: <HarborBar>[_tabBar()],
          body: Builder(
            builder: (final BuildContext page) {
              _page = page;
              return HarborScrollView(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]);
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

  Widget body() => HarborScrollView(slivers: <Widget>[SliverList.list(children: _boatRows(0, 9))]);

  @override
  Widget build(final BuildContext context) {
    follow(ShowcaseClock.of(context));
    return HarborFrame(
      top: <HarborBar>[_header('Harbor Master')],
      bottom: <HarborBar>[_tabBar()],
      body: Builder(
        builder: (final BuildContext context) {
          page = context;
          return body();
        },
      ),
    );
  }
}

/// A sheet: its own header, a form, and a footer that rides the keyboard.
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
      body: HarborScrollView(
        slivers: <Widget>[
          SliverList.list(
            children: const <Widget>[
              HarborClear.rowInsets(child: _Field('Boat', 'Sea Breeze')),
              HarborClear.rowInsets(child: _Field('Skipper', 'A. Marsh')),
              HarborClear.rowInsets(child: _Field('Arrives', 'Tuesday, noon')),
              HarborClear.rowInsets(child: _Field('Nights', '3')),
              HarborClear.rowInsets(child: _Field('Shore power', 'Yes')),
              HarborClear.rowInsets(child: _Field('Water', 'Yes')),
              HarborClear.rowInsets(child: _Field('Notes', 'Arriving under sail')),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A sheet that covers the page, with no barrier: the page learns what it covers and scrolls clear
/// of it.
class _CoversPageDemo extends StatefulWidget {
  const _CoversPageDemo();

  @override
  State<_CoversPageDemo> createState() => _CoversPageDemoState();
}

class _CoversPageDemoState extends _OverPageState<_CoversPageDemo> {
  @override
  String get chapter => 'coverspage';

  @override
  double get opens => _cue('coverspage', 'sheet') - 0.3;

  @override
  double get closes => _end('coverspage') - 0.6;

  @override
  Future<void> show(final BuildContext context) => showHarborSheet<void>(
    context,
    coversPage: true,
    barrier: HarborBarrier.none,
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
  Widget body() => _TimedScrollView(
    fraction: (final double t) => ShowcaseTimeline.ease(t, _cue('coverspage', 'page') - 0.2, _end('coverspage') - 1.2),
    slivers: <Widget>[_boatList(10)],
  );
}

/// A dialog kept to the page's room: between the header and the tab bar.
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
    inheritRoom: true,
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
            Text(
              'Sea Breeze is asking to come alongside berth 4.',
              style: TextStyle(fontSize: 16, height: 1.35, color: Palette.deepSea),
            ),
            SizedBox(height: 18),
            _Button('Answer'),
          ],
        ),
      ),
    ),
  );
}

// --- Keeping in sight ------------------------------------------------------------------------

/// A long form whose focused field is low on the page: when the keyboard rises, the reveal
/// scrolls it back into sight above it.
class _KeepVisibleDemo extends StatelessWidget {
  const _KeepVisibleDemo();

  @override
  Widget build(final BuildContext context) {
    final bool focused = ShowcaseClock.of(context) >= _cue('keepvisible', 'focused') - 0.3;
    return HarborFrame(
      top: <HarborBar>[_header('Log a sighting')],
      bottom: <HarborBar>[_tabBar()],
      body: HarborScrollView(
        slivers: <Widget>[
          SliverList.list(
            children: <Widget>[
              const HarborClear.rowInsets(child: _Field('Vessel', 'Northwind')),
              const HarborClear.rowInsets(child: _Field('Seen at', 'Harbor mouth')),
              const HarborClear.rowInsets(child: _Field('Heading', 'North-east')),
              const HarborClear.rowInsets(child: _Field('Speed', '6 knots')),
              const HarborClear.rowInsets(child: _Field('Flag', 'Red ensign')),
              const HarborClear.rowInsets(child: _Field('Crew', '3')),
              HarborKeepVisible(
                clearance: 16,
                child: HarborClear.rowInsets(
                  child: _Field('Remarks', focused ? 'Under full sail|' : '', focused: focused),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Trials -----------------------------------------------------------------------------------

/// The trials passing, device by device, as the narrator names them.
class _TrialsDemo extends StatelessWidget {
  const _TrialsDemo();

  static const List<(String, String)> _trials = <(String, String)>[
    ('phones', 'iPhone 16 · the composer rides the keyboard'),
    ('phones', 'Pixel 9, three-button nav · the tab bar clears it'),
    ('foldables', 'Galaxy Z Fold, open · sheets keep off the hinge'),
    ('keyboard', 'Every device, keyboard up · nothing covered'),
  ];

  @override
  Widget build(final BuildContext context) {
    final double t = ShowcaseClock.of(context);
    return HarborFrame(
      top: <HarborBar>[_header('harbor_trial_test.dart')],
      body: HarborClear(
        rowInsets: true,
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
                          style: const TextStyle(
                            fontFamily: 'Menlo',
                            fontSize: 13.5,
                            height: 1.3,
                            color: Palette.deepSea,
                          ),
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
