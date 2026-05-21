# 0003 — Min SDK Android 21 / iOS 12.0

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** User (selected from options)

## Context

Flutter's defaults vary by version and aren't pinned in the scaffold (Android uses `minSdk = flutter.minSdkVersion`, iOS defaults to 13.0 in this scaffold). For reproducible builds and clear device-support intent, we needed explicit minimums.

## Decision

- **Android `minSdk = 21`** (Android 5.0 Lollipop, 2014).
- **iOS deployment target `12.0`** (iOS 12, 2018).

## Alternatives considered

- Android 23 / iOS 13.0 — modern baseline covering ~99% of active devices. Rejected: dropping 21–22 sacrifices coverage without an actual capability gain in Phase 1.
- Android 24 / iOS 14.0 — stricter permissions model and modern WebView. Rejected: the app does not yet need features that require 24+.

## Consequences

- Plays nicely with all Phase 1 dependencies. None of `flutter_riverpod`, `dio`, `hive`, `go_router`, `path_provider` require above these targets.
- Some future packages (e.g., advanced biometric or background-execution libraries) may demand higher minimums. We'll raise the floor when (and if) a needed package forces it.
- Android 21 means runtime permissions are NOT auto-granted via the legacy model — `permission_handler` flows will be required for any sensitive permission (location, camera, etc.).
