#!/usr/bin/env python3
"""Checks that each package's version bump matches what changed since its last release.

A release that changes only documentation (README, CHANGELOG, dartdoc comments, tests, the example:
nothing a consumer's code can observe) bumps the build number, `1.0.1` -> `1.0.1+1`. A change a
consumer can observe (code in lib/, or the pubspec's dependencies) bumps the semantic version. The
maintainer set this rule on 2026-10-16, after three docs-only releases went out as patch bumps
(harbor 1.0.2, harbor_material 0.1.1 and 0.1.2). A rule in CLAUDE.md is only remembered; this makes
it fail.

For each package it finds the version at HEAD and the last different version in the pubspec's git
history (the previous release), diffs that commit against HEAD inside the package, and fails when
the version's semantic core moved with no observable change, or only the build number moved over
an observable change. An unchanged version passes: that is an ordinary commit, not a release.

Usage: tool/check_version.py [<rev>]   (default HEAD; a rev checks the tree as of that commit)
"""

import re
import subprocess
import sys

ROOT = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True, check=True).stdout.strip()
PACKAGES = {'harbor': '', 'harbor_test': 'harbor_test/', 'harbor_material': 'harbor_material/'}
OTHER_PACKAGES = [p for p in PACKAGES.values() if p]
DEP_SECTIONS = ('dependencies', 'dev_dependencies', 'dependency_overrides', 'environment')
# Published before this check existed, as patch bumps over docs-only changes. pub.dev versions cannot
# be renumbered, so they are recorded rather than left to fail every later run. Never add to this.
PUBLISHED_BEFORE_THE_RULE = {('harbor', '1.0.2'), ('harbor_material', '0.1.1'), ('harbor_material', '0.1.2')}


def git(*args: str) -> str:
    return subprocess.run(['git', '-C', ROOT, *args], capture_output=True, text=True, check=True).stdout


def version_at(rev: str, pubspec: str) -> str | None:
    try:
        text = git('show', f'{rev}:{pubspec}')
    except subprocess.CalledProcessError:
        return None
    match = re.search(r'^version:\s*(\S+)', text, re.M)
    return match.group(1) if match else None


def core(version: str) -> str:
    return version.split('+', 1)[0]


def is_promotion(previous: str, current: str) -> bool:
    """A pre-release promoted to its release (1.0.0-dev.1 -> 1.0.0): legitimate with no code change."""
    return '-' in core(previous) and core(previous).split('-', 1)[0] == core(current)


def previous_release(rev: str, pubspec: str, current: str) -> str | None:
    """The newest commit, at or before rev, whose pubspec version differs from current."""
    for commit in git('log', '--format=%H', rev, '--', pubspec).split():
        version = version_at(commit, pubspec)
        if version is not None and version != current:
            return commit
    return None


def in_package(path: str, prefix: str) -> bool:
    if prefix:
        return path.startswith(prefix)
    return not any(path.startswith(other) for other in OTHER_PACKAGES)


def observable(base: str, rev: str, prefix: str) -> list[str]:
    """Paths in the package whose change a consumer's code can observe."""
    found = []
    for path in git('diff', '--name-only', base, rev).split():
        if not in_package(path, prefix):
            continue
        local = path[len(prefix):]
        if local == 'pubspec.yaml':
            if _deps_changed(base, rev, path):
                found.append(path)
        elif local.startswith('lib/') and local.endswith('.dart'):
            if _code_changed(base, rev, path):
                found.append(path)
        elif local.startswith('lib/') and local.endswith('.yaml'):
            # lib/fix_data/*.yaml changes what `dart fix` does for consumers.
            found.append(path)
    return found


def _code_changed(base: str, rev: str, path: str) -> bool:
    for line in git('diff', '-U0', base, rev, '--', path).splitlines():
        if line.startswith(('+++', '---')) or not line.startswith(('+', '-')):
            continue
        body = line[1:].strip()
        if body and not body.startswith('//'):
            return True
    return False


def _deps_changed(base: str, rev: str, path: str) -> bool:
    def deps(r: str) -> str:
        try:
            text = git('show', f'{r}:{path}')
        except subprocess.CalledProcessError:
            return ''
        out, keep = [], False
        for line in text.splitlines():
            top = re.match(r'^(\w[\w_]*):', line)
            if top:
                keep = top.group(1) in DEP_SECTIONS
            if keep:
                out.append(line)
        return '\n'.join(out)
    return deps(base) != deps(rev)


def main() -> int:
    rev = sys.argv[1] if len(sys.argv) > 1 else 'HEAD'
    if git('rev-parse', '--is-shallow-repository').strip() == 'true':
        # A shallow clone has no earlier release to compare against, so every package would pass
        # without being checked. Refuse instead: CI checks out with fetch-depth: 0 for this.
        print('check_version: this clone is shallow, so the last release is not in history; '
              'fetch full history (actions/checkout fetch-depth: 0, or git fetch --unshallow)', file=sys.stderr)
        return 2
    failures = []
    for name, prefix in PACKAGES.items():
        pubspec = f'{prefix}pubspec.yaml'
        current = version_at(rev, pubspec)
        if current is None:
            continue
        base = previous_release(rev, pubspec, current)
        if base is None:
            print(f'{name} {current}: no earlier version in history, nothing to compare')
            continue
        previous = version_at(base, pubspec)
        changed = observable(base, rev, prefix)
        semver_moved = core(current) != core(previous)
        print(f'{name} {previous} -> {current}: {len(changed)} observable change(s)'
              + (f' ({", ".join(changed[:4])}{", ..." if len(changed) > 4 else ""})' if changed else ''))
        if (name, current) in PUBLISHED_BEFORE_THE_RULE:
            print(f'  ({name} {current} was published before this check; recorded, not failed)')
        elif semver_moved and not changed and is_promotion(previous, current):
            print(f'  ({previous} -> {current} promotes a pre-release to its release)')
        elif semver_moved and not changed:
            failures.append(f'{name} {previous} -> {current}: only docs, tests or the example changed since {previous}. '
                            f'Bump the build number instead ({core(previous)}+N), not the semantic version.')
        elif not semver_moved and changed:
            failures.append(f'{name} {previous} -> {current}: {changed[0]} changes what consumers get, so this needs a '
                            f'semantic version bump, not only the build number.')
    for failure in failures:
        print(f'check_version: {failure}', file=sys.stderr)
    return 1 if failures else 0


if __name__ == '__main__':
    sys.exit(main())
