# 0009 — No refresh-token flow in Phase 1

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** User (option (a) chosen from two)

## Context

The user's `core/network/auth_interceptor.dart` brief says: "handle 401, refresh". The backend's refresh-token contract (endpoint path, request body, response shape, rotation rules) has not yet been shared.

The interceptor needs *some* behaviour on 401 right now so the app can ship Phase 1.

## Decision

The Phase 1 `AuthInterceptor.onError` handles 401 responses by:

1. Deleting the cached JWT (`HiveKeys.keyJwtToken`) from the auth box.
2. Deleting the cached user (`HiveKeys.keyCurrentUser`) from the auth box.
3. Calling `handler.next(err)` so the error propagates to the calling repository.

A `TODO(refresh-token)` marker is left in `auth_interceptor.dart` pointing at where the refresh + replay logic will land.

## Alternatives considered

- **Block Phase 1 until backend contract is shared.** Rejected: the user explicitly chose to defer this and unblock setup.
- **Stub a fake refresh call that always fails.** Rejected: silently fails in ways that mask real auth issues during dev.

## Consequences

- The user is signed out (locally) the first time a 401 arrives. Subsequent navigation triggers the router's "no token" redirect to `/onboarding`.
- Token rotation, sliding sessions, and seamless retry-after-refresh are **not** implemented. Calls that race a token expiry will surface as errors to the user rather than transparently recover.
- When the backend's refresh contract lands, the work is: add a refresh endpoint constant, implement refresh + queued-request-replay in `AuthInterceptor`, remove the cached-data clear, write a new decision record superseding this one.
