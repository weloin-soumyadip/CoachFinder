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

## Known divergences

- **Android `minSdk`** — decision [0003](decisions/0003-min-sdk-android-21-ios-12.md) chose 21, but Flutter master's gradle plugin persistently rewrites `minSdk` → `flutter.minSdkVersion` (= 24) on every build. Effective shipping value is 24. Needs a follow-up: either find the override mechanism or update 0003.

## Future phases

- [ ] **Phase 2** — TBD (decided with user)

---

## Conventions

- Tick a box only when the step is fully done and verified.
- New decisions made during a step → add a new file under `decisions/` and link it from the relevant phase doc in `docs/`.
- New phase started → add `docs/phase-XX-<slug>.md` with the plan, and append a new section to this file.
