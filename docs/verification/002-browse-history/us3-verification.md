# US3 verification — empty periods and honest load failures

**Date**: 2026-11-11
**Task**: T023
**Method**: source-level review only. No Flutter/Dart SDK, build, emulator or physical-device run was possible on this machine.

## Scope

US3: distinguish empty period, no filter matches, no expenses ever, unavailable and stale states; show truthful totals; offer Go to today, Day-only Add, Clear filter and Retry; preserve the selection on Retry; keep the selection stable across local midnight.

## Source checks

| Check | Result | Evidence |
| --- | --- | --- |
| Status derivation matches the contract | PASS (source) | `app/lib/features/browse_history/domain/history_snapshot.dart:134`; `app/lib/features/browse_history/application/history_controller.dart:189` |
| `emptyEver` takes precedence over filter/period emptiness | PASS (source) | `history_snapshot.dart:135` |
| Empty period shows zero totals, Go to today and Day-only Add | PASS (source) | `history_snapshot.dart:139`; `history_screen.dart:258`; `app/lib/features/browse_history/presentation/history_states.dart:15` |
| No filter matches shows zero totals and Clear filter | PASS (source) | `history_snapshot.dart:137`; `history_states.dart:39` |
| No expenses ever shows the first-expense invitation, not unavailability | PASS (source) | `history_snapshot.dart:135`; `history_states.dart:57` |
| First-load failure shows unavailable and Retry, never zero totals | PASS (source) | `history_controller.dart:194`; `history_screen.dart:206` hides the summary; `history_states.dart:73` |
| Refresh failure with a prior snapshot retains values and marks them stale | PASS (source) | `history_controller.dart:196`; `history_screen.dart:198` stale banner above the retained summary/list |
| Stale summary labels the retained snapshot's own period/filter | PASS (source) | `history_screen.dart:212-216` uses `snapshot.period.rangeType` and `snapshot.filter`, not the newly selected values |
| Stale banner is explicit and offers Retry | PASS (source) | `history_states.dart:138`; `history_screen.dart:198` |
| Retry preserves range, period and filter | PASS (source) | `history_controller.dart:140` reuses `_rangeType`, `_anchor`, `_filter` |
| Retry re-reads categories if the first category load failed | PASS (source) | `history_controller.dart:151` reloads categories when `_categories` is empty |
| No zero-filled snapshot on failure | PASS (source) | failure branches never replace `_snapshot`; `history_snapshot.dart:71` only returns a snapshot on success |
| No reset/replacement of saved data | PASS (source) | read-only repository paths; no write statement |
| Midnight while History is open does not move the selection | PASS (source) | no midnight timer in `HistoryController`; only explicit navigation/range/Go to today changes `_anchor` |
| Reopening History starts at the current day | PASS (source) | `history_screen.dart:41` creates a new controller; `history_controller.dart:76` initializes Day/today |
| Go to today preserves the active filter | PASS (source) | `history_controller.dart:117` changes only `_anchor` |
| All five states have distinct copy and actions | PASS (source) | `history_states.dart:15`, `:39`, `:57`, `:73`, `:138` |

**Stale presentation note**: `stale` is implemented as the distinct `HistoryStaleBanner` in
`history_states.dart:138` rather than a full-page `HistoryStates` body. This keeps the last
loaded summary and rows visible while marking them as not current, which satisfies the
requirement that stale values are retained but not presented as fresh.

## Not performed

- No Android emulator or physical-device inspection was run.
- No controlled read-failure injection was executed at runtime; the failure paths were reviewed in source.
- No `flutter build apk --debug`, `flutter analyze` or `dart format` was run.

## Disposition

US3 source-level checks pass. Runtime state/failure acceptance remains unverified until the owner authorizes the build and device checks.
