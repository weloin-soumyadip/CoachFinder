/// StateProvider holding the active [ThemeMode] (system / light / dark).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide theme mode.
///
/// - [ThemeMode.system] - follow the OS appearance (the default).
/// - [ThemeMode.light] / [ThemeMode.dark] - force that brightness.
///
/// The initial value is hydrated from Hive in `main.dart` via a `ProviderScope`
/// override so [MaterialApp] can read it synchronously on first build. The
/// student Profile screen mutates it and persists the change.
final StateProvider<ThemeMode> themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Decode a persisted theme-mode string (a [ThemeMode.name]) back into a
/// [ThemeMode], falling back to [ThemeMode.system] for null / unknown values.
ThemeMode themeModeFromStorage(String? stored) {
  return ThemeMode.values.firstWhere(
    (ThemeMode mode) => mode.name == stored,
    orElse: () => ThemeMode.system,
  );
}
