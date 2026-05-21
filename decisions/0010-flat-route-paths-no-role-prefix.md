# 0010 — Flat route paths, no role prefix in URLs

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** Claude (derived from the user's route list in the original Phase 1 brief)

## Context

GoRouter route paths could be organised two ways:

- **Role-prefixed:** `/student/home`, `/student/search`, `/owner/dashboard` - role is visible in the URL.
- **Flat:** `/home`, `/search`, `/dashboard` - role is determined by app state (the `roleProvider`), not the path.

The user's Phase 1 brief listed routes as flat: `/home, /search, /center/:id, /student-profile, /saved, /dashboard, /manage-center, /create-center, /enquiries, /enquiry/:id`.

## Decision

Use **flat paths** as listed in the brief.

Role-shell classification (needed by the cross-shell redirect guard) is done via two `List<String>` of path prefixes inside `AppRouter`:

```dart
static const _studentPrefixes = ['/home', '/search', '/center', '/saved', '/student-profile'];
static const _ownerPrefixes = ['/dashboard', '/manage-center', '/enquiries', '/enquiry'];
```

A path matches a prefix iff `loc == prefix` or `loc.startsWith('$prefix/')`.

## Alternatives considered

- **Role-prefixed paths** (`/student/...`, `/owner/...`). Rejected because the user's brief explicitly listed flat paths, and they make the cross-shell guard purely role-state-driven (which matches the "role gates everything permanently" UX principle).
- **Hardcode the prefix list inline in the redirect callback.** Rejected: the list is referenced twice (student check + owner check); extracting it keeps the source of truth in one place.

## Consequences

- The URL never reveals the role - good for branding consistency, bad for ops/log analysis if shells need to be told apart at a glance.
- Any *new* route added in either shell must also be appended to the matching `_studentPrefixes` / `_ownerPrefixes` list, otherwise the cross-shell guard will incorrectly classify it. This is easy to forget. A future enhancement could replace the lists with a derive-from-routes computation.
- Path collisions between shells are guarded by author discipline only - the current routes are disjoint by name (`/home` vs `/dashboard`, `/center/:id` vs `/enquiry/:id`).
