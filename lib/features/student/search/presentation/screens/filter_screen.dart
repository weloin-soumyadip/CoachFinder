/// Full-screen filter editor - subject, city, board, rating, and fees range.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/neo_button.dart';
import '../../data/controllers/search_provider.dart';
import '../../data/models/filter_model.dart';

/// Minimum-rating presets offered as chips (null = "Any").
const List<double?> _ratingOptions = <double?>[null, 3.0, 4.0, 4.5];

/// Full-screen editor for the student search filters. Seeds its draft state
/// once from the active [SearchFilters], then on Apply builds a fresh
/// `SearchFilters` (preserving the current query `q`) and calls
/// `applyFilters`, popping back to the results.
class FilterScreen extends HookConsumerWidget {
  /// Creates the filter editor screen.
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final initial = ref.read(searchControllerProvider).filters;

    final subjectCtrl = useTextEditingController(text: initial.subject ?? '');
    final cityCtrl = useTextEditingController(text: initial.city ?? '');
    final minFeesCtrl =
        useTextEditingController(text: initial.minFees?.toString() ?? '');
    final maxFeesCtrl =
        useTextEditingController(text: initial.maxFees?.toString() ?? '');
    final board = useState<SearchBoard?>(initial.board);
    final minRating = useState<double?>(initial.minRating);

    String? trimmedOrNull(TextEditingController c) {
      final String t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    void apply() {
      final String? q = ref.read(searchControllerProvider).filters.q;
      final filters = SearchFilters(
        q: q,
        subject: trimmedOrNull(subjectCtrl),
        city: trimmedOrNull(cityCtrl),
        board: board.value,
        minRating: minRating.value,
        minFees: int.tryParse(minFeesCtrl.text.trim()),
        maxFees: int.tryParse(maxFeesCtrl.text.trim()),
      );
      ref.read(searchControllerProvider.notifier).applyFilters(filters);
      context.pop();
    }

    void reset() {
      subjectCtrl.clear();
      cityCtrl.clear();
      minFeesCtrl.clear();
      maxFeesCtrl.clear();
      board.value = null;
      minRating.value = null;
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text(AppStrings.filterTitle),
        actions: <Widget>[
          TextButton(
            onPressed: reset,
            child: const Text(AppStrings.filterReset),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.sp16),
              children: <Widget>[
                const _FieldLabel(label: AppStrings.filterSubjectLabel),
                _TextField(
                  controller: subjectCtrl,
                  hint: AppStrings.filterSubjectHint,
                ),
                const SizedBox(height: AppSpacing.sp24),
                const _FieldLabel(label: AppStrings.filterCityLabel),
                _TextField(
                  controller: cityCtrl,
                  hint: AppStrings.filterCityHint,
                ),
                const SizedBox(height: AppSpacing.sp24),
                const _FieldLabel(label: AppStrings.filterBoardLabel),
                Wrap(
                  spacing: AppSpacing.sp8,
                  runSpacing: AppSpacing.sp8,
                  children: <Widget>[
                    _ChoicePill(
                      label: AppStrings.filterAny,
                      selected: board.value == null,
                      onTap: () => board.value = null,
                    ),
                    for (final b in SearchBoard.values)
                      _ChoicePill(
                        label: b.wireValue,
                        selected: board.value == b,
                        onTap: () => board.value = b,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp24),
                const _FieldLabel(label: AppStrings.filterRatingLabel),
                Wrap(
                  spacing: AppSpacing.sp8,
                  runSpacing: AppSpacing.sp8,
                  children: <Widget>[
                    for (final r in _ratingOptions)
                      _ChoicePill(
                        label: r == null
                            ? AppStrings.filterAny
                            : '${r.toStringAsFixed(1)}${AppStrings.filterRatingSuffix}',
                        selected: minRating.value == r,
                        onTap: () => minRating.value = r,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp24),
                const _FieldLabel(label: AppStrings.filterFeesLabel),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _TextField(
                        controller: minFeesCtrl,
                        hint: AppStrings.filterMinFeesHint,
                        numeric: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sp12),
                    Expanded(
                      child: _TextField(
                        controller: maxFeesCtrl,
                        hint: AppStrings.filterMaxFeesHint,
                        numeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sp32),
                NeoButton(
                  onPressed: apply,
                  filled: true,
                  accent: AppColors.studentPrimary,
                  child: const Text(AppStrings.filterApply),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bold label shown above each filter field.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sp8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.palette.textPrimary,
            ),
      ),
    );
  }
}

/// A filled text field used for the subject / city / fees inputs.
class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.numeric = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: palette.textMuted),
        filled: true,
        fillColor: palette.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp16,
          vertical: AppSpacing.sp12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sp12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Selectable pill used for the board + rating choices.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
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
      color: selected ? AppColors.studentPrimary : palette.surface,
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
              color: selected ? AppColors.studentPrimary : palette.borderSubtle,
            ),
          ),
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
  }
}
