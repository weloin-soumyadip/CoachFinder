/// A subject choice from `GET /api/subjects` (and the populated
/// `subjectsOffered` on a centre). Only `id` + `name` are needed for the
/// multi-select and display; the centre persists the `id`s.
library;

/// A selectable subject (`{_id, name}`).
class SubjectOption {
  /// Creates a subject option.
  const SubjectOption({required this.id, required this.name});

  /// Mongo ObjectId string (maps from `_id`).
  final String id;

  /// Display name.
  final String name;

  /// Parses one subject document (`{_id|id, name}`), tolerating a missing name.
  factory SubjectOption.fromJson(Map<String, dynamic> json) {
    return SubjectOption(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SubjectOption && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
