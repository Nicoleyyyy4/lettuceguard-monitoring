import 'package:flutter/material.dart';
import '../utils/colors.dart';

/// Reusable Neumorphic UI Container Card Box
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color backgroundColor;
  final bool isInset;
  final double distance;
  final double blur;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.backgroundColor = LettuceGuardColors.neuBackground,
    this.isInset = false,
    this.distance = 6.0,
    this.blur = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1.2,
        ),
        boxShadow: isInset
            ? [
                BoxShadow(
                  color: LettuceGuardColors.neuShadowDark.withOpacity(0.6),
                  offset: Offset(distance, distance),
                  blurRadius: blur,
                ),
                BoxShadow(
                  color: LettuceGuardColors.neuShadowLight.withOpacity(0.9),
                  offset: Offset(-distance, -distance),
                  blurRadius: blur,
                ),
              ]
            : [
                BoxShadow(
                  color: LettuceGuardColors.neuShadowDark,
                  offset: Offset(distance, distance),
                  blurRadius: blur,
                ),
                BoxShadow(
                  color: LettuceGuardColors.neuShadowLight,
                  offset: Offset(-distance, -distance),
                  blurRadius: blur,
                ),
              ],
      ),
      child: child,
    );
  }
}
