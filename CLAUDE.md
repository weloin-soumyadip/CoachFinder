# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

CoachFinder is a Flutter app (this repo, `app/`) for discovering and contacting coaching centers, with a separate Node/Express + MongoDB backend in the sibling `../server/` directory. The app supports three role shells — **student**, **owner** (coaching-center owner), and **teacher** — each with its own tab navigation, accent colour, and feature set.

## Commands

All commands run from the repo root (`app/`).

```bash
flutter pub get                      # install dependencies
flutter analyze                      # MUST print "No issues found!" before any change is done
dart format lib                      # format (run before analyze)
flutter test                         # run the whole suite
flutter test test/path/to/file_test.dart           # single file
flutter test --plain-name "parses owner"           # single test by name
dart run build_runner build --delete-conflicting-outputs   # regen json_serializable / hive adapters
flutter run                          # run on the default device
flutter run -d <device-id>           # e.g. -d chrome (web), -d RMX3710 (a physical Android)
flutter build apk --debug            # the build smoke-test used to confirm a change compiles
```

Backend (in `../server/`, only when verifying the API contract): `npm run dev` (ts-node watch), `npm run build`, `npm test`. The backend is normally run via `docker compose up -d` from `../server/`.

**Definition of "done" for a code change:** `dart format lib` → `flutter analyze` clean → `flutter build apk --debug` succeeds. New hero/atmospheric UI is also walked in **both light and dark** modes (neoglass is most fragile when the dark calibration is off). New `data/models/` files get a matching test under `test/` (TDD).

## Architecture

### Entry & bootstrap (`lib/main.dart`)
`main()` → `LocalStorage.init()` (opens the Hive `coachfinder_settings` box) → reads the persisted role + theme → `runApp` inside a Riverpod `ProviderScope` that **overrides** `roleProvider` and `themeModeProvider` with the hydrated values. `CoachFinderApp` is a `HookConsumerWidget`; a `useEffect` *touches* `authControllerProvider` once (without subscribing) so its launch-time `bootstrap()` fires a `/me` rehydration — restoring the session across restarts. The router redirect reads `roleProvider` directly, so rehydration propagates without rebuilding `MaterialApp`.

### Routing & role shells (`lib/core/router/`)
`GoRouter` (`app_router.dart`) with `initialLocation: '/splash'`. The redirect guard is the security boundary: it reads `roleProvider` + the Hive auth box on every navigation and decides whether the target path is reachable. Three shells — `_StudentShell`, `_OwnerShell`, `_TeacherShell` — each wrap their tabs in `AdaptiveNavigation` (`lib/shared/layouts/`), which renders a floating bottom nav below 768 px and a side rail at/above it. Paths are classified into a role by prefix lists (`_studentPrefixes` / `_ownerPrefixes` / `_teacherPrefixes`); a user in the wrong role's shell is bounced to `_homeFor(role)`. **Route names are constants in `app_routes.dart` — never use raw path strings at call sites.** `landingRouteForRole` / `_homeFor` are the single source of truth for where a freshly-authenticated role lands.

### Auth & the data layer
The repository pattern (mirrors the reference project `maxinvoice-app`): only `data/repository/` (or `data/repositories/`) may touch Dio / Hive / secure storage. The chain is `AuthController` (a `StateNotifier<AuthState>` in `features/auth/data/providers/auth_providers.dart`) → `AuthRepository` (throws `AuthException`) → `ApiClient` (Dio wrapper in `lib/core/api/`) → backend. Tokens live in `flutter_secure_storage` (`core/storage/token_storage.dart`); non-secret session bits (role, current user id, theme) live in Hive via `LocalStorage` + `StorageKeys` (`core/storage/local_storage.dart`). On a 401 the `ApiClient` interceptor transparently refreshes the access token via `POST /auth/refresh` (single-flight, retries the original request) and only clears the session if refresh itself fails — see ADR 0039. Responses are unwrapped by `ApiResponse.fromJson`, which handles **both** envelope shapes — top-level (`{success, accessToken, user}`, used by auth) and nested (`{success, data, message}`). When changing any request/response model, verify it against the real backend handler in `../server/src/controllers/*.controller.ts` (the `api-contract-checker` agent automates this). **`../server/api.md` documents ONLY the auth endpoints** — for every other surface (centers, owners, students, search, …) read the route + controller + Zod schema in `../server/src/` directly; do not assume an endpoint is missing just because `api.md` omits it (the centers CRUD, e.g. `POST /api/centers`, exists despite being undocumented there).

### Platform-aware networking (`lib/core/api/api_config.dart`)
`baseUrl` is resolved at runtime: a `--dart-define=BACKEND_BASE_URL=…` override wins; else web → `localhost`, Android → `10.0.2.2` (the emulator host alias). Android debug builds permit cleartext HTTP via `android/app/src/debug/res/xml/network_security_config.xml` (debug-only; release never merges it). **A physical Android device can't reach `10.0.2.2` and can't reach the laptop unless the backend's Docker port is published beyond loopback** — use `--dart-define` with the laptop's LAN IP, or `adb reverse tcp:5000 tcp:5000`. See ADR 0032.

### Feature anatomy
Every feature under `lib/features/<role>/<feature>/` follows:
```
data/
  models/                 # one model per file; each gets a *_test.dart (TDD)
  controllers/            # Riverpod NotifierProvider for state mutated across navigation
  repository/             # the ONLY layer allowed to touch Dio/Hive (real backend wiring)
  mock_<feature>_data.dart  # fixtures (+ small models) for Phase-1 mock-backed screens
presentation/
  screens/                # HookConsumerWidget screens
  widgets/                # HookWidget / StatelessWidget pieces; private _Foo inlined in a screen is fine
```
Most screens are still **mock-backed** (fixtures in `mock_*_data.dart`, in-memory state that resets on restart). The auth feature is the one fully wired to the backend. Read-only screens read fixtures directly; UI that mutates shared state across navigation (enquiries, manage-center, teacher-profile) uses a `NotifierProvider` in `data/controllers/` as the single source of truth so list + detail views can't drift.

### State management
Riverpod 2 only (no get_it). `flutter_hooks` for local widget state (`useState`, `useTextEditingController`, `useMemoized`, `useEffect`). Screens are `HookConsumerWidget`.

### Design system — neoglass
The visual language is **neoglass** ("Glass surrounds, Neo presses"): `BrandBackdrop` + `GlassPanel` on hero/atmospheric screens (auth, onboarding, splash, and the teacher shell), flat `palette.surface` cards on the other shell screens, `NeoSurface` / `NeoButton` for tactile elements, all built from four hand-rolled widgets in `lib/shared/widgets/` (no neumorphism/glass packages). **Before building or restyling any UI, consult the `flutter-ui` skill (`.claude/skills/flutter-ui/SKILL.md`) — it is the authoritative spec** for surfaces, the token system, responsive/no-overflow rules, and copy-paste component patterns. Tokens: `context.palette.*` (brightness-aware neutrals/text, `core/theme/app_palette.dart`), `AppColors.*` (fixed role accents — student `#1A56DB`, owner `#E05A2B`, teacher `#0D9488`), `AppSpacing.*`, `AppEffects.*`. Never inline a hex literal, raw size, animation `Duration`, or user-facing string (those go in `core/constants/app_strings.dart`).

## Conventions

- **No hardcoded values.** Strings → `AppStrings`; colours → `context.palette` / `AppColors`; sizes/spacing → `AppSpacing`; motion/blur/shadow → `AppEffects`.
- **`///` doc comment** on every public class and method; `const` constructors where possible. A widget reading `context.palette` can't be `const` — that's expected.
- **Tech stack is FIXED** — do not add a package not already in `pubspec.yaml`. Hand-draw unusual visuals with `CustomPainter` (e.g. the owner dashboard's 7-day chart); stub unavailable actions with a "Coming soon" snackbar (`AppStrings.stubComingSoon`). Photos/uploads are coloured placeholder tiles until a picker exists.
- **Every architectural decision is recorded as an ADR** in `decisions/00NN-<slug>.md` (currently up to 0048). When you make a non-trivial decision during a change, add a new numbered ADR and link it. ADRs are the detailed per-feature history — prefer reading the relevant ADR over re-deriving intent.
- **`.claude/agents/`** holds reusable subagents: `flutter-ui-stylist` (build/restyle UI), `flutter-data-layer` (wire a feature's data/API layer), `flutter-code-reviewer` (review Flutter changes), `api-contract-checker` (verify app↔backend wire contract). Dispatch these for the work they cover.

## Project status & roadmap

Phase 1 (project setup) is complete through Step 3; Step 4 (placeholder → real screens) has effectively been delivered feature-by-feature. **Built and on neoglass / palette-aware:**

- **Auth** — onboarding (animated 3-role selector), login + register + forgot-password screens, validation (`AuthValidators`), and the real backend-wired data layer (register/login/`/me` rehydration, secure token storage). ADRs 0023–0032.
- **Splash** — launch screen that gates on auth rehydration. ADR 0033.
- **Student shell** — Home (animated feed, **dashboard wired to `GET /api/students/dashboard`**), Search (**wired to `GET /api/search`**: 4 tabs, full filters, infinite scroll — ADR 0038; save/unsave toggle on each card; centre cards tap → centre detail), Centre detail (**wired to `GET /api/centers/:id` + `/reviews` + `POST /views` + `POST /enquiries`** — read-only profile + reviews list + Enquire sheet; reached from Search/Saved cards, ADR 0046), Teacher detail (**wired to `GET /api/teachers/:id` + `/reviews`** — read-only profile + reviews; reached from Search/Saved teacher cards; subjects passed via route `extra` since the endpoint returns bare ids; no enquiry/contact — backend has none for teachers, ADR 0047), Saved (**wired to `/api/students/bookmarks`** — list/create/delete via a shared `BookmarkController`, ADR 0040), Profile (**edit wired to `GET /auth/me` + `PATCH /students/me` + `POST /students/me/password`** — edit form + change-password, ADR 0041; + app-wide theme toggle). ADRs 0014–0018, 0026, 0038, 0040, 0041.
- **Owner shell** — **Setup gate** (`/owner-setup`, top-level — NO tabs): a freshly-authenticated owner lands here; it checks `GET /api/centers/me` (spinner) and forwards to the dashboard, or — when none — hosts the **3-step create-center wizard** (`CenterCreateWizard`: Basics → Location → Review, hand-built `CenterStepIndicator` at the top) → `POST /api/centers` → dashboard. `landingRouteForRole`/`_homeFor` for owner point here so a no-center owner can't reach the center-less dashboard. ADR 0043. Dashboard (**wired to `GET /api/owners/dashboard`** — live stats + 7-day views chart + recent-enquiries preview; static delta captions / avatar colours kept as fixtures, ADR 0042; header **greeting name** is the authenticated owner (`authControllerProvider.user`) and the **centre-name subtitle** is live from `GET /api/centers/me` via `myCenterProvider`, ADR 0043), Create-Center (`/manage-center/create` — same wizard under an AppBar; minimal fields + description, default geo coords since no map picker, one-owner-one-center `409`, ADR 0043), Manage-Center (**wired to `GET /api/centers/me` + `PATCH /api/centers/:id`** — read view + edit form via `manageCenterControllerProvider`; real `OwnerCenter` model, strict-partial save, id-based subject multi-select from `GET /api/subjects`, fee min/max range, full address fields, timings editor; photos/gallery still read-only/omitted, ADR 0044), Enquiries (**wired to `GET /api/owners/enquiries` (+ `/search`) + `GET`/`PATCH /api/owners/enquiries/:id`** — inbox: status filter New/Contacted/Closed, debounced search, infinite scroll, unread count; detail: contact + message + status control + private owner-notes editor. NO reply/chat (backend has none — an enquiry is one message + status + notes), ADR 0048), Profile (**edit wired to `GET /auth/me` + `PATCH /owners/me` + `POST /owners/me/password`** — read view + edit form (name/phone; email read-only) + change-password mirroring the student profile; business subtitle from `myCenterProvider`; theme toggle + logout; ADR 0045). ADRs 0018–0021, 0042, 0043, 0044, 0045.
- **Teacher shell** — Home, Search (find a center to affiliate with), Enquiries (inbox + detail), Schedule (week strip), Profile (read view + edit form). ADRs 0022, 0034–0037.
- **Cross-cutting** — theme-aware palette migration / dark mode (ADR 0017), floating bottom-nav restyle (ADR 0027), the neoglass design system itself (ADR 0028), shared `AdaptiveNavigation` + entrance-animation widgets.

Most non-auth screens are still **mock-backed** (fixtures, in-memory state that resets on restart); wiring them to the backend is the bulk of the remaining work. **Phase 2 scope is TBD with the user.**

### Known divergences
- **Android `minSdk`** — ADR 0003 chose 21, but Flutter's gradle plugin rewrites it to `flutter.minSdkVersion` (24) on every build, so the effective shipping value is 24. Needs a follow-up (find the override or update ADR 0003).

## Keeping this file current

This file is the living project context (it replaced the old `task.md` checklist). When a feature lands, a decision is made, or a convention changes, update the relevant section here and add the ADR under `decisions/`. Keep entries terse and link to the ADR for detail rather than duplicating prose — the value of this file is a fast, accurate orientation, not an exhaustive log.
