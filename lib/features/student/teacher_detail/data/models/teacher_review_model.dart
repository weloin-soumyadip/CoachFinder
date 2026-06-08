/// A public teacher review, parsed from `GET /api/teachers/:id/reviews`
/// (`{student:{name,profileImage}, rating, comment, createdAt}`).
library;

/// One review.
class TeacherReview {
  /// Creates a review.
  const TeacherReview({
    required this.id,
    required this.studentName,
    this.studentImage = '',
    required this.rating,
    this.comment,
    this.createdAt,
  });

  /// Review id.
  final String id;

  /// Author display name.
  final String studentName;

  /// Author avatar URL (may be empty).
  final String studentImage;

  /// Rating 1–5.
  final int rating;

  /// Optional comment.
  final String? comment;

  /// Created timestamp, or null.
  final DateTime? createdAt;

  /// Parses one review doc.
  factory TeacherReview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> student =
        (json['student'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final String name = (student['name'] as String?)?.trim() ?? '';
    return TeacherReview(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      studentName: name.isEmpty ? 'Student' : name,
      studentImage: (student['profileImage'] as String?) ?? '',
      rating: _asInt(json['rating']) ?? 0,
      comment: (json['comment'] as String?)?.trim(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
