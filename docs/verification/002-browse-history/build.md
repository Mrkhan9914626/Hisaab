# Android debug build — 002-browse-history

**Date**: 2026-11-11
**Task**: T032
**Status**: **NOT RUN**

## Lane identity

- File: `codemagic.yaml`
- Workflow: `android-debug` (`name: Android debug APK`)
- Flutter channel: `stable`
- Commands:
  - `cd "$CM_BUILD_DIR/app"` then `flutter pub get`
  - `cd "$CM_BUILD_DIR/app"` then `flutter build apk --debug`
- Artifact: `app/build/app/outputs/flutter-apk/app-debug.apk`

## Result

Not run. This machine has no Flutter/Dart SDK (`where.exe flutter` and `where.exe dart` returned no executable), so the lane could not be executed locally. No CI run was triggered.

No build identity (Flutter version, commit, artifact hash, timestamps) exists to record.

## Required when authorized

Run the `android-debug` lane with owner authorization and record:

- Flutter version and channel
- Commit/build identity
- `flutter pub get` result
- `flutter build apk --debug` result and artifact path/hash
- Optional `dart format --output=none --set-exit-if-changed .` and `flutter analyze` results, if run
- Pass/fail/skipped, with the exact failure output when not passing

## Disposition

**Skipped, not passed.** Do not report this lane as a pass until it is actually run.
