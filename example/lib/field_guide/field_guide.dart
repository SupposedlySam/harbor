import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/palette.dart';
import '../art/sea.dart';
import '../game/widgets.dart';
import 'entries_content.dart';
import 'entries_docks.dart';
import 'entries_floating.dart';
import 'entries_frames.dart';
import 'entries_platform.dart';
import 'entries_tide.dart';
import 'entry.dart';

/// Every class in the field guide, in the order of its index.
final List<GuideEntry> fieldGuideEntries = <GuideEntry>[
  ...frameEntries,
  ...dockEntries,
  ...tideEntries,
  ...contentEntries,
  ...floatingEntries,
  ...platformEntries,
];

/// The Harbor Field Guide: every class in the package, named as it is in
/// code, each with a drawing of the real thing it's named after and a stage
/// to try it on.
class FieldGuidePage extends StatelessWidget {
  const FieldGuidePage({super.key});

  @override
  Widget build(final BuildContext context) {
    final Map<GuideGroup, List<GuideEntry>> groups = <GuideGroup, List<GuideEntry>>{
      for (final GuideGroup group in GuideGroup.values)
        group: <GuideEntry>[
          for (final GuideEntry entry in fieldGuideEntries)
            if (entry.group == group) entry,
        ],
    };
    return HarborPage(
      child: Harbor(
        newPort: true,
        debugLabel: 'field guide',
        top: <HarborDock>[
          HarborDock.pier(
            wake: const HarborWake.fade(length: 10, blurSigma: 14),
            backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.7)),
            child: PierHeader(
              title: 'Harbor Field Guide',
              subtitle: 'Every class, and the real thing it’s named for',
              // Opened on its own, there is nothing to go back to.
              showBack: Navigator.canPop(context),
            ),
          ),
        ],
        body: Sea(
          mood: SeaMood.night,
          child: HarborFairway(
            key: const ValueKey<String>('field guide index'),
            slivers: <Widget>[
              const SliverToBoxAdapter(
                child: HarborMooringLine(
                  child: LogbookNote(
                    pattern: 'How to read this guide',
                    tryThis:
                        'Each page is one class, under the name you’d write in code. The drawing is the real thing it’s '
                        'named for. The phone on each page is a stage with its own status bar, home indicator and keyboard: '
                        'drag the tide gauge beside it to bring the keyboard in and out, and use the controls to change '
                        'the class’s options. The readings show what MediaQuery and the harbor’s waters say on the stage.',
                  ),
                ),
              ),
              for (final GuideGroup group in GuideGroup.values)
                if (groups[group]!.isNotEmpty) ...<Widget>[
                  SliverToBoxAdapter(
                    child: HarborMooringLine(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              group.title.toUpperCase(),
                              style: const TextStyle(color: Palette.brass, letterSpacing: 2, fontWeight: FontWeight.w700),
                            ),
                            Text(group.blurb, style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: groups[group]!.length,
                    itemBuilder: (final BuildContext context, final int i) => _EntryRow(entry: groups[group]![i]),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final GuideEntry entry;

  @override
  Widget build(final BuildContext context) => InkWell(
    key: ValueKey<String>('guide ${entry.id}'),
    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: entry.page)),
    child: HarborMooringLine(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Container(
              width: 84,
              height: 60,
              decoration: BoxDecoration(color: Palette.sail, borderRadius: BorderRadius.circular(6)),
              clipBehavior: Clip.antiAlias,
              child: entry.art(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.className,
                    style: const TextStyle(fontFamily: 'Menlo', fontSize: 13, fontWeight: FontWeight.w700, color: Palette.foam),
                  ),
                  const SizedBox(height: 2),
                  Text(entry.realWorld, style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Palette.foam.withValues(alpha: 0.5)),
          ],
        ),
      ),
    ),
  );
}

/// The button that opens the field guide: a book on a brass disc.
class FieldGuideButton extends StatelessWidget {
  const FieldGuideButton({super.key});

  /// Opens the field guide over [context]'s navigator.
  static void open(final BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (final BuildContext context) => const FieldGuidePage()));

  @override
  Widget build(final BuildContext context) => BrassButton(
    key: const ValueKey<String>('field guide button'),
    icon: Icons.menu_book_rounded,
    tooltip: 'Field guide',
    onPressed: () => open(context),
  );
}
