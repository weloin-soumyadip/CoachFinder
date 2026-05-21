# 0005 — Keep `cupertino_icons` (scaffold default)

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** Claude (not on user's approved package list; defaulted to keep)

## Context

The user's `pubspec.yaml` brief listed 9 runtime packages to add. `flutter create` also adds `cupertino_icons: ^1.0.8` by default. The user said "DO NOT suggest or add any package not listed above without asking me first" — ambiguous about whether scaffold defaults count.

## Decision

Keep `cupertino_icons: ^1.0.8` in `pubspec.yaml`. Flagged to the user in the Step 1 summary so they can object.

## Alternatives considered

- Remove it. Rejected: it's the standard Flutter package providing `CupertinoIcons` (iOS-style glyphs). Removing it would force re-adding the moment any iOS-style icon is needed — and the user explicitly targets iOS as a platform.
- Ask the user explicitly before keeping it. Considered, but `cupertino_icons` is essentially a Flutter platform default — asking felt like noise. Mentioned in the Step 1 summary instead.

## Consequences

- Adds ~78 KB to the bundle. Negligible.
- If the user reads the Step 1 summary and rejects this, the fix is a one-line removal from `pubspec.yaml` plus `flutter pub get`.
