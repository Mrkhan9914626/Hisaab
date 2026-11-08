# Device-local operation contracts

**Feature:** `001-record-expenses` | **Date:** 2026-11-04  
These are in-process Dart contracts, not HTTP endpoints. Types are implementation interfaces to preserve across later features. Data invariants: [data model](../data-model.md). Storage guarantees: [persistence](persistence.md).

## Common types and boundaries

Use sealed result/error types and immutable values, not exceptions or null meaning empty data at the widget boundary. `AppFailure` carries a non-sensitive code and retry kind, never raw SQL or field contents in diagnostics. Codes: `storageUnavailable`, `initializationFailed`, `incompatibleStore`, `integrityFailure`, `calculationOverflow`, `outcomeUnavailable`, `privacyPolicyUnavailable`; validation errors are a map of field identifiers to user-facing instructions. IDs and payloads are not included in log messages.

Contract type names: `Money(minorUnits)`, `LocalDate(year, month, day)`, `Category(id,name,iconKey,isActive,isProtected)`, `Expense(id,saveSequence,amount,category,date,note)`, `EntryDraft`, `ImmutableSubmission(id,amount,categoryId,date,note)`, `OverviewSnapshot(today,todayRows,todayCount,todayTotal,monthTotal,hasAnyExpenses)`. `Result<T>` is `Success<T>` or `Failure<T>(AppFailure)`. `SaveOutcome` is `Saved(Expense)`, `Cancelled`, `KnownUnsaved(AppFailure)` or `OutcomeUnavailable(AppFailure)`; `SaveProgress` includes queued/writing/cancelling/checkingOutcome. `RetryKind` distinguishes ordinary operation retry from reconciliation.

## Native storage policy

`LocalStoragePolicy.prepareExpenseDirectory() → Future<Result<PrivateStoreLocation>>`

- Return an absolute private directory only after its required protection/backup exclusion is set and verified. The Dart repository appends a constant filename; callers cannot supply arbitrary filesystem paths.
- Android implementation uses noBackupFilesDir. iOS implementation uses a protected backup-excluded Application Support subdirectory. DB and all sidecars stay in this location.
- Failure blocks financial initialization with `privacyPolicyUnavailable`, retaining any existing data; no fallback to cache, external/shared storage or network.
- Platform inspection of backup/transfer behavior is additional required evidence, not implied by this method returning success.

## Store initialization and category choices

`ExpenseRepository.initialize() → Future<Result<void>>`

`ExpenseRepository.listActiveCategories() → Future<Result<List<Category>>>`

Initialize/migrate and verify schema/categories transactionally. Six stable defaults exist exactly once; Other stays protected. A confirmed existing empty history is a valid result; failed open/seed/invariant verification is Failure. Archive fixtures remain readable but are excluded from active choices. An empty active set/missing Other is an integrity failure, not a valid empty dropdown.

## Validate an entry

`EntryValidator.validate(EntryDraft draft, LocalDate today, List<Category> activeCategories) → ValidationResult`

Pure operation: return either immutable validated values or field errors. Amount 1–99,999,999,900 paisa, no unsupported precision; explicit active category required; valid date ≤ today; optional note ≤200 user-perceived characters. Preserve entered values on error. Focus first invalid field; several errors also produce a linked summary. Validation does not create an ID or save any data.

## Save, request cancellation, reconcile

`SaveCoordinator.begin(ImmutableSubmission submission) → SaveOperation`

`SaveOperation.progress → Stream<SaveProgress>`

`SaveOperation.outcome → Future<SaveOutcome>`

`SaveCoordinator.requestCancellation(ExpenseId id) → Future<SaveOutcome>`

`SaveCoordinator.reconcile(ExpenseId id) → Future<SaveOutcome>`

- Coordinator owns one app-wide write pipeline and operation registry. A second begin with the same ID/payload attaches to the existing operation; ID with different payload fails integrity checks. UI suppresses double taps but repository uniqueness is the ultimate guard.
- `begin` checks for an already saved matching ID before applying new-entry date/category validation. Frozen fields cannot change while queued/writing/checking. Once known-unsaved, the same unchanged payload can retry under the same ID; changed payload starts a new ID after prior execution is retired.
- Back/Cancel during pending save offers cancellation. Choosing to keep waiting does not set the cancel flag. Accepting cancellation enters cancelling/checking, not immediate navigation or ordinary draft discard.
- Queued work can be retired before dispatch. Active transaction checks cancellation before insert and immediately before return; throwing the dedicated cancellation exception rolls back. No unawaited SQL is permitted. A cancel after the final check can lose to commit.
- `Saved` requires acknowledged commit or matching row through a clean reconciled connection. `Cancelled` requires absence plus no commit-capable work remaining for this ID. If commit wins, return Saved and announce it truthfully. No compensating delete.
- Timeout is UI feedback only; it cannot settle an operation or release the identity for another submission. Unknown results require reconciliation, not a new write. The original native Future remains observed. If original execution cannot be drained, stay OutcomeUnavailable rather than claim absence.
- Any connection with uncertain transaction state is quarantined. Clean recovery, writer fence and matching-row query must be proved by native tests as defined in persistence.md. If not possible, the architecture validation gate is blocked.
- Saved/Cancelled navigate to origin (Overview now). KnownUnsaved retains editable fields and offers Retry or ordinary draft discard. OutcomeUnavailable retains fields, disables new submission/payload replacement and offers Check result again. Failed checking retains the same operation identity.
- A saved result followed by Overview refresh failure is still Saved; show saved feedback plus a separate unavailable-summary error. Do not offer Save again for that operation.

## Overview

`ExpenseRepository.loadOverview(LocalDate today) → Future<Result<OverviewSnapshot>>`

One read transaction supplies today rows, month sum and any-history existence; today's total/count derive from exactly those rows. All saved today entries are reachable, newest save_sequence first. Local month range is inclusive first day/exclusive next first day. All amounts exact; integer aggregate overflow → calculationOverflow, not zero.

UI states: initial loading; confirmed no expenses ever; empty today with earlier records; populated; unavailable with actionable Retry. A retained prior snapshot is explicitly stale/unavailable, not current. Refresh on entry/resume and local day/month rollover; no polling/network service. A new form defaults to current today, while an open draft retains its chosen date and is revalidated at submission.

## Read-only details

`ExpenseRepository.loadExpense(ExpenseId id) → Future<Result<Expense>>`

Return matching joined category metadata or failure; a missing record is integrity/not-found feedback with Retry/Back, never a fabricated blank expense or deletion claim. Present amount, category icon/name, civil date, note/No note added, device-only reminder. No edit/delete controls. Back does not mutate any data.

## Ordinary entry navigation

`EntryController.requestLeave() → LeaveDecision`

If no save pending: complete initial-value equality → leave directly; changed draft → Discard expense changes? with Keep editing as safe initial focus. Dismissing keeps all fields. Explicit Discard changes returns without a write. During pending save/reconciliation, delegate to the cancellation contract instead. Trap confirmation focus and restore it; system back and navigation gestures follow the same rules. OS kill is not a cancellable navigation promise and does not require draft restoration.

## Presentation and privacy boundaries

Presentation must not execute SQL, format money via floating numbers, fetch fonts/assets remotely, or render failure as an empty result. No logging of payloads, notes, dates, categories, amounts, identifiers or DB content. Only non-sensitive operation code/stage and duration may be locally recorded for diagnosis. Synthetic fixture output belongs in test reports with no real device data. All essential flows support screen readers, both device themes, large text, reduced motion, keyboard and safe areas per the specification.
