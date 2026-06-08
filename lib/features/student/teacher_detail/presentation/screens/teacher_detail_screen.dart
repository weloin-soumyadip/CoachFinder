/// Student teacher detail screen — wired to `GET /api/teachers/:id` (+ reviews)
/// via [teacherDetailControllerProvider]. Read-only (the backend has no teacher
/// enquiry or view-tracking). Subject names are supplied by the caller (the
/// search/saved card passes them via the route's `extra`) because the endpoint
/// returns bare subject ids.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../saved/data/models/bookmark_model.dart';
import '../../../saved/presentation/widgets/bookmark_toggle_button.dart';
import '../../data/controllers/teacher_detail_provider.dart';
import '../../data/models/teacher_detail_model.dart';
import '../../data/models/teacher_review_model.dart';

/// Teacher detail screen. Receives `teacherId` from the route; [subjectNames]
/// are passed via `extra` from the search/saved card (the API returns ids only).
class TeacherDetailScreen extends HookConsumerWidget {
  /// Creates the detail screen for [teacherId].
  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
    this.subjectNames = const <String>[],
  });

  /// The backend teacher `_id`.
  final String teacherId;

  /// Subject names supplied by the caller (the endpoint returns ids only).
  final List<String> subjectNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final TeacherDetailState state =
        ref.watch(teacherDetailControllerProvider(teacherId));
    final TeacherDetail? teacher = state.teacher;

    Widget body;
    if (teacher == null && state.status == TeacherDetailStatus.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (teacher == null) {
      body = _LoadError(
        message: state.errorMessage ?? AppStrings.teacherDetailLoadError,
        onRetry: () => ref
            .read(teacherDetailControllerProvider(teacherId).notifier)
            .load(),
      );
    } else {
      body = _DetailBody(
        teacher: teacher,
        reviews: state.reviews,
        subjectNames: subjectNames,
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(
          teacher?.name ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
        ),
        actions: teacher == null
            ? null
            : <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sp16),
                  child: BookmarkToggleButton(
                    targetType: BookmarkTargetType.teacher,
                    targetId: teacherId,
                  ),
                ),
              ],
      ),
      body: body,
    );
  }
}

/// The loaded teacher's scrollable sections.
class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.teacher,
    required this.reviews,
    required this.subjectNames,
  });

  final TeacherDetail teacher;
  final List<TeacherReview> reviews;
  final List<String> subjectNames;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final String? bio =
        (teacher.bio ?? '').trim().isEmpty ? null : teacher.bio!.trim();
    // Prefer populated names from the API; fall back to the caller-supplied ones.
    final List<String> subjects =
        teacher.subjectNames.isNotEmpty ? teacher.subjectNames : subjectNames;

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
            _HeaderCard(teacher: teacher),
            if (bio != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionAbout),
              const SizedBox(height: AppSpacing.sp12),
              _Card(
                child: Text(
                  bio,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            if (subjects.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionSubjects),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: subjects),
            ],
            if (teacher.boards.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionBoards),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: teacher.boards),
            ],
            if (teacher.classRange != null &&
                !teacher.classRange!.isEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionClasses),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: <String>[_classLabel(teacher.classRange!)]),
            ],
            if (teacher.experienceYears > 0) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionExperience),
              const SizedBox(height: AppSpacing.sp12),
              _Card(
                child: Text(
                  '${teacher.experienceYears}${AppStrings.teacherYearsSuffix}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
            if (teacher.languages.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionLanguages),
              const SizedBox(height: AppSpacing.sp12),
              _Chips(labels: teacher.languages),
            ],
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(title: AppStrings.teacherSectionFees),
            const SizedBox(height: AppSpacing.sp12),
            _Card(child: _FeesText(fees: teacher.fees)),
            if (teacher.education.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionEducation),
              const SizedBox(height: AppSpacing.sp12),
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0;
                        i < teacher.education.length;
                        i++) ...<Widget>[
                      if (i > 0)
                        Divider(height: 1, color: palette.borderSubtle),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sp16,
                          vertical: AppSpacing.sp12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(Icons.school_outlined,
                                size: 18, color: palette.textMuted),
                            const SizedBox(width: AppSpacing.sp12),
                            Expanded(
                              child: Text(
                                teacher.education[i].summary,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (teacher.batches.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.sp24),
              _SectionTitle(title: AppStrings.teacherSectionBatches),
              const SizedBox(height: AppSpacing.sp12),
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    for (int i = 0;
                        i < teacher.batches.length;
                        i++) ...<Widget>[
                      if (i > 0)
                        Divider(height: 1, color: palette.borderSubtle),
                      _BatchRow(batch: teacher.batches[i]),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sp24),
            _SectionTitle(
              title:
                  '${AppStrings.centerDetailReviews} (${teacher.totalReviews})',
            ),
            const SizedBox(height: AppSpacing.sp12),
            _ReviewsSection(reviews: reviews),
          ],
        ),
      ),
    );
  }
}

/// Avatar + name + rating + verified + location.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.teacher});

  final TeacherDetail teacher;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Avatar(teacher: teacher),
          const SizedBox(width: AppSpacing.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  teacher.name,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp4),
                _RatingRow(
                  rating: teacher.averageRating,
                  total: teacher.totalReviews,
                ),
                if (teacher.locationLabel.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp8),
                  Row(
                    children: <Widget>[
                      Icon(Icons.location_on_outlined,
                          size: 16, color: palette.textMuted),
                      const SizedBox(width: AppSpacing.sp4),
                      Flexible(
                        child: Text(
                          teacher.locationLabel,
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
                if (teacher.isVerified) ...<Widget>[
                  const SizedBox(height: AppSpacing.sp8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(Icons.verified,
                          size: 16, color: AppColors.success),
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
    );
  }
}

/// Network avatar with an accent-initial fallback.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.teacher});

  final TeacherDetail teacher;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget fallback() => Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.studentPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            teacher.initial,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.neutralWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    if (teacher.profileImage.isEmpty) return fallback();
    return ClipOval(
      child: Image.network(
        teacher.profileImage,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
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

/// One batch row: name + days + time.
class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch});

  final TeacherBatch batch;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final String when = <String>[
      if (batch.days.isNotEmpty) batch.days.join(', '),
      if ((batch.startTime ?? '').isNotEmpty &&
          (batch.endTime ?? '').isNotEmpty)
        '${_formatHhmm(batch.startTime)} ${AppStrings.centerTimingTo} ${_formatHhmm(batch.endTime)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sp16,
        vertical: AppSpacing.sp12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            batch.name,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          if (when.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              when,
              style: textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ],
      ),
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

  final TeacherFees? fees;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final TeacherFees? f = fees;
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

/// Reviews list, or an empty state.
class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<TeacherReview> reviews;

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

  final TeacherReview review;

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
String _classLabel(TeacherClassRange r) {
  if (r.from != null && r.to != null) {
    return '${AppStrings.centerClassPrefix}${r.from}–${r.to}';
  }
  if (r.from != null) return '${AppStrings.centerClassPrefix}${r.from}+';
  return '${AppStrings.centerClassPrefix}${r.to}';
}

/// "₹1,000 – ₹5,000".
String _feeLabel(TeacherFees f) {
  final String sym = f.currency == 'INR' ? '₹' : '${f.currency} ';
  final String? lo =
      f.min == null ? null : '$sym${_withCommas(f.min!.round())}';
  final String? hi =
      f.max == null ? null : '$sym${_withCommas(f.max!.round())}';
  if (lo != null && hi != null) return '$lo${AppStrings.centerFeeRangeSep}$hi';
  return lo ?? hi ?? AppStrings.centerNotSet;
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
