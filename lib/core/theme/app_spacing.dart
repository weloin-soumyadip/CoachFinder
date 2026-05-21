/// Spacing constants on the 8px grid (sp4 through sp48).
library;

/// Spacing tokens used for padding, margins, and gaps. Anchored on a 4/8 px
/// grid so layouts compose predictably.
abstract final class AppSpacing {
  AppSpacing._();

  static const double sp4 = 4;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp48 = 48;
}
