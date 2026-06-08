# 0045 — Owner Profile (read / edit / change-password) backend wiring

**Status:** Accepted
**Date:** 2026-06-06

## Context

The owner **Profile** tab was mock-backed (`mock_owner_profile_data.dart`); the Edit button
was a "Coming soon" stub and there was no change-password flow (only the theme toggle +
logout were wired). The backend owner-self APIs are shipped (read from
`owners.routes.ts` / `owners.controller.ts` / `owners.schemas.ts` — `server/api.md` is
auth-only):

- **Read:** `GET /api/auth/me` → `{success, userType, user}` (the sanitized Owner doc).
- **Update:** `PATCH /api/owners/me` (`ownerSelfPatchSchema`, `.strict()`) accepts only
  `{name?, phone?, profileImage?}` → `{user: <doc>}`.
- **Password:** `POST /api/owners/me/password` `{currentPassword, newPassword}` →
  `{success, accessToken, refreshToken}` — **revokes all sessions and re-issues tokens**
  (must be persisted, like the student flow).

The Owner model is minimal — no owner-specific fields (no business name / bio / designation);
the "business name" the UI shows is the **centre** name.

## Decision

Cloned the student-profile feature (ADR 0041) for the owner — the pattern is identical minus
the academic fields.

**Data layer** (`owner/profile/data/`): `OwnerProfile` model (+ `initial`/`firstName`
getters), `OwnerProfileUpdate` (strict-partial `toJson`), remote datasource (`fetch` via
`/auth/me` reading top-level `user`; `update` via `PATCH /owners/me`; `changePassword`
returning the re-issued `PasswordChangeTokens`), repository (`OwnerProfileException`, injects
the shared `TokenStorage` and **persists the rotated tokens before returning** on password
change), and `OwnerProfileController` (`StateNotifier`, load + save + changePassword).
`ApiConfig.ownersMe` / `ownersMePassword`.

**Presentation:**
- `owner_profile_screen.dart` rewired: header identity (name, email, initial) from
  `ownerProfileControllerProvider`; the **business subtitle from `myCenterProvider`** (the
  centre name) since the owner has no business field; Edit → `ownerEditProfile`; a new
  **Change Password** settings row → `ownerChangePassword`. Theme toggle + logout unchanged.
- `edit_owner_profile_screen.dart` — name + phone editable, email read-only; strict-partial
  diff save (mirrors the student edit form).
- `change_password_screen.dart` (owner) — current/new/confirm, owner-orange; calls
  `OwnerProfileController.changePassword`.
- Nested routes `ownerEditProfile` (`/owner-profile/edit`) + `ownerChangePassword`
  (`/owner-profile/change-password`).

## Scope notes

- **Editable: name + phone only.** Email is read-only (no self-change endpoint). `profileImage`
  is accepted by the backend but there is no image picker in the fixed stack, so it isn't
  edited (an emptied phone is likewise omitted — the form can't clear it).
- The mock `mock_owner_profile_data.dart` is **kept** only because the dashboard header still
  uses `mockOwnerBusinessName` as a fallback while `myCenterProvider` loads.
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (113) →
  `flutter build apk --debug`. Live read/edit/password round-trip not yet walked on device.
