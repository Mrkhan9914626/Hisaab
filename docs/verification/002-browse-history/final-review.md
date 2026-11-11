# Final review and constitution re-check — 002-browse-history

**Date**: 2026-11-11
**Task**: T036
**Method**: source-level review only. No Flutter/Dart SDK, build, emulator, device, runtime test, task study or performance trial was run.

## Disposition

**Source-complete; acceptance evidence incomplete.**

The implementation and source-level reviews are complete. The feature cannot be reported as fully accepted because the Android debug build (T032), manual matrix (T035), SC-001 study (T034), and the deferred fixture/performance work (T031/T033) were not run. SC-002 is explicitly deferred; SC-001 and SC-003–SC-007 remain unverified at runtime.

## Constitution re-check

| Area | Finding | Status |
| --- | --- | --- |
| Exact money | Totals use `BigInt` accumulation and `Money`; no floating `total()`; signed-64-bit overflow maps to `calculationOverflow` | PASS (source) |
| Civil dates | `calendar_range.dart` uses civil dates, Monday–Sunday weeks, inclusive boundaries, domain limits `0001-01-01`..`9999-12-31`, no UTC instant/elapsed-duration math, no year-10000 construction | PASS (source) |
| Single-transaction reads | `loadHistory` uses one `readTransaction` for rows, `hasAnyExpenses` and `MAX(expense_date)`; no write statement | PASS (source) |
| Failure/stale semantics | failures never render zero as confirmed-empty; stale retains prior snapshot and is explicitly marked; first-load failure shows unavailable + Retry | PASS (source) |
| Privacy/offline/scope | no network/account/telemetry/backup/export; no financial-field logging; no new dependency; no schema/migration change; no excluded controls | PASS (source) |
| Accessibility | theme-sourced colors, scrollable layouts, labeled controls, selected/disabled states, 48 dp targets, non-color-only actions; contrast and screen-reader behavior not measured | PASS (source design); device checks NOT RUN |
| Read-only History | repository history paths are `rawQuery` only; no edit/delete/category lifecycle | PASS (source) |
| Existing behavior preserved | Add validation, duplicate-submit, pending-save cancellation, discard rules and Overview no-date behavior retain their logic; Add now returns `Expense` and the one caller/test was updated | PASS (source) |

## Changed-file review

- `app/lib/core/domain/calendar_range.dart` — civil-date primitives and period derivation.
- `app/lib/core/presentation/date_format.dart` — period/group/range labels and current indicator.
- `app/lib/features/browse_history/domain/` — range/filter/snapshot values.
- `app/lib/features/browse_history/application/history_controller.dart` — selection/filter/navigation/load; category retry recovery.
- `app/lib/features/browse_history/presentation/` — screen, range controls, filter control, state bodies.
- `app/lib/features/record_expenses/data/expense_repository.dart` — `listCategoriesForFilter`, `loadHistory`.
- `app/lib/features/record_expenses/presentation/expense_list_row.dart` — shared row.
- `app/lib/features/record_expenses/presentation/overview_screen.dart` — History action and `Expense?` result handling.
- `app/lib/features/record_expenses/presentation/add_expense_screen.dart` — `initialDate`, `Expense` result.
- `app/lib/features/record_expenses/application/entry_controller.dart` — `initialDate`.
- `app/test/presentation/add_expense_save_test.dart` — updated to `push<Expense>`.

## Residual risks

1. **No analyzer/build evidence.** Syntax was checked with a bracket-balance script only; type errors, import errors, lints, SQL alias mistakes and widget issues could remain. `flutter analyze` and the Android debug build were not run.
2. **No runtime behavior evidence.** Date boundary, filter, state, failure, Add round-trip and navigation behavior were reviewed in source, not observed.
3. **No accessibility evidence.** Contrast ratios were not measured; TalkBack order, 200% text, landscape, keyboard and safe areas were not inspected on a device.
4. **SC-002 unverified.** The 10,000-record fixture and timing trials are deferred.
5. **SC-001 unverified.** No task study was run.
6. **Test not run.** The updated widget test was not executed because no Flutter SDK is available.
7. **Generation guard.** A superseded `load()` returns without clearing `_loading`; the newer load owns the state, but this relies on every superseding path completing normally. No runtime test exercised overlapping loads.
8. **Unused accessor.** `HistoryController.activeFilterCategory` is currently unused; harmless, but it should be removed if the filter UI does not adopt it.

## Skipped checks

- T031 fixture: deferred.
- T032 `android-debug` build/analyze/format: not run.
- T033 SC-002 trials: deferred.
- T034 SC-001 task study: not run.
- T035 manual matrix: all items skipped; item 25 deferred with T031.
- T029 device accessibility checks and hundreds-of-rows scroll: not run/deferred.
- Automated tests: not run.

## Required next evidence

1. Authorized `android-debug` lane: `flutter pub get`, `flutter build apk --debug`, optionally `dart format --output=none --set-exit-if-changed .` and `flutter analyze`.
2. Small-fixture manual matrix on an emulator or physical device, with device/emulator disclosure.
3. SC-001 study with 10 unfamiliar participants, offline.
4. When authorized: T031 fixture and T033 SC-002 trials.

Until those exist, report the feature as **source-complete, acceptance-pending**, not as passing.
