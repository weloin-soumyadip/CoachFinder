# 0024 — Auth redesign from external spec (Sign In / Sign Up / Forgot Password)

**Status:** Accepted (supersedes the hero layout of [0023])
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (external design spec + 3 reconciliation choices) + Claude (adaptation)

## Context

The user supplied a detailed external spec for three auth screens (Sign Up,
Sign In, Forgot Password) with a green theme and a literal stack
(`StatefulWidget` + `setState` + `GlobalKey<FormState>`, top-level `lib/widgets/`,
raw routes `/signup`…, `dart analyze`). That conflicts with the project on
several axes (blue brand + no-hardcoded-color system, `HookConsumerWidget` +
Riverpod, feature-folder widgets, named `AppRoutes`), and the screens overlap
the existing login/register (redesigned with a hero in [0023]). The spec also
had template bugs (Sign Up titled "Welcome Back!"; a Forgot Password **password**
field; wrong bottom links).

Rather than apply it verbatim, three reconciliation questions were asked. The
user chose: **blue brand**, **project conventions**, and **replace login/register
+ add Forgot Password**.

## Decision

Took the spec's **layout, fields, validation, and UX**, rendered in the project's
conventions: blue via `context.palette`/`AppColors.studentPrimary`,
`HookConsumerWidget` + hooks, widgets in `lib/features/auth/presentation/`,
named routes. This **replaces the [0023] hero layout** with a flatter
back-button + title + subtitle + form layout (no gradient hero, no card).

- **Validation** uses `Form` + a `useMemoized(GlobalKey<FormState>.new)` (the
  hooks equivalent of the spec's `GlobalKey<FormState>`); fields are
  `TextFormField`s via the upgraded `AuthFieldWidget`, validated on submit by a
  new `AuthValidators` (`notEmpty` / `email` / `password` ≥8 / `confirmPassword`
  match). Obscure toggles and the "Remember for 30 days" checkbox are `useState`
  (the hooks equivalent of `setState`).
- **Widgets** (in the auth feature folder, not a top-level `lib/widgets/`):
  upgraded `AuthFieldWidget` (M3 floating-label `TextFormField` + `validator`);
  reused `AuthPrimaryButton` (the green→blue CTA), `AuthOrDivider` ("Or"),
  `AuthBottomLink`; reused `AuthOAuthButton` for the stacked "Continue With
  Google/Facebook" buttons. Removed the now-unused `AuthHero`,
  `AuthHeroBackButton`, `AuthCard`, `AuthBrandingBadge`, and register's
  `_TermsCheckbox`. (A per-spec `AuthBackButton` was added then removed at the
  user's request — see Update below.)
- **Screens:** `LoginScreen` (Sign In: email, password, remember + Forgot link
  row), `RegisterScreen` (Sign Up: first/last name Row, email, password,
  confirm), and new `ForgotPasswordScreen` (email only). Each capped at 480 px,
  centered.
- **Routes:** new `AppRoutes.forgotPassword` → `/forgot-password` (sibling of
  login/register), added to the redirect's `isAuthRoute` so it's reachable
  without a token. Kept the existing `/login` and `/register` paths/names so the
  onboarding flow and redirect guard don't churn (the spec's `/signin` `/signup`
  were declined with "project conventions").

### Behaviour preserved & template bugs fixed

- The `kDebugMode` test-credential sign-in, role passing
  (`landingRouteForRole`), and register dev-shortcut are **unchanged** — now
  gated behind `formKey.validate()`. Social buttons + Forgot/Recover are
  stubs/SnackBars (no backend; the fixed stack has no real auth).
- Corrected the spec's template bugs: Sign Up keeps the correct "Create Account"
  title (not "Welcome Back!"); Forgot Password **omits the password field** (you
  don't enter a password to recover one); bottom links point the right way
  ("Remember your password? Sign In" on Forgot).

## Consequences

- `studentPrimaryDark` (added in [0023] for the hero gradient) is now unused but
  kept (harmless, plausibly reusable).
- The "Remember for 30 days" value is local-only (not yet persisted) until real
  auth lands.
- Per the user's "visual + conventions" scope, the green palette was not
  introduced; auth stays on-brand blue.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.

## Update (2026-05-27)

The user asked to **remove the back button** from all auth screens. The spec's
circular back button, its per-screen `goBack` handlers, and the `AuthBackButton`
widget were removed; lateral navigation is handled entirely by the bottom links
(Sign In ⇄ Sign Up, and "Remember your password? Sign In" on Forgot Password).
The heading's top padding was bumped (`sp16` → `sp32`) now that nothing sits
above it. Re-verified: analyze clean, build succeeded.
