/// Reusable staggered entrance animation: fade + slide-up.
library;

import 'package:flutter/material.dart';

/// Fades and slides [child] up as [animation] crosses the [start]..[end]
/// window (values in 0..1 of the driving controller). Lets one
/// `AnimationController` stagger many elements via per-item [Interval]s without
/// allocating a `CurvedAnimation` per child or a controller per widget.
///
/// Typical use: a screen creates `useAnimationController(...)`, plays it once on
/// mount, and wraps each section in an `EntranceFadeSlide` with an increasing
/// [start].
class EntranceFadeSlide extends StatelessWidget {
  const EntranceFadeSlide({
    super.key,
    required this.animation,
    required this.start,
    required this.end,
    required this.child,
    this.offsetY = 18,
  });

  /// The driving animation (usually an `AnimationController`).
  final Animation<double> animation;

  /// Window within the parent animation (0..1) over which this item animates.
  final double start;
  final double end;

  /// Initial downward offset (logical px) the child slides up from.
  final double offsetY;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = Interval(start, end, curve: Curves.easeOutCubic)
            .transform(animation.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offsetY),
            child: child,
          ),
        );
      },
    );
  }
}
