/// Pressable neomorphic affordance — animates from outset shadows to a settled,
/// accent-tinted state on press/select.
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A neomorphic, pressable surface that settles when tapped or selected. Used
/// for primary CTAs, role tiles, OAuth buttons, and any "press to act"
/// affordance in the soft-and-premium design system.
///
/// - [filled] `true` → accent-fill primary (white label / icon).
/// - [filled] `false` → surface-fill secondary, label / icon coloured by
///   [accent] (defaults to `palette.primary`).
/// - [selected] true → sticky settled state. Used by toggle-like tiles
///   (the onboarding role selector) where the press IS the selection signal.
///
/// **Fallback note:** the project's Flutter doesn't support
/// `BoxShadow(inset: true)`, so the pressed / selected look is conveyed by
/// dropping the outset shadows (so the button visually settles into the
/// surface) plus an accent-tinted background and accent border on selected
/// non-filled buttons. Animated via `AnimatedContainer`.
///
/// Disable by passing `onPressed: null`.
class NeoButton extends HookWidget {
  const NeoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.filled = false,
    this.accent,
    this.selected = false,
    this.height = 52,
    this.radius = AppSpacing.sp12,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sp16),
  });

  /// Tap handler. `null` disables the button.
  final VoidCallback? onPressed;

  /// Foreground content (typically a `Row` of icon + label, or just text).
  final Widget child;

  /// `true` → accent-fill primary. `false` → surface-fill secondary.
  final bool filled;

  /// Brand accent. Defaults to `context.palette.primary`.
  final Color? accent;

  /// Sticky settled (selected) state for toggle-like tiles.
  final bool selected;

  /// Tap-target height. Default 52 (matches existing auth buttons).
  final double height;

  /// Corner radius. Default [AppSpacing.sp12].
  final double radius;

  /// Horizontal padding around [child].
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color brand = accent ?? palette.primary;
    final ValueNotifier<bool> pressed = useState<bool>(false);
    final bool enabled = onPressed != null;
    final bool settled = selected || pressed.value;

    final Color background = filled
        ? (enabled ? brand : palette.border)
        : (selected ? brand.withValues(alpha: 0.08) : palette.surface);

    final List<BoxShadow>? shadows = settled
        ? null
        : <BoxShadow>[
            BoxShadow(
              color: palette.neoShadowDark,
              offset: AppEffects.neoOutsetOffsetDark,
              blurRadius: AppEffects.neoOutsetBlur,
            ),
            if (!filled)
              BoxShadow(
                color: palette.neoShadowLight,
                offset: AppEffects.neoOutsetOffsetLight,
                blurRadius: AppEffects.neoOutsetBlur,
              ),
          ];

    final BoxBorder? border = !filled && selected
        ? Border.all(color: brand, width: 1.5)
        : (!filled && isDark ? Border.all(color: palette.borderSubtle) : null);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => pressed.value = true : null,
      onTapUp: enabled ? (_) => pressed.value = false : null,
      onTapCancel: enabled ? () => pressed.value = false : null,
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: AppEffects.neoPressDuration,
        curve: Curves.easeOut,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadows,
          border: border,
        ),
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: filled
                  ? (enabled ? AppColors.neutralWhite : palette.textMuted)
                  : brand,
              fontWeight: FontWeight.w700,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: filled ? AppColors.neutralWhite : brand,
                size: 20,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
