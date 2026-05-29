import 'package:coachfinder/core/theme/app_theme.dart';
import 'package:coachfinder/shared/layouts/adaptive_navigation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const destinations = <AdaptiveDestination>[
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    AdaptiveDestination(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Search',
    ),
  ];

  // Compact width forces the floating bottom bar (the rail kicks in at 768).
  // The real theme is supplied so the bar's `context.palette` resolves.
  Widget harness() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: AdaptiveNavigation(
          destinations: destinations,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  testWidgets('floating bottom bar is icon-only with no labels or tooltips',
      (WidgetTester tester) async {
    await tester.pumpWidget(harness());

    // Sanity check: compact layout renders the icon-only bar (selected Home
    // shows its filled icon), not the rail.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.search_outlined), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byIcon(Icons.home)));
    await tester.pump();
    // Wait well past any tooltip wait duration so a stray tooltip would appear.
    await tester.pump(const Duration(seconds: 2));

    // The bar is icon-only - no labels and no Tooltips - so no empty-string
    // Text (the symptom of an empty tooltip) should ever reach the tree.
    expect(
      find.text(''),
      findsNothing,
      reason: 'the icon-only bar should render no label/tooltip text',
    );
  });
}
