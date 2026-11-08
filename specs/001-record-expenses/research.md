# Research: Offline recording with cloud-built Flutter

**Feature:** `001-record-expenses` | **Date:** 2026-11-04  
**Status:** Research decisions complete; implementation and cloud/native validation have not run.

## 1. Approved platform and delivery constraints

**Decision:** Flutter/Dart, SQLite and Codemagic; minimum Android 7.0/API 24 and iOS 15. Preserve both platforms in source; Android APK is the initial delivery artifact, not an amendment removing iPhone from V1.

**Rationale:** The owner explicitly selected this stack in `/sp.plan` and answered A to the minimum-OS question. No Flutter/Android SDK is installed on the owner's Windows system. Cloud tooling must run format, analysis, tests, native generation and builds.

**Alternatives considered:** Local SDK installation is optional, not a prerequisite imposed on the owner. Android-only product scope conflicts with the approved specification. A browser prototype cannot substitute for either native platform.

**Evidence:** [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms), [Codemagic Flutter setup](https://docs.codemagic.io/yaml-quick-start/building-a-flutter-app/).

## 2. Toolchain and dependency reproducibility

**Decision:** Candidate SDK pin Flutter `3.47.8`, using only its bundled Dart. Candidate direct packages: `sqflite 2.4.5`, `characters 1.4.1`, `uuid 4.6.0`; development-only `sqflite_common_ffi 2.4.5`, SDK `flutter_test`/`integration_test`, and the scaffold's lint package. Use Flutter SDK widgets, `ChangeNotifier` and constructor injection rather than a state-management/router/ORM package. Use native channel calls for the private no-backup path rather than adding a general filesystem dependency.

**Rationale:** The official security advisory names Flutter 3.47.8 as patched. Pub metadata lists the candidate sqflite version as requiring Dart 3.12 and Flutter 3.44 or later. The bundled Dart patch for that Flutter SDK was not independently verified in this session. Bootstrap must capture the actual toolchain pair, dependency resolution, generated Gradle/Java/Xcode compatibility and package licenses before locking the SDK and dependency graph. A sourced candidate is not a demonstrated Codemagic installation.

**Alternatives considered:** Floating `stable`/unlocked dependencies produce non-reproducible builds. Drift adds generation/reactivity not required by this recording slice. A single large controller mixing SQL, money and widgets prevents independent tests. A general UUID dependency is preferable to hand-writing random identifier generation. Native-only code is limited to storage policy/path enforcement.

**Licensing:** sqflite and its FFI test adapter BSD-2-Clause; characters BSD-3-Clause; uuid MIT; SQLite public-domain dedication. Confirm the locked transitive graph and NOTICE obligations during bootstrap. Use bundled Material icons and system font fallback initially; Manrope/Source Sans 3 may be bundled only with reviewed licenses. No remote font loader.

**Sources:** [Flutter advisory](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp), [SDK archive](https://docs.flutter.dev/install/archive), [sqflite](https://pub.dev/packages/sqflite), [sqflite versions](https://pub.dev/packages/sqflite/versions), [FFI adapter](https://pub.dev/packages/sqflite_common_ffi), [characters](https://pub.dev/packages/characters), [uuid](https://pub.dev/packages/uuid), [SQLite copyright](https://sqlite.org/copyright.html).

## 3. Complete project generation without local SDKs

**Decision:** Place the Flutter application in `app/` beside the existing documentation. Run a one-time manual macOS Codemagic bootstrap that generates a fresh project in a temporary directory. Publish the generated source as a restricted build artifact; the owner downloads and merges it into `app/`, then commits through their ordinary Git workflow. Do not give CI repository-write credentials or auto-push generated files. Generate both Android and iOS projects; commit source/configuration and lockfiles, not SDKs, machine paths, caches, secrets or binaries. Normal workflows fail if platform source is missing; they never run `flutter create` to mask incomplete source.

**Rationale:** Dart files alone do not supply the Android Gradle wrapper, manifest, Xcode project, or plugin registration setup. Creating a fresh temporary project avoids overwriting specs or reviewed platform privacy configuration. The first bootstrap can select a YAML workflow from `codemagic.yaml` without an existing Flutter app; if app detection prevents UI import, configure that repository as an existing YAML/custom project rather than claiming a Dart-only repo is buildable.

**Alternatives considered:** Local `flutter create` violates the owner's environment assumption. Hand-written generated platform projects are fragile. Regeneration on each build discards reviews and can restore unsafe defaults. GitHub-hosted build scripts are not a runtime backend: only source and synthetic test data enter CI, never actual expense history.

**Sources:** [Create an app](https://docs.flutter.dev/reference/create-new-app), [Codemagic YAML](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/).

## 4. Exact money, local dates and coherent Overview

**Decision:** Store PKR as integer paisa (`1..99999999900`). Parse and format with strings/integers, never `double`. 10,000 maximum-value expenses sum to `999999999000000` paisa, safely within signed 64-bit integers. SQLite `SUM()` over integer inputs remains integer and reports overflow; do not use `total()` or floating casts. Preserve overflow as a typed calculation error.

Store expense dates as validated fixed-width civil dates `YYYY-MM-DD`, Gregorian years 0001–9999, not UTC timestamps. This is the representable date domain, not an age/retention cutoff. Date construction rejects normalization of invalid dates. Build next-month boundaries with calendar components; do not add 24-hour durations across daylight saving. Sorting ISO civil-date strings gives chronological order over this domain.

An Overview read obtains today's rows, month sum and existence-of-any-expenses under one serialized read transaction. Derive today's count/total from those exact rows. Order using a database-generated monotonic `save_sequence`, not a changeable device clock. App resume/day/month changes trigger a fresh snapshot; existing civil dates are never rewritten.

**Alternatives considered:** Floating arithmetic silently loses exactness. UTC instant-to-local conversion moves recorded calendar days after timezone changes. Persisted summary caches create an unnecessary second financial truth. Civil-day ordinals also work but make manual diagnosis and fixtures less readable; a validated fixed-width date is sufficient.

**Sources:** [SQLite aggregate functions](https://sqlite.org/lang_aggfunc.html), [Dart integer types](https://dart.dev/language/built-in-types), [SQLite types](https://sqlite.org/datatype3.html).

## 5. SQLite lifecycle and durability

**Decision:** One app-owned sqflite handle, serialized write coordinator and injectable database factory. Enable/verify foreign keys on every open before migration; parameterized SQL, explicit `typeof()` checks and foreign keys with RESTRICT. Schema v1 creation and six stable default categories are transactional. Seed only on initial creation; subsequent opens validate rather than repair by overwriting. Future upgrades are ordered transactional preserving migrations; downgrade/newer schema/corruption/open failure surface a typed error with no delete/recreate path.

Use rollback journal `DELETE` with `synchronous=EXTRA`, configured outside transactions and read back. If the platform cannot honor the intended safe configuration, surface/record incompatibility rather than silently selecting a less durable mode. Success is emitted only after the transaction Future confirms commit. Hardware/filesystem flush assumptions remain SQLite's documented boundary, not a promise against arbitrary hardware damage.

**Alternatives considered:** WAL+FULL is valid but unnecessary before measurements demonstrate a concurrency need. OFF/MEMORY journaling is unacceptable; WAL+NORMAL is not chosen for stronger durability expectations. `INSERT OR REPLACE` can delete/reinsert rows and must not implement initialization or idempotency. Multiple screen-owned connections complicate cancellation and snapshots.

**Sources:** [sqflite transaction documentation](https://pub.dev/packages/sqflite), [SQLite atomic commit](https://sqlite.org/atomiccommit.html), [SQLite pragmas](https://sqlite.org/pragma.html), [foreign keys](https://sqlite.org/foreignkeys.html).

## 6. Duplicate-safe save, cancellation and unknown outcomes

**Decision:** Freeze a valid form into an immutable submission carrying a UUID also used as public expense ID. Repeated taps/retries reuse that identity. An existing ID with an identical payload means saved; a differing payload is an integrity error. Genuine separate new forms get different IDs. Only after proven non-persistence may editing produce a new payload/ID.

The coordinator owns the transaction beyond the widget lifetime. Cancellation before dispatch retires the queued operation. During a transaction, check the cancellation flag before insert and synchronously immediately before normal callback return; throw a dedicated cancellation exception to roll back. No await follows the final check. Cancellation after that checkpoint may lose to commit; report saved if so. Do not claim `Future.timeout`, route disposal or ignoring a Future cancels native work.

Reconciliation must first stop future attempts and drain the original write. A row's absence while an old transaction can still commit is not confirmed cancellation. If commit/rollback state is uncertain, quarantine the connection and establish a clean recovery boundary against the same file. Then check the ID through the clean connection: matching row → saved; absent row plus proof no old attempt can commit → cancelled/known-unsaved; inability to establish a clean boundary → outcome unavailable. Reconciliation retry checks the original operation, not a new Save.

**Native feasibility gate:** sqflite transaction/close error semantics require tests against the locked plugin, not assumptions from FFI. A successful close alone is not proof of a clean rollback. The planned adapter must demonstrate old native execution is settled, no queued commit remains, and a new connection can acquire/finish a transaction before absence is trusted. If that cannot be proved, retain outcome-unavailable and block the cancellation/recovery acceptance gate; research another SQLite adapter with explicit recovery controls rather than weaken the spec. No persisted auto-retry worker is introduced; termination simply reopens the actual store. A durable cancellation ledger is unnecessary without persistent retry queues.

**Alternatives considered:** Disabling cancellation was rejected by the owner's option C. Deleting an expense after a successful commit to pretend cancellation succeeded violates no-deletion scope and truthful feedback. Deduplicating identical fields loses legitimate purchases. Unbounded automatic retries are not needed.

**Sources:** [SQLite COMMIT failure semantics](https://sqlite.org/lang_transaction.html), [Dart timeout behavior](https://api.dart.dev/dart-async/Future/timeout.html), [sqflite implementation reference](https://github.com/tekartik/sqflite/tree/master/sqflite_common/lib/src) (verify locked release, not just upstream).

## 7. Device-only storage and platform limitations

**Decision:** A narrow native method channel returns/creates a protected expense directory before opening SQLite. Android uses `Context.getNoBackupFilesDir()`; iOS uses a dedicated Application Support subdirectory with backup exclusion and file protection. All DB/journal/sidecar files stay inside that directory. Native code applies/examines iOS `isExcludedFromBackup` before first financial write and after directory recreation; inability to establish the policy blocks initialization, not silently falls back to an ordinary Documents/database path.

Android defense in depth: explicit `allowBackup=false`, legacy full-backup exclusions and Android 12+ cloud/device-transfer exclusions, no custom backup agent, no runtime internet permission in the release merged manifest. Validate modern cross-platform transfer behavior with the pinned compile SDK and device OS; do not add unsupported XML elements to older resource parsers. Do not rely on `allowBackup=false` alone: Android documents manufacturer-dependent device-transfer behavior. No remote SDK/telemetry, sensitive logs, file-sharing, export, share sheet or auto-upload path.

iOS: no iCloud container/CloudKit entitlement, document sharing or open-in-place export; exclude the financial directory from backup and apply complete-until-first-authentication file protection, with locked-before-first-unlock errors handled as unavailable data. App-private storage uses OS protections; V1 does not promise an independent app passcode or protection against a compromised/rooted device. Backup exclusion is a configuration to verify, not proof of every vendor/system migration path. The attempted Apple documentation fetch provided no usable guidance; another fetch was interrupted and was not retried. Native implementation must verify exact Apple flag semantics and device-transfer limitations against current SDK documentation and inspect built entitlements.

**Release gate:** Run Android cloud/D2D and iOS backup/restore/Quick Start transfer checks on supported representative devices with synthetic markers. Inspect for copied DB and sidecars, not only UI zeros. An unverified or unavoidable off-device path remains release-blocking under Constitution I. Do not call a platform limitation a waived promise. No exception has been authorized.

**Alternatives considered:** sqflite's default database path alone is insufficient privacy evidence. Cache storage is purgeable and violates history preservation. SQLCipher/key management adds unrequested features and does not by itself prevent system transfer. A remote crash SDK conflicts with device-only diagnostics.

**Sources:** [Android backup controls and caveats](https://developer.android.com/identity/data/autobackup), [Android backup tests](https://developer.android.com/guide/topics/data/testingbackup), [Apple backup exclusion reference](https://developer.apple.com/documentation/foundation/urlresourcevalues/isexcludedfrombackup) (content not verified in this research).

## 8. Testing and cloud delivery

**Decision:** Required Codemagic host lane: locked dependency resolution, format, analysis, pure Dart/widget tests and file-backed SQLite FFI tests, then debug APK. Use separate native Android emulator and macOS iOS simulator integration lanes. Cloud host tests are not native persistence evidence. Verify emulator acceleration and pinned runner availability in the account; failure to provision native tests is reported as a blocked gate, not a passing/skipped test disguised as success.

Run deliberately failing behavioral tests in cloud before implementation, keep immutable red/green build URLs/commit IDs in evidence, and require the green regression suite before merging each increment. Minimal SDK-generated scaffolding is not feature implementation; behavioral implementation starts only after the corresponding failing test run. Physical-device timing, screen-reader, backup/transfer and termination tests remain separate acceptance evidence.

Use debug APK for initial sideload testing, no release secrets. Later use a dedicated manually gated trusted-branch signed-release workflow with a stable owner-held keystore. Do not expose signing secrets to PRs or auto-publish to a store. Unsigned iOS compile and simulator tests do not produce an installable iPhone build; signed device distribution requires appropriate Apple credentials/profiles and separate authorization.

**Alternatives considered:** `flutter build apk` alone skips tests; builds do not establish correctness. Native integration tests cannot be replaced by host FFI. Regenerating debug signing keys across cloud workers can break in-place updates: mark debug APKs disposable, use synthetic data, and switch to stable signing before real history. Never suggest uninstalling a real-data app as a harmless signing fix.

**Sources:** [Plugins in tests](https://docs.flutter.dev/testing/plugins-in-tests), [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests), [Codemagic testing](https://docs.codemagic.io/yaml-testing/testing/), [Linux image](https://docs.codemagic.io/specs-linux/ubuntu-24.04/), [Android signing](https://docs.codemagic.io/yaml-code-signing/signing-android/), [iOS signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/), [locked dependency resolution](https://dart.dev/tools/pub/cmd/pub-get).

## Decision status

No unanswered product question is hidden in this document. Candidate package/toolchain versions are explicit verification tasks, not claimed builds. Owner-approved stack and OS floors allow implementation planning; native cancellation/recovery, platform backup/transfer, SDK/dependency compatibility and release signing remain concrete technical validation gates. No cloud account, Git remote, signing identity, build or platform result was created by this research.
