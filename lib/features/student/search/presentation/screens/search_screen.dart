/// Student search screen - search bar, type tabs, browse/recent, and results.
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
import '../../data/mock_search_data.dart';
import '../widgets/institute_result_card.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/teacher_result_card.dart';

/// Student search screen.
///
/// Phase 1: all content is rendered from `mock_search_data.dart` and filtered
/// locally. A search bar drives a live, case-insensitive filter; a segmented
/// control narrows results to All / Teachers / Institutes. With no query on the
/// "All" tab it shows a resting state (browse categories + recent searches).
/// Result cards flow into a responsive grid (1 column on phones, up to 3 on
/// wide layouts). Result taps and the Filters entry point are placeholders.
class SearchScreen extends HookConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState<String>('');
    final segment = useState<SearchEntityType>(SearchEntityType.all);

    void setQuery(String value) {
      controller.text = value;
      controller.selection = TextSelection.collapsed(offset: value.length);
      query.value = value;
    }

    void clear() {
      controller.clear();
      query.value = '';
    }

    final q = query.value.trim().toLowerCase();
    final showResting = q.isEmpty && segment.value == SearchEntityType.all;

    bool teacherMatches(SearchTeacher t) =>
        q.isEmpty ||
        t.name.toLowerCase().contains(q) ||
        t.title.toLowerCase().contains(q) ||
        t.tags.any((tag) => tag.toLowerCase().contains(q));

    bool instituteMatches(SearchInstitute i) =>
        q.isEmpty ||
        i.name.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q) ||
        i.tags.any((tag) => tag.toLowerCase().contains(q));

    final teachers = segment.value == SearchEntityType.institutes
        ? const <SearchTeacher>[]
        : mockSearchTeachers.where(teacherMatches).toList();
    final institutes = segment.value == SearchEntityType.teachers
        ? const <SearchInstitute>[]
        : mockSearchInstitutes.where(instituteMatches).toList();
    final resultCount = teachers.length + institutes.length;

    return Scaffold(
      body: DecoratedBox(
        // Subtle vertical brand-tint wash at the top that fades into the flat
        // background within the first ~40% of the viewport, matching the Home
        // tab's backdrop.
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

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: floatingNavClearance(context)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sp16,
                              vertical: AppSpacing.sp16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SearchFieldWidget(
                                controller: controller,
                                onChanged: (v) => query.value = v,
                                onClear: clear,
                              ),
                              const SizedBox(height: AppSpacing.sp16),
                              _SegmentControl(
                                selected: segment.value,
                                onChanged: (s) => segment.value = s,
                              ),
                              const SizedBox(height: AppSpacing.sp24),
                              if (showResting)
                                _RestingState(onTermSelected: setQuery)
                              else
                                _Results(
                                  count: resultCount,
                                  segment: segment.value,
                                  teachers: teachers,
                                  institutes: institutes,
                                  cardWidth: cardWidth,
                                  gap: gap,
                                  onFilters: () =>
                                      context.goNamed(AppRoutes.studentFilter),
                                ),
                            ],
                          ),
                        ),
                      ],
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

/// All / Teachers / Institutes segmented control (three equal-width pills).
class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.selected, required this.onChanged});

  final SearchEntityType selected;
  final ValueChanged<SearchEntityType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SegmentPill(
            label: AppStrings.searchSegmentAll,
            selected: selected == SearchEntityType.all,
            onTap: () => onChanged(SearchEntityType.all),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _SegmentPill(
            label: AppStrings.searchSegmentTeachers,
            selected: selected == SearchEntityType.teachers,
            onTap: () => onChanged(SearchEntityType.teachers),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _SegmentPill(
            label: AppStrings.searchSegmentInstitutes,
            selected: selected == SearchEntityType.institutes,
            onTap: () => onChanged(SearchEntityType.institutes),
          ),
        ),
      ],
    );
  }
}

/// One pill in [_SegmentControl]. Filled blue when selected, outlined when not.
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
    // Shared tap target + label. The settled (selected) pill is a filled brand
    // fill so selection stays unmistakable; unselected pills are frosted glass.
    final Widget inner = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
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

/// Results state: a "Found N …" header with a Filters link, then the grid.
class _Results extends StatelessWidget {
  const _Results({
    required this.count,
    required this.segment,
    required this.teachers,
    required this.institutes,
    required this.cardWidth,
    required this.gap,
    required this.onFilters,
  });

  final int count;
  final SearchEntityType segment;
  final List<SearchTeacher> teachers;
  final List<SearchInstitute> institutes;
  final double cardWidth;
  final double gap;
  final VoidCallback onFilters;

  String get _word => switch (segment) {
        SearchEntityType.teachers => AppStrings.searchTeachersWord,
        SearchEntityType.institutes => AppStrings.searchInstitutesWord,
        SearchEntityType.all => AppStrings.searchResultsWord,
      };

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const _EmptyResults();

    final palette = context.palette;
    final cards = <Widget>[
      for (final teacher in teachers)
        TeacherResultCard(teacher: teacher, onTap: () {}),
      for (final institute in institutes)
        InstituteResultCard(institute: institute, onTap: () {}),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '${AppStrings.searchFoundPrefix} $count $_word',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
              ),
            ),
            InkWell(
              onTap: onFilters,
              borderRadius: BorderRadius.circular(AppSpacing.sp8),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sp4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.tune,
                      size: 18,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.sp4),
                    Text(
                      AppStrings.searchFilters,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp16),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        ),
      ],
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
    // Frosted-glass browse chip. GlassPanel supplies the translucent fill +
    // hairline; a transparent Material/InkWell on top keeps the tap ripple.
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
            Icon(
              Icons.history,
              size: 20,
              color: palette.textMuted,
            ),
            const SizedBox(width: AppSpacing.sp12),
            Expanded(
              child: Text(
                term,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
            ),
            Icon(
              Icons.north_west,
              size: 18,
              color: palette.iconFaint,
            ),
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
          Icon(
            Icons.search_off,
            size: 48,
            color: palette.iconFaint,
          ),
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
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
