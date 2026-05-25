# 0017 — Theme-aware colour migration (dark mode)

**Status:** Accepted
**Date:** 2026-05-25
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + dark-palette style choice) + Claude (architecture, mapping, execution)

## Context

The app shipped a working theme toggle (decision [0016]) and a dark `ThemeData`,
but every bespoke screen painted with fixed `AppColors` (white cards, grey-50
scaffolds, near-black text). So toggling to Dark only affected Material-driven
chrome; the screens stayed light. The user asked to make **all screens
theme-aware** for dark mode, and chose the **"Dim charcoal"** dark palette
(soft neutral-grey surfaces above a near-black background; brand blue lightened
to `#7AA2F7` as a foreground for contrast).

## Decision

Introduced a `ThemeExtension<AppPalette>` of semantic, brightness-aware tokens
and routed all screen colours through it. **Light values equal the original
fixed colours exactly**, so light mode is unchanged; only the dark variants are
new.

- `lib/core/theme/app_palette.dart` — `AppPalette` (11 tokens: `background`,
  `surface`, `border`, `borderSubtle`, `textPrimary`, `textSecondary`,
  `textMuted`, `iconFaint`, `inputFill`, `primary`, `primaryTint`) with
  `light`/`dark` instances, `copyWith`, and `lerp`. Plus a
  `context.palette` `BuildContext` extension for access.
- `app_colors.dart` — added a "Dark-theme neutrals" block (the Dim-charcoal
  hexes). All hex literals still live here; `AppPalette` references them.
- `app_theme.dart` — registers the per-brightness palette via `extensions:` and
  sets `scaffoldBackgroundColor` from it.
- Migrated 22 UI files to read `context.palette.*`.

### Token mapping (light → dark)

| Token | Light | Dark | Was |
|---|---|---|---|
| background | `#F9FAFB` | `#0F1115` | neutralGrey50 |
| surface | `#FFFFFF` | `#1A1D23` | neutralWhite (fills) |
| border | `#E5E7EB` | `#2A2F38` | neutralGrey200 |
| borderSubtle | `#F3F4F6` | `#21252C` | neutralGrey100 |
| textPrimary | `#111827` | `#F3F4F6` | neutralBlack / neutralGrey900 |
| textSecondary | `#374151` | `#C7CDD6` | neutralGrey700 |
| textMuted | `#6B7280` | `#9CA3AF` | neutralGrey500 |
| iconFaint | `#D1D5DB` | `#4B5563` | neutralGrey300 |
| inputFill | `#EEF1F6` | `#21252C` | inputFill |
| primary | `#1A56DB` | `#7AA2F7` | studentPrimary (foreground) |
| primaryTint | `#E3EBFC` | `#25304A` | studentPrimaryTint |

### Fill-vs-foreground rule (the crux)

Two tokens are context-dependent and were **kept fixed** in their fill role:

- **`studentPrimary`** → `palette.primary` only when used as a *foreground*
  (text/icon/border). As a *fill* behind white content (selected segment pills,
  filled buttons, the NextSession card, the FAB) it stays `AppColors.studentPrimary` —
  white-on-blue reads fine in dark.
- **`neutralWhite`** → `palette.surface` only when used as a *fill*. As a
  *foreground* on a coloured/brand fill (avatar/logo initials, selected-pill
  labels, text/icons on the blue card) it stays `AppColors.neutralWhite`.

Fixed brand/semantic tokens (`ratingStar`, `priceGreen`, `success`, `error`,
`navIndicator`, `teacherAccent`/tint, `ownerAccent`) were left unchanged — they
read acceptably in both themes. A "cutout" ring border (the online dot) now
tracks `palette.surface` so it reads as a cutout in both themes.

### Execution

Foundation + two exemplars (`saved_bookmark_button`, `teacher_result_card`)
were migrated by hand to lock the pattern, then the remaining ~18 files were
migrated by four parallel subagents grouped by feature (auth; onboarding+home;
search+saved+profile; teacher placeholders), each given the mapping, the
fill-vs-foreground rules, and the exemplars. Because `AppColors` was kept intact,
partial migration always compiled, so a single final `flutter analyze` caught
any `const`/missed stragglers. The nav bar (decision-era) already used the
`ColorScheme` directly and was untouched here.

## Consequences

- `const` was removed from widget literals whose colour now resolves at runtime
  via `context.palette` — an inherent cost of theme-awareness. Literals with
  fixed `AppColors` kept `const`.
- New screens MUST use `context.palette.*` for neutrals/brand-foregrounds (not
  raw `AppColors` neutrals) to stay theme-correct.
- Material chrome (dialogs, snackbars, nav) was already adapting via the M3
  `ColorScheme`; the bespoke screens now match.
- The owner shell screens are bare placeholders with no explicit colours, so
  they already adapt — nothing to migrate there.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build apk
--debug` → built. Audit confirmed zero `neutralGrey*`/`neutralBlack` remain in
UI files; all remaining `neutralWhite`/`studentPrimary` refs are intentional
fills / white-on-colour foregrounds.

## Follow-ups

- A visual pass on-device in dark mode to fine-tune any token (e.g. `primaryTint`
  contrast, the teal `teacherAccentTint` chip) once screens are exercised.
- When owner/teacher screens get real UIs, build them palette-first.
