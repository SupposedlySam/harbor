import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import '../art/radio_art.dart';
import '../game/fleet.dart';
import '../game/widgets.dart';
import 'registration.dart';

/// The radio room: a column-style page. Its header is a quay, so the list of
/// channels starts below it rather than sailing under it, and the page ends
/// above the town's tab bar like any tab.
class RadioTab extends StatelessWidget {
  const RadioTab({super.key});

  @override
  Widget build(final BuildContext context) => Harbor(
    debugLabel: 'radio room',
    top: const <HarborDock>[
      HarborDock.quay(
        debugLabel: 'radio room header',
        backdrop: QuayStones(),
        child: PierHeader(title: 'Radio room', subtitle: 'Four channels on the air'),
      ),
    ],
    body: RadioWaves(
      child: HarborFairway(
        padding: const EdgeInsetsDirectional.only(top: 8, bottom: 16),
        slivers: <Widget>[
          const SliverToBoxAdapter(
            child: HarborMooringLine(
              child: LogbookNote(
                pattern: 'Column-style quay header',
                tryThis:
                    'The header is a quay: this list starts where it ends instead of sailing under it. '
                    'Tune in to a channel, or register a new boat at the bottom.',
              ),
            ),
          ),
          SliverList.builder(
            itemCount: Fleet.channels.length,
            itemBuilder: (final BuildContext context, final int i) => _ChannelRow(
              channel: Fleet.channels[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (final BuildContext context) => HarborPage(child: ChannelPage(channel: Fleet.channels[i])),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: HarborMooringLine(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Builder(
                  builder: (final BuildContext context) => BrassAction(
                    label: 'Register a new boat',
                    icon: Icons.app_registration_rounded,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (final BuildContext context) => const HarborPage(child: RegistrationPage()),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.onTap});

  final RadioChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final RadioCall latest = channel.calls.first;
    return InkWell(
      onTap: onTap,
      child: HarborMooringLine(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.night.withValues(alpha: 0.6),
                  border: Border.all(color: Palette.brass, width: 1.5),
                ),
                child: Text(
                  channel.frequency.replaceFirst('Ch ', ''),
                  style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(channel.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Palette.foam)),
                    Text(
                      '${latest.from}: ${latest.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Palette.foam.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(channel.frequency, style: TextStyle(color: Palette.foam.withValues(alpha: 0.5), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A call on the log, with an id that survives edits and new calls.
class _LoggedCall {
  _LoggedCall(this.id, this.call, {this.edited = false});

  final int id;
  final RadioCall call;
  final bool edited;
}

enum _CallAction { reply, edit, copy }

/// A radio channel: a new port with a frosted pier for its header and a
/// composer quay that floats on the tide. The thread is a reversed fairway, so
/// its newest call rests just above the composer, at low tide and high, and
/// older calls sail up under the header.
///
/// Type "@" for a buoy of crew anchored above the composer, hold a call for a
/// dialog of actions that keeps to this page's clear water, and open the photo
/// locker with the paperclip: a breakwater sheet the thread keeps clear of.
class ChannelPage extends StatefulWidget {
  const ChannelPage({super.key, required this.channel});

  final RadioChannel channel;

  /// The key on the bubble of the call with [id]. The channel's own calls take
  /// ids from 0 (the newest) up; calls sent here take the next ids after them.
  static Key callKey(final int id) => ValueKey<String>('call $id');

  /// The key on the composer, inside its dock.
  static const Key composerKey = ValueKey<String>('composer');

  /// The key on the header, inside its dock.
  static const Key headerKey = ValueKey<String>('channel header');

  /// The key on the crew mention list, inside its buoy.
  static const Key mentionsKey = ValueKey<String>('crew mentions');

  /// The key on the call actions card, inside its dialog.
  static const Key actionsKey = ValueKey<String>('call actions');

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  late final List<_LoggedCall> _calls = <_LoggedCall>[
    for (int i = 0; i < widget.channel.calls.length; i++) _LoggedCall(i, widget.channel.calls[i]),
  ];
  late int _nextId = _calls.length;
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'composer');
  final HarborAnchor _composerAnchor = HarborAnchor(debugLabel: 'composer');
  String? _mentionQuery;
  int? _editingId;
  bool _noteUp = true;

  @override
  void initState() {
    super.initState();
    _text.addListener(_watchForMentions);
  }

  @override
  void dispose() {
    _text
      ..removeListener(_watchForMentions)
      ..dispose();
    _focus.dispose();
    _composerAnchor.dispose();
    super.dispose();
  }

  /// The crew name being typed after an "@" at the cursor, or null.
  static String? _mentionAt(final TextEditingValue value) {
    final int cursor = value.selection.baseOffset;
    if (cursor < 0 || cursor > value.text.length) {
      return null;
    }
    final String before = value.text.substring(0, cursor);
    final int at = before.lastIndexOf('@');
    if (at < 0 || (at > 0 && before[at - 1].trim().isNotEmpty)) {
      return null;
    }
    final String query = before.substring(at + 1);
    return query.contains(RegExp(r'\s')) ? null : query;
  }

  void _watchForMentions() {
    final String? query = _mentionAt(_text.value);
    if (query != _mentionQuery) {
      setState(() => _mentionQuery = query);
    }
  }

  List<Sailor> get _mentionable {
    final String query = (_mentionQuery ?? '').toLowerCase();
    return <Sailor>[
      for (final Sailor sailor in Fleet.crew)
        if (sailor.name.toLowerCase().startsWith(query)) sailor,
    ];
  }

  void _mention(final Sailor sailor) {
    final TextEditingValue value = _text.value;
    final int cursor = value.selection.baseOffset;
    final String before = value.text.substring(0, cursor);
    final int at = before.lastIndexOf('@');
    final String inserted = '${before.substring(0, at)}@${sailor.name} ';
    _text.value = TextEditingValue(
      text: inserted + value.text.substring(cursor),
      selection: TextSelection.collapsed(offset: inserted.length),
    );
    _focus.requestFocus();
  }

  void _send() {
    final String text = _text.text.trim();
    if (text.isEmpty) {
      return;
    }
    final int? editing = _editingId;
    final int index = editing == null ? -1 : _calls.indexWhere((final _LoggedCall c) => c.id == editing);
    if (index < 0) {
      _post(text);
    } else {
      final RadioCall old = _calls[index].call;
      setState(() {
        _calls[index] = _LoggedCall(
          editing!,
          RadioCall(from: old.from, text: text, mine: old.mine, minutesAgo: old.minutesAgo),
          edited: true,
        );
        _editingId = null;
      });
    }
    _text.clear();
  }

  void _post(final String text) => setState(
    () => _calls.insert(0, _LoggedCall(_nextId++, RadioCall(from: 'You', text: text, mine: true, minutesAgo: 0))),
  );

  void _cancelEdit() {
    setState(() => _editingId = null);
    _text.clear();
  }

  Future<void> _showActions(final BuildContext callContext, final _LoggedCall logged) async {
    final RenderBox box = callContext.findRenderObject()! as RenderBox;
    final Rect near = box.localToGlobal(Offset.zero) & box.size;
    final _CallAction? action = await showHarborDialog<_CallAction>(
      callContext,
      inheritClearWater: true,
      builder: (final BuildContext context) => _CallActionsDialog(logged: logged, near: near),
    );
    if (!mounted || action == null) {
      return;
    }
    switch (action) {
      case _CallAction.reply:
        final String text = '${logged.call.from}, copy that. ';
        _text.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() => _editingId = null);
        _focus.requestFocus();
      case _CallAction.edit:
        final String text = logged.call.text;
        _text.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
        setState(() => _editingId = logged.id);
        _focus.requestFocus();
      case _CallAction.copy:
        await Clipboard.setData(ClipboardData(text: logged.call.text));
        if (callContext.mounted) {
          HarborSignals.raise(
            callContext,
            slot: HarborSignalSlot.low,
            builder: (final BuildContext context) =>
                const SignalFlag(message: 'Call copied to the log', icon: Icons.content_copy_rounded),
          );
        }
    }
  }

  void _openPhotoLocker(final BuildContext context) {
    showHarborSheet<void>(
      context,
      breakwater: true,
      builder: (final BuildContext context) => HarborSheet.draggable(
        debugLabel: 'photo locker',
        extent: _lockerExtent,
        surface: const Sailcloth(),
        header: const SheetHeader(title: 'Photo locker'),
        builder: (final BuildContext context, final ScrollController controller) => HarborFairway(
          controller: controller,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 16),
          slivers: <Widget>[
            const SliverToBoxAdapter(
              child: LogbookNote(
                pattern: 'Breakwater sheet',
                tryThis:
                    'This sheet reports how far it covers the channel, so the thread keeps clear of it: '
                    'drag the locker up and down and watch the newest call ride above it. Tap a photo to send it.',
              ),
            ),
            SliverGrid.builder(
              itemCount: 18,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (final BuildContext context, final int i) {
                final PhotoScene scene = PhotoScene.values[i % PhotoScene.values.length];
                return GestureDetector(
                  onTap: () {
                    HarborSheet.close(context);
                    _post('📷 A snapshot: ${_photoTitle(scene)}');
                  },
                  child: PhotoTile(scene: scene, hull: Palette.hulls[i % Palette.hulls.length]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static const HarborSheetExtent _lockerExtent = HarborSheetExtent();

  static String _photoTitle(final PhotoScene scene) => switch (scene) {
    PhotoScene.sunset => 'sunset over Gullhaven',
    PhotoScene.lighthouse => 'the old lighthouse',
    PhotoScene.boat => 'Saltwind under full sail',
    PhotoScene.gulls => 'the gulls, plotting',
    PhotoScene.storm => 'a squall off Foghorn Bay',
    PhotoScene.moonlight => 'moonlight on the moorings',
  };

  @override
  Widget build(final BuildContext context) {
    final List<Sailor> crew = _mentionQuery == null ? const <Sailor>[] : _mentionable;
    return Harbor(
      newPort: true,
      debugLabel: 'radio channel',
      top: <HarborDock>[
        HarborDock.pier(
          debugLabel: 'channel header',
          wake: const HarborWake.fade(length: 12, blurSigma: 20),
          backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.55)),
          child: PierHeader(
            key: ChannelPage.headerKey,
            showBack: true,
            title: widget.channel.name,
            subtitle: widget.channel.frequency,
            trailing: BrassButton(
              icon: Icons.menu_book_rounded,
              tooltip: 'Logbook',
              onPressed: () => setState(() => _noteUp = !_noteUp),
            ),
          ),
        ),
      ],
      bottom: <HarborDock>[
        HarborDock.quay(
          debugLabel: 'composer',
          tide: HarborTideStance.float,
          wake: const HarborWake.hairline(),
          backdrop: const ColoredBox(color: Color(0xF20A2036)),
          child: HarborAnchorPoint(
            anchor: _composerAnchor,
            child: _Composer(
              key: ChannelPage.composerKey,
              controller: _text,
              focusNode: _focus,
              editing: _editingId != null,
              onSend: _send,
              onCancelEdit: _cancelEdit,
              onAttach: _openPhotoLocker,
            ),
          ),
        ),
      ],
      buoys: <HarborBuoy>[
        if (_noteUp)
          HarborBuoy(
            key: const ValueKey<String>('logbook'),
            alignment: Alignment.topCenter,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => setState(() => _noteUp = false),
              // Scrolls rather than overflowing when the clear water is small:
              // the tide is in and the photo locker is up on a small phone.
              child: const SingleChildScrollView(
                child: LogbookNote(
                  pattern: 'Pier header · reversed fairway · floating composer',
                  tryThis:
                      'Tap the composer: the tide rises, the composer floats on it, and the newest call stays just above. '
                      'Type @ for crew, hold a call for actions, open the photo locker with the paperclip. '
                      'Tap this note to stow it; the logbook button brings it back.',
                ),
              ),
            ),
          ),
        if (crew.isNotEmpty)
          HarborBuoy.anchored(
            key: const ValueKey<String>('mentions'),
            anchor: _composerAnchor,
            child: _MentionList(crew: crew, onPick: _mention),
          ),
      ],
      body: RadioWaves(
        child: HarborFairway(
          reverse: true,
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: <Widget>[
            SliverList.builder(
              itemCount: _calls.length,
              itemBuilder: (final BuildContext context, final int i) {
                final _LoggedCall logged = _calls[i];
                final Widget bubble = _CallBubble(
                  key: ValueKey<int>(logged.id),
                  logged: logged,
                  editing: logged.id == _editingId,
                  onLongPress: (final BuildContext context) => _showActions(context, logged),
                );
                // The call being edited keeps itself in sight as the keyboard comes in.
                return logged.id == _editingId ? HarborBeacon(keepInSight: true, clearance: 8, child: bubble) : bubble;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.editing,
    required this.onSend,
    required this.onCancelEdit,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool editing;
  final VoidCallback onSend;
  final VoidCallback onCancelEdit;
  final ValueChanged<BuildContext> onAttach;

  @override
  Widget build(final BuildContext context) => HarborMooringLine(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (editing)
            Row(
              children: <Widget>[
                const Icon(Icons.edit_rounded, size: 14, color: Palette.brass),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Amending a call on the log', style: TextStyle(color: Palette.brass, fontSize: 12)),
                ),
                TextButton(onPressed: onCancelEdit, child: const Text('Belay that')),
              ],
            ),
          Row(
            children: <Widget>[
              BrassButton(icon: Icons.attach_file_rounded, tooltip: 'Photo locker', onPressed: () => onAttach(context)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (final String _) => onSend(),
                  style: const TextStyle(color: Palette.foam),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Call the channel… (@ for crew)',
                    hintStyle: TextStyle(color: Palette.foam.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Palette.deepSea,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BrassButton(icon: editing ? Icons.check_rounded : Icons.send_rounded, tooltip: 'Send', onPressed: onSend),
            ],
          ),
        ],
      ),
    ),
  );
}

class _CallBubble extends StatelessWidget {
  const _CallBubble({super.key, required this.logged, required this.editing, required this.onLongPress});

  final _LoggedCall logged;
  final bool editing;
  final ValueChanged<BuildContext> onLongPress;

  @override
  Widget build(final BuildContext context) {
    final RadioCall call = logged.call;
    final String when = call.minutesAgo == 0 ? 'just now' : '${call.minutesAgo} min ago';
    return HarborMooringLine(
      child: Align(
        alignment: call.mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: Builder(
            builder: (final BuildContext context) => GestureDetector(
              onLongPress: () => onLongPress(context),
              child: Container(
                key: ChannelPage.callKey(logged.id),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: call.mine ? Palette.brass.withValues(alpha: 0.92) : Palette.sea.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(call.mine ? 14 : 4),
                    bottomRight: Radius.circular(call.mine ? 4 : 14),
                  ),
                  border: editing ? Border.all(color: Palette.foam, width: 2) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (!call.mine)
                      Text(
                        call.from,
                        style: const TextStyle(color: Palette.brass, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    Text(call.text, style: TextStyle(color: call.mine ? Palette.night : Palette.foam)),
                    const SizedBox(height: 2),
                    Text(
                      logged.edited ? '$when · amended' : when,
                      style: TextStyle(
                        fontSize: 10,
                        color: (call.mine ? Palette.night : Palette.foam).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MentionList extends StatelessWidget {
  const _MentionList({required this.crew, required this.onPick});

  final List<Sailor> crew;
  final ValueChanged<Sailor> onPick;

  @override
  Widget build(final BuildContext context) => ConstrainedBox(
    // Never taller than the water it floats in: the buoy layer hands it the
    // clear water as its constraints, so a long list scrolls instead of
    // reaching up under the header.
    constraints: const BoxConstraints(maxHeight: 300, maxWidth: 360),
    child: Material(
      key: ChannelPage.mentionsKey,
      color: Palette.night.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Palette.brass.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: crew.length,
        itemBuilder: (final BuildContext context, final int i) {
          final Sailor sailor = crew[i];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              backgroundColor: sailor.color,
              child: Text(
                sailor.name[0],
                style: const TextStyle(color: Palette.night, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(sailor.name, style: const TextStyle(color: Palette.foam)),
            subtitle: Text(sailor.role, style: TextStyle(color: Palette.foam.withValues(alpha: 0.6))),
            onTap: () => onPick(sailor),
          );
        },
      ),
    ),
  );
}

/// The actions card for a call, inside a dialog that inherits the channel's
/// clear water: it settles beside the call it was opened from, but never
/// under the header or the composer.
class _CallActionsDialog extends StatelessWidget {
  const _CallActionsDialog({required this.logged, required this.near});

  final _LoggedCall logged;

  /// Where the call is, in global coordinates.
  final Rect near;

  @override
  Widget build(final BuildContext context) {
    // The dialog's padding is the channel's docks and the tide, so this is the
    // channel's clear water; align the card to the call within it.
    final EdgeInsets clear = MediaQuery.paddingOf(context);
    final double height = MediaQuery.sizeOf(context).height - clear.vertical;
    final double along = height <= 0 ? 0.5 : ((near.center.dy - clear.top) / height).clamp(0.0, 1.0);
    return HarborMoored(
      extra: const EdgeInsetsDirectional.all(8),
      child: Align(
        alignment: Alignment(0, along * 2 - 1),
        child: Material(
          key: ChannelPage.actionsKey,
          color: Palette.night.withValues(alpha: 0.97),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Palette.brass, width: 1.2),
          ),
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '“${logged.call.text}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.75), fontStyle: FontStyle.italic),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.reply_rounded),
                  title: const Text('Reply'),
                  onTap: () => Navigator.of(context).pop(_CallAction.reply),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit'),
                  enabled: logged.call.mine,
                  onTap: () => Navigator.of(context).pop(_CallAction.edit),
                ),
                ListTile(
                  leading: const Icon(Icons.content_copy_rounded),
                  title: const Text('Copy'),
                  onTap: () => Navigator.of(context).pop(_CallAction.copy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
