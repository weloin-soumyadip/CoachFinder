/// Strict-partial update payload for `PATCH /api/centers/:id`. The backend
/// schema is `.partial().strict()`, so [toJson] emits ONLY the keys that were
/// actually changed (each field null = "leave unchanged"). The edit form builds
/// one of these by diffing the draft against the loaded [OwnerCenter].
library;

import 'owner_center.dart';

/// The editable subset of a centre. Every field is nullable; a null field is
/// omitted from [toJson]. List/object fields carry the whole new value when
/// changed.
class CenterUpdate {
  /// Creates a partial update.
  const CenterUpdate({
    this.name,
    this.description,
    this.address,
    this.area,
    this.city,
    this.state,
    this.pincode,
    this.phone,
    this.alternatePhone,
    this.email,
    this.website,
    this.boards,
    this.subjectIds,
    this.classRange,
    this.fees,
    this.timings,
  });

  /// New name, or null.
  final String? name;

  /// New description, or null.
  final String? description;

  /// New address, or null.
  final String? address;

  /// New area, or null.
  final String? area;

  /// New city, or null.
  final String? city;

  /// New state, or null.
  final String? state;

  /// New pincode, or null.
  final String? pincode;

  /// New phone, or null.
  final String? phone;

  /// New alternate phone, or null.
  final String? alternatePhone;

  /// New email, or null.
  final String? email;

  /// New website, or null.
  final String? website;

  /// New board list, or null.
  final List<String>? boards;

  /// New subject id list (→ `subjectsOffered`), or null.
  final List<String>? subjectIds;

  /// New class range, or null.
  final CenterClassRange? classRange;

  /// New fee range, or null.
  final CenterFees? fees;

  /// New timings, or null.
  final List<CenterTiming>? timings;

  /// True when nothing changed — the caller should skip the PATCH (an empty
  /// body is rejected by the backend with `400 no fields to update`).
  bool get isEmpty =>
      name == null &&
      description == null &&
      address == null &&
      area == null &&
      city == null &&
      state == null &&
      pincode == null &&
      phone == null &&
      alternatePhone == null &&
      email == null &&
      website == null &&
      boards == null &&
      subjectIds == null &&
      classRange == null &&
      fees == null &&
      timings == null;

  /// Serialises ONLY the non-null (changed) fields — the exact PATCH body.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (area != null) 'area': area,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (phone != null) 'phone': phone,
      if (alternatePhone != null) 'alternatePhone': alternatePhone,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (boards != null) 'boards': boards,
      if (subjectIds != null) 'subjectsOffered': subjectIds,
      if (classRange != null) 'classRange': classRange!.toJson(),
      if (fees != null) 'fees': fees!.toJson(),
      if (timings != null)
        'timings': timings!.map((CenterTiming t) => t.toJson()).toList(),
    };
  }
}
