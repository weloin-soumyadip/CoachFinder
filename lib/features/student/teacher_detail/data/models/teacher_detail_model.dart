/// Public teacher detail model, parsed from `GET /api/teachers/:id` (the
/// `projectTeacherPublic` shape a student sees). Null-tolerant throughout.
///
/// Note: the backend does NOT populate `subjects` on this endpoint (they come
/// back as bare ObjectIds), so subject *names* are supplied separately by the
/// caller (the search/saved card passes them via the route's `extra`).
library;

/// A `{from, to}` class range.
class TeacherClassRange {
  /// Creates a class range.
  const TeacherClassRange({this.from, this.to});

  /// Lowest grade.
  final int? from;

  /// Highest grade.
  final int? to;

  /// True when neither bound is set.
  bool get isEmpty => from == null && to == null;

  /// Parses `{from, to}`.
  factory TeacherClassRange.fromJson(Map<String, dynamic> json) {
    return TeacherClassRange(
        from: _asInt(json['from']), to: _asInt(json['to']));
  }
}

/// A `{min, max, currency}` fee range.
class TeacherFees {
  /// Creates a fee range.
  const TeacherFees({this.min, this.max, this.currency = 'INR'});

  /// Minimum fee.
  final num? min;

  /// Maximum fee.
  final num? max;

  /// Currency code.
  final String currency;

  /// True when neither bound is set.
  bool get isEmpty => min == null && max == null;

  /// Parses `{min, max, currency}`.
  factory TeacherFees.fromJson(Map<String, dynamic> json) {
    return TeacherFees(
      min: json['min'] as num?,
      max: json['max'] as num?,
      currency: (json['currency'] as String?) ?? 'INR',
    );
  }
}

/// One education entry (`{degree, institution, year, field}`).
class TeacherEducation {
  /// Creates an education entry.
  const TeacherEducation({
    required this.degree,
    this.institution,
    this.field,
    this.year,
  });

  /// Degree (e.g. "M.Sc Physics").
  final String degree;

  /// Institution name.
  final String? institution;

  /// Field of study.
  final String? field;

  /// Year (graduation).
  final int? year;

  /// A one-line summary: "Degree, Institution (Year)".
  String get summary {
    final String tail = <String>[
      if ((institution ?? '').trim().isNotEmpty) institution!.trim(),
      if (year != null) '$year',
    ].join(' · ');
    return tail.isEmpty ? degree : '$degree — $tail';
  }

  /// Parses one education item.
  factory TeacherEducation.fromJson(Map<String, dynamic> json) {
    return TeacherEducation(
      degree: (json['degree'] as String?) ?? '',
      institution: json['institution'] as String?,
      field: json['field'] as String?,
      year: _asInt(json['year']),
    );
  }
}

/// One batch (`{name, days[], startTime, endTime, capacity}`).
class TeacherBatch {
  /// Creates a batch.
  const TeacherBatch({
    required this.name,
    this.days = const <String>[],
    this.startTime,
    this.endTime,
    this.capacity,
  });

  /// Batch name.
  final String name;

  /// Days the batch runs.
  final List<String> days;

  /// Start time `HH:mm`.
  final String? startTime;

  /// End time `HH:mm`.
  final String? endTime;

  /// Capacity.
  final int? capacity;

  /// Parses one batch.
  factory TeacherBatch.fromJson(Map<String, dynamic> json) {
    return TeacherBatch(
      name: (json['name'] as String?) ?? '',
      days: (json['days'] is List)
          ? (json['days'] as List<dynamic>).whereType<String>().toList()
          : const <String>[],
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      capacity: _asInt(json['capacity']),
    );
  }
}

/// The public teacher detail.
class TeacherDetail {
  /// Creates a teacher detail.
  const TeacherDetail({
    required this.id,
    required this.name,
    this.profileImage = '',
    this.bio,
    this.experienceYears = 0,
    this.fees,
    this.boards = const <String>[],
    this.classRange,
    this.languages = const <String>[],
    this.education = const <TeacherEducation>[],
    this.batches = const <TeacherBatch>[],
    this.subjectNames = const <String>[],
    this.city = '',
    this.state = '',
    this.averageRating = 0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  /// Mongo ObjectId string.
  final String id;

  /// Display name.
  final String name;

  /// Avatar URL.
  final String profileImage;

  /// Bio / about text.
  final String? bio;

  /// Years of experience.
  final int experienceYears;

  /// Fee range.
  final TeacherFees? fees;

  /// Boards taught.
  final List<String> boards;

  /// Class range.
  final TeacherClassRange? classRange;

  /// Languages spoken.
  final List<String> languages;

  /// Education entries.
  final List<TeacherEducation> education;

  /// Batches offered.
  final List<TeacherBatch> batches;

  /// Subject names IF the endpoint populated them (usually empty — the caller
  /// supplies names from the search result instead).
  final List<String> subjectNames;

  /// City.
  final String city;

  /// State.
  final String state;

  /// Average rating.
  final double averageRating;

  /// Review count.
  final int totalReviews;

  /// Whether the teacher is verified.
  final bool isVerified;

  /// "City, State" label (drops empty parts).
  String get locationLabel => <String>[city, state]
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .join(', ');

  /// First letter of the name (avatar fallback initial).
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Parses one teacher document. Null-tolerant throughout.
  factory TeacherDetail.fromJson(Map<String, dynamic> json) {
    return TeacherDetail(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      profileImage: (json['profileImage'] as String?) ?? '',
      bio: json['bio'] as String?,
      experienceYears: _asInt(json['experienceYears']) ?? 0,
      fees: json['feesRange'] is Map<String, dynamic>
          ? TeacherFees.fromJson(json['feesRange'] as Map<String, dynamic>)
          : null,
      boards: _stringList(json['boards']),
      classRange: json['classRange'] is Map<String, dynamic>
          ? TeacherClassRange.fromJson(
              json['classRange'] as Map<String, dynamic>)
          : null,
      languages: _stringList(json['languages']),
      education: _education(json['education']),
      batches: _batches(json['batches']),
      subjectNames: _subjectNames(json['subjects']),
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      averageRating: _asDouble(json['averageRating']),
      totalReviews: _asInt(json['totalReviews']) ?? 0,
      isVerified: json['isVerified'] == true,
    );
  }

  /// Only keeps names when `subjects` is populated to objects; bare-id arrays
  /// yield an empty list (the caller supplies names instead).
  static List<String> _subjectNames(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> m) => (m['name'] as String?) ?? '')
        .where((String n) => n.isNotEmpty)
        .toList();
  }

  static List<TeacherEducation> _education(dynamic value) {
    if (value is! List) return const <TeacherEducation>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(TeacherEducation.fromJson)
        .where((TeacherEducation e) => e.degree.isNotEmpty)
        .toList();
  }

  static List<TeacherBatch> _batches(dynamic value) {
    if (value is! List) return const <TeacherBatch>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(TeacherBatch.fromJson)
        .where((TeacherBatch b) => b.name.isNotEmpty)
        .toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList();
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

/// Coerces a dynamic JSON number/string to an int, or null.
int? _asInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
