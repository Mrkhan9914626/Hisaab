<!--
Sync Impact Report
Version change: 1.0.0 -> 2.0.0 (MAJOR)

Modified principles:
- IV. Accessible, Deliberate Mobile Interaction -> IV. Accessible Android Interaction
  (scope narrowed from Android + iPhone to Android only; iOS touch targets and
  platform parity removed)
- VI. Minimal Scope and Explicit Decisions -> V. Minimal Scope and Source-Code Focus
  (renumbered from VI; adds Android-only and source-code-only delivery rules)
- V. Test-First Verification -> REMOVED (automated test authoring is no longer required)

Unchanged titles (obligations adjusted):
- I. Offline-First Privacy (Android-only wording; iOS references removed)
- II. Exact Money and Consistent History (remaining test references removed)
- III. Durable, History-Preserving Storage (automated-test/migration-test mandate removed;
  durability and data-preservation rules retained)

Added sections: none

Removed sections:
- Principle V. Test-First Verification
- Automated-test and test-first gates in the development workflow

Templates requiring updates:
- ✅ UPDATED: .specify/templates/plan-template.md
- ✅ UPDATED: .specify/templates/spec-template.md
- ✅ UPDATED: .specify/templates/tasks-template.md
- ✅ UPDATED: .claude/commands/sp.tasks.md
- ✅ UPDATED: .claude/commands/sp.implement.md
- ✅ REVIEWED: .claude/commands/sp.constitution.md, sp.plan.md, sp.specify.md
  (no further changes required)
- ✅ UPDATED: CLAUDE.md, README.md, docs/expense-tracker-summary.md
- ⚠ PENDING (historical records retained, owner decision required):
  docs/adr/0001-approved-mobile-stack-and-platform-floors.md,
  docs/adr/0002-protected-sqlite-and-save-coordinator.md,
  docs/expense-tracker-feature-map.md, specs/001-record-expenses/*.
  These describe the previous Android + iPhone and test-first scope; they are not
  rewritten here so history remains auditable.
- NOT PRESENT: .specify/templates/commands/ (actual commands live in .claude/commands/)

Deferred placeholders: none.
Follow-up decisions: the owner may archive or remove legacy iOS source
(app/ios/) and iOS CI references; no constitution placeholder depends on that choice.
-->
# Personal Expense Tracker Constitution

## Core Principles

### I. Offline-First Privacy

- All V1 expense entry, browsing, editing, category management, and settings MUST work
  without a network connection, account, or server.
- Expense records and preferences MUST remain in application-private device storage.
  The app MUST NOT transmit financial data, notes, categories, or user identifiers to
  analytics, advertising, crash-reporting, or other remote services.
- Required fonts and interface assets MUST be available offline. V1 MUST NOT introduce
  network-dependent startup or permissions unrelated to its local tracking workflows.
- Platform-managed backup and device-transfer behavior MUST be explicitly reviewed and
  configured to prevent automatic off-device copies of expense data in V1. Release
  evidence MUST document the Android backup and data-extraction settings and any
  platform limitations; an unresolved conflict with device-only storage blocks release.
- Diagnostic output MUST exclude expense amounts, dates, notes, category names, and
  database contents. Error codes and non-sensitive operational context are permitted.

**Rationale:** Device-only storage is a product promise, not merely the absence of a
custom synchronization service.

### II. Exact Money and Consistent History

- V1 MUST store, calculate, and display expenses in PKR only. Persisted monetary values
  and all aggregations MUST use integer minor units or exact decimal arithmetic;
  binary floating-point money calculations are prohibited.
- Amount input MUST reject zero, negative, malformed, and unsupported-precision values.
  At most two fractional digits are permitted. Feature specifications MUST define and
  verify bounds, formatting, rounding policy, and overflow handling; input MUST NOT be
  silently rounded or truncated.
- For a given date range and category filter, totals, subtotals, counts, and displayed
  entries MUST derive from the same records. An edit or deletion MUST update every
  affected view without double-counting or creating an unintended second expense.
- Expense dates MUST be interpreted as local calendar dates. Feature specifications
  MUST define inclusive/exclusive range boundaries and week-start behavior. Date
  handling MUST NOT silently move an expense to another day after timezone changes.

**Rationale:** A tracker that produces inconsistent or inexact totals cannot provide
reliable spending history.

### III. Durable, History-Preserving Storage

- Successful writes MUST survive app termination and restart. Expense changes and
  related data updates MUST be atomic or provide equivalent all-or-nothing guarantees.
  Success feedback MUST occur only after persistence succeeds.
- Failed reads MUST NOT appear as an empty history. Failed writes MUST retain user
  input, provide an actionable error, and leave saved records consistent. The app MUST
  NOT silently reset, replace, or discard an existing store after an error.
- Category identity MUST remain stable through renaming. Archiving MUST hide a category
  from new entries while preserving its existing expenses and allowing restoration.
  Categories MUST NOT cascade-delete expenses. A protected active fallback category
  MUST remain available.
- Expense deletion MUST require an explicit confirmation naming the target entry and
  explaining its effect. Until confirmation, saved data MUST remain unchanged.
- Schema changes MUST include a versioned migration strategy and a documented source-level
  review confirming that existing records, relationships, and monetary values are
  preserved. Destructive migrations and silent database recreation are prohibited.
- First-use and Settings screens MUST disclose that losing the phone, uninstalling the
  app, or clearing its data may permanently erase history. V1 MUST NOT promise recovery,
  backup, or synchronization that does not exist.

**Rationale:** With no recovery feature, accidental local data loss is especially costly.

### IV. Accessible Android Interaction

- V1 targets Android only. The same core expense workflows MUST be available on all
  supported Android versions; platform navigation, keyboards, safe areas, and
  accessibility semantics MUST be respected.
- The approved screen direction MUST guide implementation: Overview, History, and
  Categories as primary navigation; accessible labeled expense entry; light and dark
  themes; clear Settings and empty states. Visual details belong in the screen design
  specification, not duplicated as constitutional constants.
- Normal text MUST meet at least 4.5:1 contrast, large text at least 3:1, and meaningful
  non-text controls at least 3:1 against adjacent colors. Touch targets MUST be at
  least 48 dp on Android.
- Controls MUST expose labels and states to screen readers, support system text scaling
  and reduced motion, and remain usable with the keyboard open. Essential actions MUST
  NOT rely on color, hover, or swipe gestures alone.
- Forms MUST preserve valid input after errors, show errors beside the relevant fields,
  and provide predictable back/cancel behavior. Leaving a changed form MUST require
  explicit discard confirmation. Save actions MUST prevent duplicate submissions and
  provide immediate feedback without moving surrounding controls.

**Rationale:** Daily entry must be usable, understandable, and safe on Android.

### V. Minimal Scope and Source-Code Focus

- V1 MUST remain a manual personal-expense tracker with daily, weekly, and monthly
  history, customizable categories, PKR-only money, and device-only storage.
- V1 MUST NOT include income tracking, budgets, receipt scanning, bank integration,
  multiple currencies, accounts, cloud synchronization, or manual backup and restore.
  Income tracking is a future possibility, not an authorized V1 implementation task.
- V1 is Android-only. iOS support is out of scope; no iOS-specific source, configuration,
  or verification is required. Existing iOS artifacts are legacy and MAY be removed or
  archived by the project owner without affecting this constitution.
- Delivery is source-code-only. Writing production application source is the required
  deliverable. Automated test authoring, test suites, test infrastructure, test-first
  workflows, and test jobs in continuous integration are NOT required and MUST NOT block
  task completion or release. Correctness is established through source-level review,
  build success, and manual Android checks rather than automated test evidence.
- The technology stack is owner-approved: Flutter with bundled Dart, SQLite via the
  `sqflite` plugin, Codemagic cloud builds, and Android 7.0 / API 24 as the minimum
  supported version. Dependencies MUST have a documented need and compatible licensing;
  no backend, analytics, or runtime network dependency is permitted.
- Feature specifications MUST define acceptance criteria and exclusions before planning;
  plans MUST justify complexity with the simplest rejected alternative. Monetary,
  date-range, persistence, and presentation concerns MUST have separately reviewable
  responsibilities without prescribing a framework beyond the approved stack.
- Proposed screen-document defaults, including field-length and amount limits, MUST NOT
  be treated as approved requirements solely because the visual mockups were approved.
  Resolve them in the feature specification before affected implementation begins.

**Rationale:** Scope discipline preserves a small, trustworthy Android V1 without
committing the project to tests or platform work the owner has explicitly excluded.

## Product and Technical Constraints

- Product scope is recorded in `docs/expense-tracker-summary.md`; approved screen
  direction is recorded in
  `docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md`.
- The application MUST remain usable offline from first launch. No backend service,
  cloud data store, authentication flow, or external API is required for V1.
- The approved stack and minimum platform version are recorded in
  `docs/adr/0001-approved-mobile-stack-and-platform-floors.md` as amended by this
  constitution: Flutter/Dart, SQLite via `sqflite`, Codemagic, and Android 7.0 / API 24.
  iOS scope from that ADR is superseded. The implementation plan MUST identify the
  resolved toolchain pins, device-local persistence mechanism, asset packaging, Android
  automatic backup/transfer policy, and build commands.
- Feature specifications MUST set measurable responsiveness and scale targets for the
  expected local dataset. Measurements MUST identify the device class, dataset size,
  and scenario; unmeasured performance claims are not acceptance evidence.
- Prototype sample entries, fixed dates, browser-only state, and board layout MUST NOT
  become production behavior. Real calendar dates and durable writes are mandatory.

## Development Workflow and Quality Gates

1. **Specify:** Capture user journeys, acceptance scenarios, exclusions, relevant failure
   states, and unresolved defaults. Resolve blocking product questions before planning.
2. **Plan:** Check every core principle before research and again after design. Record
   compliance evidence or an explicitly authorized exception. Confirm the change stays
   within the approved Flutter/Android stack.
3. **Prepare tasks:** Map implementation tasks to user stories and concrete file paths.
   Include local persistence, migration, accessibility, and offline work where applicable.
   Automated test tasks are not required and MUST NOT be generated as mandatory gates.
4. **Implement:** Write production source in small, reviewable increments. Keep monetary
   and date rules independently reviewable, preserve existing records, and never report
   a failed build or check as passing. Logs MUST comply with Principle I.
5. **Review and release:** Verify acceptance scenarios by source review, a successful
   Android debug build, and manual checks of offline behavior, restart persistence, and
   relevant accessibility states. Recheck constitution compliance and disclose untested
   conditions. Release-blocking failures MUST be resolved before release; no actual
   release is authorized by completing a plan.
6. **Record decisions:** Record an architectural decision when selecting the stack,
   persistence/migration approach, or another consequential hard-to-reverse design.
   Keep specifications, plans, tasks, and runtime guidance aligned with amendments.

## Governance

This constitution is the project's highest internal engineering policy. Applicable law,
security requirements, and explicit project-owner instructions still apply. If a proposed
change conflicts with a principle, surface the conflict before implementation; do not
silently reinterpret a principle to make the change pass.

Amendments MUST identify the affected rules, rationale, migration or compatibility impact,
and dependent documents. The project owner MUST approve the amendment. Update this file,
its Sync Impact Report, affected templates and guidance, and `Last Amended` together;
record the work in a constitution-stage Prompt History Record. `Ratified` remains the
original adoption date, 2026-11-03.

Use semantic versioning for this constitution, independently of application versions:

- **MAJOR:** remove or redefine a principle incompatibly, change the supported platform
  set, or relax an existing mandatory protection or V1 boundary.
- **MINOR:** add a principle or materially expand compatible mandatory guidance.
- **PATCH:** clarify wording or correct references without changing obligations.

Version 1.0.0 was the first adoption; the prior file was an unversioned template.
Version 2.0.0 narrows scope to Android-only and removes the test-first requirement.

A time-limited exception MUST name its scope, reason, owner, expiry/review date, validation
plan, and explicit project-owner approval in the implementation plan. An exception MUST
NOT waive privacy, exact-money, data-preservation, or V1 scope protections; changing those
requires an approved constitutional amendment. A complexity-tracking table alone is not
approval and MUST NOT turn a failing gate into a passing gate.

Every feature plan and review MUST record compliance with the five principles. Requirements
or tasks that contradict this constitution MUST be corrected or escalated before affected
work proceeds. Unchanged documents need no cosmetic edits; missing guidance MUST be
reported rather than silently recreated without authorization.

**Version**: 2.0.0 | **Ratified**: 2026-11-03 | **Last Amended**: 2026-11-09
