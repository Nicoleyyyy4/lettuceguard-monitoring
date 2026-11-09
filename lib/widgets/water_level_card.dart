import 'package:flutter/material.dart';
import '../utils/colors.dart';

class WaterLevelCard extends StatelessWidget {
  final double percentage; // e.g. 85.0%
  final double distanceCm; // distance from HC-SR04 to water surface (e.g. 4.5 cm)
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
    Color gaugeColor = LettuceGuardColors.waterLevelColor;
    if (isError) {
      gaugeColor = LettuceGuardColors.statusError;
    } else if (isLow) {
      gaugeColor = LettuceGuardColors.statusWarning;
    }

    return Card(
      elevation: isError || isLow ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isError
              ? LettuceGuardColors.statusError
              : (isLow ? LettuceGuardColors.statusWarning : LettuceGuardColors.borderLight),
          width: isError || isLow ? 2 : 1,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.waves,
                      color: LettuceGuardColors.waterLevelColor,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Reservoir Water Level',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: LettuceGuardColors.textDark,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isError
                        ? LettuceGuardColors.statusError.withOpacity(0.12)
                        : (isLow
                            ? LettuceGuardColors.statusWarning.withOpacity(0.12)
                            : LettuceGuardColors.primaryGreen.withOpacity(0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isError
                        ? 'HC-SR04 ERROR'
                        : (isLow ? 'LOW WATER' : 'SUFFICIENT'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isError
                          ? LettuceGuardColors.statusError
                          : (isLow
                              ? LettuceGuardColors.statusWarning
                              : LettuceGuardColors.primaryGreen),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Percentage & Distance Metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isError ? 'ERR' : '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isError
                            ? LettuceGuardColors.statusError
                            : (isLow ? LettuceGuardColors.statusWarning : LettuceGuardColors.textDark),
                      ),
                    ),
                    const Text(
                      'Volume Capacity',
                      style: TextStyle(
                        fontSize: 12,
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),
                  ],
                ),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: LettuceGuardColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isError ? 'N/A' : '${distanceCm.toStringAsFixed(1)} cm',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: LettuceGuardColors.textDark,
                        ),
                      ),
                      const Text(
                        'Sensor Distance',
                        style: TextStyle(
                          fontSize: 10,
                          color: LettuceGuardColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Animated Visual Liquid Gauge Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: isError ? 0.0 : (percentage / 100.0).clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: LettuceGuardColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tank Depth: ${reservoirDepthCm.toInt()} cm',
                  style: const TextStyle(fontSize: 11, color: LettuceGuardColors.textMuted),
                ),
                Text(
                  'Sensor: HC-SR04 Ultrasonic',
                  style: const TextStyle(fontSize: 11, color: LettuceGuardColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
