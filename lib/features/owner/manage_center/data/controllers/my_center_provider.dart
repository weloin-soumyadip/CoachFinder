/// Read-only access to the authenticated owner's coaching centre
/// (`GET /api/centers/me`). The dashboard header watches this for the live
/// centre name. `autoDispose` so it re-fetches when the dashboard is re-entered
/// — keeping the name fresh across logins and after a centre is created.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/owner_center.dart';
import 'create_center_provider.dart' show manageCenterRepositoryProvider;

/// Fetches the owner's centre, or null when they have none (`404`). Throws
/// [ManageCenterException] on a real failure (the consumer can fall back).
final AutoDisposeFutureProvider<OwnerCenter?> myCenterProvider =
    FutureProvider.autoDispose<OwnerCenter?>(
  (ref) => ref.read(manageCenterRepositoryProvider).getMine(),
);
