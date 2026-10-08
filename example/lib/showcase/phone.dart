import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import '../field_guide/stage.dart';
import 'timeline.dart';

/// What the phone shows on screen, for the outlines the showcase draws over it.
enum PhonePart { header, tabBar, composer, keyboard }

/// A phone running a real harbor page, driven by [time].
///
/// Nothing on this screen is placed by the showcase. The keyboard reaches the page only as
/// `MediaQuery.viewInsets`, the way the platform reports it, and the page is an ordinary
/// [Harbor]: where the header, the list, the composer and the tab bar land is harbor's doing.
class ShowcasePhone extends StatefulWidget {
  const ShowcasePhone({super.key, required this.time, required this.parts});

  final double time;

  /// Keys on the parts the showcase outlines; read after layout, so the outlines are where harbor put things.
  final Map<PhonePart, GlobalKey> parts;

  static const Size screen = Size(402, 874);
  static const EdgeInsets coast = EdgeInsets.only(top: 62, bottom: 34);

  @override
  State<ShowcasePhone> createState() => _ShowcasePhoneState();
}

class _ShowcasePhoneState extends State<ShowcasePhone> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(final ShowcasePhone oldWidget) {
    super.didUpdateWidget(oldWidget);
    _follow();
  }

  @override
  void initState() {
    super.initState();
    _follow();
  }

  // The list follows the timeline after each layout, so the extent it scrolls through is the
  // one harbor gave it.
  void _follow() {
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (!mounted || !_scroll.hasClients) {
        return;
      }
      final ScrollPosition position = _scroll.position;
      position.jumpTo(position.maxScrollExtent * ShowcaseTimeline.scroll(widget.time));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final double keyboard = ShowcaseTimeline.keyboard(widget.time);
    final EdgeInsets viewPadding = ShowcasePhone.coast;
    // As Flutter computes it: the padding is what the view padding leaves after the keyboard.
    final EdgeInsets padding = EdgeInsets.only(top: viewPadding.top, bottom: math.max(0, viewPadding.bottom - keyboard));
    final MediaQueryData media = MediaQuery.of(context).copyWith(
      size: ShowcasePhone.screen,
      devicePixelRatio: 3,
      padding: padding,
      viewPadding: viewPadding,
      viewInsets: EdgeInsets.only(bottom: keyboard),
      textScaler: TextScaler.noScaling,
    );
    return SizedBox.fromSize(
      size: ShowcasePhone.screen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(54),
        child: MediaQuery(
          data: media,
          child: Theme(
            data: ThemeData(useMaterial3: true, colorSchemeSeed: Palette.shallows, fontFamily: 'Georgia'),
            child: Material(
              color: const Color(0xFFF4F7FA),
              child: Stack(
                children: <Widget>[
                  HarborSea(child: _Page(parts: widget.parts, scroll: _scroll, composerOut: ShowcaseTimeline.composerOut(widget.time))),
                  const Positioned(left: 0, right: 0, top: 0, height: 62, child: IgnorePointer(child: StatusBarArt(island: true))),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: keyboard,
                    child: KeyedSubtree(key: widget.parts[PhonePart.keyboard], child: const KeyboardArt()),
                  ),
                  if (keyboard < 1) const Positioned(left: 0, right: 0, bottom: 8, height: 5, child: HomeIndicatorArt()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.parts, required this.scroll, required this.composerOut});

  final Map<PhonePart, GlobalKey> parts;
  final ScrollController scroll;
  final bool composerOut;

  static const List<(String, String, IconData, Color)> _boats = <(String, String, IconData, Color)>[
    ('Sea Breeze', 'Sailboat · berth 4', Icons.sailing, Color(0xFFE2463A)),
    ('Old Faithful', 'Tug · berth 9', Icons.directions_boat, Color(0xFF2E7D5B)),
    ('Marigold', 'Ferry · berth 2', Icons.directions_ferry, Color(0xFFF2C14E)),
    ('Blue Heron', 'Trawler · berth 7', Icons.anchor, Color(0xFF3D5A98)),
    ('Pearl', 'Yacht · berth 1', Icons.sailing, Color(0xFF8E44AD)),
    ('Kestrel', 'Rowboat · berth 12', Icons.rowing, Color(0xFF16A085)),
    ('Northwind', 'Sailboat · berth 5', Icons.sailing, Color(0xFFD35400)),
    ('Dory', 'Rowboat · berth 14', Icons.rowing, Color(0xFF2E7D5B)),
  ];

  @override
  Widget build(final BuildContext context) => Harbor(
    top: <HarborDock>[
      HarborDock.pier(
        wake: const HarborWake.fade(length: 18, blurSigma: 14),
        backdrop: ColoredBox(color: Colors.white.withValues(alpha: 0.72)),
        child: KeyedSubtree(
          key: parts[PhonePart.header],
          child: const SizedBox(
            key: ValueKey<String>('showcase header'),
            height: 64,
            child: Center(
              child: Text('Harbor Master', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Palette.deepSea)),
            ),
          ),
        ),
      ),
    ],
    bottom: <HarborDock>[
      HarborDock.pier(
        tide: HarborTideStance.float,
        state: composerOut ? HarborDockState.open : HarborDockState.withdrawn,
        duration: const Duration(milliseconds: 400),
        backdrop: const ColoredBox(color: Colors.white),
        child: KeyedSubtree(key: parts[PhonePart.composer], child: const _Composer()),
      ),
      HarborDock.quay(
        backdrop: const ColoredBox(color: Palette.deepSea),
        child: KeyedSubtree(key: parts[PhonePart.tabBar], child: const _TabBar()),
      ),
    ],
    body: HarborFairway(
      controller: scroll,
      slivers: <Widget>[
        SliverList.builder(
          itemCount: _boats.length * 3,
          itemBuilder: (final BuildContext context, final int i) {
            final (String name, String detail, IconData icon, Color color) = _boats[i % _boats.length];
            return HarborMooringLine(
              child: Container(
                height: 76,
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Palette.deepSea)),
                        Text(detail, style: const TextStyle(fontSize: 14, color: Color(0xFF5B6B7A))),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(final BuildContext context) => Padding(
    key: const ValueKey<String>('showcase composer'),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: const Color(0xFFEDF1F5), borderRadius: BorderRadius.circular(22)),
            child: const Text('Radio the harbor master…', style: TextStyle(fontSize: 16, color: Color(0xFF7A8A99))),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(radius: 22, backgroundColor: Palette.shallows, child: Icon(Icons.send, color: Colors.white, size: 20)),
      ],
    ),
  );
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(final BuildContext context) => const SizedBox(
    key: ValueKey<String>('showcase tab bar'),
    height: 60,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Icon(Icons.anchor, color: Palette.brass, size: 28),
        Icon(Icons.map_outlined, color: Colors.white70, size: 28),
        Icon(Icons.forum_outlined, color: Colors.white70, size: 28),
        Icon(Icons.settings_outlined, color: Colors.white70, size: 28),
      ],
    ),
  );
}
