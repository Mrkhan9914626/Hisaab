# Implementation Plan: Record expenses and see current spending

**Branch**: `001-record-expenses` | **Date**: 2026-11-04 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/001-record-expenses/spec.md`  
**Status**: Technical design complete; implementation, cloud setup and native validation not executed.

## Summary

Build the first offline recording slice for Android and iPhone: default categories, exact PKR entry, durable duplicate-safe/cancellable saves, today's Overview/current-month total, read-only details, safe forms and honest storage errors/disclosures. The owner approved Flutter/Dart/SQLite/Codemagic and Android API 24 / iOS 15. Development is source-first on Windows with no local SDK requirement; a one-time cloud bootstrap creates complete platform projects, and Codemagic runs failing-first tests, analysis and APK builds. GitHub push, account setup and build execution require separate execution authorization.

Use pure Dart money/date/validation types, Flutter SDK presentation/controllers, one sqflite repository and a single save coordinator. Submission UUIDs supply exact-once retry identity; a pending cancellation is not confirmed until no writer can later persist. Native storage adapters enforce private no-backup paths. No server, authentication, analytics, background retry queue or unimplemented navigation controls.

**For implementers:** Read this plan and [spec.md](spec.md) together. `/sp.tasks` will produce the executable checkbox task list; this `/sp.plan` intentionally does not create tasks.md or application source.

## Technical Context

**Language/Version**: Dart bundled with candidate Flutter 3.47.8; capture actual Dart patch with flutter --version --machine during cloud bootstrap and lock the verified compatible pair before implementation. No standalone Dart override.  
**Primary Dependencies**: Flutter SDK; candidate sqflite 2.4.5, characters 1.4.1, uuid 4.6.0; development-only sqflite_common_ffi 2.4.5, flutter_test and integration_test. Dependency graph/licenses/toolchain compatibility must be verified and locked during bootstrap. SDK ChangeNotifier/Navigator and constructor injection; no ORM/router/state package.  
**Storage**: SQLite schema v1 in protected device-private excluded-from-backup directory; integer paisa, validated civil dates, atomic writes and preserving migrations; one database owner/serialized coordinator.  
**Testing**: Cloud Flutter pure-domain/widget tests, file-backed SQLite FFI tests, native Android integration and iOS simulator integration, external process-restart driver and physical-device/manual acceptance. Codemagic reports retain assertion-level red/green evidence.  
**Target Platform**: Android 7.0/API 24 minimum and iOS 15 minimum, explicitly owner-approved option A; Android APK initial build artifact with iOS source/testing retained. Not web/desktop production.  
**Project Type**: Mobile application in app/ with Android/iOS platform projects; existing Spec Kit documentation remains at repository root.  
**Performance Goals (binding acceptance targets)**: 10,000 records/24 months including 500 today on 2020–2022 4-GB phones, ≥1 GB free; ≥29/30 launches ≤2 s, durable saves + refresh ≤1 s, details ≤500 ms, saving feedback ≤100 ms. Preserve all rows and exact totals, including 999999999000000 paisa maximum fixture sum.  
**Constraints**: Offline first launch; app-private device-only financial data and assets; zero sensitive telemetry/logs; backup/transfer conflict blocks release; no local Flutter/Android SDK; future dates rejected; optional notes ≤200 grapheme clusters; per-expense PKR 0.01–999,999,999.00.  
**Scale/Scope**: One person/device, six initial categories, three working routes (Overview/Add/read-only details), four stories/32 acceptance scenarios, 22 FRs and seven outcomes; retention unbounded by the 10,000-record acceptance fixture. Full V1 still requires four later features.

## Constitution Check

### Pre-research gate

| Principle | Status | Evidence / boundary |
| --- | --- | --- |
| I. Offline-first privacy | PASS for research | Specification requires no remote financial flow; research explicitly includes backup/transfer controls, offline assets and non-sensitive diagnostics. Native verification is not claimed. |
| II. Exact money/history | PASS | Owner-approved bounds/date/note rules, integer arithmetic and today/month civil-date ranges; week/filter journeys outside this feature. |
| III. Durable storage | PASS for design | Atomic persistence, failure safety, category IDs and confirmed cancellation captured in spec. Adapter recovery is an explicit feasibility test, not assumed reliable. |
| IV. Accessible mobile interaction | PASS for design | Approved visual direction, themes/contrast/targets/text/screen-reader/keyboard/discard requirements carry forward. |
| V. Test-first verification | PASS for design | Cloud-first red/green evidence and native/manual lanes planned; local SDK absence does not waive tests. |
| VI. Minimal scope/decisions | PASS | Owner approved stack and API24/iOS15 before any scaffolding. No V1 exclusions introduced; dependency need/license review and alternatives in research. |

No constitutional exception has been requested or granted. PASS for a design means the obligation is planned, not that runtime evidence exists.

## Project Structure

### Documentation (this feature)

```text
specs/001-record-expenses/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md
└── contracts/
    ├── local-operations.md
    └── persistence.md
```

`tasks.md` belongs to the subsequent `/sp.tasks` command. Architecture decisions must be recorded through `/sp.adr` before consequential implementation; research.md already contains Decision/Rationale/Alternatives so the decisions are not lost.

### Source Code (planned, not created)

```text
codemagic.yaml
CLAUDE.md
app/
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── domain/{money,local_date,app_failure}.dart
│   │   ├── storage/{local_storage_policy,app_database,migrations}.dart
│   │   └── presentation/{app_theme,money_text,storage_notice}.dart
│   └── features/record_expenses/
│       ├── domain/{expense,category,entry_draft,submission,overview_snapshot,entry_validator}.dart
│       ├── data/expense_repository.dart
│       ├── application/{entry_controller,overview_controller,save_coordinator}.dart
│       └── presentation/{overview_screen,add_expense_screen,expense_details_screen,discard_dialog}.dart
├── android/       # complete generated Gradle wrapper/project + reviewed Kotlin storage bridge
├── ios/           # complete generated Xcode/Runner project + reviewed Swift storage bridge
├── test/
│   ├── domain/{money,local_date,entry_validator}_test.dart
│   ├── data/{schema,expense_repository,migration,recovery}_test.dart
│   ├── application/{save_coordinator,entry_controller,overview_controller}_test.dart
│   └── presentation/{overview,add_expense,details,accessibility}_test.dart
└── integration_test/{record_expense,pending_cancellation,storage_policy,reopen}_test.dart
docs/
├── build-toolchain.md
└── verification/001-record-expenses/  # evidence only after actual tests
```

**Structure Decision**: One mobile project, feature-cohesive code with small shared value/storage/presentation foundations. Money/date logic has no widget/SQL dependency; repository does not navigate; coordinator owns submission lifecycle; screens do not own connections. `app/` avoids clobbering this documentation repository during generation. Paths in braces describe individual planned files, not generated directories.

## Phase 0 — Research decisions

Complete: [research.md](research.md). It resolves the cloud-only environment, stack/OS choices, candidate pins, exact storage, cooperative cancellation/reconciliation, privacy controls, test lanes and alternatives. Candidate toolchain compatibility, native cancellation recovery and backup/transfer behavior have explicit proof obligations, not unanswered product questions. No run was performed merely because documentation describes a command.

### Selected architecture

- Flutter SDK widgets, system-theme light/dark, Navigator for three working routes; no placeholder tabs/settings.
- Value parsing/formatting is exact and pure; 200-character notes use grapheme segmentation. Explicit category selection and stable built-in IDs.
- SQLite repository owns creation, schema versioning, constraints, active-category checks, coherent snapshots and details.
- Save coordinator owns immutable UUID payload, cancellation checkpoints, terminal commit observation and clean-boundary reconciliation; controller manages form validation/dirty state, focus and safe navigation.
- Native method channel configures the financial directory before SQLite opens. Android noBackupFilesDir + backup XML/manifest restrictions; iOS protected excluded Application Support. Treat sidecars as financial data. No remote analytics or assets.
- Default schema uses DELETE journal/EXTRA sync; verify effective pragmas. A timeout never cancels SQL or proves absence. If locked-plugin clean recovery cannot be demonstrated, keep outcome unavailable and block that behavior's acceptance until an adapter revision is reviewed.

## Phase 1 — Data design and contracts

Complete: [data-model.md](data-model.md), [local operation contracts](contracts/local-operations.md), [persistence contract](contracts/persistence.md), [quickstart.md](quickstart.md).

### Data flow

Overview initializes protected storage/schema → loads one coherent snapshot → entry captures fresh default today/no category → pure validator returns values/field errors → coordinator freezes submission UUID → repository checks matching ID/active category and inserts transactionally → observed commit produces Saved → return to Overview and refresh. Details load by public UUID with current category metadata. Empty-ever vs empty-today requires a successful any-history query. A failed load is never zero spending.

Cancellation while pending offers cancellation, never ordinary discard. If queued, retire safely; if writing, request rollback at the final checkpoint. Commit winning means Saved. Uncertain outcome retains visible draft and same immutable payload and offers checking retry, without another write. Only confirmed absence after draining/recovering the original execution permits Cancelled/KnownUnsaved.

### Presentation and native boundary

Bundle Material icons/system font fallbacks; optional approved fonts must be licensed and packaged offline. Define explicit light/dark tokens from approved direction, enforce platform hit areas and semantic labels, text scaling/reduced motion, field error focus/summary, keyboard scrolling/safe areas, and focus-safe confirmations. A 200-character note remains available in details even if the Overview preview wraps/truncates visually; the saved text is not truncated.

Native privacy bridge returns a verified private directory or a privacy failure. The iOS reference could not be fully retrieved and another request was interrupted; exact exclusion/transfer semantics require implementation-time official SDK review and native evidence. No attempt is made to turn inaccessible documentation into an assumed guarantee.

### Cloud workflow topology

1. Manual `bootstrap-source` (macOS): generate complete fresh app outside repository tree; return restricted source archive for owner review/import; no auto-push and no normal-build regeneration. Permanent organization/app identifiers are required owner setup inputs before execution, not invented values.
2. `android-checks-debug` (verified Linux): locked pub get, format, analyze, domain/widget/FFI tests, debug APK. Tests must fail the lane when failing. No signing secrets, real financial data or DB artifacts.
3. `android-native-tests`: verified emulator/runner with bounded boot readiness; native plugin/recovery and external kill/reopen tests. Account/emulator unavailability blocks this evidence, not substituted by host tests.
4. `ios-unsigned` / `ios-simulator-tests` (verified macOS/Xcode): unsigned compile and explicit native tests, clearly differentiated. Neither is physical iPhone distribution evidence.
5. Later manually authorized trusted-branch release signing: stable Android key; Apple distribution credentials if required. No automatic store publication. Debug cloud signing is disposable and must not carry irreplaceable history.

## Phase 2 — Implementation sequencing and validation strategy

This is phase-level decomposition, not a replacement for `/sp.tasks`. Each behavior cycle is: write a meaningful failing assertion → run in Codemagic and retain red evidence → minimum implementation → same test/regression green → review → owner-authorized commit/push. SDK-generated scaffold alone is not feature behavior. Never run local Flutter commands and claim results when SDKs are absent.

### Increment A — Reproducible project and exact domain

**Files:** root codemagic.yaml, app/pubspec.yaml/lock and generated Android/iOS source; app/lib/core/domain/{money,local_date,app_failure}.dart; app/lib/features/record_expenses/domain/{entry_draft,entry_validator,submission,expense,category,overview_snapshot}.dart; corresponding domain tests.

- [ ] Generate/import complete source through approved cloud bootstrap; pin/record Flutter/Dart/JDK/Gradle/Xcode/images and dependency licenses; enforce API24/iOS15; no behavior copied from prototype.
- [ ] Before domain behavior, run assertion-level failing tests for 0.01/max/over-max/0/negative/precision/huge inputs, exact 0.10+0.20, grouping, civil date/month/leap/timezone and 200/201 grapheme notes/dirty equality.
- [ ] Implement typed values and validation; run focused `flutter test test/domain` then full host suite. First host build must validate the injected FFI native library is available.

### Increment B — Protected durable repository

**Files:** core/storage/{local_storage_policy,app_database,migrations}.dart; feature data/expense_repository.dart; generated Android MainActivity storage-channel code/manifest/res/xml and iOS Runner storage-channel/Info.plist configuration; test/data and integration_test/storage_policy_test.dart.

- [ ] Write failing file-backed schema/constraint/seed/active-category/Other/no-reseed and close-reopen tests; privacy bridge failure must not fall back to an unsafe path.
- [ ] Implement schema v1, exact integer/date storage, same-ID payload comparison, monotonic sequence, snapshot/detail reads, typed read/write/init/overflow failures and no-reset behavior.
- [ ] Test creation failure rollback, unsupported newer schema, corrupt/unavailable file and 10,000-record exact sums. No artificial v2 ships; require real v1→v2 preservation fixtures before any future format upgrade.
- [ ] Run native storage/reopen/foreign-key/pragmas tests on both platforms; host FFI success alone cannot close this increment's native gate.

### Increment C — Save lifecycle and cancellation

**Files:** application/save_coordinator.dart and entry_controller.dart; test/application/save_coordinator_test.dart; test/data/recovery_test.dart; integration_test/pending_cancellation_test.dart.

- [ ] Write deterministic failing race tests at queue, insert, final cancellation check, native commit response and recovery boundaries: repeated taps, retry same UUID, different UUID equal purchase, mismatched payload, cancel-before-write, rollback-wins, commit-wins, lost acknowledgement and unknown outcome.
- [ ] Implement the shared coordinator and typed outcomes in contracts; await actual work and preserve identity; no route-owned Future cancellation, automatic new submission or compensating deletion.
- [ ] Demonstrate clean-boundary recovery with the locked mobile plugin. If it cannot be proved, do not mark the feature complete; preserve OutcomeUnavailable, review an adapter change, and rerun tests. This is a technical feasibility gate, not a waived requirement.
- [ ] Prove no late record appears after confirmed cancellation, including reopen and process interruption; confirmed successful saves survive 100 termination/restart trials under synthetic fixtures.

### Increment D — Usable accessible recording slice

**Files:** app/main.dart/app.dart, core/presentation, feature presentation screens/dialog and overview_controller.dart; presentation/controller tests; integration_test/record_expense_test.dart.

- [ ] Write widget tests for fresh first-use/no-recovery notice, empty today with history, populated/stale/error Overview, amount/category/date/note errors and focus, safe unchanged/dirty leave, pending cancellation status, Saved plus refresh failure and read-only details.
- [ ] Implement only Overview/Add/details routes, success/error feedback and current local-day/month refresh. Block unavailable/inert feature controls; keep device theme and offline assets.
- [ ] Run full native journeys with 500 today rows accessible and exact month/today sets. Test both themes/orientations, screen-reader labels/order, 200%/maximum system text, reduced motion, touch targets, keyboard and safe areas; no essential action hidden.

### Increment E — Cloud artifacts and acceptance evidence

**Files:** codemagic.yaml, docs/build-toolchain.md, docs/verification/001-record-expenses/acceptance.md and synthetic fixture generation/test drivers.

- [ ] Enforce host checks before APK, native lane statuses, restricted artifacts and no signing secrets on PR builds. A compile failure or skipped lane must remain visible and cannot count as a pass.
- [ ] Execute SC-002 physical timings on representative 2020–2022/4-GB devices (candidate Pixel 4a and iPhone 12; record actual device/OS). Run 30 trials for launch/save/details/feedback, 100 save/restarts, and 10-person usability/disclosure studies.
- [ ] Inspect Android merged manifest/backup rules/noBackup directory and iOS file flags/entitlements; use synthetic backups/D2D/Quick Start tests and inspect financial files/sidecars. An unresolved off-device path or missing platform evidence blocks release.
- [ ] Before real financial use, authorize stable signing and install/upgrade preservation tests. Never uninstall to resolve a signature conflict without explicit owner acknowledgement of unrecoverable data loss. Later features must pass final integrated V1 journeys before release.

### Acceptance traceability

| Spec requirement(s) | Planned implementation | Required evidence |
| --- | --- | --- |
| FR-001 | A/B/D/E offline assets and native workflows | Story 1–4 core journeys offline on both platforms; no runtime dependency on CI/network |
| FR-002, FR-021 | B stable categories/invariants | Story 3.3, Story 4.6; seed/Other/archived fixture tests, no lifecycle UI |
| FR-003–009 | A validator/value types, D form | Story 4.1, 4.8–12; money/date/note/explicit-category tests and huge/overflow inputs |
| FR-010–011 | B/C transaction/coordinator | Story 1.1–7, Story 4.2, 4.13–15; identity/commit/cancel/restart/race tests |
| FR-012 | B snapshot, D Overview lifecycle | Story 2.1, 2.4–6 and earlier-date scenarios; coherent rows/count/sums and local rollover |
| FR-013 | B detail read, D read-only route | Story 2.2–3 and Story 4.7; missing/read error, note fallback, stable Back |
| FR-014–015 | B typed read result, D states | Story 3.1/4, Story 4.3/6/7, post-save refresh failure edge case |
| FR-016 | C pending cancellation, D discard dialog | Story 4.4–5 and 4.13–15; dirty/unchanged/focus/cancel race |
| FR-017–018 | B privacy adapters/config, D copy, E inspection | Story 3.2; no recovery comprehension, backup/transfer and sensitive-log/network checks |
| FR-019 | D theme/components/forms | Native/manual contrast/targets/text/semantics/keyboard/safe-area evidence |
| FR-020 | B migration lifecycle | No-reset/retention/reopen/unsupported-version tests; real upgrade fixture whenever schema changes |
| FR-022 | D route registry | Only working three routes, no simulated History/Categories/Settings/Edit/Delete |
| SC-001, SC-007 | D/E | Ten unfamiliar people, ≥9 entry+detail within 30 s and ≥9 correct no-recovery explanation; zero financial transfers/sensitive logs |
| SC-002, SC-003 | A/B/D/E | 10,000 fixtures/500 today, 30 timings/device, exact totals/date invariants; fixture volume not retention cap |
| SC-004, SC-005 | B/C/E | 100 successful-save restarts; failure/cancellation tests no false feedback, reset, partial row or duplicate |
| SC-006 | D/E | Both native platforms offline and full accessibility/layout inspection matrix |

Every numbered scenario from Stories 1 (1–7), 2 (1–6), 3 (1–4), and 4 (1–15) is covered above. All Edge Cases also map to A/B/C/D/E tests. `/sp.tasks` must assign individual test paths and tests-before-code dependencies, rather than treat this grouped table as test execution evidence.

## Post-design Constitution Check

| Principle | Design result | Evidence still required before affected completion/release |
| --- | --- | --- |
| I. Privacy | PASS design; runtime gate pending | research §7, native storage/persistence contracts, B/E. Verify Android/iOS backup and transfer; any unresolved conflict blocks release. |
| II. Exactness | PASS design | data-model + A/B; integer parsing/SQL sums, coherent snapshot, stable civil dates and typed overflow. |
| III. Durability | PASS design; native recovery gate pending | persistence contract + B/C; terminal commit, clean recovery and no-late-write proof, restart and migration evidence. |
| IV. Accessibility | PASS design | D/E, approved screen direction and FR-019 inspection matrix. |
| V. Test-first | PASS design | A–E red/green cloud evidence, native vs FFI distinction, physical timings and honest skipped checks. |
| VI. Scope/decisions | PASS | User stack/OS approval recorded; no extra production flow. ADRs before architecture implementation; exact toolchain/package graph verified at bootstrap. |

No blocked policy is silently waived. The plan is ready for task decomposition, not a declaration that runtime gates have passed. If technical verification contradicts required privacy/durability behavior, stop affected execution and report it before changing scope or implementation contracts.

## Complexity Tracking

| Design responsibility | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| One repository + save coordinator | Exactly-once ID, atomicity, pending cancellation/reconciliation | Widgets calling SQL directly cannot safely own work after navigation or distinguish uncertain commit. |
| Narrow Kotlin/Swift storage bridge | Native private/no-backup path and flags before write | Default path/plugin storage alone does not establish device-only policy. |
| Separate host/native/manual lanes | No local SDK, real plugin differences, physical/privacy evidence | A single APK build or FFI suite cannot prove platform persistence/accessibility/transfer behavior. |
| One-time cloud scaffold export | Complete reviewed native projects without local SDK | Source-only app or per-build regeneration is incomplete/unsafe. |

No additional service, background job, ORM, cloud financial store or constitutional exception is introduced. Stable signing/account/identifier setup is deliberately excluded from automatic execution and remains owner-controlled.
