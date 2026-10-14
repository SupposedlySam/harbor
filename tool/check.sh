#!/usr/bin/env bash
# The one gate: analyze and test the package, its sea trials (harbor_test), then the example.
#
# CI runs this, and so does a release (CLAUDE.md), so a release and a green build can never be
# checked by two different lists that drift apart.
#
# FLUTTER overrides the command: CI installs the pinned SDK as plain `flutter`, a workstation runs
# it through fvm so `.fvmrc` decides the version. DART does the same for `dart`, which the pinned
# Flutter SDK brings.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${FLUTTER:-}" ]]; then
  read -r -a flutter <<< "$FLUTTER"
  read -r -a dart <<< "${DART:-dart}"
elif command -v fvm >/dev/null 2>&1; then
  flutter=(fvm flutter)
  dart=(fvm dart)
else
  echo "check.sh: neither FLUTTER nor fvm is available" >&2
  exit 2
fi

for dir in "$root" "$root/harbor_test" "$root/example"; do
  echo "== ${dir#"$root"}/"
  (
    cd "$dir"
    "${flutter[@]}" pub get
    "${flutter[@]}" analyze --fatal-infos
    "${flutter[@]}" test
  )
  if [[ "$dir" == "$root" ]]; then
    # The dart fix transforms (lib/fix_data/), each one checked against its golden in test_fixes/:
    # `--compare-to-golden` runs every test_fixes/*.dart against its .expect. placement.yaml and
    # rename.yaml (with harbor_test/lib/fix_data.yaml) are generated from tool/fix_data/, so they are
    # also checked against their generators; signals.yaml and bars.yaml are hand-written, and their
    # goldens are their only check.
    echo "== dart fix"
    (
      cd "$root"
      "${dart[@]}" run tool/fix_data/placement.dart --check
      "${dart[@]}" run tool/fix_data/rename.dart --check
      cd test_fixes
      "${dart[@]}" fix --compare-to-golden
    )
  fi
done
