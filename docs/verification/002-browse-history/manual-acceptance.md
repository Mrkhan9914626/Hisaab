# Manual Android acceptance matrix — 002-browse-history

**Date**: 2026-11-11
**Task**: T035
**Status**: **NOT RUN — all items skipped**

## Environment disclosure

- No physical Android device was used.
- No emulator was used.
- No debug APK was built or installed.
- No synthetic fixture was loaded into a running app.
- Source-level reviews are recorded separately in `us1-verification.md`, `us2-verification.md`, `us3-verification.md`, `us4-verification.md` and `accessibility.md`; they are not a substitute for this matrix.

## Matrix result

| # | Quickstart item | Result | Reason |
| --- | --- | --- | --- |
| 1 | Open History from Overview; current day/Day/All categories | SKIPPED | no build/device |
| 2 | Day/Week/Month labels, totals, exclusions, exactly-once | SKIPPED | no build/device/fixture |
| 3 | Previous/next move exactly one unit | SKIPPED | no build/device |
| 4 | Backward navigation stops at the earliest period | SKIPPED | no build/device |
| 5 | Clock rollback; forward navigation reaches later saved dates; Add rejects future | SKIPPED | no build/device/fixture |
| 6 | Month → Week and other range changes select the current period | SKIPPED | no build/device |
| 7 | Go to today selects current period and preserves filter | SKIPPED | no build/device |
| 8 | Midnight does not move the open selection; reopen starts at today | SKIPPED | no build/device |
| 9 | Active-category filter narrows rows/count/subtotals/total | SKIPPED | no build/device/fixture |
| 10 | Archived-category history remains visible/filterable | SKIPPED | no build/device/fixture |
| 11 | Clear filter restores the full result | SKIPPED | no build/device |
| 12 | Filter survives navigation/range/details/Add | SKIPPED | no build/device |
| 13 | Empty period: zero totals, Go to today, Day-only Add | SKIPPED | no build/device |
| 14 | No-match filter: zero totals, Clear filter | SKIPPED | no build/device |
| 15 | No-expenses-ever invitation, no false unavailability | SKIPPED | no build/device |
| 16 | Controlled read failure: error + Retry, no zeros/reset | SKIPPED | no build/device/failure harness |
| 17 | Successful Retry preserves range/period/filter | SKIPPED | no build/device |
| 18 | Refresh failure retains snapshot marked stale | SKIPPED | no build/device |
| 19 | Row details read-only; Back preserves selection | SKIPPED | no build/device |
| 20 | Day prefill; Week/Month and later entries default to today | SKIPPED | no build/device |
| 21 | In-view save refreshes rows/count/total | SKIPPED | no build/device |
| 22 | Out-of-view save feedback without false inclusion | SKIPPED | no build/device |
| 23 | Light/dark, 200% text, reduced motion, landscape, keyboard, safe areas | SKIPPED | no build/device |
| 24 | Labels, selected/disabled states, contrast, 48 dp, non-color-only | SKIPPED | no build/device; contrast not measured |
| 25 | Hundreds of grouped rows fully scrollable | **DEFERRED** | depends on the deferred T031 fixture; not reported as passing |

## Success-criteria mapping

| Criterion | Runtime status | Notes |
| --- | --- | --- |
| SC-003 boundary/exactly-once/timezone/clock | **UNVERIFIED** | source review only; no fixture/device trials |
| SC-004 100+ filter trials | **UNVERIFIED** | no fixture/device trials |
| SC-005 empty/stale/failure states | **UNVERIFIED** | no controlled failure injection at runtime |
| SC-006 selected-day/Week/Month/out-of-range Add | **UNVERIFIED** | no Add trials |
| SC-007 offline/accessibility/restart/contrast | **UNVERIFIED** | no build/device/screen-reader/contrast check; large-dataset portion deferred |
| SC-002 performance/large dataset | **DEFERRED** | T031/T033 deferred by owner |
| SC-001 task study | **NOT RUN** | see `task-study.md` |

## Disposition

The entire manual matrix is skipped. Do not report SC-003–SC-007 as passing until an authorized build and emulator/device run produces observed evidence.
