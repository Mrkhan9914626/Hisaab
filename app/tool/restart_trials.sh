#!/usr/bin/env bash
# External restart-trial driver for SC-004.
#
# Not executed by source implementation. Run only against a synthetic-data
# debug/test installation; never against a device holding real history.
#
# Usage:
#   ./restart_trials.sh <android-package-id> [trials]
set -euo pipefail

PACKAGE_ID="${1:?Usage: restart_trials.sh <android-package-id> [trials]}"
TRIALS="${2:-100}"

command -v adb >/dev/null 2>&1 || {
  printf '%s\n' 'adb is required' >&2
  exit 1
}

adb wait-for-device

for trial in $(seq 1 "$TRIALS"); do
  printf 'Trial %s/%s: force-stop and relaunch\n' "$trial" "$TRIALS"
  adb shell am force-stop "$PACKAGE_ID"
  adb shell monkey -p "$PACKAGE_ID" -c android.intent.category.LAUNCHER 1 >/dev/null
  adb shell "while [ \"\$(pidof '$PACKAGE_ID')\" = \"\" ]; do sleep 1; done"
done

printf '%s\n' 'Restart trials finished. Inspect saved synthetic rows before recording evidence.'
