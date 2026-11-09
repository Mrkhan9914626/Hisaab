# Expense Tracker Feature Map

**Date:** 2026-11-04  
**Status:** Proposed decomposition for review; not an approved feature specification or implementation plan.  
**Purpose:** Choose cohesive Spec Kit Plus feature boundaries before running `/sp.specify`.

## Recommendation

Organize V1 into **five outcome-oriented features**, not twelve screens and not technical layers. Each feature owns its user journey, relevant presentation, local persistence, validation, failure behavior, and acceptance tests. The five features together deliver the approved V1; an earlier increment is not the complete release.

| Suggested order | Feature | User outcome | Candidate short name |
| --- | --- | --- | --- |
| 1 | Record expenses and see current spending | Record a PKR expense offline and trust that it is saved and reflected in today's spending. | `record-expenses` |
| 2 | Browse and filter spending history | Understand spending for a selected day, week, or month and category. | `browse-history` |
| 3 | Correct and remove expenses safely | Fix a saved expense or deliberately remove it without corrupting history. | `maintain-expenses` |
| 4 | Customize categories without losing history | Adapt expense organization while preserving all existing records. | `manage-categories` |
| 5 | Manage appearance and understand device-only storage | Choose how the app looks and understand its currency, storage, and recovery limits. | `app-preferences` |

These names are suggestions, not allocated branch names. No branch numbers or formal specifications are created by this document.

## Evidence and authority

Read for this proposal:

- [Application idea and scope](expense-tracker-summary.md), especially Version 1 and Scope Limits.
- [Approved screen direction](superpowers/specs/2026-11-03-expense-tracker-screens-design.md), including its approval status, navigation, all screen flows, proposed defaults, and limitations.
- [Constitution v1.0.0](../.specify/memory/constitution.md), ratified 2026-11-03.
- Light-theme screen-board capture and dark-theme category-editor capture listed in the screen document.

The application summary's final sentence still says visual design is not approved. The later screen document explicitly records approval on 2026-11-03, and the constitution recognizes that approved direction. Use the approved direction while retaining the screen document's distinction: the written specification and proposed defaults still need review. No source document was changed to resolve this stale wording.

The constitution is binding engineering policy. Scope comes from the summary and constitution; screen relationships come from the approved design. Prototype examples, sample dates, floating-point arithmetic, browser state, and review-only controls are not production requirements.

## Feature 1 — Record expenses and see current spending

**Job:** When I spend money, I want to record it quickly so that I can see what I spent today and retain the record after closing the app.

### Owns

- First launch without registration or mandatory onboarding.
- Built-in categories: Food & drinks, Transport, Shopping, Bills, Health, and protected Other. Establish stable identities and initialize defaults without recreating them on every launch.
- Add expense: PKR amount, category, local calendar date, optional note; today is the default when there is no selected-day context.
- Successful durable save, repeat-tap protection, success feedback, and return to the originating available screen.
- Overview: today's total/count/list, current-month total, and entry into expense details.
- Read-only details: amount, category, date, note or “No note added,” and local-storage label.
- Genuine first-use versus an empty today with earlier history; explicit device-only and no-recovery disclosure from first use.
- Retained input and retry on save failure; read failures distinct from empty data; confirmation before discarding changed entry forms.

### Does not own

Historical period browsing/filtering, expense editing/deletion, custom category management, or manual appearance selection. Do not introduce temporary production controls that pretend those unfinished flows work.

### Independent acceptance examples

- With an empty local store, the person sees zero spending, the first-entry action, built-in categories, and the local-only/no-recovery notice without connecting to a network.
- Save PKR 650.25 for today in Food & drinks. It appears once in Overview and details; today's total/count and this month's total reflect it. Terminate and reopen the app: the same record remains.
- Save an allowed earlier-date expense: it remains accessible through its subsequent history flow and does not incorrectly increase today's total. Its inclusion in the current-month total follows its date. Before History exists, verify the saved record using the feature's local behavior tests rather than inventing another UI route.
- Repeated save taps create one record. A failed save retains all fields and shows retry without success feedback; a failed read never displays “No expenses yet.”
- Cancel a changed entry: Keep editing retains the draft; Discard leaves saved data unchanged.

**Dependencies:** None on another product feature. Stack/OS approval is required before production scaffolding, not before drafting this specification. Exact money, durable local storage, offline assets, navigation foundations, and storage/privacy protections are enabling tasks here—not separate user-facing features.

**Sources:** Screen sections 2, 4 (Overview/Add), 6 (details), 7 (first use), and 9; constitution I–V.

## Feature 2 — Browse and filter spending history

**Job:** When I want to understand past spending, I want to browse a meaningful period and category so that I can see the relevant entries and accurate totals together.

### Owns

- Day/Week/Month controls, readable period labels, previous/next navigation, and reset to the current period when range type changes.
- Selected-period total/count, entries grouped by date, and date subtotals derived from the same selected records.
- Visible category filter, All categories, and clear-filter behavior. Historical categories must remain usable as filters even when archived.
- Overview-to-History navigation and history-row-to-details navigation.
- Add-entry integration: a selected day supplies the default date; a week/month or unrelated entry must not inherit a stale selected-day date. Return to History after saving and refresh the relevant data without implying that an out-of-range entry belongs in the current result.
- Empty selected period, no filter matches, Go to today, and read-failure states that preserve the distinction between no results and unavailable data.

### Independent acceptance examples

- Given known entries across day, week, month, and year boundaries, each range shows exactly the included records, matching count, daily subtotals, and total.
- Filter by an active or archived category: list, count, and totals change together. Clear the filter: the full selected-period result returns.
- Switch Month to Week: select the current week rather than carrying the old month's position forward.
- Start Add expense from a selected day: that date is prefilled. Start an unrelated new entry afterward: the old day is not reused.
- Zero matching records produces zero totals and the correct empty-state action. A load failure produces an actionable error instead.

**Dependencies:** Feature 1's expense/category contracts and entry/detail flows. Archived-category behavior can be tested with fixtures before Feature 4 exists; the actual archive-to-filter journey is then an integration test.

**Sources:** Screen sections 4 (History) and 7 (empty states); constitution II, III, and V.

## Feature 3 — Correct and remove expenses safely

**Job:** When a saved entry is wrong or unnecessary, I want to correct or remove that specific entry without duplicating it or damaging other records.

### Owns

- Edit and Delete actions from details; prefilled editing of amount/category/date/note.
- Updating the same record, not creating a replacement or duplicate.
- Keeping an expense's existing archived category during editing, visibly labeled as archived; archived categories are not offered as new assignments.
- Changed-form discard confirmation, retained input on failure, and duplicate-submit protection.
- Delete confirmation naming the note/category, amount, and date; safe cancellation; explicit irreversible removal only after confirmation and successful persistence.
- Correct return to details after editing or the originating available list after deletion; recalculation of every affected Overview/History total, count, date grouping, and category count.

### Independent acceptance examples

- Given a saved expense, change its amount and move it across a month boundary. Its identity is unchanged, the record count does not increase, and old/new period totals change exactly once.
- Cancel editing and choose Keep editing: retain the draft. Choose Discard: keep the original saved expense.
- Cancel deletion: nothing changes. Confirm deletion: only the named record is removed, and the change survives restart.
- Fail an edit or deletion write: the previous saved state and related totals remain consistent; show an actionable failure, not a success message.
- An expense assigned to an archived category can retain that category; another archived category cannot be newly assigned.

**Dependencies:** Feature 1. Full visible History regression coverage uses Feature 2. Archived-category acceptance can run with fixtures; verify the complete archive/edit journey after Feature 4.

**Sources:** Screen sections 5 (archived selections), 6, and 9; constitution II–V.

## Feature 4 — Customize categories without losing history

**Job:** When the default categories do not fit my spending, I want to tailor them while keeping earlier expenses intact and understandable.

### Owns

- Active category list with names, icons, and recorded expense counts; separate archived list when present.
- Add/edit form, labeled icon selection, preview, name validation, retained input, and changed-form discard protection.
- Rename/icon changes on the same category identity, reflected on existing expenses without changing expense amounts or dates.
- Confirmed archiving, restoration, and consistent new-entry choices.
- Protected Other: cannot rename or archive; icon can change. Explain and disable unavailable operations rather than waiting for a failed submission.
- No category deletion, cascading expense deletion, or silent reassignment of history.

### Independent acceptance examples

- Create Education, save an expense against it, then rename it: existing expenses display the new label and retain their identity, amount, and date.
- Archive a category with expenses: those expenses and all spending totals remain unchanged; the category disappears from new-entry choices but remains available for historical filtering.
- Restore it: it becomes selectable for new entries again; archive/restore survives restart.
- Other remains active with its protected name. Its icon can be changed.
- Invalid/duplicate names, cancelled archive confirmation, and failed category writes leave saved records consistent and preserve editable input as appropriate.

**Dependencies:** Feature 1's stable category identities and default categories. Features 2/3 supply the end-to-end filter/edit integration surfaces, not a prerequisite for testing category lifecycle rules with fixture records.

**Sources:** Screen section 5 and section 9; constitution III–V.

## Feature 5 — Manage appearance and understand device-only storage

**Job:** When I adjust the app or check its limitations, I want clear local preferences and honest storage information without risking my spending data.

### Owns

- Settings reached from Overview, with predictable return navigation.
- Appearance choices: Use device setting, Light, Dark; persist the local preference and apply it consistently across available screens.
- Read-only PKR currency description, no-account/no-cloud explanation, prominent no-recovery warning, and explicit absence of backup/restore.
- App name and actual installed version, rather than the prototype's sample version.
- Preference load/save failures presented honestly; appearance changes cannot modify expense history.

### Independent acceptance examples

- Select Dark, restart, and reopen Settings: the saved preference remains applied; expense/category data is unchanged.
- Select Use device setting and change the device theme: the app follows it. An explicit Light/Dark selection overrides the device theme.
- Settings states the consequences of phone loss, uninstalling, and clearing data, and exposes no sign-in, bank, cloud, backup, or restore controls.
- Preference-write failure does not claim the choice was durably saved or alter saved financial records.

**Dependencies:** Feature 1's Overview navigation and shared presentation foundations. Other feature screens join the appearance integration test as they become available.

**Important boundary:** This feature owns the preference selector and comprehensive Settings content. It does not defer first-use disclosures, privacy enforcement, offline operation, or accessible light/dark rendering from earlier features.

**Sources:** Screen section 7 (Settings); constitution I, III, and IV.

## Sequence and independent testing

Recommended sequence: **Record → History → Maintain expenses → Categories → Preferences.** This produces a usable recording slice first, then historical visibility, correction, customization, and preference control. Preferences may be delivered earlier if desired; its UI is not a dependency of History, correction, or categories.

After Record, History, Maintain expenses, Categories, and Preferences all depend on shared contracts, not necessarily on each other's management UI. Use approved test fixtures to exercise known records, archived categories, dates, and failures. Fixture-based acceptance does not substitute for the final integrated journeys.

“Independently testable” means each feature has observable acceptance criteria and controlled test data without needing a person to perform every earlier workflow. It does **not** mean each feature is a standalone app or can ignore shared expense/category rules.

Agree on the small shared domain contract in the first specification and carry it forward: expense identity, exact PKR amount, local calendar date, optional note, stable category identity, and category active/archive status. Detailed technical interfaces belong in planning; later specs must not silently redefine earlier approved rules.

## All twelve design frames accounted for

| Design screen/state | Feature owner |
| --- | --- |
| Overview | Record |
| Add expense | Record; History contributes selected-day context |
| History | History |
| Categories | Categories |
| Add/edit category | Categories |
| Expense details | Record supplies read-only view; Maintain adds actions |
| Edit expense | Maintain expenses |
| Settings | Preferences |
| First use | Record |
| Empty history | History; Record owns empty-today/first-use distinctions |
| Delete confirmation | Maintain expenses |
| Form feedback | Each feature owns its own validation, persistence failure, and retry states |

## Requirements that travel with every affected feature

Do not create standalone “database,” “validation,” “accessibility,” “error handling,” or “offline mode” product features. These are implementation responsibilities and acceptance obligations within the relevant slice.

- **Privacy:** no network/account dependency, telemetry containing financial data, or network-only fonts/assets. Non-sensitive diagnostic output only. Review and configure platform backup/device-transfer behavior to uphold device-only storage; unresolved limitations block release.
- **Money and dates:** exact PKR arithmetic, no silent rounding/truncation, at most two fractional digits, consistent record sets for all displayed calculations, and local calendar dates that do not shift existing expenses after timezone changes.
- **Durability:** acknowledge only persisted success; all-or-nothing mutations; restart persistence; no silent resets; actionable errors. Versioned, data-preserving migration strategy and tests whenever schema changes affect existing data.
- **Interaction:** accessible labels, safe back/cancel, discard confirmation, duplicate-submit prevention, keyboard/safe-area handling, light/dark contrast, large text, reduced motion, and platform touch-target sizes.
- **Evidence:** failing behavioral tests before implementation; fresh acceptance/regression evidence. Native offline core-flow checks on Android and iOS for release; identify emulator/simulator versus physical-device evidence and skipped checks.
- **Performance:** affected specifications must define measurable responsiveness/scale criteria with device class, dataset size, and scenario. No invented or unmeasured promise of “instant” behavior.

## Decisions to resolve without inventing scope

| Decision | Status in current sources | Resolve before |
| --- | --- | --- |
| Maximum expense amount, accepted input/formatting, overflow behavior | Positive values and at most two decimal places are binding; the proposed upper bound is not approved. Resolve exact formatting and rejection behavior. | Record planning |
| Future-dated expenses | Screen study proposes today or earlier; not an approved product rule yet. | Record planning |
| Note length | 80 characters proposed, not approved. | Record planning |
| Week start and exact period boundaries | Monday–Sunday proposed; local calendar dates are binding. Define boundaries and calendar behavior explicitly. | History planning; Record must already preserve date identity |
| Category names and uniqueness | Trimmed 1–30 characters and case-insensitive uniqueness across active/archived categories are proposed. | Categories planning; earlier specs must not hard-code conflicting assumptions |
| Local-data responsiveness/scale targets | Required, but device class, record volume, and timing targets are not yet agreed. | Planning each affected feature; targets belong in its specification |
| Stack, minimum OS versions, persistence/testing choices | No approved stack or OS floor. Obtain explicit owner approval before production scaffolding; record consequential architecture decisions. | First production scaffolding |
| Platform backup/device transfer | Off-device expense copies are prohibited by the constitution; platform settings and limitations require verification. This is not an optional feature choice. | Configure from the first persistence implementation; verify before release |

These are targeted specification/planning gates, not a reason to ask the owner to redesign the entire application now. Do not confuse the proposed defaults with approved visual direction.

## Exclusions remain unchanged

No income, budgets, balances/savings metrics, receipt scanning, bank connections, multiple currencies, accounts, backend/cloud synchronization, or manual backup/restore. No charts are required by the approved V1 screens. No mandatory onboarding carousel. Do not add category deletion or reset-history controls.

## Suggested next command

After reviewing the feature boundaries, start with this description:

```text
/sp.specify Record personal expenses offline in PKR using built-in categories, a local calendar date, and an optional note. Include first-use and empty-today states, durable duplicate-safe expense creation, read-only expense details, today's total/count/list, this month's total, and clear device-only/no-recovery notices. Retain input and support retry after save failures, distinguish read failures from empty data, and confirm discarding changed forms. Exclude historical period browsing and filtering, expense editing/deletion, custom category management, and manual appearance selection from this feature. Follow the constitution and approved screen direction; resolve proposed amount/date/note rules explicitly rather than assuming approval.
```

Keep each subsequent feature in its own `/sp.specify` cycle. Follow with `/sp.clarify` where needed, then `/sp.plan`, `/sp.tasks`, and `/sp.implement` for that feature. Carry dependencies and shared obligations forward; completing the first feature does not waive the remaining V1 requirements or authorize release.
