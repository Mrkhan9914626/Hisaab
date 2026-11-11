# Implementation Plan: Browse and filter spending history

**Branch**: `002-browse-history` | **Date**: 2026-11-09 | **Spec**: [spec.md](spec.md)  
**Input**: Feature specification from `/specs/002-browse-history/spec.md`  
**Status**: Technical design complete; no application source, build or device check was executed by this planning step. The 10,000-record fixture harness and SC-002 performance/large-dataset trials are deferred by owner decision on 2026-11-10 (see Increment E).

## Summary

Add the second offline Android slice: open History from Overview, browse Day/Week/Month periods with previous/next navigation and readable labels, see exact PKR period totals and counts with date-grouped rows and date subtotals, filter by any active or archived category, distinguish empty-period/no-match/no-expenses-ever/read-failure states, and start Add expense with the selected day pre-filled only while Day is active.

The technology stack is **identical to Feature 1**: Flutter with its bundled Dart, SQLite through `sqflite`, Codemagic cloud builds, Android 7.0 / API 24 minimum, integer-paisa money, civil-date storage, one repository/database owner, SDK `ChangeNotifier`/`Navigator` and constructor injection. No new package, ORM, router, state-management library, backend, analytics or telemetry is introduced. Feature 2 adds read-only history queries to the existing repository, pure calendar-range values, a History controller/screen, an Overview-to-History shortcut, and an optional `initialDate` on the existing Add-expense form. The SQLite schema stays at `user_version = 1`; no migration is needed because history only reads existing indexed records.

## Technical Context

**Language/Version**: Dart bundled with the Feature 1 candidate pin Flutter `3.47.8`; no standalone Dart override. The actual Dart patch, dependency resolution and cloud-runner compatibility remain the same bootstrap/lockfile gate recorded for Feature 1.  
**Primary Dependencies**: Same as Feature 1 — Flutter SDK; `sqflite 2.4.5`, `characters 1.4.1`, `uuid 4.6.0`; development-only `sqflite_common_ffi 2.4.5`, `flutter_test`, `integration_test` and `flutter_lints 5.0.0`. No new production dependency. SDK `ChangeNotifier`, `Navigator` and constructor injection only; no ORM, router, calendar, formatting or state-management package.  
**Storage**: Same app-private SQLite store, schema v1, integer paisa, canonical `YYYY-MM-DD` civil dates, `save_sequence` ordering, existing `(expense_date, save_sequence DESC)` index, one repository/database owner and protected no-backup directory. History is read-only and performs no schema change, migration, seed or mutation.  
**Testing**: Automated test authoring is NOT REQUIRED under Constitution V. Verification is source-level review, a successful Android debug build, and named manual Android inspections. Existing host/integration tests may be maintained opportunistically but are not acceptance gates and must not be claimed as run without evidence.  
**Target Platform**: Android 7.0 / API 24 and later only, per Constitution v2.0.0. iOS is legacy and out of scope; the Flutter/Dart/SQLite/Codemagic stack itself is unchanged from Feature 1.  
**Project Type**: Mobile application in `app/`, reusing the Feature 1 platform project, storage policy and recording contracts. Documentation stays at repository root.  
**Performance Goals (binding acceptance targets from SC-002)**: On a 2020–2022 Android phone with 4 GB memory, ≥1 GB free storage, offline, over 10,000 saved expenses across 24 months with 500 dated today: ≥29/30 selected-period loads show correct grouped rows, count and total within 2 seconds; ≥29/30 range-type or category-filter changes show correct results within 500 ms; ≥29/30 history-row selections show correct details within 500 ms. The fixture harness and timing evidence are deferred by owner decision (2026-11-10); these targets remain unverified until that work is authorized.  
**Constraints**: Fully offline; no network, account, telemetry or financial logging. PKR-only exact arithmetic with at most two fractional digits; no floating money. Local civil-date boundaries: Day inclusive, Week Monday–Sunday inclusive, Month first–last day inclusive; non-overlapping periods; no UTC instant conversion. Forward navigation stops at the later of the current period or the latest saved-expense period, so device-clock rollback cannot hide saved history, while creating new future-dated expenses stays unavailable. Backward navigation stops at the earliest representable civil date. History never mutates expenses or categories.  
**Scale/Scope**: One person/device; four user stories and 26 acceptance scenarios; FR-001–FR-023 and SC-001–SC-007. Adds one working History screen (plus Overview shortcut and Add-expense date initializer) on top of the existing Overview/Add/details routes. Excludes edit/delete, category lifecycle, Settings/appearance, charts, income, budgets, accounts, cloud and backup.  
**Unresolved clarifications**: None. The device-clock-rollback forward-navigation question was resolved in the specification on 2026-11-09.

## Constitution Check

*GATE: evaluated before Phase 0 research and re-checked after Phase 1 design.*

| Principle | Status | Evidence / boundary |
| --- | --- | --- |
| I. Offline-first privacy | PASS | History adds no network, account or telemetry path; it reads the existing app-private no-backup SQLite store and logs no amounts, dates, notes, category names or identifiers. FR-001, FR-023; persistence contract. Backup/transfer runtime evidence remains the Feature 1 release gate. |
| II. Exact money and history | PASS | Integer paisa only; one read transaction supplies rows, count, date subtotals and total from the same record set; inclusive local civil-date boundaries with explicit Monday–Sunday weeks; checked integer aggregation and typed overflow. FR-005–FR-011; research §2–§4. |
| III. Durable storage | PASS | Read-only history; no schema change or migration; successful saves remain durable and visible after restart; failed reads become an explicit unavailable/stale state, never zero or an empty-period message; archived categories stay readable and filterable; no delete/reset path. FR-008, FR-016, FR-018–FR-019; persistence contract. |
| IV. Accessible Android interaction | PASS | Android-only approved direction; labeled Day/Week/Month controls, visible active filter and clear action, exposed selected states, 48 dp targets, 4.5:1/3:1 contrast, system text scaling, reduced motion, keyboard/safe-area handling, Back preservation and non-color-only operation. FR-002–FR-003, FR-007–FR-009, FR-021; quickstart inspection matrix. |
| V. Minimal scope and source-code focus | PASS | Reuses the owner-approved Flutter/Dart/SQLite/Codemagic stack with no new dependency; no excluded V1 feature or inert control is added; no iOS work, backend or automated-test gate is introduced; unsupported defaults are not inherited from visual mockups. FR-020, FR-023; complexity tracking. |

No constitutional exception is requested or granted. A PASS means the obligation is designed into the plan, not that runtime or device evidence exists.

## Project Structure

### Documentation (this feature)

```text
specs/002-browse-history/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── checklists/requirements.md      # created by /sp.specify
└── contracts/
    ├── history-operations.md
    └── history-persistence.md
```

`tasks.md` belongs to the later `/sp.tasks` command and is not created here.

### Source Code (repository root)

```text
app/lib/
├── app.dart                                 # unchanged entry composition
├── main.dart                                # unchanged bootstrap
├── core/
│   ├── domain/
│   │   ├── app_failure.dart                 # reused typed failures
│   │   ├── local_date.dart                  # reused validated civil date
│   │   ├── calendar_range.dart              # NEW pure day/week/month arithmetic
│   │   └── money.dart                       # reused exact PKR value
│   ├── presentation/
│   │   ├── app_theme.dart                   # reused light/dark tokens
│   │   ├── category_icon.dart               # reused offline icon mapping
│   │   ├── date_format.dart                 # EXTENDED period/group labels
│   │   ├── money_text.dart                  # reused exact formatting
│   │   └── storage_notice.dart              # reused device-only notice
│   └── storage/                             # reused; no schema change
│       ├── app_database.dart
│       ├── local_storage_policy.dart
│       └── migrations.dart
└── features/
    ├── record_expenses/                     # Feature 1 contracts, extended only as noted
    │   ├── domain/{category,expense,entry_draft,entry_validator,overview_snapshot,submission}.dart
    │   ├── data/expense_repository.dart     # EXTENDED with read-only history queries
    │   ├── application/entry_controller.dart# EXTENDED with optional initial date
    │   └── presentation/
    │       ├── overview_screen.dart         # EXTENDED with labeled History shortcut
    │       ├── add_expense_screen.dart      # EXTENDED with optional initial date
    │       ├── expense_details_screen.dart  # reused unchanged
    │       ├── expense_list_row.dart        # NEW shared row extracted from Overview
    │       └── discard_dialog.dart          # reused unchanged
    └── browse_history/                      # NEW feature slice
        ├── domain/
        │   ├── history_range.dart           # range type, period and navigation limits
        │   ├── category_filter.dart         # All categories vs one selected category
        │   └── history_snapshot.dart        # date groups, snapshot and status
        ├── application/history_controller.dart
        └── presentation/
            ├── history_screen.dart
            ├── history_range_controls.dart
            ├── history_filter_control.dart
            └── history_states.dart          # empty/no-match/error/stale bodies
```

Verification evidence, when actually produced, belongs in `docs/verification/002-browse-history/`.

**Structure Decision**: One mobile project and one feature-cohesive history slice. `browse_history` consumes the Feature 1 `Expense`/`Category` contracts and the single `ExpenseRepository`; it does not open a second database connection, define a second money/date model, or mutate recording data. The repository gains read-only history methods so all rows, counts, subtotals and totals come from one transaction. `calendar_range.dart` stays pure and independent of widgets/SQL. Presentation owns labels, grouping widgets and state rendering; the controller owns selection/filter/navigation state. No new dependency, service or route family beyond the working History screen.

## Phase 0 — Research decisions

Complete: [research.md](research.md). It reuses the approved Feature 1 stack and resolves the history-specific questions: civil-date period arithmetic, Monday–Sunday weeks, single-snapshot reads, exact totals/overflow, forward/backward navigation limits, archived-category filtering, Add-expense prefill ownership, and large-list accessibility/performance. Candidate toolchain pins and cloud-runner compatibility remain the same explicit verification gates as Feature 1; no build was performed.

### Selected approach

- Pure `HistoryRangeType` (`day`, `week`, `month`) plus a `HistoryPeriod` derived from an anchor civil date through `calendar_range.dart`; the week is Monday–Sunday and month boundaries are first/last day, with no elapsed-time arithmetic.
- One serialized read transaction returns the selected period's rows (already joined to current category metadata), an any-history existence flag, and the latest saved expense date. Rows are ordered `expense_date DESC, save_sequence DESC`; groups, subtotals and the period total are derived in pure Dart from exactly those rows with checked 64-bit accumulation.
- `HistoryController` holds the range type, anchor date, category filter, loaded snapshot, available filter categories and failure state. Range change and Go to today select the current period of the active range; filter survives navigation and detail round trips.
- Navigation bounds are computed from the store, not the clock alone: the latest reachable period is the later of the current period and the period containing the latest saved expense; the earliest reachable period is the period containing `0001-01-01`.
- Navigation: Overview gains one labeled History action that pushes the History screen. The History screen pushes the existing details screen and the existing Add-expense screen. Add receives an `initialDate` only from a Day selection; Week/Month and unrelated new entries keep today.
- Presentation reuses the existing theme, exact money formatting, category icons and storage notice. Range/filter controls are labeled, 48 dp, screen-reader exposed and not color-only. The grouped list virtualizes rows while keeping every record reachable.

## Phase 1 — Data design and contracts

Complete: [data-model.md](data-model.md), [history operation contracts](contracts/history-operations.md), [history persistence contract](contracts/history-persistence.md), [quickstart.md](quickstart.md).

### Data flow

Overview opens → user activates History → controller initializes selection to today/Day and `All categories` → repository loads categories for the filter and performs one read transaction for the current period → snapshot derives date groups, subtotals, count and total from the returned rows → screen renders loading/available/empty period/no filter matches/no expenses ever/unavailable/stale according to the snapshot and store facts.

Range change → selection resets to the current period of the new range and the filter is preserved → reload. Previous/next → move exactly one period, bounded by the earliest representable period and the latest reachable period, then reload. Filter change/clear → same period, narrowed or restored rows and totals → reload. Go to today → current period, filter preserved → reload.

Row tap → existing read-only details route. Back returns to the same controller state (range, period, filter). Add expense → existing form with `initialDate` only for Day; on success the form returns the saved `Expense`; History refreshes and shows neutral success feedback, explicitly not implying inclusion when the saved date/category falls outside the current period/filter.

Read failure → retain any prior snapshot only as explicitly stale/unavailable with Retry; a first-load failure shows an actionable error, never zero totals. Retry reuses the same selection and filter.

### Presentation and accessibility boundary

Reuse the approved light/dark tokens, Material icons and system fonts offline. Render the range controls as labeled segmented buttons with an explicit selected state; previous/next are labeled icon buttons with tooltips. The filter is a labeled dropdown/menu containing `All categories`, active categories and archived categories visibly marked archived; the active filter is text-visible and has a separate Clear filter action. Date groups show a readable local date label and subtotal; rows show category icon, note-or-category fallback, category label and PKR amount. Empty, no-match, empty-ever, stale and error states are visually and textually distinct, use zero totals only for confirmed empty results, and always expose their action. Large text, landscape, keyboard, reduced motion and safe areas must not hide any essential control; every selected-period row remains scroll-reachable.

### Native and storage boundary

No new platform channel, permission, asset, backup rule or schema migration. History uses the Feature 1 protected SQLite location and the existing serialized repository. Reads are transaction-scoped and side-effect free; a read failure leaves stored data unchanged. Diagnostics stay non-sensitive. Backup/transfer behavior and native persistence evidence remain the Feature 1 release gate and are not implied by this read-only feature.

## Phase 2 — Implementation sequencing and validation strategy

Phase-level decomposition only; `/sp.tasks` owns the executable checkbox list. Automated tests are not a constitutional gate. Each increment ends in source review and, where SDK/cloud access is authorized, a successful Android debug build plus the named manual Android inspection.

### Increment A — Pure calendar periods and history values

**Files**: `app/lib/core/domain/calendar_range.dart`; `app/lib/features/browse_history/domain/{history_range,category_filter,history_snapshot}.dart`; extensions to `app/lib/core/presentation/date_format.dart`.

- [ ] Implement pure civil-date arithmetic: add/subtract days, add months with clamping, Monday week start/end, month start/end, period-for-anchor, period previous/next, inclusive containment, earliest representable period and comparison of anchors. Handle leap days, month lengths, year boundaries, weeks spanning months/years and the `0001-01-01`–`9999-12-31` domain without constructing year 10000.
- [ ] Implement immutable selection/period/filter/snapshot values and group derivation from an already-ordered row list. Preserve exactly-once membership and stable ordering.
- [ ] Implement readable Day/Week/Month/date-group labels with a separate current-period indicator; keep formatting out of SQL and money calculations.
- [ ] Source-review the calendar logic against the specification's boundary examples before wiring storage.

### Increment B — Read-only history queries

**Files**: `app/lib/features/record_expenses/data/expense_repository.dart` (read-only extension); optionally `app/lib/features/browse_history/data/history_read_types.dart` if DTO placement needs isolating.

- [ ] Add `listCategoriesForFilter()` returning all active and archived categories in stable seed/row order with name, icon and active flag; failure is a typed storage error, not an empty list.
- [ ] Add one read transaction that returns the selected period's joined expense rows filtered by optional category id, `EXISTS` any-history and `MAX(expense_date)`; order by `expense_date DESC, save_sequence DESC`; use inclusive civil-date string comparisons; never mutate rows.
- [ ] Derive count, date groups, date subtotals and total only from the returned rows using checked integer accumulation; map signed-64-bit overflow to `calculationOverflow`; never use floating `total()` or separate aggregates that could disagree.
- [ ] Verify the existing `(expense_date, save_sequence DESC)` index serves range reads; do not add a schema index or bump `user_version` unless a measured need is documented and a preserving migration is reviewed.
- [ ] Review failure behavior: storage unavailable/incompatible/integrity failures surface typed failures; no zero-filled fallback and no data reset.

### Increment C — History controller and navigation

**Files**: `app/lib/features/browse_history/application/history_controller.dart`.

- [ ] Implement fresh-open selection: current local day with Day range and `All categories`.
- [ ] Implement range change resetting to the current period of the new range while preserving the filter; previous/next moving exactly one period; backward bound at the earliest representable period; forward bound at the later of the current period and the latest saved-expense period.
- [ ] Implement Go to today (current period for the active range, filter preserved), filter selection/clearing, load/refresh, and app-resume refresh. A midnight while open does not move the selection; reopening History starts at the current day.
- [ ] Implement status derivation and stale handling: `emptyEver`, `emptyPeriod`, `noFilterMatches`, `available`, first-load `unavailable`, and retained `stale`; never convert a failure into zero totals.
- [ ] Preserve selection and filter across details and Add round trips; disable previous/next at their bounds with exposed disabled state.

### Increment D — History presentation and integration

**Files**: `app/lib/features/browse_history/presentation/*`; `app/lib/features/record_expenses/presentation/{overview_screen,add_expense_screen,expense_list_row}.dart`; `app/lib/features/record_expenses/application/entry_controller.dart`.

- [ ] Add a labeled History action on Overview that pushes the working History screen; do not add inert tabs or excluded controls.
- [ ] Build range controls, period label, total/count card, filter control with archived options and clear action, date-group headers with subtotals, and reusable history rows that open the existing details screen. Preserve state on Back.
- [ ] Build the five distinct result states with truthful copy: empty period (zero totals, Go to today, Day-only add action), no filter matches (zero totals, clear filter), no expenses ever (invite first expense, zero totals), unavailable (Retry, no zeros), stale (retained values explicitly marked, Retry).
- [ ] Extend Add expense with an optional `initialDate` used only by a Day-context History action; Week/Month and later unrelated forms use today. Change the save result to return the saved expense so History can refresh and give neutral out-of-view feedback. Preserve the recording feature's validation, duplicate-submit, cancellation, dirty-discard and error rules unchanged.
- [ ] Verify 48 dp targets, labels/states for screen readers, contrast, text scaling to the platform maximum, reduced motion, landscape, keyboard/safe areas, both themes, and full scroll reachability for hundreds of grouped entries.

### Increment E — Build and manual acceptance evidence

**Files**: `docs/verification/002-browse-history/` when evidence is produced; root `codemagic.yaml` reuse (no new workflow required).

- [ ] Run the existing `android-debug` cloud lane only with owner authorization; require dependency resolution and `flutter build apk --debug` success. A skipped or failed lane remains visible and is not reported as a pass.
- [ ] On an authorized emulator or physical device, manually exercise Day/Week/Month boundaries, leap day, year boundary, week spanning months/years, previous/next limits, range-change reset, Go to today, filter/clear with archived fixtures, empty period, no-match, no-expenses-ever, stale and read-failure states, restart persistence, and detail/Add round trips.
- [ ] Run the SC-002 timing trials on a representative 2020–2022/4 GB Android device with synthetic 10,000-record/500-today fixtures; record device, OS, build identity, fixture version, results and skipped checks. Do not invent evidence and do not use real financial data.
- [ ] Complete the SC-007 accessibility/layout inspection matrix and disclose whether evidence came from a physical device or emulator. Browser-prototype behavior is not acceptance evidence.

**Deferred verification — owner decision 2026-11-10**: The 10,000-record synthetic fixture harness, the SC-002 timing trials, and the large-dataset checks that depend on that fixture are deferred. T033 and the large-dataset portions of T029/T035 MUST be recorded as skipped or deferred, never as passing. The remaining functional checks (SC-003–SC-007 on small synthetic fixtures), the SC-001 task study, source review, and the Android build remain in scope. This is a disclosed acceptance gap, not a constitutional waiver; the feature MUST NOT be reported as fully meeting SC-002 until the deferred evidence exists.

### Acceptance traceability

| Spec requirement(s) | Planned implementation | Required evidence |
| --- | --- | --- |
| FR-001, FR-020 | D Overview shortcut, History/details/Add routes | Working offline journeys; no inert controls |
| FR-002–FR-004 | A periods, C controller, D controls | Fresh Day default; labels; exact prev/next moves; range-change reset |
| FR-005–FR-006, FR-011 | A grouping, B single-snapshot read, D rendering | Matching rows/count/subtotals/total; newest-first ordering; exact extremes/overflow |
| FR-007 | D rows/details, state retention | Row opens read-only details; Back preserves range/period/filter |
| FR-008–FR-009 | B filter categories, C filter state, D control | Active+archived filters; visible active filter; clear restores; persists |
| FR-010 | A calendar ranges, B query boundaries | Inclusive day/Monday–Sunday/month; adjacent periods excluded; timezone/clock independence |
| FR-012–FR-014 | C statuses, D state bodies | Four distinct states with correct copy/actions/zero-vs-unavailable |
| FR-015 | C Go to today | Current period for active range; filter preserved |
| FR-016 | B typed failures, C stale/unavailable, D Retry | No zero-filled failure, no reset, retained values marked stale |
| FR-017 | D Add integration, C refresh | Day-only prefill; Week/Month/unrelated today; neutral out-of-view success |
| FR-018–FR-019 | Reused shared contracts; read-only queries | No mutation; archived metadata readable; restart/refresh reflects durable records |
| FR-021 | D accessible controls/states, E inspection | Labels, states, contrast, 48 dp, scaling, reduced motion, Back, safe areas |
| FR-022 | A/B/D virtualization and indexed reads | SC-002 timings; every selected record scroll-reachable |
| FR-023 | Reused private storage; no new I/O | Offline source review; no sensitive logs/telemetry |
| SC-001–SC-007 | A–E | Task study, timing trials, boundary/filter fixtures, state matrix, accessibility evidence |

Every acceptance scenario in Stories 1–4 and the Edge Cases maps to Increments A–E. `/sp.tasks` must turn these groups into concrete tasks and named manual checks rather than treating this table as evidence.

## Post-design Constitution Check

| Principle | Design result | Evidence still required before affected completion/release |
| --- | --- | --- |
| I. Privacy | PASS design | Source review confirms no new I/O; Feature 1 backup/transfer gate remains open and is not waived. |
| II. Exactness | PASS design | A/B review of civil-date boundaries, single-record-set derivation, integer overflow and stable ordering. |
| III. Durability | PASS design | Read-only SQL review; manual restart/refresh and failure-state checks; no migration added. |
| IV. Accessibility | PASS design | D/E inspection matrix on Android; disclose physical vs emulator evidence. |
| V. Scope/stack | PASS design | Reuses Feature 1 pins and has no new dependency; confirm no excluded controls or iOS work. |

No gate is silently waived. The deferred performance/scale evidence is disclosed rather than waived (see Increment E). The plan is ready for task decomposition, not a claim that runtime, build or device evidence exists.

## Complexity Tracking

| Design responsibility | Why needed | Simpler alternative rejected because |
| --- | --- | --- |
| Read-only history methods on the existing repository | One database owner and one read transaction for consistent rows/count/subtotals/total | A second history connection or separate aggregate queries can disagree and complicate the serialized storage contract |
| Pure `calendar_range.dart` separate from UI/SQL | Explicit Monday–Sunday/week/month rules, navigation bounds and leap/month/year-boundary review | Doing date math inside widgets or SQL strings hides boundary errors and prevents independent review |
| `HistoryController` holding selection/filter state | Range resets, bounds, filter persistence and stale/failure transitions must survive navigation | Screen-local state loses the active filter/period across details and Add round trips |
| Optional Add-expense `initialDate` | Selected-day prefill without a stale global date | A shared "last day" value leaks into Week/Month or unrelated later entries |
| Extracted shared row widget | Overview and History must render the same row contract | Duplicating row rendering invites divergent labels, icons or amounts |

No new service, backend, ORM, router, calendar package, schema migration or constitutional exception is introduced. Backups, signing and release authorization remain owner/Feature 1 gates and are outside this plan.
