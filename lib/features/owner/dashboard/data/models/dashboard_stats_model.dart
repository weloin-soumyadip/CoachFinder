/// Models for the owner dashboard, backing `GET /api/owners/dashboard`. The
/// backend returns six metric sections (counters + a 7-day view series + the
/// latest enquiries) for the calling owner's single coaching center, nested
/// under the envelope's `data` key.
library;

/// One day in the dashboard's 7-day profile-view series. The backend always
/// returns exactly 7 of these, ascending and zero-filled for empty days.
class ProfileViewPoint {
  const ProfileViewPoint({required this.date, required this.views});

  /// The day this point represents, parsed from a bare `YYYY-MM-DD` string.
  /// Null when the field is absent or unparseable.
  final DateTime? date;

  /// The profile-view count for [date] (0 on a zero-filled day).
  final int views;

  /// Parses one `{date, views}` entry. Null-tolerant: a bad/absent date → null,
  /// a missing or string-encoded `views` → coerced (defaulting to 0).
  factory ProfileViewPoint.fromJson(Map<String, dynamic> json) {
    return ProfileViewPoint(
      date: DateTime.tryParse((json['date'] ?? '').toString()),
      views: _asInt(json['views'], 0),
    );
  }
}

/// A summary of one recent enquiry sent to the owner's center, with the
/// student's contact populated. Newest-first; the backend returns at most 5.
class RecentEnquiry {
  const RecentEnquiry({
    required this.enquiryId,
    required this.studentName,
    required this.phone,
    required this.email,
    required this.message,
    required this.createdAt,
  });

  /// The enquiry document's id.
  final String enquiryId;

  /// The enquiring student's display name.
  final String studentName;

  /// The student's phone number (may be empty when absent).
  final String phone;

  /// The student's email (may be empty when absent).
  final String email;

  /// The enquiry message body.
  final String message;

  /// When the enquiry was created. Null when absent/unparseable.
  final DateTime? createdAt;

  /// Parses one enquiry. All strings default to `''`; `createdAt` is parsed via
  /// [DateTime.tryParse] so a malformed timestamp yields null rather than throws.
  factory RecentEnquiry.fromJson(Map<String, dynamic> json) {
    return RecentEnquiry(
      enquiryId: (json['enquiryId'] ?? '').toString(),
      studentName: (json['studentName'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

/// The full owner-dashboard payload (the envelope's `data` block). Aggregates
/// the six metric sections the presentation layer maps into its `DashboardStat`
/// / `DailyViews` / `EnquiryPreview` view models.
class OwnerDashboardData {
  const OwnerDashboardData({
    required this.weeklyProfileViews,
    required this.weeklyEnquiries,
    required this.averageRating,
    required this.totalReviews,
    required this.activeStudents,
    required this.profileViewStats,
    required this.recentEnquiries,
  });

  /// Total profile views over the trailing 7-day window.
  final int weeklyProfileViews;

  /// Total enquiries received over the trailing 7-day window.
  final int weeklyEnquiries;

  /// The center's lifetime average rating (always a double, even when the
  /// backend serialises a whole number as an int).
  final double averageRating;

  /// The center's lifetime total review count.
  final int totalReviews;

  /// Distinct active students associated with the center.
  final int activeStudents;

  /// The 7-day profile-view series (ascending, zero-filled). Empty only when the
  /// field is absent/malformed.
  final List<ProfileViewPoint> profileViewStats;

  /// The latest enquiries (newest-first, at most 5). Empty when absent/malformed.
  final List<RecentEnquiry> recentEnquiries;

  /// Parses the dashboard `data` block. Null-tolerant throughout: missing numbers
  /// default to 0, missing/malformed arrays to an empty list, and numeric fields
  /// are coerced from numbers OR numeric strings (the defensive style used across
  /// the search / bookmarks data layer).
  factory OwnerDashboardData.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardData(
      weeklyProfileViews: _asInt(json['weeklyProfileViews'], 0),
      weeklyEnquiries: _asInt(json['weeklyEnquiries'], 0),
      averageRating: _asDouble(json['averageRating'], 0),
      totalReviews: _asInt(json['totalReviews'], 0),
      activeStudents: _asInt(json['activeStudents'], 0),
      profileViewStats: _parseList(
        json['profileViewStats'],
        ProfileViewPoint.fromJson,
      ),
      recentEnquiries: _parseList(
        json['recentEnquiries'],
        RecentEnquiry.fromJson,
      ),
    );
  }
}

/// Maps a value that may be a [List] of maps (or anything else) into a typed
/// list via [fromJson], skipping non-map entries. A null / wrong-typed value
/// yields an empty list.
List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return <T>[];
  return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

/// Coerces a value that may be a number, a numeric string, or absent into an
/// int, falling back to [fallback] when it is null/unparseable.
int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Coerces a value that may be a number (int OR double), a numeric string, or
/// absent into a double, falling back to [fallback] when it is null/unparseable.
double _asDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
