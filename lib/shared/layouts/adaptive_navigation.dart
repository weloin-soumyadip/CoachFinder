/// Adaptive navigation shell - NavigationBar on mobile, NavigationRail on wider screens.
library;

import 'package:flutter/material.dart';

/// One navigation destination, expressed in a UI-agnostic shape so the same
/// list can power either a [NavigationBar] or a [NavigationRail].
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

  /// User-facing label.
  final String label;
}

/// Switches between bottom [NavigationBar] (compact widths) and side
/// [NavigationRail] (wider widths) using a single configurable [breakpoint].
///
/// The caller owns selection state and routing - this widget only renders the
/// chrome and forwards taps via [onDestinationSelected].
///
/// The bar/rail background is transparent (it blends with the surface behind
/// it). Colours are derived from the active [ColorScheme] so icons and labels
/// stay visible in both themes - dark in light mode, light in dark mode. The
/// selected destination reads via its filled icon and a bolder, full-strength
/// `onSurface` tone; unselected ones use the muted `onSurfaceVariant` tone.
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    super.key,
    required this.child,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.breakpoint = 768,
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

  /// Width (in logical pixels) at which the layout switches from
  /// [NavigationBar] (below) to [NavigationRail] (at or above).
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= breakpoint;
    final colorScheme = Theme.of(context).colorScheme;

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.transparent,
                useIndicator: false,
                selectedIconTheme: IconThemeData(color: colorScheme.onSurface),
                unselectedIconTheme:
                    IconThemeData(color: colorScheme.onSurfaceVariant),
                selectedLabelTextStyle: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                destinations: <NavigationRailDestination>[
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: colorScheme.outlineVariant,
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (Set<WidgetState> states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (Set<WidgetState> states) {
              final bool selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 12,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            },
          ),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          elevation: 0,
          destinations: <NavigationDestination>[
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
                // Empty string suppresses the hover/long-press tooltip (a null
                // tooltip would fall back to showing the label).
                tooltip: '',
              ),
          ],
        ),
      ),
    );
  }
}
