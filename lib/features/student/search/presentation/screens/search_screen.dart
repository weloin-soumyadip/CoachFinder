/// Student search screen - search bar, type tabs, browse/recent, and results.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_effects.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../saved/data/models/bookmark_model.dart';
import '../../../saved/presentation/widgets/bookmark_toggle_button.dart';
import '../../data/controllers/search_provider.dart';
import '../../data/mock_search_data.dart';
import '../widgets/center_search_card.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/teacher_search_card.dart';
import '../widgets/webinar_search_card.dart';

/// Student search screen, wired to `GET /api/search`.
///
/// A debounced search field drives `searchControllerProvider`; a segmented
/// control selects the `SearchMode` (All / Teachers / Centers / Webinars). With
/// no active search it shows a resting state (browse categories + recent
/// searches). Results flow into a responsive grid (1 column on phones, up to 3
/// on wide layouts) and paginate via infinite scroll. The Filters entry point
/// pushes the full-screen filter editor.
class SearchScreen extends HookConsumerWidget {
  /// Creates the student search screen.
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final debounce = useRef<Timer?>(null);
    useEffect(() => () => debounce.value?.cancel(), const <Object?>[]);

    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    // Resting (browse) state is shown until a search has run. The clear button
    // and an emptied field both reset back to it.
    final bool showResting = state.status == SearchStatus.idle;

    void runQuery(String value) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) {
        notifier.reset();
      } else {
        notifier.setQuery(trimmed);
      }
    }

    void onChanged(String value) {
      debounce.value?.cancel();
      debounce.value = Timer(AppEffects.searchDebounce, () => runQuery(value));
    }

    void selectTerm(String term) {
      debounce.value?.cancel();
      controller.text = term;
      controller.selection = TextSelection.collapsed(offset: term.length);
      notifier.setQuery(term);
    }

    void clear() {
      debounce.value?.cancel();
      controller.clear();
      notifier.reset();
    }

    return Scaffold(
      body: DecoratedBox(
        // Subtle brand-tint wash at the top that fades into the flat background,
        // matching the Home tab's backdrop.
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
            builder: (context, constraints) {
              // Responsive grid sizing, measured on the content area so it is
              // correct inside the desktop NavigationRail too. Content is capped
              // and centred so cards don't stretch on very wide windows.
              final cappedWidth =
                  constraints.maxWidth > 1100 ? 1100.0 : constraints.maxWidth;
              final contentWidth = cappedWidth - AppSpacing.sp16 * 2;
              final rawColumns = (contentWidth / 320).floor();
              final columns =
                  rawColumns < 1 ? 1 : (rawColumns > 3 ? 3 : rawColumns);
              const gap = AppSpacing.sp16;
              final cardWidth = (contentWidth - gap * (columns - 1)) / columns;

              return NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Infinite scroll: fetch the next page as the user nears the
                  // bottom, when the active mode still has more and nothing is
                  // already loading.
                  if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 320 &&
                      state.hasMore &&
                      !state.isLoading &&
                      !state.isLoadingMore) {
                    notifier.loadMore();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      EdgeInsets.only(bottom: floatingNavClearance(context)),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp16,
                          vertical: AppSpacing.sp16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            SearchFieldWidget(
                              controller: controller,
                              onChanged: onChanged,
                              onClear: clear,
                            ),
                            const SizedBox(height: AppSpacing.sp16),
                            _SegmentControl(
                              selected: state.mode,
                              onChanged: notifier.setMode,
                            ),
                            const SizedBox(height: AppSpacing.sp24),
                            if (showResting)
                              _RestingState(onTermSelected: selectTerm)
                            else
                              _ResultsBody(
                                state: state,
                                cardWidth: cardWidth,
                                gap: gap,
                                onRetry: notifier.search,
                                onClearFilters: notifier.clearFilters,
                                onFilters: () =>
                                    context.pushNamed(AppRoutes.studentFilter),
                              ),
                          ],
                        ),
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

/// All / Teachers / Centers / Webinars control. Scrolls horizontally so the
/// four labels never overflow on a narrow phone.
class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.selected, required this.onChanged});

  final SearchMode selected;
  final ValueChanged<SearchMode> onChanged;

  static const List<(SearchMode, String)> _tabs = <(SearchMode, String)>[
    (SearchMode.all, AppStrings.searchSegmentAll),
    (SearchMode.teacher, AppStrings.searchSegmentTeachers),
    (SearchMode.coaching, AppStrings.searchSegmentCenters),
    (SearchMode.webinar, AppStrings.searchSegmentWebinars),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _tabs.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.sp8),
            _SegmentPill(
              label: _tabs[i].$2,
              selected: selected == _tabs[i].$1,
              onTap: () => onChanged(_tabs[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

/// One pill in [_SegmentControl]. Filled blue when selected, frosted when not.
class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
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

/// Resting (pre-search) state: browse-by-category chips + recent searches.
class _RestingState extends StatelessWidget {
  const _RestingState({required this.onTermSelected});

  final ValueChanged<String> onTermSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionHeader(title: AppStrings.searchBrowseByCategory),
        const SizedBox(height: AppSpacing.sp12),
        Wrap(
          spacing: AppSpacing.sp8,
          runSpacing: AppSpacing.sp8,
          children: <Widget>[
            for (final category in mockSearchCategories)
              _CategoryPill(
                label: category,
                onTap: () => onTermSelected(category),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp24),
        const _SectionHeader(title: AppStrings.searchRecentSearches),
        const SizedBox(height: AppSpacing.sp8),
        for (final term in mockRecentSearches)
          _RecentSearchTile(term: term, onTap: () => onTermSelected(term)),
      ],
    );
  }
}

/// Switches between the loading / error / empty / results views off [state].
class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.state,
    required this.cardWidth,
    required this.gap,
    required this.onRetry,
    required this.onClearFilters,
    required this.onFilters,
  });

  final SearchState state;
  final double cardWidth;
  final double gap;
  final VoidCallback onRetry;
  final VoidCallback onClearFilters;
  final VoidCallback onFilters;

  /// Loaded result count for the active mode.
  int get _count => switch (state.mode) {
        SearchMode.all =>
          state.teachers.length + state.centers.length + state.webinars.length,
        SearchMode.teacher => state.teachers.length,
        SearchMode.coaching => state.centers.length,
        SearchMode.webinar => state.webinars.length,
      };

  /// Plural noun for the "Found N …" header.
  String get _word => switch (state.mode) {
        SearchMode.all => AppStrings.searchResultsWord,
        SearchMode.teacher => AppStrings.searchTeachersWord,
        SearchMode.coaching => AppStrings.searchCentersWord,
        SearchMode.webinar => AppStrings.searchWebinarsWord,
      };

  @override
  Widget build(BuildContext context) {
    // Fresh load with no prior results — show a spinner.
    if (state.isLoading && _count == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sp48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // Error with nothing to show — inline retry.
    if (state.status == SearchStatus.error && _count == 0) {
      return _ErrorState(
        message: state.errorMessage ?? AppStrings.searchLoadError,
        onRetry: onRetry,
      );
    }
    final palette = context.palette;
    // Empty after a completed search; the header (with Clear) stays visible so
    // over-restrictive filters can always be cleared.
    final bool empty = state.hasData && _count == 0;
    final bool showClear = state.filters.hasActiveFilters;
    final cards = <Widget>[
      for (final teacher in state.teachers)
        if (state.mode == SearchMode.all || state.mode == SearchMode.teacher)
          TeacherSearchCard(
            teacher: teacher,
            onTap: () => context.pushNamed(
              AppRoutes.studentTeacherDetail,
              pathParameters: <String, String>{'id': teacher.id},
              extra: teacher.subjects,
            ),
            headerAction: BookmarkToggleButton(
              targetType: BookmarkTargetType.teacher,
              targetId: teacher.id,
            ),
          ),
      for (final center in state.centers)
        if (state.mode == SearchMode.all || state.mode == SearchMode.coaching)
          CenterSearchCard(
            center: center,
            onTap: () => context.pushNamed(
              AppRoutes.studentCenterDetail,
              pathParameters: <String, String>{'id': center.id},
            ),
            headerAction: BookmarkToggleButton(
              targetType: BookmarkTargetType.coachingCenter,
              targetId: center.id,
            ),
          ),
      for (final webinar in state.webinars)
        if (state.mode == SearchMode.all || state.mode == SearchMode.webinar)
          WebinarSearchCard(
            webinar: webinar,
            onJoin: () => _showComingSoon(context),
            headerAction: BookmarkToggleButton(
              targetType: BookmarkTargetType.webinar,
              targetId: webinar.id,
            ),
          ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${AppStrings.searchFoundPrefix} $_count $_word',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
              ),
            ),
            if (showClear) ...<Widget>[
              _HeaderAction(
                icon: Icons.close,
                label: AppStrings.searchClearFilters,
                color: palette.textSecondary,
                onTap: onClearFilters,
              ),
              const SizedBox(width: AppSpacing.sp4),
            ],
            _HeaderAction(
              icon: Icons.tune,
              label: AppStrings.searchFilters,
              color: palette.primary,
              onTap: onFilters,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp16),
        if (empty)
          const _EmptyResults()
        else
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final card in cards) SizedBox(width: cardWidth, child: card),
            ],
          ),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sp24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

/// A compact icon+label tap target used in the results header (Filters / Clear).
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sp8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sp4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bold section title used above the browse and recent lists.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.palette.textPrimary,
          ),
    );
  }
}

/// Outlined, pill-shaped category chip in the resting state.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp24,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sp24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp16,
              vertical: AppSpacing.sp8,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row in the recent-searches list. Tapping re-runs that search.
class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.term, required this.onTap});

  final String term;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sp8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
        child: Row(
          children: <Widget>[
            Icon(Icons.history, size: 20, color: palette.textMuted),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Text(
                term,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
            ),
            Icon(Icons.north_west, size: 18, color: palette.iconFaint),
          ],
        ),
      ),
    );
  }
}

/// Shown when a query yields no matches.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp48),
      child: Column(
        children: <Widget>[
          Icon(Icons.search_off, size: 48, color: palette.iconFaint),
          const SizedBox(height: AppSpacing.sp12),
          Text(
            AppStrings.searchNoResultsTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            AppStrings.searchNoResultsSubtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Shown when a search fails and there is nothing cached to display.
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
            child: const Text(AppStrings.searchRetry),
          ),
        ],
      ),
    );
  }
}

/// Stub for actions without a backend yet (e.g. joining a webinar).
void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(AppStrings.stubComingSoon)),
  );
}
