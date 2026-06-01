# 0036 — Teacher Enquiries (inbox + conversation + reply)

**Status:** Accepted
**Date:** 2026-05-30
**Phase:** Round 5 — building out the teacher shell's tab screens.
**Made by:** User (one-line directive: "now lets do the enquery screen") +
Claude (design approval → flutter-ui implementation).

## Context

Continuing the teacher shell build-out (ADRs 0034 home, 0035 search), the
Enquiries tab was still a placeholder. A teacher — an independent tutor — gets
enquiries directly from students. The owner already has a full enquiries
feature (ADR 0020: inbox + detail + reply, backed by a Riverpod `Notifier`).

Earlier this session the user **reverted the glassmorphism restyle** of the
owner enquiry inbox ("I don't want that kind of a screen"), keeping its flat
treatment. So although the teacher home/search use the teal neoglass system,
the enquiries surface is intentionally *flat*.

Through the design flow the user chose:

- **Scope:** the full feature — inbox + conversation/detail + reply (not
  list-only).
- **Style:** flat + teal, matching the owner inbox they kept (not glass). This
  is also the right call for a scrolling `ListView` (no per-frame `BackdropFilter`
  re-blur).

## Decision

Built the teacher enquiries feature as a teal-branded mirror of the owner's,
under `lib/features/teacher/enquiries/`:

- `data/mock_teacher_enquiry_data.dart` — `TeacherEnquiry`
  (`id, studentName, initial, avatarColor, subject, timeAgo, status, phone,
  email, thread`) + `TeacherEnquiryMessage { text, fromTeacher, timeLabel }` +
  `TeacherEnquiryStatus` / `TeacherEnquiryFilter`. 5 seed enquiries (2 new / 2
  replied / 1 archived).
- `data/controllers/teacher_enquiry_provider.dart` — `teacherEnquiriesProvider`,
  a `Notifier<List<TeacherEnquiry>>` (`byId`, `addReply`, `archive`,
  `unarchive`) so the inbox and detail share one source of truth and update
  live across navigation.
- `presentation/screens/teacher_enquiries_screen.dart` — inbox: title + unread
  count, search, All/New/Replied/Archived filter pills, a `ListView.separated`
  of tiles, empty state. Flat `palette.surface`, teal accents, capped 720 px.
- `presentation/screens/teacher_enquiry_detail_screen.dart` — contact card
  (avatar, subject chip, status chip, phone/email, Call/Email stubs),
  conversation thread (student left on surface, teacher right on teal),
  app-bar Archive/Unarchive, pinned `TeacherReplyInputWidget`.
- `presentation/widgets/teacher_enquiry_tile_widget.dart` +
  `teacher_reply_input_widget.dart`.

Routing: new `AppRoutes.teacherEnquiryDetail` + a nested `:id` `GoRoute` under
`/teacher-enquiries` (so the URL is `/teacher-enquiries/<id>`, the back button
returns within the shell, and the existing teacher prefix guard already covers
it). Reused the existing generic `enquiries*` / `enquiry*` `AppStrings` — **no
new strings**.

**Single-source reconciliation:** the teacher home (ADR 0034) previously had
its *own* lightweight `TeacherEnquiry` model for its "Recent Enquiries"
preview. That duplicate was removed from `mock_teacher_home_data.dart`; the
home now imports `mockTeacherEnquiries` from this feature and shows the first
three (`.take(3)`), so the home preview and the inbox can't drift. (Home data
now holds only `TeacherSession`; its unused `material`/`app_colors` imports
were dropped.)

## Consequences

- The teacher shell now has a complete, working enquiry workflow matching the
  owner's, teal-branded and flat per the user's stated preference.
- One canonical teacher-enquiry model + fixture feeds both the home preview and
  the inbox/detail — no duplicated model, no risk of the two diverging.
- Replies / status changes are in-memory only (reset on restart); Call / Email
  are "Coming soon" stubs until a dialer/mailer integration exists.
- The home's enquiry preview rows are now driven by the richer model
  (`.timeAgo` instead of the old `.ago`); the home looks identical.
- Verified: `dart format` + `flutter analyze` (whole project) clean. Not yet
  walked on a device in light/dark.
