import 'package:flutter/material.dart';
import 'package:harbor/harbor.dart';

import '../art/docks.dart';
import '../art/palette.dart';
import '../game/widgets.dart';

/// Harbor registration: an onboarding form, built as a new port.
///
/// Its footer is a quay on pilings, so the keyboard covers the Continue button
/// while you type and the form ends at the waterline. Each field is a beacon
/// that keeps itself in sight as the keyboard rises. While the berth password
/// has focus, the same footer switches to floating, riding the keyboard with
/// the password rules on it. The crest at the top reads the tide's height and
/// shrinks as it comes in: information only, never what anything clears.
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  /// The key on the footer's content, inside its dock.
  static const Key footerKey = ValueKey<String>('registration footer');

  /// The key on the crest's box.
  static const Key crestKey = ValueKey<String>('registration crest');

  /// The keys on the form's fields.
  static const Key boatNameKey = ValueKey<String>('boat name');
  static const Key homePortKey = ValueKey<String>('home port');
  static const Key emailKey = ValueKey<String>('harbor master email');
  static const Key passwordKey = ValueKey<String>('berth password');

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _boatName = TextEditingController();
  final TextEditingController _homePort = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode(debugLabel: 'berth password');
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(_passwordFocusChanged);
  }

  @override
  void dispose() {
    _passwordFocus
      ..removeListener(_passwordFocusChanged)
      ..dispose();
    _boatName.dispose();
    _homePort.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _passwordFocusChanged() {
    if (_passwordFocus.hasFocus != _passwordFocused) {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    }
  }

  void _continue(final BuildContext context) {
    final String boat = _boatName.text.trim().isEmpty ? 'your boat' : _boatName.text.trim();
    FocusScope.of(context).unfocus();
    HarborFlares.raise(
      context,
      slot: HarborFlareSlot.high,
      builder: (final BuildContext context) =>
          SignalFlag(message: 'Welcome to the harbor, $boat!', icon: Icons.anchor_rounded),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(final BuildContext context) => Harbor(
    newPort: true,
    debugLabel: 'harbor registration',
    top: <HarborDock>[
      HarborDock.pier(
        debugLabel: 'crest',
        wake: const HarborWake.fade(length: 16, blurSigma: 12),
        backdrop: ColoredBox(color: Palette.night.withValues(alpha: 0.7)),
        child: const _CrestHeader(),
      ),
    ],
    bottom: <HarborDock>[
      HarborDock.quay(
        // The same dock either way: only its stance on the tide changes.
        key: const ValueKey<String>('registration footer dock'),
        debugLabel: 'registration footer',
        tide: _passwordFocused ? HarborTideStance.float : HarborTideStance.pilings,
        wake: const HarborWake.hairline(),
        backdrop: const QuayStones(),
        child: Builder(
          builder: (final BuildContext context) => _Footer(
            key: RegistrationPage.footerKey,
            password: _passwordFocused ? _password : null,
            onContinue: () => _continue(context),
          ),
        ),
      ),
    ],
    body: ColoredBox(
      color: Palette.deepSea,
      child: HarborFairway(
        padding: const EdgeInsetsDirectional.only(top: 4, bottom: 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: HarborMooringLine(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const LogbookNote(
                    pattern: 'Footer on pilings · floating for one field · fields in sight · shrinking crest',
                    tryThis:
                        'Tap a field: the keyboard covers the Continue quay and the form ends at the waterline, '
                        'with the field kept in sight. Tap the berth password: the same footer floats up on the tide '
                        'with the rules. Watch the crest shrink as the tide comes in.',
                  ),
                  const SizedBox(height: 8),
                  _Field(
                    key: RegistrationPage.boatNameKey,
                    controller: _boatName,
                    label: 'Boat name',
                    hint: 'Barnacle Belle',
                    icon: Icons.sailing_rounded,
                  ),
                  _Field(
                    key: RegistrationPage.homePortKey,
                    controller: _homePort,
                    label: 'Home port',
                    hint: 'Gullhaven',
                    icon: Icons.location_city_rounded,
                  ),
                  _Field(
                    key: RegistrationPage.emailKey,
                    controller: _email,
                    label: "Harbor master's email",
                    hint: 'master@gullhaven.harbor',
                    icon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _Field(
                    key: RegistrationPage.passwordKey,
                    controller: _password,
                    focusNode: _passwordFocus,
                    label: 'Berth password',
                    hint: 'Something the gulls will never guess',
                    icon: Icons.lock_rounded,
                    obscure: true,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The crest: a lighthouse that stands 120 tall at low tide and shrinks to 48
/// as the keyboard comes in. It reads the tide's height to decide how tall to
/// draw itself; nothing clears it by that number. The header it sits in is a
/// dock, measured like any other.
class _CrestHeader extends StatelessWidget {
  const _CrestHeader();

  static const double _lowTide = 120;
  static const double _highTide = 48;

  @override
  Widget build(final BuildContext context) {
    final HarborTideState tide = HarborTide.of(context);
    final double risen = tide.highWater <= 0 ? 0.0 : (tide.height / tide.highWater).clamp(0.0, 1.0);
    final double size = _lowTide + (_highTide - _lowTide) * risen;
    return HarborMooringLine(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            const BackPlankButton(),
            const SizedBox(width: 8),
            SizedBox(
              key: RegistrationPage.crestKey,
              height: size,
              // The beam sweeps while the tide is out; at high tide the lamp is trimmed.
              child: LighthouseArt(key: ValueKey<bool>(tide.isIn), shining: !tide.isIn),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Harbor registration',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Palette.foam),
                  ),
                  Text(
                    'Enter your vessel in the harbor ledger',
                    style: TextStyle(color: Palette.foam.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.keyboardType,
    this.obscure = false,
    this.last = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool last;

  @override
  Widget build(final BuildContext context) => HarborBeacon(
    keepInSight: true,
    onlyWhileFocused: true,
    clearance: 24,
    child: Padding(
      padding: const EdgeInsets.only(top: 14),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: last ? TextInputAction.done : TextInputAction.next,
        style: const TextStyle(color: Palette.foam),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Palette.brass),
          filled: true,
          fillColor: Palette.night.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
  );
}

/// The footer on the quay: Continue and the fine print, plus the password
/// rules while the berth password has focus.
class _Footer extends StatelessWidget {
  const _Footer({super.key, required this.password, required this.onContinue});

  /// The password being typed, while its rules are shown.
  final TextEditingController? password;
  final VoidCallback onContinue;

  @override
  Widget build(final BuildContext context) {
    final TextEditingController? password = this.password;
    return HarborMooringLine(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (password != null)
              ListenableBuilder(
                listenable: password,
                builder: (final BuildContext context, final Widget? _) => _PasswordRules(password: password.text),
              ),
            BrassAction(label: 'Continue', icon: Icons.arrow_forward_rounded, onPressed: onContinue),
            // Afloat on the tide, the footer travels light: the fine print stays ashore.
            if (password == null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                'By registering you agree to the Harbor Byelaws and the gulls’ code of conduct.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.foam.withValues(alpha: 0.75), fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  @override
  Widget build(final BuildContext context) {
    Widget rule(final bool met, final String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: met ? Palette.brass : Palette.foam,
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Palette.foam, fontSize: 12)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          rule(password.length >= 8, 'At least 8 knots'),
          rule(password.contains(RegExp('[0-9]')), 'An anchor (0–9)'),
          rule(password.contains(RegExp('[A-Z]')), 'A flagship (A–Z)'),
        ],
      ),
    );
  }
}
