/// Rounded search input used at the top of the student Search screen.
library;

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// A filled, rounded text field with a leading search icon and an optional
/// clear button. The caller owns the [controller] and reacts to [onChanged];
/// [onClear] is invoked when the trailing clear button is tapped. [hintText]
/// overrides the default placeholder so the same field can be reused across
/// screens (Search, Saved).
class SearchFieldWidget extends StatelessWidget {
  const SearchFieldWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.hintText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    final palette = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText ?? AppStrings.searchHint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
        prefixIcon: Icon(
          Icons.search,
          color: palette.textMuted,
        ),
        suffixIcon: hasText
            ? IconButton(
                icon: Icon(
                  Icons.close,
                  color: palette.textMuted,
                  size: 20,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sp16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          borderSide: BorderSide(
            color: palette.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
