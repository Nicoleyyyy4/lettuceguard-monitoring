import 'package:flutter/material.dart';

/// Refined Botanical Hydroponic Telemetry Design Palette for LettuceGuard
class LettuceGuardColors {
  // Brand & Accent Colors
  static const Color primaryGreen = Color(0xFF1B7A4E);
  static const Color primaryGreenDark = Color(0xFF0F4C30);
  static const Color primaryGreenBright = Color(0xFF2EB872);
  static const Color accentLightGreen = Color(0xFF6EE7B7);
  static const Color secondaryTeal = Color(0xFF0891B2);

  // Light Mode Surfaces
  static const Color background = Color(0xFFF3F7F4);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedLight = Color(0xFFEAF2EC);
  static const Color borderLight = Color(0xFFDCE7DF);

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0C1510);
  static const Color darkSidebar = Color(0xFF101C16);
  static const Color darkCardSurface = Color(0xFF15241C);
  static const Color darkElevated = Color(0xFF1D3026);
  static const Color darkBorder = Color(0xFF263D31);

  // Neumorphic / Soft-Surface Palette (retained for compatibility)
  static const Color neuBackground = Color(0xFFEBF2ED);
  static const Color neuShadowLight = Color(0xFFFFFFFF);
  static const Color neuShadowDark = Color(0xFFC5D5C9);

  // Sensor Category Colors (balanced & accessible in light and dark modes)
  static const Color airTempColor = Color(0xFFEF4444);
  static const Color humidityColor = Color(0xFF0EA5E9);
  static const Color waterTempColor = Color(0xFFF97316);
  static const Color phColor = Color(0xFF8B5CF6);
  static const Color tdsColor = Color(0xFFD97706);
  static const Color waterLevelColor = Color(0xFF06B6D4);

  // Status & Warning Colors
  static const Color statusOk = Color(0xFF16A34A);
  static const Color statusWarning = Color(0xFFEA580C);
  static const Color statusError = Color(0xFFDC2626);

  // Neutral Text Colors
  static const Color textDark = Color(0xFF112218);
  static const Color textMuted = Color(0xFF536A5C);
  static const Color textLight = Color(0xFFEDF6F0);
  static const Color textMutedDark = Color(0xFF93AC9D);

  // Brightness-aware semantic helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      isDark(context) ? primaryGreenBright : primaryGreen;

  static Color canvas(BuildContext context) =>
      isDark(context) ? darkBackground : background;

  static Color sidebar(BuildContext context) =>
      isDark(context) ? darkSidebar : cardSurface;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkCardSurface : cardSurface;

  static Color surfaceElevated(BuildContext context) =>
      isDark(context) ? darkElevated : elevatedLight;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : borderLight;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? textLight : textDark;

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? textMutedDark : textMuted;

  static Color shadow(BuildContext context) => isDark(context)
      ? Colors.black.withValues(alpha: 0.32)
      : const Color(0xFF0F3D26).withValues(alpha: 0.06);

  static LinearGradient heroGradient(BuildContext context) => isDark(context)
      ? const LinearGradient(
          colors: [Color(0xFF0E3824), Color(0xFF155336), Color(0xFF0F4C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [Color(0xFF0F4C30), Color(0xFF1B7A4E), Color(0xFF0D7A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}
