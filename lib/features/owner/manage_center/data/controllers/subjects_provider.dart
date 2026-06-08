/// The subject options for the centre edit form's multi-select, fetched from
/// `GET /api/subjects`. Read-only; cached for the session (subjects rarely
/// change).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subject_option.dart';
import 'create_center_provider.dart' show manageCenterRepositoryProvider;

/// All active subjects, for the centre subject picker. Throws
/// [ManageCenterException] on failure (the edit form falls back to the centre's
/// own already-selected subjects).
final FutureProvider<List<SubjectOption>> subjectsProvider =
    FutureProvider<List<SubjectOption>>(
  (ref) => ref.read(manageCenterRepositoryProvider).fetchSubjects(),
);
