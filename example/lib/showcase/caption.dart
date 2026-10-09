import 'package:flutter/material.dart';

import '../art/palette.dart';

/// The caption under a showcase video: the harbor word, and the line the narrator is saying,
/// word for word.
///
/// Lines swap at once as each is spoken, with no fade or scroll: the eye belongs on the harbor and
/// the device, and someone watching without sound reads exactly what is being said. Shared by the
/// phone tour and the wide-format video.
class ShowcaseCaption extends StatelessWidget {
  const ShowcaseCaption({super.key, required this.term, required this.line, this.pronounced, this.install = false});

  /// The chapter's harbor word.
  final String term;

  /// How [term] is pronounced, for the words whose spelling does not tell you.
  final String? pronounced;

  /// The narrator's line, word for word.
  final String line;

  /// Whether [term] is the install command, set in code type.
  final bool install;

  @override
  Widget build(final BuildContext context) => ColoredBox(
    color: Palette.deepSea,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                term,
                style: TextStyle(
                  fontFamily: install ? 'Menlo' : 'Georgia',
                  fontSize: install ? 34 : 46,
                  fontWeight: FontWeight.w700,
                  color: Palette.brass,
                ),
              ),
              if (pronounced case final String pronounced)
                Text(
                  pronounced,
                  style: TextStyle(fontFamily: 'Georgia', fontSize: 18, fontStyle: FontStyle.italic, color: Palette.foam.withValues(alpha: 0.8)),
                ),
            ],
          ),
          const SizedBox(width: 28),
          Container(width: 2, height: 52, color: Palette.brass.withValues(alpha: 0.5)),
          const SizedBox(width: 28),
          Expanded(
            child: Text(
              line,
              key: const ValueKey<String>('caption line'),
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Georgia', fontSize: 24, height: 1.2, color: Palette.foam),
            ),
          ),
        ],
      ),
    ),
  );
}
