---

description: "Task list template for feature implementation"
---

# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Delivery**: This project is source-code-only under Constitution V. Do not generate
mandatory automated test tasks, test infrastructure, or test-first gates. Correctness is
reviewed at source level, through a successful Android build, and by manual check.

**Organization**: Tasks are grouped by user story to enable independent implementation and verification of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Offline Android**: Use the approved app and Android paths from plan.md; no V1 API/backend.
- Paths shown below assume single project - adjust based on plan.md structure

<!-- 
  ============================================================================
  IMPORTANT: The tasks below are SAMPLE TASKS for illustration purposes only.
  
  The /sp.tasks command MUST replace these with actual tasks based on:
  - User stories from spec.md (with their priorities P1, P2, P3...)
  - Feature requirements from plan.md
  - Entities from data-model.md
  - Local domain/use-case contracts and persistence boundaries from contracts/; do not invent a V1 API
  
  Tasks MUST be organized by user story so each story can be:
  - Implemented independently
  - Verified independently
  - Delivered as an MVP increment
  
  DO NOT keep these sample tasks in the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

Examples of foundational tasks (adjust based on your project):

- [ ] T004 Implement private device-local schema and source-reviewed migrations in [approved data path]
- [ ] T005 [P] Verify Android backup-transfer controls and offline assets in [Android paths]
- [ ] T006 Implement exact PKR/local-date primitives and non-sensitive error handling in [domain/data paths]
- [ ] T007 Configure approved Android environment and accessibility/theme tokens in [app paths]

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Verification**: [How to verify this story works on its own]

### Implementation for User Story 1

- [ ] T008 [P] [US1] Create [Entity1] model in src/models/[entity1].py
- [ ] T009 [P] [US1] Create [Entity2] model in src/models/[entity2].py
- [ ] T010 [US1] Implement [Service] in src/services/[service].py (depends on T008, T009)
- [ ] T011 [US1] Implement [feature] in src/[location]/[file].py
- [ ] T012 [US1] Add validation and error handling
- [ ] T013 [US1] Add non-sensitive operational diagnostics; exclude financial values and user text

**Checkpoint**: At this point, User Story 1 should be fully functional and verifiable independently

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]

**Independent Verification**: [How to verify this story works on its own]

### Implementation for User Story 2

- [ ] T014 [P] [US2] Create [Entity] model in src/models/[entity].py
- [ ] T015 [US2] Implement [Service] in src/services/[service].py
- [ ] T016 [US2] Implement [feature] in src/[location]/[file].py
- [ ] T017 [US2] Integrate with User Story 1 components (if needed)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]

**Independent Verification**: [How to verify this story works on its own]

### Implementation for User Story 3

- [ ] T018 [P] [US3] Create [Entity] model in src/models/[entity].py
- [ ] T019 [US3] Implement [Service] in src/services/[service].py
- [ ] T020 [US3] Implement [feature] in src/[location]/[file].py

**Checkpoint**: All user stories should now be independently functional

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] TXXX [P] Documentation updates in docs/
- [ ] TXXX Code cleanup and refactoring
- [ ] TXXX Performance optimization across all stories
- [ ] TXXX Source-review monetary, date, persistence-failure, and migration behavior
- [ ] TXXX Verify no sensitive data in logs and no off-device expense copies
- [ ] TXXX Verify core workflows offline on Android, including restart persistence
- [ ] TXXX Verify both themes, contrast, screen readers, large text, reduced motion, and 48 dp touch targets
- [ ] TXXX Verify portrait/landscape, safe areas, keyboard-open forms, and discard confirmation
- [ ] TXXX Validate data-loss disclosures and no-recovery messaging on first use and Settings
- [ ] TXXX Run the Android debug build and record device/dataset performance measurements
- [ ] TXXX Record fresh review evidence, skipped checks, and final constitution compliance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently verifiable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but should be independently verifiable

### Within Each User Story

- Models before services
- Services before feature UI
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all models for User Story 1 together:
Task: "Create [Entity1] model in src/models/[entity1].py"
Task: "Create [Entity2] model in src/models/[entity2].py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and verifiable
- Automated test tasks are not required; review source and build the Android app instead
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
