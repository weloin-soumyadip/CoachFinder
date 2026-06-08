# 0043 — Owner create-center flow + no-center dashboard CTA

**Status:** Accepted
**Date:** 2026-06-06

## Context

A freshly-signed-up **owner** has no coaching center. The owner Dashboard calls
`GET /api/owners/dashboard`, which `404`s ("No coaching center found for this owner")
for such an owner — and the dashboard rendered the generic cloud-off error card
(ADR 0042). There was no path anywhere in the app to create a center
(`CreateCenterScreen` was a `Center(child: Text(...))` placeholder; the `manage_center`
data layer was `// TODO` stubs).

The backend create-center API **exists** but is **not documented in `server/api.md`**
(that file covers only the auth endpoints). The contract was read directly from the
source:

- **`POST /api/centers`** (Bearer, `owner`) — body `centerCreateSchema` (`.strict()`,
  `server/src/schemas/centers.schemas.ts`):
  - **Required:** `name`, `address`, `location.coordinates [lng,lat]`, `city`, `state`,
    `pincode`, `phone`.
  - **Optional:** `description`, `area`, `country`, `alternatePhone`, `email`, `website`,
    `subjectsOffered[]`, `boards[]`, `classRange{from,to}`, `fees{min,max,currency}`,
    `timings[]`, `profileImage`, `bannerImage`, `gallery[]`.
  - One owner = one center → **409** "You already have a coaching center" if one exists.
  - Replies **201 `{ center }`** — **top-level `center`**, not nested under `data`
    (`server/src/controllers/centers.controller.ts:26`).
- **`GET /api/centers/me`** (Bearer, `owner`) → **200 `{ center }`** or **404** when none.

## Decision

Wired a minimal create-center flow and surfaced it from the dashboard's existing 404.

**UX — a full gate, not an inline form (final, per user).** A no-center owner is gated to a
**standalone setup screen with no bottom-nav tabs** until a center exists:

- **Routing.** `landingRouteForRole(owner)` and the redirect's `_homeFor(owner)` both point
  at a new **top-level** route `/owner-setup` (`OwnerSetupScreen`) that lives *outside* the
  owner `ShellRoute`, so it renders without the `AdaptiveNavigation` tabs. The redirect
  bounces any non-owner off `/owner-setup`. An owner therefore can't reach the (center-less,
  404-ing) dashboard or any other owner tab before creating a center.
- **The gate.** On mount `OwnerSetupScreen` calls `ManageCenterRepository.hasCenter()`
  (`GET /api/centers/me` → `200` = has, `404` = none). While checking → a centered
  `CircularProgressIndicator`. `has` → `goNamed(ownerDashboard)` (enters the shell). `none` →
  hosts the create wizard. Error → inline retry.
- **The wizard.** `CenterCreateWizard` is a **3-step** flow — Basics (name, description) →
  Location & contact (address, city, state, pincode, phone) → Review & create — with a
  hand-built `CenterStepIndicator` (numbered circles + connectors, owner-accent, the "Smart
  Stepper / Example" look; no package, per the fixed stack) pinned at the top. Each step
  validates before Next; the final step calls `POST /api/centers` (button spinner while it
  runs) and, on success, `onCreated()` forwards to the dashboard.
- The standalone `CreateCenterScreen` (`/manage-center/create` route) is now a thin
  AppBar+SafeArea wrapper around the **same** `CenterCreateWizard`, so there is one create
  UI. (The earlier single-page `CenterCreateForm` and the dashboard-inline / CTA-card
  variants were removed.)

**Dashboard 404 fallback.** The dashboard's `GET /api/owners/dashboard` 404→`noCenter`
mapping (`OwnerDashboardStatus.noCenter`) is kept as defense-in-depth, but with the gate in
place the dashboard is only reached with a center, so it falls through to the error card.

**Dashboard header made dynamic (follow-up).** The greeting name now reads the authenticated
owner (`authControllerProvider.user?.name`, first token), and the centre-name subtitle is
live from `GET /api/centers/me` via a small `OwnerCenterSummary` model + an `autoDispose`
`myCenterProvider` (falls back to the fixture `mockOwnerBusinessName` while loading / on
error). `autoDispose` keeps it fresh across logins and after a centre is created. This
supersedes ADR 0042's "header name + business name stay fixture-backed" note. The
`/centers/me` read is shared with the gate's existence check via `ManageCenterRepository.getMine()`
(`hasCenter()` now delegates to it).

**Location/geo — default coordinates, no map picker.** The stack is fixed (no
maps/geocoding package), but the backend requires `location.coordinates`. `CenterCreateRequest`
always stamps the India centroid `[78.9629, 20.5937]` (lng, lat). The owner refines the
precise location later via the Edit screen. Non-blocking; geo-search is simply imprecise
until edited.

**Form scope — required + description only.** The create form collects `name`, `phone`,
`address`, `city`, `state`, `pincode`, `description`. Boards/subjects/fees/timings/photos
are enriched afterward from the existing Edit screen (the selector widgets already exist).

**Data layer.** Implemented the two `manage_center` `// TODO` stubs:
- `ManageCenterRemoteDataSource.createCenter` → `rawPost(ApiConfig.centers, …)` (reads the
  top-level `{center}` envelope; the doc isn't needed on success).
- `ManageCenterRepository.create` → translates `ApiError` to `ManageCenterException`
  (surfacing the `409` message verbatim).
- New `center_create_request.dart` (strict `toJson`, default coords) and
  `create_center_provider.dart` (`CreateCenterController` StateNotifier, `submit()→bool`).
- `ApiConfig.centers` / `ApiConfig.centersMe` added.

## Consequences / notes

- The mock-backed manage-center **read / edit** screens (`manage_center_provider.dart` still
  seeds `mockCenter`) are **untouched** — wiring them to `GET /api/centers/me` + the doc model
  + `PATCH /api/centers/:id` is a deliberate follow-up, not this pass.
- The `409` re-create path surfaces the backend message as a snackbar; the form stays put.
- `server/api.md` is **auth-only** — future center/owner work must read the
  route/controller/schema in `../server/src/` directly, not trust `api.md`.
- Verified: `dart format` → `flutter analyze` clean → new model test (5 cases) green →
  `flutter build apk --debug` succeeds.
