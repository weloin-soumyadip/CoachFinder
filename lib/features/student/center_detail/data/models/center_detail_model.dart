/// Public coaching-centre detail model, parsed from `GET /api/centers/:id`
/// (the `projectCenterPublic` shape a student sees). Null-tolerant throughout.
library;

/// A subject offered by the centre (`{_id, name}`).
class CenterDetailSubject {
  /// Creates a subject.
  const CenterDetailSubject({required this.id, required this.name});

  /// Subject id.
  final String id;

  /// Display name.
  final String name;

  /// Parses `{_id|id, name}` (or a bare id string).
  factory CenterDetailSubject.fromJson(dynamic value) {
    if (value is String) return CenterDetailSubject(id: value, name: '');
    if (value is Map<String, dynamic>) {
      return CenterDetailSubject(
        id: (value['_id'] ?? value['id'] ?? '').toString(),
        name: (value['name'] as String?) ?? '',
      );
    }
    return const CenterDetailSubject(id: '', name: '');
  }
}

/// A `{from, to}` class range.
class CenterDetailClassRange {
  /// Creates a class range.
  const CenterDetailClassRange({this.from, this.to});

  /// Lowest grade.
  final int? from;

  /// Highest grade.
  final int? to;

  /// True when neither bound is set.
  bool get isEmpty => from == null && to == null;

  /// Parses `{from, to}`.
  factory CenterDetailClassRange.fromJson(Map<String, dynamic> json) {
    return CenterDetailClassRange(
      from: _asInt(json['from']),
      to: _asInt(json['to']),
    );
  }
}

/// A `{min, max, currency}` fee range.
class CenterDetailFees {
  /// Creates a fee range.
  const CenterDetailFees({this.min, this.max, this.currency = 'INR'});

  /// Minimum fee.
  final num? min;

  /// Maximum fee.
  final num? max;

  /// Currency code.
  final String currency;

  /// True when neither bound is set.
  bool get isEmpty => min == null && max == null;

  /// Parses `{min, max, currency}`.
  factory CenterDetailFees.fromJson(Map<String, dynamic> json) {
    return CenterDetailFees(
      min: json['min'] as num?,
      max: json['max'] as num?,
      currency: (json['currency'] as String?) ?? 'INR',
    );
  }
}

/// One day's timing (`{day, openTime?, closeTime?, closed}`).
class CenterDetailTiming {
  /// Creates a timing.
  const CenterDetailTiming({
    required this.day,
    this.openTime,
    this.closeTime,
    this.closed = false,
  });

  /// Day label (`Mon`…`Sun`).
  final String day;

  /// Opening time `HH:mm`.
  final String? openTime;

  /// Closing time `HH:mm`.
  final String? closeTime;

  /// Whether the centre is closed this day.
  final bool closed;

  /// Parses one timing item.
  factory CenterDetailTiming.fromJson(Map<String, dynamic> json) {
    return CenterDetailTiming(
      day: (json['day'] as String?) ?? '',
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      closed: (json['closed'] as bool?) ?? false,
    );
  }
}

/// The public coaching-centre detail.
class CenterDetail {
  /// Creates a centre detail.
  const CenterDetail({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.area,
    required this.city,
    required this.state,
    this.pincode,
    this.country,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.website,
    this.subjects = const <CenterDetailSubject>[],
    this.boards = const <String>[],
    this.classRange,
    this.fees,
    this.timings = const <CenterDetailTiming>[],
    this.profileImage = '',
    this.bannerImage = '',
    this.gallery = const <String>[],
    this.averageRating = 0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  /// Mongo ObjectId string.
  final String id;

  /// Centre name.
  final String name;

  /// Long-form description.
  final String? description;

  /// Street address.
  final String address;

  /// Locality / area.
  final String? area;

  /// City.
  final String city;

  /// State.
  final String state;

  /// PIN code.
  final String? pincode;

  /// Country.
  final String? country;

  /// Primary phone.
  final String phone;

  /// Alternate phone.
  final String? alternatePhone;

  /// Contact email.
  final String? email;

  /// Website URL.
  final String? website;

  /// Subjects offered.
  final List<CenterDetailSubject> subjects;

  /// Board / curriculum values.
  final List<String> boards;

  /// Class range.
  final CenterDetailClassRange? classRange;

  /// Fee range.
  final CenterDetailFees? fees;

  /// Weekly timings.
  final List<CenterDetailTiming> timings;

  /// Profile image URL.
  final String profileImage;

  /// Banner image URL.
  final String bannerImage;

  /// Gallery image URLs.
  final List<String> gallery;

  /// Denormalised average rating.
  final double averageRating;

  /// Denormalised review count.
  final int totalReviews;

  /// Whether the centre is verified.
  final bool isVerified;

  /// "Area, City" location label (drops empty parts).
  String get locationLabel => <String>[area ?? '', city]
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .join(', ');

  /// First letter of the name (logo fallback initial).
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Parses one centre document. Null-tolerant throughout.
  factory CenterDetail.fromJson(Map<String, dynamic> json) {
    return CenterDetail(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      address: (json['address'] as String?) ?? '',
      area: json['area'] as String?,
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      pincode: json['pincode'] as String?,
      country: json['country'] as String?,
      phone: (json['phone'] as String?) ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      subjects: _subjects(json['subjectsOffered']),
      boards: _stringList(json['boards']),
      classRange: json['classRange'] is Map<String, dynamic>
          ? CenterDetailClassRange.fromJson(
              json['classRange'] as Map<String, dynamic>)
          : null,
      fees: json['fees'] is Map<String, dynamic>
          ? CenterDetailFees.fromJson(json['fees'] as Map<String, dynamic>)
          : null,
      timings: _timings(json['timings']),
      profileImage: (json['profileImage'] as String?) ?? '',
      bannerImage: (json['bannerImage'] as String?) ?? '',
      gallery: _stringList(json['gallery']),
      averageRating: _asDouble(json['averageRating']),
      totalReviews: _asInt(json['totalReviews']) ?? 0,
      isVerified: json['isVerified'] == true,
    );
  }

  static List<CenterDetailSubject> _subjects(dynamic value) {
    if (value is! List) return const <CenterDetailSubject>[];
    return value.map(CenterDetailSubject.fromJson).toList();
  }

  static List<CenterDetailTiming> _timings(dynamic value) {
    if (value is! List) return const <CenterDetailTiming>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CenterDetailTiming.fromJson)
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
