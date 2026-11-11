# Setup baseline — 002-browse-history

**Date**: 2026-11-10
**Branch**: `002-browse-history`
**Task**: T002

## Confirmed baseline (source review)

| Item | Recorded state | Evidence |
| --- | --- | --- |
| Flutter / Dart | Candidate Flutter `3.47.8` with bundled Dart (no standalone Dart override) | `app/pubspec.yaml` unchanged; planning pins in `specs/002-browse-history/plan.md` |
| Production packages | `characters 1.4.1`, `sqflite 2.4.5`, `uuid 4.6.0` | `app/pubspec.yaml` — no package added |
| Development packages | `flutter_test`, `integration_test`, `flutter_lints 5.0.0`, `sqflite_common_ffi 2.4.5` | `app/pubspec.yaml` — unchanged |
| Schema | `user_version = 1`; no migration, table, index or seed change | `app/lib/core/storage/app_database.dart` (`schemaVersion = 1`), `app/lib/core/storage/migrations.dart` |
| Android floor | `minSdk 24` | `app/android` Gradle configuration (Feature 1 baseline) |
| iOS | Legacy and out of scope under Constitution v2.0.0 | `CLAUDE.md`, constitution v2.0.0 |
| New dependencies | None | No `pubspec.yaml` edit was made for this feature |
| Feature slice | `app/lib/features/browse_history/{domain,application,presentation}` created | directories present |

## Not performed

- No `flutter pub get`, `dart format`, `flutter analyze`, build, emulator or physical-device check was run. The owner's Windows machine has no Flutter/Android SDK and no build authorization was supplied for this delivery.
- These commands remain owner-authorized gates and must not be reported as passing until actually observed.
