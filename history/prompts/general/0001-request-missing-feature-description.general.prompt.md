---
id: "0001"
title: "Request Missing Feature Description"
stage: general
date: 2026-11-03
surface: agent
model: "cx/gpt-6.1-sol[1m]"
feature: null
branch: main
user: "Mrkhan9914626"
command: /sp.specify
labels: [specification, missing-input]
links:
  spec: null
  ticket: null
  adr: null
  pr: null
files:
  - history/prompts/general/0001-request-missing-feature-description.general.prompt.md
tests: []
---

## Prompt

/sp.specify

## Response snapshot

ERROR: No feature description provided.
Please provide the feature you want specified, for example: `/sp.specify Add expense creation with amount, category, date, and notes`.
No feature branch, specification, or requirements checklist was created.

## Outcome

- Impact: Stopped specification creation because the command's feature-description input was empty.
- Tests: Not run; no application changes.
- Files: Created this prompt history record using the local template because `.specify/scripts/bash/create-phr.sh` does not exist.
- Next prompts: Run `/sp.specify` with a feature description.
- Reflection: Do not infer a feature from the repository name or command instructions.

## Evaluation notes (flywheel)

- Failure modes observed: Empty feature-description input; PHR creation script absent.
- Graders run and results (PASS/FAIL): Manual check PASS for detecting empty input and avoiding feature creation.
- Prompt variant (if applicable): None.
- Next experiment (smallest change to try): Supply a nonempty feature description.
