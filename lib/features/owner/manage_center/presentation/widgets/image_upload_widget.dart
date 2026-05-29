/// Center photo gallery: coloured placeholder tiles with optional add/remove.
///
/// Doubles as a read-only gallery (omit [onAdd]/[onRemove]) and an editable
/// grid. Real image picking needs a picker package that isn't in the stack, so
/// [onAdd] is expected to surface a "coming soon" message for now.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/mock_center_data.dart';

/// A wrap of photo tiles. When [onRemove] is supplied each tile shows a remove
/// button; when [onAdd] is supplied a trailing "Add Photo" tile is shown.
class ImageUploadWidget extends StatelessWidget {
  const ImageUploadWidget({
    super.key,
    required this.photos,
    this.onAdd,
    this.onRemove,
  });

  final List<CenterPhoto> photos;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sp12,
      runSpacing: AppSpacing.sp12,
      children: <Widget>[
        for (final CenterPhoto photo in photos)
          _PhotoTile(
            photo: photo,
            onRemove: onRemove == null ? null : () => onRemove!(photo.id),
          ),
        if (onAdd != null) _AddTile(onTap: onAdd!),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.photo, this.onRemove});

  final CenterPhoto photo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 88,
      child: Stack(
        children: <Widget>[
          Container(
            width: 104,
            height: 88,
            decoration: BoxDecoration(
              color: photo.color,
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.image_outlined,
                  color: AppColors.neutralWhite,
                  size: 22,
                ),
                const SizedBox(height: AppSpacing.sp4),
                Text(
                  photo.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.neutralWhite,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.neutralBlack,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.neutralWhite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sp12),
      child: Container(
        width: 104,
        height: 88,
        decoration: BoxDecoration(
          color: palette.inputFill,
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_a_photo_outlined,
                color: palette.textMuted, size: 20),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              AppStrings.centerPhotoAdd,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
