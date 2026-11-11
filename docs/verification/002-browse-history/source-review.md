# Foundation source review — 002-browse-history

**Date**: 2026-11-10
**Task**: T012
**Scope**: `calendar_range.dart`, history domain values, `loadHistory`, snapshot derivation and `HistoryController`
**Method**: source-level review against `data-model.md`, `contracts/history-operations.md` and `contracts/history-persistence.md`. No runtime, SDK, database or device command was executed.

## Reviewed files

- `app/lib/core/domain/calendar_range.dart`
- `app/lib/features/browse_history/domain/history_range.dart`
- `app/lib/features/browse_history/domain/category_filter.dart`
- `app/lib/features/browse_history/domain/history_snapshot.dart`
- `app/lib/features/record_expenses/data/expense_repository.dart` (`listCategoriesForFilter`, `loadHistory`)
- `app/lib/features/browse_history/application/history_controller.dart`

## Findings

| Check | Result | Notes |
| --- | --- | --- |
| Civil dates only; no UTC instant or elapsed duration | PASS | `CalendarRange` uses Gregorian day/month/year arithmetic and a days-from-civil weekday helper. No `DateTime.add` or UTC conversion. |
| Monday–Sunday weeks | PASS | `weekStart` subtracts `weekday - 1`; `HistoryPeriod.forAnchor(week)` ends six days later and clamps to the domain end. |
| Inclusive boundaries | PASS | `HistoryPeriod.contains` uses `!before(start) && !after(end)`; SQL uses `>=` / `<=`. |
| Leap day, month lengths, year boundaries | PASS | Uses `LocalDate.daysInMonth`; day/month navigation clamps and returns `null` outside `0001-01-01`–`9999-12-31`. |
| No year-10000 construction | PASS | `addDays`, `addMonthsClamped` and week-end derivation return `null` at the domain edge; month-end uses the last valid day. |
| One read transaction | PASS | `loadHistory` performs the joined row query, `EXISTS` and `MAX(expense_date)` inside one `database.transaction`. |
| Read-only | PASS | `loadHistory` and `listCategoriesForFilter` contain only `rawQuery`; no insert, update, delete, pragma write or schema statement. |
| Ordering | PASS | `ORDER BY e.expense_date DESC, e.save_sequence DESC`. |
| Optional category predicate | PASS | `SelectedCategory` appends `AND e.category_id = ?` with a bound argument. |
| Derived count/subtotals/total | PASS | `HistorySnapshot.derive` walks the returned rows once; no separate `COUNT` or `SUM` supplies a displayed value. |
| Checked arithmetic / overflow | PASS | Group subtotals and period total accumulate as `BigInt`, are range-checked against signed 64-bit and map to `calculationOverflow`. |
| Failure semantics | PASS | First-load failure → `unavailable`; refresh failure with a prior snapshot → `stale`; no zero-filled fallback. |
| Empty-state precedence | PASS | `emptyEver` → `noFilterMatches` (active filter) → `emptyPeriod` → `available`. |
| Navigation bounds | PASS | `NavigationLimits` uses the later of the current period and the latest saved-expense period; earliest is the period containing `0001-01-01`. |
| Range change reset | PASS | `changeRange` replaces the anchor with the current period of the new range and preserves the filter. |
| Filter persistence | PASS | Filter lives on the controller and is only changed by `selectFilter`/`clearFilter`; navigation and refresh keep it. |
| Unresolved selected id | PASS | `HistoryController.load` maps an unresolved selected id to `integrityFailure` instead of an empty result. |
| Midnight stability | PASS | No midnight timer; the controller only moves the selection on explicit navigation, range change or Go to today. Reopening History creates a fresh controller at the current day. |
| Category list failure | PASS | `listCategoriesForFilter` returns a typed `Failure`, never an empty list; `initialize` shows `unavailable` instead of "no categories". |
| Amounts/notes/dates in logs | PASS | No logging of stored values; failures carry only non-sensitive codes. |

## Residual risks / not verified

- No analyzer, formatter, build or device run was possible locally. Dart syntax and type correctness were reviewed manually.
- SQLite index usage, transaction behavior and timing were not measured; the deferred SC-002 evidence remains outstanding.
- The 10,000-record fixture and performance trials are deferred by owner decision (T031/T033).
