/// Single quick-action button: a tinted icon, a label, and a chevron, on a
/// tappable embossed neomorphic surface card.
library;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_palette.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/neo_surface.dart';

/// A shortcut tile on the dashboard. Renders [icon] in an [accent]-tinted
/// circle next to [label] and forwards taps via [onTap]. The accent defaults to
/// the owner brand orange so the action grid reads as one branded cluster.
class QuickActionWidget extends StatelessWidget {
  const QuickActionWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.ownerAccent,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return NeoSurface(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.sp16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sp16),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.sp12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: AppSpacing.sp12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: palette.iconFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
