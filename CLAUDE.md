# harbor: notes for the agent working here

`README.md` is the API and the vocabulary. Read it whole before changing anything: its "The one
rule" section is the model the names come from (edges, bars, room), and its appendix "Upgrading
from 0.x: renamed in 0.9" maps the 0.8 harbour names to them, with the complete table in
`doc/design/naming.md`.

## Running it

The Flutter version is pinned in `.fvmrc`, so use `fvm flutter`, not a bare `flutter`.

```sh
./tool/check.sh        # analyze (infos are fatal) and test: the package, harbor_test, harbor_material, then the example
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
   A release that changes only documentation (README wording, CHANGELOG text, dartdoc comments,
   nothing a consumer's code can observe) bumps the build number, `1.0.1` -> `1.0.1+1`, never the
   semver patch: a semantic version is for a change to code (Jonah, 2026-10-16). The same goes for
   harbor_test and harbor_material.
2. `./tool/check.sh` must pass, and CI must be green on that commit.
3. `fvm flutter pub publish --dry-run` must report 0 warnings. A pub.dev release can be retracted
   but never deleted, so look at the file list it prints, not just the verdict.
4. `fvm flutter pub publish`.

`harbor_test/` (the sea trials) is a second package, released after harbor from its own
directory. Its `pubspec.yaml` asks for harbor from pub.dev and its committed `pubspec_overrides.yaml`
points that at `../` for development, so before releasing it raise its `harbor:` constraint to the
harbor just published, bump its own `version:` and `CHANGELOG.md`, and run steps 3 and 4 there.

`harbor_material/` (the Material companion, `doc/design/DECISIONS.md` "harbor_material") is a third,
released the same way after harbor: its `pubspec.yaml` asks for `harbor: ^1.0.0` from pub.dev, its
committed `pubspec_overrides.yaml` points harbor and harbor_test at the checkout, and it is not one
of harbor's dev dependencies, so the root `analysis_options.yaml` excludes it and `tool/check.sh`
analyzes it from its own directory.

**What ships is decided by `.pubignore`, which replaces `.gitignore` for pub** in the root
directory. A new gitignore rule must be copied there too, or pub will publish what git ignores.
lamp files, `.claude/`, `CLAUDE.md`, `doc/`, `tool/` and `.github/` are kept out on purpose.

## The owner agent

This repo has an owner agent (see `/owner-agent`), reachable in llm_chat room `harbor_owner`
under the identity `harbor-owner`.

- **None of the agent's tooling is in the repository or the package.** `.claude/`, `.lamp/`,
  `.game_loop/`, `.llm_chat/`, `.showrunner/`, `.worktrees/`, `.harbor_owner/` and `lamp.lock` are
  gitignored and pubignored, and
  every hook is registered in `.claude/`, which is gitignored: game_loop's in `settings.json`,
  where its installer writes them on every `lamp upgrade`, and llm_chat's and the GitHub
  watcher's in `settings.local.json`. Keep each hook in one file only, or it runs twice. A clone
  gets harbor and nothing else; a new owner session sets its tooling up again with `/owner-agent`.
- The GitHub watcher is `.claude/hooks/issue-waker.py`, a Stop hook that polls GitHub while the
  session is idle and wakes it for new issues and PRs, reopens, and comments on open or closed
  items. It is ported from showrunner's waker, which keeps the history behind each rule. Its
  state lives in `.harbor_owner/`.
- game_loop (through lamp) holds the owner's mandate, the stop gate and the doorbell:
  `./.game_loop/bin/game_loop status` first in every session.
- showrunner (through lamp) sends work to crawlers, each a Claude Code session in its own
  worktree under `.worktrees/`: `./.showrunner/bin/showrunner doctor` and `status` first in every
  session. Its config keeps `./tool/check.sh` as the check and serializes leaves on the version
  and changelog files rather than on `test/**`, since harbor's tests are one file per issue. Being
  ignored, its hooks are provisioned into each worktree by `spawn` rather than carried by git.
- **Sign every GitHub comment with the line `— 🤖 harbor owner agent`.** The agent posts under
  the maintainer's account, so this signature is the only way the waker can tell its own
  comments from the maintainer's. An unsigned comment wakes the session that wrote it.
- `lamp.lock` would normally be committed; it is not here because harbor's lamp dependencies
  (llm_chat, game_loop) serve this agent only, which nobody cloning harbor needs.
- `doc/READINGS.md` records when each front-door doc was last read whole.
