/// Filled bookmark button used to remove an item from the Saved list.
library;

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A small, tinted, circular button showing a filled bookmark. It signals that
/// an item is saved; tapping it ([onTap]) removes the item. Used in the footer
/// of the result cards on the Saved screen.
class SavedBookmarkButton extends StatelessWidget {
  const SavedBookmarkButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: AppStrings.savedRemoveTooltip,
      child: Material(
        color: context.palette.primaryTint,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sp8),
            child: Icon(
              Icons.bookmark,
              size: 20,
              color: context.palette.primary,
            ),
          ),
        ),
      ),
    );
  }
}
