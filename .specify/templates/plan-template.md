# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/sp.plan` command. See
`.claude/commands/sp.plan.md` for the execution workflow and
`.specify/memory/constitution.md` for the mandatory project gates.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  
**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  
**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  
**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  
**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]
**Project Type**: [single/web/mobile - determines source structure]  
**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  
**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  
**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Record PASS, BLOCKED, or an authorized exception with concrete evidence for every gate.
No affected implementation starts while a gate is BLOCKED. Research may evaluate candidate
stacks; it does not authorize production scaffolding.

- **I. Offline-first privacy:** Core flows and assets work offline; data stays in private
  device storage; no accounts, remote telemetry, or financial-data logs. Document Android
  and iOS automatic backup/transfer controls and any platform limitations.
- **II. Exact money and history:** PKR-only exact arithmetic, validated bounds/precision,
  explicit local-date and week boundaries, and a shared record set for lists and totals.
- **III. Durable storage:** Atomic writes, restart persistence, non-destructive errors,
  category history preservation, confirmed deletion, tested migrations when applicable,
  and accurate no-recovery messaging.
- **IV. Accessible mobile interaction:** Approved screen direction, both themes, platform
  touch targets, contrast, screen readers, text scaling, safe areas, reduced motion,
  keyboard-open forms, and explicit discard behavior.
- **V. Test-first verification:** Failing tests precede changed behavior; plan domain,
  persistence, failure-path, and migration tests as relevant, plus Android/iOS offline
  and interface verification. Identify tools, devices, and untested conditions.
- **VI. Minimal scope and decisions:** No excluded V1 features or assumed backend. Record
  project-owner approval of the stack and supported OS versions before scaffolding;
  resolve feature defaults and justify dependencies and complexity.

Repeat this checklist after Phase 1 design with links to the supporting plan sections.
Complexity justification is not an exception approval; follow constitution Governance.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/sp.plan command output)
├── research.md          # Phase 0 output (/sp.plan command)
├── data-model.md        # Phase 1 output (/sp.plan command)
├── quickstart.md        # Phase 1 output (/sp.plan command)
├── contracts/           # Phase 1 output (/sp.plan command)
└── tasks.md             # Phase 2 output (/sp.tasks command - NOT created by /sp.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Offline mobile app (Android and iPhone; no V1 API)
[approved-app-root]/
├── [presentation: approved screens, navigation, accessible components]
├── [domain: exact money, calendar ranges, category rules]
├── [data: device-local storage and migrations]
└── [tests: unit, persistence integration, and platform UI]

[platform-projects-if-required]/
└── [Android/iOS configuration, backup/transfer controls, packaged assets]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Complexity Tracking

> **Fill only for proposed complexity or governance-authorized exceptions.**
> Record approval, owner, expiry/review date, and validation for an exception. Mandatory
> privacy, exact-money, data-preservation, and V1 scope rules require an amendment,
> not a justification entry. Unapproved violations remain BLOCKED.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
