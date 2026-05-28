/// Helpers mapping a user role to the auth screens' brand accent.
library;

import 'package:flutter/material.dart';

import '../../../core/providers/role_provider.dart';
import '../../../core/theme/app_colors.dart';

/// Returns the primary brand accent for the active [role]. Used to colour the
/// auth screens' CTA, focused input ring, footer link, and remember toggle so
/// the form visibly belongs to the role the user picked on onboarding.
///
/// Falls back to [AppColors.studentPrimary] when [role] is null or unknown.
Color authAccent(String? role) {
  switch (role) {
    case roleOwner:
      return AppColors.ownerAccent;
    case roleTeacher:
      return AppColors.teacherAccent;
    case roleStudent:
    default:
      return AppColors.studentPrimary;
  }
}

/// Returns the two-orb gradient pair for the auth backdrop, themed to [role]:
/// the role's accent paired with a darker shade for depth.
///
/// Student uses the predefined [AppColors.studentPrimaryDark]; owner and
/// teacher compute their darker shade via HSL so we don't have to maintain
/// extra fixed tokens.
List<Color> authBackdropOrbs(String? role) {
  switch (role) {
    case roleOwner:
      return <Color>[AppColors.ownerAccent, _darken(AppColors.ownerAccent)];
    case roleTeacher:
      return <Color>[
        AppColors.teacherAccent,
        _darken(AppColors.teacherAccent),
      ];
    case roleStudent:
    default:
      return const <Color>[
        AppColors.studentPrimary,
        AppColors.studentPrimaryDark,
      ];
  }
}

Color _darken(Color seed) {
  final HSLColor hsl = HSLColor.fromColor(seed);
  return hsl.withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0)).toColor();
}
