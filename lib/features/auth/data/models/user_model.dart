/// Authenticated user model — backend payload and Hive cache.
library;

/// The common fields the backend always returns on `auth/register` and
/// `auth/login`. Role-specific extras (teacher's `bio`, student's
/// `currentClass`, etc.) live in dedicated profile models loaded via
/// `/api/{role}/me` and are not part of the auth flow.
///
/// `id` corresponds to the backend's MongoDB `_id` string.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    required this.isEmailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.phone,
    this.profileImage = '',
  });

  /// Mongo ObjectId string — maps from backend `_id`.
  final String id;

  /// Display name (full name, single string).
  final String name;

  /// Lower-cased email address (the backend normalises before storing).
  final String email;

  /// Optional phone number; null when the user didn't provide one.
  final String? phone;

  /// Profile image URL. Empty string when not set.
  final String profileImage;

  /// Account active flag — set false by admin moderation.
  final bool isActive;

  /// Email verification flag — informational only at this phase.
  final bool isEmailVerified;

  /// Timestamp the user record was created on the backend.
  final DateTime createdAt;

  /// Timestamp the user record was last updated on the backend.
  final DateTime updatedAt;

  /// Parses the backend's `user` JSON envelope. Maps `_id` to [id], tolerates
  /// extra (role-specific) fields by ignoring them.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: (json['profileImage'] as String?) ?? '',
      isActive: json['isActive'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serialises to the shape stored in Hive (under `keyCurrentUser`). Uses
  /// `id` (not `_id`) because the value never round-trips to the backend —
  /// the server is the source of truth and re-sends `_id` on the next
  /// `/auth/me` call.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      'profileImage': profileImage,
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Parses a Hive-cached `User` JSON map (`id`, not `_id`).
  factory User.fromCache(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImage: (json['profileImage'] as String?) ?? '',
      isActive: json['isActive'] as bool,
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
