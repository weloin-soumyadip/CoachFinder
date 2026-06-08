/// Search result models (teacher / center / webinar) and the pagination block
/// returned by `GET /api/search`.
library;

/// A min/max money range. Backed by the backend `feesRange` (teacher) and
/// `fees` (center) sub-documents, which share the `{min, max}` shape.
class FeesRange {
  const FeesRange({required this.min, required this.max});

  /// Lower bound (defaults to 0 when the key is absent).
  final int min;

  /// Upper bound (defaults to 0 when the key is absent).
  final int max;

  /// Parses a `{min, max}` map; missing keys default to 0.
  factory FeesRange.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeesRange(min: 0, max: 0);
    return FeesRange(
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Pagination metadata sibling of `data` on every search response envelope:
/// `{ page, limit, total, pages }`. The standard [ApiResponse] drops this, so
/// the datasource reads it from the raw envelope and builds this directly.
class SearchPagination {
  const SearchPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  /// 1-based page number this response represents.
  final int page;

  /// Page size requested.
  final int limit;

  /// Total matching documents across all pages.
  final int total;

  /// Total number of pages (always >= 1 from the backend).
  final int pages;

  /// True when a later page exists. Drives infinite-scroll / "load more".
  bool get hasMore => page < pages;

  /// Parses the `pagination` block; missing numbers default to a single page.
  /// Values are coerced from either numbers OR numeric strings — the bookmarks
  /// endpoint echoes the raw query params (`page: '1'`, `limit: '50'`) as
  /// strings, which a hard `as num` cast would throw on.
  factory SearchPagination.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SearchPagination(page: 1, limit: 0, total: 0, pages: 1);
    }
    return SearchPagination(
      page: _asInt(json['page'], 1),
      limit: _asInt(json['limit'], 0),
      total: _asInt(json['total'], 0),
      pages: _asInt(json['pages'], 1),
    );
  }
}

/// Coerces a JSON value that may be a number, a numeric string, or absent into
/// an int, falling back to [fallback] when it is null or unparseable.
int _asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Flattens a populated subject array (`[{_id, name, slug}, ...]`) — or a raw
/// id/string array — into a list of human-readable names.
List<String> _subjectNames(dynamic raw) {
  if (raw is! List) return <String>[];
  return raw
      .map((dynamic s) {
        if (s is Map<String, dynamic>) return (s['name'] ?? '').toString();
        return s.toString();
      })
      .where((String n) => n.isNotEmpty)
      .toList();
}

/// Coerces a backend string array into a `List<String>`.
List<String> _stringList(dynamic raw) {
  if (raw is! List) return <String>[];
  return raw.map((dynamic s) => s.toString()).toList();
}

/// One `data[]` element of a `searchType=teacher` response. Public-safe
/// projection — `_id` is mapped to [id]; populated `subjects` are flattened
/// to names.
class TeacherSearchResult {
  const TeacherSearchResult({
    required this.id,
    required this.name,
    required this.profileImage,
    required this.subjects,
    required this.experienceYears,
    required this.feesRange,
    required this.boards,
    required this.city,
    required this.state,
    required this.averageRating,
    required this.totalReviews,
    required this.isVerified,
  });

  /// Backend `_id`.
  final String id;

  /// Teacher display name.
  final String name;

  /// Avatar URL ('' when omitted).
  final String profileImage;

  /// Subject names the teacher teaches (flattened from populated objects).
  final List<String> subjects;

  /// Years of experience (0 when omitted).
  final int experienceYears;

  /// Fees range (`feesRange.{min,max}`).
  final FeesRange feesRange;

  /// Boards taught (e.g. `['CBSE', 'ICSE']`).
  final List<String> boards;

  /// City ('' when omitted).
  final String city;

  /// State ('' when omitted).
  final String state;

  /// Mean review rating (0..5). Defaults to 0.
  final double averageRating;

  /// Number of reviews backing [averageRating].
  final int totalReviews;

  /// Whether the teacher is verified.
  final bool isVerified;

  /// Parses one teacher search item, tolerating absent projection keys.
  factory TeacherSearchResult.fromJson(Map<String, dynamic> json) {
    return TeacherSearchResult(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      profileImage: (json['profileImage'] as String?) ?? '',
      subjects: _subjectNames(json['subjects']),
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      feesRange: FeesRange.fromJson(json['feesRange'] as Map<String, dynamic>?),
      boards: _stringList(json['boards']),
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      isVerified: (json['isVerified'] as bool?) ?? false,
    );
  }
}

/// One `data[]` element of a `searchType=coaching` response. `_id` is mapped
/// to [id]; populated `subjectsOffered` are flattened to names.
class CenterSearchResult {
  const CenterSearchResult({
    required this.id,
    required this.name,
    required this.area,
    required this.city,
    required this.state,
    required this.subjectsOffered,
    required this.boards,
    required this.fees,
    required this.profileImage,
    required this.averageRating,
    required this.totalReviews,
    required this.isVerified,
  });

  /// Backend `_id`.
  final String id;

  /// Center name.
  final String name;

  /// Locality / area ('' when omitted).
  final String area;

  /// City ('' when omitted).
  final String city;

  /// State ('' when omitted).
  final String state;

  /// Subject names offered (flattened from populated objects).
  final List<String> subjectsOffered;

  /// Boards offered.
  final List<String> boards;

  /// Fees range (`fees.{min,max}`).
  final FeesRange fees;

  /// Profile / logo image URL ('' when omitted).
  final String profileImage;

  /// Mean review rating (0..5). Defaults to 0.
  final double averageRating;

  /// Number of reviews backing [averageRating].
  final int totalReviews;

  /// Whether the center is verified.
  final bool isVerified;

  /// Parses one center search item, tolerating absent projection keys.
  factory CenterSearchResult.fromJson(Map<String, dynamic> json) {
    return CenterSearchResult(
      id: (json['_id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      subjectsOffered: _subjectNames(json['subjectsOffered']),
      boards: _stringList(json['boards']),
      fees: FeesRange.fromJson(json['fees'] as Map<String, dynamic>?),
      profileImage: (json['profileImage'] as String?) ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      isVerified: (json['isVerified'] as bool?) ?? false,
    );
  }
}

/// One `data[]` element of a `searchType=webinar` response. The populated
/// `teacher` object is flattened into [teacherName] / [teacherProfileImage].
class WebinarSearchResult {
  const WebinarSearchResult({
    required this.id,
    required this.title,
    required this.teacherName,
    required this.teacherProfileImage,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.thumbnail,
    required this.joinUrl,
    required this.status,
  });

  /// Backend `_id`.
  final String id;

  /// Webinar title.
  final String title;

  /// Hosting teacher's name ('' when the teacher is absent).
  final String teacherName;

  /// Hosting teacher's avatar URL ('' when absent).
  final String teacherProfileImage;

  /// Scheduled start, parsed from the backend UTC ISO string.
  final DateTime scheduledAt;

  /// Duration in minutes (0 when omitted).
  final int durationMinutes;

  /// Thumbnail URL ('' when omitted).
  final String thumbnail;

  /// Join URL ('' when omitted).
  final String joinUrl;

  /// Status: `scheduled` / `live` / `completed` / `cancelled` ('' when absent).
  final String status;

  /// Parses one webinar search item. [scheduledAt] falls back to epoch when
  /// the field is missing or unparseable so callers never null-check it.
  factory WebinarSearchResult.fromJson(Map<String, dynamic> json) {
    final dynamic teacher = json['teacher'];
    final Map<String, dynamic> teacherMap =
        teacher is Map<String, dynamic> ? teacher : <String, dynamic>{};
    return WebinarSearchResult(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] as String?) ?? '',
      teacherName: (teacherMap['name'] as String?) ?? '',
      teacherProfileImage: (teacherMap['profileImage'] as String?) ?? '',
      scheduledAt: DateTime.tryParse((json['scheduledAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      thumbnail: (json['thumbnail'] as String?) ?? '',
      joinUrl: (json['joinUrl'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
    );
  }
}
