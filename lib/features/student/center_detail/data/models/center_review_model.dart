/// A public coaching-centre review, parsed from `GET /api/centers/:id/reviews`
/// (`{student:{name,profileImage}, rating, comment, createdAt}`).
library;

/// One review.
class CenterReview {
  /// Creates a review.
  const CenterReview({
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
  factory CenterReview.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> student =
        (json['student'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return CenterReview(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      studentName: (student['name'] as String?)?.trim().isNotEmpty == true
          ? (student['name'] as String).trim()
          : 'Student',
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
