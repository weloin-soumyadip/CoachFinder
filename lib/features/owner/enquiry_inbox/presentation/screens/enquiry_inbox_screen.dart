/// Inbox list of student enquiries — wired to `GET /api/owners/enquiries`
/// (+ `/search`) via [enquiryListControllerProvider]: search, New/Contacted/
/// Closed status filters, an unread count, and infinite scroll.
library;

import 'dart:async';

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
import '../../data/controllers/enquiry_provider.dart';
import '../../data/models/enquiry_model.dart';
import '../widgets/enquiry_tile_widget.dart';

/// Owner enquiry inbox.
class EnquiryInboxScreen extends HookConsumerWidget {
  /// Creates the inbox.
  const EnquiryInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EnquiryListState state = ref.watch(enquiryListControllerProvider);
    final EnquiryListController controller =
        ref.read(enquiryListControllerProvider.notifier);
    final TextEditingController searchController = useTextEditingController();
    final ValueNotifier<String> query = useState<String>('');
    final ScrollController scrollController = useScrollController();

    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    // Debounce the search box → controller.setQuery.
    useEffect(() {
      final Timer timer = Timer(
        const Duration(milliseconds: 350),
        () => controller.setQuery(query.value.trim()),
      );
      return timer.cancel;
    }, <Object?>[query.value]);

    // Infinite scroll: load the next page near the bottom.
    useEffect(() {
      void onScroll() {
        final ScrollPosition p = scrollController.position;
        if (p.pixels >= p.maxScrollExtent - 300) controller.loadMore();
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, <Object?>[scrollController]);

    void openEnquiry(String id) => context.pushNamed(
          AppRoutes.ownerEnquiryDetail,
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
                      if (state.newCount > 0) ...<Widget>[
                        const SizedBox(width: AppSpacing.sp8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${state.newCount} ${AppStrings.enquiriesUnreadSuffix}',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.ownerAccent,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
                  child: _SearchField(
                    controller: searchController,
                    onChanged: (String v) => query.value = v,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp12),
                _FilterBar(
                  selected: state.filter,
                  onSelected: controller.setFilter,
                ),
                const SizedBox(height: AppSpacing.sp16),
                Expanded(
                  child: _Body(
                    state: state,
                    scrollController: scrollController,
                    onRetry: controller.load,
                    onOpen: openEnquiry,
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

/// The list region: spinner / error / empty / list (with a load-more footer).
class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.scrollController,
    required this.onRetry,
    required this.onOpen,
  });

  final EnquiryListState state;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == EnquiryListStatus.error && state.items.isEmpty) {
      return _ErrorState(
        message: state.errorMessage ?? AppStrings.enquiriesLoadError,
        onRetry: onRetry,
      );
    }
    if (state.items.isEmpty) return const _EmptyState();

    final bool showFooter = state.status == EnquiryListStatus.loadingMore;
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sp16,
        0,
        AppSpacing.sp16,
        floatingNavClearance(context),
      ),
      itemCount: state.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sp12),
      itemBuilder: (BuildContext context, int i) {
        if (i >= state.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sp16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final Enquiry e = state.items[i];
        return EnquiryTileWidget(enquiry: e, onTap: () => onOpen(e.id));
      },
    );
  }
}

/// Rounded search box.
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

  final EnquiryFilter selected;
  final ValueChanged<EnquiryFilter> onSelected;

  static const List<(EnquiryFilter, String)> _items = <(EnquiryFilter, String)>[
    (EnquiryFilter.all, AppStrings.enquiriesFilterAll),
    (EnquiryFilter.newEnquiry, AppStrings.enquiriesFilterNew),
    (EnquiryFilter.contacted, AppStrings.enquiriesFilterContacted),
    (EnquiryFilter.closed, AppStrings.enquiriesFilterClosed),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
      child: Row(
        children: <Widget>[
          for (final (EnquiryFilter value, String label) in _items)
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

/// One status filter pill — filled accent when selected.
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
      color: selected ? AppColors.ownerAccent : palette.surface,
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
              color: selected ? AppColors.ownerAccent : palette.border,
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

/// Centered empty state.
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
            Icon(Icons.inbox_outlined, size: 48, color: palette.iconFaint),
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

/// Inline load-failure state with a retry button.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off, size: 48, color: palette.iconFaint),
            const SizedBox(height: AppSpacing.sp12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: AppSpacing.sp16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ownerAccent,
                foregroundColor: AppColors.neutralWhite,
              ),
              child: const Text(AppStrings.dashboardRetry),
            ),
          ],
        ),
      ),
    );
  }
}
