# Expense-tracker Development Guidelines

Generated from feature planning; corrected for the planned Flutter layout. Last updated: 2026-11-04.

## Active Technologies

- Owner-approved Flutter/Dart, SQLite and Codemagic; Android API 24 minimum and iOS 15 minimum (`001-record-expenses`).
- Candidate Flutter 3.47.8 with its bundled Dart; candidate sqflite 2.4.5, characters 1.4.1, uuid 4.6.0; test-only sqflite_common_ffi 2.4.5 plus Flutter SDK testing. Pins/runner compatibility and licenses require cloud bootstrap verification; no build has been run.
- App-private SQLite, integer paisa, civil dates, stable expense/category IDs, one repository/save coordinator. No backend, analytics or runtime network dependency.

## Project Structure

Planned, not yet scaffolded:

```text
app/lib/core/
app/lib/features/record_expenses/
app/test/
app/integration_test/
app/android/
app/ios/
codemagic.yaml
specs/001-record-expenses/
```

## Commands

The owner's Windows system has no Flutter/Android SDK. Run SDK-dependent checks in Codemagic from app/ after approved bootstrap, not locally:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

Native Android/iOS checks are separate from host/FFI tests and APK compilation. See specs/001-record-expenses/quickstart.md for workflow/bootstrap/signing constraints. Never claim tests ran when only source was generated. Push, cloud resource setup, builds and distribution require owner authorization.

## Code Style

Use Dart formatting, immutable domain values and constructor injection. Separate exact money/calendar validation, persistence and presentation. No double-based money, silent rounding, destructive migrations or logging of financial fields. Run meaningful failing behavioral tests in cloud before implementation, then retain fresh green/regression evidence.

## Recent Changes

- 001-record-expenses: technical plan, research, data model and local contracts for offline recording; no application implementation. Full V1 and release gates remain incomplete.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
