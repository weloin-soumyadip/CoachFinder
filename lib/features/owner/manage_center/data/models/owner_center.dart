/// Full owner-visible coaching-centre model, parsed from `GET /api/centers/me`.
/// Mirrors the backend `CoachingCenter` document (the editable subset + the
/// read-only rating/reviews). The nested [CenterFees] / [CenterClassRange] /
/// [CenterTiming] carry `toJson` too so the [CenterUpdate] payload can reuse
/// them.
library;

import 'subject_option.dart';

/// The owner's coaching centre.
class OwnerCenter {
  /// Creates a centre.
  const OwnerCenter({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.area,
    required this.city,
    required this.state,
    required this.pincode,
    this.country,
    required this.phone,
    this.alternatePhone,
    this.email,
    this.website,
    this.subjects = const <SubjectOption>[],
    this.boards = const <String>[],
    this.classRange,
    this.fees,
    this.timings = const <CenterTiming>[],
    this.gallery = const <String>[],
    this.profileImage = '',
    this.bannerImage = '',
    this.averageRating = 0,
    this.totalReviews = 0,
  });

  /// Mongo ObjectId string.
  final String id;

  /// Centre name.
  final String name;

  /// Long-form description ("about"), or null.
  final String? description;

  /// Street address.
  final String address;

  /// Locality / area, or null.
  final String? area;

  /// City.
  final String city;

  /// State / province.
  final String state;

  /// Postal / PIN code.
  final String pincode;

  /// Country (defaults to India server-side), or null.
  final String? country;

  /// Primary phone.
  final String phone;

  /// Alternate phone, or null.
  final String? alternatePhone;

  /// Contact email, or null.
  final String? email;

  /// Website URL, or null.
  final String? website;

  /// Subjects offered (populated `{_id,name}`).
  final List<SubjectOption> subjects;

  /// Board / curriculum enum values.
  final List<String> boards;

  /// Class range, or null.
  final CenterClassRange? classRange;

  /// Fee range, or null.
  final CenterFees? fees;

  /// Weekly timings.
  final List<CenterTiming> timings;

  /// Gallery image URLs (read-only — no uploader yet).
  final List<String> gallery;

  /// Profile image URL.
  final String profileImage;

  /// Banner image URL.
  final String bannerImage;

  /// Denormalised average rating (read-only).
  final double averageRating;

  /// Denormalised review count (read-only).
  final int totalReviews;

  /// The backend's board enum values (the source of truth for the selector).
  static const List<String> boardOptions = <String>[
    'CBSE',
    'ICSE',
    'State',
    'IB',
    'IGCSE',
    'Other',
  ];

  /// Parses one centre document. Null-tolerant throughout so a partial payload
  /// can't throw.
  factory OwnerCenter.fromJson(Map<String, dynamic> json) {
    return OwnerCenter(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      address: (json['address'] as String?) ?? '',
      area: json['area'] as String?,
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      pincode: (json['pincode'] as String?) ?? '',
      country: json['country'] as String?,
      phone: (json['phone'] as String?) ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      subjects: _subjectsFrom(json['subjectsOffered']),
      boards: _stringList(json['boards']),
      classRange: json['classRange'] is Map<String, dynamic>
          ? CenterClassRange.fromJson(
              json['classRange'] as Map<String, dynamic>)
          : null,
      fees: json['fees'] is Map<String, dynamic>
          ? CenterFees.fromJson(json['fees'] as Map<String, dynamic>)
          : null,
      timings: _timingsFrom(json['timings']),
      gallery: _stringList(json['gallery']),
      profileImage: (json['profileImage'] as String?) ?? '',
      bannerImage: (json['bannerImage'] as String?) ?? '',
      averageRating: _toDouble(json['averageRating']),
      totalReviews: _toInt(json['totalReviews']),
    );
  }

  /// Parses `subjectsOffered`, which may be populated objects (`{_id,name}`) or
  /// bare id strings.
  static List<SubjectOption> _subjectsFrom(dynamic value) {
    if (value is! List) return const <SubjectOption>[];
    return value
        .map<SubjectOption?>((dynamic e) {
          if (e is Map<String, dynamic>) return SubjectOption.fromJson(e);
          if (e is String) return SubjectOption(id: e, name: '');
          return null;
        })
        .whereType<SubjectOption>()
        .toList();
  }

  static List<CenterTiming> _timingsFrom(dynamic value) {
    if (value is! List) return const <CenterTiming>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CenterTiming.fromJson)
        .toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.whereType<String>().toList();
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// A `{from, to}` class range (grades 1–12).
class CenterClassRange {
  /// Creates a class range.
  const CenterClassRange({this.from, this.to});

  /// Lowest grade, or null.
  final int? from;

  /// Highest grade, or null.
  final int? to;

  /// True when neither bound is set.
  bool get isEmpty => from == null && to == null;

  /// Parses `{from, to}`.
  factory CenterClassRange.fromJson(Map<String, dynamic> json) {
    return CenterClassRange(
      from: _toIntOrNull(json['from']),
      to: _toIntOrNull(json['to']),
    );
  }

  /// Serialises only the set bounds.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };

  @override
  bool operator ==(Object other) =>
      other is CenterClassRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// A `{min, max, currency}` fee range.
class CenterFees {
  /// Creates a fee range.
  const CenterFees({this.min, this.max, this.currency = 'INR'});

  /// Minimum fee, or null.
  final num? min;

  /// Maximum fee, or null.
  final num? max;

  /// Currency code (defaults INR).
  final String currency;

  /// True when neither bound is set.
  bool get isEmpty => min == null && max == null;

  /// Parses `{min, max, currency}`.
  factory CenterFees.fromJson(Map<String, dynamic> json) {
    return CenterFees(
      min: json['min'] as num?,
      max: json['max'] as num?,
      currency: (json['currency'] as String?) ?? 'INR',
    );
  }

  /// Serialises the set bounds plus the currency.
  Map<String, dynamic> toJson() => <String, dynamic>{
        if (min != null) 'min': min,
        if (max != null) 'max': max,
        'currency': currency,
      };

  @override
  bool operator ==(Object other) =>
      other is CenterFees &&
      other.min == min &&
      other.max == max &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(min, max, currency);
}

/// One day's timing (`{day, openTime?, closeTime?, closed}`).
class CenterTiming {
  /// Creates a timing.
  const CenterTiming({
    required this.day,
    this.openTime,
    this.closeTime,
    this.closed = false,
  });

  /// Day label (`Mon`…`Sun`).
  final String day;

  /// Opening time `HH:mm`, or null.
  final String? openTime;

  /// Closing time `HH:mm`, or null.
  final String? closeTime;

  /// Whether the centre is closed this day.
  final bool closed;

  /// Parses one timing item.
  factory CenterTiming.fromJson(Map<String, dynamic> json) {
    return CenterTiming(
      day: (json['day'] as String?) ?? '',
      openTime: json['openTime'] as String?,
      closeTime: json['closeTime'] as String?,
      closed: (json['closed'] as bool?) ?? false,
    );
  }

  /// Serialises the timing (omitting null times).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'day': day,
        if (openTime != null) 'openTime': openTime,
        if (closeTime != null) 'closeTime': closeTime,
        'closed': closed,
      };

  @override
  bool operator ==(Object other) =>
      other is CenterTiming &&
      other.day == day &&
      other.openTime == openTime &&
      other.closeTime == closeTime &&
      other.closed == closed;

  @override
  int get hashCode => Object.hash(day, openTime, closeTime, closed);
}

/// Coerces a dynamic JSON number/string to an int, or null.
int? _toIntOrNull(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
