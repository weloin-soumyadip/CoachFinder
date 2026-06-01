/// Rounded network image with a graceful initial-letter fallback, shared by the
/// student home dashboard cards (teacher avatar, center thumbnail, webinar host).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Renders [imageUrl] as a rounded image of [size]×[size]. When the URL is
/// empty, still loading, or fails to load, falls back to a soft [accent]-tinted
/// tile showing the first letter of [fallbackLabel].
///
/// No caching package is in the stack, so this leans on [Image.network]'s own
/// frame/error builders rather than `cached_network_image`.
class AvatarImageWidget extends StatelessWidget {
  const AvatarImageWidget({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    this.accent = AppColors.studentPrimary,
    this.size = 56,
    this.radius = AppSpacing.sp12,
  });

  /// Remote image URL; empty string renders the fallback tile directly.
  final String imageUrl;

  /// Source of the fallback initial (first character, upper-cased).
  final String fallbackLabel;

  /// Tint for the fallback tile fill + initial.
  final Color accent;

  /// Square edge length in logical pixels.
  final double size;

  /// Corner radius of the tile.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = _Fallback(
      label: fallbackLabel,
      accent: accent,
      size: size,
      radius: radius,
    );
    if (imageUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Show the tinted fallback while the image streams in, then the image.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, _, __) => fallback,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.label,
    required this.accent,
    required this.size,
    required this.radius,
  });

  final String label;
  final Color accent;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final String initial =
        label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.palette.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
