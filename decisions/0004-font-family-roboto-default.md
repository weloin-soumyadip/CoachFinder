# 0004 — Font family: Material 3 default (Roboto)

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** User (selected from options)

## Context

`core/theme/app_text_styles.dart` defines `TextStyle` constants that need a `fontFamily` value. Three reasonable defaults exist: Roboto (Material 3 default, ships with Flutter), a Google Font (Inter/Poppins, requires new dep), or `null` (decide later).

## Decision

Use Material 3 default. Leave `fontFamily: null` in `TextStyle` definitions — Flutter falls back to Roboto on Android and the platform default sans-serif on iOS.

## Alternatives considered

- **Inter via `google_fonts`** — popular Material 3 pairing. Rejected for Phase 1: `google_fonts` is not on the approved package list, and would require explicit permission before adding.
- **Skip — leave fontFamily null permanently** — kept as effectively the same outcome; we *are* leaving it null but with intent of "Roboto is fine".

## Consequences

- Zero new dependencies for typography.
- iOS will render with the system sans-serif (SF Pro), not Roboto. Cross-platform visual parity is intentionally sacrificed in favor of platform-native feel.
- If branding ever demands a specific custom font, swap to either a bundled `.ttf` under `assets/fonts/` + `pubspec.yaml` declaration, or add `google_fonts`. Either route requires a new decision record.
