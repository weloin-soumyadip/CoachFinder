/// Teacher enquiry inbox: students who contacted the tutor directly, with
/// search and status filters.
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
import '../../data/controllers/teacher_enquiry_provider.dart';
import '../../data/mock_teacher_enquiry_data.dart';
import '../widgets/teacher_enquiry_tile_widget.dart';

/// Teacher enquiry inbox.
///
/// Lists the enquiries from [teacherEnquiriesProvider] with a search box and
/// All / New / Replied / Archived status filters. Tapping a tile pushes the
/// detail route (so its back button returns here). Reads update live as the
/// detail screen replies to or archives an enquiry. Teal-branded
/// ([AppColors.teacherAccent]).
class TeacherEnquiriesScreen extends HookConsumerWidget {
  const TeacherEnquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<TeacherEnquiry> enquiries = ref.watch(teacherEnquiriesProvider);
    final TextEditingController searchController = useTextEditingController();
    final ValueNotifier<String> query = useState<String>('');
    final ValueNotifier<TeacherEnquiryFilter> filter =
        useState<TeacherEnquiryFilter>(TeacherEnquiryFilter.all);

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    final int unreadCount = enquiries
        .where(
            (TeacherEnquiry e) => e.status == TeacherEnquiryStatus.newEnquiry)
        .length;

    final String q = query.value.trim().toLowerCase();
    final List<TeacherEnquiry> filtered = enquiries.where((TeacherEnquiry e) {
      final bool matchesFilter = switch (filter.value) {
        TeacherEnquiryFilter.all => true,
        TeacherEnquiryFilter.newEnquiry =>
          e.status == TeacherEnquiryStatus.newEnquiry,
        TeacherEnquiryFilter.replied =>
          e.status == TeacherEnquiryStatus.replied,
        TeacherEnquiryFilter.archived =>
          e.status == TeacherEnquiryStatus.archived,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return e.studentName.toLowerCase().contains(q) ||
          e.subject.toLowerCase().contains(q) ||
          e.preview.toLowerCase().contains(q);
    }).toList();

    void openEnquiry(String id) => context.pushNamed(
          AppRoutes.teacherEnquiryDetail,
          pathParameters: <String, String>{'id': id},
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sp16,
                    AppSpacing.sp8,
                    AppSpacing.sp16,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        AppStrings.enquiriesTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      if (unreadCount > 0) ...<Widget>[
                        const SizedBox(width: AppSpacing.sp8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$unreadCount ${AppStrings.enquiriesUnreadSuffix}',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.teacherAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sp12),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sp16,
                  ),
                  child: _SearchField(
                    controller: searchController,
                    onChanged: (String value) => query.value = value,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp12),
                _FilterBar(
                  selected: filter.value,
                  onSelected: (TeacherEnquiryFilter f) => filter.value = f,
                ),
                const SizedBox(height: AppSpacing.sp16),
                Expanded(
                  child: filtered.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.sp16,
                            0,
                            AppSpacing.sp16,
                            floatingNavClearance(context),
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sp12),
                          itemBuilder: (BuildContext context, int i) =>
                              TeacherEnquiryTileWidget(
                            enquiry: filtered[i],
                            onTap: () => openEnquiry(filtered[i].id),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded search box for filtering the inbox by name, subject, or message.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(color: palette.textPrimary),
      decoration: InputDecoration(
        hintText: AppStrings.enquiriesSearchHint,
        hintStyle: TextStyle(color: palette.textMuted),
        prefixIcon: Icon(Icons.search, color: palette.textMuted),
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sp12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Horizontally-scrollable row of status filter pills.
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelected});

  final TeacherEnquiryFilter selected;
  final ValueChanged<TeacherEnquiryFilter> onSelected;

  static const List<(TeacherEnquiryFilter, String)> _items =
      <(TeacherEnquiryFilter, String)>[
    (TeacherEnquiryFilter.all, AppStrings.enquiriesFilterAll),
    (TeacherEnquiryFilter.newEnquiry, AppStrings.enquiriesFilterNew),
    (TeacherEnquiryFilter.replied, AppStrings.enquiriesFilterReplied),
    (TeacherEnquiryFilter.archived, AppStrings.enquiriesFilterArchived),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          for (final (TeacherEnquiryFilter value, String label) in _items)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sp8),
              child: _FilterPill(
                label: label,
                selected: value == selected,
                onTap: () => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

/// One status filter pill - filled teal when selected.
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
    return Material(
      color: selected ? AppColors.teacherAccent : palette.surface,
      borderRadius: BorderRadius.circular(AppSpacing.sp24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.sp24),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sp16,
            vertical: AppSpacing.sp8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.sp24),
            border: Border.all(
              color: selected ? AppColors.teacherAccent : palette.border,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color:
                      selected ? AppColors.neutralWhite : palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

/// Centered empty state shown when no enquiry matches the search/filter.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: palette.iconFaint,
            ),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              AppStrings.enquiriesEmptyTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sp4),
            Text(
              AppStrings.enquiriesEmptySubtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
