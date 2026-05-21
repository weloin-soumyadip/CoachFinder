/// StateProvider holding the active user role.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Role constant for the student experience.
const String roleStudent = 'student';

/// Role constant for the coaching-owner experience.
const String roleOwner = 'owner';

/// The currently selected user role.
///
/// - `'student'` - app behaves as the student shell.
/// - `'owner'` - app behaves as the coaching-owner shell.
/// - `null` - no role yet chosen; force the onboarding flow.
///
/// The initial value is hydrated from Hive in `main.dart` via a
/// `ProviderScope` override so the router can read it synchronously on first build.
final StateProvider<String?> roleProvider = StateProvider<String?>((ref) => null);
