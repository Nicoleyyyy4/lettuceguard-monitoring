import 'package:flutter/material.dart';

/// Responsive screen size categories and adaptive layout helpers.
enum ScreenSizeClass { compact, medium, expanded }

class LettuceGuardResponsive {
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;
  static const double wideBreakpoint = 1360;

  static ScreenSizeClass of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedBreakpoint) return ScreenSizeClass.expanded;
    if (width >= compactBreakpoint) return ScreenSizeClass.medium;
    return ScreenSizeClass.compact;
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compactBreakpoint && w < expandedBreakpoint;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expandedBreakpoint;

  static bool isDesktopAuth(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expandedBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 24);
    }
    if (width >= compactBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 14);
  }

  static int sensorGridColumns(double availableWidth) {
    if (availableWidth >= 900) return 3;
    if (availableWidth >= 560) return 3;
    if (availableWidth < 310) return 1;
    return 2;
  }

  static double sensorGridAspectRatio(double availableWidth, int columns) {
    final tileWidth = (availableWidth - (columns - 1) * 14) / columns;
    // Target a comfortable vertical card height around 176-188 px
    final targetHeight = columns == 1 ? 168.0 : (columns == 3 ? 186.0 : 180.0);
    return (tileWidth / targetHeight).clamp(0.88, 1.85);
  }
}

/// Centers content with a clean maximum readable width on wide web viewports.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1320,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? LettuceGuardResponsive.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
