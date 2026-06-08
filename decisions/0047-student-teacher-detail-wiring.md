# 0047 — Student teacher detail screen (backend-wired)

**Status:** Accepted
**Date:** 2026-06-06

## Context

The student Search "Teachers" tab listed teacher cards whose `onTap` was a no-op — there was
no teacher detail screen (only the centre detail, ADR 0046). The user asked that tapping a
teacher (or centre) card opens a detail screen for that item; centre cards were already wired
in ADR 0046, so this adds the **teacher** detail.

Backend (read from `teachers.routes.ts` / `teachers.controller.ts` / `teacherReviews.*`):

- **`GET /api/teachers/:id`** → `{teacher}` via `projectTeacherPublic`: name, profileImage,
  bio, `subjects` (**bare ObjectIds — NOT populated**), education[], experienceYears,
  feesRange, batches[], languages[], boards[], classRange, city/state, averageRating,
  totalReviews, isVerified. 404 on missing/inactive. (email/phone are stripped — no contact.)
- **`GET /api/teachers/:id/reviews`** → paginated `{data:[{student{name,profileImage}, rating,
  comment, createdAt}], pagination}`.
- **No teacher enquiry** and **no teacher view-tracking** exist (enquiries are centre-only) —
  so the teacher detail is **read-only profile + reviews**.

## Decision

Built `student/teacher_detail/` mirroring the centre-detail feature (ADR 0046), minus the
Enquire CTA and view recording.

**Data layer:** `TeacherDetail` model (+ nested `TeacherFees` / `TeacherClassRange` /
`TeacherEducation` / `TeacherBatch`) + `TeacherReview`; datasource (`fetchById`,
`fetchReviews`), repository (`TeacherDetailException`), and an `autoDispose` **family**
controller `teacherDetailControllerProvider(teacherId)` that loads the teacher then
(non-fatally) the first page of reviews. `ApiConfig.teacherById` / `teacherReviews` added.

**Screen:** AppBar + scrollable sections — header (avatar, name, ★rating + N reviews,
verified, location), About (bio), Subjects, Boards, Classes, Experience, Languages, Fees,
Education list, Batches (schedule), and a reviews list. Student accent, flat surface cards.

**Subjects workaround:** the endpoint returns subject **ids** (unpopulated), so the
originating Search / Saved card passes the already-flattened subject **names** via the route's
`extra` (a `List<String>`); the screen prefers populated names if ever present, else the
passed names. On a web hard-reload (no `extra`) the subjects section is simply hidden.

**Navigation:** the Search teacher card and the Saved teacher card now push
`studentTeacherDetail` (`/teacher/:id`) with `extra: teacher.subjects`. `/teacher` added to
the router's `_studentPrefixes` (cross-shell guard parity with `/center`).

## Consequences / notes

- No contact actions (the public teacher projection strips email/phone); no enquiry (backend
  has none for teachers). Reviews load the first page only (limit 50).
- The `TeacherReview` model duplicates the centre `CenterReview` shape (per the per-feature
  model convention) rather than sharing a cross-feature model.
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (122) →
  `flutter build apk --debug`. Live tap-through not yet walked on device.
