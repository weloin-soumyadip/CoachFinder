/// An upcoming webinar (and its host) surfaced on the student dashboard.
library;

/// Minimal host projection nested under each `upcomingWebinars[]` element.
class WebinarTeacher {
  const WebinarTeacher({
    required this.name,
    required this.profileImage,
    required this.totalReviews,
  });

  /// Host teacher display name. Empty string when omitted.
  final String name;

  /// Host avatar URL. Empty string when omitted.
  final String profileImage;

  /// Host's total review count (used for ranking server-side). Defaults to 0.
  final int totalReviews;

  /// Parses the nested `teacher` object.
  factory WebinarTeacher.fromJson(Map<String, dynamic> json) {
    return WebinarTeacher(
      name: (json['name'] as String?) ?? '',
      profileImage: (json['profileImage'] as String?) ?? '',
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One entry in `dashboard.upcomingWebinars` from
/// `GET /api/students/dashboard`. `_id` is mapped to [id] and `scheduledAt`
/// (ISO 8601) is parsed to a [DateTime].
class UpcomingWebinar {
  const UpcomingWebinar({
    required this.id,
    required this.title,
    required this.teacher,
    required this.scheduledAt,
    required this.thumbnail,
    required this.joinUrl,
  });

  /// Backend `_id`.
  final String id;

  /// Webinar title.
  final String title;

  /// The hosting teacher.
  final WebinarTeacher teacher;

  /// Scheduled start time (UTC as returned by the backend).
  final DateTime scheduledAt;

  /// Thumbnail image URL. Empty string when omitted.
  final String thumbnail;

  /// Join link. Empty string when omitted.
  final String joinUrl;

  /// Parses one `upcomingWebinars[]` element, applying the controller's
  /// defaults.
  factory UpcomingWebinar.fromJson(Map<String, dynamic> json) {
    return UpcomingWebinar(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      teacher: WebinarTeacher.fromJson(
        (json['teacher'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      thumbnail: (json['thumbnail'] as String?) ?? '',
      joinUrl: (json['joinUrl'] as String?) ?? '',
    );
  }
}
