# ADR-0001: Approved Mobile Stack and Platform Floors

> **Amendment (2026-11-09):** Constitution v2.0.0 makes V1 Android-only and removes
> automated test requirements. The iOS platform floor, iOS build/verification steps, and
> iOS scope in this ADR are superseded. The Flutter/Dart, SQLite, Codemagic, and Android
> API 24 decisions remain in force.

> **Scope**: This ADR records the approved cross-cutting delivery stack: framework, local persistence engine, cloud build service, and minimum supported OS versions. It does not approve individual package versions or release signing.

- **Status:** Accepted
- **Date:** 2026-11-08
- **Feature:** 001-record-expenses
- **Context:** The feature must work fully offline on Android and iPhone, store financial records only on the device, and be built without a local Flutter/Android SDK. The project owner explicitly approved the stack and minimum OS floors before production scaffolding, satisfying Constitution VI. The candidate toolchain pins are still subject to verification during the one-time cloud bootstrap.

## Decision

- **Framework:** Flutter with its bundled Dart SDK. Candidate pin: Flutter `3.47.8`. The verified Dart patch must be captured from `flutter --version --machine` during bootstrap and locked before behavioral implementation.
- **Local persistence:** SQLite through the `sqflite` plugin (candidate `2.4.5`) on device. Host tests use the development-only `sqflite_common_ffi` adapter (candidate `2.4.5`) against file-backed databases.
- **Cloud build and verification:** Codemagic workflows for a manual macOS source bootstrap, Linux host checks and debug APK, Android native integration tests, unsigned iOS compile, and iOS simulator integration tests.
- **Minimum platforms:** Android 7.0 / API 24 and iOS 15.0. Both platforms stay in source scope; the Android APK is the initial delivery artifact, not a scope reduction.
- **Project location:** The Flutter application lives in `app/` beside the existing Spec Kit documentation repository.
- **Supporting packages (candidates):** `characters 1.4.1` for grapheme counting, `uuid 4.6.0` for immutable submission identities, and the scaffold's lint package. No ORM, router, or state-management framework is introduced.

Candidate versions are not claimed as installed or compatible until the owner-authorized bootstrap records the resolved dependency graph, licenses, and actual Flutter/Dart/JDK/Gradle/Xcode/image versions in `docs/build-toolchain.md`.

## Consequences

### Positive

- One codebase covers both required mobile platforms with a single exact-money and local-date domain model.
- SQLite provides atomic local transactions without a server, account, or network dependency.
- Cloud build keeps the owner's Windows machine free of SDK installations while producing reproducible artifacts and evidence.
- API 24 and iOS 15 floors bound platform-specific testing and native backup/storage behavior.

### Negative

- Native integration, backup/transfer, accessibility, and physical-device evidence require owner-authorized cloud and device access that source code alone cannot provide.
- Exact toolchain compatibility and package resolution remain bootstrap gates; a failed pin blocks implementation.
- Flutter adds generated Android/iOS projects that must be produced once and reviewed rather than hand-written.

## Alternatives Considered

- **Local SDK installation:** Optional rather than imposed on the owner; cloud execution avoids a Windows-specific toolchain requirement.
- **Android-only or web scope:** Rejected; both Android and iPhone are required by the specification.
- **Drift or another ORM:** Adds code generation and reactive layers not needed for this recording slice.
- **Custom platform storage without a plugin:** Hand-writing SQLite bindings increases durability and recovery risk.
- **Regenerating platform projects on every build:** Discards reviewed privacy configuration and is explicitly rejected by the plan.

## References

- Feature Spec: `specs/001-record-expenses/spec.md`
- Implementation Plan: `specs/001-record-expenses/plan.md`
- Research: `specs/001-record-expenses/research.md` §1–§3, §8
- Quickstart: `specs/001-record-expenses/quickstart.md` §2–§6
- Related ADRs: `docs/adr/0002-protected-sqlite-and-save-coordinator.md`
- Evaluator Evidence: `history/prompts/001-record-expenses/0004-plan-cloud-built-flutter-expense-recording.plan.prompt.md`
