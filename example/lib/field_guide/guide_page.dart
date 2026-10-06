import 'dart:async';

import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import '../art/sea.dart';
import '../game/widgets.dart';
import 'stage.dart';

/// One page of the field guide: a class, the real thing it's named after,
/// what it does in an app, and a stage to try it on.
///
/// The entry that builds it owns its own controls' state and rebuilds this
/// page when they change; [stage] is rebuilt with it.
class GuidePage extends StatefulWidget {
  const GuidePage({
    super.key,
    required this.className,
    required this.realWorld,
    required this.inYourApp,
    required this.art,
    required this.stage,
    required this.code,
    this.controls = const <Widget>[],
    this.device = StageDevice.iPhone17,
    this.tide = true,
    this.focus = StageFocus.whole,
    this.settings,
  });

  /// The class, as you'd write it: `HarborDock.pier`.
  final String className;

  /// What the thing is in a real harbor.
  final String realWorld;

  /// What it does in your app.
  final String inYourApp;

  /// A drawing of the real thing.
  final Widget art;

  /// What's on the stage's screen.
  final WidgetBuilder stage;

  /// The code for what's on the stage, as the controls have it now.
  final String code;

  /// This class's own options.
  final List<Widget> controls;

  final StageDevice device;

  /// Whether the tide gauge is offered.
  final bool tide;

  /// The part of the phone this class is about.
  final StageFocus focus;

  /// Settings to share with the entry (to read the tide, say); one is made if null.
  final StageSettings? settings;

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  late final StageSettings _settings = widget.settings ?? StageSettings(device: widget.device);

  @override
  void dispose() {
    if (widget.settings == null) {
      _settings.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // The page is a harbor of its own: the header is a pier over the top,
    // and the controls are a quay along the bottom, so the stage between
    // them stays in sight while you change things.
    return HarborPage(
      child: Harbor(
        newPort: true,
        debugLabel: 'field guide page',
        top: <HarborDock>[
          HarborDock.pier(
            wake: const HarborWake.fade(length: 10, blurSigma: 14),
            backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.7)),
            child: PierHeader(title: widget.className, subtitle: 'Field guide', showBack: true),
          ),
        ],
        bottom: <HarborDock>[
          HarborDock.quay(
            debugLabel: 'control quay',
            backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.97)),
            child: ControlQuay(
              children: <Widget>[
                if (widget.controls.isNotEmpty) ...<Widget>[
                  _Panel(title: widget.className, children: widget.controls),
                  const SizedBox(height: 10),
                ],
                StageControls(settings: _settings, tide: widget.tide, focus: widget.focus),
                const SizedBox(height: 10),
                ProbeReadout(settings: _settings),
                CodeCard(code: widget.code),
              ],
            ),
          ),
        ],
        body: Sea(
          mood: SeaMood.night,
          child: HarborMoored(
            mooringLine: true,
            child: LayoutBuilder(
              builder: (final BuildContext context, final BoxConstraints body) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  // Unfolded, the plate takes at most half the page and scrolls,
                  // so the stage always keeps the rest.
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: body.maxHeight / 2),
                    child: _Plate(
                      art: widget.art,
                      className: widget.className,
                      realWorld: widget.realWorld,
                      inYourApp: widget.inYourApp,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: _settings,
                      builder: (final BuildContext context, final Widget? _) => LayoutBuilder(
                        builder: (final BuildContext context, final BoxConstraints constraints) => Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: Stage(
                                settings: _settings,
                                builder: widget.stage,
                                maxHeight: constraints.maxHeight,
                                focus: widget.focus,
                              ),
                            ),
                            if (!_settings.device.tv && (widget.tide || !widget.focus.isWhole)) ...<Widget>[
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 48,
                                child: TideGauge(settings: _settings, tide: widget.tide, focus: widget.focus),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The controls, on a quay along the bottom of the page: the class's own
/// options first, then the stage's, the readings and the code. Folds down to
/// its handle to give the stage the rest of the page.
class ControlQuay extends StatefulWidget {
  const ControlQuay({super.key, required this.children});

  final List<Widget> children;

  @override
  State<ControlQuay> createState() => _ControlQuayState();
}

class _ControlQuayState extends State<ControlQuay> {
  bool _open = true;

  @override
  Widget build(final BuildContext context) {
    final double reach = MediaQuery.sizeOf(context).height * 0.3;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The quay's stone coping, so it reads as the dock it is.
        const SizedBox(height: 10, child: QuayStones()),
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const ValueKey<String>('control quay handle'),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.tune_rounded, size: 18, color: Palette.brass),
                  const SizedBox(width: 8),
                  const Text('Controls', style: _panelTitle),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'on a HarborDock.quay',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.foam.withValues(alpha: 0.6)),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.0 : 0.5,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.expand_more_rounded, color: Palette.brass),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: reach),
                  child: SingleChildScrollView(
                    key: const ValueKey<String>('control quay'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
                  ),
                ),
        ),
      ],
    );
  }
}

/// The class and the real thing it's named for: a strip with the drawing and
/// the name, that unfolds to say what it is in a harbor and in your app.
class _Plate extends StatefulWidget {
  const _Plate({required this.art, required this.className, required this.realWorld, required this.inYourApp});

  final Widget art;
  final String className;
  final String realWorld;
  final String inYourApp;

  @override
  State<_Plate> createState() => _PlateState();
}

class _PlateState extends State<_Plate> {
  bool _open = false;

  @override
  Widget build(final BuildContext context) => Material(
    color: Palette.sail,
    borderRadius: BorderRadius.circular(8),
    elevation: 3,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const ValueKey<String>('plate'),
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _open ? SingleChildScrollView(child: _unfolded()) : _folded(),
      ),
    ),
  );

  Widget _folded() => SizedBox(
    height: 64,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(width: 96, child: widget.art),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _name(15),
                const SizedBox(height: 2),
                Text(
                  widget.realWorld,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF4E342E), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsetsDirectional.only(end: 8),
          child: Icon(Icons.expand_more_rounded, color: Palette.plank),
        ),
      ],
    ),
  );

  Widget _unfolded() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SizedBox(height: 150, child: widget.art),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _name(17),
            const SizedBox(height: 8),
            _Line(icon: Icons.sailing_rounded, label: 'In the harbor', text: widget.realWorld),
            const SizedBox(height: 6),
            _Line(icon: Icons.phone_iphone_rounded, label: 'In your app', text: widget.inYourApp),
          ],
        ),
      ),
    ],
  );

  // A class name never breaks mid-word; a long one shrinks to fit.
  Widget _name(final double size) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(
      widget.className,
      maxLines: 1,
      style: TextStyle(fontFamily: 'Menlo', fontSize: size, fontWeight: FontWeight.w700, color: Palette.plankDark),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.text});

  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(final BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Icon(icon, size: 18, color: Palette.plank),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '$label  ',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.plankDark),
              ),
              TextSpan(text: text),
            ],
          ),
          style: const TextStyle(color: Color(0xFF4E342E), height: 1.35),
        ),
      ),
    ],
  );
}

const TextStyle _panelTitle = TextStyle(fontFamily: 'Menlo', color: Palette.brass, fontWeight: FontWeight.w700);

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children, this.header});

  final String title;
  final List<Widget> children;

  /// Replaces the title row (a folding panel's tappable header, say).
  final Widget? header;

  @override
  Widget build(final BuildContext context) => Material(
    // A Material, not a decorated box, so the switches' ink shows on it.
    color: Palette.night.withValues(alpha: 0.85),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: Palette.brass.withValues(alpha: 0.4)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        header ??
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Text(title, style: _panelTitle),
            ),
        if (children.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(12, header == null ? 8 : 0, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          )
        else if (header == null)
          const SizedBox(height: 12),
      ],
    ),
  );
}

/// The stage's own switches: device, coast, reading direction and the chart.
///
/// Folded away at first, showing what the stage is set to, so the class's own
/// options sit next to the phone.
class StageControls extends StatefulWidget {
  const StageControls({super.key, required this.settings, this.tide = true, this.focus = StageFocus.whole});

  final StageSettings settings;
  final bool tide;

  /// The page's crop, which the whole-phone switch can undo.
  final StageFocus focus;

  @override
  State<StageControls> createState() => _StageControlsState();
}

class _StageControlsState extends State<StageControls> {
  bool _open = false;

  StageSettings get settings => widget.settings;

  String get _summary => <String>[
    settings.device.name,
    if (!settings.device.tv && !settings.statusBar) 'no status bar',
    if (!settings.device.tv && !settings.homeIndicator) 'no home indicator',
    if (settings.rtl) 'right-to-left',
    if (settings.chart) 'chart',
    if (!widget.focus.isWhole)
      if (settings.wholePhone) 'whole phone' else widget.focus.label,
  ].join(' · ');

  @override
  Widget build(final BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (final BuildContext context, final Widget? _) => AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _Panel(
        title: 'The stage',
        header: InkWell(
          key: const ValueKey<String>('stage settings'),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: <Widget>[
                const Text('The stage', style: _panelTitle),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Palette.foam.withValues(alpha: 0.7)),
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.expand_more_rounded, color: Palette.brass),
                ),
              ],
            ),
          ),
        ),
        children: !_open
            ? const <Widget>[]
            : <Widget>[
                ChoiceControl<StageDevice>(
                  label: 'Device',
                  values: settings.device.tv ? const <StageDevice>[StageDevice.television] : StageDevice.phones,
                  value: settings.device,
                  labelOf: (final StageDevice d) => d.name,
                  onChanged: (final StageDevice d) => settings.device = d,
                ),
                if (!settings.device.tv) ...<Widget>[
                  ToggleControl(
                    label: 'Status bar',
                    value: settings.statusBar,
                    onChanged: (final bool v) => settings.statusBar = v,
                  ),
                  ToggleControl(
                    label: 'Home indicator',
                    value: settings.homeIndicator,
                    onChanged: (final bool v) => settings.homeIndicator = v,
                  ),
                ],
                ToggleControl(
                  label: 'Right-to-left',
                  value: settings.rtl,
                  onChanged: (final bool v) => settings.rtl = v,
                ),
                ToggleControl(
                  label: 'HarborChartOverlay',
                  value: settings.chart,
                  onChanged: (final bool v) => settings.chart = v,
                ),
                if (!widget.focus.isWhole)
                  ToggleControl(
                    label: 'Whole phone',
                    value: settings.wholePhone,
                    onChanged: (final bool v) => settings.wholePhone = v,
                  ),
              ],
      ),
    ),
  );
}

/// The tide gauge: a striped tide staff you drag the water up and down, from
/// low tide (keyboard down) to high tide (keyboard up), with a button that
/// brings the tide in or out the way a keyboard slides.
class TideGauge extends StatefulWidget {
  const TideGauge({super.key, required this.settings, this.tide = true, this.focus = StageFocus.whole});

  final StageSettings settings;

  /// Whether the staff and its toggle are offered.
  final bool tide;

  /// The page's crop: when it has one, a button under the staff swaps it for
  /// the whole phone and back.
  final StageFocus focus;

  @override
  State<TideGauge> createState() => _TideGaugeState();
}

class _TideGaugeState extends State<TideGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(vsync: this, duration: const Duration(milliseconds: 320))
    ..addListener(() => widget.settings.tide = Curves.easeOutCubic.transform(_sweep.value));

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _toggle() {
    _sweep.value = widget.settings.tide;
    unawaited(widget.settings.tide > 0.5 ? _sweep.reverse() : _sweep.forward());
  }

  @override
  Widget build(final BuildContext context) => ListenableBuilder(
    listenable: widget.settings,
    builder: (final BuildContext context, final Widget? _) {
      final double tide = widget.settings.tide;
      final Widget? crop = widget.focus.isWhole
          ? null
          : IconButton(
              key: const ValueKey<String>('focus toggle'),
              tooltip: widget.settings.wholePhone ? 'Focus on the ${widget.focus.label}' : 'Show the whole phone',
              color: Palette.brass,
              onPressed: () => widget.settings.wholePhone = !widget.settings.wholePhone,
              icon: Icon(widget.settings.wholePhone ? Icons.crop_rounded : Icons.fit_screen_rounded),
            );
      if (!widget.tide) {
        return Column(mainAxisAlignment: MainAxisAlignment.end, children: <Widget>[?crop]);
      }
      return LayoutBuilder(
        builder: (final BuildContext context, final BoxConstraints constraints) =>
            // Too short for a staff to drag: just the switches, if they fit.
            constraints.maxHeight < 160 ? const SizedBox.shrink() : _staff(tide, crop),
      );
    },
  );

  Widget _staff(final double tide, final Widget? crop) {
    return Column(
      children: <Widget>[
        Text(
          tide > 0.5 ? 'High' : 'Low',
          style: const TextStyle(color: Palette.brass, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: LayoutBuilder(
            builder: (final BuildContext context, final BoxConstraints constraints) => GestureDetector(
              key: const ValueKey<String>('tide gauge'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (final DragUpdateDetails d) {
                _sweep.stop();
                widget.settings.tide = 1.0 - (d.localPosition.dy / constraints.maxHeight);
              },
              onTapUp: (final TapUpDetails d) =>
                  widget.settings.tide = 1.0 - (d.localPosition.dy / constraints.maxHeight),
              child: CustomPaint(painter: _TideStaffPainter(tide), size: Size(48, constraints.maxHeight)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 48,
          child: IconButton.filled(
            key: const ValueKey<String>('tide toggle'),
            tooltip: tide > 0.5 ? 'Lower the tide' : 'Raise the tide',
            style: IconButton.styleFrom(backgroundColor: Palette.brass, foregroundColor: Palette.night),
            onPressed: _toggle,
            icon: Icon(tide > 0.5 ? Icons.keyboard_hide_rounded : Icons.keyboard_rounded),
          ),
        ),
        ?crop,
      ],
    );
  }
}

class _TideStaffPainter extends CustomPainter {
  _TideStaffPainter(this.tide);

  final double tide;

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect staff = Rect.fromLTWH(size.width / 2 - 9, 0, 18, size.height);
    // Water up to the tide's level.
    final double water = size.height * (0.06 + tide * 0.88);
    final Rect sea = Rect.fromLTWH(0, size.height - water, size.width, water);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)),
        Paint()..color = const Color(0xFF0E2236),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(sea, const Radius.circular(8)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Palette.shallows, Palette.sea],
          ).createShader(sea),
      )
      ..drawRect(staff, Paint()..color = Palette.sail);
    // Black and white bands, a mark every tenth.
    for (int i = 0; i < 10; i++) {
      final double y = size.height * i / 10;
      canvas.drawRect(Rect.fromLTWH(staff.left, y, staff.width, size.height / 20), Paint()..color = Colors.black87);
      final TextPainter mark = TextPainter(
        text: TextSpan(
          text: '${10 - i}',
          style: const TextStyle(color: Palette.buoyRed, fontSize: 8, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      mark.paint(canvas, Offset(staff.right + 2, y + 1));
    }
    // The waterline and its ripple.
    final double line = size.height - water;
    canvas.drawLine(
      Offset(0, line),
      Offset(size.width, line),
      Paint()
        ..color = Palette.foam
        ..strokeWidth = 2,
    );
    final Path handle = Path()
      ..moveTo(0, line - 7)
      ..lineTo(10, line)
      ..lineTo(0, line + 7)
      ..close();
    canvas.drawPath(handle, Paint()..color = Palette.brass);
  }

  @override
  bool shouldRepaint(final _TideStaffPainter oldDelegate) => oldDelegate.tide != tide;
}

/// What the probes on the stage read: `MediaQuery` and the harbor's waters,
/// where each probe sits.
class ProbeReadout extends StatelessWidget {
  const ProbeReadout({super.key, required this.settings});

  final StageSettings settings;

  @override
  Widget build(final BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (final BuildContext context, final Widget? _) {
      final Map<String, String> probes = settings.probes;
      if (probes.isEmpty) {
        return const SizedBox.shrink();
      }
      return _Panel(
        title: 'Readings',
        children: <Widget>[
          for (final MapEntry<String, String> probe in probes.entries) ...<Widget>[
            Text(
              probe.key,
              style: const TextStyle(color: Palette.foam, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              probe.value,
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 11,
                color: Palette.foam.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    },
  );
}

/// The code for what's on the stage, in a dark card.
class CodeCard extends StatelessWidget {
  const CodeCard({super.key, required this.code});

  final String code;

  @override
  Widget build(final BuildContext context) => Container(
    key: const ValueKey<String>('code card'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFF0A0F14), borderRadius: BorderRadius.circular(10)),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Text(
        code,
        style: const TextStyle(fontFamily: 'Menlo', fontSize: 11.5, color: Color(0xFFB8E0FF), height: 1.45),
      ),
    ),
  );
}

/// A row of choices for one option.
class ChoiceControl<T> extends StatelessWidget {
  const ChoiceControl({
    super.key,
    required this.label,
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final T value;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: TextStyle(color: Palette.foam.withValues(alpha: 0.75), fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final T v in values)
              ChoiceChip(
                key: ValueKey<String>('$label: ${labelOf(v)}'),
                label: Text(labelOf(v), style: const TextStyle(fontFamily: 'Menlo', fontSize: 11)),
                selected: v == value,
                onSelected: (final bool _) => onChanged(v),
                selectedColor: Palette.brass,
                labelStyle: TextStyle(color: v == value ? Palette.night : Palette.foam),
                backgroundColor: Palette.deepSea,
                showCheckmark: false,
              ),
          ],
        ),
      ],
    ),
  );
}

/// A switch for one option.
class ToggleControl extends StatelessWidget {
  const ToggleControl({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(final BuildContext context) => SwitchListTile(
    key: ValueKey<String>('toggle $label'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(
      label,
      style: const TextStyle(fontFamily: 'Menlo', fontSize: 12, color: Palette.foam),
    ),
    value: value,
    onChanged: onChanged,
    activeThumbColor: Palette.brass,
  );
}

/// A slider for one number.
class SliderControl extends StatelessWidget {
  const SliderControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(final BuildContext context) => Row(
    children: <Widget>[
      SizedBox(
        width: 120,
        child: Text(
          '$label ${value.toStringAsFixed(0)}',
          style: const TextStyle(fontFamily: 'Menlo', fontSize: 12, color: Palette.foam),
        ),
      ),
      Expanded(
        child: Slider(
          key: ValueKey<String>('slider $label'),
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: Palette.brass,
          onChanged: onChanged,
        ),
      ),
    ],
  );
}

/// What to look for on the stage with the options as they are now.
class GuideHint extends StatelessWidget {
  const GuideHint({super.key, required this.text});

  final String text;

  @override
  Widget build(final BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.visibility_rounded, size: 16, color: Palette.brass),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            key: const ValueKey<String>('hint'),
            style: TextStyle(color: Palette.foam.withValues(alpha: 0.9), fontSize: 13, height: 1.35),
          ),
        ),
      ],
    ),
  );
}
