# Data Model: Browse and filter spending history

**Feature:** `002-browse-history` | **Schema:** reuses v1, no migration | **Date:** 2026-11-09  
Design only; no query or database was created. Shared contracts: [history operations](contracts/history-operations.md), [history persistence](contracts/history-persistence.md). Recording entities: [Feature 1 data model](../001-record-expenses/data-model.md).

## Reused persistent entities

Feature 2 adds no table, column, index or migration. It reads the existing schema v1:

| Entity | Fields used | History behavior |
| --- | --- | --- |
| Expense | `id`, `save_sequence`, `amount_minor`, `category_id`, `expense_date`, `note` | Read-only; never inserted, updated or deleted. `expense_date` is a canonical civil date; `save_sequence` supplies stable newest-saved ordering. |
| Category | `id`, `name`, `icon_key`, `is_active`, `is_protected` | All categories, active and archived, are filter options and row labels. Archived categories keep their saved references. |
| Store metadata | `user_version = 1` | Validated on open by the existing storage layer; History does not change it. |

The existing index `expenses_date_sequence (expense_date, save_sequence DESC)` supports the inclusive range scan and ordering. No persisted totals, counts or groups are introduced.

## Value objects

| Value | Representation | Validation / behavior |
| --- | --- | --- |
| HistoryRangeType | enum `day`, `week`, `month` | Exactly one active range. Labels are presentation concerns. |
| LocalDate | reused validated Gregorian civil date, persisted/compared as `YYYY-MM-DD` | `0001-01-01`–`9999-12-31`; never derived from a UTC instant or elapsed duration. |
| HistoryAnchor | `LocalDate` | Any representable date. The selected period is derived from it. |
| HistoryPeriod | `rangeType`, inclusive `start` and `end` `LocalDate`s | Day: start = end = anchor. Week: Monday–Sunday containing the anchor. Month: first–last day of the anchor month. `contains(LocalDate)` is inclusive at both boundaries. Periods are non-overlapping per range type. |
| CategoryFilter | sealed `AllCategories` or `SelectedCategory(categoryId)` | `AllCategories` is the default. A selected id must resolve to an existing active or archived category when loaded; an id that no longer resolves is a typed read failure, not an empty filter result. |
| HistoryPeriodLabel | derived presentation text plus `isCurrent` flag | Names the covered local calendar dates and indicates the current period without changing period identity. |
| NavigationLimits | `earliestPeriod`, `latestReachablePeriod` | Earliest is the period containing `0001-01-01` for the range. Latest is the later of the current period and the period containing the latest saved expense date. |

## Derived entities

### DateGroup

| Field | Type | Invariant |
| --- | --- | --- |
| date | `LocalDate` | One local calendar date inside the selected period. |
| expenses | ordered list of reused `Expense` | Only rows whose `expense_date` equals `date`; ordered `save_sequence DESC`; every row appears exactly once across groups. |
| subtotalMinor | `int` | Exact PKR paisa sum of this group's rows using checked integer accumulation; never floating, rounded or truncated. |

Groups are ordered newest date first. Display order never changes a subtotal or the period total.

### HistorySnapshot

| Field | Type | Invariant |
| --- | --- | --- |
| period | `HistoryPeriod` | The exact selection that produced this snapshot. |
| filter | `CategoryFilter` | The exact filter that produced this snapshot. |
| groups | ordered `List<DateGroup>` | Date-descending; empty only when `count` is zero. |
| count | `int` | `groups` row total; equals the number of matching expenses. |
| totalMinor | `int` | Sum of all group subtotals / all matching rows, checked. |
| hasAnyExpenses | `bool` | Whether the store contains at least one expense anywhere, from the same read transaction. |
| latestExpenseDate | `LocalDate?` | Latest saved expense date in the store, or `null` when empty; drives the forward navigation limit. |
| status | `HistoryStatus` | One of the values below. |

`count`, every `subtotalMinor`, `totalMinor` and every displayed row derive from the same returned row list. A failure never produces a zero-filled snapshot.

### HistoryStatus

| Status | Meaning | Totals |
| --- | --- | --- |
| `loading` | Initial load for the current selection. | Not shown as current. |
| `available` | At least one matching row exists. | Exact snapshot totals. |
| `emptyPeriod` | No rows match the selected period, but expenses exist elsewhere. | Zero. |
| `noFilterMatches` | A category filter is active and no rows match it in the selected period. | Zero. |
| `emptyEver` | The store contains no expenses at all. | Zero, with a first-expense invitation. |
| `unavailable` | The first load failed; no trustworthy snapshot exists. | Not zero; explicit error and Retry. |
| `stale` | A prior snapshot is retained while a refresh failed. | Retained values explicitly marked unavailable/stale. |

`emptyEver` takes precedence over period/filter emptiness. `noFilterMatches` requires an active filter. `emptyPeriod` requires `hasAnyExpenses = true` and `AllCategories`. A first-load failure can never become `emptyPeriod` or `emptyEver`.

## Controller state

### HistorySelection

`rangeType`, `anchorDate`, and derived `HistoryPeriod`. A fresh History opens with `Day` and the current local day. Changing `rangeType` replaces the anchor with the current local period of the new type. Previous/next replace the anchor with the start of the target period. Go to today replaces it with the current period of the active type.

### HistoryViewState

- `selection`, `filter`, `snapshot`, `categories` (filter options), `navigationLimits`, `failure`, `loading`.
- `canGoPrevious` is false when the selected period start equals the earliest period start.
- `canGoNext` is false when the selected period start equals the latest reachable period start.
- An active filter and the selected range/period survive period changes, range changes, detail round trips and Add-expense round trips. They are never silently cleared.
- An already selected period does not change at local midnight while History is open; reopening History starts at the current day.

## Read derivation rules

1. Period membership is `start <= expense_date <= end` on canonical civil strings.
2. Optional filter adds `category_id = ?` in the same transaction.
3. Rows are ordered `expense_date DESC, save_sequence DESC`.
4. Walk the ordered rows once: append to the current date group while the date matches; start a new group when it changes; accumulate that group's subtotal.
5. Accumulate the period total across groups with checked signed 64-bit arithmetic. Overflow → `calculationOverflow`; never a wrapped, clamped or floating value.
6. `count` is the walked row count. No separate count query is used.
7. `hasAnyExpenses` and `latestExpenseDate` come from the same transaction so navigation bounds and result state agree with the snapshot.

## State transitions

```text
fresh open ──load──> loading ──success──> available | emptyPeriod | noFilterMatches | emptyEver
                       └──failure──> unavailable ──retry──> loading

available/empty* ──range change / prev / next / filter / go to today / resume──> loading (or in-place refresh)
                 └──refresh failure──> stale (retained snapshot) ──retry──> loading

any state ──row tap──> details ──Back──> same selection/filter state
any state ──Add (Day only prefilled)──> form ──saved──> refresh current selection
                                      └──cancelled/unchanged──> same selection/filter state
```

Range change and Go to today preserve the filter. Filter change and clear preserve range and period. Navigation never mutates stored data.

## Validation and failure rules

- Domain validation rejects an unrepresentable period, a period outside `0001-01-01`–`9999-12-31`, and a selected category id that does not resolve in the loaded filter list.
- A read failure is `AppFailure(storageUnavailable | incompatibleStore | integrityFailure | calculationOverflow)`; no exception text, SQL or field contents reach the UI or logs.
- The UI must never render zero totals for `unavailable` or current-looking values for `stale`.
- History does not validate or alter amounts, dates, notes or categories owned by the recording feature; it consumes them unchanged.
- Synthetic fixtures used for manual checks must not be written into a real installation or stored in build artifacts/logs.
