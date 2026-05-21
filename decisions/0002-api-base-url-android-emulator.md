# 0002 — API base URL for Android emulator

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** User (selected from options)

## Context

`core/network/dio_client.dart` needs a `baseUrl` for Dio's `BaseOptions`. The backend (Node.js + Express + MongoDB) is being developed locally. Default dev environment is presumed to be Android emulator.

## Decision

`baseUrl = 'http://10.0.2.2:5000/api'`

Stored as a `static const String` in `core/constants/api_endpoints.dart`.

## Alternatives considered

- `http://localhost:5000/api` — works on iOS simulator, desktop, and `flutter run` on the host. Rejected as the default: it does NOT resolve to the host machine from inside an Android emulator (the loopback there is the emulator itself).
- Hosted dev/staging URL — would work everywhere. Rejected for Phase 1: no staging URL exists yet; we'll switch when one does.

## Consequences

- Android emulator: works out of the box.
- iOS simulator: `10.0.2.2` does not resolve. We'll need an env-based or platform-based switch later (likely `Platform.isAndroid ? '10.0.2.2' : 'localhost'`), but not in Phase 1.
- Physical devices on the same LAN: neither URL works; they'd need the host's LAN IP. Out of scope until first physical-device test.
- Network security config: Android 28+ blocks cleartext HTTP by default. We'll need to add a `network_security_config.xml` allowing `10.0.2.2` cleartext for debug builds. Flag for the first time `flutter run` fails on Android.
