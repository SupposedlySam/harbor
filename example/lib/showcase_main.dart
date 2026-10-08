import 'package:flutter/material.dart';

import 'showcase/showcase.dart';
import 'showcase/timeline.dart';

/// Plays the README showcase on a loop: `fvm flutter run -t lib/showcase_main.dart`.
///
/// The README's video is recorded from the same widget by `tool/render_showcase.sh`.
void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Player()));

class _Player extends StatefulWidget {
  const _Player();

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (ShowcaseTimeline.duration * 1000).round()),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => ColoredBox(
    color: Colors.black,
    child: AnimatedBuilder(
      animation: _clock,
      builder: (final BuildContext context, final Widget? _) => HarborShowcase(time: _clock.value * ShowcaseTimeline.duration),
    ),
  );
}
