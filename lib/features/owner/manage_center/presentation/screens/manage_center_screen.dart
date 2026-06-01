/// Center tab - read view of the owner's coaching center with an Edit button.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/layouts/adaptive_navigation.dart';
import '../../../../../shared/widgets/brand_backdrop.dart';
import '../../../../../shared/widgets/glass_panel.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../../../../shared/widgets/neo_surface.dart';
import '../../data/controllers/manage_center_provider.dart';
import '../../data/mock_center_data.dart';
import '../widgets/image_upload_widget.dart';

/// Owner Center tab.
///
/// Displays the center the way students see it - identity, a read-only stats
/// strip, about, subjects, boards, timings, photos, contact, and fees - from
/// [manageCenterProvider]. The Edit button pushes the edit form; saving there
/// updates this view live.
class ManageCenterScreen extends HookConsumerWidget {
  const ManageCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CenterProfile center = ref.watch(manageCenterProvider);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[AppColors.ownerAccent],
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.sp16,
                  AppSpacing.sp8,
                  AppSpacing.sp16,
                  floatingNavClearance(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    GlassPanel(
                      padding: const EdgeInsets.all(AppSpacing.sp16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              AppStrings.centerTabTitle,
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sp12),
                          NeoButton(
                            onPressed: () =>
                                context.pushNamed(AppRoutes.ownerEditCenter),
                            accent: AppColors.ownerAccent,
                            height: 44,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const <Widget>[
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: AppSpacing.sp8),
                                Text(AppStrings.centerEdit),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    _StatsStrip(center: center),
                    const SizedBox(height: AppSpacing.sp16),
                    _IdentityCard(center: center),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionAbout),
                    const SizedBox(height: AppSpacing.sp12),
                    _Card(
                      child: Text(
                        center.about,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionSubjects),
                    const SizedBox(height: AppSpacing.sp12),
                    _ReadChips(labels: center.subjects),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionBoards),
                    const SizedBox(height: AppSpacing.sp12),
                    _ReadChips(labels: center.boards),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionTimings),
                    const SizedBox(height: AppSpacing.sp12),
                    _TimingsCard(timings: center.timings),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionPhotos),
                    const SizedBox(height: AppSpacing.sp12),
                    ImageUploadWidget(photos: center.photos),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionContact),
                    const SizedBox(height: AppSpacing.sp12),
                    _ContactCard(center: center),
                    const SizedBox(height: AppSpacing.sp24),
                    _SectionTitle(title: AppStrings.centerSectionFees),
                    const SizedBox(height: AppSpacing.sp12),
                    _FeesCard(fees: center.fees),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only views / rating / reviews strip.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.center});

  final CenterProfile center;

  @override
  Widget build(BuildContext context) {
    return NeoSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp16),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                value: _withCommas(center.profileViews),
                label: AppStrings.centerStatViews,
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _Stat(
                value: center.rating.toStringAsFixed(1),
                label: AppStrings.centerStatRating,
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _Stat(
                value: center.reviewCount.toString(),
                label: AppStrings.centerStatReviews,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return Column(
      children: <Widget>[
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      indent: AppSpacing.sp8,
      endIndent: AppSpacing.sp8,
      color: context.palette.borderSubtle,
    );
  }
}

/// Logo, name, tagline, and location.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.center});

  final CenterProfile center;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: center.logoColor,
              borderRadius: BorderRadius.circular(AppSpacing.sp16),
            ),
            alignment: Alignment.center,
            child: Text(
              center.initial,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.neutralWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
                const SizedBox(height: 2),
                Text(
                  center.tagline,
                  style: textTheme.bodySmall?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
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
                        center.location,
                        style: textTheme.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only accent-tinted chips (subjects / boards).
class _ReadChips extends StatelessWidget {
  const _ReadChips({required this.labels});

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
              color: AppColors.ownerAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sp24),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.ownerAccent,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}

/// Read-only weekly timings list.
class _TimingsCard extends StatelessWidget {
  const _TimingsCard({required this.timings});

  final List<DayTiming> timings;

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
                    timings[i].isOpen
                        ? '${formatTimeOfDay(timings[i].openAt)} '
                            '${AppStrings.centerTimingTo} '
                            '${formatTimeOfDay(timings[i].closeAt)}'
                        : AppStrings.centerTimingClosed,
                    style: textTheme.bodyMedium?.copyWith(
                      color: timings[i].isOpen
                          ? palette.textSecondary
                          : palette.textMuted,
                      fontWeight:
                          timings[i].isOpen ? FontWeight.w600 : FontWeight.w400,
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

/// Phone, email, and address rows.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.center});

  final CenterProfile center;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: <Widget>[
          _ContactRow(icon: Icons.phone_outlined, value: center.phone),
          const SizedBox(height: AppSpacing.sp12),
          _ContactRow(icon: Icons.email_outlined, value: center.email),
          const SizedBox(height: AppSpacing.sp12),
          _ContactRow(
            icon: Icons.location_on_outlined,
            value: center.address,
          ),
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

/// Course + fee rows.
class _FeesCard extends StatelessWidget {
  const _FeesCard({required this.fees});

  final List<CourseFee> fees;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < fees.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: palette.borderSubtle),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sp16,
                vertical: AppSpacing.sp12,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      fees[i].course,
                      style: textTheme.bodyLarge?.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sp12),
                  Text(
                    fees[i].fee,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.priceGreen,
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

/// Outset neomorphic surface used for most independent content sections.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return NeoSurface(
      padding: padding ?? const EdgeInsets.all(AppSpacing.sp16),
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// Inserts thousands separators into a non-negative integer (e.g. 1248 ->
/// "1,248").
String _withCommas(int value) {
  final String digits = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
