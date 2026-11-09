# Persistence, recovery and upgrade contract

**Feature:** `001-record-expenses` | **Date:** 2026-11-04

## Ownership and configuration

One application repository owns the database factory, private location, connection lifecycle and serialized operation queue. Screens cannot open their own connections. Inject `DatabaseFactory` so host tests use file-backed sqflite_common_ffi while mobile integration tests use the real sqflite plugin. Inside a transaction use only its Transaction object; await every SQL statement, never call the outer Database and never catch a write error then return normally.

Configuration before migrations: foreign_keys=ON, journal_mode=DELETE, synchronous=EXTRA. Query each effective value and map an unsupported safe configuration to a typed error. Do not apply journal-mode changes inside schema transactions. The adapter must observe both transaction callback errors and native commit completion. An exception alone is not proof of rollback; success is acknowledged only after commit completes. Existing-store data is never deleted on failure.

## Schema and access

See [data-model.md](../data-model.md) for fields and constraints. Primary writes use INSERT and explicit identity comparison; never REPLACE or destructive upserts. Prefer explicit ID lookup + insert in one transaction; if a uniqueness failure occurs, inspect the saved payload in a safe transaction rather than ignoring every constraint failure as deduplication. Foreign-key enforcement and active-category validation are separate rules. Dates use canonical civil strings, notes use grapheme validation at the repository boundary.

Overview queries and derived values share a consistent snapshot. SQL SUM on integer money, exact today-row accumulation with checked bounds, no floating `total()`/cast. A failed read does not supply empty collections/zero defaults. Store absence, empty data and inaccessible data are distinct states.

## Idempotency and cancellation proof obligations

1. Immutable ID/payload established before first write; all retries of that operation reuse it.
2. One execution owner schedules all attempts; cancelled/retired attempts cannot re-enter the queue.
3. Cancellation checkpoint before insert and final synchronous check before callback return. Throw to roll back; no await follows the final check. Native commit can still win after this point.
4. Original native work must settle before a missing-row read proves absence. Never settle operation ownership merely because a timeout elapsed, the route closed or cancellation was requested.
5. On uncertain commit/rollback: stop scheduling on the old handle and quarantine it; drain known pending native work. Recover the same file and obtain a demonstrably clean connection/write boundary. A completed close Future alone is not sufficient evidence because adapters may suppress close/rollback errors.
6. Native recovery proof requires that the old connection cannot later commit, the new connection successfully acquires/finishes an exclusive writer transaction/fence, and a subsequent ID read sees committed state rather than old uncommitted state. Use finite retry budgets for recovery attempts and expose Check result again on exhaustion. Do not block the UI thread or silently run infinite retries.
7. Matching committed row → Saved; absent and no future writer → Cancelled if requested, otherwise KnownUnsaved; any failure to prove the boundary → OutcomeUnavailable. Different payload under same ID → IntegrityFailure, never Saved.
8. If sqflite cannot satisfy the verified boundary, do not assert cancellation. Keep uncertain feedback honest and block native acceptance; investigate a replacement SQLite adapter/native recovery extension, with a reviewed decision before adopting it. No deletion is allowed to emulate cancellation.

## Creation and upgrades

- Use user_version=1. Schema/default creation is one atomic transaction. Stable seed IDs are defined in the data model; no per-open replacement or reinsert on read failure.
- Validate invariants on open; distinguish genuinely new file from existing invalid store. An invalid/missing protected category in an existing initialized store is actionable failure, not automatic reset.
- Future schema upgrade n→n+1 preserves row identities, exact integers, category relationships, dates and notes, with fixture-based upgrade/failure tests before the migration. Supported downgrade is none: newer schema shows incompatible-store error.
- Closing/reopening the file must preserve all successful submissions. Process death during a transaction must yield complete row or none after recovery. An unknown operation does not survive as an auto-retry worker; restart shows actual saved data and starts no speculative writes.
- No recovery/export/backup file is created as part of migration. An in-place transactional rollback preserves original data; do not stage financial contents in a backed-up or shared temporary directory.

## Platform protection

Android DB directory uses noBackupFilesDir; iOS protected Application Support child directory is excluded from backup before use. Treat journal/sidecars as financial data. Verify Android merged manifest/XML and iOS built entitlements/file flags, not only source declarations. No account, cloud API, release network permission, iCloud entitlement, file sharing or real-data CI upload.

Release evidence must test Android cloud and device transfer and iOS backup/device migration with synthetic records and inspect whether any financial files are copied. Incomplete or contradictory evidence blocks release; the constitution has no authorized exception. Current Apple exclusion/transfer semantics need native verification because documentation retrieval was unavailable/interrupted during planning.

## Required test boundaries

Inject deterministic barriers/faults at queue dispatch, before insert, after insert, final cancellation checkpoint, commit acknowledgement, connection recovery and Overview refresh. Do not simulate native commit uncertainty merely by throwing before a transaction starts. Test on host SQLite and actual Android/iOS paths. Include: matched retries, mismatched IDs, separate equal purchases, no late write after confirmed cancellation, commit-wins feedback, failed checking with retained draft, initialization failure, corrupt/inaccessible store with no reset, exact maximum sums, aggregation overflow, and versioned-upgrade preservation when applicable.
