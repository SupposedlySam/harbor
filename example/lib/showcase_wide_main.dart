import 'package:flutter/material.dart';

import 'showcase_wide/timeline.dart';
import 'showcase_wide/wide.dart';

/// Plays the wide-format README video on a loop: `fvm flutter run -t lib/showcase_wide_main.dart`.
///
/// It is recorded from the same widget by `tool/render_showcase.sh showcase_wide`.
void main() => runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: _Player()));

class _Player extends StatefulWidget {
  const _Player();

  @override
  State<_Player> createState() => _PlayerState();
}

class _PlayerState extends State<_Player> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (WideTimeline.duration * 1000).round()),
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
      builder: (final BuildContext context, final Widget? _) => WideShowcase(time: _clock.value * WideTimeline.duration),
    ),
  );
}
