# Feature Specification: Record expenses and see current spending

**Feature Branch**: `001-record-expenses`  
**Created**: 2026-11-04  
**Status**: Ready for planning — product clarifications resolved on 2026-11-04  
**Input**: User description: "@docs/expense-tracker-feature-map.md let write the specs for Feature 1 — Record expenses and see current spending"

## Clarifications

### Session 2026-11-04

- Q: What should happen if the person presses Back/Cancel while saving? → A: Offer cancellation of the pending save. Confirm cancellation only if no expense was persisted; otherwise report that it was saved (option C).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Record an expense and trust the saved result (Priority: P1)

As a person tracking personal spending, I want to record a PKR expense offline and immediately see accurate spending so that I can trust the record without an account or internet connection.

**Why this priority**: Durable expense entry and correct spending are the smallest useful outcome of this feature.

**Independent Test**: On an offline installation, save an expense, inspect Overview and its details, terminate the app, and reopen it. The expense must exist exactly once with matching values and totals. Earlier records and built-in categories can be supplied as controlled test data without another feature's interface.

**Acceptance Scenarios**:

1. **Given** a working local store with no expenses, **When** the person records PKR 650.25 for today in Food & drinks with the note Lunch, **Then** persisted success returns them to Overview, today's list contains the entry once, today's count is 1, and today's and this month's totals are PKR 650.25.
2. **Given** the saved entry above, **When** the app is terminated and reopened offline, **Then** the same expense identity, amount, category, date, and note remain, and totals have not changed.
3. **Given** a valid completed form, **When** Save is tapped repeatedly while saving or a failed attempt is retried, **Then** at most one expense is created for that submission; success is announced only after durable storage is confirmed. If the first attempt actually persisted before interruption, retry must not create a second expense.
4. **Given** an existing expense of PKR 0.10 today, **When** PKR 0.20 is recorded today, **Then** today's total is exactly PKR 0.30, the count is 2, and no extra fractional digits appear.
5. **Given** a working store and an allowed date earlier in the current month, **When** an expense is saved for that date, **Then** it is durably retained and included in this month's total, but not today's count, total, or list. Success identifies the saved date so an absent today-row does not imply save failure.
6. **Given** an allowed date outside the current month, **When** an expense is saved for that date, **Then** neither today's spending nor this month's spending increases. Retention is verified through local behavior tests until History is available; this feature adds no temporary historical browsing route.
7. **Given** two separate deliberate entries with identical field values, **When** each new form is saved once, **Then** two distinct expenses are retained; repeat-submit protection must not prohibit genuine repeated purchases.

---

### User Story 2 - Understand current spending and individual records (Priority: P1)

As a person checking spending, I want today's total, count, and entries together with this month's total and read-only details so that I can understand what the amounts represent.

**Why this priority**: Entry is only trustworthy if recorded amounts and their summaries agree.

**Independent Test**: Supply expenses across day, month, and year boundaries, open Overview and a today-row, and compare the displayed information with the known records. No History, edit, or category-management interface is needed.

**Acceptance Scenarios**:

1. **Given** PKR 100.10 and PKR 200.20 today, PKR 50.05 earlier this month, and PKR 900.00 in the previous month, **When** Overview opens, **Then** today's total is PKR 300.30 with count 2 and exactly those two entries; this month's total is PKR 350.35.
2. **Given** today's entry with a note, **When** its row is opened, **Then** read-only details show its exact amount, category name and icon, calendar date, note, and device-only storage label. Back returns to Overview without changing the record.
3. **Given** today's entry without a note, **When** it appears in Overview and details, **Then** its row uses its category name as the title and details say No note added.
4. **Given** earlier history but no expenses today, **When** Overview opens, **Then** it says No expenses today, shows zero for today's total/count, keeps the correct current-month total, and does not say No expenses yet or claim history was erased.
5. **Given** the app remains open across local midnight or is resumed after the month changes, **When** Overview is shown again, **Then** the date and summaries reflect the current local day and month without changing saved expense dates.
6. **Given** saved expenses and a subsequent device-timezone change, **When** the app reopens, **Then** each saved date stays unchanged; inclusion in today/current month follows that date and the device's newly current local day/month.

---

### User Story 3 - Start with clear privacy and recovery expectations (Priority: P1)

As a first-time user, I want to start recording immediately and understand where records live so that I do not mistake device-only privacy for a recovery service.

**Why this priority**: These disclosures cannot wait for the later Settings feature; there is no recovery path in V1.

**Independent Test**: Launch a clean installation without connectivity. Verify the initial state, disclosures, category choices, and successful first-entry journey; reopen repeatedly to check that initialization preserves existing state.

**Acceptance Scenarios**:

1. **Given** a new installation with a confirmed empty store, **When** it starts offline, **Then** Overview shows the current date, zero spending/count, No expenses yet, a brief entry explanation, and Add your first expense, with no registration or mandatory onboarding carousel.
2. **Given** first use, **When** the initial state is displayed, **Then** readable content explains that records stay on this device, there is no account/cloud synchronization or backup/restore, and phone loss, uninstalling, or clearing app data may permanently erase history with no recovery in V1.
3. **Given** first use, **When** the entry form opens, **Then** Food & drinks, Transport, Shopping, Bills, Health, and protected Other are available. Repeated launches neither duplicate nor replace these identities or existing data.
4. **Given** an expense earlier than today was the first saved expense, **When** Overview is shown, **Then** the state changes from no expenses ever recorded to no expenses today, while retaining the device-only reminder and correct month total.

---

### User Story 4 - Recover from mistakes and storage failures safely (Priority: P1)

As a person entering spending, I want validation, safe cancellation, and honest retry behavior so that an error does not lose my input or corrupt saved history.

**Why this priority**: A local-only tracker cannot repair careless data loss through cloud recovery.

**Independent Test**: Supply invalid inputs and controlled read/write failures and inspect form contents, saved records, totals, announcements, and cancellation behavior.

**Acceptance Scenarios**:

1. **Given** blank, zero, negative, malformed, over-precision, or over-limit amount input, **When** Save is attempted, **Then** no expense is created, the amount field explains the accepted rule, input remains editable, and focus moves to the first invalid field.
2. **Given** a completed form, **When** the save fails, **Then** all entered fields remain, an actionable error and Retry are available, no success is shown, and existing records and totals remain unchanged.
3. **Given** a read failure at startup or refresh, **When** Overview attempts to load data, **Then** it shows an unavailable-data error and Retry rather than zero spending or a genuine-empty message. Previously loaded values, if retained, are explicitly marked unavailable/stale rather than presented as current.
4. **Given** a changed unsaved form with no save pending, **When** Back or Cancel is used, **Then** Discard expense changes? offers Keep editing and Discard changes; Keep editing preserves all input, while Discard changes returns to the origin without saving. Cancelling the confirmation keeps the draft.
5. **Given** a form identical to its initial values, **When** Back or Cancel is used, **Then** it returns directly without confirmation or saved-data changes. Changing a value and restoring the complete original form also counts as unchanged.
6. **Given** category initialization cannot be durably completed, **When** the app starts, **Then** it offers an actionable initialization error and retry; it does not invent empty history, create repeated categories, or allow an expense with a missing category relationship.
7. **Given** a known saved expense, **When** details cannot be loaded, **Then** an error and retry/back actions appear rather than a fabricated empty record, success message, or deletion claim.
8. **Given** otherwise valid forms, **When** amounts 0.01 and 999999999.00 are submitted separately, **Then** both are accepted exactly; amounts 0.00 and 999999999.01 are rejected without creating records or changing saved totals.
9. **Given** the device's current local date, **When** today or yesterday is submitted on otherwise valid forms, **Then** each is accepted; tomorrow is unavailable in the date selector and rejected with a date-field error if supplied through another route, preserving all input.
10. **Given** a draft whose selected date becomes tomorrow after a device-date or timezone change, **When** Save is attempted, **Then** the date-field error requires correction without changing the selected date or other input automatically. Existing saved expense dates remain unchanged.
11. **Given** otherwise valid forms with notes of exactly 200 user-perceived characters, including combined letters and multi-part emoji, **When** each is saved and reopened, **Then** the note is retained exactly; a 201-character note produces a field error, creates no expense, and remains fully editable without truncation.
12. **Given** empty or whitespace-only notes, **When** otherwise valid expenses are saved, **Then** they save without a note and details show No note added. For nonblank notes, spaces and line breaks count toward the 200-character boundary and survive saving unchanged.
13. **Given** a save in progress that has not persisted, **When** the person requests cancellation through Back/Cancel and cancellation succeeds, **Then** cancellation is confirmed only after the pending submission can no longer persist, the app returns to the origin, and no expense is added immediately or later, including after restart.
14. **Given** a save that persists before cancellation takes effect, **When** the person requests cancellation, **Then** the app reports that the expense was saved, returns to the origin, and reflects exactly one expense in affected summaries without claiming it was discarded.
15. **Given** a cancellation request whose save outcome cannot yet be determined, **When** reconciliation is pending or fails, **Then** the form remains available with checking status or an actionable reconciliation retry, duplicate submission is prevented, and neither cancellation nor saved success is confirmed until the actual outcome is established.

### Edge Cases

- Amount boundaries include accepted PKR 0.01 and PKR 999,999,999.00, rejected PKR 0.00 and PKR 999,999,999.01, and very long numeric input. Unsupported precision such as 1.001 is rejected, not rounded. Blank, zero, negative, exponent notation, currency text, grouping characters, and multiple decimal separators are invalid input.
- Exact totals must remain correct when many valid expenses together exceed the maximum allowed for one expense. A total must never wrap, silently round, or be clipped to that per-expense maximum; an unrepresentable total is an explicit calculation error, not a plausible incorrect value.
- Dates include leap days, invalid dates, the first/last day of a month/year, and local midnight while a draft is open. A draft's selected date does not silently change at midnight; a newly opened unrelated form uses the new today.
- Future dates are rejected using the current local date at submission, including when device-date or timezone changes make the draft's date future-dated. Saved expense dates are never rewritten by this validation.
- Note tests include empty and whitespace-only values, mixed scripts, combined letters, multi-part emoji, spaces, and line breaks. Exactly 200 user-perceived characters are accepted; 201 are rejected with retained input, never silently truncated.
- A successful save followed by an Overview refresh failure remains a saved expense: communicate saved success separately from unavailable summaries and do not invite resubmission as though the write failed.
- App interruption before a save completes leaves either one complete expense or no new expense, never a partial record. On reopening, display actual saved state; automatic recovery of an unsaved draft after termination is not promised.
- Cancellation may race with persistence: confirmed cancellation guarantees the pending submission cannot later create an expense; if persistence wins, report saved success instead. An unknown outcome must be reconciled without ordinary draft-discard claims or duplicate submission.
- Failed reads, existing-store corruption, and partial initialization must not trigger store replacement, default-data recreation over existing data, or automatic deletion. Retry must use the existing store.
- Existing fixture categories can be archived: they remain readable on saved expenses but cannot be newly selected. Other must stay active and available. No category lifecycle controls are introduced here.
- Large text, long notes/category labels, long totals, landscape, keyboard-open forms, and both themes must not hide Save, errors, labels, Back, or confirmation actions.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The person MUST be able to launch, record an expense, view Overview/details, and retry available operations offline from first launch on Android and iPhone, without registration, mandatory onboarding, or network-dependent assets.
- **FR-002**: Initialization MUST establish stable identities for Food & drinks, Transport, Shopping, Bills, Health, and Other exactly once. Other MUST remain active with its protected name; subsequent launches MUST preserve existing categories and expenses rather than reseeding over them.
- **FR-003**: Add expense MUST provide labeled PKR amount, active category selection, local calendar date, optional note, Save, and Back/Cancel. Amount and an explicit category selection are required; no category is silently preselected. The default date is today unless a later available selected-day flow explicitly supplies a date. New unrelated entries MUST NOT inherit stale date/category/note values from a prior entry.
- **FR-004**: Amount MUST be positive PKR with at most two fractional digits, from PKR 0.01 through PKR 999,999,999.00 inclusive per expense. Amounts below or above these bounds MUST be rejected with a field error before saving, without rounding or truncation.
- **FR-005**: Amount entry MUST trim outer whitespace and accept ordinary digits with an optional period followed by one or two fractional digits, with at least one digit before the period. Group separators, signs, exponent notation, currency text, internal spaces, incomplete decimals, and unsupported precision MUST produce field errors. Values MUST NOT be silently rounded or truncated. User-facing saved amounts MUST show PKR, comma thousands grouping, a period decimal separator, and exactly two fractional digits consistently across summaries, rows, and details.
- **FR-006**: Individual amounts and all totals MUST remain exact. Values outside the approved per-expense bound MUST be rejected before saving. Totals MAY exceed that individual bound and MUST remain exact through at least the acceptance dataset in SC-002; if a calculation cannot be represented, the app MUST show an actionable calculation error instead of a wrapped, rounded, or misleading numeric result.
- **FR-007**: Expense dates MUST represent valid Gregorian local calendar dates, remain unchanged after timezone changes, and not be derived from elapsed 24-hour periods. Today is the device's current local calendar date. Today's range includes exactly that date; this month's range includes the first day of the current local month and excludes the first day of the next month. Earlier valid dates MUST be accepted without an invented retention cutoff.
- **FR-008**: Expense dates MUST be today or an earlier valid local calendar date. Future dates MUST NOT be offered as selectable dates and MUST be rejected with a date-field error if supplied by another input route. The selected date MUST be validated against the device's current local date at submission; a date that has become future-dated because the device date or timezone changed MUST require correction, without silently altering the draft.
- **FR-009**: The note MUST be optional and allow up to 200 user-perceived characters inclusive, counting a combined letter or emoji sequence as one character. Blank or whitespace-only input is stored as no note; for nonblank input, the complete entered text, including spaces and line breaks, counts toward the limit and is preserved. A note longer than 200 characters MUST produce a field error and prevent saving until corrected, while retaining all entered fields without silent truncation.
- **FR-010**: Save MUST create one complete expense with a stable identity and valid category relationship, with all-or-nothing persistence. The person MUST receive immediate saving feedback without layout shifts or duplicate submissions; persisted success returns to the originating available screen, refreshes affected summaries, and announces the saved result/date. A fresh form MAY intentionally save another expense with identical values.
- **FR-011**: A reported successful write MUST survive termination and restart. A failed write MUST preserve the entire editable form, show an actionable error and retry, leave saved records consistent, and never announce success. An uncertain/interrupted outcome MUST be reconciled without creating duplicates. Back/Cancel during an in-progress save MUST offer cancellation of that pending submission. The app MUST confirm cancellation only after establishing that no expense was persisted and the pending submission cannot subsequently persist; it then returns to the origin without a new expense. If persistence has already succeeded, the app MUST report the expense as saved, return to the origin, and refresh affected summaries rather than claim cancellation. While the outcome remains unknown, the app MUST retain the form, communicate that the result is being checked, prevent a duplicate submission, and offer reconciliation retry if checking fails; it MUST NOT claim either saved success or confirmed cancellation.
- **FR-012**: Overview MUST show the current local date, today's exact total/count/list, and the current month's exact total. Today's list MUST show all today's entries, newest saved first with stable ordering, each with category icon/name, note or category-name fallback, and amount. List, count, and total MUST use the same records and update after a successful save or day/month change when Overview is shown/resumed.
- **FR-013**: Selecting a today-row MUST open read-only details for that expense, showing amount, category icon/name, expense date, note or No note added, and device-only label. Back MUST return predictably without changes. Edit/Delete controls MUST NOT be offered until their owning feature is implemented.
- **FR-014**: The app MUST distinguish a confirmed store with no expenses from no expenses today with earlier history, and from unavailable data. Genuine first use MUST show zero totals/count, No expenses yet, an entry explanation, and Add your first expense. Empty today MUST show No expenses today, the correct month total, and an entry action without implying earlier records were removed or an unavailable History route already works.
- **FR-015**: Read and initialization failures MUST show errors and actionable retry without fabricating empty data or resetting an existing store. Failed detail reads MUST support retry/back. A post-save refresh failure MUST NOT turn a successful write into a repeat-entry instruction.
- **FR-016**: When no save is pending, Back/Cancel from a changed form MUST request explicit discard confirmation with Keep editing as the safe default and Discard changes as the data-loss action. Keeping/cancelling MUST preserve the draft; discarding MUST leave saved records unchanged. Unchanged forms return directly. While a save or its outcome reconciliation is pending, FR-011's cancellation rules apply instead; the ordinary draft-discard flow MUST NOT claim to undo a persisted expense. Focus MUST be contained during confirmation and return sensibly afterward.
- **FR-017**: First use MUST visibly disclose device-only storage, no account/cloud sync, no backup/restore, and possible permanent history loss through phone loss, uninstalling, or clearing data, with no V1 recovery promise. Overview and details MUST retain concise device-only reminders. This obligation MUST NOT be deferred to Settings.
- **FR-018**: Expense/category data MUST stay in app-private device storage and MUST NOT be transmitted to remote services. Automatic platform backup/device transfer MUST be reviewed and configured to prevent off-device copies; unresolved platform conflicts block release. Diagnostics MUST exclude amounts, dates, notes, category names, user identifiers, and stored financial contents.
- **FR-019**: Screens MUST follow the approved visual direction in both light/dark device themes, use visible labels and accessible control states, meet normal-text contrast of at least 4.5:1, large-text contrast of 3:1, and meaningful non-text contrast of 3:1, and provide at least 44-point iOS/48-dp Android touch targets. All actions MUST work without color, icons, or gestures alone and support screen readers, system text scaling, reduced motion, safe areas, keyboard-open forms, and predictable native back behavior. Errors MUST appear beside fields with focus on the first invalid field; several errors MUST also have a linked summary.
- **FR-020**: Existing expense history, identities, category relationships, dates, and exact amounts MUST be preserved across application updates. Any change to the saved-data format MUST have a versioned, non-destructive upgrade strategy and preservation tests; failures MUST NOT trigger silent resets. Retention MUST NOT expire automatically.
- **FR-021**: Archived categories MUST remain associated with historical expenses and readable in details but unavailable for new assignments. This feature MUST NOT expose category rename/archive/restore/delete controls, silently reassign saved records, or cascade-delete expenses.
- **FR-022**: Navigation MUST expose working Overview, Add expense, and read-only details journeys only. It MUST NOT offer inert or simulated History, Categories, Settings, Edit, Delete, or appearance controls. Later features add their approved navigation and selected-day/origin-return integration without redefining this feature's saved expense/category rules.

### Constitution Alignment *(mandatory)*

Authority: [Constitution v1.0.0](../../.specify/memory/constitution.md). The [feature map](../../docs/expense-tracker-feature-map.md#feature-1--record-expenses-and-see-current-spending) supplies boundaries; the [approved screen direction](../../docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md) guides presentation. The later approved direction supersedes the summary's stale visual-approval sentence; proposed field limits are not thereby approved.

- **Scope / Principle VI**: FR-001–022 form the first recording slice, not the complete V1 release. Exclusions and implementation approvals are specified below. No framework, server, or persistence tool is selected here.
- **Privacy/offline / Principle I**: FR-001, FR-017, and FR-018 require offline assets, truthful disclosures, non-sensitive diagnostics, private local storage, and verified platform backup/transfer restrictions. No telemetry exception is implied.
- **Correctness / Principle II**: FR-004–009 and FR-012 define exact PKR, rejection/formatting, stable local dates, and today/month boundaries. The owner resolved the per-expense amount maximum, future-date policy, and note limit on 2026-11-04; the decisions and boundary scenarios are recorded here. Weekly boundaries and category filters are genuinely outside this feature and must be defined by History; Monday–Sunday is not adopted here.
- **Data safety / Principle III**: FR-002, FR-010–018, FR-020–021 cover durable atomic saving, retry, read failures, protected categories, migration preservation, and disclosures. Expense deletion and category lifecycle actions are absent; their confirmation/restoration journeys belong to later features. Comprehensive Settings content remains Feature 5, not a reason to omit first-use warnings.
- **Accessibility / Principle IV**: FR-003, FR-010, FR-016, and FR-019 make labels, feedback, themes, contrast, targets, keyboard/back behavior, and safe discarding mandatory from this slice.
- **Verification / Principle V**: Every numbered acceptance scenario and Edge Cases bullet MUST become a failing-first behavioral test before the affected behavior is implemented, or a named platform inspection where direct inspection is necessary. Story 1 covers exact money, submission safety, and restart; Story 2 covers ranges, summaries, and details; Story 3 covers initialization, offline startup, and notices; Story 4 covers errors, cancellation, and preservation. FR-018 backup/transfer settings and FR-019 accessibility require Android/iOS inspection evidence; FR-020 requires upgrade preservation tests whenever stored-data format changes. Planning/tasks must name the test/inspection for each scenario, requirement, and success criterion. Native offline release checks must identify emulator/simulator versus physical device and disclose skipped checks; prototype browser checks do not satisfy them.

### Scope and Unresolved Decisions *(mandatory)*

**Included**: First-use Overview, built-in categories, offline expense creation, today/month summaries, today's list, read-only details, safe entry cancellation, durable duplicate-safe save/retry, honest read failures, initial privacy protections, and accessible light/dark presentation.

**Excluded**: Historical period navigation/filtering; expense editing/deletion; custom category management; manual appearance preference/Settings interface; income, budgets, balances/savings, charts, receipt scanning, bank integration, other currencies, accounts, backend/cloud sync, manual backup/restore, category deletion, reset-history controls, and mandatory onboarding. Do not add a temporary way to browse earlier records before History exists.

**Resolved product decisions — 2026-11-04**: In response to Q1–Q3, the owner selected `1. A`, `2. A`, and `3. B`: (1) PKR 999,999,999.00 inclusive maximum per expense; (2) today or earlier only, with future dates rejected; (3) an optional-note maximum of 200 user-perceived characters inclusive. FR-004, FR-008, FR-009, and Story 4 scenarios 8–12 encode these decisions. The 200-character note rule supersedes the screen study's proposed 80 characters for this feature. No blocking product clarification remains; separate implementation approval gates below still apply.

**Documented defaults for this draft**: Period-based entry uses Gregorian local dates; categories require an explicit selection; accepted amount entry uses ungrouped digits and a period; saved amounts display two fractional digits; today's rows are newest-saved-first; the device theme supplies light/dark presentation until Feature 5. Drafts remain during validation, retry, and Keep editing but need not survive app termination. These defaults are specification decisions. The numeric targets in Success Criteria are binding acceptance targets to verify during implementation; they are not claims of prior screen-design approval or measured performance.

**Acceptance-target status — 2026-11-08**: The project owner confirmed through the analysis-remediation request that SC-001–SC-007 and the Performance baseline are binding acceptance targets for implementation and release, not proposals for later review. Any target change requires an explicit owner-approved specification amendment.

**Performance baseline**: For specification acceptance, use both an Android phone and an iPhone released during 2020–2022 with 4 GB memory, at least 1 GB free device storage, a supported OS version, and no network connection. Measure with 10,000 saved expenses spanning 24 months, including 500 today, and all six built-in categories; include repeated maximum-approved amounts for correctness checks. Record actual device/OS and whether evidence uses physical hardware or an emulator/simulator. Planning must select concrete representative devices and an owner-approved OS floor without weakening these targets silently.

**Dependencies and approval gates**: No other product feature is required. Exact money, durable local saving, navigation, packaged assets, and storage/privacy controls are enabling work within this slice. The stack, minimum OS versions, persistence/testing tools, and consequential architecture choices need separate explicit owner approval before production scaffolding. No selection is inferred from the prototype. History, maintenance, categories, and preferences must preserve the shared entity rules and complete their integration journeys later; this spec does not authorize a full V1 release.

### Key Entities *(include if feature involves data)*

- **Expense**: One personal spending record with a stable identity, exact positive PKR amount, stable category reference, local calendar expense date, and optional note. Two deliberate identical purchases are distinct expenses. Its expense date is independent of save time/order.
- **Category**: A stable identity with a display name, offline icon, and active/archived status. Six categories are initialized; Other has protected active/name status. Historical references survive later name/icon/status changes; archived categories cannot be assigned to new expenses.
- **Entry draft**: Unsaved amount, category, date, note, originating available screen, and changed/saving/error state. A draft is not counted as spending; keeping it after an error cannot create a saved record by itself.
- **Spending summary**: Today's total/count/list and current-month total derived from the same saved record sets for their respective calendar ranges. It is not a balance, budget, or separate source of financial truth.

## Success Criteria *(mandatory)*

### Measurable Outcomes

These are binding acceptance targets to verify during implementation, not measurements of an existing application. They are not provisional proposals.

- **SC-001**: In a task study with 10 people unfamiliar with the app, at least 9 can independently record a supplied valid today expense and find its details within 30 seconds from Overview, after the app is ready, without assistance or a network connection.
- **SC-002**: On each representative device and the dataset defined above, over 30 offline trials, at least 29 cold launches show correct Overview content within 2 seconds of launch; at least 29 valid saves show durable success and refreshed Overview within 1 second of Save; at least 29 today-row selections show correct details within 500 milliseconds. Pressed/saving feedback appears within 100 milliseconds in at least 29 save trials. Scrolling through today's 500 rows must leave every entry reachable without truncating the dataset.
- **SC-003**: Across all amount/date boundary fixtures and the 10,000-expense dataset, 100% of displayed totals/counts and detail values match the expected saved records exactly, including totals above one expense's approved maximum; no timezone change alters a saved expense date.
- **SC-004**: Across at least 100 successful saves followed by termination/restart, 100% retain exactly one complete expense per deliberate submission. Controlled interrupted writes/retries and repeated-tap tests produce zero partial records, unintended duplicates, or changes to earlier records.
- **SC-005**: Across every controlled read, initialization, calculation, and write failure test, 100% report an actionable error without a false-empty state, false success, silent reset, or lost in-session form input. All discard-cancellation tests preserve the draft, and confirmed-discard tests preserve saved history.
- **SC-006**: Both Android and iPhone pass the first-launch, add, Overview, details, cancellation, retry, and restart journeys offline. Required screens pass the specified light/dark contrast, platform target sizes, screen-reader labeling/order, portrait/landscape, 200% text or the platform's maximum if lower, reduced-motion, keyboard-open, and safe-area inspections with zero blocked essential actions. Broader supported system text sizes remain covered by FR-019.
- **SC-007**: In the 10-person study, at least 9 correctly explain after first use that records stay on the device and cannot be recovered by this app after phone loss/uninstall/data clearing. Runtime inspection finds zero outbound financial-data transfers or sensitive diagnostic contents; platform backup/transfer configuration evidence has no unresolved device-only conflict before release.
