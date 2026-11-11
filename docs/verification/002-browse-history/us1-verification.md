# US1 verification — browse periods, totals and grouped entries

**Date**: 2026-11-11
**Task**: T017
**Method**: source-level review only. No Flutter/Dart SDK, build, emulator or physical-device run was possible on this machine.

## Scope

US1: open History from Overview, browse Day/Week/Month periods, move exactly one period at a time, see the current-period marker, exact totals/counts, date-grouped rows with subtotals, and open read-only details with Back preserving the selection.

## Source checks

| Check | Result | Evidence |
| --- | --- | --- |
| Overview exposes one labeled History action | PASS (source) | `app/lib/features/record_expenses/presentation/overview_screen.dart:136` |
| History opens with Day/today/All categories | PASS (source) | `app/lib/features/browse_history/application/history_controller.dart:76`; `app/lib/features/browse_history/presentation/history_screen.dart:41` |
| Day/Week/Month controls are labeled and expose selection | PASS (source) | `app/lib/features/browse_history/presentation/history_range_controls.dart:32` |
| Readable period label and current-period marker | PASS (source) | `app/lib/features/browse_history/presentation/history_screen.dart:174`; `app/lib/core/presentation/date_format.dart:40` |
| Previous/next move exactly one period and expose disabled bounds | PASS (source) | `app/lib/features/browse_history/application/history_controller.dart:93`; `app/lib/features/browse_history/domain/history_range.dart:69`; `history_range_controls.dart:62` |
| Range change resets to the current period and keeps the filter | PASS (source) | `history_controller.dart:84` |
| Go to today selects the current period and keeps the filter | PASS (source) | `history_controller.dart:117`; `history_screen.dart:128`; empty-period action in `history_states.dart:31` |
| Monday–Sunday weeks, inclusive civil-date boundaries | PASS (source) | `app/lib/core/domain/calendar_range.dart:14`; `app/lib/features/browse_history/domain/history_range.dart:31`; `history_snapshot.dart`/SQL use `>=` and `<=` |
| Leap day, month lengths, year boundaries, weeks spanning months/years | PASS (source) | `calendar_range.dart:22`, `:71`, `:84`; `LocalDate.daysInMonth`; no year-10000 construction |
| Day/Week/Month inclusivity and no year-10000 construction | PASS (source) | `calendar_range.dart:22`; `history_range.dart:39`; `history_range.dart:43` |
| Exact total and count for the selected period | PASS (source) | `app/lib/features/browse_history/domain/history_snapshot.dart:71`; `history_screen.dart` summary card |
| Rows grouped by date, newest date first, newest-saved first | PASS (source) | SQL order in `app/lib/features/record_expenses/data/expense_repository.dart:319`; group walk in `history_snapshot.dart:105` |
| Each date group shows a readable date label and subtotal | PASS (source) | `history_screen.dart` `_DateGroupHeader`; `date_format.dart:22` |
| Every row appears exactly once | PASS (source) | one joined row query per transaction; `history_snapshot.dart:105` walks that list once |
| Displayed total equals the sum of displayed rows and date subtotals | PASS (source) | same row list supplies groups, subtotals, count and total in `history_snapshot.dart:71` |
| Row opens existing read-only details | PASS (source) | `history_screen.dart:70` pushes `ExpenseDetailsScreen`; details has no mutation path |
| Back from details preserves range, period and filter | PASS (source) | controller lives on `HistoryScreen`; details push/pop does not recreate it |
| Loading state is explicit and does not show zero totals | PASS (source) | `history_screen.dart:225` loading sliver; summary hidden while loading |
| Virtualized grouped list | PASS (source) | `history_screen.dart` `_HistoryList` uses `SliverList` with `SliverChildBuilderDelegate` |

## Not performed

- No Android emulator or physical-device inspection was run.
- No `flutter build apk --debug`, `flutter analyze` or `dart format` was run.
- The 10,000-record fixture and SC-002 timing checks are deferred (T031/T033).

## Disposition

US1 source-level checks pass. Runtime and Android acceptance remain unverified until the owner authorizes the build and device checks.
