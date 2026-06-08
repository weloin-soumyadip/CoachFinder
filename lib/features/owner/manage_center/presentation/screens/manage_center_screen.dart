/// Center tab — read view of the owner's coaching center, wired to
/// `GET /api/centers/me` via [manageCenterControllerProvider]. An Edit button
/// pushes the edit form; saving there updates this view live.
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
import '../../data/models/owner_center.dart';
import '../../data/models/subject_option.dart';

/// Owner Center tab.
class ManageCenterScreen extends HookConsumerWidget {
  /// Creates the read view.
  const ManageCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ManageCenterState state = ref.watch(manageCenterControllerProvider);
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final OwnerCenter? center = state.center;

    Widget body;
    if (center == null && state.isLoading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sp48),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (center == null) {
      body = _LoadError(
        message: state.errorMessage ?? AppStrings.centerLoadError,
        onRetry: () => ref.read(manageCenterControllerProvider.notifier).load(),
      );
    } else {
      body = _CenterBody(center: center);
    }

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
                          if (center != null) ...<Widget>[
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sp24),
                    body,
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

/// The loaded centre's sections.
class _CenterBody extends StatelessWidget {
  const _CenterBody({required this.center});

  final OwnerCenter center;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String description = (center.description ?? '').trim().isEmpty
        ? AppStrings.centerNotSet
        : center.description!.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _StatsStrip(center: center),
        const SizedBox(height: AppSpacing.sp16),
        _IdentityCard(center: center),
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
        if (center.subjects.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sp24),
          _SectionTitle(title: AppStrings.centerSectionSubjects),
          const SizedBox(height: AppSpacing.sp12),
          _ReadChips(
            labels: center.subjects
                .map((SubjectOption s) => s.name)
                .where((String n) => n.isNotEmpty)
                .toList(),
          ),
        ],
        if (center.boards.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sp24),
          _SectionTitle(title: AppStrings.centerSectionBoards),
          const SizedBox(height: AppSpacing.sp12),
          _ReadChips(labels: center.boards),
        ],
        if (center.classRange != null &&
            !center.classRange!.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sp24),
          _SectionTitle(title: AppStrings.centerSectionClasses),
          const SizedBox(height: AppSpacing.sp12),
          _ReadChips(labels: <String>[_classRangeLabel(center.classRange!)]),
        ],
        const SizedBox(height: AppSpacing.sp24),
        _SectionTitle(title: AppStrings.centerSectionTimings),
        const SizedBox(height: AppSpacing.sp12),
        _TimingsCard(timings: center.timings),
        const SizedBox(height: AppSpacing.sp24),
        _SectionTitle(title: AppStrings.centerSectionContact),
        const SizedBox(height: AppSpacing.sp12),
        _ContactCard(center: center),
        const SizedBox(height: AppSpacing.sp24),
        _SectionTitle(title: AppStrings.centerSectionFees),
        const SizedBox(height: AppSpacing.sp12),
        _Card(child: _FeesText(fees: center.fees)),
      ],
    );
  }
}

/// Read-only rating / reviews strip.
class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.center});

  final OwnerCenter center;

  @override
  Widget build(BuildContext context) {
    return NeoSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sp16),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _Stat(
                value: center.averageRating.toStringAsFixed(1),
                label: AppStrings.centerStatRating,
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _Stat(
                value: center.totalReviews.toString(),
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

/// Logo, name, and location.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.center});

  final OwnerCenter center;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final String initial =
        center.name.isEmpty ? '?' : center.name[0].toUpperCase();
    final String location = _locationLabel(center);
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.ownerAccent,
              borderRadius: BorderRadius.circular(AppSpacing.sp16),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
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
                if (location.isNotEmpty) ...<Widget>[
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
                          location,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only accent-tinted chips (subjects / boards / classes).
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

/// Read-only weekly timings list (empty-state when none set).
class _TimingsCard extends StatelessWidget {
  const _TimingsCard({required this.timings});

  final List<CenterTiming> timings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    if (timings.isEmpty) {
      return _Card(
        child: Text(
          AppStrings.centerNotSet,
          style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
        ),
      );
    }
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

/// Phone, alternate phone, email, website, and address rows.
class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.center});

  final OwnerCenter center;

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

/// Fee range text (or an empty state).
class _FeesText extends StatelessWidget {
  const _FeesText({required this.fees});

  final CenterFees? fees;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;
    final CenterFees? f = fees;
    if (f == null || f.isEmpty) {
      return Text(
        AppStrings.centerNotSet,
        style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
      );
    }
    return Text(
      _feeRangeLabel(f),
      style: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.priceGreen,
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

/// Outset neomorphic surface used for most content sections.
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

/// Inline load-failure state with a retry button.
class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
    );
  }
}

/// Joins area + city into a single "Area, City" label (dropping empties).
String _locationLabel(OwnerCenter c) {
  return <String>[c.area ?? '', c.city]
      .map((String s) => s.trim())
      .where((String s) => s.isNotEmpty)
      .join(', ');
}

/// "Class 6–10" / "From Class 6" / "Up to Class 10".
String _classRangeLabel(CenterClassRange r) {
  if (r.from != null && r.to != null) {
    return '${AppStrings.centerClassPrefix}${r.from}–${r.to}';
  }
  if (r.from != null) return '${AppStrings.centerClassPrefix}${r.from}+';
  return '${AppStrings.centerClassPrefix}${r.to}';
}

/// "₹1,000 – ₹5,000".
String _feeRangeLabel(CenterFees f) {
  final String sym = f.currency == 'INR' ? '₹' : '${f.currency} ';
  final String? lo =
      f.min == null ? null : '$sym${_withCommas(f.min!.round())}';
  final String? hi =
      f.max == null ? null : '$sym${_withCommas(f.max!.round())}';
  if (lo != null && hi != null) return '$lo${AppStrings.centerFeeRangeSep}$hi';
  return lo ?? hi ?? AppStrings.centerNotSet;
}

/// "4:00 PM to 7:00 PM" or "Closed".
String _timingLabel(CenterTiming t) {
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
