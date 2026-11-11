# ADR-0002: Protected SQLite and Save Coordinator

> **Amendment (2026-11-09):** Constitution v2.0.0 is Android-only. The iOS protected-storage
> location and iOS native bridge described here are out of scope; Android `noBackupFilesDir`,
> `allowBackup=false`, and the extraction rules remain in force.

> **Scope**: This ADR records the persistence, privacy-path, and write-lifecycle decision cluster. It covers storage location, exact money representation, atomic save ownership, idempotency, cancellation, and recovery. It does not claim that native feasibility gates have passed.

- **Status:** Accepted
- **Date:** 2026-11-08
- **Feature:** 001-record-expenses
- **Context:** Expense history must survive termination, never be duplicated by retries, never be turned into an empty store by a failed read, and never leave the device through platform backup or transfer. Saves may be cancelled while pending, and a cancellation must not be confirmed while an existing transaction could still commit. The plan and persistence contract require one application-owned connection and a serialized write pipeline.

## Decision

- **Exact money:** Persist PKR as integer paisa (`INTEGER`, range `1..99999999900` per expense). Parse and format with strings/BigInt/integers; never use binary floating point. Aggregate overflow surfaces as a typed calculation failure rather than a wrapped or rounded total.
- **Exact dates:** Persist validated Gregorian civil dates as fixed-width `YYYY-MM-DD` text. Dates are never rewritten by timezone or clock changes; month boundaries are built from calendar components, not 24-hour durations.
- **Protected location:** A native method channel returns a verified private directory before SQLite opens. Android uses `noBackupFilesDir` plus `allowBackup=false` and cloud/device-transfer exclusion XML. iOS uses a protected Application Support subdirectory with `isExcludedFromBackup` and file protection verified before the first write. Any failure returns `privacyPolicyUnavailable` and blocks initialization; there is no cache, shared-storage, Documents, or network fallback.
- **One database owner:** A single repository owns the database factory, connection lifecycle, schema v1 creation, invariants, and a serialized operation queue. Screens never open connections and never execute SQL.
- **Schema v1:** Atomic creation, `user_version=1`, six stable built-in categories seeded exactly once, protected/active `Other`, active-category insert trigger, `RESTRICT` foreign keys, and no destructive reset or reseed. Six initial categories use stable IDs independent of display names.
- **Single save coordinator:** `SaveCoordinator` owns immutable `ImmutableSubmission` payloads keyed by UUID. Repeated taps or retries reuse the same ID and payload. Same ID with a different payload is an integrity failure. Two deliberate equal-value purchases use different IDs.
- **Cancellation and recovery:** Cancellation is cooperative and checked before insert and synchronously before the transaction callback returns. A dedicated rollback exception performs rollback. Confirmed cancellation requires proof that no writer can later persist the ID. Uncertain outcomes are quarantined and reconciled through a clean writer boundary; otherwise the result stays `OutcomeUnavailable`. No timeout, route disposal, or compensating delete may claim cancellation.
- **Honest states:** Successful saves are announced only after observed commit. Failed reads and failed refreshes never become zero-filled or genuine-empty states. A saved result followed by a refresh failure still reports Saved.

## Consequences

### Positive

- Integer paisa and civil-date strings eliminate floating rounding and timezone drift.
- A single coordinator makes exactly-once deduplication and pending cancellation tractable across navigation and widget disposal.
- Native no-backup paths plus platform configuration provide defense in depth for device-only privacy.
- Typed failures and no-reset rules preserve user history when storage or platform policy fails.

### Negative

- The coordinator and reconciliation adapter add complexity compared with screens calling SQL directly.
- Native storage and cancellation recovery require real-device/plugin evidence; FFI host tests alone cannot close those gates.
- Pending-save cancellation can legitimately lose to commit, so the UX must support both outcomes honestly.
- The native bridge must be maintained inside generated Android/iOS projects.

## Alternatives Considered

- **Multiple screen-owned SQLite connections:** Cannot safely coordinate cancellation, snapshots, or commit observation, and risks stale writes.
- **`INSERT OR REPLACE` or destructive upserts:** Could delete/reinsert rows and break identity and history preservation.
- **WAL with weaker synchronization:** Not selected before measurements justify it; `DELETE` journal with `synchronous=EXTRA` is the default durability profile.
- **Compensating delete after a winning commit:** Pretends cancellation succeeded and violates no-deletion scope.
- **Default plugin database path or cache directory:** Does not establish the device-only no-backup policy and may be purgeable.
- **Floating-point money or UTC timestamps:** Violates exact-money and stable-civil-date requirements.

## References

- Feature Spec: `specs/001-record-expenses/spec.md` FR-004–FR-018
- Implementation Plan: `specs/001-record-expenses/plan.md` Phase 1–2
- Research: `specs/001-record-expenses/research.md` §4–§7
- Data Model: `specs/001-record-expenses/data-model.md`
- Persistence Contract: `specs/001-record-expenses/contracts/persistence.md`
- Local Operations Contract: `specs/001-record-expenses/contracts/local-operations.md`
- Related ADRs: `docs/adr/0001-approved-mobile-stack-and-platform-floors.md`
- Evaluator Evidence: `history/prompts/001-record-expenses/0008-fix-high-severity-analysis-findings.misc.prompt.md`
