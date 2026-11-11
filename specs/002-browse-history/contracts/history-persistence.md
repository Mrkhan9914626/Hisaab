# Read-only persistence contract for history

**Feature:** `002-browse-history` | **Date:** 2026-11-09  
Storage ownership, configuration and upgrade rules remain those of [Feature 1 persistence](../001-record-expenses/contracts/persistence.md). This feature consumes them without redefining them.

## Ownership and configuration

- One application `ExpenseRepository` continues to own the `DatabaseFactory`, protected private location, connection lifecycle and serialized operation queue. Screens and the History controller never open their own connection.
- History opens no new database, uses no new file, and performs no write. The existing configuration (`foreign_keys=ON`, `journal_mode=DELETE`, `synchronous=EXTRA`) and failure mapping are unchanged.
- The protected no-backup directory, Android manifest/backup rules and privacy behavior are unchanged. History adds no permission, asset, channel, export or network path.
- Diagnostics may record only non-sensitive operation codes and durations. No SQL, row contents, amounts, dates, notes, category names or identifiers may be logged or copied into artifacts.

## Schema and compatibility

- No schema change. `user_version` remains `1`; no migration, index creation, seed, repair, delete or recreate step is introduced.
- The existing tables supply all fields: `expenses(save_sequence, id, amount_minor, category_id, expense_date, note)` and `categories(id, name, icon_key, is_active, is_protected)`.
- The existing index `expenses_date_sequence (expense_date, save_sequence DESC)` supports the inclusive civil-date range and required ordering. Filtering by `category_id` occurs within the same indexed range scan; do not add a new index or migration unless a measured need is documented and a preserving, reviewed migration is authorized.
- An unsupported/newer schema or an invalid existing store remains the Feature 1 explicit failure. History must not reset, reseed or recreate it.

## Snapshot read boundary

Within one read transaction, in this order or an equivalent consistent boundary:

1. Read joined expense rows for the inclusive period, optionally filtered by category id, ordered `expense_date DESC, save_sequence DESC`:

   ```sql
   SELECT e.save_sequence, e.id, e.amount_minor, e.category_id,
          e.expense_date, e.note,
          c.name AS category_name, c.icon_key, c.is_active, c.is_protected
   FROM expenses e
   JOIN categories c ON c.id = e.category_id
   WHERE e.expense_date >= ? AND e.expense_date <= ?
     /* AND e.category_id = ? when a category filter is active */
   ORDER BY e.expense_date DESC, e.save_sequence DESC
   ```

2. `SELECT EXISTS(SELECT 1 FROM expenses) AS present` for the no-expenses-ever distinction.
3. `SELECT MAX(expense_date) AS latest FROM expenses` for the forward navigation limit.

- Use inclusive `>= start` / `<= end` comparisons on canonical `YYYY-MM-DD` strings. Use `<= '9999-12-31'` when the period ends at the domain maximum; never construct year 10000.
- The transaction must be read-only in effect: no `INSERT`, `UPDATE`, `DELETE`, pragma write, temporary table or schema statement.
- A failure inside the transaction returns a typed `Failure`. It must not return empty collections, zero totals or a partially assembled snapshot.

## Exactness and consistency

- Rows, groups, group subtotals, count and period total all derive from the same returned row list. No separate `COUNT`, `SUM` or `total()` query may supply a displayed value.
- Group by `expense_date`; accumulate each group and the period total with checked integer/BigInt arithmetic over `amount_minor`. Negative values are impossible under the schema; overflow of signed 64-bit display arithmetic maps to `AppFailure(calculationOverflow)`.
- Every matching row appears exactly once. Date groups are newest first and rows within a group are newest-saved first.
- Archived category rows remain readable through the join; the current category name/icon is displayed. History never changes `is_active`, `category_id`, dates, notes or amounts.
- `latestExpenseDate` and `hasAnyExpenses` are from the same snapshot. A later write made through the recording feature becomes visible only on the next refresh/resume; History does not poll.

## Navigation bounds

- Earliest reachable period: `periodFor(rangeType, LocalDate(1, 1, 1))`.
- Latest reachable period: the later of the current period and the period containing `latestExpenseDate` (when present).
- The bounds are recomputed on every successful load. If `latestExpenseDate` is later than today because the device clock moved backward, forward navigation must reach that saved period and show its exact rows, count and total.
- Future-dated expense creation remains rejected by the unchanged recording validator; History must not offer any write path that would create one.

## Failure, stale and empty semantics

| Situation | Required behavior |
| --- | --- |
| Store contains no expenses ever | `emptyEver` with zero totals and a first-expense action |
| Selected period has no rows, store has records elsewhere | `emptyPeriod` with zero totals and Go to today; Day also offers Add for that day |
| Active filter has no rows in the period | `noFilterMatches` with zero totals and Clear filter |
| First load fails | `unavailable` with actionable error and Retry; no zero totals |
| Refresh fails after a successful load | `stale`; retain the prior snapshot only as explicitly unavailable/stale, with Retry |
| Retry succeeds | Preserve the same range, period and filter and show the correct records |
| Selected category id does not resolve | Typed integrity/storage failure, not an empty result |

A failed read must not reset or replace stored data. Closing and reopening the app must show the same durably saved records, because History reads the same committed store.

## Verification obligations

Automated tests are not required under Constitution V. The following must still be checked by source review and named manual Android inspection on an authorized build:

- **Boundaries:** day/week/month inclusivity; Monday–Sunday week; leap day; month lengths; year transitions; weeks or months spanning boundaries; adjacent periods excluded; each row exactly once.
- **Totals:** repeated identical amounts and maximum-per-expense fixtures; subtotals and period total agree with rows; overflow becomes an explicit error.
- **Filters:** active and archived categories; clearing restores the full result; filter survives period navigation, range change, resume and detail/Add round trips.
- **States:** empty period, no filter matches, no expenses ever, first-load failure, retry success and stale retention are distinct and correctly worded.
- **Navigation:** backward bound at the earliest representable period; forward bound at the later of the current period and the latest saved period; device-clock-rollback saved periods reachable; new future-dated entry still rejected.
- **Add integration:** Day prefill only; Week/Month and unrelated entries default to today; in-view and out-of-view saves both give truthful feedback and refresh.
- **Accessibility and layout:** both themes, system text scaling, reduced motion, landscape, keyboard, safe areas, screen-reader labels/order, 48 dp targets and full scroll reachability.
- **Performance:** SC-002 trials on a representative device with the synthetic 10,000-record/500-today fixture; disclose skipped checks and whether evidence came from a physical device or emulator.
