/// A top-rated teacher surfaced on the student dashboard.
library;

/// One entry in `dashboard.topTeachers` from `GET /api/students/dashboard`.
///
/// Public-safe projection (no email/phone). Field names mirror the backend
/// controller exactly; `_id` is mapped to [id].
class TopTeacher {
  const TopTeacher({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.subjects,
    required this.averageRating,
    required this.totalReviews,
  });

  /// Backend `_id`.
  final String id;

  /// Teacher display name.
  final String name;

  /// Avatar URL. Empty string when the backend omits it.
  final String profileImage;

  /// Subject names the teacher covers (backend already flattens to strings).
  final List<String> subjects;

  /// Mean review rating (0..5). Defaults to 0.
  final double averageRating;

  /// Number of reviews backing [averageRating]. Defaults to 0.
  final int totalReviews;

  /// Parses one `topTeachers[]` element, applying the controller's defaults.
  factory TopTeacher.fromJson(Map<String, dynamic> json) {
    return TopTeacher(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      profileImage: (json['profileImage'] as String?) ?? '',
      subjects: (json['subjects'] as List<dynamic>?)
              ?.map((dynamic s) => s.toString())
              .toList() ??
          <String>[],
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}
