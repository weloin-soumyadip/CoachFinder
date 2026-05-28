/// Outset / inset neomorphic surface for the soft-and-premium design system.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_effects.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_spacing.dart';

/// A soft neomorphic surface — outset (lifted off the page) by default, or
/// inset (recessed) via [inset]. Calibrated for the "soft & premium" intensity:
/// subtle dual shadows on outset; the inset variant paints true neumorphic
/// inset shadows (dark feathered along the top + left interior, light along
/// the bottom + right) via a [CustomPainter] — the project's Flutter doesn't
/// support `BoxShadow(inset: true)`, so we draw the equivalent by hand.
///
/// In dark mode the "light" shadow is intentionally faint — there is no real
/// light source to fake — so a 1 px [AppPalette.borderSubtle] edge is added
/// for definition.
///
/// The outer fill defaults to [AppPalette.surface] (or [AppPalette.inputFill]
/// for the inset variant); pass [fill] to override (e.g. an accent fill for an
/// embossed brand badge).
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.sp16),
    this.radius = AppSpacing.sp16,
    this.inset = false,
    this.fill,
  });

  /// Foreground content painted inside the surface.
  final Widget child;

  /// Padding between the surface edge and [child].
  final EdgeInsets padding;

  /// Corner radius in logical pixels.
  final double radius;

  /// When `true`, the surface is drawn as a recessed neumorphic well:
  /// [AppPalette.inputFill] background + a hand-painted inset shadow.
  final bool inset;

  /// Override fill color. Defaults to [AppPalette.surface] (outset) or
  /// [AppPalette.inputFill] (inset).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background =
        fill ?? (inset ? palette.inputFill : palette.surface);

    if (inset) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: ColoredBox(color: background)),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NeoInsetShadowPainter(
                    shadowDark: palette.neoShadowDark,
                    shadowLight: palette.neoShadowLight,
                    radius: radius,
                  ),
                ),
              ),
            ),
            if (isDark)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: palette.borderSubtle),
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      );
    }

    final List<BoxShadow> shadows = <BoxShadow>[
      BoxShadow(
        color: palette.neoShadowDark,
        offset: AppEffects.neoOutsetOffsetDark,
        blurRadius: AppEffects.neoOutsetBlur,
      ),
      BoxShadow(
        color: palette.neoShadowLight,
        offset: AppEffects.neoOutsetOffsetLight,
        blurRadius: AppEffects.neoOutsetBlur,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border: isDark ? Border.all(color: palette.borderSubtle) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Paints a soft inset (recessed) shadow inside a rounded rectangle.
///
/// Trick: clip the canvas to the rounded rect, then stroke two shifted RRect
/// outlines with [MaskFilter.blur]. After clipping, only the edges that
/// "bleed into" the original rect remain visible — the top + left for the
/// dark "weight" shadow (shifted down-right) and the bottom + right for the
/// light highlight (shifted up-left). The result reads as if light were
/// falling on a recessed well.
class _NeoInsetShadowPainter extends CustomPainter {
  _NeoInsetShadowPainter({
    required this.shadowDark,
    required this.shadowLight,
    required this.radius,
  });

  final Color shadowDark;
  final Color shadowLight;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    canvas.save();
    canvas.clipRRect(rrect);

    // Dark "weight" shadow on the top + left interior: stroke a copy of the
    // rect shifted DOWN-RIGHT. After clipping, only the top and left strokes
    // remain visible inside the clip.
    final Paint darkPaint = Paint()
      ..color = shadowDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(rrect.shift(const Offset(4, 4)), darkPaint);

    // Light "highlight" on the bottom + right interior: stroke a copy shifted
    // UP-LEFT.
    final Paint lightPaint = Paint()
      ..color = shadowLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rrect.shift(const Offset(-4, -4)), lightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NeoInsetShadowPainter old) {
    return old.shadowDark != shadowDark ||
        old.shadowLight != shadowLight ||
        old.radius != radius;
  }
}
