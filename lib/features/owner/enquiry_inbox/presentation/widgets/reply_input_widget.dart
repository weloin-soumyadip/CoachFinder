/// Multi-line reply input pinned at the bottom of the enquiry detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';

/// A growing text field plus a circular send button. Owns its own controller;
/// on send it forwards the trimmed text via [onSend] and clears itself. The
/// send button is disabled while the field is empty.
class ReplyInputWidget extends HookWidget {
  const ReplyInputWidget({super.key, required this.onSend});

  /// Called with the trimmed reply text when the user taps send.
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = useTextEditingController();
    // Rebuild as the text changes so the send button enables/disables.
    useListenable(controller);
    final bool canSend = controller.text.trim().isNotEmpty;
    final palette = context.palette;

    void handleSend() {
      final String text = controller.text.trim();
      if (text.isEmpty) return;
      onSend(text);
      controller.clear();
    }

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sp12,
        AppSpacing.sp8,
        AppSpacing.sp12,
        AppSpacing.sp12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: AppStrings.enquiryReplyHint,
                hintStyle: TextStyle(color: palette.textMuted),
                filled: true,
                fillColor: palette.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sp16,
                  vertical: AppSpacing.sp12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sp24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sp8),
          Material(
            color: canSend
                ? AppColors.ownerAccent
                : AppColors.ownerAccent.withValues(alpha: 0.35),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canSend ? handleSend : null,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.send_rounded,
                  color: AppColors.neutralWhite,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
