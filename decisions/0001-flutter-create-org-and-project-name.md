# 0001 — Flutter create org and project name

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** User (selected from options)

## Context

The working directory `app/` was empty. To scaffold a Flutter project we needed:
- An `--org` (reverse-domain prefix), which combined with the project name becomes Android `applicationId` and iOS `CFBundleIdentifier`.
- A `--project-name`, which becomes the `name` in `pubspec.yaml` and the Dart package identifier.
- A `--platforms` list.

## Decision

- `--org com.weloin`
- `--project-name coachfinder`
- `--platforms android,ios`

Resulting bundle ID: `com.weloin.coachfinder`. Pubspec package name: `coachfinder`.

Command executed:
```
flutter create --org com.weloin --project-name coachfinder --platforms android,ios .
```

## Alternatives considered

- `com.weloin.coachfinder / app` — project name matches the folder. Rejected: pubspec name `app` is generic and conflicts with Dart conventions favoring product-specific names.
- All platforms (android + ios + web + desktop) — wider reach. Rejected for Phase 1: scope is mobile-only; web/desktop would add config surface area and untested code paths.

## Consequences

- Folder is named `app/` but the Dart package is `coachfinder`. Imports in Dart files use `package:coachfinder/...`.
- Renaming the project later requires `applicationId` + bundle ID changes in `android/app/build.gradle.kts` and `ios/Runner.xcodeproj/project.pbxproj`, plus `pubspec.yaml` name + all import strings. Treat as effectively permanent.
