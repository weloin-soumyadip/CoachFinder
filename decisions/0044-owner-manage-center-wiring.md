# 0044 — Owner Manage-Center (read + edit) backend wiring

**Status:** Accepted
**Date:** 2026-06-06

## Context

The owner **My Center** tab (read view + edit form) was fully mock-backed
(`mock_center_data.dart`'s `CenterProfile` + an in-memory `NotifierProvider`).
The backend centre APIs are shipped (not in `server/api.md`, which is auth-only —
read from `centers.controller.ts` / `centers.schemas.ts` instead):

- **`GET /api/centers/me`** (owner) → `{center: <full doc>}` (not projected), with
  `subjectsOffered` populated to `{_id,name,slug}`. `404` when none.
- **`PATCH /api/centers/:id`** (owner, `.partial().strict()`) → `{center: <updated>}`;
  `403` if not yours; re-slugs on name/city change; rejects unknown keys.
- **`GET /api/subjects`** → `{data:[{_id,name,slug}], pagination}` — backs the subject picker.

The mock `CenterProfile` didn't map 1:1 to the backend `CoachingCenter`, so the wiring
involved deliberate scope decisions (confirmed with the user).

## Decision

Replaced the mock with a real data layer + rewired both screens.

**Data layer** (`manage_center/data/`):
- `OwnerCenter` (full model) + nested `CenterFees{min,max,currency}` /
  `CenterClassRange{from,to}` / `CenterTiming{day,openTime,closeTime,closed}` and
  `subjects: List<SubjectOption>`. Null-tolerant `fromJson`; the nested objects carry
  `toJson` for reuse.
- `CenterUpdate` — strict-partial `toJson` (only changed keys; `subjectIds` →
  `subjectsOffered`).
- `SubjectOption{id,name}` for `/api/subjects`.
- Datasource `updateCenter` (`PATCH`) + `fetchSubjects`; repository `getMine`→`OwnerCenter?`,
  `update`→`OwnerCenter`, `fetchSubjects`. `getMine` now returns the **full** `OwnerCenter`
  (the old lightweight `OwnerCenterSummary` was removed; the dashboard header + gate use the
  full model's `name` / non-null). `ManageCenterController` (`StateNotifier`, load + save) +
  `subjectsProvider` (FutureProvider). `ApiConfig.centerById` / `ApiConfig.subjects`.

**Read view + edit form** rewired to `manageCenterControllerProvider` (loading / error /
data states). The edit form seeds from the loaded centre, builds a `CenterUpdate` diff (only
changed fields), and `PATCH`es; subjects are an id-based multi-select from `subjectsProvider`;
timings convert between the backend `HH:mm`/`closed` shape and the UI's `TimeOfDay` editor
(seeded to a full Mon–Sun set, sent only when touched).

## Mock-vs-backend reconciliation (user-confirmed scope)

| Mock UI | Backend | Decision |
|---|---|---|
| Per-course fee list (`CourseFee`) | single `fees{min,max,currency}` | **Replaced with a min/max fee range** (the list had no backend home). |
| `subjects: List<String>` names | `subjectsOffered` ObjectId refs | **Real multi-select from `GET /api/subjects`**, persisting ids. |
| single `location` text label | `address`+`area`+`city`+`state`+`pincode` | **Expanded to proper address fields.** GeoJSON `location` left untouched (no map picker; partial PATCH omits it). |
| `tagline`, per-course fees, photo *editing*, `profileViews` | no equivalent | **Dropped.** `description` is the "about"; gallery has no uploader (read-only/omitted); stats strip shows rating + reviews only. |
| `boards` incl. `'State Board'` | enum incl. `'State'` | Use the backend enum values verbatim (`OwnerCenter.boardOptions`). |

## Consequences / notes

- `mock_center_data.dart` + `image_upload_widget.dart` + `owner_center_summary.dart` removed;
  `DayTiming` + time helpers moved into `timing_editor_widget.dart`; `subject_selector_widget`
  is now id-based.
- `GET /api/subjects` is fetched with `limit=100` (first page) — fine for a picker; a
  type-ahead/paged picker is a future item if the subject list grows.
- Clearing an *optional* field that must be a valid URL/email/non-empty (website, email, area,
  alternatePhone) isn't supported (the diff omits empties) — mirrors the student-profile edit.
- Gallery/photos display + upload remains out of scope (no picker in the fixed stack).
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (108) →
  `flutter build apk --debug`. End-to-end against a live centre not yet walked on device.
