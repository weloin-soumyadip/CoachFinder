# 0042 — Owner dashboard wiring

**Status:** Accepted
**Date:** 2026-06-04

## Context

The owner Dashboard tab was fully fixture-backed (`mock_dashboard_data.dart`).
The backend shipped the endpoint (server `task.md`, `dashboard.controller.getOwnerDashboard`,
routed at `owners.routes.ts`):

**`GET /api/owners/dashboard`** (Bearer, owner) → `{ success, data: { weeklyProfileViews,
weeklyEnquiries, averageRating, totalReviews, activeStudents, profileViewStats[7]{date,views},
recentEnquiries[≤5]{enquiryId,studentName,phone,email,message,createdAt} } }`. Auto-resolves
the owner's single center (one owner = one center); `404 "No coaching center found for this
owner"` when none. Nested under `data` (like the bookmarks list).

## Decision

Wired the dashboard to the live endpoint, **without removing any static field the
endpoint doesn't supply** (explicit user constraint).

**Data layer** (`lib/features/owner/dashboard/data/`, the four `// TODO` stubs):
- `OwnerDashboardData` + `ProfileViewPoint{date,views}` + `RecentEnquiry{…}` — null-tolerant
  `fromJson` with int/double/string-number coercion and `DateTime.tryParse` dates.
- Datasource (`rawGet` → reads `body['data']`), repository (`OwnerDashboardException`,
  surfaces the 404 verbatim), and an `OwnerDashboardController` (`StateNotifier`,
  re-entrancy-guarded `load()` fired on first read) mirroring the bookmarks/profile
  controllers. `ApiConfig.ownersDashboard` added.

**Presentation** (`owner_dashboard_screen.dart`):
- Watches `ownerDashboardControllerProvider`; a `_DashboardBody` shows a spinner while the
  first load is in flight, an inline retry (`_DashboardError`) on failure, otherwise the
  mapped sections.
- API→view-model mappers (`_statsFrom` / `_viewsFrom` / `_enquiriesFrom`) build the existing
  `DashboardStat` / `DailyViews` / `EnquiryPreview` view models from the live data, **keeping
  their static fields** (icons, accents, avatar colours, `isNew`). `mock_dashboard_data.dart`
  (the view-model classes + fixtures) is left intact.

## Static-vs-live mapping (user constraint: keep static, don't remove)

| UI element | Source |
|---|---|
| Profile Views / New Enquiries / Active Students values | live (`weekly*`, `activeStudents`) |
| Rating value + "N reviews" caption | live (`averageRating`, `totalReviews`) |
| 7-day views chart | live (`profileViewStats`) |
| Recent-enquiry id/name/message/time | live (`recentEnquiries`; `timeAgo` derived from `createdAt`) |
| Stat **delta captions** ("+12%", "+3 today", "+5 this month") + trend arrows | **not in API** — fields kept, but **not rendered** (a fixed "+12%" beside a real number misleads; per user, hide the misleading deltas without deleting the model fields) |
| Enquiry avatar colour, `isNew` flag | **not in API** — kept static (fixture colour cycled by index; `isNew` defaults false) |
| Header owner name + business name | **not in this endpoint** — stays fixture-backed (`mock_owner_profile_data.dart`) |

## Consequences / notes

- `intl` is not in the stack, so a small `_formatCount` groups thousands by hand.
- Verified live (`owner@coachfinder.dev`): `200` with `averageRating 4.7 / totalReviews 88`,
  zero-filled 7-day series, empty `recentEnquiries` (that owner has no ProfileView/enquiry
  seed) — the empty-enquiries state renders.
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (93 tests) →
  `flutter build apk --debug` succeeds.
