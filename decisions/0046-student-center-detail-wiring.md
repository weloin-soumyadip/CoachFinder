# 0046 — Student coaching-center detail screen (backend-wired)

**Status:** Accepted
**Date:** 2026-06-06

## Context

The student center-detail screen (`/center/:id`, `studentCenterDetail`) was a placeholder
(`Text('CenterDetailScreen (id: …)')`) with stub data files, and the Search / Saved cards
didn't navigate to it (their `onTap` was unwired). The backend exposes a rich public surface
(read from `centers.routes.ts` / `centers.controller.ts` / `centerReviews.*` / `enquiries.*`
— `server/api.md` is auth-only):

- **`GET /api/centers/:id`** → `{center}` via `projectCenterPublic` (name, description, full
  address, phone/altPhone/email/website, `subjectsOffered` populated `{_id,name}`, boards,
  classRange, fees, timings, profileImage/bannerImage/gallery, averageRating, totalReviews,
  isVerified). 404 on missing/inactive.
- **`GET /api/centers/:id/reviews`** → paginated `{data:[{student{name,profileImage}, rating,
  comment, createdAt}], pagination}`.
- **`POST /api/centers/:id/enquiries`** (student) → `{message, subject?}`.
- **`POST /api/centers/:id/views`** (student/teacher) → fire-and-forget analytics.

## Decision

Scope **A** (confirmed with the user): read-only detail **+ reviews list + Enquire**. (No
"write a review" this pass.)

**Data layer** (`student/center_detail/data/`, the former stubs): `CenterDetail` model (+
nested `CenterDetailFees`/`ClassRange`/`Timing`/`Subject`), `CenterReview` model, datasource
(`fetchById` / `fetchReviews` / `recordView` / `createEnquiry`), repository
(`CenterDetailException`; `recordView` is best-effort and never throws), and an
`autoDispose` **family** controller `centerDetailControllerProvider(centerId)` that on first
read fetches the centre, then (non-fatally) the first page of reviews, and records a view —
plus a `submitEnquiry()` mutation. `ApiConfig.centerReviews/centerViews/centerEnquiries`
path helpers added (`centerById` reused for the GET).

**Screen** (replaces the stub): an AppBar (back) + scrollable sections — header
(banner/logo via `Image.network` with fallbacks, name, ★rating + N reviews, verified badge,
location), about, subjects/boards/class-range chips, fees, timings, contact, and a reviews
list (empty state when none). A pinned **Enquire** bottom bar opens a modal sheet (message +
optional subject dropdown from the centre's subjects → `POST` enquiry → snackbar). Student
accent (`AppColors.studentPrimary` / `palette.primary`), flat `palette.surface` cards (the
student shell hasn't migrated to neoglass).

**Navigation:** the Search result `CenterSearchCard` and the Saved coaching-centre card now
push `studentCenterDetail` with the real backend `_id` (`center.id` / `bookmark.targetId`).

## Deviations (fixed stack)

- **No map** — address shown as text (no maps/geocoding package).
- **Call / Email** — the contact rows display the values; tap-to-call/email is not wired
  (no `url_launcher`). (No "Coming soon" buttons added — kept the rows informational.)
- Banner / logo via `Image.network` with a coloured-placeholder `errorBuilder`.

## Consequences / notes

- The unused widget stubs under `center_detail/presentation/widgets/` (map, gallery, etc.)
  were left in place (empty libraries; harmless). Reviews load the first page only (limit 50)
  — no infinite scroll (a future item if needed).
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (117) →
  `flutter build apk --debug`. Live tap-through (search → detail → enquire) not yet walked on
  device.
