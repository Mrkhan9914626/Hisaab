---
id: "0002"
title: "Amend Constitution Android-Only Source-Only"
stage: constitution
date: 2026-11-09
surface: agent
model: opencode/deepseek-v4.1-flash-free
feature: none
branch: 001-record-expenses
user: "Mrkhan9914626"
command: /sp.constitution
labels: [constitution, android-only, source-only, scope-reduction, governance]
links:
  spec: "docs/superpowers/specs/2026-11-03-expense-tracker-screens-design.md"
  ticket: null
  adr: "docs/adr/0001-approved-mobile-stack-and-platform-floors.md"
  pr: null
files:
  - .specify/memory/constitution.md
  - .specify/templates/plan-template.md
  - .specify/templates/spec-template.md
  - .specify/templates/tasks-template.md
  - .claude/commands/sp.tasks.md
  - .claude/commands/sp.implement.md
  - CLAUDE.md
  - README.md
  - docs/expense-tracker-summary.md
  - docs/adr/0001-approved-mobile-stack-and-platform-floors.md
  - docs/adr/0002-protected-sqlite-and-save-coordinator.md
  - history/prompts/constitution/0002-amend-constitution-android-only.constitution.prompt.md
tests:
  - "Constitution placeholder, heading, version, and date checks"
  - "Dependent-template and command-guidance consistency checks"
  - "Documentation whitespace review"
---

## Prompt

I have decided some changes in my application, The application is now only for android to be simple and jsut writting a source code for the application without writting and tests and other complexities

## Response snapshot

Amended the constitution to v2.0.0 (MAJOR). Narrowed V1 to Android only, removed the
Test-First Verification principle and all automated-test gates, and renumbered Minimal
Scope to Principle V with explicit source-code-only delivery rules. Updated the plan, spec,
and tasks templates and the sp.tasks/sp.implement commands so they no longer require tests
or iOS work. Propagated the Android-only scope into CLAUDE.md, README.md, the product
summary, and both ADRs. Historical feature specs and the feature map were flagged in the
Sync Impact Report rather than rewritten.

## Outcome

- ✅ Impact: MAJOR amendment; Android-only scope and test-free source delivery.
- 🧪 Tests: Documentation consistency and whitespace checks only; app tests not required.
- 📁 Files: Constitution, three templates, two commands, three guidance docs, two ADRs,
  and this record.
- 🔁 Next prompts: Decide whether to remove legacy `app/ios/` and iOS CI references; then
  continue Android source implementation under the updated tasks flow.
- 🧠 Reflection: Removing principles requires renaming/renumbering and updating every
  downstream gate, including command prompts, not only the constitution.

## Evaluation notes (flywheel)

- Failure modes observed: The Bash PHR generator `.specify/scripts/bash/create-phr.sh` is
  absent from this PowerShell-template repository; the record was created from the existing
  template with native file tools.
- Graders run and results (PASS/FAIL): PASS — no unexplained bracket tokens and version
  line matches report; PASS — five principles and Android-only scope consistent across
  templates and commands; PASS — ISO dates and PHR metadata.
- Prompt variant (if applicable): none.
- Next experiment (smallest change to try): Remove or archive legacy iOS code and confirm
  the Android debug build workflow still matches CLAUDE.md.
