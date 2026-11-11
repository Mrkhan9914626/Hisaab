# Quickstart: verify history browsing on the Feature 1 stack

**Feature:** `002-browse-history` | **Date:** 2026-11-09  
This is an execution guide, not a record of executed commands. The stack is identical to Feature 1: Flutter/Dart, SQLite via `sqflite`, Codemagic, Android 7.0 / API 24 minimum. No new dependency, SDK, platform project, schema version or workflow is added. Read [plan.md](plan.md) and [research.md](research.md) first.

## 1. Confirm the unchanged prerequisites

- Use the existing `app/` Flutter project and the Feature 1 pins: candidate Flutter `3.47.8` with bundled Dart, `sqflite 2.4.5`, `characters 1.4.1`, `uuid 4.6.0`; host-only `sqflite_common_ffi 2.4.5`.
- Keep Android `minSdk 24`; iOS is legacy/out of scope under Constitution v2.0.0.
- Confirm `app/pubspec.yaml` gained no new package. If implementation is tempted to add a calendar, date-formatting, router or state package, stop and revisit [research.md](research.md) §1 instead.
- Confirm `user_version` stays `1` and no migration, index, table or seed changed. History is read-only.
- The owner's Windows machine has no local Flutter/Android SDK. SDK-dependent commands run only in an owner-authorized Codemagic build.

## 2. Build with the existing Android lane

Use the existing root `codemagic.yaml` `android-debug` workflow; no new workflow is required. With owner authorization, from `app/`:

```sh
set -eu
flutter pub get
flutter build apk --debug
```

If an analysis lane is available, it may additionally run:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
```

A skipped, failed or unavailable lane is recorded as such and is never reported as a pass. Do not claim a build, analysis or test result that was not actually observed. Use the debug APK only for disposable synthetic-data checks; never enter irreplaceable real history.

## 3. Source-review checklist before manual checks

Review the diff against [history-operations.md](contracts/history-operations.md) and [history-persistence.md](contracts/history-persistence.md):

- [ ] `calendar_range.dart` uses civil dates only; Monday–Sunday weeks; inclusive boundaries; correct leap/month/year behavior; no UTC or duration-based date math; no year-10000 construction.
- [ ] `loadHistory` uses one read transaction, inclusive `>=`/`<=` string comparisons, optional category predicate, `expense_date DESC, save_sequence DESC` ordering, and no write statement.
- [ ] Count, date subtotals and period total are derived from the same returned rows with checked integer arithmetic; no floating `total()`; overflow maps to `calculationOverflow`.
- [ ] `latestExpenseDate` and `hasAnyExpenses` come from the same transaction; navigation bounds use the later of the current and latest saved periods; the earliest period is handled.
- [ ] The controller resets to the current period on range change and Go to today, preserves the filter, and preserves selection/filter across details and Add round trips.
- [ ] Status derivation keeps `emptyEver`, `emptyPeriod`, `noFilterMatches`, `unavailable` and `stale` distinct; failures never render zero as if no records existed.
- [ ] Add receives `initialDate` only from a Day selection; Week, Month, Overview and later unrelated entries default to today; the saved record result does not imply out-of-view inclusion.
- [ ] No new network, account, telemetry, backup, export, logging of financial fields, schema change or excluded control appears.

## 4. Prepare synthetic fixtures safely

- Use the existing test/fixture helpers (for example `app/test/support/synthetic_fixtures.dart`) in a disposable debug build or test driver. Do not add a production reset/export/seed screen.
- Build a fixture that covers known records on:
  - a selected day and its adjacent days;
  - Sunday/Monday and the days immediately before/after the week;
  - first/last day of a month and adjacent months;
  - a leap day, a year transition and a week spanning a month or year;
  - multiple active categories and at least one archived category (`is_active = 0`);
  - repeated identical amounts and maximum-per-expense amounts;
  - a saved date later than the simulated current date for the clock-rollback check.
- Use only synthetic labels, amounts and notes. Never copy a real phone database, journal or sidecar into an emulator, artifact, log or Git.

## 5. Manual Android acceptance

Run on an authorized emulator or physical device and record whether evidence came from a physical device or emulator.

### Navigation and periods

1. Open Overview, activate the labeled History action, and confirm History opens on the current day with Day selected and All categories visible.
2. Check Day, Week and Month labels and totals against the fixture; confirm adjacent days/weeks/months are excluded and each record appears exactly once.
3. Use previous/next and confirm exactly one day/week/month moves with the label, rows, count and totals together.
4. Confirm backward navigation stops at the earliest representable period.
5. Set the device date backward with later-dated saved fixtures; confirm forward navigation reaches those saved periods and shows their exact rows/count/total, while Add still rejects a new future date.
6. Change Month → Week and confirm the current week is selected; repeat for other range changes.
7. Use Go to today and confirm the current period for the active range is selected and the filter is preserved.
8. Leave History open across local midnight and confirm the selected period does not silently move; reopen History and confirm it starts at the current day.

### Filter

9. Select an active category: rows, count, date subtotals and total narrow together.
10. Select an archived category with saved rows: its history remains visible and filterable.
11. Clear the filter: the full period result returns and the active-filter indication disappears.
12. Navigate periods, change range, open/close details and Add expense while a filter is active; confirm the filter remains visible and applied.

### States and failures

13. Exercise a period with no rows while records exist elsewhere: zero totals, "selected period is empty", Go to today, and—when Day is selected—an Add action for that day.
14. Apply a filter with no matches: zero totals, "no entries match", and a working Clear filter action.
15. Use a store with no expenses: first-expense invitation, zero totals, no registration/onboarding, no unavailability claim.
16. Induce a controlled read failure (invalid/corrupt disposable fixture or injected failure harness, never by deleting real data): actionable error and Retry, no zero totals, no reset.
17. Retry successfully and confirm the same range, period and filter return with correct rows.
18. Retain a loaded snapshot and fail the refresh: confirm values are explicitly marked stale/unavailable rather than current.

### Details and Add

19. Open a row: read-only details show amount, category, date, note or "No note added"; Back returns to the same range, period and filter.
20. From Day, start Add and confirm the selected day is prefilled. From Week and Month, confirm today is prefilled. After completing/abandoning, start an unrelated new entry and confirm it uses today.
21. Save inside the displayed period/filter: History refreshes with success and the new row/count/total.
22. Save outside the displayed period or filter: success is stated without implying inclusion; current rows and totals remain correct.

### Accessibility and layout

23. Check both light and dark themes, 200% text or the platform maximum if lower, reduced motion, landscape, keyboard-open and safe areas.
24. Confirm Day/Week/Month, previous/next, filter, Clear filter, Retry, Go to today, empty-state actions and rows are labeled, expose selected/disabled state, meet 4.5:1/3:1 contrast and 48 dp targets, and never depend on color alone.
25. Confirm hundreds of grouped entries remain fully scrollable with no omitted record.

## 6. Performance trials

On a representative 2020–2022 Android phone with 4 GB memory, ≥1 GB free storage, offline, using 10,000 synthetic expenses over 24 months with 500 dated today:

- 30 selected-period loads: ≥29 within 2 seconds with correct grouped rows, count and total.
- 30 range-type or category-filter changes: ≥29 within 500 ms.
- 30 history-row selections: ≥29 within 500 ms to correct details.

Record the actual device, OS, build/signing identity, fixture version, commit, tool versions, each trial result and every skipped check. Emulator timings are not physical-device evidence unless explicitly labeled as such. Do not invent evidence.

## 7. Record evidence

When checks actually run, write results under `docs/verification/002-browse-history/` with the date, commit, build identity, device/emulator disclosure, fixture description and pass/fail/not-run status for each item above. A passing build alone does not establish correctness; an unrun item stays unrun.

## Status

Nothing in this quickstart was executed during planning. No cloud build, SDK command, database query, emulator or physical-device check was performed. Owner authorization is required for push, cloud build and device execution.
