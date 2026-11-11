# US4 verification — Add expense from History with the right date

**Date**: 2026-11-11
**Task**: T028
**Method**: source-level review only. No Flutter/Dart SDK, build, emulator or physical-device run was possible on this machine.

## Scope

US4: start Add from History; prefill the selected day only while Day is active; default Week/Month and unrelated entries to today; return to History after a successful save; refresh the current view; keep out-of-view feedback neutral; preserve Feature 1 validation, duplicate-submit, pending-save cancellation and discard behavior.

## Source checks

| Check | Result | Evidence |
| --- | --- | --- |
| `EntryController` accepts optional `initialDate` | PASS (source) | `app/lib/features/record_expenses/application/entry_controller.dart:31` |
| Fresh draft and dirty baseline use the same initial date | PASS (source) | `entry_controller.dart:40` sets `_draft` then `_initial = _draft` |
| No static/global selected-day state | PASS (source) | `initialDate` is an instance constructor parameter; no global is introduced |
| `AddExpenseScreen` accepts optional `initialDate` and passes it to the controller | PASS (source) | `app/lib/features/record_expenses/presentation/add_expense_screen.dart:14`, `:46` |
| Successful save returns the saved `Expense` | PASS (source) | `add_expense_screen.dart:142` `Saved` case pops `expense` |
| Cancel/abandon returns `null` | PASS (source) | `add_expense_screen.dart:151`, `:198`, `:201` |
| Overview consumes `Expense?` and reloads only after a save | PASS (source) | `app/lib/features/record_expenses/presentation/overview_screen.dart:89` |
| History passes `initialDate` only for Day | PASS (source) | `app/lib/features/browse_history/presentation/history_screen.dart:84` |
| Week/Month and Overview default to today | PASS (source) | `initialDate` is null for Week/Month; `entry_controller.dart:40` falls back to `_clock()` |
| History refreshes the current selection after a save | PASS (source) | `history_screen.dart:99` |
| In-view save feedback is neutral and accurate | PASS (source) | `history_screen.dart:108`–`119` |
| Out-of-view save feedback does not imply inclusion | PASS (source) | same block uses `period.contains` and category-id comparison |
| Failed refresh is not reported as refreshed | PASS (source) | `history_screen.dart:108` requires a success status before the “refreshed” message |
| Current rows/totals remain correct for the actual selection | PASS (source) | refresh reloads the same period/filter; out-of-view rows are excluded by the query |
| Validation, duplicate-submit, pending-save and discard rules unchanged | PASS (source) | `add_expense_screen.dart` save/retry/back paths and `EntryController` save/retry/reconcile paths retain their existing logic |
| Future-dated creation remains rejected | PASS (source) | unchanged `EntryValidator` future-date rejection; History prefill does not weaken it |

## Not performed

- No Android emulator or physical-device inspection was run.
- No `flutter build apk --debug`, `flutter analyze` or `dart format` was run.
- No runtime Add trials were executed.

## Disposition

US4 source-level checks pass. Runtime Add/return acceptance remains unverified until the owner authorizes the build and device checks.
