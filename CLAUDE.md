# harbor: notes for the agent working here

`README.md` is the API and the vocabulary (docks, piers, quays, fairways, the tide). Read it
whole before changing anything; the names in code are the names in that glossary.

## Running it

The Flutter version is pinned in `.fvmrc`, so use `fvm flutter`, not a bare `flutter`.

```sh
./tool/check.sh        # analyze (infos are fatal) and test, the package then the example
```

That script is the one gate. CI (`.github/workflows/check.yaml`) runs it on every push and pull
request, and a release runs it first. If a check belongs in the gate, add it there.

The example suite is the larger one: the field guide's widget tests measure every class's
options on a pretend phone, so a layout change in `lib/` usually shows up there first. The
device play-through (`example/integration_test/`) is in `README.md`. It needs a simulator and
is not part of the gate.

## How consumers get harbor

From **pub.dev**: `flutter pub add harbor`. That is the only release channel. harbor was briefly a
lamp geanie (wish #1, no consumers) and was taken out on 2026-10-07: a second channel meant two
releases to keep in step for no consumer that needed it. A project on this machine that needs an
unreleased commit takes a git dependency on this repo with a `ref:`.

**Pushed is not released.** To release:

1. Bump `version:` in `pubspec.yaml` and add the entry to `CHANGELOG.md`, in one commit.
2. `./tool/check.sh` must pass, and CI must be green on that commit.
3. `fvm flutter pub publish --dry-run` must report 0 warnings. A pub.dev release can be retracted
   but never deleted, so look at the file list it prints, not just the verdict.
4. `fvm flutter pub publish`.

**What ships is decided by `.pubignore`, which replaces `.gitignore` for pub** in the root
directory. A new gitignore rule must be copied there too, or pub will publish what git ignores.
lamp files, `.claude/`, `CLAUDE.md`, `doc/`, `tool/` and `.github/` are kept out on purpose.

## The owner agent

This repo has an owner agent (see `/owner-agent`), reachable in llm_chat room `harbor_owner`
under the identity `harbor-owner`.

- **None of the agent's tooling is in the repository or the package.** `.claude/`, `.lamp/`,
  `.game_loop/`, `.llm_chat/`, `.harbor_owner/` and `lamp.lock` are gitignored and pubignored, and
  every hook is registered in the machine-local `.claude/settings.local.json`. A clone gets
  harbor and nothing else; a new owner session sets its tooling up again with `/owner-agent`.
- The GitHub watcher is `.claude/hooks/issue-waker.py`, a Stop hook that polls GitHub while the
  session is idle and wakes it for new issues and PRs, reopens, and comments on open or closed
  items. It is ported from showrunner's waker, which keeps the history behind each rule. Its
  state lives in `.harbor_owner/`.
- game_loop (through lamp) holds the owner's mandate, the stop gate and the doorbell:
  `./.game_loop/bin/game_loop status` first in every session.
- **Sign every GitHub comment with the line `— 🤖 harbor owner agent`.** The agent posts under
  the maintainer's account, so this signature is the only way the waker can tell its own
  comments from the maintainer's. An unsigned comment wakes the session that wrote it.
- `lamp.lock` would normally be committed; it is not here because harbor's lamp dependencies
  (llm_chat, game_loop) serve this agent only, which nobody cloning harbor needs.
- `doc/READINGS.md` records when each front-door doc was last read whole.
