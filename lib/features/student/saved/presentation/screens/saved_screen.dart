/// Student Saved screen - search field, All/Coachings/Tutors filter, and the
/// bookmarked tutors and coaching institutes.
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
import '../../../search/data/mock_search_data.dart';
import '../../../search/presentation/widgets/institute_result_card.dart';
import '../../../search/presentation/widgets/search_field_widget.dart';
import '../../../search/presentation/widgets/teacher_result_card.dart';
import '../../data/mock_saved_data.dart';

/// Student Saved screen.
///
/// Phase 1: the saved tutors and coachings come from `mock_saved_data.dart` and
/// live in local hook state so the un-save (filled bookmark) control on each
/// card actually removes it. A search field filters the saved items live, and
/// an All / Coachings / Tutors control narrows by type. Cards reuse the Search
/// result cards and flow into the same responsive grid (1 column on phones, up
/// to 3 on wide layouts). Card taps remain placeholders; clearing the list (or
/// a non-matching search) shows an empty state.
class SavedScreen extends HookConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final query = useState<String>('');
    final filter = useState<SavedFilter>(SavedFilter.all);
    final tutors = useState<List<SearchTeacher>>(List.of(mockSavedTutors));
    final coachings =
        useState<List<SearchInstitute>>(List.of(mockSavedCoachings));

    void clear() {
      controller.clear();
      query.value = '';
    }

    void removeTutor(String id) {
      tutors.value =
          tutors.value.where((SearchTeacher t) => t.id != id).toList();
    }

    void removeCoaching(String id) {
      coachings.value =
          coachings.value.where((SearchInstitute c) => c.id != id).toList();
    }

    final q = query.value.trim().toLowerCase();

    bool tutorMatches(SearchTeacher t) =>
        q.isEmpty ||
        t.name.toLowerCase().contains(q) ||
        t.title.toLowerCase().contains(q) ||
        t.tags.any((String tag) => tag.toLowerCase().contains(q));

    bool coachingMatches(SearchInstitute c) =>
        q.isEmpty ||
        c.name.toLowerCase().contains(q) ||
        c.location.toLowerCase().contains(q) ||
        c.tags.any((String tag) => tag.toLowerCase().contains(q));

    final visibleCoachings = filter.value == SavedFilter.tutors
        ? const <SearchInstitute>[]
        : coachings.value.where(coachingMatches).toList();
    final visibleTutors = filter.value == SavedFilter.coachings
        ? const <SearchTeacher>[]
        : tutors.value.where(tutorMatches).toList();
    final total = visibleCoachings.length + visibleTutors.length;

    return Scaffold(
      body: DecoratedBox(
        // Subtle vertical brand-tint wash at the top that fades into the flat
        // background within the first ~40% of the viewport, matching the Home
        // and Search tabs' backdrop.
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
              // Responsive grid sizing, measured on the content area so it stays
              // correct inside the desktop NavigationRail. Content is capped and
              // centred so cards don't stretch on very wide windows.
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
                      ),
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
                          if (total == 0)
                            const _SavedEmpty()
                          else
                            _SavedList(
                              count: total,
                              coachings: visibleCoachings,
                              tutors: visibleTutors,
                              cardWidth: cardWidth,
                              gap: gap,
                              onRemoveCoaching: removeCoaching,
                              onRemoveTutor: removeTutor,
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

/// All / Coachings / Tutors filter control (three equal-width pills).
class _FilterControl extends StatelessWidget {
  const _FilterControl({required this.selected, required this.onChanged});

  final SavedFilter selected;
  final ValueChanged<SavedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _FilterPill(
            label: AppStrings.savedFilterAll,
            selected: selected == SavedFilter.all,
            onTap: () => onChanged(SavedFilter.all),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _FilterPill(
            label: AppStrings.savedFilterCoachings,
            selected: selected == SavedFilter.coachings,
            onTap: () => onChanged(SavedFilter.coachings),
          ),
        ),
        const SizedBox(width: AppSpacing.sp8),
        Expanded(
          child: _FilterPill(
            label: AppStrings.savedFilterTutors,
            selected: selected == SavedFilter.tutors,
            onTap: () => onChanged(SavedFilter.tutors),
          ),
        ),
      ],
    );
  }
}

/// One pill in [_FilterControl]. Filled blue when selected, outlined when not.
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

/// The saved results: a "N saved" count line then the responsive card grid.
class _SavedList extends StatelessWidget {
  const _SavedList({
    required this.count,
    required this.coachings,
    required this.tutors,
    required this.cardWidth,
    required this.gap,
    required this.onRemoveCoaching,
    required this.onRemoveTutor,
  });

  final int count;
  final List<SearchInstitute> coachings;
  final List<SearchTeacher> tutors;
  final double cardWidth;
  final double gap;
  final ValueChanged<String> onRemoveCoaching;
  final ValueChanged<String> onRemoveTutor;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      for (final SearchInstitute c in coachings)
        InstituteResultCard(
          institute: c,
          onTap: () {},
          onUnsave: () => onRemoveCoaching(c.id),
        ),
      for (final SearchTeacher t in tutors)
        TeacherResultCard(
          teacher: t,
          onTap: () {},
          onUnsave: () => onRemoveTutor(t.id),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          '$count ${AppStrings.savedCountWord}',
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
            for (final Widget card in cards)
              SizedBox(width: cardWidth, child: card),
          ],
        ),
      ],
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
          Icon(
            Icons.bookmark_border,
            size: 48,
            color: palette.iconFaint,
          ),
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
            style: textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
