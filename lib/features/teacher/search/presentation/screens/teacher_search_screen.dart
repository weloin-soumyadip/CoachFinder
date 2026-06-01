/// Teacher search - discover coaching centers to affiliate with: a search bar,
/// a "Hiring now" filter, a browse/recent resting state, and center results.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../student/search/presentation/widgets/search_field_widget.dart';
import '../../../profile/data/mock_teacher_profile_data.dart';
import '../../data/mock_teacher_search_data.dart';
import '../widgets/center_result_card.dart';

/// Teacher search screen.
///
/// Phase 1: all content is rendered from `mock_teacher_search_data.dart` and
/// filtered locally. A search bar drives a live, case-insensitive filter over
/// the affiliation centers; a "Hiring now" toggle narrows to centers open to
/// tutors. With no query and the filter off it shows a resting state (browse by
/// subject + recent searches). Result cards flow into a responsive grid (1
/// column on phones, up to 3 on wide layouts). Card taps and the affiliate
/// request are placeholders ("Coming soon"). Teal-branded
/// ([AppColors.teacherAccent]).
class TeacherSearchScreen extends HookConsumerWidget {
  const TeacherSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState<String>('');
    final hiringOnly = useState<bool>(false);

    void setQuery(String value) {
      controller.text = value;
      controller.selection = TextSelection.collapsed(offset: value.length);
      query.value = value;
    }

    void clear() {
      controller.clear();
      query.value = '';
    }

    void stub() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.stubComingSoon)),
        );
    }

    final q = query.value.trim().toLowerCase();
    final showResting = q.isEmpty && !hiringOnly.value;

    bool centerMatches(AffiliationCenter c) =>
        q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.location.toLowerCase().contains(q) ||
        c.subjects.any((String s) => s.toLowerCase().contains(q));

    final centers = mockAffiliationCenters
        .where((AffiliationCenter c) =>
            (!hiringOnly.value || c.isHiring) && centerMatches(c))
        .toList();

    return Scaffold(
      body: DecoratedBox(
        // Subtle vertical teal wash at the top that fades into the flat
        // background within the first ~40% of the viewport — the teacher-shell
        // counterpart to the student search's blue wash.
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.teacherAccentTint,
              context.palette.background,
            ],
            stops: const <double>[0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
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
                            hintText: AppStrings.teacherSearchHint,
                            onChanged: (String v) => query.value = v,
                            onClear: clear,
                          ),
                          const SizedBox(height: AppSpacing.sp16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _HiringFilterPill(
                              active: hiringOnly.value,
                              onTap: () => hiringOnly.value = !hiringOnly.value,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sp24),
                          if (showResting)
                            _RestingState(onTermSelected: setQuery)
                          else
                            _Results(
                              centers: centers,
                              cardWidth: cardWidth,
                              gap: gap,
                              onRequest: stub,
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

/// The single "Hiring now" toggle. Filled teal when active, frosted glass when
/// not.
class _HiringFilterPill extends StatelessWidget {
  const _HiringFilterPill({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Widget inner = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.bolt_outlined,
                size: 16,
                color: active ? AppColors.neutralWhite : palette.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sp4),
              Text(
                AppStrings.teacherSearchHiringFilter,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppColors.neutralWhite
                          : palette.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
    if (active) {
      return Material(
        color: AppColors.teacherAccent,
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
        child: inner,
      );
    }
    return GlassPanel(
      padding: EdgeInsets.zero,
      radius: AppSpacing.sp24,
      child: inner,
    );
  }
}

/// Resting (pre-search) state: browse-by-subject chips + recent searches.
class _RestingState extends StatelessWidget {
  const _RestingState({required this.onTermSelected});

  final ValueChanged<String> onTermSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SectionHeader(title: AppStrings.teacherSearchBrowseSubject),
        const SizedBox(height: AppSpacing.sp12),
        Wrap(
          spacing: AppSpacing.sp8,
          runSpacing: AppSpacing.sp8,
          children: <Widget>[
            for (final String subject in teacherSubjectOptions)
              _SubjectChip(
                label: subject,
                onTap: () => onTermSelected(subject),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sp24),
        const _SectionHeader(title: AppStrings.teacherSearchRecent),
        const SizedBox(height: AppSpacing.sp8),
        for (final String term in mockTeacherSearchRecents)
          _RecentSearchTile(term: term, onTap: () => onTermSelected(term)),
      ],
    );
  }
}

/// Results state: a "Found N centers" header, then the responsive grid.
class _Results extends StatelessWidget {
  const _Results({
    required this.centers,
    required this.cardWidth,
    required this.gap,
    required this.onRequest,
  });

  final List<AffiliationCenter> centers;
  final double cardWidth;
  final double gap;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    if (centers.isEmpty) return const _EmptyResults();

    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '${AppStrings.teacherSearchFoundPrefix} ${centers.length} '
          '${AppStrings.teacherSearchCentersWord}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.sp16),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final AffiliationCenter center in centers)
              SizedBox(
                width: cardWidth,
                child: CenterResultCard(
                  center: center,
                  onTap: onRequest,
                  onRequest: onRequest,
                ),
              ),
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

/// Frosted-glass browse-by-subject chip.
class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.label, required this.onTap});

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

/// Shown when a query / filter yields no matching centers.
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
            AppStrings.teacherSearchNoResultsTitle,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sp4),
          Text(
            AppStrings.teacherSearchNoResultsSubtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}
