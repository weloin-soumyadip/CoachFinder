# 0020 — Owner Enquiries inbox + detail

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + scope/feature choices) + Claude (implementation)

## Context

The owner shell's Enquiries tab and the enquiry-detail route were both bare
placeholders (`Text('EnquiryInboxScreen')` / `EnquiryDetailScreen (id: …)`),
though the dashboard already linked taps into the detail route. The `data/` and
`presentation/widgets/` skeletons named the intended pieces (`enquiry_model`,
`enquiry_provider`, `enquiry_tile_widget`, `reply_input_widget`). The user asked
to build the screen and, via clarifying questions, chose **both** the inbox list
and the detail view, with **all** inbox features (status filter tabs, search,
new/unread badges, course tag) and **all** detail features (message thread,
reply box, contact + Call action, status actions).

## Decision

Built a fixture-backed inbox + conversation detail, owner-branded
(`AppColors.ownerAccent`) and palette-first per decision [0017].

### Shared mutable state (first Notifier in the codebase)

This is the first feature where state must survive navigation: a reply or
archive in the **detail** screen has to show up in the **inbox**. Prior screens
were read-only and used plain fixtures; here the two screens are separate
routes, so a shared store is required.

Implemented the `enquiry_provider.dart` stub as a Riverpod **`Notifier`**
(`NotifierProvider<EnquiryNotifier, List<Enquiry>>`) — supported by the pinned
`flutter_riverpod ^2.5.1`, and consistent with the "Riverpod only" rule. It
seeds from fixtures in `build()` and exposes `addReply` (appends an owner
message + flips status to replied), `archive`, `unarchive`, and `byId`. Both
screens `ref.watch` it, so updates propagate live. When the backend lands,
`build()` becomes a repository fetch and the mutators post to the API.

### Pieces

- `data/mock_enquiry_data.dart` — `Enquiry` (with `copyWith` + `preview`),
  `EnquiryMessage`, `EnquiryStatus { newEnquiry, replied, archived }`,
  `EnquiryFilter { all, … }`, and five seed enquiries (2 new / 2 replied /
  1 archived for filter variety). The model/remote/repository stubs in
  `data/models` + `data/repository` are left for the later backend swap,
  following the established `mock_*_data.dart` convention.
- `EnquiryTileWidget` (implemented stub) — avatar, name + time, course tag,
  2-line snippet; new enquiries get a bold name, accent-tinted border, and a
  "NEW" badge.
- `ReplyInputWidget` (implemented stub) — a `HookWidget` owning its own
  `TextEditingController` (`useListenable` to enable/disable send), growing
  1–4 lines, with an accent send button; forwards trimmed text via `onSend`.
- `EnquiryInboxScreen` — title + unread count, search box (filters by name /
  course / message), All·New·Replied·Archived filter pills, a tile list, and an
  empty state. Content capped at 720 px via `Align`+`ConstrainedBox`.
- `EnquiryDetailScreen` — contact card (avatar, course chip, status chip, phone
  + email, Call/Email buttons → "Coming soon"), a chat thread (student bubbles
  left/surface, owner bubbles right/accent with white text), and the pinned
  reply box. App-bar archive/unarchive action; not-found fallback.

### Fixture-id alignment (avoiding a dashboard refactor)

The detail reads by id from the provider. The first three seed ids
(`enq-101/102/103`) intentionally match the dashboard's recent-enquiries
preview, so the **existing** dashboard tap-through resolves to a real enquiry
without touching the dashboard's own (deliberately condensed) preview fixture.
Unifying the two fixtures into one source is a noted follow-up for the backend
phase.

### Navigation

Tile taps (and the dashboard preview taps) now use `context.pushNamed` for the
detail route — within the owner `ShellRoute` this pushes the conversation over
the current tab, so the detail's back button (`canPop ? pop : goNamed(inbox)`)
returns there with the bottom nav intact. The dashboard's `openEnquiry` was
switched from `goNamed` → `pushNamed` for the same reason.

## Consequences

- Replies and status changes are **in-memory only** (lost on app restart) until
  the backend lands; this is the intended Phase-1 behaviour.
- The detail renders inside the owner shell, so the bottom nav stays visible
  beneath the reply box — acceptable for now; making detail full-screen would
  need a root-navigator route (out of scope).
- Call / Email are "Coming soon" stubs (no `url_launcher` — the stack is fixed).
- The dashboard now shares enquiry ids with this feature; keep them in sync
  until both read one source.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
