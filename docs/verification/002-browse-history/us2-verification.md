# US2 verification — category filtering without breaking totals

**Date**: 2026-11-11
**Task**: T020
**Method**: source-level review only. No Flutter/Dart SDK, build, emulator or physical-device run was possible on this machine.

## Scope

US2: filter the selected period by any active or archived category; rows, count, date subtotals and total narrow together; clear restores the full result; the filter survives navigation, range changes, resume and detail/Add round trips.

## Source checks

| Check | Result | Evidence |
| --- | --- | --- |
| Filter lists All categories plus every active and archived category | PASS (source) | `app/lib/features/record_expenses/data/expense_repository.dart:126`; `app/lib/features/browse_history/presentation/history_filter_control.dart:44` |
| Archived categories are visibly marked | PASS (source) | `history_filter_control.dart:53` |
| Selecting a category narrows rows, count, subtotals and total together | PASS (source) | `expense_repository.dart:313` adds `AND e.category_id = ?`; `history_snapshot.dart:71` derives all displayed values from those rows |
| Clearing restores the full period result | PASS (source) | `app/lib/features/browse_history/application/history_controller.dart:130`; `history_filter_control.dart:63` |
| Active filter is visible and separately clearable | PASS (source) | `history_filter_control.dart:72`; no color-only indication |
| Filter persists across previous/next and range changes | PASS (source) | `history_controller.dart:84`, `:93`, `:105` change range/anchor only; `_filter` is untouched |
| Filter persists across app resume | PASS (source) | `history_screen.dart:56` calls `refresh`; `refresh` does not change `_filter` |
| Filter persists across details and Add round trips | PASS (source) | `history_screen.dart:70` and `:81`; the controller is not recreated |
| No-match state shows zero totals and a Clear filter action | PASS (source) | `history_snapshot.dart:137`; `app/lib/features/browse_history/presentation/history_states.dart:39` |
| Archived category with saved rows remains filterable after restart | PASS (source) | categories are read from the store, not filtered by `is_active`; the filter query uses only `category_id` |
| Archived category with no rows is not an error | PASS (source) | it yields `noFilterMatches`, not a failure |
| Unresolved selected id is a typed failure, not an empty result | PASS (source) | `history_controller.dart:169` resolves against loaded categories and maps `null` to `integrityFailure` |
| No archiving/restoration/rename/reassignment/deletion | PASS (source) | repository filter paths use only `rawQuery`; no mutation statement |

## Not performed

- No Android emulator or physical-device inspection was run.
- No `flutter build apk --debug`, `flutter analyze` or `dart format` was run.
- The 100+ filter-trial acceptance matrix (SC-004) was not run; it is part of the unrun manual matrix.

## Disposition

US2 source-level checks pass. Runtime filter trials remain unverified until the owner authorizes the build and device checks.
