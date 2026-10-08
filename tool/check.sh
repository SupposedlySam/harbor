#!/usr/bin/env bash
# The one gate: analyze and test the package, its sea trials (harbor_test), then the example.
#
# CI runs this, and so does a release (CLAUDE.md), so a release and a green build can never be
# checked by two different lists that drift apart.
#
# FLUTTER overrides the command: CI installs the pinned SDK as plain `flutter`, a workstation runs
# it through fvm so `.fvmrc` decides the version.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${FLUTTER:-}" ]]; then
  read -r -a flutter <<< "$FLUTTER"
elif command -v fvm >/dev/null 2>&1; then
  flutter=(fvm flutter)
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
done
