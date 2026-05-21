# 0008 — iOS deployment target set via Xcode project (no Podfile on Linux)

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** Claude (environment-driven decision)

## Context

The plan called for setting `platform :ios, '12.0'` in `ios/Podfile`. CocoaPods generates the `Podfile` lazily on first `pod install`, which only runs on macOS. The development host is Linux — no `Podfile` exists yet in `ios/`.

The scaffold's `ios/Runner.xcodeproj/project.pbxproj` shipped with `IPHONEOS_DEPLOYMENT_TARGET = 13.0;` in three build configurations (Debug, Release, Profile).

## Decision

Set the iOS deployment target by editing the Xcode project file directly:

```
sed -i 's/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/g' \
  ios/Runner.xcodeproj/project.pbxproj
```

All three configs now read `IPHONEOS_DEPLOYMENT_TARGET = 12.0;`.

No `Podfile` is created in this phase — it will be auto-generated on first `pod install` on macOS.

## Alternatives considered

- Hand-write a `Podfile` with `platform :ios, '12.0'`. Rejected: a hand-written Podfile that doesn't match CocoaPods' expected scaffold can break `pod install` later. Better to let CocoaPods generate it on macOS.
- Skip the iOS target change entirely and rely on whatever the default is. Rejected: leaving the deployment target at 13.0 contradicts decision [0003](0003-min-sdk-android-21-ios-12.md).

## Consequences

- On macOS, when the project is first built / `pod install` runs, the generated `Podfile` will need its `platform :ios, '12.0'` line uncommented to match the Xcode target. If skipped, individual pods may default-upgrade to 13.0+ and bump the effective minimum back up.
- Anyone running on macOS after Phase 1 needs to verify the generated `Podfile` matches. Add this check to the "first macOS build" runbook (TBD).
- The Xcode project file is the source of truth for the deployment target; this edit will survive `Podfile` regeneration.
