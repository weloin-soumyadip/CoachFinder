/// Student Saved screen - the student's bookmarks (tutors, coachings, webinars)
/// from `GET /api/students/bookmarks`, with live search, a type filter, and an
/// unsave (bookmark) toggle on every card.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../search/data/models/search_result_model.dart';
import '../../../search/presentation/widgets/center_search_card.dart';
import '../../../search/presentation/widgets/search_field_widget.dart';
import '../../../search/presentation/widgets/teacher_search_card.dart';
import '../../../search/presentation/widgets/webinar_search_card.dart';
import '../../data/controllers/bookmarks_provider.dart';
import '../../data/models/bookmark_model.dart';
import '../widgets/bookmark_toggle_button.dart';

/// Which kind of saved item the filter is narrowing to.
enum SavedFilter {
  /// Everything the student saved.
  all,

  /// Saved teachers / tutors.
  tutors,

  /// Saved coaching centers.
  coachings,

  /// Saved webinars.
  webinars;

  /// The target type this filter maps to, or null for [SavedFilter.all].
  BookmarkTargetType? get targetType {
    switch (this) {
      case SavedFilter.all:
        return null;
      case SavedFilter.tutors:
        return BookmarkTargetType.teacher;
      case SavedFilter.coachings:
        return BookmarkTargetType.coachingCenter;
      case SavedFilter.webinars:
        return BookmarkTargetType.webinar;
    }
  }

  /// The pill label.
  String get label {
    switch (this) {
      case SavedFilter.all:
        return AppStrings.savedFilterAll;
      case SavedFilter.tutors:
        return AppStrings.savedFilterTutors;
      case SavedFilter.coachings:
        return AppStrings.savedFilterCoachings;
      case SavedFilter.webinars:
        return AppStrings.savedFilterWebinars;
    }
  }
}

/// Student Saved screen, wired to the bookmarks backend.
///
/// Watches [bookmarksControllerProvider] (the full saved set, loaded once and
/// kept in sync with the Search-card toggle). A search field filters the loaded
/// items live, and an All / Tutors / Coachings / Webinars control narrows by
/// type. Each bookmark renders through the matching Search result card with a
/// filled bookmark toggle that removes it. Loading shows a spinner; a failed
/// load shows an inline retry; an empty set (or no match) shows an empty state.
class SavedScreen extends HookConsumerWidget {
  /// Creates the student Saved screen.
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState<String>('');
    final filter = useState<SavedFilter>(SavedFilter.all);

    final state = ref.watch(bookmarksControllerProvider);
    final notifier = ref.read(bookmarksControllerProvider.notifier);

    // Refetch the saved set every time the screen is entered. The controller
    // only fetches once on first creation (which may have happened earlier via
    // a Search bookmark button, or failed), so without this the list could be
    // stale or never load when the Saved tab is opened. The controller guards
    // against an overlapping fetch, so this is safe alongside that first load.
    useEffect(() {
      notifier.load();
      return null;
    }, const <Object?>[]);

    void clear() {
      controller.clear();
      query.value = '';
    }

    final String q = query.value.trim().toLowerCase();
    final BookmarkTargetType? typeFilter = filter.value.targetType;

    bool matches(Bookmark b) {
      if (typeFilter != null && b.targetType != typeFilter) return false;
      if (q.isEmpty) return true;
      final String name = (b.target['name'] ?? b.target['title'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(q);
    }

    final List<Bookmark> visible = state.bookmarks.where(matches).toList();

    return Scaffold(
      body: DecoratedBox(
        // Subtle brand-tint wash at the top, matching the Home and Search tabs.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              context.palette.primaryTint,
              context.palette.background,
            ],
            stops: const <double>[0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Responsive grid sizing, capped + centred so cards don't stretch
              // on very wide windows / inside the desktop NavigationRail.
              final cappedWidth =
                  constraints.maxWidth > 1100 ? 1100.0 : constraints.maxWidth;
              final contentWidth = cappedWidth - AppSpacing.sp16 * 2;
              final rawColumns = (contentWidth / 320).floor();
              final columns =
                  rawColumns < 1 ? 1 : (rawColumns > 3 ? 3 : rawColumns);
              const gap = AppSpacing.sp16;
              final cardWidth = (contentWidth - gap * (columns - 1)) / columns;

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: floatingNavClearance(context)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.sp8),
                          Text(
                            AppStrings.savedTitle,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: context.palette.textPrimary,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sp16),
                          SearchFieldWidget(
                            controller: controller,
                            hintText: AppStrings.savedSearchHint,
                            onChanged: (String v) => query.value = v,
                            onClear: clear,
                          ),
                          const SizedBox(height: AppSpacing.sp16),
                          _FilterControl(
                            selected: filter.value,
                            onChanged: (SavedFilter f) => filter.value = f,
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          _Body(
                            state: state,
                            visible: visible,
                            cardWidth: cardWidth,
                            gap: gap,
                            onRetry: notifier.load,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Switches between loading / error / empty / list off the [BookmarkState].
class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.visible,
    required this.cardWidth,
    required this.gap,
    required this.onRetry,
  });

  final BookmarkState state;
  final List<Bookmark> visible;
  final double cardWidth;
  final double gap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // First load with nothing cached.
    if (state.isLoading && state.bookmarks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.sp12),
              // TEMP DIAGNOSTIC: surface the live state so a screenshot of the
              // stuck spinner tells us exactly why it is showing.
              Text(
                'DEBUG status=${state.status} '
                'items=${state.bookmarks.length} '
                'visible=${visible.length} err=${state.errorMessage}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }
    // Load failed and there's nothing to show.
    if (state.status == BookmarkStatus.error && state.bookmarks.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? AppStrings.savedLoadError,
        onRetry: onRetry,
      );
    }
    if (visible.isEmpty) return const _SavedEmpty();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${visible.length} ${AppStrings.savedCountWord}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.palette.textMuted,
              ),
        ),
        const SizedBox(height: AppSpacing.sp12),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final Bookmark b in visible)
              SizedBox(width: cardWidth, child: _SavedCard(bookmark: b)),
          ],
        ),
      ],
    );
  }
}

/// Renders one bookmark through the matching Search result card, with a filled
/// bookmark toggle (tapping it removes the bookmark via the shared controller).
class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.bookmark});

  final Bookmark bookmark;

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.stubComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final action = BookmarkToggleButton(
      targetType: bookmark.targetType,
      targetId: bookmark.targetId,
    );
    switch (bookmark.targetType) {
      case BookmarkTargetType.teacher:
        final TeacherSearchResult teacher =
            TeacherSearchResult.fromJson(bookmark.target);
        return TeacherSearchCard(
          teacher: teacher,
          onTap: () => context.pushNamed(
            AppRoutes.studentTeacherDetail,
            pathParameters: <String, String>{'id': teacher.id},
            extra: teacher.subjects,
          ),
          headerAction: action,
        );
      case BookmarkTargetType.coachingCenter:
        return CenterSearchCard(
          center: CenterSearchResult.fromJson(bookmark.target),
          onTap: () => context.pushNamed(
            AppRoutes.studentCenterDetail,
            pathParameters: <String, String>{'id': bookmark.targetId},
          ),
          headerAction: action,
        );
      case BookmarkTargetType.webinar:
        return WebinarSearchCard(
          webinar: WebinarSearchResult.fromJson(bookmark.target),
          onJoin: () => _showComingSoon(context),
          headerAction: action,
        );
    }
  }
}

/// All / Tutors / Coachings / Webinars control. Scrolls horizontally so the
/// four labels never overflow on a narrow phone.
class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.selected, required this.onChanged});

  final SavedFilter selected;
  final ValueChanged<SavedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < SavedFilter.values.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.sp8),
            _FilterPill(
              label: SavedFilter.values[i].label,
              selected: selected == SavedFilter.values[i],
              onTap: () => onChanged(SavedFilter.values[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// One pill in [_FilterControl]. Filled blue when selected, frosted when not.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Widget inner = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sp12,
            horizontal: AppSpacing.sp24,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      selected ? AppColors.neutralWhite : palette.textSecondary,
                ),
          ),
        ),
      ),
    );
    if (selected) {
      return Material(
        color: AppColors.studentPrimary,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: inner,
      );
    }
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp12,
      child: inner,
    );
  }
}

/// Shown when nothing is saved (or a search/filter matches nothing).
class _SavedEmpty extends StatelessWidget {
  const _SavedEmpty();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
      child: Column(
        children: <Widget>[
          Icon(Icons.bookmark_border, size: 48, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            AppStrings.savedEmptyTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            AppStrings.savedEmptySubtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Shown when the bookmark load fails and nothing is cached.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_off, size: 48, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: AppSpacing.sp16),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppStrings.savedRetry),
          ),
        ],
      ),
    );
  }
}
