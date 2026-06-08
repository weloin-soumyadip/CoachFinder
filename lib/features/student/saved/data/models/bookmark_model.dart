/// Bookmark model + target-type enum for the student Saved feature, backing
/// `GET/POST/DELETE /api/students/bookmarks`. A bookmark is polymorphic — its
/// [Bookmark.target] resolves to a Teacher, Webinar, or CoachingCenter.
library;

/// The kind of entity a bookmark points at. [wireValue] is the exact string
/// the backend's `targetType` enum uses; [fromWire] parses it back.
enum BookmarkTargetType {
  /// A coaching teacher (`'Teacher'`).
  teacher,

  /// A scheduled webinar (`'Webinar'`).
  webinar,

  /// A coaching center / institute (`'CoachingCenter'`).
  coachingCenter;

  /// The exact backend `targetType` string for this value.
  String get wireValue {
    switch (this) {
      case BookmarkTargetType.teacher:
        return 'Teacher';
      case BookmarkTargetType.webinar:
        return 'Webinar';
      case BookmarkTargetType.coachingCenter:
        return 'CoachingCenter';
    }
  }

  /// Parses a backend `targetType` string. Tolerant: an unrecognised value
  /// falls back to [BookmarkTargetType.teacher] so a stray payload never throws.
  static BookmarkTargetType fromWire(String wire) {
    switch (wire) {
      case 'Teacher':
        return BookmarkTargetType.teacher;
      case 'Webinar':
        return BookmarkTargetType.webinar;
      case 'CoachingCenter':
        return BookmarkTargetType.coachingCenter;
      default:
        return BookmarkTargetType.teacher;
    }
  }
}

/// One saved item. The backend `target` is either a populated object (the list
/// endpoint, union-selected to `_id, name, profileImage, averageRating,
/// totalReviews, isVerified, slug, city, area, title, scheduledAt,
/// durationMinutes, thumbnail, joinUrl, status`) or a bare id string (the
/// create endpoint, which does not populate). The raw [target] map is kept
/// intact so the presentation layer can feed it straight into the existing
/// `TeacherSearchResult` / `CenterSearchResult` / `WebinarSearchResult`
/// `fromJson`s.
class Bookmark {
  const Bookmark({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.target,
    this.createdAt,
  });

  /// The bookmark's own `_id` — the value DELETE expects in its path.
  final String id;

  /// Which collection [target] / [targetId] resolves to.
  final BookmarkTargetType targetType;

  /// The bookmarked entity's `_id` (the target's id, NOT the bookmark id).
  final String targetId;

  /// The raw populated target object (empty map on a create response, where the
  /// backend returns only the bare id string).
  final Map<String, dynamic> target;

  /// When the bookmark was created (null when the field is absent/unparseable).
  final DateTime? createdAt;

  /// Stable identity used for fast membership lookup on search cards:
  /// `'<targetType.wireValue>:<targetId>'`, e.g. `'Teacher:t1'`.
  String get key => '${targetType.wireValue}:$targetId';

  /// Parses one bookmark, handling both envelope shapes for `target`:
  /// a populated `Map` (list) → kept as [target], [targetId] from `target._id`;
  /// a bare `String` (create) → [target] empty, [targetId] is the string.
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    final dynamic rawTarget = json['target'];
    final Map<String, dynamic> targetMap =
        rawTarget is Map<String, dynamic> ? rawTarget : <String, dynamic>{};
    final String targetId = rawTarget is Map<String, dynamic>
        ? (targetMap['_id'] ?? '').toString()
        : (rawTarget ?? '').toString();
    return Bookmark(
      id: (json['_id'] ?? '').toString(),
      targetType:
          BookmarkTargetType.fromWire((json['targetType'] ?? '').toString()),
      targetId: targetId,
      target: targetMap,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
