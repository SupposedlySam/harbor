# When the front-door docs were last read whole

A search only finds what you already knew to look for. It won't catch a stale sentence or a
section that stopped making sense; reading the file end to end will. This ledger records who
did that, and at which commit. It is easy to game, and that is accepted: a name and a commit
are still more than silence. The pattern is borrowed from showrunner's `docs/READINGS.md`.

One line per reading, newest last:

    - <file> — read whole at <short sha> on <date> — <what the reading changed, or "nothing">

## Readings

- README.md — read whole at 62e10f0 on 2026-10-06 — nothing. I did not check its claims against
  the code; the reading was for sense and for rot.
- CHANGELOG.md — read whole at 62e10f0 on 2026-10-06 — nothing.
- example/SCENARIOS.md — read whole at 62e10f0 on 2026-10-06 — nothing. Every `scenes/*.dart`
  file it names exists.
- example/README.md — read whole at 62e10f0 on 2026-10-06 — it was still the `flutter create`
  stub ("A new Flutter project."). Replaced with a pointer to the game, the field guide and
  SCENARIOS.md.
- README.md — read whole on fix/audit-pass-4 (on integration/0.2.0) on 2026-10-08 — six fixes: a
  sheet with a barrier is a route (the paragraph said every sheet is, right after saying one with
  no barrier is not); the reserved-hinge note said no layout splits around a hinge, false since
  sheets, dialogs, signals and buoys keep off one; `dualScreenOpen` missing from the devices;
  "it goes in the next release" for testing.dart was ambiguous; foldables and dialogs added where
  they belong; the FAB example used the physical `Alignment.bottomRight` the accessibility section
  steers away from. Claims checked against the code only where a fix touched them.
