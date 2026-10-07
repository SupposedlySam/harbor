# harbor: notes for the agent working here

`README.md` is the API and the vocabulary (docks, piers, quays, fairways, the tide). Read it
whole before changing anything; the names in code are the names in that glossary.

## Running it

The Flutter version is pinned in `.fvmrc`, so use `fvm flutter`, not a bare `flutter`.

```sh
./tool/check.sh        # analyze (infos are fatal) and test, the package then the example
```

That script is the one gate. CI (`.github/workflows/check.yaml`) runs it on every push and pull
request, and `lamp publish` runs it before granting a wish. If a check belongs in the gate, add
it there and both pick it up.

The example suite is the larger one: the field guide's widget tests measure every class's
options on a pretend phone, so a layout change in `lib/` usually shows up there first. The
device play-through (`example/integration_test/`) is in `README.md`. It needs a simulator and
is not part of the gate.

## How consumers get harbor

Through **lamp**, published locally from `main`. Not from pub.dev (`publish_to: 'none'`).

```sh
lamp add harbor          # in the consumer; vendors a released commit into .lamp/harbor
```

```yaml
# the consumer's pubspec.yaml; no version constraint, ever: upgrades swap the directory
dependencies:
  harbor:
    path: .lamp/harbor
```

**Pushed is not released.** A consumer sits on a wish, a specific commit, until it runs
`lamp upgrade`. To release, from a clean `main`:

```sh
lamp publish harbor --note "what changed, for someone deciding whether to upgrade"
lamp wishes harbor       # confirm the newest wish names HEAD
```

Keep `version:` in `pubspec.yaml` and `CHANGELOG.md` in step with what a wish carries. The wish
number is lamp's label; the version is what a reader of the changelog sees.

## The owner agent

This repo has an owner agent (see `/owner-agent`), reachable in llm_chat room `harbor_owner`
under the identity `harbor-owner`.

- `.claude/hooks/issue-waker.py` is a Stop hook that polls GitHub while the session is idle and
  wakes it for new issues and PRs, reopens, and comments on open or closed items. It is ported
  from showrunner's waker, which keeps the history behind each rule. Its state lives in
  `.harbor_owner/`, which is gitignored.
- **Sign every GitHub comment with the line `— 🤖 harbor owner agent`.** The agent posts under
  the maintainer's account, so this signature is the only way the waker can tell its own
  comments from the maintainer's. An unsigned comment wakes the session that wrote it.
- The llm_chat wiring (`.lamp/`, `.llm_chat/`, `.claude/settings.local.json`) is machine-local and
  not tracked. `lamp.lock` is tracked and pins the llm_chat version.
- `doc/READINGS.md` records when each front-door doc was last read whole.
