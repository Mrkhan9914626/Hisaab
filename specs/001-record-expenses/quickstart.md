# Cloud-only development quickstart

**Feature:** `001-record-expenses` | **Date:** 2026-11-04  
This is a future execution guide, not a record of executed commands. The owner's Windows computer needs an editor, Git and a browser, not Flutter/Android SDKs. Minimum app OS: Android API 24 / iOS 15. Read [plan.md](plan.md) first.

## 1. Connect the repository safely

1. Create/select the owner's GitHub repository and approve its visibility before pushing. No remote is configured in the inspected repository; the planning step has not created one. Review the diff and exclude `.superpowers/` review captures, caches, personal history or unrelated pending changes unless deliberately intended. Do not commit signing keys or any real expense database.
2. Configure the Git remote and push only when the owner requests it. In Codemagic, authorize the intended repository, select the feature branch and YAML configuration. Those are source/build services, not runtime expense services; never upload a real phone's database.
3. Implementation creates root `codemagic.yaml`. For the first bootstrap, import as a YAML/custom project if Flutter app detection requires an existing pubspec. Verify the selected plan offers the macOS runner and pinned Flutter toolchain; account access/billing is not supplied by source code.

## 2. One-time bootstrap (cloud SDKs)

Create a manually triggered macOS workflow named `bootstrap-source` with candidate Flutter `3.47.8`. If the pin is unavailable, fail and deliberately review a supported patched pin; do not silently fall back to a moving channel. The workflow prints only non-sensitive tooling metadata:

```sh
set -eu
flutter --version --machine
dart --version
flutter doctor -v
```

The owner must choose the permanent reverse-domain application identifier before executing bootstrap. Pass its organization prefix as required workflow environment variable `APP_ORG`; it is a setup input, not a secret. Do not use someone else's domain or publish the template example identifier as a final package ID.

```sh
set -eu
: "${APP_ORG:?Set the owner-approved reverse-domain organization prefix}"
BOOTSTRAP_ROOT="$(mktemp -d)"
flutter create --platforms=android,ios --org "$APP_ORG" \
  --project-name expense_tracker "$BOOTSTRAP_ROOT/app"
cd "$BOOTSTRAP_ROOT/app"
flutter pub get
mkdir -p "$CM_BUILD_DIR/bootstrap-artifacts"
tar --exclude='./.dart_tool' --exclude='./build' \
  --exclude='./android/local.properties' --exclude='./ios/Flutter/ephemeral' \
  --exclude='./ios/Pods' --exclude='./ios/.symlinks' \
  -czf "$CM_BUILD_DIR/bootstrap-artifacts/flutter-source.tar.gz" .
```

Publish `bootstrap-artifacts/flutter-source.tar.gz` as a restricted Codemagic artifact. Download/extract into a temporary local directory, inspect it, then merge into repository `app/` without overwriting reviewed feature code/configuration. Do not execute this again over an existing platform project. Commit intended `app/lib`, `android`, `ios`, tests, pubspec, lockfile, metadata and ignore rules. Follow generated ignores for `local.properties`, signing files, build caches and generated artifacts. Do not archive a DB, `.env`, key or unrelated repository content. For the first bootstrap archive, generated caches are unnecessary; refine the packaging allowlist before production use.

After generation, implementation sets Android minSdk 24 and iOS deployment target 15.0 consistently in generated configurations; keeps compatible generated compile/target SDK, Gradle/JDK/Xcode versions; records exact versions in `docs/build-toolchain.md`; installs candidate dependencies from research.md; resolves/reviews `pubspec.lock`. Add Flutter assets and platform privacy config before native behavior. Never run `flutter create` in normal build workflows.

## 3. Required host validation + testing APK

Root YAML workflow `android-checks-debug` uses a verified Linux runner with Flutter pinned to the approved bootstrap result. Run from `app/`. The initial dependency-resolution/bootstrap lane may create the lock; normal lanes enforce it:

```sh
set -eu
cd "$CM_BUILD_DIR/app"
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze
mkdir -p test-results
flutter test --machine > test-results/flutter.json
flutter build apk --debug
```

Use Codemagic's test_report for `app/test-results/flutter.json`. No `ignore_failure`, unconditional success, or pipeline masking failures. Archive `app/build/app/outputs/flutter-apk/app-debug.apk`, test reports and non-sensitive toolchain metadata, never test DB files or signing secrets. The host SQLite FFI adapter needs the image's supported SQLite native library setup verified by bootstrap (package instructions mention libsqlite3 runtime/development packages). A MissingPluginException in a host test is not an acceptable substitute for a failing behavioral assertion; inject FFI/fake repositories deliberately.

A debug APK is for disposable synthetic-data testing. Cloud debug keys may change between runners; it is not a reliable long-term update identity. Do not enter irreplaceable real history in these builds. Stable release signing is required before a real-use installation; never recommend uninstalling as a harmless way to solve signature conflicts.

## 4. Red/green development without a local SDK

For each behavioral increment:

1. Add a focused failing test, push an owner-approved branch commit and run the appropriate Codemagic lane. Preserve commit/build URL and assertion showing the missing behavior, not merely a compiler/configuration failure.
2. Add the minimum implementation, run the same test plus existing regressions in Codemagic, and retain the passing evidence.
3. Review the diff and failed/skipped native checks before moving on. A successful APK compile cannot replace red/green evidence.

Use focused cloud commands, for example `flutter test test/domain/money_test.dart` or `flutter test test/data/expense_repository_test.dart`. Source editing remains local; SDK-dependent commands run remotely. Pushing/building is a separate owner-authorized execution action, not performed by `/sp.plan`.

## 5. Native Android verification

Workflow `android-native-tests` must verify an available emulator and acceleration on its selected runner rather than assume it. Codemagic's documented Linux environment provides emulator launch tools; the account-specific boot is untested here. Start it, wait for ADB and use a bounded boot readiness check before running:

```sh
set -eu
cd "$CM_BUILD_DIR/app"
flutter pub get --enforce-lockfile
flutter emulators --launch emulator &
adb wait-for-device
ready=false
for attempt in $(seq 1 120); do
  if [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; then
    ready=true
    break
  fi
  sleep 2
done
[ "$ready" = true ] || { printf '%s\n' 'Android emulator boot timed out'; exit 1; }
flutter devices
flutter test integration_test -d emulator-5554
```

Bound the entire job including `adb wait-for-device` with a Codemagic workflow timeout. Verify the actual emulator ID; do not silently run on a different target. Maintain API-24 minimum and current-OS native coverage using available images; image absence is reported as unavailable coverage. If Linux virtualization is unavailable, choose a verified runner/device service under separate authorization; do not mark native tests passed using host SQLite.

Native tests exercise real plugin/file creation, cancel/commit races, protection policy failures and reopen. OS force-stop/relaunch checks need an external driver (`adb shell am force-stop` and relaunch against synthetic fixtures) because killing the test process cannot verify its own restart. Never add production diagnostic screens or destructive reset commands to make test fixtures convenient.

## 6. iOS verification remains in scope

Mac workflow `ios-unsigned` uses a verified pinned Xcode/Flutter pair, installs locked dependencies, and compiles:

```sh
set -eu
cd "$CM_BUILD_DIR/app"
flutter pub get --enforce-lockfile
flutter build ios --release --no-codesign
```

This is **compile evidence only**, not an installable iPhone IPA or runtime proof. A separate simulator lane boots an available simulator from that Xcode image and runs `flutter test integration_test -d <selected-simulator-id>`; choose and record the actual ID at execution, do not pass the angle-bracket token literally. Minimum iOS 15 needs a compatible available runtime/device; a recent simulator does not establish that minimum.

Signed physical-iPhone distribution requires suitable Apple certificates/profiles/program access and an authorized workflow. If unavailable, record the blocked physical-iOS acceptance, do not remove iPhone from V1 or claim complete native verification. Simulator timings do not satisfy physical-device responsiveness targets.

## 7. Signing, privacy and physical acceptance

A later trusted manually triggered `android-release` workflow consumes Codemagic-managed signing identity environment variables (`CM_KEYSTORE_PATH`, `CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, `CM_KEY_PASSWORD`) through reviewed Gradle signing config. Owner retains a secure independent keystore backup; no PR workflow receives signing secrets. `flutter build apk --release` is only production signing if Gradle actually uses that release identity; default template debug signing must not pass the gate. Store upload is outside this feature.

Before real-use/release, validate app-private/no-backup paths, merged manifest permissions, legacy/new Android backup rules, iOS file flags/entitlements, and cloud/device-transfer behavior with synthetic data. Inspect financial files/sidecars, not only UI. Unverified or conflicting off-device paths block release.

Use a physical Android 2020–2022 4-GB device and iPhone from that class (candidate Pixel 4a and iPhone 12, subject to actual availability) with ≥1 GB free, 10,000 synthetic expenses over 24 months and 500 today. Run the specification's 30-trial response timings, 100 save/restart tests, both themes/orientations, text scaling, screen readers, reduced motion, keyboard and safe-area checks. Owner/task study uses 10 unfamiliar people per SC-001/007. Record synthetic fixture version, OS, device, build/signing identity, commit, tool versions, results and skips under `docs/verification/001-record-expenses/`; never invent evidence.

## Definition of this quickstart's status

Nothing here was executed against Flutter, Android, iOS or Codemagic in this planning session. GitHub remote, account authorization, permanent identifiers, exact cloud image compatibility, signing and device availability are operational execution inputs, not approved or created resources. See research.md for official sources and plan.md for phase gates.
