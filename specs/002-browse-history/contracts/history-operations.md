# Device-local history operation contracts

**Feature:** `002-browse-history` | **Date:** 2026-11-09  
These are in-process Dart contracts, not HTTP endpoints. Data shapes: [data model](../data-model.md). Storage guarantees: [history persistence](history-persistence.md). Recording contracts remain owned by [Feature 1](../001-record-expenses/contracts/local-operations.md).

## Common types and boundaries

Use the existing sealed `Result<T>` = `Success<T>` / `Failure<T>(AppFailure)` and reused `Money`, `LocalDate`, `Expense`, `Category`, `ExpenseId`. New history types are immutable:

```text
HistoryRangeType = day | week | month
CategoryFilter   = AllCategories | SelectedCategory(categoryId)
HistoryPeriod    = (rangeType, start: LocalDate, end: LocalDate)   // inclusive
DateGroup        = (date: LocalDate, expenses: List<Expense>, subtotalMinor: int)
HistorySnapshot  = (period, filter, groups, count, totalMinor,
                    hasAnyExpenses, latestExpenseDate, status)
HistoryStatus    = loading | available | emptyPeriod | noFilterMatches | emptyEver | unavailable | stale
HistoryQuery     = (period: HistoryPeriod, filter: CategoryFilter)
```

Failures carry only non-sensitive `AppFailureCode` values: `storageUnavailable`, `initializationFailed`, `incompatibleStore`, `integrityFailure`, `calculationOverflow`, `outcomeUnavailable`, `privacyPolicyUnavailable`. No SQL, amounts, dates, notes, category names, identifiers or row contents appear in messages or diagnostics. History introduces no new failure code.

## Repository reads

### `ExpenseRepository.listCategoriesForFilter() → Future<Result<List<Category>>>`

- Returns every category, active and archived, in stable seed/row order.
- Includes `id`, `name`, `iconKey`, `isActive`, `isProtected`; archived entries remain selectable.
- Failure is a typed storage failure. It is not an empty list and must not be shown as "no categories".
- Read-only; does not archive, restore, rename or reassign anything.

### `ExpenseRepository.loadHistory(HistoryQuery query) → Future<Result<HistorySnapshot>>`

- Runs one read transaction over the existing schema v1 and returns the snapshot defined in the data model.
- Applies `period.start <= expense_date <= period.end` and, for `SelectedCategory`, `category_id = ?` in the same transaction.
- Orders rows `expense_date DESC, save_sequence DESC`; groups by date; derives count, group subtotals and total from exactly those rows.
- Also returns `hasAnyExpenses` and `latestExpenseDate` from the same transaction.
- Group/period money accumulation uses checked integer arithmetic. Overflow → `Failure(calculationOverflow)`; never a wrapped, clamped, rounded or floating total.
- Must not mutate rows, categories, `user_version` or files. A missing/unreadable store → typed failure with no zero-filled snapshot and no reset.

### Navigation bounds

The controller derives bounds from `HistorySnapshot` plus the injected local clock:

```text
earliestPeriod        = periodFor(rangeType, LocalDate(1, 1, 1))
currentPeriod         = periodFor(rangeType, today)
latestSavedPeriod     = latestExpenseDate == null ? null : periodFor(rangeType, latestExpenseDate)
latestReachablePeriod = laterOf(currentPeriod, latestSavedPeriod)
```

`canGoPrevious = selected.start > earliestPeriod.start`.  
`canGoNext = selected.start < latestReachablePeriod.start`.

Forward movement may therefore expose saved periods later than the current date after a device-clock rollback. Creating new future-dated expenses remains rejected by the unchanged recording validator.

## History controller

### `HistoryController.initialize() → Future<void>`

Sets `Day` with the current local day and `AllCategories`, loads filter categories, then loads the snapshot. No expenses is not an error.

### `HistoryController.changeRange(HistoryRangeType rangeType) → Future<void>`

- Sets the requested range and resets the anchor to the **current period** of that range, regardless of the previous period.
- Preserves the active category filter.
- Reloads rows, count, subtotals, total and navigation bounds.

### `HistoryController.goToPrevious() / goToNext() → Future<void>`

- Moves exactly one day, week or month for the active range and reloads.
- Does nothing when the corresponding bound is reached; controls expose the disabled state.
- Backward stops at the earliest representable period. Forward stops at `latestReachablePeriod`.

### `HistoryController.goToToday() → Future<void>`

Selects the current period for the active range, preserves the filter and reloads.

### `HistoryController.selectFilter(CategoryFilter filter) / clearFilter() → Future<void>`

- `selectFilter` accepts a loaded active or archived category id and reloads the same period with the narrowed record set.
- `clearFilter` restores `AllCategories` and the full period result.
- The active filter remains visible and is never silently cleared by navigation, range change, resume or detail/Add round trips.

### `HistoryController.refresh() / load() → Future<void>`

- Re-queries the current selection and filter; used on open, after a successful Add, and on app resume.
- First-load failure → `unavailable` with actionable Retry.
- Refresh failure with a prior snapshot → `stale`: retained values are explicitly marked unavailable/stale, never presented as current.
- Retry reuses the same range, period and filter.
- Midnight while open does not move the selection; reopening History initializes to the current day.

### Status derivation

```text
loading                                      -> loading
failure, no prior snapshot                   -> unavailable
failure, prior snapshot retained             -> stale
success, !hasAnyExpenses                     -> emptyEver
success, filter active and count == 0        -> noFilterMatches
success, AllCategories and count == 0        -> emptyPeriod
success, count > 0                           -> available
```

`emptyEver` takes precedence over filter/period emptiness. Empty results show zero totals; `unavailable` and `stale` must not show zero as if no records existed.

## Navigation and Add-expense integration

### `OverviewScreen` → History

A single labeled History action pushes `HistoryScreen(repository: ..., coordinator: ...)`. No inert tab or excluded control is added.

### History row → details

Pushes the existing `ExpenseDetailsScreen` with the row's `ExpenseId`. Back returns to History with the same controller state (range, period, filter); details performs no mutation.

### `HistoryScreen` → Add expense

- With `Day` active, start Add with `initialDate = selected day`.
- With `Week` or `Month` active, start Add with no `initialDate` (today).
- Never reuse an earlier selected day for a later unrelated entry.
- `AddExpenseScreen` / `EntryController` accept optional `initialDate`; when omitted the existing default remains the current local day.
- On success, Add returns the saved `Expense` (null on cancel/abandon). History refreshes the current selection and shows neutral success feedback.
- If the saved date or category is outside the displayed period or filter, the feedback must not imply the entry belongs to the current result, and the current rows/totals remain correct for the actual selection.
- Recording validation, duplicate-submit protection, dirty-form discard, pending-save cancellation and failure handling are unchanged and remain owned by Feature 1.

## Presentation and privacy boundaries

- Presentation must not execute SQL, compute money with floating point, persist selection/filter state outside the controller lifetime, or render a failure as an empty result.
- Range controls are labeled and expose their selected/disabled state; previous/next have accessible labels; the filter and Clear filter action are text-visible and not color-only.
- Empty period, no filter matches, no expenses ever, stale and unavailable are distinct, non-interchangeable states with the actions required by FR-012–FR-016.
- No logging of payloads, notes, dates, categories, amounts, identifiers or database contents. No network, account, telemetry, backup or export path is introduced.
- Every selected-period row remains reachable by scrolling; no row is dropped to shorten the list.
