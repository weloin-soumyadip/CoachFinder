/// Student profile model + wire enums for the profile read/edit feature,
/// backing `GET /api/auth/me` (prefill/read) and `PATCH /api/students/me`
/// (update — the response echoes the same full doc). The model is null-tolerant
/// across every optional field, mirroring the defensive parsing in
/// `bookmark_model.dart` and `search_result_model.dart`.
library;

/// The student's gender. [wireValue] is the exact string the backend's enum
/// uses (`male`/`female`/`other`/`prefer_not_to_say`); [fromWire] parses it back
/// (null-tolerant — unknown/absent → null).
enum StudentGender {
  /// `'male'`.
  male,

  /// `'female'`.
  female,

  /// `'other'`.
  other,

  /// `'prefer_not_to_say'`.
  preferNotToSay;

  /// The exact backend enum string for this value.
  String get wireValue {
    switch (this) {
      case StudentGender.male:
        return 'male';
      case StudentGender.female:
        return 'female';
      case StudentGender.other:
        return 'other';
      case StudentGender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }

  /// Human-readable label for selectors / display.
  String get label {
    switch (this) {
      case StudentGender.male:
        return 'Male';
      case StudentGender.female:
        return 'Female';
      case StudentGender.other:
        return 'Other';
      case StudentGender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  /// Parses a backend `gender` string. Null-tolerant: null / empty / unknown
  /// values return null so a stray payload never throws.
  static StudentGender? fromWire(String? wire) {
    switch (wire) {
      case 'male':
        return StudentGender.male;
      case 'female':
        return StudentGender.female;
      case 'other':
        return StudentGender.other;
      case 'prefer_not_to_say':
        return StudentGender.preferNotToSay;
      default:
        return null;
    }
  }
}

/// The student's education board. [wireValue] is the exact backend enum string
/// (`CBSE`/`ICSE`/`State`/`IB`/`IGCSE`/`Other`); [fromWire] parses it back
/// (null-tolerant).
enum StudentBoard {
  /// `'CBSE'`.
  cbse,

  /// `'ICSE'`.
  icse,

  /// `'State'`.
  state,

  /// `'IB'`.
  ib,

  /// `'IGCSE'`.
  igcse,

  /// `'Other'`.
  other;

  /// The exact backend enum string for this value.
  String get wireValue {
    switch (this) {
      case StudentBoard.cbse:
        return 'CBSE';
      case StudentBoard.icse:
        return 'ICSE';
      case StudentBoard.state:
        return 'State';
      case StudentBoard.ib:
        return 'IB';
      case StudentBoard.igcse:
        return 'IGCSE';
      case StudentBoard.other:
        return 'Other';
    }
  }

  /// Human-readable label (identical to [wireValue] for boards, but kept as a
  /// distinct getter so the UI never quotes the wire string directly).
  String get label => wireValue;

  /// Parses a backend `board` string. Null-tolerant: null / empty / unknown
  /// values return null.
  static StudentBoard? fromWire(String? wire) {
    switch (wire) {
      case 'CBSE':
        return StudentBoard.cbse;
      case 'ICSE':
        return StudentBoard.icse;
      case 'State':
        return StudentBoard.state;
      case 'IB':
        return StudentBoard.ib;
      case 'IGCSE':
        return StudentBoard.igcse;
      case 'Other':
        return StudentBoard.other;
      default:
        return null;
    }
  }
}

/// A student's full profile, as returned by `GET /api/auth/me` (under `user`)
/// and `PATCH /api/students/me` (under the top-level `user`). Immutable; every
/// optional field defaults defensively so a partial / stray payload parses.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage = '',
    this.dateOfBirth,
    this.gender,
    this.currentClass,
    this.board,
    this.city,
    this.isActive = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// The student's `_id`.
  final String id;

  /// Display name.
  final String name;

  /// Login email (read-only on the edit screen — the PATCH body never sends it).
  final String email;

  /// Contact phone, or null when unset.
  final String? phone;

  /// Avatar URL; empty string when unset (the backend default).
  final String profileImage;

  /// Date of birth, or null when unset / unparseable.
  final DateTime? dateOfBirth;

  /// Gender, or null when unset / unknown.
  final StudentGender? gender;

  /// Current class (1–12), or null when unset / unparseable.
  final int? currentClass;

  /// Education board, or null when unset / unknown.
  final StudentBoard? board;

  /// City, or null when unset.
  final String? city;

  /// Whether the account is active.
  final bool isActive;

  /// Whether the email has been verified.
  final bool isEmailVerified;

  /// Account creation timestamp, or null when absent / unparseable.
  final DateTime? createdAt;

  /// Last-update timestamp, or null when absent / unparseable.
  final DateTime? updatedAt;

  /// Parses a sanitized student doc. Maps `_id` → [id], tolerates missing /
  /// malformed optional fields (date strings that don't parse → null, unknown
  /// enums → null, non-int `currentClass` → null).
  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: _nullableString(json['phone']),
      profileImage: (json['profileImage'] ?? '').toString(),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      gender: StudentGender.fromWire(_nullableString(json['gender'])),
      currentClass: _parseInt(json['currentClass']),
      board: StudentBoard.fromWire(_nullableString(json['board'])),
      city: _nullableString(json['city']),
      isActive: json['isActive'] == true,
      isEmailVerified: json['isEmailVerified'] == true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// Field-wise copy used by the controller to fold a PATCH response (or local
  /// edits) into the held profile.
  StudentProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    DateTime? dateOfBirth,
    StudentGender? gender,
    int? currentClass,
    StudentBoard? board,
    String? city,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      currentClass: currentClass ?? this.currentClass,
      board: board ?? this.board,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the trimmed string, or null when null / blank.
  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final String s = value.toString();
    return s.isEmpty ? null : s;
  }

  /// Parses a value into an int, or null when absent / non-numeric.
  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parses an ISO date string, or null when absent / unparseable.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
