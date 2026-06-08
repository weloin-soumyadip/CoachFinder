/// Partial update payload for `PATCH /api/owners/me`. The backend accepts a
/// STRICT partial — only `{name?, phone?, profileImage?}` — so [toJson] emits
/// ONLY the non-null fields, keeping the request a true partial.
library;

/// The editable subset of an owner profile. Every field is nullable; a null
/// field is omitted from [toJson]. The edit form constructs one of these with
/// only the fields the user changed.
class OwnerProfileUpdate {
  /// Creates an owner profile update.
  const OwnerProfileUpdate({
    this.name,
    this.phone,
    this.profileImage,
  });

  /// New display name, or null to leave unchanged.
  final String? name;

  /// New phone, or null to leave unchanged.
  final String? phone;

  /// New avatar URL, or null to leave unchanged.
  final String? profileImage;

  /// True when no field is set — the caller should skip the PATCH entirely
  /// (an empty body is rejected by the backend).
  bool get isEmpty => name == null && phone == null && profileImage == null;

  /// Serialises ONLY the non-null fields — the exact PATCH body.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}
