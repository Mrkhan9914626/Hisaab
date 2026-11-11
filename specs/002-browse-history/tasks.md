# Tasks: Browse and filter spending history

**Input**: Design documents from `/specs/002-browse-history/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Delivery**: This project is source-code-only under Constitution v2.0.0. Automated test
authoring is NOT a completion gate. Correctness is established through source-level
review, a successful Android debug build, and named manual Android inspections. Existing
host/integration tests may be maintained opportunistically but are not acceptance gates
and MUST NOT be reported as run without evidence. iOS is legacy and out of scope.

**Deferred verification (owner decision 2026-11-10)**: The 10,000-record synthetic fixture
harness and the SC-002 performance/large-dataset trials are deferred. T031 and T033 are
marked DEFERRED, and the large-dataset portions of T029/T035 must be recorded as skipped.
Do not mark deferred work done or report it as passing. The remaining functional checks,
source review, build and small-fixture manual acceptance stay in scope.

**Organization**: Tasks are grouped by user story so each story can be implemented and
verified independently after the shared foundation is complete.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Every task names an exact file path.
- `history_screen.dart` is a shared integration file; its edits are sequential.

## Path Conventions

- Mobile app source: `app/lib/`
- Feature tests/support fixtures: `app/test/`, `app/integration_test/`
- Build configuration: root `codemagic.yaml`
- Verification evidence: `docs/verification/002-browse-history/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the Feature 1 baseline and create the new feature slice.

- [X] T001 Create `app/lib/features/browse_history/domain/`, `app/lib/features/browse_history/application/` and `app/lib/features/browse_history/presentation/`; confirm `app/pubspec.yaml` adds no package and `app/lib/core/storage/migrations.dart` keeps `user_version = 1`.
- [X] T002 [P] Record the unchanged baseline (Flutter pin, existing packages, schema v1, Android `minSdk 24`, no new dependency, iOS out of scope) in `docs/verification/002-browse-history/setup.md`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Civil-date arithmetic, immutable history values, read-only queries and the shared controller. No user story work starts until this phase is complete.

**⚠️ CRITICAL**: T012 must pass source review before any story phase begins.

- [X] T003 [P] Implement civil-date primitives in `app/lib/core/domain/calendar_range.dart`: `addDays`, `addMonthsClamped`, date comparison helpers, domain minimum `0001-01-01` and maximum `9999-12-31`, with no UTC instant or elapsed-duration arithmetic and no year-10000 construction.
- [X] T004 Implement period derivation and navigation in `app/lib/core/domain/calendar_range.dart`: period-for-anchor for `day`/`week`/`month`, Monday–Sunday week start/end, month first/last day, inclusive `contains`, previous/next period, earliest representable period, and later-of-period comparison.
- [X] T005 [P] Implement `HistoryRangeType`, `HistoryPeriodLabel` and `NavigationLimits` in `app/lib/features/browse_history/domain/history_range.dart`; labels remain presentation concerns and never change period identity.
- [X] T006 [P] Implement sealed `CategoryFilter` (`AllCategories` / `SelectedCategory(categoryId)`) in `app/lib/features/browse_history/domain/category_filter.dart`, including the rule that an unresolved selected id is a typed failure rather than an empty filter.
- [X] T007 [P] Implement `DateGroup`, `HistoryQuery`, `HistorySnapshot` and `HistoryStatus` in `app/lib/features/browse_history/domain/history_snapshot.dart`; derive groups, count, date subtotals and period total from one ordered row list using checked `BigInt` accumulation and `calculationOverflow` on signed-64-bit overflow.
- [X] T008 [P] Extend `app/lib/core/presentation/date_format.dart` with `formatPeriodLabel`, `formatDateGroupLabel`, `formatRangeLabel` and a current-period indicator; reuse `MoneyText` for all amounts and keep labels out of SQL and money arithmetic.
- [X] T009 Add `ExpenseRepository.listCategoriesForFilter()` in `app/lib/features/record_expenses/data/expense_repository.dart`; return every active and archived category in stable `rowid` order with `id`, `name`, `iconKey`, `isActive` and `isProtected`; a failure returns a typed `Failure`, never an empty list.
- [X] T010 Add `ExpenseRepository.loadHistory(HistoryQuery query)` in `app/lib/features/record_expenses/data/expense_repository.dart`; use one read transaction with joined expense/category rows, inclusive `expense_date >= start` and `<= end`, optional `category_id = ?`, `ORDER BY expense_date DESC, save_sequence DESC`, `EXISTS(SELECT 1 FROM expenses)` and `MAX(expense_date)`; perform no write, schema change or migration.
- [X] T011 Implement `HistoryController` in `app/lib/features/browse_history/application/history_controller.dart`: initialize to Day/today/All categories, load/refresh/retry, change range with current-period reset, previous/next one period with bounds, Go to today, select/clear filter, full status derivation (`loading`, `available`, `emptyPeriod`, `noFilterMatches`, `emptyEver`, `unavailable`, `stale`), stale snapshot retention, filter persistence, and no silent period move at midnight.
- [X] T012 Source-review `calendar_range.dart`, `loadHistory`, snapshot derivation and `HistoryController` against `data-model.md`, `contracts/history-operations.md` and `contracts/history-persistence.md`; record findings, including overflow and failure-path behavior, in `docs/verification/002-browse-history/source-review.md`.

**Checkpoint**: Foundation ready — period arithmetic, values, read-only queries and controller state are available to all stories.

---

## Phase 3: User Story 1 — Browse a period with trustworthy totals and grouped entries (Priority: P1) 🎯 MVP

**Goal**: Open History from Overview, browse Day/Week/Month periods with previous/next and readable labels, see exact period totals/counts with date-grouped rows and subtotals, and open read-only details.

**Independent Verification**: With controlled synthetic records on adjacent dates, weeks and months, verify that each period shows exactly its records, each date subtotal and the period total agree, previous/next move exactly one unit, range changes reset to the current period, and Back from details preserves the range/period.

### Implementation for User Story 1

- [X] T013 [P] [US1] Extract the shared `ExpenseListRow` widget into `app/lib/features/record_expenses/presentation/expense_list_row.dart` from the private row in `overview_screen.dart`, and reuse it in `app/lib/features/record_expenses/presentation/overview_screen.dart`.
- [X] T014 [P] [US1] Build `HistoryRangeControls` in `app/lib/features/browse_history/presentation/history_range_controls.dart` with labeled Day/Week/Month segmented controls, exposed selected state, labeled previous/next icon buttons with tooltips and exposed disabled state, and 48 dp touch targets.
- [X] T015 [US1] Build the base `HistoryScreen` in `app/lib/features/browse_history/presentation/history_screen.dart`: fresh Day/today selection, period label with current indicator, exact total/count card, virtualized flattened grouped list with date headers/subtotals and rows, row tap to the existing details screen, loading and available states, and state preservation on Back.
- [X] T016 [US1] Add one labeled History action to `app/lib/features/record_expenses/presentation/overview_screen.dart` that pushes `HistoryScreen` with the existing repository/coordinator; add no inert tabs, Edit, Delete, Categories or Settings controls.
- [X] T017 [US1] Verify US1 on Android/source: day/week/month inclusivity, Monday–Sunday weeks, leap day, month lengths, year boundaries and weeks spanning months/years; exactly-once rows/count/subtotals/total; previous/next exactly one unit; range-change reset; Go to today; row-to-details and Back state; record results in `docs/verification/002-browse-history/us1-verification.md`. (Source-level verification recorded; Android/device run not performed.)

**Checkpoint**: User Story 1 is independently functional and is the MVP.

---

## Phase 4: User Story 2 — Filter by category without breaking the totals (Priority: P1)

**Goal**: Filter a selected period by any active or archived category and have rows, count, subtotals and total narrow together; clear the filter to restore the full result.

**Independent Verification**: With records in multiple active and archived categories in one period, apply each filter and compare rows, date subtotals, count and total with the expected subset; clear and confirm the full result returns and the filter survives period navigation and detail round trips.

### Implementation for User Story 2

- [X] T018 [P] [US2] Build `HistoryFilterControl` in `app/lib/features/browse_history/presentation/history_filter_control.dart` with `All categories`, every active category, every archived category visibly marked archived, a visible active-filter description, a separate Clear filter action, and accessible labels/states that do not rely on color alone.
- [X] T019 [US2] Integrate filtering into `app/lib/features/browse_history/presentation/history_screen.dart` and `app/lib/features/browse_history/application/history_controller.dart`: selecting a category narrows rows/count/date subtotals/period total together; clearing restores the full result; the active filter persists across period navigation, range changes, app resume and detail/Add round trips.
- [X] T020 [US2] Verify US2: active and archived category filters, zero totals and clear-filter action for no matches, full-result restoration after clear, and filter persistence across navigation/range/details; record results in `docs/verification/002-browse-history/us2-verification.md`. (Source-level verification recorded; runtime/device trials not performed.)

**Checkpoint**: User Stories 1 and 2 work independently and together.

---

## Phase 5: User Story 3 — Understand empty periods and honest load failures (Priority: P2)

**Goal**: Distinguish empty period, no filter matches, no expenses ever, stale data and read failure with truthful totals and working actions.

**Independent Verification**: Exercise each of the five states with controlled fixtures and injected/induced read failures; confirm the copy, zero-or-unavailable totals, Go to today, Day-only Add, Clear filter and Retry actions are distinct and correct.

### Implementation for User Story 3

- [X] T021 [P] [US3] Build `HistoryStates` in `app/lib/features/browse_history/presentation/history_states.dart` with distinct bodies for `emptyPeriod`, `noFilterMatches`, `emptyEver`, `unavailable` and `stale`; use zero totals only for confirmed empty/no-match/no-expenses-ever results, and never for `unavailable` or `stale`.
- [X] T022 [US3] Integrate the state bodies into `app/lib/features/browse_history/presentation/history_screen.dart` with Go to today, Day-only Add for the selected day, Clear filter, Retry, and an explicit stale marker that retains prior values without presenting them as current; Retry preserves the selected range/period/filter.
- [X] T023 [US3] Verify US3: first-load failure with no zeros, refresh failure with retained stale values, successful Retry with preserved selection, empty period vs no-match vs no-expenses-ever distinctions, and midnight stability while History is open; record results in `docs/verification/002-browse-history/us3-verification.md`. (Source-level verification recorded; runtime failure injection/device trials not performed.)

**Checkpoint**: User Stories 1–3 are independently functional and failure-safe.

---

## Phase 6: User Story 4 — Start an expense from History with the right date (Priority: P2)

**Goal**: Start Add expense from History with the selected day pre-filled only while Day is active, return to History after a successful save, refresh results, and avoid implying an out-of-view entry belongs to the current result.

**Independent Verification**: Start Add from Day, Week and Month contexts; inspect the prefilled date. Save inside and outside the displayed period/filter; verify return destination, neutral success feedback, refreshed rows/count/totals, and that a later unrelated form defaults to today.

### Implementation for User Story 4

- [X] T024 [US4] Add optional `LocalDate? initialDate` to `EntryController` in `app/lib/features/record_expenses/application/entry_controller.dart`; a fresh draft uses `initialDate ?? clock()`, the initial dirty baseline uses the same date, and no static or global selected-day state is introduced.
- [X] T025 [US4] Add optional `LocalDate? initialDate` to `AddExpenseScreen` in `app/lib/features/record_expenses/presentation/add_expense_screen.dart` and pass it to `EntryController`; on success return the saved `Expense` instead of `true`, return `null` on cancel/abandon, and preserve validation, duplicate-submit, pending-save cancellation and discard rules unchanged.
- [X] T026 [US4] Update `OverviewScreen._openAdd` in `app/lib/features/record_expenses/presentation/overview_screen.dart` to consume the `Expense?` result and reload only when a save succeeded; preserve the existing no-date behavior.
- [X] T027 [US4] Add the Add-expense action to `app/lib/features/browse_history/presentation/history_screen.dart`: pass `initialDate` only when Day is active; omit it for Week/Month; on a saved `Expense`, refresh the current selection and show neutral success feedback that does not imply inclusion when the saved date or category is outside the current period/filter.
- [X] T028 [US4] Verify US4: Day prefill, Week/Month and unrelated later entries defaulting to today, in-view save refresh, out-of-view save feedback without false inclusion, and failure paths preserving form/retry/discard behavior; record results in `docs/verification/002-browse-history/us4-verification.md`. (Source-level verification recorded; runtime Add/device trials not performed.)

**Checkpoint**: All four user stories are independently functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility, privacy, performance, build and final acceptance evidence across all stories.

- [X] T029 [P] Inspect accessibility and layout in `app/lib/features/browse_history/presentation/` and the Overview shortcut: both light/dark themes, 200% text or the platform maximum, reduced motion, landscape, keyboard-open, safe areas, 48 dp targets, screen-reader labels/order, exposed selected/disabled states, non-color-only operation, and full scroll reachability for hundreds of grouped rows; record results in `docs/verification/002-browse-history/accessibility.md`. If the deferred T031 fixture is unavailable, record the hundreds-of-rows scroll check as skipped rather than passing a smaller list as equivalent. (Source-level review recorded; device checks and the hundreds-of-rows scroll check were not run/skipped.)
- [X] T030 [P] Review offline/privacy/scope in `app/lib/features/browse_history/` and the extended `app/lib/features/record_expenses/`: no network, account, telemetry, backup, export or new I/O; no logging of amounts, dates, notes, category names, identifiers or row contents; no excluded controls; no new dependency; no schema or migration change; record results in `docs/verification/002-browse-history/privacy-scope.md`. (Source-level review recorded.)
- [ ] T031 **DEFERRED (owner, 2026-11-10)** Prepare the synthetic verification fixture using `app/test/support/synthetic_fixtures.dart` in a disposable debug build: 10,000 expenses over 24 months, 500 dated today, adjacent day/week/month records, leap day/year transition, week spanning month/year, active and archived categories, repeated and maximum amounts, and a saved date later than the simulated current date; no production seed/reset/export screen. Do not implement or run for this delivery; record as deferred, not done or passed.
- [ ] T032 Run the existing `android-debug` lane in root `codemagic.yaml` with owner authorization: `flutter pub get`, `flutter build apk --debug`, and optionally `dart format --output=none --set-exit-if-changed .` and `flutter analyze`; record pass/fail/skipped and the exact build identity in `docs/verification/002-browse-history/build.md`; never report a skipped or failed lane as a pass. **NOT RUN — no local Flutter/Dart SDK; recorded as skipped, not passed.**
- [ ] T033 **DEFERRED (owner, 2026-11-10)** Run SC-002 performance trials on a 2020–2022 Android phone with 4 GB memory, ≥1 GB free storage, offline, using the T031 fixture; record 30 selected-period loads (≥29 within 2 s), 30 range/filter changes (≥29 within 500 ms) and 30 row-to-details selections (≥29 within 500 ms), including device/OS/build/fixture identity and skipped checks, in `docs/verification/002-browse-history/performance.md`. Blocked by the deferred T031 fixture; SC-002 remains unverified and must not be reported as run or passed.
- [ ] T034 Run the SC-001 task study with 10 people unfamiliar with the app, offline; record completion count, time, supplied data and physical/emulator disclosure in `docs/verification/002-browse-history/task-study.md`. Does not require the T031 10,000-record fixture; small synthetic data is sufficient. **NOT RUN.**
- [ ] T035 Run the remaining SC-003–SC-007 manual Android acceptance matrix from `quickstart.md`: boundary fixtures, 100+ filter trials, all empty/stale/failure states, selected-day/Week/Month/out-of-range Add trials, restart persistence, offline behavior, light/dark contrast, screen-reader labels/order, maximum text, reduced motion, keyboard, landscape and safe areas; record results and every skipped item in `docs/verification/002-browse-history/manual-acceptance.md`. Large-dataset and performance portions depending on the deferred T031 fixture must be recorded as deferred; run the remaining functional checks with small synthetic fixtures. **NOT RUN — all matrix items skipped; large-dataset item deferred with T031.**
- [X] T036 Perform the final constitution re-check and source review of exact money, civil-date boundaries, single-transaction reads, failure/stale semantics, privacy/scope and accessibility in all changed files; record the disposition, residual risks and skipped checks in `docs/verification/002-browse-history/final-review.md`; do not claim runtime evidence that was not observed. (Source-level review recorded; runtime evidence not observed.)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; start immediately.
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS all user stories.
- **User Stories (Phases 3–6)**: Depend on Foundational (T012 checkpoint).
  - US1 is the MVP and should be delivered first.
  - US2, US3 and US4 build on the History screen created in US1.
- **Polish (Phase 7)**: Depends on all desired implementation phases.

### Task Dependencies

- T002 after T001.
- T004 after T003.
- T009 and T010 share `expense_repository.dart`; do T009 then T010.
- T011 depends on T004–T010.
- T012 depends on T011.
- T013 and T014 can run in parallel after T012.
- T015 depends on T010, T013 and T014.
- T016 depends on T014 and follows T013 because both edit `overview_screen.dart`.
- T017 depends on T015 and T016.
- T018 depends on T006 and T009.
- T019 depends on T011, T015 and T018.
- T020 depends on T019.
- T021 depends on T007.
- T022 depends on T011, T015 and T021.
- T023 depends on T022.
- T024 has no story-internal dependency beyond the foundation.
- T025 depends on T024.
- T026 depends on T025.
- T027 depends on T011, T015, T024 and T025.
- T028 depends on T026 and T027.
- T029 and T030 depend on the UI/story tasks they inspect.
- T031 can start after the foundation but is needed by T033. T031 is deferred (owner, 2026-11-10).
- T032 depends on T017, T020, T023 and T028.
- T033 depends on T031 and T032. Because T031 is deferred, T033 is also deferred and SC-002 remains unverified.
- T034 and T035 depend on T032.
- T036 depends on T029–T035.

### User Story Dependencies

- **US1 (P1)**: Can start after T012. No dependency on other stories.
- **US2 (P1)**: Can start after T012 and T015; integrates with US1's History screen.
- **US3 (P2)**: Can start after T012 and T015; integrates with US1's History screen.
- **US4 (P2)**: Can start after T012 and T015; touches Feature 1 Add/Overview plus the History screen.

### Within Each User Story

- Reusable widgets before screen integration.
- Controller/domain behavior before presentation wiring.
- Source review and manual Android verification after the story's implementation tasks.
- Story complete before moving to the next priority unless staffed in parallel.

### Parallel Opportunities

- Setup: T002 can run alongside T001 once directories exist.
- Foundational: T003, T005, T006, T007 and T008 touch different files and can run in parallel; T004 follows T003; T009/T010 are sequential; T011 and T012 follow.
- US1: T013 and T014 can run in parallel; T015 then T016/T017.
- US2: T018 can be built while US1 screen work is finishing; T019 follows.
- US3: T021 can be built while US1 screen work is finishing; T022 follows.
- US4: T024 then T025; T027 follows the screen integration.
- Polish: T029, T030 and T031 can run in parallel; T032 then T033–T036.

---

## Parallel Example: User Story 1

```text
Task T013 [US1]: Extract shared ExpenseListRow in
  app/lib/features/record_expenses/presentation/expense_list_row.dart
Task T014 [US1]: Build HistoryRangeControls in
  app/lib/features/browse_history/presentation/history_range_controls.dart
```

## Parallel Example: User Story 2

```text
Task T018 [US2]: Build HistoryFilterControl in
  app/lib/features/browse_history/presentation/history_filter_control.dart
```

## Parallel Example: User Story 3

```text
Task T021 [US3]: Build HistoryStates in
  app/lib/features/browse_history/presentation/history_states.dart
```

## Parallel Example: User Story 4

```text
Task T024 [US4]: Add optional initialDate to EntryController in
  app/lib/features/record_expenses/application/entry_controller.dart
Task T025 [US4]: Add optional initialDate and Expense result to AddExpenseScreen in
  app/lib/features/record_expenses/presentation/add_expense_screen.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational (T003–T012) and pass the T012 source review.
3. Complete Phase 3: User Story 1 (T013–T017).
4. **STOP and VALIDATE**: run the US1 manual Android checks against synthetic fixtures.
5. Demo the working Day/Week/Month browsing flow if the build is available.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. Add US1 → verify → deliver the MVP.
3. Add US2 → verify category filtering → deliver.
4. Add US3 → verify honest empty/failure states → deliver.
5. Add US4 → verify selected-day Add integration → deliver.
6. Complete Polish: accessibility, privacy/scope, build and final acceptance evidence. The performance/large-dataset evidence (T031/T033 and dependent checks) is deferred by owner decision and recorded as skipped.

### Parallel Team Strategy

After T012:

- Developer A owns US1 (screen, range controls, Overview shortcut).
- Developer B can build the standalone US2 filter control and US3 state widgets while US1 screen work proceeds.
- Developer C can extend `EntryController` for US4 once the foundation is stable.
- Screen integration tasks T015, T019, T022 and T027 all edit `history_screen.dart`; schedule them sequentially to avoid conflicts.
- Overview edits T013, T016 and T026 are sequential for the same reason.

---

## Notes

- [P] tasks touch different files and have no dependency on incomplete tasks.
- [Story] labels map every story-phase task to US1–US4 for traceability.
- Automated test authoring is not required under Constitution v2.0.0; source review, an
  Android build and named manual checks are the acceptance evidence.
- Verification evidence belongs under `docs/verification/002-browse-history/` and must
  disclose skipped checks and whether a physical device or emulator was used.
- Never enter real financial data into disposable builds; use only synthetic fixtures.
- Commit after each task or logical group; do not commit evidence that was not observed.
- T031/T033 and the large-dataset portions of T029/T035 are deferred by owner decision (2026-11-10). Record them as skipped/deferred; never mark them done or passing. SC-002 remains unverified until the deferred work is authorized.
- Any target change to SC-002 or scope requires an explicit owner-approved specification amendment.
