/// Connected save/unsave button — the single bookmark affordance shared by the
/// Search result cards and the Saved screen.
library;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../data/controllers/bookmarks_provider.dart';
import '../../data/models/bookmark_model.dart';

/// A small circular bookmark button bound to [bookmarksControllerProvider].
///
/// Shows a filled bookmark when ([targetType], [targetId]) is saved and an
/// outline when it isn't; tapping toggles it (optimistically, via the shared
/// controller) so every card showing the same target flips together. On a
/// failed mutation the controller's error message is surfaced as a snackbar.
class BookmarkToggleButton extends HookConsumerWidget {
  /// Creates a bookmark toggle for the given target.
  const BookmarkToggleButton({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  /// Which collection [targetId] belongs to.
  final BookmarkTargetType targetType;

  /// The bookmarked entity's id.
  final String targetId;

  String get _key => '${targetType.wireValue}:$targetId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool saved = ref.watch(
      bookmarksControllerProvider.select((s) => s.isSavedKey(_key)),
    );
    final palette = context.palette;

    Future<void> onTap() async {
      final notifier = ref.read(bookmarksControllerProvider.notifier);
      await notifier.toggle(targetType, targetId);
      final String? error = ref.read(bookmarksControllerProvider).errorMessage;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Tooltip(
      message:
          saved ? AppStrings.savedRemoveTooltip : AppStrings.savedSaveTooltip,
      child: Material(
        color: saved ? palette.primaryTint : palette.surface,
        shape: CircleBorder(
          side:
              saved ? BorderSide.none : BorderSide(color: palette.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sp8),
            child: Icon(
              saved ? Icons.bookmark : Icons.bookmark_border,
              size: 20,
              color: saved ? palette.primary : palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
