/// Owner profile model, parsed from `GET /api/auth/me` (the sanitized Owner
/// doc). The Owner model is minimal — just the common user fields; there are no
/// owner-specific profile fields (business name lives on the centre).
library;

/// The authenticated owner's profile.
class OwnerProfile {
  /// Creates an owner profile.
  const OwnerProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage = '',
    this.isActive = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// The owner's `_id`.
  final String id;

  /// Display name.
  final String name;

  /// Login email (read-only on the edit screen — the PATCH body never sends it).
  final String email;

  /// Contact phone, or null when unset.
  final String? phone;

  /// Avatar URL; empty string when unset (the backend default).
  final String profileImage;

  /// Whether the account is active.
  final bool isActive;

  /// Whether the email has been verified.
  final bool isEmailVerified;

  /// Account creation timestamp, or null when absent / unparseable.
  final DateTime? createdAt;

  /// Last-update timestamp, or null when absent / unparseable.
  final DateTime? updatedAt;

  /// First name (first whitespace-delimited token), or '' when empty.
  String get firstName {
    final String n = name.trim();
    if (n.isEmpty) return '';
    return n.split(RegExp(r'\s+')).first;
  }

  /// First letter of the name (avatar initial), or '?' when empty.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Parses a sanitized owner doc. Maps `_id` → [id], tolerates missing fields.
  factory OwnerProfile.fromJson(Map<String, dynamic> json) {
    return OwnerProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: _nullableString(json['phone']),
      profileImage: (json['profileImage'] ?? '').toString(),
      isActive: json['isActive'] == true,
      isEmailVerified: json['isEmailVerified'] == true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// Field-wise copy used by the controller to fold a PATCH response in.
  OwnerProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
    bool? isActive,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OwnerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
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

  /// Parses an ISO date string, or null when absent / unparseable.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
