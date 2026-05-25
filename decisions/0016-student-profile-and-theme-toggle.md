# 0016 — Student Profile screen + app-wide theme toggle

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (sections, sign-out behaviour, theme-toggler request) + Claude (structure, theme plumbing, fixtures)

## Context

The student shell's `/student-profile` route was a bare placeholder
(`Text('StudentProfileScreen')`). The user asked for the real Profile screen and
chose its composition: a **profile header**, a **settings menu list**, **sign
out** (behind a confirmation dialog), and — added during clarification — an
in-app **theme toggler**. The quick-stats row was explicitly dropped. No
screenshot was provided, so the screen was fabricated to match the app's design
language.

## Decision

### Profile screen

`student_profile_screen.dart` rewritten as a `HookConsumerWidget` (fixture-backed
like Home/Search/Saved; single column capped at 600 px and centred so it doesn't
stretch on wide/desktop layouts). Composition:

- **Header card** — initial avatar + full name (`mockUser`, shared with Home) +
  email (new `mock_profile_data.dart` fixture) + an outlined **Edit Profile**
  button.
- **Appearance** — a System / Light / Dark segmented selector (the same pill
  idiom as Search/Saved, with an icon per option).
- **Settings** — a card of placeholder rows (Notifications, Payment Methods,
  Help & Support, About) that surface a "Coming soon" snackbar. Edit Profile
  lives in the header, so it is not duplicated here.
- **Sign Out** — an `AppColors.error` outlined button → confirmation dialog →
  clears `keyJwtToken` + `keyCurrentUser` + `keyUserRole`, sets `roleProvider`
  to `null`, and navigates to `/onboarding` (the router then keeps the
  token-less session on the onboarding/auth flow).

### App-wide theme toggle

A dark `ThemeData` already existed and `MaterialApp` already wired
`theme`/`darkTheme`/`themeMode`, with `themeMode` hardcoded to
`ThemeMode.system`. The toggle therefore needed only state + persistence + UI:

- New `themeModeProvider` (`StateProvider<ThemeMode>`) plus a
  `themeModeFromStorage` decode helper, in `core/providers/`.
- `main.dart` hydrates the saved mode from `settingsBox` and overrides the
  provider (mirroring the existing `roleProvider` hydration); `CoachFinderApp`
  watches it for `MaterialApp.themeMode`.
- New `HiveKeys.keyThemeMode` in `boxSettings`. Selecting a mode sets the
  provider **and** persists `mode.name`.

## Known limitation (flagged to the user up front)

The existing bespoke screens (Home, Search, Saved, and this Profile) paint with
fixed `AppColors` (e.g. `neutralWhite` cards, `neutralGrey50` scaffolds) rather
than `Theme.of(context).colorScheme` tokens. So choosing **Dark** flips
Material-driven surfaces (nav bar, dialogs, system chrome) and the choice
persists correctly, but those custom screens **do not visually darken yet**.
Making every screen theme-aware is a larger, separate migration (replace fixed
`AppColors` usages with theme/`ColorScheme` tokens, or add dark variants).

## Alternatives considered

- **Stats row in the header** — offered, but the user dropped it.
- **Simple Light/Dark switch** instead of a 3-way selector — rejected to
  preserve the existing `ThemeMode.system` default as a first-class choice.
- **In-memory-only theme mode** — rejected; persisting via Hive matches how the
  role is stored and survives restarts.
- **Sign out → `/login`** (keeping the role) — rejected in favour of a full
  reset to `/onboarding`, per the chosen sign-out behaviour.

## Consequences

- Settings rows and Edit Profile are placeholder taps; they become real when
  the profile/account features land. The profile data-layer scaffold under
  `profile/data/` is still untouched `// TODO` (UI uses fixtures, same as Home).
- `themeModeProvider` is reusable by other roles' profile screens (owner /
  teacher) when they get real UIs.
- The hardcoded-colour limitation above is the main follow-up if true dark mode
  is wanted.

## Follow-ups

- Migrate screens to theme/`ColorScheme` tokens so Dark mode visually applies
  everywhere.
- Real profile data + edit flow via the profile controller/repository once the
  backend lands.
