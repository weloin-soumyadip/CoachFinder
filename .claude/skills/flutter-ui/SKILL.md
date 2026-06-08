---
name: flutter-ui
description: >-
  Use when building, restyling, or reviewing ANY Flutter UI in this CoachFinder
  app — screens, widgets, cards, forms, lists. Generates modern, theme-aware UI
  that follows the project's neoglass design system (BrandBackdrop, GlassPanel,
  NeoSurface, NeoButton over context.palette / AppColors / AppSpacing /
  AppEffects), folder structure, Riverpod + hooks conventions, and the
  established card / chip / section / stats-strip / read-view+edit-form patterns.
---

# CoachFinder Flutter UI — Neoglass

How to build UI in this repo so it looks modern AND matches existing screens.
The reference implementations are the **onboarding** and **auth** features —
mirror them for hero / atmospheric surfaces. The student/owner/teacher shell
screens are mid-migration; do not regress those that have already moved to
neoglass.

## The aesthetic (what "modern" means here)

**Mantra:** **Glass surrounds. Neo presses.**

| Surface | Style | Why |
|---|---|---|
| Page background on hero / auth / onboarding / future empty-state screens | `BrandBackdrop` | Sets atmosphere; gives glass something to blur. |
| Form shelves, OAuth row, sticky AppBars, sheets, snackbars (future) | `GlassPanel` | Containers that frame other content. |
| Feed cards, stat strips, recent-enquiries previews (future migration) | `NeoSurface` (outset) | Independent content cards, need weight. |
| Primary CTA / Continue button | `NeoButton(filled: true, accent: …)` | Tactile, pressable. |
| Role tiles, selectable chips | `NeoButton(selected: …)` | The settled (selected) state IS the selection signal. |
| Text fields | `AuthFieldWidget` (already wraps `NeoSurface(inset: true)`) | Recessed "well" — affordance for typing. |
| Avatars / brand badges | `NeoSurface` (accent fill) | Embossed brand. |
| Dialogs, modal sheets (future) | `GlassPanel` | Overlays. |
| Debug-only chrome | Stays flat | Not a production surface. |

**Intensity: soft & premium.** Subtle shadows, gentle blur. Calibration baked
into `AppEffects`: outset blur 18, dark-shadow alpha 8 % (light) / 50 % (dark);
glass blur 24, fill alpha 60 % (light) / 24 % (dark). Heavier reads as 2020
skeumorphism.

**The rhythm:** bold section title → glass shelf or neo card → next title.
Keep generous whitespace; use `AppSpacing.sp24` between sections.

**Capped & centered on wide screens** (the app has a NavigationRail ≥ 768 px):
wrap scroll content in `Align(alignment: Alignment.topCenter)` +
`ConstrainedBox(maxWidth: …)`. Use **480** for auth / onboarding, **600** for
account / profile, **720** for feeds / lists / forms.

## Non-negotiable conventions

- **Responsive by default — never overflow.** Every layout must adapt to its
  width and never throw a RenderFlex overflow on any screen (phone → wide web).
  - Text in any bounded box (cards, chips, list rows, app bars) gets
    `maxLines` + `overflow: TextOverflow.ellipsis`. Never let a label decide a
    box's size unbounded.
  - A child that must share a row's width goes in `Expanded` / `Flexible`, not
    a fixed `width:`. Reserve fixed `width:` for items inside a horizontal
    scroller.
  - Fixed `height:` on a card/chip must fit its *worst-case* content (e.g. a
    two-line label), or the text must be capped so it can't exceed it.
  - Rows / rails of cards adapt: use `LayoutBuilder` to **fill the row when the
    items fit, fall back to a horizontal scroller when they don't** (see the
    responsive rail pattern below), or use `Wrap` when multi-row is acceptable.
  - Always cap + center wide content (see "Capped & centered" above). Verify
    the screen at a narrow phone width AND a wide (≥ 1000 px) web window before
    claiming done.
- **No hardcoded values.** Strings → `AppStrings`. Colours → `context.palette.*`
  or `AppColors.*`. Sizes / spacing → `AppSpacing.*`. Motion / blur / shadow
  numerics → `AppEffects.*`. Never inline a hex literal, a `Duration` for an
  animation, or a `Color.withValues(alpha: 0.something)` shadow.
- **Theme-aware by default.** Read neutrals / text via `context.palette` (import
  `core/theme/app_palette.dart`). A widget that reads `context.palette` can't be
  `const` — that's expected; keep `const` only on fixed-`AppColors` literals.
- **Screens** extend `HookConsumerWidget`. **Widgets** are `HookWidget` (need
  hooks) or `StatelessWidget`. Private sub-widgets (`_Foo`) inlined in the
  screen file are fine for single-use pieces.
- **Riverpod only** (no get_it). Read-only screens use fixtures directly; UI
  that mutates shared state across navigation uses a **`NotifierProvider`** in
  `data/controllers/` (see enquiries / manage-center / teacher-profile).
- **`///` doc comment** on every class and public method. `const` constructors
  where possible.
- Only `data/repository/` may touch Dio / Hive. Fixtures live in
  `data/mock_<feature>_data.dart` (models + fixtures together).

## Design tokens

`context.palette` (brightness-aware — `lib/core/theme/app_palette.dart`):
`background`, `surface`, `border`, `borderSubtle`, `textPrimary`,
`textSecondary`, `textMuted`, `iconFaint`, `inputFill`, `primary`,
`primaryTint`, **`neoShadowDark`**, **`neoShadowLight`**, **`glassFill`**,
**`glassBorder`**.

`AppColors` (fixed — `lib/core/theme/app_colors.dart`): role accents
`studentPrimary` (#1A56DB), `ownerAccent` (#E05A2B), `teacherAccent` (#0D9488);
`studentPrimaryDark` (gradient stop); `ratingStar`, `priceGreen`, `ctaAmber`;
semantic `success` / `warning` / `error` / `info`; `neutralWhite`, `neutralBlack`.

`AppSpacing`: `sp4 sp8 sp12 sp16 sp24 sp32 sp48`.

`AppEffects` (`lib/core/theme/app_effects.dart`): `glassBlur` (24),
`glassBlurStrong` (36), `neoOutsetOffsetDark/Light`, `neoOutsetBlur` (18),
`neoInsetOffsetDark/Light`, `neoInsetBlur` (12), `neoPressDuration` (220 ms),
`orbDiameter` (320).

### Picking the accent

- **Student** screens → `palette.primary` (foreground) / `AppColors.studentPrimary` (fill).
- **Owner** screens → `AppColors.ownerAccent`.
- **Teacher** screens → `AppColors.teacherAccent`.
- **Auth + global brand surfaces** → `AppColors.studentPrimary` (the brand blue).
- **Onboarding** → all three role accents on the backdrop (one each).

### Dark mode neo calibration

- In dark mode the "light" outset shadow is intentionally near-invisible —
  there is no real light source to fake. `NeoSurface` / `NeoButton` add a 1 px
  `palette.borderSubtle` automatically for edge definition. Don't bypass this.
- Glass fill alpha is *lower* in dark (24 %, not 60 %) — translucent over a
  dark backdrop reads as smoke, not milk. The token handles it.
- Brand foregrounds on dark surfaces use `palette.primary` (the lightened blue
  `AppColors.darkPrimary`), not `AppColors.studentPrimary`.

### Fill-vs-foreground rule (still critical)

- A brand accent (`studentPrimary` / `ownerAccent` / `teacherAccent`) is **fixed**
  — use it as a *foreground* (text / icon / border), as a *fill behind white text*
  (filled NeoButton, selected pills, avatars), or as a `withValues(alpha: 0.08–0.14)`
  tint.
- `palette.surface` is a *fill*; `AppColors.neutralWhite` is only for
  *foreground on a coloured fill* (e.g. a white initial on an accent avatar).
- For student screens specifically, brand *foregrounds* use `palette.primary`
  (lightens in dark); brand *fills* keep `AppColors.studentPrimary`.
- Decorative "content" colours (fixture pastels for topic chips / tag pills)
  must still adapt: tint via `seed.withValues(alpha: ~0.2)` in dark mode and
  lighten any coloured icon via
  `HSLColor.fromColor(seed).withLightness(0.72).toColor()`.

## Performance notes

- `BackdropFilter` (inside `GlassPanel`) is GPU-heavy. **Prefer one large
  `GlassPanel` over many small ones.**
- **Never** put a `GlassPanel` inside a `ListView.builder` item — every scroll
  frame triggers a fresh blur and the app stutters. Glass is for outer chrome,
  not list rows.
- `BrandBackdrop` orbs are cheap (one `RadialGradient` paint each), but stack
  cost grows; **only use `BrandBackdrop` on hero / atmospheric screens** (auth,
  onboarding, future landing / empty states). Shell pages keep plain
  `palette.background`.

## Copy-paste component patterns

**Responsive card rail** (fill the row when items fit, scroll when they don't)
```dart
LayoutBuilder(
  builder: (context, constraints) {
    const double minItem = 120, gap = AppSpacing.sp12, h = 108;
    final int n = items.length;
    final double available = constraints.maxWidth - AppSpacing.sp16 * 2;
    final bool fits = n > 0 && n * minItem + (n - 1) * gap <= available;
    if (fits) {
      return SizedBox(height: h, child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
          for (int i = 0; i < n; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: gap),
            Expanded(child: ItemCard(item: items[i])),   // null width → fills
          ],
        ]),
      ));
    }
    return SizedBox(height: h, child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      itemCount: n,
      separatorBuilder: (_, __) => const SizedBox(width: gap),
      itemBuilder: (context, i) => ItemCard(item: items[i], width: minItem),
    ));
  },
)
// ItemCard: `final double? width;` → `Container(width: width, …)`; cap its label
// with maxLines + ellipsis so a fixed-height card can never overflow.
```

**Brand backdrop** (auth, onboarding, hero screens)
```dart
Scaffold(
  backgroundColor: palette.background,
  body: BrandBackdrop(
    orbColors: const <Color>[AppColors.studentPrimary, AppColors.studentPrimaryDark],
    child: SafeArea(child: …),
  ),
)
```

**Glass shelf** (form panel, OAuth row, sheet)
```dart
GlassPanel(
  padding: const EdgeInsets.all(AppSpacing.sp24),
  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[ … ]),
)
```

**Neo surface card** (independent content card; future shell migration)
```dart
NeoSurface(
  padding: const EdgeInsets.all(AppSpacing.sp16),
  child: …,
)
```

**Neo recessed well** (used internally by AuthFieldWidget; lift up for custom forms)
```dart
NeoSurface(
  inset: true,
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp12),
  child: TextFormField(
    decoration: neoInputDecoration(context: context, label: 'Email', icon: Icons.mail_outline),
  ),
)
```

**Primary CTA** (filled accent)
```dart
NeoButton(
  onPressed: onPressed,
  filled: true,
  accent: AppColors.studentPrimary,
  child: const Text('Continue'),
)
```

**Secondary / OAuth-style button** (surface fill, accent foreground)
```dart
NeoButton(
  onPressed: onPressed,
  filled: false,
  accent: palette.textPrimary,
  child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
    Icon(Icons.g_mobiledata, size: 20),
    SizedBox(width: AppSpacing.sp8),
    Text('Continue with Google'),
  ]),
)
```

**Selectable role tile / chip** (settles on select)
```dart
NeoButton(
  onPressed: onTap,
  selected: isSelected,
  accent: roleAccent,
  filled: false,
  height: 88,
  radius: AppSpacing.sp16,
  child: …,  // row of icon + title + blurb + indicator
)
```

**Accent-tinted icon tile** (unchanged from the previous system; still useful)
```dart
Container(
  width: 40, height: 40, alignment: Alignment.center,
  decoration: BoxDecoration(
    color: accent.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppSpacing.sp12),
  ),
  child: Icon(icon, size: 22, color: accent),
)
```

**Section title** (unchanged)
```dart
Text(title, style: textTheme.titleMedium?.copyWith(
  fontWeight: FontWeight.w700, color: palette.textPrimary));
```

**Stats strip** (unchanged for now; will move to `NeoSurface` outer + inner divisions during the next migration phase)
```dart
Container(
  decoration: BoxDecoration(
    color: palette.surface,
    borderRadius: BorderRadius.circular(AppSpacing.sp16),
    border: Border.all(color: palette.borderSubtle),
  ),
  child: IntrinsicHeight(child: Row(children: [Expanded(_Stat), VerticalDivider(color: palette.borderSubtle), …])),
)
```

**Screen scaffold shell** (hero variant — backdrop + glass shelves)
```dart
Scaffold(
  backgroundColor: palette.background,
  body: BrandBackdrop(
    orbColors: const <Color>[AppColors.studentPrimary, AppColors.studentPrimaryDark],
    child: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sp24, AppSpacing.sp32, AppSpacing.sp24, AppSpacing.sp32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
              Text('Title', …),
              SizedBox(height: AppSpacing.sp24),
              GlassPanel(child: …),  // form / shelf
              SizedBox(height: AppSpacing.sp24),
              NeoButton(filled: true, accent: AppColors.studentPrimary, onPressed: …, child: …),
            ]),
          ),
        ),
      ),
    ),
  ),
)
```

**Screen scaffold shell** (shell variant — plain background, no backdrop) — keep using `palette.background` for the student / owner / teacher tabbed shells until they migrate in a later round.

## Read-view + edit-form pattern (for editable features)

1. `data/mock_<feature>_data.dart`: the model (with `copyWith`) + a fixture.
2. `data/controllers/<feature>_provider.dart`: a `Notifier<Model>` seeded from
   the fixture, exposing mutators; `final fooProvider = NotifierProvider<…>(FooNotifier.new);`.
3. Read screen `ref.watch`es the provider; an Edit button `context.pushNamed`es
   the edit route (so back returns within the shell).
4. Edit screen `ref.read`s the provider **once** into local hook draft state
   (`useTextEditingController(text: …)`, `useState`), then on Save calls
   `notifier.save(current.copyWith(...))`, shows a snackbar, and `context.pop()`.
5. Add the route name to `AppRoutes` and a nested `GoRoute` in `app_router.dart`.
6. Detail / edit screens pushed inside a shell use `AppBar` with
   `leading: BackButton(onPressed: () => context.pop())`.

## Workflow when generating UI

1. Add any new strings to `app_strings.dart`, routes to `app_routes.dart` +
   `app_router.dart`.
2. Build the screen / widgets following the neoglass patterns above; brand by
   role. Default to `palette.background` + flat surfaces for non-hero screens
   until the shell migration phase lands.
3. Verify: `dart format lib` → `flutter analyze` (must be *No issues found!*) →
   `flutter build apk --debug`. For new hero screens, also walk the screen on a
   device or simulator in **both light and dark** modes — neoglass is most
   fragile when the calibration is off.
4. Record the decision: add `decisions/00NN-<slug>.md` and update the relevant section of `CLAUDE.md`.

## Constraints

- **Tech stack is FIXED** — do NOT add a package not already in `pubspec.yaml`
  (no charts, image pickers, url_launcher, no neumorphism / glass packages —
  we hand-built four small widgets specifically to avoid that). Hand-draw with
  `CustomPainter` for unusual visuals and stub unavailable actions with a
  "Coming soon" snackbar (`AppStrings.stubComingSoon`).
- Photos / uploads are coloured placeholder tiles until a picker exists.
- Mock / in-memory state is the Phase-1 norm; note it resets on restart.
- **Migration boundary:** Until further notice, only auth + onboarding screens
  use `BrandBackdrop` + `GlassPanel`. Other screens stay flat (still use
  `palette.surface` cards with `palette.borderSubtle` hairlines from the prior
  system). When asked to restyle one, confirm scope with the user before
  rolling the new system to it.
