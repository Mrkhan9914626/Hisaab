# Tasks: Record expenses and see current spending

**Feature:** `001-record-expenses` | **Branch:** `001-record-expenses` | **Date:** 2026-11-06
**Input**: Design documents from `/specs/001-record-expenses/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Automated tests are mandatory for changed production behavior under Constitution V.
Every behavioral task below is preceded by a failing-first test task for the intended missing
behavior. Documentation-only and inspection tasks use named checks instead. No Flutter/Android
SDK exists locally: all SDK-dependent commands run in owner-authorized Codemagic lanes, and no
task may claim results that were not actually observed.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested
independently. All four user stories are P1; US1 is delivered first as the MVP.

**Implementation status (2026-11-09)**: Production Dart source, host/integration test
artifacts, hand-authored Android/iOS platform source and native storage-policy bridges are
present for Phases 2–6. No `flutter pub get`, formatter, analyzer, test, build, native
inspection or cloud lane has executed because no local Flutter/Dart/Android/iOS SDK exists.
Test tasks and every verification/evidence task remain unchecked; no pass, red/green or build
result is claimed. T004 cloud bootstrap and T005 lockfile/toolchain resolution remain blocked.
The platform package identifiers are provisional `com.example.*` values until the owner supplies
the permanent `APP_ORG`; wrapper binaries (`gradle-wrapper.jar`), generated Flutter configs,
Pods and native build evidence are still SDK/cloud-produced. T078's quarantine, writer fence,
finite recovery and matching-row reconciliation are implemented in source, but its native
feasibility gate (T081) still requires real-plugin evidence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: `US1`, `US2`, `US3`, `US4`
- Exact file paths are repository-relative from `D:\Expense-tracker`

## Path Conventions

- Flutter app: `app/` (Android/iOS platform projects generated once by cloud bootstrap)
- Host/widget tests: `app/test/`; native integration tests: `app/integration_test/`
- Evidence and inspection records: `docs/verification/001-record-expenses/`
- No V1 backend, API, cloud data store, analytics or runtime network dependency is created.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Reproducible project scaffold, toolchain pin and cloud lanes. Nothing here is
application behavior; SDK-generated scaffold alone is never counted as feature evidence.

- [X] T001 [P] Record the approved stack ADR (Flutter/Dart/SQLite/Codemagic, Android API 24, iOS 15) in `docs/adr/0001-approved-mobile-stack-and-platform-floors.md` using `.specify/templates/adr-template.md`; cite `plan.md` and `research.md`.
- [X] T002 [P] Record the persistence/lifecycle ADR (protected SQLite, integer paisa, save coordinator, native no-backup bridge) in `docs/adr/0002-protected-sqlite-and-save-coordinator.md`.
- [X] T003 Create root `codemagic.yaml` with workflows `bootstrap-source` (manual macOS), `android-checks-debug` (Linux), `android-native-tests`, `ios-unsigned`, `ios-simulator-tests`; no `ignore_failure`, bounded emulator boot, restricted artifacts, no signing secrets or DB files on PR builds.
- [ ] T004 Run owner-authorized `bootstrap-source` with the permanent `APP_ORG` (requires cloud account, GitHub remote and push approval), download the restricted `flutter-source.tar.gz`, inspect it, and merge generated `app/android/`, `app/ios/`, `app/pubspec.yaml` and ignore files into `app/` without overwriting feature code or specs per `quickstart.md` §2.
- [ ] T005 Configure `app/pubspec.yaml` with pinned `sqflite 2.4.5`, `characters 1.4.1`, `uuid 4.6.0`, dev-only `sqflite_common_ffi 2.4.5`, `flutter_test` and `integration_test`; resolve and review `app/pubspec.lock`; record resolved Dart/Flutter pair, licenses and JDK/Gradle/Xcode/image versions in `docs/build-toolchain.md`.
- [X] T006 Enforce Android `minSdk 24` and iOS deployment target `15.0` in `app/android/app/build.gradle(.kts)` and `app/ios/Podfile`/Runner project settings; verify both platform projects build configuration references the approved floors.
- [X] T007 [P] Configure `app/analysis_options.yaml` (lints, no warnings-as-hidden), formatter compliance and `.gitignore` rules for `app/test-results/`, build caches, `android/local.properties`, signing files and DB artifacts.

**Checkpoint**: Reproducible source and cloud lanes exist. No behavior has been claimed.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Exact domain primitives, protected schema, repository initialization, test harness,
and presentation foundations required by every user story.

**⚠️ CRITICAL**: No user story work begins until this phase is complete.

### Domain and failure primitives

- [ ] T008 [P] Write failing tests for sealed `Result<T>`, `AppFailure` codes and `RetryKind` (ordinary vs reconciliation) in `app/test/domain/app_failure_test.dart`.
- [X] T009 Implement `Result`/`Success`/`Failure`, `AppFailure` (`storageUnavailable`, `initializationFailed`, `incompatibleStore`, `integrityFailure`, `calculationOverflow`, `outcomeUnavailable`, `privacyPolicyUnavailable`) and `RetryKind` in `app/lib/core/domain/app_failure.dart` (no raw SQL, payload or field contents in failures).
- [ ] T010 [P] Write failing Money tests in `app/test/domain/money_test.dart`: `1..99999999900` paisa bounds; outer-whitespace trim; digits plus optional period and 1–2 fraction digits; reject blank/zero/negative/sign/grouping/exponent/currency/incomplete/multiple-dot/`1.001`; reject above max; accept `0.01` and `999999999.00` exactly; format `PKR 1,234.50`; never use `double`.
- [X] T011 Implement exact `Money` parsing/comparison (BigInt or normalized digit strings before int conversion) and integer-only formatting in `app/lib/core/domain/money.dart`.
- [ ] T012 [P] Write failing `LocalDate` tests in `app/test/domain/local_date_test.dart`: Gregorian leap days, invalid `2023-02-29`, year `0001-01-01`/`9999-12-31`, canonical `YYYY-MM-DD`, today/month inclusive-first/exclusive-next boundaries, civil comparison not UTC, and the `9999-12` end predicate.
- [X] T013 Implement validated `LocalDate` (no normalization of invalid dates, no duration-based month math) in `app/lib/core/domain/local_date.dart`.
- [ ] T014 [P] Write failing entity tests in `app/test/domain/entities_test.dart` for `Category`, `Expense`, `ExpenseId`, `Note` and `ImmutableSubmission`: stable IDs, 200/201 grapheme boundary (ZWJ, flags, skin tones, composed/decomposed, line breaks), blank→NULL, nonblank preservation, frozen submission identity, and identity not derived from fields.
- [X] T015 Implement `Category`/`Expense` in `app/lib/features/record_expenses/domain/category.dart` and `expense.dart`; `ExpenseId`/`Note`/`ImmutableSubmission` in `submission.dart`; `OverviewSnapshot` in `overview_snapshot.dart`.
- [ ] T016 [P] Write failing `EntryValidator` tests in `app/test/domain/entry_validator_test.dart`: accepted/rejected amount boundaries, explicit active category required, tomorrow rejected at submission, yesterday accepted, note 200 accepted/201 rejected, and field-error map with preserved input.
- [X] T017 Implement pure `EntryValidator.validate(EntryDraft, LocalDate, List<Category>)` in `app/lib/features/record_expenses/domain/entry_validator.dart` and draft/validation types in `entry_draft.dart`.

### Storage and repository foundation

- [X] T018 [P] Create the host SQLite test harness in `app/test/support/test_database_factory.dart` (file-backed `sqflite_common_ffi`, injected factory) and synthetic fixture builders in `app/test/support/synthetic_fixtures.dart`; no real device data or DB file is copied into tests or CI.
- [ ] T019 [P] Write failing storage-policy contract tests in `app/test/data/local_storage_policy_test.dart`: only a verified private directory is accepted, Dart appends the constant filename, and any failure yields `privacyPolicyUnavailable` with no cache/shared/network fallback.
- [X] T020 Implement the Dart `LocalStoragePolicy` contract, method-channel client and injectable fake in `app/lib/core/storage/local_storage_policy.dart`.
- [X] T021 Implement the Android storage bridge in the generated `app/android/app/src/main/kotlin/**/MainActivity.kt` (plus package files) returning `context.noBackupFilesDir` after verification, with a native failure when unavailable; register it before SQLite opens.
- [X] T022 Implement the iOS storage bridge in `app/ios/Runner/StoragePolicyBridge.swift` and `app/ios/Runner/AppDelegate.swift`: protected Application Support child directory, `isExcludedFromBackup` set and verified before first write, failure rather than Documents fallback.
- [ ] T023 [P] Write failing schema tests in `app/test/data/schema_test.dart`: atomic creation, `user_version=1`, effective `foreign_keys=ON`/`journal_mode=DELETE`/`synchronous=EXTRA`, six seed categories exactly once, Other protected/active/name trigger, amount storage-class/bounds checks, active-category insert trigger, RESTRICT foreign key, and reopen without reseed.
- [X] T024 Implement `AppDatabase` factory configuration, schema v1 creation, triggers/indexes and transactional seeding in `app/lib/core/storage/app_database.dart` and `migrations.dart`; no destructive reset, `REPLACE`, or journal changes inside transactions.
- [ ] T025 [P] Write failing initialization/category tests in `app/test/data/initialize_test.dart`: confirmed empty store succeeds, seed/creation failure rolls back, missing Other or empty active set is `integrityFailure`, newer schema is `incompatibleStore`, corrupt/existing invalid file is an error with no reset/reseed, and archived fixtures remain readable but excluded from active choices.
- [X] T026 Implement `ExpenseRepository.initialize()` and `listActiveCategories()` with injectable `DatabaseFactory` and typed failures in `app/lib/features/record_expenses/data/expense_repository.dart`.

### Presentation foundation

- [ ] T027 [P] Write failing theme/token tests in `app/test/presentation/app_theme_test.dart` for light/dark tokens, 4.5:1 normal / 3:1 large / 3:1 non-text contrast, and 44-pt iOS / 48-dp Android minimum target tokens.
- [X] T028 Implement `app/lib/core/presentation/app_theme.dart` with explicit light/dark tokens, system theme selection, bundled Material icons and system font fallback; no remote assets.
- [ ] T029 [P] Write failing money-display tests in `app/test/presentation/money_text_test.dart` (grouping, two decimals, long totals, no floating formatting) and implement `app/lib/core/presentation/money_text.dart`.

**Checkpoint**: Foundation ready — exact values, protected schema, repository initialization and
theme are testable. User story implementation can now begin.

---

## Phase 3: User Story 1 — Record an expense and trust the saved result (Priority: P1) 🎯 MVP

**Goal**: Offline PKR entry with durable exactly-once save, immediate feedback, saved-date
announcement and a minimal post-save Overview refresh.

**Independent Test**: On an offline installation, save PKR 650.25 for today in Food & drinks
with note Lunch, verify it appears once in today's list with matching totals, terminate and
reopen, and confirm the same identity/values remain — with no duplicate after repeated taps or
retry. Controlled earlier records may be supplied as synthetic fixtures.

### Tests for User Story 1 (write first, verify they fail for the intended missing behavior) ⚠️

- [ ] T030 [P] [US1] Write failing repository save tests in `app/test/data/expense_save_test.dart`: atomic insert of exact paisa/category/date/note; matching-ID same-payload retry returns the saved row once; same-ID different payload is `integrityFailure`; two separate IDs with identical field values create two expenses; earlier/outside-month dates persist but stay out of today (covers Story 1.1–1.7, 4.8).
- [ ] T031 [P] [US1] Write failing coordinator happy-path tests in `app/test/application/save_coordinator_basic_test.dart`: `begin` freezes one UUID payload, repeated `begin` with same ID/payload attaches, repeated taps produce one write, success only after acknowledged commit, and a fresh form gets a new ID (covers Story 1.3, 1.7).
- [ ] T032 [P] [US1] Write a failing widget test in `app/test/presentation/add_expense_save_test.dart`: valid form Save shows immediate saving feedback, on success returns to Overview, today's entry appears once with exact amount and saved-date announcement, and a forced refresh failure still reports Saved separately (covers Story 1.1–1.3, 4.2 post-save edge).
- [ ] T033 [P] [US1] Write a failing native integration test in `app/integration_test/record_expense_test.dart`: offline first launch, record a maximum and a fractional amount, close/reopen, and assert identical identity/amount/category/date/note/count/totals (covers Story 1.1–1.2, 1.4, SC-004 start).

### Implementation for User Story 1

- [X] T034 [US1] Implement `ExpenseRepository.createExpense(ImmutableSubmission)` as one awaited transaction with explicit INSERT, same-ID payload comparison, typed `integrityFailure`, active-category recheck and exact integer/date/note values in `app/lib/features/record_expenses/data/expense_repository.dart` (depends on T024, T026).
- [X] T035 [US1] Implement the one-app-wide `SaveCoordinator.begin()` registry, immutable submission handling and `SaveOutcome`/`SaveProgress` happy path in `app/lib/features/record_expenses/application/save_coordinator.dart`; success emitted only after the commit is observed.
- [X] T036 [US1] Implement `EntryController` form state, fresh defaults (today, no category, no stale carry-over), submission freeze with `uuid` and post-save Overview refresh trigger in `app/lib/features/record_expenses/application/entry_controller.dart`.
- [X] T037 [US1] Implement the minimal Add expense screen with labeled amount/category/date/note fields, Save and Back/Cancel in `app/lib/features/record_expenses/presentation/add_expense_screen.dart`; suppress double taps without hiding feedback and keep layout stable.
- [X] T038 [US1] Implement the minimal populated Overview view (today's rows newest-saved-first, exact count/total, month total) and refresh-after-save in `app/lib/features/record_expenses/presentation/overview_screen.dart` and `application/overview_controller.dart`; do not yet implement US2 empty/stale states.
- [X] T039 [US1] Wire `main.dart`/`app.dart` dependency injection and the working Overview and Add routes only; defer the read-only Details route entirely to T051 so no placeholder or inert route is exposed. Use constructor-injected repository/coordinator and provide no inert History/Categories/Settings/Edit/Delete controls in `app/lib/main.dart` and `app/lib/app.dart`; FR-022's three working routes are complete only after T051.
- [X] T040 [US1] Announce persisted success including the saved civil date and reflect exactly one row in affected summaries; keep a post-save refresh failure separate from write success in `entry_controller.dart` and `overview_controller.dart`.
- [ ] T041 [US1] Run the owner-authorized `android-checks-debug` and relevant integration lane at the US1 commit; retain assertion-level red/green evidence, commit ID and build URL under `docs/verification/001-record-expenses/us1.md` without claiming skipped checks.

**Checkpoint**: US1 is functional and independently testable. MVP ready for validation.

---

## Phase 4: User Story 2 — Understand current spending and individual records (Priority: P1)

**Goal**: Coherent today count/list/total and current-month total that always derive from the
same saved records, plus read-only details and honest empty/unavailable states.

**Independent Test**: Supply synthetic expenses across day, month and year boundaries, open
Overview and a today-row, and compare every displayed amount, count, row and detail field with
the known fixture. No History, edit or category-management interface is required.

### Tests for User Story 2 (write first, verify they fail for the intended missing behavior) ⚠️

- [ ] T042 [P] [US2] Write failing overview-snapshot tests in `app/test/data/overview_test.dart`: one read boundary supplies rows/count/total/month total/any-history; today's total equals the exact row sum; newest `save_sequence` first; month start inclusive/next start exclusive; empty-ever vs empty-today; earlier-date retention; timezone/device-clock change does not rewrite saved dates; totals above per-expense max stay exact (`999999999000000` fixture) and signed-64-bit overflow is `calculationOverflow` (covers Story 2.1, 2.4–2.6, SC-003).
- [ ] T043 [P] [US2] Write failing details-read tests in `app/test/data/expense_details_test.dart`: joined current category name/icon, archived category still readable, note and `No note added` fallback, missing/invalid ID is an integrity/not-found failure (never a blank record), and reads do not mutate data (covers Story 2.2–2.3, 4.7).
- [ ] T044 [P] [US2] Write failing Overview controller/widget tests in `app/test/presentation/overview_states_test.dart`: loading, confirmed empty-ever, empty-today with history and correct month total, populated, unavailable (no zero/empty fallback), explicitly stale prior snapshot, and refresh on resume across local midnight/month change (covers Story 2.1, 2.4–2.5, FR-014).
- [ ] T045 [P] [US2] Write a failing details widget test in `app/test/presentation/details_test.dart`: exact amount, category icon/name, civil date, note or `No note added`, device-only label, no edit/delete controls, predictable Back with no mutation (covers Story 2.2–2.3, FR-013).
- [ ] T046 [P] [US2] Write a failing native integration test in `app/integration_test/overview_details_test.dart`: day/month/year-boundary fixtures show exactly the expected today set/count/total and month total; opening a row shows matching details (covers Story 2.1–2.6, SC-003).

### Implementation for User Story 2

- [X] T047 [US2] Implement `ExpenseRepository.loadOverview(LocalDate today)` as one serialized read transaction returning today rows, derived count/total, exact integer month sum, `hasAnyExpenses` and typed overflow failure in `app/lib/features/record_expenses/data/expense_repository.dart` (depends on T034).
- [X] T048 [US2] Implement `ExpenseRepository.loadExpense(ExpenseId)` with joined category metadata and typed not-found/integrity failures in `expense_repository.dart`.
- [X] T049 [US2] Implement `OverviewController` states (`loading`, `emptyEver`, `emptyToday`, `available`, `unavailable`, `stale`), retained-snapshot marking and refresh on entry/resume/day-month rollover in `app/lib/features/record_expenses/application/overview_controller.dart`.
- [X] T050 [US2] Implement Overview UI states, today's full list (newest first), count/total/month total, empty-ever vs empty-today copy and unavailable/stale error with Retry in `app/lib/features/record_expenses/presentation/overview_screen.dart`; keep a post-save refresh failure distinct from save success.
- [X] T051 [US2] Implement the read-only `expense_details_screen.dart` route from a today-row and register/wire it in `app/lib/main.dart`/`app.dart`: amount, category icon/name, civil date, note/No note added, device-only reminder and Back; no edit/delete controls.
- [ ] T052 [US2] Verify one consistent formatting/ordering source across Overview rows, today totals and details (exact `Money` formatting, `save_sequence` order) and add/extend regressions in `app/test/data/overview_test.dart` and `app/test/presentation/details_test.dart`.
- [ ] T053 [US2] Run the owner-authorized host and native lanes at the US2 commit; retain assertion-level red/green evidence and build URLs in `docs/verification/001-record-expenses/us2.md`.

**Checkpoint**: US1 and US2 work independently and together.

---

## Phase 5: User Story 3 — Start with clear privacy and recovery expectations (Priority: P1)

**Goal**: Offline first-use entry, stable built-in categories and truthful device-only/no-recovery
disclosures, with verified platform backup/transfer restrictions.

**Independent Test**: Launch a clean offline installation, verify first-use Overview, disclosures,
six categories, successful first-entry journey, repeated-launch state preservation, and that no
financial file is copied by platform backup/device transfer.

### Tests for User Story 3 (write first, verify they fail for the intended missing behavior) ⚠️

- [ ] T054 [P] [US3] Write failing first-use tests in `app/test/presentation/first_use_test.dart`: current date, zero spending/count, `No expenses yet`, entry explanation, `Add your first expense`, device-only/no-account/no-sync/no-backup/no-recovery disclosure, no mandatory onboarding, and the empty-ever→empty-today transition after an earlier first save (covers Story 3.1–3.4, FR-017, FR-014).
- [ ] T055 [P] [US3] Write failing category tests in `app/test/data/categories_test.dart`: six stable IDs/names/icons seeded exactly once; Other protected/active with protected name; archived fixture excluded from active choices but readable on saved expenses; repeated opens neither duplicate nor replace identities or existing data (covers Story 3.3, FR-002, FR-021).
- [ ] T056 [P] [US3] Write a failing native storage-policy integration test in `app/integration_test/storage_policy_test.dart`: verified private no-backup directory, DB and sidecars co-located, privacy-bridge failure blocks initialization with existing data untouched, and no fallback path is used (covers FR-018, SC-007 storage side).
- [ ] T057 [P] [US3] Run the Android inspection: merged manifest `allowBackup=false`, legacy and Android 12+ cloud/device-transfer exclusion XML, no release INTERNET permission, no backup agent; record exact files/lines and a synthetic backup/D2D test in `docs/verification/001-record-expenses/android-backup-inspection.md`.
- [ ] T058 [P] [US3] Run the iOS inspection: built entitlements have no iCloud/CloudKit/file-sharing, financial directory carries `isExcludedFromBackup` and file protection before first write; record findings and synthetic backup/restore/Quick Start behavior in `docs/verification/001-record-expenses/ios-storage-inspection.md`.
- [ ] T059 [P] [US3] Runtime-inspect diagnostics and network: logs/crash paths contain no amounts, dates, notes, category names, IDs or DB contents; no outbound financial transfer, analytics SDK, remote font/asset or unrelated permission exists; record in `docs/verification/001-record-expenses/privacy-inspection.md`.
- [ ] T060 [P] [US3] Verify the first-launch/add/overview/details journeys function offline on both platforms with synthetic data and record any emulator/simulator limitation in `docs/verification/001-record-expenses/offline-journeys.md`.

### Implementation for User Story 3

- [X] T061 [US3] Implement the first-use Overview disclosure and `No expenses yet` explanation with `Add your first expense` in `app/lib/features/record_expenses/presentation/overview_screen.dart` (depends on T050).
- [X] T062 [US3] Implement the shared device-only reminder/no-account/no-sync/no-backup/no-recovery copy component in `app/lib/core/presentation/storage_notice.dart` and apply it on Overview and details.
- [X] T063 [US3] Enforce and expose category seed/active/protected/archived invariants in `app/lib/core/storage/app_database.dart` and `app/lib/features/record_expenses/data/expense_repository.dart`; ensure initialization failure surfaces `initializationFailed` without reseeding (depends on T024, T026).
- [X] T064 [US3] Implement Android backup protections in `app/android/app/src/main/AndroidManifest.xml`, `app/android/app/src/main/res/xml/backup_rules.xml` and `data_extraction_rules.xml`; keep `noBackupFilesDir` as the only financial location and ensure no runtime INTERNET permission.
- [X] T065 [US3] Implement iOS backup exclusion/file-protection configuration in `app/ios/Runner/StoragePolicyBridge.swift`, `app/ios/Runner/Info.plist` and Runner entitlements; no iCloud container, document sharing or open-in-place export.
- [X] T066 [US3] Remove/deny any remote asset, font, analytics or network dependency introduced by scaffolding; confirm packaged Material icons/system fallback in `app/pubspec.yaml`, `app/lib/core/presentation/app_theme.dart` and platform manifests.
- [ ] T067 [US3] Run the owner-authorized native storage/policy lanes and retain red/green evidence, actual device/simulator identity and inspection links in `docs/verification/001-record-expenses/us3.md`; any unresolved off-device path stays release-blocking.

**Checkpoint**: First use, categories and device-only disclosures are truthful and testable.

---

## Phase 6: User Story 4 — Recover from mistakes and storage failures safely (Priority: P1)

**Goal**: Field validation, dirty-discard safety, honest write/read/initialization failures,
and cooperative save cancellation with reconciled unknown outcomes and no late/duplicate writes.

**Independent Test**: Supply invalid inputs and controlled faults at queue/insert/commit/recovery
boundaries; inspect retained form contents, focus, announcements, saved rows, totals and
cancellation results, including after reopen.

### Tests for User Story 4 (write first, verify they fail for the intended missing behavior) ⚠️

- [ ] T068 [P] [US4] Write failing form-validation widget tests in `app/test/presentation/add_expense_validation_test.dart`: blank/zero/negative/malformed/over-precision/`0.00`/`999999999.01` rejected with field instructions and preserved input; `0.01`/`999999999.00` accepted; tomorrow unavailable/rejected at submission and a draft that becomes future-dated requires correction without silent change; exactly 200 graphemes accepted and 201 rejected without truncation; focus moves to first invalid field plus a linked summary (covers Story 4.1, 4.8–4.12, FR-004–FR-009, FR-019 errors).
- [ ] T069 [P] [US4] Write failing failure-path tests in `app/test/presentation/failure_states_test.dart` and `app/test/data/failure_paths_test.dart`: write failure retains all fields + actionable Retry, no success, existing records/totals unchanged; startup/refresh read failure shows unavailable + Retry (never zero/genuine-empty); stale values explicitly marked; details load failure offers Retry/Back without fabrication; post-save refresh failure still reports Saved; init failure offers Retry without reset or duplicate categories (covers Story 4.2–4.3, 4.6–4.7, FR-015).
- [ ] T070 [P] [US4] Write failing dirty-discard tests in `app/test/presentation/discard_dialog_test.dart`: unchanged form returns directly; restored-original full form counts as unchanged; changed form shows `Discard expense changes?` with `Keep editing` safe initial focus and focus trap; dismissing preserves every field; explicit discard leaves saved data unchanged; pending save delegates to cancellation instead (covers Story 4.4–4.5, FR-016).
- [ ] T071 [P] [US4] Write failing cancellation/reconciliation coordinator tests in `app/test/application/save_coordinator_cancellation_test.dart` with deterministic barriers at queue dispatch, before insert, final checkpoint and commit acknowledgement: cancel-before-write, rollback-wins, commit-wins reports Saved exactly once, lost acknowledgement, unknown outcome, failed checking retains identity and draft, same-ID retry never duplicates, and no compensating delete (covers Story 4.13–4.15, FR-011).
- [ ] T072 [P] [US4] Write failing recovery tests in `app/test/data/recovery_test.dart`: quarantine uncertain connection, clean same-file recovery, writer fence/exclusive transaction, matching-row → Saved, absence only after original execution settles, finite retry budget, exhaustion → `outcomeUnavailable`, and no reset/reseed on corruption (covers Story 4.15, persistence contract §Idempotency).
- [ ] T073 [P] [US4] Write a failing native integration test in `app/integration_test/pending_cancellation_test.dart`: request cancellation while writing; confirm only after no writer can persist, verify no late row after reopen, and verify commit-wins reports Saved (covers Story 4.13–4.14).
- [ ] T074 [P] [US4] Write a failing restart/persistence integration driver in `app/integration_test/reopen_test.dart` plus external force-stop/relaunch script `app/tool/restart_trials.sh`: 100 successful saves each yield exactly one complete row after termination; interrupted writes yield one row or none; no partial record, duplicate or earlier-record change (covers SC-004, Edge Cases interruption).

### Implementation for User Story 4

- [X] T075 [US4] Implement field-level validation presentation, first-invalid focus, linked multi-error summary and full value retention in `app/lib/features/record_expenses/application/entry_controller.dart` and `presentation/add_expense_screen.dart` (depends on T017, T036).
- [X] T076 [US4] Implement `discard_dialog.dart` and `EntryController.requestLeave()` with initial-value equality, safe `Keep editing` focus, focus trap/restore and system-back/gesture handling; while a save is pending delegate to cancellation (depends on T036).
- [X] T077 [US4] Implement cooperative cancellation in `SaveCoordinator`: cancellation checkpoints before insert and synchronously before normal return, dedicated rollback exception, no unawaited SQL, queued retirement, immutable identity retention and typed outcomes in `app/lib/features/record_expenses/application/save_coordinator.dart`.
- [X] T078 [US4] Implement uncertain-connection quarantine, drain-original-work, clean-boundary recovery, writer fence, matching-row reconciliation and finite retry/exhaustion handling in `save_coordinator.dart` plus adapter support in `app/lib/core/storage/app_database.dart`; never settle on timeout/route disposal and never delete to emulate cancellation.
- [X] T079 [US4] Implement pending-save Back/Cancel UX: offer cancellation, show queued/writing/cancelling/checkingOutcome status without layout shift, disable duplicate submission while uncertain, and provide reconciliation Retry on failure in `presentation/add_expense_screen.dart` and `entry_controller.dart`.
- [X] T080 [US4] Implement write/init/read/refresh failure UI with actionable Retry and no false empty/success: preserve form input, mark retained snapshots stale, offer Retry/Back on details, and separate post-save refresh failure from Saved in `overview_screen.dart`, `expense_details_screen.dart`, `overview_controller.dart` and `add_expense_screen.dart`.
- [ ] T081 [US4] Verify the native cancellation/recovery feasibility gate on the locked sqflite plugin; if a clean boundary cannot be demonstrated, keep `outcomeUnavailable`, block acceptance and record the adapter review in `docs/verification/001-record-expenses/cancellation-gate.md` rather than claiming success.
- [ ] T082 [US4] Run the owner-authorized host/native lanes at the US4 commit and retain assertion-level red/green evidence, actual device identity and skipped-check disclosures in `docs/verification/001-record-expenses/us4.md`.

**Checkpoint**: All four stories are independently functional; cancellation and failure behavior
is honest and evidenced.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Whole-app regression, platform/accessibility/performance evidence and release gates.

- [ ] T083 [P] Run the full cloud host gate (`flutter pub get --enforce-lockfile`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test` including FFI) and retain fresh pass/fail output in `docs/verification/001-record-expenses/host-gate.md`.
- [ ] T084 [P] Run `android-native-tests` on a verified emulator covering API 24 minimum and a current supported OS; record actual emulator/device/OS, boot readiness, results and any unavailable coverage in `docs/verification/001-record-expenses/android-native.md`.
- [ ] T085 [P] Run `ios-unsigned` compile and `ios-simulator-tests`; distinguish compile-only from runtime evidence and record the actual simulator/runtime in `docs/verification/001-record-expenses/ios-native.md`; physical-iPhone signing gaps remain explicitly blocked.
- [ ] T086 [P] Verify accessibility in both themes: 4.5:1 normal / 3:1 large / 3:1 non-text contrast, 44-pt/48-dp targets, screen-reader labels/order, 200%/maximum text, reduced motion, portrait/landscape, keyboard-open forms, safe areas, error focus/summary and no essential action hidden; record in `docs/verification/001-record-expenses/accessibility.md`.
- [ ] T087 [P] Verify the offline journeys end-to-end on physical Android and iPhone when available (first launch, add, Overview, details, cancellation, retry, restart) and record device/OS plus skipped physical checks in `docs/verification/001-record-expenses/physical-journeys.md`.
- [ ] T088 [P] Generate the 10,000-record/24-month/500-today synthetic fixture (including repeated maximum amounts and exact `999999999000000` paisa sum) and run the 30-trial launch/save/details/feedback timings plus full-row reachability on representative 2020–2022/4-GB Android and iPhone devices (candidate Pixel 4a and iPhone 12), recording actual device/OS and whether evidence is physical hardware or an emulator/simulator in `docs/verification/001-record-expenses/performance.md`.
- [ ] T089 [P] Run the 10-person usability/disclosure study for SC-001/SC-007 and record task success, timing, no-recovery explanations and assistance in `docs/verification/001-record-expenses/usability.md`.
- [ ] T090 [P] Run Android cloud/D2D and iOS backup/restore/Quick Start checks with synthetic markers, inspect copied financial files and sidecars, and record release-gate status in `docs/verification/001-record-expenses/backup-transfer.md`; any unresolved off-device path blocks release.
- [ ] T091 [P] Configure the manually gated trusted-branch release signing workflow in `codemagic.yaml` and document stable keystore ownership, no PR secrets and no store auto-publish in `docs/build-toolchain.md`; note that no signing identity is created by this task.
- [ ] T092 [P] Validate `quickstart.md` commands against the actual pinned toolchain, update mismatches in `specs/001-record-expenses/quickstart.md`, and record the verified path in `docs/verification/001-record-expenses/quickstart-validation.md`.
- [ ] T093 Final constitution compliance review: map every FR-001–FR-022, acceptance scenario, edge case and SC-001–SC-007 to a fresh test/inspection result or an explicit blocked/skipped check in `docs/verification/001-record-expenses/acceptance.md`; no claim may exceed observed evidence.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; T003 must precede T004; T004 requires owner-approved `APP_ORG`, cloud account and push authorization.
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS all user stories.
- **US1 (Phase 3)**: Depends on Foundational; no dependency on other stories.
- **US2 (Phase 4)**: Depends on Foundational; benefits from US1 repository save for integration fixtures, but pure data/widget tests can run on synthetic fixtures.
- **US3 (Phase 5)**: Depends on Foundational (native bridge/schema); Overview disclosure integrates with US1/US2 screens.
- **US4 (Phase 6)**: Depends on US1 (coordinator/controller/screens) and Foundational validator; US2 details failure UX integrates with T051.
- **Polish (Phase 7)**: Depends on all desired stories.

### User Story Dependencies (realistic)

- **US1 (P1)**: Independent after Foundational — MVP.
- **US2 (P1)**: Independent after Foundational; final integration refresh touches US1 components.
- **US3 (P1)**: Independent after Foundational; disclosure placement touches the Overview shell.
- **US4 (P1)**: Requires US1's save/controller/screen scaffolding; does not redefine US1 behavior.

### Within Each User Story

1. Write the failing test and confirm it fails for the intended behavioral reason.
2. Implement the minimum production change.
3. Re-run the focused test plus regressions; retain red/green evidence.
4. Do not start a later story while its required tests are unimplemented or failing.

### Parallel Opportunities

- Setup: T001/T002 (ADRs) and T007 (lint) run in parallel; T004 is a serial owner gate.
- Foundational: T008/T010/T012/T014/T016 (domain tests) can be authored in parallel; T018/T019/T021/T022 (storage boundaries) parallel; T023/T025 (schema/repository) sequential; T027/T029 (presentation) parallel.
- US1 tests T030–T033 are parallel across distinct files.
- US2 tests T042–T046 are parallel; implementation T047/T048 sequential on the same repository file, T049–T051 parallel by file.
- US3 tests T054–T060 are parallel; platform implementation T064/T065 parallel; T063 sequential on schema/repository.
- US4 tests T068–T074 are parallel; coordinator work T077/T078 is sequential on the same file.
- Polish inspection tasks T083–T092 are parallel except shared fixture generation (T088 depends on T018).

---

## Parallel Example: User Story 1

```text
Task: "Write failing repository save tests in app/test/data/expense_save_test.dart"
Task: "Write failing coordinator happy-path tests in app/test/application/save_coordinator_basic_test.dart"
Task: "Write failing widget test in app/test/presentation/add_expense_save_test.dart"
Task: "Write failing native integration test in app/integration_test/record_expense_test.dart"
```

```text
After red evidence, implement sequentially where files overlap:
Task: "Implement ExpenseRepository.createExpense in expense_repository.dart"
Task: "Implement SaveCoordinator.begin happy path in save_coordinator.dart"
Task: "Implement Add expense screen and Overview refresh"
```

## Parallel Example: User Story 2

```text
Task: "Write failing overview-snapshot tests in app/test/data/overview_test.dart"
Task: "Write failing details-read tests in app/test/data/expense_details_test.dart"
Task: "Write failing Overview state tests in app/test/presentation/overview_states_test.dart"
Task: "Write failing details widget test in app/test/presentation/details_test.dart"
Task: "Write failing integration test in app/integration_test/overview_details_test.dart"
```

## Parallel Example: User Story 3

```text
Task: "Write failing first-use tests in app/test/presentation/first_use_test.dart"
Task: "Write failing category tests in app/test/data/categories_test.dart"
Task: "Write failing storage-policy native test in app/integration_test/storage_policy_test.dart"
Task: "Run Android backup inspection and record android-backup-inspection.md"
Task: "Run iOS storage inspection and record ios-storage-inspection.md"
```

## Parallel Example: User Story 4

```text
Task: "Write failing validation tests in app/test/presentation/add_expense_validation_test.dart"
Task: "Write failing failure-path tests in app/test/presentation/failure_states_test.dart"
Task: "Write failing discard tests in app/test/presentation/discard_dialog_test.dart"
Task: "Write failing cancellation tests in app/test/application/save_coordinator_cancellation_test.dart"
Task: "Write failing recovery tests in app/test/data/recovery_test.dart"
Task: "Write failing cancellation integration test in app/integration_test/pending_cancellation_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (owner-authorized bootstrap, pins, lanes).
2. Complete Phase 2 (exact domain, schema, repository init, theme).
3. Complete Phase 3 (US1 durable save + minimal Overview).
4. **STOP and VALIDATE**: run US1 native offline record/restart and host suites; retain evidence.
5. Do not declare feature completion; US2–US4 and release gates remain.

### Incremental Delivery

1. Setup + Foundational → reproducible, testable foundation.
2. US1 → MVP recording slice with exactly-once save.
3. US2 → trustworthy summaries and read-only details.
4. US3 → first-use trust, categories and privacy evidence.
5. US4 → validation, cancellation, failure safety.
6. Polish → accessibility, performance, backup/transfer, signing and final acceptance.

### Parallel Team Strategy

- Team completes Setup + Foundational together.
- After Foundational: Developer A owns US1; Developer B can start US2 data tests with fixtures; Developer C can prepare US3 inspections/tests; US4 waits for US1 scaffolding.
- Merge only after the owning story's red/green evidence is recorded.

---

## Notes

- All SDK-dependent checks run only in Codemagic; local SDK absence is never a waiver.
- Push, cloud resource setup, builds, signing and distribution require explicit owner authorization.
- [P] tasks touch different files and have no unfinished dependencies.
- Each story must be independently testable; do not hide a story behind another story's UI.
- Never claim tests ran when only source was generated; never copy real expense data/DB into tests, logs, Git or CI.
- If a technical gate (native cancellation recovery, backup/transfer exclusion, toolchain pin) cannot be proved, keep the outcome honest, block the affected acceptance, and escalate rather than weaken the specification.
