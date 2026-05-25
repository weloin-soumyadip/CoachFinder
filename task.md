# CoachFinder — Task List

> Master checklist tracking work across all phases. Updated at the end of every step.

## Phase 1 — Project setup

- [x] **Step 0** — `flutter create` scaffolding (org `com.weloin`, project `coachfinder`, platforms `android,ios`)
- [x] **Step 1** — `pubspec.yaml` rewrite with the 9 runtime + 3 dev packages; Android `minSdk = 21`; iOS deployment target `12.0`; `flutter pub get`
- [x] **Step 2** — Skeleton folder + file creation (100 files across 80 directories, each `///` doc + `// TODO: implement`)
- [x] **Step 3** — Fully implement `core/` (theme, router, network, storage, error, providers) and `main.dart` (20 files, 14 expected screen-class errors blocking compile until Step 4)
- [ ] **Step 4** — Placeholder screens + real onboarding screen with role-selector logic

## Post-Phase-1 iterations

- [x] **Onboarding UI redesign** — select-then-continue flow with two role cards and Continue CTA (matches user's screenshot)
- [x] **Login screen UI** — branded badge, email + password with visibility toggle, Forgot Password link, Google / Apple buttons, Sign Up footer link. Submit / social / forgot-password buttons are stubbed via SnackBar (no backend wired)
- [x] **Register screen UI** — top bar with back arrow, Google / Apple, Full Name / Email / Password / Confirm Password, Terms checkbox with inline links, CREATE ACCOUNT button, Sign In footer link. Same stub pattern.
- [x] **`lib/shared/` folder added** — `shared/layouts/adaptive_navigation.dart` for the role-agnostic shell; `shared/widgets/` reserved. See [decision 0011](decisions/0011-shared-folder-and-adaptive-navigation.md).
- [x] **AdaptiveNavigation wired into both shells** — `_StudentShell` and `_OwnerShell` in `app_router.dart` now use `AdaptiveNavigation` (`NavigationBar` < 768 px, `NavigationRail` ≥ 768 px). Breakpoint bumped from 600 to 768 to keep phone landscape on the bottom bar. Green nav indicator added per Home design.
- [x] **Student Home (mobile)** — full layout built with fixture data: top bar, greeting, Next Session featured card, horizontally-scrolling Trending Topics rail, Recommended For You coach list, Personalized Path card with progress ring, action tiles row, chat FAB. Fixture file: `lib/features/student/home/data/mock_home_data.dart`. Widgets filled: `category_chip_widget.dart` (TopicChip) and `featured_card_widget.dart` (CoachCard).
- [x] **Teacher role added (3rd role)** — plumbing + placeholders. New `roleTeacher` constant, teal accent (`#0D9488`), third onboarding card, 5 teacher routes + `_TeacherShell` (Home · Search · Enquiries · Schedule · Profile), 5 placeholder screens under `lib/features/teacher/`. Redirect guard refactored from binary to N-role (`_homeFor` + generalized cross-shell check); `landingRouteForRole` added for the auth dev-shortcuts. Onboarding converted to scroll-safe layout so 3 cards don't overflow small phones. See [decision 0012](decisions/0012-teacher-role.md). Real teacher screen UIs are a later, per-design task.
- [x] **Debug test-credential sign-in bypass** — login now signs in only on `test@gmail.com` / `test-password` (`DevCredentials`), gated by `kDebugMode`; wrong input shows an error, release builds disable it. Register's dev-shortcut wrapped in the same `kDebugMode` gate so no backdoor ships. A debug-only hint pill under the Log In button shows the test credential. See [decision 0013](decisions/0013-debug-test-credential-bypass.md).
- [x] **Student Search (mobile + desktop)** — search bar with live local filtering, segmented tabs (All / Teachers / Institutes), resting state (browse-by-category chips + recent searches), and a "Found N …" results header with Filters link. Responsive grid (1 col phone, up to 3 on wide layouts, content capped at 1100px). New fixtures + models in `mock_search_data.dart` (`SearchTeacher`, `SearchInstitute`, `SearchEntityType`); widgets `search_field_widget.dart`, `teacher_result_card.dart`, `institute_result_card.dart`. Result taps + Filters are placeholders. See [decision 0014](decisions/0014-student-search-screen.md).
- [x] **Student Saved (mobile + desktop)** — search field + All / Coachings / Tutors filter over the student's bookmarked tutors and coaching institutes. Reuses the Search result cards (now with an optional `onUnsave` footer control) and the responsive grid; a working filled-bookmark un-save toggle removes items from local hook state and reveals an empty state. New dedicated `lib/features/student/saved/` feature (`mock_saved_data.dart` with `SavedFilter` enum + fixtures reusing the Search models; real `saved_screen.dart`). New shared `SavedBookmarkButton` in `lib/shared/widgets/`. The old placeholder under `profile/` and the stale `saved_center_tile_widget.dart` stub were removed; router import repointed. Un-save is local-only (no backend); card taps are placeholders. See [decision 0015](decisions/0015-student-saved-screen.md).
- [x] **Theme-aware colour migration (dark mode)** — introduced a `ThemeExtension<AppPalette>` (`lib/core/theme/app_palette.dart`) of brightness-aware semantic tokens (surface, background, text {primary,secondary,muted}, border(Subtle), iconFaint, inputFill, primary, primaryTint) accessed via a `context.palette` extension; registered on both themes with a per-brightness `scaffoldBackgroundColor`. **Light values are the original colours exactly** (light mode unchanged); dark = "Dim charcoal". Migrated 22 UI files off fixed `AppColors` neutrals/brand-foregrounds, keeping `studentPrimary` fills + white-on-colour foregrounds + fixed semantic tokens. Dark hexes added to `app_colors.dart`. Now the whole app (not just Material chrome) responds to the theme toggle. Foundation + 2 exemplars by hand, remaining ~18 files via 4 parallel subagents. See [decision 0017](decisions/0017-theme-aware-palette-migration.md).
- [x] **Tab bar visibility / theming** — `adaptive_navigation.dart` now colours the bottom `NavigationBar` + side `NavigationRail` entirely from the `ColorScheme`: transparent background (blends with the surface), no coloured indicator pill, selected = full-strength `onSurface` + bold + filled icon, unselected = `onSurfaceVariant` (dark in light theme, light in dark theme). Hover tooltips suppressed (`tooltip: ''`).
- [x] **Student Profile + app-wide theme toggle** — real `student_profile_screen.dart` (fixture-backed, single column capped at 600px): identity header (avatar + name + email + Edit Profile), an **Appearance** System/Light/Dark selector, a placeholder settings list (Notifications / Payment Methods / Help & Support / About → "Coming soon" snackbar), and **Sign Out** behind a confirm dialog (clears token + role → `/onboarding`). Theme toggle is fully wired: new `themeModeProvider` + `keyThemeMode`, hydrated/persisted via `settingsBox` (mirrors role), `MaterialApp.themeMode` now watches it. New `mock_profile_data.dart` (email fixture). **Caveat:** existing screens use fixed `AppColors`, so Dark flips Material surfaces + persists but those bespoke screens don't visually darken yet — full theme-token migration is a follow-up. See [decision 0016](decisions/0016-student-profile-and-theme-toggle.md).

## Known divergences

- **Android `minSdk`** — decision [0003](decisions/0003-min-sdk-android-21-ios-12.md) chose 21, but Flutter master's gradle plugin persistently rewrites `minSdk` → `flutter.minSdkVersion` (= 24) on every build. Effective shipping value is 24. Needs a follow-up: either find the override mechanism or update 0003.

## Future phases

- [ ] **Phase 2** — TBD (decided with user)

---

## Conventions

- Tick a box only when the step is fully done and verified.
- New decisions made during a step → add a new file under `decisions/` and link it from the relevant phase doc in `docs/`.
- New phase started → add `docs/phase-XX-<slug>.md` with the plan, and append a new section to this file.
