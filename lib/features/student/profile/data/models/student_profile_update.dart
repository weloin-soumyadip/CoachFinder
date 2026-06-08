/// Partial update payload for `PATCH /api/students/me`. The backend accepts a
/// STRICT partial — only keys present in the body are written — so [toJson]
/// emits ONLY the non-null fields, keeping the request a true partial.
library;

import 'student_profile_model.dart';

/// The editable subset of a student profile. Every field is nullable; a null
/// field is omitted from [toJson] (it is NOT cleared server-side). The
/// presentation layer constructs one of these from its form, passing only the
/// fields the user actually changed.
class StudentProfileUpdate {
  const StudentProfileUpdate({
    this.name,
    this.phone,
    this.profileImage,
    this.dateOfBirth,
    this.gender,
    this.currentClass,
    this.board,
    this.city,
  });

  /// New display name, or null to leave unchanged.
  final String? name;

  /// New phone, or null to leave unchanged.
  final String? phone;

  /// New avatar URL, or null to leave unchanged.
  final String? profileImage;

  /// New date of birth (serialised to ISO-8601), or null to leave unchanged.
  final DateTime? dateOfBirth;

  /// New gender, or null to leave unchanged.
  final StudentGender? gender;

  /// New current class (1–12), or null to leave unchanged.
  final int? currentClass;

  /// New education board, or null to leave unchanged.
  final StudentBoard? board;

  /// New city, or null to leave unchanged.
  final String? city;

  /// True when no field is set — the caller should skip the PATCH entirely
  /// (an empty body is rejected by the backend with `400 no fields to update`).
  bool get isEmpty =>
      name == null &&
      phone == null &&
      profileImage == null &&
      dateOfBirth == null &&
      gender == null &&
      currentClass == null &&
      board == null &&
      city == null;

  /// Serialises ONLY the non-null fields. Dates → ISO-8601 strings, enums →
  /// their `wireValue`. The result is the exact PATCH body.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
      // Date-only field: emit a bare `YYYY-MM-DD` (no time / timezone) so a
      // local-midnight pick can't shift a day across the UTC boundary on the
      // round-trip. The backend's `z.coerce.date()` accepts this form.
      if (dateOfBirth != null) 'dateOfBirth': _dateOnly(dateOfBirth!),
      if (gender != null) 'gender': gender!.wireValue,
      if (currentClass != null) 'currentClass': currentClass,
      if (board != null) 'board': board!.wireValue,
      if (city != null) 'city': city,
    };
  }
}

/// Formats [d] as a zero-padded `YYYY-MM-DD` string using its LOCAL calendar
/// components (date-only; time and timezone are intentionally dropped).
String _dateOnly(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
