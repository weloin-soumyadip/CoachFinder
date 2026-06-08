# 0041 — Student profile edit + change-password wiring

**Status:** Accepted
**Date:** 2026-06-04

## Context

The student Profile tab's identity header was rendered from fixtures
(`mockUser` + `mock_profile_data.dart`) and the **Edit Profile** button was a
"Coming soon" stub. The backend already exposed everything needed:

- `GET /api/auth/me` → `{ success, userType, user }`, where `user` is the full
  sanitized student doc (password stripped). This is the read/prefill source.
- `PATCH /api/students/me` → strict partial update (only keys present are
  written). Editable keys: `name`, `phone`, `profileImage`, `dateOfBirth`,
  `gender` (`male|female|other|prefer_not_to_say`), `currentClass` (1–12),
  `board` (`CBSE|ICSE|State|IB|IGCSE|Other`), `city`, `location`. Returns
  `{ user }` at the top level.
- `POST /api/students/me/password` → `{ currentPassword, newPassword }`;
  **revokes all refresh tokens** and returns a fresh `{ accessToken, refreshToken }`.

## Decision

Wired the feature end-to-end following the established **read-view + edit-form**
pattern (mirrors the teacher profile, ADR 0037) and the flat-shell migration
boundary (flat `FilledButton` + `palette.inputFill` fields, not NeoButton/Glass).

**Scope (confirmed with the user):** the full editable field set **minus**
`profileImage` (no image picker exists — deferred) and `location` (geo, no map
UI). Plus the **Change Password** flow. Account deletion was explicitly left out.

**Data layer** (`lib/features/student/profile/data/`):
- `StudentProfile` model + `StudentGender` / `StudentBoard` wire enums
  (`wireValue`/`label`/null-tolerant `fromWire`), null-tolerant `fromJson`.
- `StudentProfileUpdate` — `toJson()` emits **only non-null** keys so the PATCH
  stays a true partial; an all-null update short-circuits the round-trip.
- Datasource (`fetch` → `/auth/me`, `update` → PATCH `/students/me`,
  `changePassword` → POST), repository (`StudentProfileException`), and a
  `StudentProfileController` (`StateNotifier`) mirroring `bookmarks_provider`.
- `ApiClient.rawPatch` added (no PATCH verb existed); `ApiConfig.studentsMe` +
  `studentsMePassword`.

**Presentation** (`presentation/screens/`):
- `EditStudentProfileScreen` — gates on the controller state (spinner / retry /
  seeded form), builds a **diff** `StudentProfileUpdate` (only changed fields),
  saves, snackbars + pops on success.
- `ChangePasswordScreen` — current/new/confirm, validated client-side (min-6,
  match, must-differ), surfaces the backend's verbatim message on failure.
- `StudentProfileScreen` — header bound to the live profile; Edit → edit route;
  new **Change Password** settings row → its route.
- Nested `edit` + `change-password` `GoRoute`s under `/student-profile`.
- Deleted the orphaned `mock_profile_data.dart`.

## Consequences / notes

- **Password change keeps the session alive.** The server revokes all refresh
  tokens on change, so the repository persists the re-issued `accessToken` /
  `refreshToken` (from the response body) to the shared `TokenStorage` *before*
  returning. Without this, the next 401 would fail refresh and bounce the user
  to login (see ADR 0039 for the interceptor). The UI does nothing special.
- **DOB is treated as date-only.** It serialises to a bare `YYYY-MM-DD` (local
  calendar components, no time/zone) and the change-diff compares on the date
  component only — otherwise a local-midnight pick shifts a day across the UTC
  boundary on the round-trip (off-by-one display) and an unchanged DOB gets
  re-sent. The backend's `z.coerce.date()` accepts the bare date.
- `email` is read-only in the form (the backend doesn't accept it on this PATCH).
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (83 tests)
  → `flutter build apk --debug` succeeds. Reviewed by `flutter-code-reviewer`.
