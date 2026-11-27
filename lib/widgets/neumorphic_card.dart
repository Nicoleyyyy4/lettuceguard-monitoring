import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Refined modern soft-surface container (dark & light mode aware).
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool isInset;
  final double distance;
  final double blur;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.backgroundColor,
    this.isInset = false,
    this.distance = 6.0,
    this.blur = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LettuceGuardColors.isDark(context);
    final bg =
        backgroundColor ??
        (isInset
            ? LettuceGuardColors.surfaceElevated(context)
            : LettuceGuardColors.surface(context));

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: LettuceGuardColors.border(
            context,
          ).withValues(alpha: isInset ? 0.9 : 0.75),
          width: 1,
        ),
        boxShadow: isInset
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : LettuceGuardColors.primaryGreenDark.withValues(
                          alpha: 0.08,
                        ),
                  offset: Offset(0, distance),
                  blurRadius: blur,
                ),
              ],
      ),
      child: child,
    );
  }
}
