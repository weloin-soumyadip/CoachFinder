/// Application entry point.
///
/// Initialises [LocalStorage] (and the legacy [HiveService] until Task 15),
/// hydrates the role + theme from local storage, then mounts the
/// [CoachFinderApp] inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
// ignore: unused_import
import 'core/constants/hive_keys.dart';
import 'core/providers/role_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/router_provider.dart';
import 'core/storage/hive_service.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // New LocalStorage is the authoritative store; HiveService stays alive
  // for unmigrated consumers until Task 15 cleans it up.
  await LocalStorage.init();
  await HiveService.instance.init();

  final initialRole = LocalStorage.get<String>(StorageKeys.userRole);
  final initialThemeMode = themeModeFromStorage(
    LocalStorage.get<String>(StorageKeys.themeMode),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        roleProvider.overrideWith((ref) => initialRole),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
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
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
