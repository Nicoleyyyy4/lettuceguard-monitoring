import 'package:flutter/material.dart';
import '../utils/colors.dart';

class WaterLevelCard extends StatelessWidget {
  final double percentage; // e.g. 85.0%
  final double
  distanceCm; // distance from HC-SR04 to water surface (e.g. 4.5 cm)
  final double reservoirDepthCm; // total height (e.g. 30.0 cm)
  final bool isError;
  final bool isLow;

  const WaterLevelCard({
    super.key,
    required this.percentage,
    required this.distanceCm,
    this.reservoirDepthCm = 30.0,
    this.isError = false,
    this.isLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LettuceGuardColors.isDark(context);
    final fillRatio = isError ? 0.0 : (percentage / 100.0).clamp(0.0, 1.0);

    Color gaugeColor = LettuceGuardColors.waterLevelColor;
    Color statusColor = LettuceGuardColors.statusOk;
    String statusLabel = 'SUFFICIENT';

    if (isError) {
      gaugeColor = LettuceGuardColors.statusError;
      statusColor = LettuceGuardColors.statusError;
      statusLabel = 'HC-SR04 ERROR';
    } else if (isLow) {
      gaugeColor = LettuceGuardColors.statusWarning;
      statusColor = LettuceGuardColors.statusWarning;
      statusLabel = 'LOW WATER';
    }

    return Container(
      decoration: BoxDecoration(
        color: LettuceGuardColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isError
              ? LettuceGuardColors.statusError
              : (isLow
                    ? LettuceGuardColors.statusWarning
                    : LettuceGuardColors.border(context)),
          width: isError || isLow ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LettuceGuardColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: gaugeColor.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.waves_rounded,
                          color: gaugeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reservoir Water Level',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: LettuceGuardColors.textPrimary(context),
                              ),
                            ),
                            Text(
                              'HC-SR04 Ultrasonic Tank Monitor',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: LettuceGuardColors.textSecondary(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Visual Tank Capsule + Metrics Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mini Vertical Liquid Tank Indicator
                Container(
                  width: 44,
                  height: 76,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: LettuceGuardColors.surfaceElevated(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: gaugeColor.withValues(alpha: 0.35),
                      width: 1.4,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      heightFactor: fillRatio,
                      widthFactor: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gaugeColor.withValues(alpha: 0.72),
                              gaugeColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Main Percentage & Distance Stat Chips
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isError
                                    ? 'ERR'
                                    : '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: isError
                                      ? LettuceGuardColors.statusError
                                      : (isLow
                                            ? LettuceGuardColors.statusWarning
                                            : LettuceGuardColors.textPrimary(
                                                context,
                                              )),
                                ),
                              ),
                              Text(
                                'Volume Capacity',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LettuceGuardColors.textSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: LettuceGuardColors.surfaceElevated(
                                context,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: LettuceGuardColors.border(context),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isError
                                      ? 'N/A'
                                      : '${distanceCm.toStringAsFixed(1)} cm',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: LettuceGuardColors.textPrimary(
                                      context,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Sensor Distance',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: LettuceGuardColors.textSecondary(
                                      context,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Animated Liquid Gauge Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: fillRatio,
                          minHeight: 10,
                          backgroundColor: LettuceGuardColors.surfaceElevated(
                            context,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  'Tank Depth: ${reservoirDepthCm.toInt()} cm',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
                Text(
                  'Sensor: HC-SR04 Ultrasonic',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
