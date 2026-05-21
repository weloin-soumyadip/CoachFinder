# 0006 — Keep `flutter_lints` (scaffold default)

**Status:** Accepted
**Date:** 2026-05-21
**Phase:** 1
**Made by:** Claude (asked user, user did not answer; defaulted to keep)

## Context

Step 1 brief mentioned only `hive_generator`, `json_serializable`, `build_runner` as dev dependencies. The scaffold also includes `flutter_lints: ^6.0.0`. Claude asked the user explicitly whether to keep it; the user said "yes, proceed with Step 1" without answering the lints sub-question.

## Decision

Keep `flutter_lints: ^6.0.0` in `dev_dependencies`. Activated by the default `analysis_options.yaml` Flutter generated.

## Alternatives considered

- Remove it. Rejected: removing lints means silently accepting style and correctness issues that a senior reviewer would catch. The cost of keeping is essentially zero (dev-only, no bundle impact).
- Replace with a stricter ruleset (e.g., `very_good_analysis`). Rejected for Phase 1: not on the approved package list and would require a new decision.

## Consequences

- Standard Flutter lint warnings will surface in the IDE and CI.
- If the user objects, removing it is a one-line change in `pubspec.yaml` plus updating `analysis_options.yaml` to drop the `include:` line.
