/// Application entry point.
///
/// Initialises Hive, hydrates the role state from local storage, then mounts
/// the [CoachFinderApp] inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/constants/hive_keys.dart';
import 'core/providers/role_provider.dart';
import 'core/router/router_provider.dart';
import 'core/storage/hive_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise local storage before the first widget builds so the router can
  // read the cached role and JWT synchronously.
  await HiveService.instance.init();
  final initialRole =
      HiveService.instance.settingsBox.get(HiveKeys.keyUserRole) as String?;

  runApp(
    ProviderScope(
      overrides: <Override>[
        roleProvider.overrideWith((ref) => initialRole),
      ],
      child: const CoachFinderApp(),
    ),
  );
}

/// Root [MaterialApp] for CoachFinder. Reads the [GoRouter] from
/// [routerProvider] so any rebuild driven by upstream providers triggers a
/// router refresh.
class CoachFinderApp extends ConsumerWidget {
  const CoachFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
