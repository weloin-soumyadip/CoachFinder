/// Adaptive navigation shell - floating bottom bar on mobile, floating side
/// rail on wider screens.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/glass_panel.dart';

/// Width at/above which the side rail replaces the bottom bar.
const double kAdaptiveNavBreakpoint = 768;

/// Height of the floating bottom-bar card (excludes its margin + safe inset).
const double _kFloatingBarHeight = 64;

/// Bottom padding a scrollable screen inside [AdaptiveNavigation] should add so
/// its last content (or a pinned bottom element) clears the **floating bottom
/// bar**, which overlays the body (`extendBody`). On wide layouts the rail is
/// on the side, so only the system inset matters there.
double floatingNavClearance(BuildContext context) {
  final double systemInset = MediaQuery.viewPaddingOf(context).bottom;
  final bool wide = MediaQuery.sizeOf(context).width >= kAdaptiveNavBreakpoint;
  if (wide) return AppSpacing.sp24 + systemInset;
  return _kFloatingBarHeight + AppSpacing.sp12 + AppSpacing.sp24 + systemInset;
}

/// One navigation destination, expressed in a UI-agnostic shape so the same
/// list can power either the floating bottom bar or the side rail.
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Icon shown when the destination is not the current selection.
  final IconData icon;

  /// Icon shown when the destination IS the current selection.
  final IconData selectedIcon;

  /// User-facing label. Retained for semantics / future use; both layouts are
  /// currently icon-only.
  final String label;
}

/// Switches between a floating bottom bar (compact widths) and a floating side
/// rail (wider widths) using a single configurable [breakpoint].
///
/// The caller owns selection state and routing - this widget only renders the
/// chrome and forwards taps via [onDestinationSelected].
///
/// Both layouts are **floating, rounded `palette.surface` cards** (icon-only,
/// no labels or indicator pill) with a soft shadow: the active destination is
/// the full-strength `palette.textPrimary` filled icon, inactive ones the faint
/// `palette.iconFaint` outlined icon, cross-faded on change.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    super.key,
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.breakpoint = kAdaptiveNavBreakpoint,
  })  : assert(destinations.length >= 2,
            'AdaptiveNavigation requires at least 2 destinations.'),
        assert(selectedIndex >= 0, 'selectedIndex must be non-negative.');

  /// The current route's content, rendered in the body / right-hand pane.
  final Widget child;

  /// All destinations, in order. The widget at `destinations[selectedIndex]`
  /// is the currently active tab.
  final List<AdaptiveDestination> destinations;

  /// Index into [destinations] that is currently active.
  final int selectedIndex;

  /// Fired when the user taps a destination. The receiver decides whether to
  /// navigate, update local state, etc.
  final ValueChanged<int> onDestinationSelected;

  /// Width (in logical pixels) at which the layout switches from the floating
  /// bottom bar (below) to the floating side rail (at or above).
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= breakpoint;

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: <Widget>[
              _FloatingSideRail(
                destinations: destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    // extendBody lets the page extend *behind* the floating bar (so it overlays
    // content). The Scaffold reports the bar's height as the body's bottom
    // MediaQuery padding, which screens add to their scroll padding so the last
    // items still clear the bar.
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _FloatingBottomBar(
        destinations: destinations,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}

/// Floating, rounded frosted-glass card holding the icon-only bottom
/// destinations: a [GlassPanel] (translucent fill + backdrop blur) under a
/// subtle [_navShadow], with the icon row filling the fixed bar height.
class _FloatingBottomBar extends StatelessWidget {
  const _FloatingBottomBar({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp16,
          0,
          AppSpacing.sp16,
          AppSpacing.sp12,
        ),
        child: DecoratedBox(
          // Glass clips the fill/blur to the radius; the shadow must sit on an
          // unclipped ancestor so it casts *outside* the rounded glass edge.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp24),
            boxShadow: _navShadow,
          ),
          child: SizedBox(
            height: _kFloatingBarHeight,
            // Zero padding so the icon row fills the full fixed bar height.
            child: GlassPanel(
              padding: EdgeInsets.zero,
              radius: AppSpacing.sp24,
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: <Widget>[
                    for (int i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _NavIcon(
                          destination: destinations[i],
                          selected: i == selectedIndex,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating, rounded surface card holding the icon-only destinations as a
/// vertical pill on the left of wide layouts.
class _FloatingSideRail extends StatelessWidget {
  const _FloatingSideRail({
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp16,
        AppSpacing.sp16,
        AppSpacing.sp8,
        AppSpacing.sp16,
      ),
      child: Container(
        width: 68,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppSpacing.sp24),
          boxShadow: _navShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.sp24),
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (int i = 0; i < destinations.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: AppSpacing.sp8),
                    SizedBox(
                      height: 56,
                      child: _NavIcon(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft shadow shared by both floating nav cards.
final List<BoxShadow> _navShadow = <BoxShadow>[
  BoxShadow(
    color: AppColors.neutralBlack.withValues(alpha: 0.08),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

/// A single icon-only destination: full-strength filled icon when [selected],
/// faint outlined icon otherwise, cross-faded on change. No label or indicator.
/// Sizes to its parent (wrap in [Expanded] within a Row, or a sized box in a
/// Column).
class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AdaptiveDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Icon(
            selected ? destination.selectedIcon : destination.icon,
            key: ValueKey<bool>(selected),
            color: selected ? palette.textPrimary : palette.iconFaint,
            size: selected ? 26 : 24,
          ),
        ),
      ),
    );
  }
}
