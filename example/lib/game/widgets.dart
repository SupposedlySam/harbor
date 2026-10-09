import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/boats.dart';
import '../art/palette.dart';
import 'fleet.dart';

/// The header every page docks at its top: a title on a plank, with an
/// optional way back and a tool at the end. It never pads for the status bar
/// itself; the dock it sits in does.
class PierHeader extends StatelessWidget {
  const PierHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.titleOpacity,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Drives the title's opacity, for a title that hands off from the page.
  final ValueListenable<double>? titleOpacity;
  final bool showBack;

  @override
  Widget build(final BuildContext context) {
    final Widget titleBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Palette.foam), maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null)
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Palette.foam.withValues(alpha: 0.7)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    final ValueListenable<double>? opacity = titleOpacity;
    final Widget middle = opacity == null
        ? titleBlock
        : ValueListenableBuilder<double>(
            valueListenable: opacity,
            builder: (final BuildContext context, final double value, final Widget? child) => Opacity(opacity: value, child: child),
            child: titleBlock,
          );
    // At least 52 tall, and as tall as the title block needs: the title sizes
    // the plank, and the way back and the tool sit on it either side.
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: HarborMooringLine(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 6),
              child: Center(heightFactor: 1, child: middle),
            ),
            Positioned.fill(
              child: NavigationToolbar(leading: leading ?? (showBack ? const BackPlankButton() : null), trailing: trailing),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round brass button with an icon.
class BrassButton extends StatelessWidget {
  const BrassButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.focusNode});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final FocusNode? focusNode;

  @override
  Widget build(final BuildContext context) => IconButton(
    focusNode: focusNode,
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(backgroundColor: Palette.night.withValues(alpha: 0.35), foregroundColor: Palette.foam),
    icon: Icon(icon, size: 20),
  );
}

class BackPlankButton extends StatelessWidget {
  const BackPlankButton({super.key});

  @override
  Widget build(final BuildContext context) => BrassButton(
    icon: Directionality.of(context) == TextDirection.ltr ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
    tooltip: 'Back',
    onPressed: () => Navigator.of(context).maybePop(),
  );
}

/// A note pinned in a scene saying what to try and which harbor pattern it
/// shows. Tap it to fold it down to a small logbook chip (so it never sits in
/// the way of the scene), and tap the chip to read it again.
class LogbookNote extends StatefulWidget {
  const LogbookNote({super.key, required this.pattern, required this.tryThis});

  /// The harbor pattern this scene puts through its paces.
  final String pattern;

  /// What to do to see it.
  final String tryThis;

  @override
  State<LogbookNote> createState() => _LogbookNoteState();
}

class _LogbookNoteState extends State<LogbookNote> {
  bool _open = true;

  @override
  Widget build(final BuildContext context) => Semantics(
    button: true,
    label: _open ? 'Fold the logbook note' : 'Open the logbook note',
    child: GestureDetector(
      key: const ValueKey<String>('logbook note'),
      onTap: () => setState(() => _open = !_open),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: AlignmentDirectional.topStart,
        child: _open ? _note() : _chip(),
      ),
    ),
  );

  Widget _chip() => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Palette.sail.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.menu_book_rounded, color: Palette.plankDark, size: 16),
          SizedBox(width: 6),
          Text('Logbook', style: TextStyle(fontWeight: FontWeight.w700, color: Palette.plankDark)),
        ],
      ),
    ),
  );

  Widget _note() => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Palette.sail.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(6),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 6, color: Colors.black26, offset: Offset(0, 2))],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.menu_book_rounded, color: Palette.plankDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.pattern, style: const TextStyle(fontWeight: FontWeight.w700, color: Palette.plankDark)),
              const SizedBox(height: 4),
              Text(widget.tryThis, style: const TextStyle(color: Color(0xFF4E342E), height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A signal flag: what a raised flare shows.
class SignalFlag extends StatelessWidget {
  const SignalFlag({super.key, required this.message, this.icon = Icons.flag_rounded});

  final String message;
  final IconData icon;

  @override
  Widget build(final BuildContext context) => Material(
    color: Palette.night.withValues(alpha: 0.92),
    shape: const StadiumBorder(side: BorderSide(color: Palette.brass, width: 1.5)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Palette.brass, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(message, style: const TextStyle(color: Palette.foam))),
        ],
      ),
    ),
  );
}

/// A boat's row in a list.
class BoatRow extends StatelessWidget {
  const BoatRow({super.key, required this.boat, this.onTap});

  final Boat boat;
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) => InkWell(
    onTap: onTap,
    child: HarborMooringLine(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: <Widget>[
            SizedBox(width: 64, child: BoatArt(kind: boat.kind, hull: boat.hull, flag: boat.flag, bob: false)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(boat.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Palette.foam)),
                  Text(
                    '${boat.kindLabel} · ${boat.captain} · ${boat.homePort}',
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Text('${boat.voyages}⚓', style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );
}

/// A rounded panel of sailcloth for sheets and cards.
class Sailcloth extends StatelessWidget {
  const Sailcloth({super.key, this.radius = 20, this.color = const Color(0xFF103A5C)});

  final double radius;
  final Color color;

  @override
  Widget build(final BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      border: Border(top: BorderSide(color: Palette.brass.withValues(alpha: 0.6))),
      boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 16, color: Colors.black45)],
    ),
  );
}

/// A sheet's header: a grab handle and a centered title with a close button.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const SizedBox(height: 8),
      Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: Palette.foam.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
      ),
      SizedBox(
        height: 48,
        child: HarborMooringLine(
          child: NavigationToolbar(
            middle: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Palette.foam)),
            trailing: trailing ?? BrassButton(icon: Icons.close_rounded, tooltip: 'Close', onPressed: () => HarborSheet.close(context)),
          ),
        ),
      ),
    ],
  );
}

/// A wide brass action button.
class BrassAction extends StatelessWidget {
  const BrassAction({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(final BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.sailing_rounded),
    label: Text(label),
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      backgroundColor: Palette.brass,
      foregroundColor: Palette.night,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

/// The page every route builds on: transparent Material for text fields and ink.
class HarborPage extends StatelessWidget {
  const HarborPage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(final BuildContext context) => Material(type: MaterialType.transparency, child: child);
}
