# 0007 — SDK constraint allows pre-release

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** Claude (environment-driven decision)

## Context

The plan called for `environment.sdk: '>=3.3.0 <4.0.0'` to keep the project portable to any Dart 3.x. The local development machine runs Dart `3.12.0-39.0.dev` from the Flutter `master` channel.

Pub's semver rules exclude pre-release versions from a plain `>=X.Y.Z` range unless explicitly opted in. So `'>=3.3.0 <4.0.0'` would *not* accept `3.12.0-39.0.dev` and `flutter pub get` would fail locally.

## Decision

Use `sdk: '>=3.3.0-0 <4.0.0'` instead of `'>=3.3.0 <4.0.0'`.

The `-0` suffix is the pub semver convention meaning "any pre-release of 3.3.0 or above is acceptable" — letting the local dev SDK satisfy the constraint without sacrificing portability.

## Alternatives considered

- Pin to `^3.12.0-39.0.dev` (what `flutter create` generated). Rejected: locks teammates running stable Dart 3.x out of building the project.
- Tell the user to switch their Flutter channel from `master` to `stable`. Rejected: out of scope for setup; the user picked their channel deliberately or by default.
- Pin to a wider open range like `'>=2.17.0 <4.0.0'`. Rejected: too lax, masks compatibility issues if anyone runs an ancient SDK.

## Consequences

- Project builds on both the local `master`-channel dev SDK and on any stable Dart 3.3+ a teammate may run.
- Stable channel users will not accidentally pick up pre-release SDKs from this constraint (their tooling won't fetch dev versions unless they switch channel manually).
- If a future Phase 2+ dependency requires Dart >=3.4, raise the lower bound.
