# Data Model: Record expenses

**Feature:** `001-record-expenses` | **Schema:** 1 | **Date:** 2026-11-04  
Design only; no database has been created. Contracts: [local operations](contracts/local-operations.md), [persistence](contracts/persistence.md).

## Value objects

| Value | Representation | Validation / behavior |
| --- | --- | --- |
| Money | native Dart integer `minorUnits`; SQLite INTEGER | PKR only; 1–99,999,999,900 paisa inclusive per expense. Decimal input uses ASCII digits, outer whitespace trimming, optional period plus 1–2 digits. No signs, grouping, exponent, currency text, incomplete decimal, silent rounding or floating arithmetic. Compare normalized digit strings or BigInt before converting to int. Leading zeros are permitted. Display `PKR 1,234.50` using integer division/remainder. |
| LocalDate | validated year/month/day; persisted TEXT `YYYY-MM-DD` | Gregorian 0001-01-01–9999-12-31, valid leap/day combinations. No history-age cutoff. Compare calendar values, not UTC instants. Selected date must be ≤ device local today at submission. Construct month end-exclusive boundary from calendar components; 9999-12 can use a query predicate through `9999-12-31` without constructing year 10000. |
| ExpenseId | UUID string | One immutable submission identity becomes the saved expense identity. Not derived from fields, notes, date or clock. UUID collision with different payload is an integrity error. |
| Note | nullable text | Empty/whitespace-only → NULL; nonblank original text including spaces/newlines preserved. Maximum 200 extended grapheme clusters via `characters`, not code units, bytes or SQLite length. Preserve the text as supplied by the form; do not normalize or trim nonblank notes. Count line-break sequences using the same locked grapheme rules as other characters. No truncation. |
| IconKey | bundled named icon identifier | Must resolve to a packaged icon with a semantic category name; no network or emoji icon dependency. |

Unicode note segmentation follows the locked `characters` Unicode rules; tests include composed/decomposed letters, flags, skin-tone and ZWJ emoji. Amount entry intentionally uses `0`–`9` and period; currency display is fixed PKR formatting, while native date pickers/accessibility respect device conventions without changing saved civil dates. No translation catalog is required in this slice.

## Persistent entities

### Category

| Field | SQLite shape | Invariant |
| --- | --- | --- |
| id | TEXT primary key, not null | Stable for the lifetime of the store. |
| name | TEXT not null | Built-in name now; later management must preserve identity. |
| icon_key | TEXT not null | Offline icon key. |
| is_active | INTEGER not null | Exact integer 0/1; archived=0. |
| is_protected | INTEGER not null | Exact integer 0/1; only built-in Other=1. |

Initial IDs/names/icon keys: `builtin.food-drinks` / Food & drinks / `food_drinks`; `builtin.transport` / Transport / `transport`; `builtin.shopping` / Shopping / `shopping`; `builtin.bills` / Bills / `bills`; `builtin.health` / Health / `health`; `builtin.other` / Other / `other`. Seed all six in schema creation transaction only. No case-insensitive category uniqueness rule is invented here; Feature 4 resolves that before creating custom categories.

Other must retain its ID/name and active/protected status. Database checks/triggers protect its active flag and name and reject deleting it. Expense references use RESTRICT; no category-delete operation is exposed. A trigger rejects new expense assignments to inactive categories; saved records retain archived references and use the current category display name/icon when read.

### Expense

| Field | SQLite shape | Invariant |
| --- | --- | --- |
| save_sequence | INTEGER PRIMARY KEY AUTOINCREMENT | Internal order only; monotonic across committed inserts; gaps allowed. Never exposed as the durable public identity. |
| id | TEXT not null unique | ExpenseId/submission UUID; retry deduplication key. |
| amount_minor | INTEGER not null | `typeof(amount_minor)='integer'` and 1–99,999,999,900. |
| category_id | TEXT not null foreign key | Existing Category.id; RESTRICT on update/delete. New insert requires active category. |
| expense_date | TEXT not null | Canonical validated civil date; never rewritten by timezone changes. |
| note | TEXT nullable | Canonical optional note rules above. |

Index: `(expense_date, save_sequence DESC)`. Date query includes today's exact date; current-month query is `expense_date >= monthStart AND expense_date < nextMonthStart`. No saved timestamp is required: save_sequence supplies ordering independent of device clock. No persisted calculated totals or counts. 10,000 records is a measured acceptance fixture, not a hard capacity or retention limit.

### Store metadata

SQLite `user_version=1` tracks schema version. Creation of metadata, category rows, constraints, indexes and triggers is one transaction; any failure rolls back initialization. Never treat a failed version query/open as a new store. A recognizable existing-file/migration inconsistency is an unavailable-data error, not permission to delete/reseed. Distinguish a genuinely missing initial file from an existing invalid file before opening. Unsupported newer schema → explicit incompatible-store error.

## Non-persistent state

### EntryDraft

Raw amount, selected category ID or none, LocalDate, raw/canonical note, `origin=overview` for this slice, initial-value snapshot, field errors and state. Dirty comparison checks the full initial form; changing then restoring all original values becomes clean. Default category is none; default date today; draft starts fresh for every unrelated new form. The coordinator owns any submitted payload independently of widget disposal. Draft input survives in-session errors/Keep editing but not necessarily process termination.

### ImmutableSubmission

`ExpenseId id`, Money, CategoryId, LocalDate and canonical Note. Freeze on first valid Save. The same ID can be retried only with exactly this payload; identical separate deliberate entries use different IDs. While uncertain, draft controls that could replace the payload are disabled but the draft remains visible. A known-unsaved failure unlocks editing; any edited payload receives a new ID, after retiring the settled attempt. Reconciliation checks saved identity before applying current-date/active-category validation to a retry.

### SaveState

`editing → queued → writing → saved` is the happy path. Additional states: `cancelling`, `checkingOutcome`, `knownUnsaved`, `outcomeUnavailable`, `cancelled`. Only `saved` and `cancelled` allow automatic return. `knownUnsaved` permits edit/retry and ordinary draft discard; `outcomeUnavailable` permits reconciliation retry, not a new write. Cancellation requests are cooperative, never an assertion that rollback occurred.

### OverviewSnapshot

`today`, exact today's row list, count and total derived from those rows, month total, and `hasAnyExpenses`. One consistent read boundary supplies the complete snapshot. Distinguish `loading`, `available`, `emptyEver`, `emptyToday`, `unavailable` and explicitly stale prior snapshot. A failed read cannot be converted into a zero-filled snapshot.

## Validation and overflow

- Domain validation rejects invalid dates/category/note/amount before write; repository rechecks category relationship/activity and uses the same immutable values.
- SQL checks include storage-class guards, integer bounds and boolean flags; civil-date validity and grapheme counting are enforced in the only production repository entry point. A direct fixture writer must validate independently or intentionally test corruption detection.
- Arithmetic must not pass through floating values. 10,000 maximum amounts sum to `999999999000000` paisa. Aggregate beyond signed 64-bit range raises typed calculation failure; no `total()`, clamping or formatting of a wrapped integer.
- UI validation does not mutate persisted history when the device date changes. An expense previously saved for a date now greater than local today still exists; reconciliation accepts it as saved.
- No DB row or journal/sidecar may be copied into test artifacts, logs, Git or CI from a real installation. Fixtures are synthetic.

## Storage transitions and migrations

1. Native private/excluded directory ready → open/configure → create/migrate transaction → invariant verification → ready.
2. Any initialization/read failure → unavailable with retry, same path and data; never reset.
3. Create expense transaction → complete commit or no insertion; one submission ID provides deduplication.
4. Ordered `n→n+1` migrations run transactionally and preserve IDs, category references, minor units and civil dates; no destructive downgrade or `REPLACE` seeds.
5. Fresh schema v1 has no prior production version to migrate. Test creation and simulated transactional failure now; whenever v2 exists, add an actual v1 fixture upgrade test before migration implementation. Do not ship a fake v2 solely for tests.
6. No schema-level deletion/edit/category-lifecycle APIs are implemented in Feature 1; future specs extend these contracts without silently redefining stored values.
