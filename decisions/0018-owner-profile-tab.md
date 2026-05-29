# 0018 — Owner Profile tab + screen

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + scope/section choices) + Claude (implementation)

## Context

The coaching-owner shell shipped with three tabs (Dashboard · Center ·
Enquiries) and no profile/account surface, while the student shell already had a
fully-built Profile screen (decision [0016]) with the app-wide theme toggle. The
user asked to add a **Profile** tab to the owner's bottom navbar, and chose
(via clarifying questions) a **full screen mirroring the student profile** with
all four sections — identity header, Appearance toggle, settings list, and Sign
Out — and an identity header showing **owner name + business name**.

## Decision

Added a fourth owner tab and a real `OwnerProfileScreen` that reuses the
student profile's structure and the existing theme/session plumbing, recoloured
to the owner brand.

- **Route:** new `AppRoutes.ownerProfile` → `/owner-profile`, added as a
  `GoRoute` inside the owner `ShellRoute` and to `_ownerPrefixes` so the
  cross-shell redirect guard treats it as owner-owned.
- **Shell:** `_OwnerShell` grew from 3 → 4 destinations (added Profile, the
  `person_outline`/`person` icon pair already used by the other shells), with
  matching `_indexFor` (`/owner-profile` → 3) and `_onTap` cases.
- **Screen:** `lib/features/owner/profile/presentation/screens/owner_profile_screen.dart`
  — `HookConsumerWidget`, single column capped at 600 px. Identity header
  (avatar initial, owner name, business-name subtitle, email, Edit Profile),
  Appearance System/Light/Dark selector, placeholder settings card
  (Notifications · Billing · Help & Support · About → "Coming soon" snackbar),
  and Sign Out behind a confirm dialog (clears token + role → `/onboarding`).
- **Fixtures:** `lib/features/owner/profile/data/mock_owner_profile_data.dart`
  (`mockOwnerName`, `mockOwnerBusinessName`, `mockOwnerEmail`,
  `mockOwnerInitial`). The owner had no `mockUser` equivalent, so a dedicated
  fixture file was added rather than overloading the student's.
- **Strings:** reused the generic `profile*` strings; added one owner-specific
  label `ownerProfileBilling = 'Billing'` (owner billing in place of the
  student's "Payment Methods").

### Theme / brand choice

The theme toggle, persistence (`themeModeProvider` + `keyThemeMode` via
`settingsBox`), and sign-out flow are **identical** to the student screen — same
provider, same Hive keys — so the choice stays app-wide and consistent.

The **accent** differs: where the student profile uses the student blue, the
owner screen uses the fixed `AppColors.ownerAccent` (orange) for the avatar
fill, the business-name line, the Edit Profile outline, and the selected
Appearance pill. Per the palette migration rules (decision [0017]),
`ownerAccent` is a fixed brand token that reads in both themes, and it is only
used as a *fill behind white* (avatar/pill) or as a *foreground on the
neutral surface* (business name, button border) — both legible in light and
dark. All neutrals/text route through `context.palette.*`, so the screen is
theme-aware like the rest of the app.

## Consequences

- The owner now has parity with the student for account/appearance/sign-out;
  the teacher shell still has a placeholder Profile (separate later task).
- Edit Profile and every settings row are placeholders ("Coming soon"); Billing
  is a label only. Real owner-account UI is a later, backend-wired task.
- The owner Dashboard/Center/Enquiries screens remain bare placeholders — only
  the Profile tab is real.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
