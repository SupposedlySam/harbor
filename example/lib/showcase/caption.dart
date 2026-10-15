import 'package:flutter/material.dart';

import '../art/palette.dart';

/// The caption under a showcase video: what the chapter shows, by its name in code, and the line
/// the narrator is saying, word for word.
///
/// Lines swap at once as each is spoken, with no fade or scroll: the eye belongs on the drawing and
/// the device, and someone watching without sound reads exactly what is being said. Shared by the
/// phone tour and the wide-format video.
class ShowcaseCaption extends StatelessWidget {
  const ShowcaseCaption({super.key, required this.term, required this.line, this.code = false});

  /// The chapter's name: the API it shows, or a plain title.
  final String term;

  /// The narrator's line, word for word.
  final String line;

  /// Whether [term] is code (an API name, the install command), set in code type.
  final bool code;

  @override
  Widget build(final BuildContext context) => ColoredBox(
    color: Palette.deepSea,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: <Widget>[
          Text(
            term,
            key: const ValueKey<String>('caption term'),
            style: TextStyle(
              fontFamily: code ? 'Menlo' : 'Georgia',
              fontSize: code ? 26 : 46,
              fontWeight: FontWeight.w700,
              color: Palette.brass,
            ),
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
