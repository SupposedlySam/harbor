import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';

/// A phone the stage pretends to be: its screen, its coast and how high its
/// keyboard comes in. Mirrors the sea-trial devices in `package:harbor/testing.dart`.
@immutable
class StageDevice {
  const StageDevice({required this.name, required this.size, required this.coast, required this.tideHeight, this.island = false, this.tv = false});

  final String name;
  final Size size;

  /// The system insets with the keyboard down (physical left/right).
  final EdgeInsets coast;
  final double tideHeight;

  /// Whether it has a Dynamic Island to draw.
  final bool island;

  /// Whether it's a television (no keyboard, title-safe band).
  final bool tv;

  static const StageDevice iPhone17 = StageDevice(
    name: 'iPhone 17',
    size: Size(402, 874),
    coast: EdgeInsets.only(top: 62, bottom: 34),
    tideHeight: 336,
    island: true,
  );
  static const StageDevice iPhoneSE = StageDevice(
    name: 'iPhone SE',
    size: Size(375, 667),
    coast: EdgeInsets.only(top: 20),
    tideHeight: 260,
  );
  static const StageDevice androidThreeButton = StageDevice(
    name: 'Android 3-button',
    size: Size(412, 915),
    coast: EdgeInsets.only(top: 24, bottom: 48),
    tideHeight: 300,
  );
  static const StageDevice androidGesture = StageDevice(
    name: 'Android gesture',
    size: Size(412, 915),
    coast: EdgeInsets.only(top: 24, bottom: 24),
    tideHeight: 300,
  );
  static const StageDevice iPhone17Landscape = StageDevice(
    name: 'iPhone 17 landscape',
    size: Size(874, 402),
    coast: EdgeInsets.only(left: 62, right: 62, bottom: 21),
    tideHeight: 200,
    island: true,
  );
  static const StageDevice foldableOpen = StageDevice(
    name: 'foldable open',
    size: Size(750, 832),
    coast: EdgeInsets.only(top: 24, bottom: 24),
    tideHeight: 330,
  );
  static const StageDevice dualScreenCover = StageDevice(
    name: 'dual screen cover',
    size: Size(466, 678),
    coast: EdgeInsets.only(right: 84, bottom: 34),
    tideHeight: 300,
  );
  static const StageDevice television = StageDevice(
    name: 'Television',
    size: Size(1200, 675),
    coast: EdgeInsets.zero,
    tideHeight: 0,
    tv: true,
  );

  /// Every sea-trial device but the television.
  static const List<StageDevice> phones = <StageDevice>[
    iPhone17,
    iPhoneSE,
    androidThreeButton,
    androidGesture,
    iPhone17Landscape,
    foldableOpen,
    dualScreenCover,
  ];
}

/// The part of the phone a page is about, the way a store screenshot crops
/// to it: the whole screen, its top, or its bottom. The phone runs off the
/// stage past the cut, so the part that matters is drawn bigger.
@immutable
class StageFocus {
  const StageFocus._(this._edge, this.extent);

  /// The whole screen.
  static const StageFocus whole = StageFocus._(null, 0);

  /// The top [extent] points: headers, piers, the status bar.
  const StageFocus.top(this.extent) : _edge = VerticalDirection.down;

  /// The bottom [extent] points: quays, sheets, the keyboard. As the tide
  /// comes in the view rises with the waterline, keeping the keyboard's top
  /// edge in sight and what rides it.
  const StageFocus.bottom(this.extent) : _edge = VerticalDirection.up;

  final VerticalDirection? _edge;

  /// How many points of the screen it shows.
  final double extent;

  /// How much of the keyboard a bottom view keeps in sight.
  static const double keyboardInView = 96;

  bool get isWhole => _edge == null;

  /// The rows of [device] in view, in screen points, with [tideHeight] of
  /// keyboard up.
  ({double top, double height}) window(final StageDevice device, final double tideHeight) {
    final double screen = device.size.height;
    if (_edge == null || extent >= screen) {
      return (top: 0.0, height: screen);
    }
    if (_edge == VerticalDirection.down) {
      return (top: 0.0, height: extent);
    }
    final double bottom = screen - math.max(0.0, tideHeight - keyboardInView);
    return (top: math.max(0.0, bottom - extent), height: extent);
  }

  String get label => switch (_edge) {
    null => 'whole phone',
    VerticalDirection.down => 'top ${extent.toStringAsFixed(0)}',
    VerticalDirection.up => 'bottom ${extent.toStringAsFixed(0)}',
  };
}

/// Everything the stage's controls set: device, coast switches, tide, reading
/// direction and the chart. Listen to it to rebuild with the stage.
class StageSettings extends ChangeNotifier {
  StageSettings({this._device = StageDevice.iPhone17});

  StageDevice _device;
  bool _statusBar = true;
  bool _homeIndicator = true;
  bool _rtl = false;
  bool _chart = false;
  bool _wholePhone = false;
  double _tide = 0.0;

  StageDevice get device => _device;
  bool get statusBar => _statusBar;
  bool get homeIndicator => _homeIndicator;
  bool get rtl => _rtl;
  bool get chart => _chart;

  /// Whether to show the whole phone even where a page focuses on part of it.
  bool get wholePhone => _wholePhone;

  /// How far the tide is in, 0 (low) to 1 (high).
  double get tide => _tide;

  /// The keyboard's height on the stage's device at the current tide.
  double get tideHeight => _device.tideHeight * _tide;

  set device(final StageDevice value) => _set(() {
    _device = value;
    if (value.tv) {
      _tide = 0.0;
    }
  });
  set statusBar(final bool value) => _set(() => _statusBar = value);
  set homeIndicator(final bool value) => _set(() => _homeIndicator = value);
  set rtl(final bool value) => _set(() => _rtl = value);
  set chart(final bool value) => _set(() => _chart = value);
  set wholePhone(final bool value) => _set(() => _wholePhone = value);
  set tide(final double value) => _set(() => _tide = value.clamp(0.0, 1.0));

  final Map<String, String> _probes = <String, String>{};

  /// What each [StageProbe] on the stage last read.
  Map<String, String> get probes => Map<String, String>.unmodifiable(_probes);

  final Map<String, Object> _reporters = <String, Object>{};
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Records what [label] reads. A [reporter] that later leaves the stage
  /// takes its reading with it (see [forget]).
  void report(final String label, final String reading, {final Object? reporter}) {
    if (reporter != null) {
      _reporters[label] = reporter;
    }
    if (_probes[label] == reading) {
      return;
    }
    _probes[label] = reading;
    notifyListeners();
  }

  /// Drops [label]'s reading once the frame ends, unless another reporter has
  /// taken the label over by then.
  void forget(final String label, final Object reporter) {
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (_disposed || _reporters[label] != reporter) {
        return;
      }
      _reporters.remove(label);
      if (_probes.remove(label) != null) {
        notifyListeners();
      }
    });
  }

  // Readings stay put: a probe that the change touches reads again, and one
  // that it doesn't still reads the same.
  void _set(final VoidCallback change) {
    change();
    notifyListeners();
  }

  /// The `MediaQuery` the stage's device would report.
  MediaQueryData mediaQuery(final MediaQueryData base) {
    final EdgeInsets coast = EdgeInsets.fromLTRB(
      _device.coast.left,
      _statusBar ? _device.coast.top : 0.0,
      _device.coast.right,
      _homeIndicator ? _device.coast.bottom : 0.0,
    );
    final double keyboard = tideHeight;
    return base.copyWith(
      size: _device.size,
      devicePixelRatio: 3.0,
      // iOS and Android report no bottom padding while the keyboard covers it.
      padding: keyboard > 0 ? coast.copyWith(bottom: 0.0) : coast,
      viewPadding: coast,
      viewInsets: EdgeInsets.only(bottom: keyboard),
      textScaler: TextScaler.noScaling,
    );
  }
}

/// Carries the stage's settings and its content builder down past the
/// stage's own navigator, so the content rebuilds when the guide page does.
class StageScope extends InheritedWidget {
  const StageScope({super.key, required this.settings, required this.builder, required super.child});

  final StageSettings settings;
  final WidgetBuilder builder;

  static StageScope of(final BuildContext context) => context.dependOnInheritedWidgetOfExactType<StageScope>()!;

  static StageSettings? settingsOf(final BuildContext context) =>
      context.getInheritedWidgetOfExactType<StageScope>()?.settings;

  @override
  bool updateShouldNotify(final StageScope oldWidget) => true;
}

/// A phone on a stand: a bezel around a pretend screen with its own sea, its
/// own navigator (so sheets and dialogs open inside it), a status bar and
/// home indicator drawn over it, and a keyboard that rises with the tide.
///
/// With a [focus], only that part of the phone is on the stage, drawn as big
/// as fits; the phone fades out past the cut.
class Stage extends StatelessWidget {
  const Stage({super.key, required this.settings, required this.builder, this.maxHeight = 640, this.focus = StageFocus.whole});

  final StageSettings settings;

  /// Builds what's on the stage's screen: usually a [Harbor].
  final WidgetBuilder builder;

  /// The tallest the stage may be drawn on the page.
  final double maxHeight;

  /// The part of the phone in view, unless [StageSettings.wholePhone].
  final StageFocus focus;

  static const double _bezel = 10;

  /// How far the phone fades out past a cut.
  static const double _fade = 28;

  @override
  Widget build(final BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (final BuildContext context, final Widget? _) {
        final StageDevice device = settings.device;
        final ({double top, double height}) target = (settings.wholePhone ? StageFocus.whole : focus).window(
          device,
          settings.tideHeight,
        );
        return LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) =>
              TweenAnimationBuilder<Offset>(
                // The view glides to a new crop, and rides the tide.
                tween: Tween<Offset>(end: Offset(target.top, target.height)),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (final BuildContext context, final Offset window, final Widget? screen) =>
                    _frame(device, window.dx, window.dy, constraints.maxWidth, screen!),
                child: _Screen(settings: settings, builder: builder),
              ),
        );
      },
    );
  }

  Widget _frame(final StageDevice device, final double top, final double height, final double width, final Widget screen) {
    final bool cutTop = top > 0.5;
    final bool cutBottom = top + height < device.size.height - 0.5;
    final double topBezel = cutTop ? 0 : _bezel;
    final double bottomBezel = cutBottom ? 0 : _bezel;
    // However little room there is, never less than none.
    final double scale = math.max(
      0.0,
      math.min((width - _bezel * 2) / device.size.width, (maxHeight - topBezel - bottomBezel) / height),
    );
    final double corner = device.tv ? 2 : 34 * scale;
    final Radius outer = Radius.circular(device.tv ? 8 : corner + _bezel);
    final Radius inner = Radius.circular(corner);
    Widget view = ClipRRect(
      borderRadius: BorderRadius.vertical(top: cutTop ? Radius.zero : inner, bottom: cutBottom ? Radius.zero : inner),
      child: SizedBox(
        width: device.size.width * scale,
        height: height * scale,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: <Widget>[
            Positioned(
              top: -top * scale,
              left: 0,
              width: device.size.width * scale,
              height: device.size.height * scale,
              child: FittedBox(child: SizedBox.fromSize(size: device.size, child: screen)),
            ),
          ],
        ),
      ),
    );
    final Widget phone = Container(
      key: const ValueKey<String>('stage'),
      padding: EdgeInsets.fromLTRB(_bezel, topBezel, _bezel, bottomBezel),
      decoration: BoxDecoration(
        color: const Color(0xFF111418),
        borderRadius: BorderRadius.vertical(top: cutTop ? Radius.zero : outer, bottom: cutBottom ? Radius.zero : outer),
        boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 18, color: Colors.black54, offset: Offset(0, 6))],
      ),
      child: view,
    );
    if (!cutTop && !cutBottom) {
      return Center(child: phone);
    }
    // The phone runs on past the cut: fade it out there, as a screenshot
    // that bleeds off the page does.
    final double total = height * scale + topBezel + bottomBezel;
    final double fade = math.min(_fade, total / 3) / total;
    view = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (final Rect bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          if (cutTop) const Color(0x00000000),
          const Color(0xFF000000),
          const Color(0xFF000000),
          if (cutBottom) const Color(0x00000000),
        ],
        stops: <double>[if (cutTop) 0.0, if (cutTop) fade else 0.0, if (cutBottom) 1 - fade else 1.0, if (cutBottom) 1.0],
      ).createShader(bounds),
      child: phone,
    );
    return Center(child: view);
  }
}

class _Screen extends StatelessWidget {
  const _Screen({required this.settings, required this.builder});

  final StageSettings settings;
  final WidgetBuilder builder;

  @override
  Widget build(final BuildContext context) {
    final MediaQueryData mediaQuery = settings.mediaQuery(MediaQuery.of(context));
    final StageDevice device = settings.device;
    return StageScope(
      settings: settings,
      builder: builder,
      child: MediaQuery(
        data: mediaQuery,
        child: Directionality(
          textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: HarborSea(
                  coast: device.tv ? const HarborCoast.titleSafe(HarborTitleSafe.fraction(0.05)) : HarborCoast.ambient,
                  margin: EdgeInsetsDirectional.symmetric(horizontal: device.tv ? 32 : 16),
                  child: HarborChartOverlay(
                    enabled: settings.chart,
                    child: HeroControllerScope.none(
                      child: Navigator(
                        onGenerateRoute: (final RouteSettings _) => PageRouteBuilder<void>(
                          pageBuilder: (final BuildContext context, final Animation<double> a, final Animation<double> b) =>
                              const _StageHome(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The device's own furniture, over everything and never in the way of touches.
              if (settings.statusBar && !device.tv)
                Positioned(top: 0, left: 0, right: 0, height: device.coast.top, child: IgnorePointer(child: StatusBarArt(island: device.island))),
              if (settings.homeIndicator && device.coast.bottom > 0 && settings.tideHeight <= 0)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: device.coast.bottom,
                  child: const IgnorePointer(child: HomeIndicatorArt()),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: settings.tideHeight,
                child: const IgnorePointer(child: KeyboardArt()),
              ),
              if (device.tv)
                const Positioned.fill(child: IgnorePointer(child: TitleSafeGuideArt())),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageHome extends StatelessWidget {
  const _StageHome();

  @override
  Widget build(final BuildContext context) {
    final StageScope scope = StageScope.of(context);
    return Material(
      color: Palette.deepSea,
      child: DefaultTextStyle.merge(style: const TextStyle(color: Palette.foam), child: scope.builder(context)),
    );
  }
}

/// Reports what `MediaQuery` and the harbor's waters say where it sits, so
/// the guide page can show the numbers under the stage.
class StageProbe extends StatefulWidget {
  const StageProbe({super.key, required this.label, this.child});

  final String label;
  final Widget? child;

  @override
  State<StageProbe> createState() => _StageProbeState();
}

class _StageProbeState extends State<StageProbe> {
  StageSettings? _settings;

  @override
  void didUpdateWidget(final StageProbe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) {
      _settings?.forget(oldWidget.label, this);
    }
  }

  @override
  void dispose() {
    _settings?.forget(widget.label, this);
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double insets = MediaQuery.viewInsetsOf(context).bottom;
    final HarborWatersData waters = HarborWaters.of(context);
    final TextDirection direction = Directionality.of(context);
    String f(final double v) => v.toStringAsFixed(0);
    String box(final EdgeInsetsDirectional e) {
      final EdgeInsets r = e.resolve(direction);
      return 'T ${f(r.top)} · B ${f(r.bottom)} · L ${f(r.left)} · R ${f(r.right)}';
    }

    final String reading =
        'padding  T ${f(padding.top)} · B ${f(padding.bottom)} · L ${f(padding.left)} · R ${f(padding.right)}\n'
        'keyboard ${f(insets)}\n'
        'coast    ${box(waters.coast)}\n'
        'docks    ${box(waters.docks)}\n'
        'mooring  ${box(waters.margin)}';
    final StageSettings? settings = _settings = StageScope.settingsOf(context);
    WidgetsBinding.instance.addPostFrameCallback((final Duration _) {
      if (mounted) {
        settings?.report(widget.label, reading, reporter: this);
      }
    });
    return widget.child ?? const SizedBox.shrink();
  }
}

/// The status bar: the time, signal, Wi-Fi and battery, and the island.
class StatusBarArt extends StatelessWidget {
  const StatusBarArt({super.key, this.island = false});

  final bool island;

  @override
  Widget build(final BuildContext context) => CustomPaint(painter: _StatusBarPainter(island));
}

class _StatusBarPainter extends CustomPainter {
  _StatusBarPainter(this.island);

  final bool island;

  @override
  void paint(final Canvas canvas, final Size size) {
    final double mid = island ? size.height * 0.55 : size.height * 0.5;
    final TextPainter time = TextPainter(
      text: const TextSpan(
        text: '9:41',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Helvetica'),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    time.paint(canvas, Offset(size.width * 0.12, mid - time.height / 2));
    final Paint white = Paint()..color = Colors.white;
    // Signal bars.
    final double x0 = size.width * 0.72;
    for (int i = 0; i < 4; i++) {
      final double h = 4.0 + i * 2.5;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0 + i * 5.0, mid + 6 - h, 3, h), const Radius.circular(1)), white);
    }
    // Wi-Fi arcs.
    final Offset wifi = Offset(x0 + 30, mid + 5);
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: wifi, radius: 3.0 + i * 3.5),
        -math.pi * 0.75,
        math.pi / 2,
        false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    // Battery.
    final Rect battery = Rect.fromLTWH(x0 + 46, mid - 5, 24, 11);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(battery, const Radius.circular(3)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawRRect(RRect.fromRectAndRadius(battery.deflate(2), const Radius.circular(2)), white)
      ..drawRect(Rect.fromLTWH(battery.right + 1, mid - 1.5, 1.5, 4), white);
    if (island) {
      final Rect pill = Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.48), width: 124, height: 36);
      canvas.drawRRect(RRect.fromRectAndRadius(pill, const Radius.circular(18)), Paint()..color = Colors.black);
    }
  }

  @override
  bool shouldRepaint(final _StatusBarPainter oldDelegate) => oldDelegate.island != island;
}

/// The home indicator: the short bar at the bottom of the screen.
class HomeIndicatorArt extends StatelessWidget {
  const HomeIndicatorArt({super.key});

  @override
  Widget build(final BuildContext context) => Center(
    child: Container(
      width: 140,
      height: 5,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(3)),
    ),
  );
}

/// A software keyboard, keys and all: what the tide is in an app.
class KeyboardArt extends StatelessWidget {
  const KeyboardArt({super.key});

  @override
  Widget build(final BuildContext context) => const ClipRect(child: CustomPaint(painter: _KeyboardPainter(), child: SizedBox.expand()));
}

class _KeyboardPainter extends CustomPainter {
  const _KeyboardPainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD1D4DA));
    // The keyboard is drawn from its top, so a low tide shows only its top rows.
    const double rowHeight = 54;
    const List<String> rows = <String>['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
    final double keyWidth = (size.width - 6) / 10;
    final Paint key = Paint()..color = Colors.white;
    final Paint shadow = Paint()..color = const Color(0xFF8A8D93);
    for (int r = 0; r < rows.length; r++) {
      final String letters = rows[r];
      final double inset = (10 - letters.length) * keyWidth / 2;
      for (int i = 0; i < letters.length; i++) {
        final Rect rect = Rect.fromLTWH(3 + inset + i * keyWidth + 3, 10 + r * rowHeight, keyWidth - 6, rowHeight - 12);
        canvas
          ..drawRRect(RRect.fromRectAndRadius(rect.shift(const Offset(0, 1.2)), const Radius.circular(5)), shadow)
          ..drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(5)), key);
        final TextPainter letter = TextPainter(
          text: TextSpan(text: letters[i], style: const TextStyle(color: Colors.black87, fontSize: 22, fontFamily: 'Helvetica')),
          textDirection: TextDirection.ltr,
        )..layout();
        letter.paint(canvas, rect.center - Offset(letter.width / 2, letter.height / 2));
      }
    }
    // Space bar row.
    final double y = 10 + 3 * rowHeight;
    final Paint grey = Paint()..color = const Color(0xFFABB0BA);
    canvas
      ..drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(6, y, keyWidth * 2.4, rowHeight - 12), const Radius.circular(5)), grey)
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(12 + keyWidth * 2.4, y, size.width - keyWidth * 4.8 - 24, rowHeight - 12), const Radius.circular(5)),
        key,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 6 - keyWidth * 2.4, y, keyWidth * 2.4, rowHeight - 12), const Radius.circular(5)),
        Paint()..color = const Color(0xFF2F7CF6),
      );
  }

  @override
  bool shouldRepaint(final _KeyboardPainter oldDelegate) => false;
}

/// The title-safe band on a television: dashed guide lines 5% in from each edge.
class TitleSafeGuideArt extends StatelessWidget {
  const TitleSafeGuideArt({super.key});

  @override
  Widget build(final BuildContext context) => const CustomPaint(painter: _TitleSafePainter());
}

class _TitleSafePainter extends CustomPainter {
  const _TitleSafePainter();

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect safe = Rect.fromLTRB(size.width * 0.05, size.height * 0.05, size.width * 0.95, size.height * 0.95);
    final Paint dash = Paint()
      ..color = Palette.buoyRed.withValues(alpha: 0.8)
      ..strokeWidth = 2;
    void dashed(final Offset a, final Offset b) {
      final double length = (b - a).distance;
      final Offset step = (b - a) / length;
      for (double d = 0; d < length; d += 14) {
        canvas.drawLine(a + step * d, a + step * math.min(d + 8, length), dash);
      }
    }

    dashed(safe.topLeft, safe.topRight);
    dashed(safe.topRight, safe.bottomRight);
    dashed(safe.bottomRight, safe.bottomLeft);
    dashed(safe.bottomLeft, safe.topLeft);
  }

  @override
  bool shouldRepaint(final _TitleSafePainter oldDelegate) => false;
}
