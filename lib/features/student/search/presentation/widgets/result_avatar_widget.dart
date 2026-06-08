/// Rounded network image with an initial-letter fallback, shared by the three
/// search result cards (teacher avatar, center logo, webinar thumbnail/host).
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// Renders [imageUrl] as a [size]×[size] tile (a circle when [circle] is true,
/// otherwise a rounded square). When the URL is empty, still loading, or fails
/// to load, falls back to a soft student-tinted tile showing the first letter
/// of [fallbackLabel].
///
/// No image-cache package is in the stack, so this leans on [Image.network]'s
/// own frame / error builders rather than `cached_network_image`.
class ResultAvatarWidget extends StatelessWidget {
  /// Creates a result avatar / logo / thumbnail tile.
  const ResultAvatarWidget({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    this.size = 52,
    this.circle = false,
  });

  /// Remote image URL; an empty string renders the fallback tile directly.
  final String imageUrl;

  /// Source of the fallback initial (first character, upper-cased).
  final String fallbackLabel;

  /// Square edge length in logical pixels.
  final double size;

  /// Whether to clip to a circle (teacher avatar) vs a rounded square (logo).
  final bool circle;

  double get _radius => circle ? size / 2 : AppSpacing.sp12;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = _Fallback(
      label: fallbackLabel,
      size: size,
      radius: _radius,
    );
    if (imageUrl.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (context, _, __) => fallback,
      ),
    );
  }
}

/// Soft student-tinted tile showing the first letter of [label].
class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.label,
    required this.size,
    required this.radius,
  });

  final String label;
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
        color: AppColors.studentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: context.palette.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
