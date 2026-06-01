/// A top-rated coaching center surfaced on the student dashboard.
library;

/// One entry in `dashboard.topCenters` from `GET /api/students/dashboard`.
///
/// Public-safe projection. Field names mirror the backend controller exactly;
/// `_id` is mapped to [id] and the center's `profileImage` is exposed as
/// [image] (the controller renames it on the way out).
class TopCenter {
  const TopCenter({
    required this.id,
    required this.name,
    required this.image,
    required this.averageRating,
    required this.totalReviews,
    required this.city,
    required this.area,
  });

  /// Backend `_id`.
  final String id;

  /// Center display name.
  final String name;

  /// Cover/logo image URL. Empty string when omitted.
  final String image;

  /// Mean review rating (0..5). Defaults to 0.
  final double averageRating;

  /// Number of reviews backing [averageRating]. Defaults to 0.
  final int totalReviews;

  /// City the center is in.
  final String city;

  /// Area/locality within [city]. Empty string when omitted.
  final String area;

  /// Parses one `topCenters[]` element, applying the controller's defaults.
  factory TopCenter.fromJson(Map<String, dynamic> json) {
    return TopCenter(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      image: (json['image'] as String?) ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      city: (json['city'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
    );
  }
}
