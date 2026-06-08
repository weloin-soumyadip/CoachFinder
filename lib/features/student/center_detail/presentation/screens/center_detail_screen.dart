/// Student coaching-center detail screen — wired to `GET /api/centers/:id`
/// (+ reviews, + record-view, + enquire) via [centerDetailControllerProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../saved/data/models/bookmark_model.dart';
import '../../../saved/presentation/widgets/bookmark_toggle_button.dart';
import '../../data/controllers/center_detail_provider.dart';
import '../../data/models/center_detail_model.dart';
import '../../data/models/center_review_model.dart';

/// Coaching-center detail screen. Receives `centerId` from the route.
class CenterDetailScreen extends HookConsumerWidget {
  /// Creates the detail screen for [centerId].
  const CenterDetailScreen({super.key, required this.centerId});

  /// The backend centre `_id`.
  final String centerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final CenterDetailState state =
        ref.watch(centerDetailControllerProvider(centerId));
    final CenterDetail? center = state.center;

    Widget body;
    if (center == null && state.status == CenterDetailStatus.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (center == null) {
      body = _LoadError(
        message: state.errorMessage ?? AppStrings.centerDetailLoadError,
        onRetry: () =>
            ref.read(centerDetailControllerProvider(centerId).notifier).load(),
      );
    } else {
      body = _DetailBody(center: center, reviews: state.reviews);
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          center?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
        actions: center == null
            ? null
            : <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sp16),
                  child: BookmarkToggleButton(
                    targetType: BookmarkTargetType.coachingCenter,
                    targetId: centerId,
                  ),
                ),
              ],
      ),
      body: body,
      bottomNavigationBar: center == null
          ? null
          : _EnquireBar(centerId: centerId, center: center),
    );
  }
}

/// The loaded centre's scrollable sections.
class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.center, required this.reviews});

  final CenterDetail center;
  final List<CenterReview> reviews;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final String? description = (center.description ?? '').trim().isEmpty
        ? null
        : center.description!.trim();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sp16,
            AppSpacing.sp16,
            AppSpacing.sp16,
            floatingNavClearance(context),
          ),
          children: <Widget>[
            _HeaderCard(center: center),
            if (description != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.centerSectionAbout),
              const SizedBox(height: AppSpacing.sp12),
              _Card(
                child: Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (center.subjects.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.centerSectionSubjects),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(
                labels: center.subjects
                    .map((CenterDetailSubject s) => s.name)
                    .where((String n) => n.isNotEmpty)
                    .toList(),
              ),
            ],
            if (center.boards.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.centerSectionBoards),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: center.boards),
            ],
            if (center.classRange != null &&
                !center.classRange!.isEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.centerSectionClasses),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: <String>[_classLabel(center.classRange!)]),
            ],
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.centerSectionFees),
            const SizedBox(height: AppSpacing.sp12),
            _Card(child: _FeesText(fees: center.fees)),
            if (center.timings.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.centerSectionTimings),
              const SizedBox(height: AppSpacing.sp12),
              _TimingsCard(timings: center.timings),
            ],
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.centerSectionContact),
            const SizedBox(height: AppSpacing.sp12),
            _ContactCard(center: center),
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(
              title:
                  '${AppStrings.centerDetailReviews} (${center.totalReviews})',
            ),
            const SizedBox(height: AppSpacing.sp12),
            _ReviewsSection(reviews: reviews),
          ],
        ),
      ),
    );
  }
}

/// Banner + logo + name + rating + verified + location.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.center});

  final CenterDetail center;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (center.bannerImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.sp16),
              ),
              child: _NetworkBanner(url: center.bannerImage),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sp16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Logo(center: center),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        center.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sp4),
                      _RatingRow(
                        rating: center.averageRating,
                        total: center.totalReviews,
                      ),
                      if (center.locationLabel.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.sp8),
                        Row(
                          children: <Widget>[
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.sp4),
                            Flexible(
                              child: Text(
                                center.locationLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (center.isVerified) ...<Widget>[
                        const SizedBox(height: AppSpacing.sp8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.sp4),
                            Text(
                              AppStrings.centerDetailVerified,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo: network profile image, falling back to an accent initial tile.
class _Logo extends StatelessWidget {
  const _Logo({required this.center});

  final CenterDetail center;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget fallback() => Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.studentPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.sp16),
          ),
          child: Text(
            center.initial,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    if (center.profileImage.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.sp16),
      child: Image.network(
        center.profileImage,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
      ),
    );
  }
}

/// A 160px network banner with a flat-surface fallback on error.
class _NetworkBanner extends StatelessWidget {
  const _NetworkBanner({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      height: 160,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 160,
        color: AppColors.studentPrimary.withValues(alpha: 0.12),
      ),
    );
  }
}

/// "★★★★☆ 4.5 · N reviews".
class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.total});

  final double rating;
  final int total;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final int full = rating.floor();
    return Row(
      children: <Widget>[
        for (int i = 0; i < 5; i++)
          Icon(
            i < full ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 18,
            color: AppColors.ratingStar,
          ),
        const SizedBox(width: AppSpacing.sp4),
        Text(
          rating.toStringAsFixed(1),
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        Text(
          ' · $total${AppStrings.dashboardReviewsSuffix}',
          style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

/// Accent-tinted read-only chips.
class _Chips extends StatelessWidget {
  const _Chips({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sp8,
      runSpacing: AppSpacing.sp8,
      children: <Widget>[
        for (final String label in labels)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sp12,
              vertical: AppSpacing.sp8,
            ),
            decoration: BoxDecoration(
              color: AppColors.studentPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppSpacing.sp24),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: context.palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Fee range text (or an empty state).
class _FeesText extends StatelessWidget {
  const _FeesText({required this.fees});

  final CenterDetailFees? fees;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final CenterDetailFees? f = fees;
    if (f == null || f.isEmpty) {
      return Text(
        AppStrings.centerNotSet,
        style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
      );
    }
    return Text(
      _feeLabel(f),
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.priceGreen,
      ),
    );
  }
}

/// Weekly timings list.
class _TimingsCard extends StatelessWidget {
  const _TimingsCard({required this.timings});

  final List<CenterDetailTiming> timings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < timings.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: palette.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16,
                vertical: AppSpacing.sp12,
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 44,
                    child: Text(
                      timings[i].day,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _timingLabel(timings[i]),
                    style: textTheme.bodyMedium?.copyWith(
                      color: timings[i].closed
                          ? palette.textMuted
                          : palette.textSecondary,
                      fontWeight:
                          timings[i].closed ? FontWeight.w400 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Phone / alt phone / email / website / address rows. Call & email are stubbed
/// (no url_launcher in the fixed stack).
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.center});

  final CenterDetail center;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[
      _ContactRow(icon: Icons.phone_outlined, value: center.phone),
      if ((center.alternatePhone ?? '').isNotEmpty)
        _ContactRow(
          icon: Icons.phone_iphone_outlined,
          value: center.alternatePhone!,
        ),
      if ((center.email ?? '').isNotEmpty)
        _ContactRow(icon: Icons.email_outlined, value: center.email!),
      if ((center.website ?? '').isNotEmpty)
        _ContactRow(icon: Icons.language_outlined, value: center.website!),
      _ContactRow(icon: Icons.location_on_outlined, value: center.address),
    ];
    return _Card(
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sp12),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: palette.textMuted),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Reviews list, or an empty state.
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<CenterReview> reviews;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (reviews.isEmpty) {
      return _Card(
        child: Text(
          AppStrings.centerDetailNoReviews,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: palette.textMuted),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < reviews.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.sp12),
          _ReviewCard(review: reviews[i]),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final CenterReview review;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  review.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.star_rounded,
                      size: 16, color: AppColors.ratingStar),
                  const SizedBox(width: 2),
                  Text(
                    review.rating.toString(),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sp8),
            Text(
              review.comment!,
              style: textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (review.createdAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sp8),
            Text(
              _shortDate(review.createdAt!),
              style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sticky bottom "Enquire" bar that opens the enquiry sheet.
class _EnquireBar extends StatelessWidget {
  const _EnquireBar({required this.centerId, required this.center});

  final String centerId;
  final CenterDetail center;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sp16,
          AppSpacing.sp8,
          AppSpacing.sp16,
          AppSpacing.sp8,
        ),
        child: FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: palette.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSpacing.sp24),
              ),
            ),
            builder: (_) => _EnquirySheet(centerId: centerId, center: center),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.studentPrimary,
            foregroundColor: AppColors.neutralWhite,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.sp12),
            ),
          ),
          icon: const Icon(Icons.send_outlined, size: 20),
          label: const Text(
            AppStrings.centerDetailEnquire,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// The enquiry bottom sheet: message + optional subject → POST enquiry.
class _EnquirySheet extends HookConsumerWidget {
  const _EnquirySheet({required this.centerId, required this.center});

  final String centerId;
  final CenterDetail center;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final TextEditingController messageC = useTextEditingController();
    final ValueNotifier<String?> subjectId = useState<String?>(null);
    final bool submitting = ref.watch(
      centerDetailControllerProvider(centerId)
          .select((CenterDetailState s) => s.enquirySubmitting),
    );

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final bool ok = await ref
          .read(centerDetailControllerProvider(centerId).notifier)
          .submitEnquiry(
            message: messageC.text.trim(),
            subjectId: subjectId.value,
          );
      if (!context.mounted) return;
      if (ok) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.centerEnquirySuccess)),
          );
      } else {
        final String message =
            ref.read(centerDetailControllerProvider(centerId)).errorMessage ??
                AppStrings.centerEnquiryError;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    }

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.sp16,
        right: AppSpacing.sp16,
        top: AppSpacing.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sp24,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              AppStrings.centerEnquiryTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sp16),
            if (center.subjects.isNotEmpty) ...<Widget>[
              Text(
                AppStrings.centerEnquirySubjectLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppSpacing.sp8),
              DropdownButtonFormField<String>(
                initialValue: subjectId.value,
                isExpanded: true,
                dropdownColor: palette.surface,
                style: TextStyle(color: palette.textPrimary),
                decoration: _fieldDecoration(context),
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    child: Text(AppStrings.centerEnquirySubjectNone),
                  ),
                  for (final CenterDetailSubject s in center.subjects)
                    if (s.id.isNotEmpty && s.name.isNotEmpty)
                      DropdownMenuItem<String>(
                          value: s.id, child: Text(s.name)),
                ],
                onChanged: (String? v) => subjectId.value = v,
              ),
              const SizedBox(height: AppSpacing.sp16),
            ],
            Text(
              AppStrings.centerEnquiryMessageLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sp8),
            TextFormField(
              controller: messageC,
              maxLines: 4,
              autofocus: true,
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? AppStrings.validatorRequired
                  : null,
              style: TextStyle(color: palette.textPrimary),
              decoration: _fieldDecoration(context).copyWith(
                hintText: AppStrings.centerEnquiryMessageHint,
                hintStyle: TextStyle(color: palette.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.sp24),
            FilledButton(
              onPressed: submitting ? null : submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.studentPrimary,
                foregroundColor: AppColors.neutralWhite,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.sp12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.neutralWhite,
                      ),
                    )
                  : const Text(
                      AppStrings.centerEnquirySend,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context) {
    final palette = context.palette;
    return InputDecoration(
      filled: true,
      fillColor: palette.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sp12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

/// Bold section title.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

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

/// Flat surface card used for content sections (student shell stays flat).
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.sp16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSpacing.sp16),
        border: Border.all(color: palette.borderSubtle),
      ),
      child: child,
    );
  }
}

/// Inline load-failure state with a retry button.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sp24),
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
                backgroundColor: AppColors.studentPrimary,
                foregroundColor: AppColors.neutralWhite,
              ),
              child: const Text(AppStrings.profileRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Class 6–12" / "Class 6+" / "Class 12".
String _classLabel(CenterDetailClassRange r) {
  if (r.from != null && r.to != null) {
    return '${AppStrings.centerClassPrefix}${r.from}–${r.to}';
  }
  if (r.from != null) return '${AppStrings.centerClassPrefix}${r.from}+';
  return '${AppStrings.centerClassPrefix}${r.to}';
}

/// "₹1,000 – ₹5,000".
String _feeLabel(CenterDetailFees f) {
  final String sym = f.currency == 'INR' ? '₹' : '${f.currency} ';
  final String? lo =
      f.min == null ? null : '$sym${_withCommas(f.min!.round())}';
  final String? hi =
      f.max == null ? null : '$sym${_withCommas(f.max!.round())}';
  if (lo != null && hi != null) return '$lo${AppStrings.centerFeeRangeSep}$hi';
  return lo ?? hi ?? AppStrings.centerNotSet;
}

/// "4:00 PM to 7:00 PM" or "Closed".
String _timingLabel(CenterDetailTiming t) {
  if (t.closed) return AppStrings.centerTimingClosed;
  final String open = _formatHhmm(t.openTime);
  final String close = _formatHhmm(t.closeTime);
  if (open.isEmpty && close.isEmpty) return AppStrings.centerTimingClosed;
  return '$open ${AppStrings.centerTimingTo} $close';
}

/// Formats a backend `HH:mm` into "h:mm AM/PM", or '' when null/malformed.
String _formatHhmm(String? hhmm) {
  if (hhmm == null) return '';
  final List<String> parts = hhmm.split(':');
  if (parts.length != 2) return '';
  final int? h = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  if (h == null || m == null) return '';
  final String period = h < 12 ? 'AM' : 'PM';
  final int h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

const List<String> _monthsShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "15 Jan 2026".
String _shortDate(DateTime d) =>
    '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

/// Inserts thousands separators into a non-negative integer.
String _withCommas(int value) {
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
