# 0048 — Owner Enquiries (inbox + detail) backend wiring

**Status:** Accepted
**Date:** 2026-06-06

## Context

The owner Enquiries tab was fully mock-backed (`mock_enquiry_data.dart` + an in-memory
`Notifier`) with a chat-thread + reply UI. The backend (read from `owners.routes.ts` /
`enquiries.controller.ts` / `enquiries.schemas.ts` / `models/Enquiry.ts`) tells a different
story:

- An enquiry is **a single student message + a status + private owner notes** — there is
  **no reply/conversation thread, no archive, no delete, and no unread flag** (a `new` status
  *is* "unread").
- **Statuses:** `new → contacted → closed` (not the mock's new/replied/archived).
- **Endpoints (owner):** `GET /api/owners/enquiries` (paginated, `status` filter),
  `GET /api/owners/enquiries/search` (`q` + status/subject/student/date),
  `GET /api/owners/enquiries/:id`, `PATCH /api/owners/enquiries/:id` (`{status?, ownerNotes?}`,
  ≥1 field). All scoped to the owner's single centre; `403` on a foreign enquiry.

## Decision

Replaced the mock with a real data layer + rebuilt both screens around what the API supports.
**The "reply/conversation" becomes "set status + private notes"** (confirmed with the user).

**Data layer** (`enquiry_inbox/data/`, the former stubs): `Enquiry` model (+ `EnquiryStatus`
wire enum `new/contacted/closed`, `EnquiryFilter`), datasource (list / search / getById /
update, with string-tolerant pagination coercion), repository (`EnquiryException`,
`EnquiryPage`), and two controllers:
- `enquiryListControllerProvider` — paginated inbox: status filter, debounced search
  (uses the `/search` endpoint when there's a query), infinite scroll, and a true `new`
  count via a tiny status-scoped query.
- `enquiryDetailControllerProvider.family(id)` — loads one enquiry and exposes `setStatus`
  / `saveNotes`; on success it **folds the updated enquiry back into the list controller**
  (`applyUpdate`) so the inbox stays in sync (and drops items that no longer match the
  active filter).

**Inbox** (`enquiry_inbox_screen.dart`): title + unread badge, search box, filter chips
**All / New / Contacted / Closed**, infinite-scroll list of tiles, loading / error / empty
states.

**Detail** (`enquiry_detail_screen.dart`): student contact card (avatar, subject chip,
status chip, phone/email with stubbed Call/Email — no `url_launcher`), the **message**, a
**status segmented control** (New/Contacted/Closed → `PATCH status`), and a **private owner
notes** editor (`PATCH ownerNotes`). The chat thread + reply box are gone.

## Removed / changed

- Deleted `mock_enquiry_data.dart` and `reply_input_widget.dart`; the tile widget +
  both screens were rebuilt on the real model. The dashboard recent-enquiries preview and the
  **teacher** enquiries feature are untouched (the latter is still mock-backed; it kept the
  `enquiryReply*` / `enquiryConversationLabel` / `enquiryActionArchive` strings).
- Status remap: replied→contacted, archived→closed; archive/unarchive dropped (use Closed).

## Consequences / notes

- No delete (backend has none). Reviews/threads don't exist for enquiries. Call/Email are
  "Coming soon" stubs.
- Verified: `dart format` → `flutter analyze` clean → `flutter test` (126) →
  `flutter build apk --debug`. Live round-trip (list → detail → change status / save notes)
  not yet walked on device.
