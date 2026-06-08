# 0039 — Client-side access-token refresh + retry

**Status:** Accepted
**Date:** 2026-06-02
**Phase:** Backend wiring — closing the deferred refresh-token gap.
**Made by:** User (reported "after every 15 mins the token is getting expired but
not getting refreshed … check whether the refresh token feature is implemented"
→ "yes go ahead and implement the client refresh") + Claude.

## Context

The backend has full refresh-token support: `POST /api/auth/refresh` reads the
refresh token from an **HttpOnly cookie** (`config.cookie.refreshName` =
`refreshToken`), runs Redis-backed rotation with family revocation, and returns
`{ accessToken, refreshToken }`. Login/register also issue both tokens.

The **client never used it.** `TokenStorage` stored the refresh token,
`AuthResponse` parsed it, and `ApiConfig.authRefresh` existed — but nothing
called the endpoint. The `ApiClient` 401 interceptor simply *cleared* the tokens
(its own comment: "refresh-token rotation is a later round", ADR 0031/0032). So
the first request after the 15-minute access-token TTL got a 401 and silently
logged the user out.

**Contract mismatch:** the server reads the refresh token from a cookie, but the
Flutter app uses Dio with **no cookie jar** and holds the refresh token in secure
storage (from the login response body). Adding a cookie-manager package was
rejected — the stack is fixed.

## Decision

Implemented refresh + retry entirely in `ApiClient` (the transport layer that
already owned the 401 handler and touches `TokenStorage` + `LocalStorage`), with
no new packages:

1. **Manual cookie header.** The refresh call sends
   `Cookie: refreshToken=<token from secure storage>` itself, bridging the
   cookie contract without a cookie jar. New constant
   `ApiConfig.refreshCookieName`.
2. **Interceptor-free `_refreshDio`.** A second `Dio` (no interceptors) makes the
   `/auth/refresh` call, so a 401 there can't re-enter the refresh flow and loop.
3. **401 → refresh → retry.** On a 401 that is neither the refresh call itself
   nor an already-retried request, the interceptor refreshes, re-issues the
   original `RequestOptions` with the new bearer (guarded by an
   `extra['__retried_after_refresh']` flag), and `handler.resolve`s the retry —
   transparently to the caller. The rotated access + refresh tokens are
   persisted.
4. **Single-flight.** A shared `Future<String?>? _refreshFuture` means many
   requests 401-ing at once trigger exactly one rotation (avoids a refresh
   stampede + spurious family-revocation from concurrent reuse).
5. **Graceful give-up.** If there's no stored refresh token, or the backend
   rejects the refresh (refresh token also expired/revoked), or a retried
   request 401s again, the session is cleared (`clearTokens` +
   `currentUserId`) so the router bounces to login on the next tick — the old
   behaviour, now only as the last resort.
6. **Proactive refresh (added after first report).** The reactive 401 handler
   alone meant refresh only ever fired *after* a protected request bounced — and
   since most screens are mock-backed and the dashboard fetches once at startup,
   an idle session past the 15-min TTL issued no request, so `/auth/refresh` was
   never observed firing. The `onRequest` interceptor now decodes the stored
   access token's `exp` (base64url-decodes the JWT payload, no signature check,
   no new package) and, when it's within `_expirySkewSeconds` (15s) of expiry,
   refreshes *before* sending — so any activity after expiry uses a fresh token
   with no 401 round-trip. Shares the single-flight `_refreshAccessToken` with
   the reactive path. Verified end-to-end against the running backend: `POST
   /auth/refresh` with `Cookie: refreshToken=<jwt>` returns
   `{success, accessToken, refreshToken}`.

Covers every call (`get`/`post`/`rawGet`/`rawPost` all go through the main
`_dio`), so `/auth/me` rehydration at launch now also survives access-token
expiry.

### Web fix (added after a "Missing refresh token" report)

The manual `Cookie: refreshToken=…` header works on mobile but **browsers
silently drop it** — `Cookie` is a forbidden header JS may not set — so on web
the refresh request reached the server with no cookie and 401'd
("Missing refresh token"). Fix: on web (`kIsWeb`) the Dio instances set
`withCredentials: true` (via `BaseOptions.extra`) so the browser (a) stores the
HttpOnly refresh cookie the backend sets at login and (b) attaches it on
`/auth/refresh` itself; the manual `Cookie` header is sent only on
mobile/desktop. Relies on the ADR-0032 CORS fix (allow-credentials + echoed
origin). Verified with a cookie-jar curl: login sets
`refreshToken=…; Path=/api/auth; HttpOnly; SameSite=Strict`, and a
jar-only refresh (no manual header) returns `{success, accessToken}`.
**Existing web sessions must log in again** so the browser captures the cookie
(pre-fix logins didn't send `withCredentials`, so none was stored). Same-site in
dev (localhost↔localhost); a cross-domain prod deploy would need the cookie's
`SameSite=Strict` relaxed to `None; Secure`.

### Final transport: refresh token in the request body (supersedes the cookie)

The `withCredentials` web fix above still didn't get the cookie *stored* in
practice — a localhost SPA over plain http hits SameSite=Strict / `localhost`-vs-
`127.0.0.1` host-mismatch / no-`Secure` problems that make browser cookie
persistence unreliable. Rather than keep fighting browser cookies, the refresh
token is now sent in the **request body** on every platform: the backend
(`auth.controller.ts` `refresh` + `logout`) reads `req.body.refreshToken`
falling back to the cookie, and `ApiClient._performRefresh` POSTs
`{ refreshToken }` from secure storage. Removed the web `withCredentials`
`extra`, the manual `Cookie` header, the `kIsWeb` branch, and
`ApiConfig.refreshCookieName`. Security note: the client already persisted the
refresh token (login/refresh response body → secure storage / web localStorage),
so accepting it from the body adds **no** new exposure over the prior design —
the HttpOnly cookie was redundant defense for this client. The cookie path
still works server-side (mobile/web both send the body), so nothing regressed.
Verified end-to-end: login → `POST /auth/refresh` with `{refreshToken}` body and
**no cookie** → `{success, accessToken, refreshToken}`.

## Consequences

- Sessions now live as long as the **7-day refresh token** instead of dying
  every 15 minutes; refresh is invisible to feature code.
- `ApiClient` gained an optional `refreshDio` constructor param purely for test
  injection.
- New test `test/core/api/api_client_refresh_test.dart` proves refresh-then-retry
  and single-flight, using a hand-rolled fake `HttpClientAdapter` + in-memory
  `TokenStorage` (no mocking package). The failure/clear-session paths aren't
  unit-tested because they call `LocalStorage` (Hive), which needs init not
  available in a pure unit test — they're covered by reading + the existing
  manual-login flow.
- **Rotation chain integrity** depends on persisting the new refresh token after
  each call; `saveTokens` does this. If a write were lost, the next refresh would
  reuse the prior token and the backend would revoke the family (forcing a
  re-login) — acceptable fail-safe.
- Verified: `dart format` + `flutter analyze` clean, full suite **46 tests**
  green, `flutter build apk --debug` succeeds. Not yet walked end-to-end against
  a live backend across a real 15-minute expiry (recommended next check, e.g. by
  temporarily shortening the access-token TTL).
