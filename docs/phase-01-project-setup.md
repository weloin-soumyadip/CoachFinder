# Phase 1 — Project setup

**Goal:** Stand up the Flutter project skeleton, install dependencies, and fully implement `core/` so the app boots into a routable shell with a role-selector onboarding screen. No feature UI in this phase.

**Status:** In progress (Step 0 and Step 1 complete; Step 2 next).

---

## Step 0 — Scaffold the Flutter project ✅

**Action:** `flutter create --org com.weloin --project-name coachfinder --platforms android,ios .`

- Scaffolds into the existing empty `app/` directory.
- Android `applicationId` and iOS bundle ID become `com.weloin.coachfinder`.
- Default `lib/main.dart` and `test/widget_test.dart` deleted (we rewrite `main.dart` in Step 3).

---

## Step 1 — `pubspec.yaml` and SDK targets ✅

**`pubspec.yaml`:** Rewrote with these dependencies at the exact constraints specified:

Runtime: `flutter_riverpod ^2.5.1`, `hooks_riverpod ^2.5.1`, `flutter_hooks ^0.20.5`, `go_router ^13.2.0`, `hive ^2.2.3`, `hive_flutter ^1.1.0`, `path_provider ^2.1.3`, `dio ^5.4.3+1`, `json_annotation ^4.9.0`. Plus scaffold default `cupertino_icons ^1.0.8` (see [0005](../decisions/0005-keep-cupertino-icons-scaffold-dep.md)).

Dev: `hive_generator ^2.0.1`, `json_serializable ^6.8.0`, `build_runner ^2.4.9`. Plus scaffold default `flutter_lints ^6.0.0` (see [0006](../decisions/0006-keep-flutter-lints-default.md)).

SDK constraint: `'>=3.3.0-0 <4.0.0'` — the `-0` allows the local Dart `3.12.0-dev` SDK to satisfy the range (see [0007](../decisions/0007-sdk-constraint-allows-prerelease.md)).

**Android (`android/app/build.gradle.kts`):** `minSdk = 21` (Android 5.0). See [0003](../decisions/0003-min-sdk-android-21-ios-12.md).

**iOS:** No `Podfile` exists yet on Linux. Set `IPHONEOS_DEPLOYMENT_TARGET = 12.0` in the Xcode project file (3 build configs). See [0008](../decisions/0008-ios-deployment-target-via-xcode-project.md).

`flutter pub get` resolved cleanly.

---

## Step 2 — Skeleton folder + file creation ✅

Create every folder and file in the agreed structure. Each file gets only:

```dart
/// <one-line description of what this file is for>
// TODO: implement
```

No logic, no imports, no classes.

**Actual file count: 100 files across 80 directories.** (My earlier "~85" estimate was an undercount.)

- `core/` — 23 files across `constants/`, `theme/`, `router/`, `network/`, `storage/`, `error/`, `providers/`, `widgets/`.
- `features/onboarding/` — 1 screen file.
- `features/auth/` — 10 files (models 2, controller 1, repository 4, screens 2, widgets 1).
- `features/student/` — 39 files (`home` 8, `search` 11, `center_detail` 12, `profile` 8).
- `features/owner/` — 27 files (`dashboard` 7, `manage_center` 12, `enquiry_inbox` 8).
- `lib/main.dart` — created in Step 3, not here.

No barrel/index files (skipped per agreement).

**Execution note:** Created via a single Bash `while read` + `printf` loop instead of 100 individual `Write` calls. Trade-off was efficiency vs. the harness preference for `Write`. The full file list was inlined in the heredoc for review.

---

## Step 3 — Fully implement `core/` + `main.dart` ✅

Implemented 19 `core/` files + new `lib/main.dart`. The 4 `core/widgets/*` files stay as skeleton (built when the first feature screen needs them, per the original plan).

`main.dart` flow:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `HiveService.instance.init()` — opens `settings`, `auth`, `cache` boxes. No adapters registered yet (`TODO(adapters)` marker in `hive_service.dart`).
3. Read `user_role` from `settings` box.
4. `runApp(ProviderScope(overrides: [roleProvider.overrideWith((ref) => initialRole)], child: CoachFinderApp()))`.

`CoachFinderApp` is a `ConsumerWidget` reading `routerProvider` and rendering `MaterialApp.router` with light + dark Material 3 themes.

**Static analysis result:** 14 errors remain — all `creation_with_non_type` / `undefined_method` about the 14 screen classes referenced by the router but not yet defined. These resolve in Step 4. Zero warnings, zero infos in `core/` code.

**Deferred to a later phase (flagged TODOs in code):**
- JWT refresh-token flow — see [decision 0009](../decisions/0009-no-refresh-token-flow-phase-1.md).
- Hive `@HiveType` adapter registration — models are still skeletons.
- `core/widgets/` shared widgets — built when first screen needs them.

**Bottom-nav tabs chosen by Claude (call out if you want different):**
- Student shell (4 tabs): Home / Search / Saved / Profile.
- Owner shell (3 tabs): Dashboard / Center / Enquiries — no profile tab since no owner-profile route exists in the spec.

**Skeleton-file housekeeping:** Added `library;` after the `///` doc comment on all 80 still-skeleton files to satisfy the `dangling_library_doc_comments` lint. No structural change.

---

## Step 4 — Placeholder screens + onboarding logic

Every screen file: `HookConsumerWidget` returning `Scaffold(body: Center(child: Text('<ScreenName>')))`. Zero logic.

Exception — `OnboardingScreen`:
- Two large tappable cards: "I am a Student" / "I am a Coaching Owner".
- On tap: write role to `Hive.box('settings').put('user_role', ...)`, set `roleProvider` state, then `context.goNamed('login', extra: <role>)`.

All widget skeleton files remain doc + TODO.

---

## Related decisions

- [0001 — Flutter create org and project name](../decisions/0001-flutter-create-org-and-project-name.md)
- [0002 — API base URL for Android emulator](../decisions/0002-api-base-url-android-emulator.md)
- [0003 — Min SDK Android 21 / iOS 12](../decisions/0003-min-sdk-android-21-ios-12.md)
- [0004 — Font family Roboto default](../decisions/0004-font-family-roboto-default.md)
- [0005 — Keep `cupertino_icons` scaffold dep](../decisions/0005-keep-cupertino-icons-scaffold-dep.md)
- [0006 — Keep `flutter_lints` default](../decisions/0006-keep-flutter-lints-default.md)
- [0007 — SDK constraint allows pre-release](../decisions/0007-sdk-constraint-allows-prerelease.md)
- [0008 — iOS deployment target via Xcode project](../decisions/0008-ios-deployment-target-via-xcode-project.md)
- [0009 — No refresh-token flow in Phase 1](../decisions/0009-no-refresh-token-flow-phase-1.md)
- [0010 — Flat route paths, no role prefix in URLs](../decisions/0010-flat-route-paths-no-role-prefix.md)
