# 0019 — Owner Dashboard screen

**Status:** Accepted
**Date:** 2026-05-27
**Phase:** Post-Phase-1 iteration
**Made by:** User (request + section/metric/action/visual choices) + Claude (implementation)

## Context

The owner shell's first tab (`/dashboard`) was a bare placeholder
(`Text('OwnerDashboardScreen')`), while the `data/` skeleton hinted at the
intended shape with empty `stat_card_widget.dart`, `quick_action_widget.dart`,
and `dashboard_stats_model.dart` stubs. The user asked to build the real
dashboard and, via clarifying questions, chose **all four** building blocks
(greeting header · stat cards · quick actions · recent-enquiries preview), the
**four metrics** (profile views · new enquiries · avg rating · active
students), the **four quick actions** (edit center · manage courses · view
enquiries · share link), and a **hand-drawn 7-day views mini-chart** as the
richer visual element.

## Decision

Built `OwnerDashboardScreen` as a fixture-backed feed, mirroring the student
home's structure (capped + centered scroll column, section headers, surface
cards) but owner-branded with `AppColors.ownerAccent`.

- **Fixtures/models:** `data/mock_dashboard_data.dart` — `DashboardStat`
  (+`StatTrend` enum), `DailyViews`, `EnquiryPreview`, and their fixtures.
  Follows the established `mock_*_data.dart` convention (home/search/saved):
  the controller/repository/model skeleton stubs are left untouched for the
  later backend swap to a controller-backed `AsyncValue<DashboardData>`.
- **Widgets:** implemented the two stubs — `StatCardWidget` (tinted accent
  icon, value, label, trend caption) and `QuickActionWidget` (tinted icon +
  label + chevron, default owner-accent) — and added `views_chart_widget.dart`.
- **Screen composition:** greeting header (owner first name + business name +
  notifications bell with unread dot), a 2×2 `IntrinsicHeight` stat grid, the
  views chart, a 2×2 quick-action grid, and a recent-enquiries preview list.
  Content capped at 720 px and centered (so the wide-screen rail layout reads
  well), mirroring the student-profile cap pattern.

### No-package mini chart

The "richer visual" was a 7-day bar chart. Rather than add a charting package
(the stack is fixed — see the project rules), `views_chart_widget.dart` draws
the bars with a `CustomPainter` (`_BarsPainter`): bars scaled to the max day,
the peak day highlighted in `ownerAccent` (others a 0.28-alpha fade) and
annotated with its value via a `TextPainter`. Day labels live in a matching
`Row` of `Expanded` slots beneath the `CustomPaint`, so labels align with bars
without the painter laying out text columns. The weekly total (1,248) is set to
equal the "Profile Views" stat for internal consistency.

### Theme-awareness / colour rules

Follows decision [0017]: neutrals/text route through `context.palette.*`; the
fixed `ownerAccent` brand token is used only as a *foreground* (icons, business
name, "View all", peak bar, NEW badge text) or behind *white* / over a
*low-alpha tint of itself* (stat/quick-action icon circles at 0.12 α, the NEW
pill at 0.14 α) — all legible in light and dark. Stat accents reuse fixed
semantic tokens (`ownerAccent`/`info`/`ratingStar`/`success`); enquiry avatar
colours are raw fixture content colours (as in `mock_home_data.dart`). The bell
dot is ringed with `palette.surface` so it reads as a cutout in both themes.

### Navigation

Edit Center → `ownerManageCenter`; View Enquiries / "View all" →
`ownerEnquiryInbox`; tapping a preview → `ownerEnquiryDetail` with the
fixture id. Manage Courses, Share Link, and the bell are "Coming soon"
snackbars (no destination screens yet).

## Consequences

- The owner now has a real first screen; Center and Enquiries tabs remain
  placeholders (separate later tasks).
- Tapping a recent enquiry lands on the placeholder `EnquiryDetailScreen`
  (id wired but the screen is bare) — acceptable until that screen is built.
- New dashboard widgets/screens must stay palette-first; the chart painter is
  passed colours from the call site rather than reading the theme itself.

## Verification

`dart format` clean · `flutter analyze` → *No issues found!* · `flutter build
apk --debug` → built.
