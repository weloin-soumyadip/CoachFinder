/// Adaptive navigation shell - NavigationBar on mobile, NavigationRail on wider screens.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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

    if (useRail) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                destinations: <NavigationRailDestination>[
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
              Expanded(child: child),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: AppColors.neutralWhite,
        indicatorColor: AppColors.navIndicator,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        destinations: <NavigationDestination>[
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
