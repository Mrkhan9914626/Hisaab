# Expense-tracker Development Guidelines

Generated from feature planning; corrected for the planned Flutter layout. Last updated: 2026-11-09.

## Active Technologies

- Owner-approved Flutter/Dart, SQLite and Codemagic; Android API 24 minimum. iOS is out of
  scope under constitution v2.0.0 (`001-record-expenses`, `002-browse-history`).
- Candidate Flutter 3.47.8 with its bundled Dart; candidate sqflite 2.4.5, characters 1.4.1,
  uuid 4.6.0. Pins/runner compatibility and licenses require cloud bootstrap verification;
  no build has been run locally. Feature 2 adds no new production dependency.
- App-private SQLite, schema v1, integer paisa, civil dates, stable expense/category IDs,
  one repository/database owner and save coordinator. No backend, analytics or runtime
  network dependency.
- History (002) is read-only: one repository read transaction, pure civil-calendar periods
  (Monday–Sunday weeks), exact checked totals, all active/archived category filters, and no
  schema change or migration.

## Project Structure

Planned, not yet fully scaffolded:

```text
app/lib/core/
app/lib/features/record_expenses/
app/lib/features/browse_history/
app/android/
codemagic.yaml
specs/001-record-expenses/
specs/002-browse-history/
```

Legacy `app/ios/` and existing `app/test/` artifacts are retained for history only and are
not part of the current Android-only, source-code-only scope.

## Commands

The owner's Windows system has no Flutter/Android SDK. Run SDK-dependent checks in Codemagic
from app/ after approved bootstrap, not locally:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter build apk --debug
```

Automated tests are not required under constitution v2.0.0. Verify changes by source review,
successful Android build, and manual Android checks. Never claim a build or check ran when
only source was generated. Push, cloud resource setup, builds and distribution require owner
authorization.

## Code Style

Use Dart formatting, immutable domain values and constructor injection. Separate exact
money/calendar validation, persistence and presentation. No double-based money, silent
rounding, destructive migrations or logging of financial fields. Keep monetary, persistence,
and presentation responsibilities independently reviewable.

## Recent Changes

- 002-browse-history: technical plan, research, data model, read-only storage/operation
  contracts and quickstart for Day/Week/Month history, exact totals, archived-category
  filtering, honest empty/failure states, and selected-day Add integration. Reuses the
  Feature 1 stack and schema v1 with no new dependency or migration; runtime/build evidence
  remains outstanding.
- Constitution v2.0.0: Android-only scope, iOS removed, automated tests no longer required.
- 001-record-expenses: technical plan, research, data model and local contracts for offline
  recording; full V1 and release gates remain incomplete.

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
