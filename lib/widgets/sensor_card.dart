import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color themeColor;
  final bool isError;
  final bool isWarning;
  final String? alertMessage;
  final String? targetRange;
  final VoidCallback? onTap;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    this.unit = '',
    required this.icon,
    required this.themeColor,
    this.isError = false,
    this.isWarning = false,
    this.alertMessage,
    this.targetRange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorderColor = LettuceGuardColors.borderLight;
    Color statusBadgeBg = LettuceGuardColors.primaryGreen.withOpacity(0.12);
    Color statusTextColor = LettuceGuardColors.primaryGreen;
    String statusText = 'Optimal';

    if (isError) {
      cardBorderColor = LettuceGuardColors.statusError;
      statusBadgeBg = LettuceGuardColors.statusError.withOpacity(0.12);
      statusTextColor = LettuceGuardColors.statusError;
      statusText = 'SENSOR ERROR';
    } else if (isWarning) {
      cardBorderColor = LettuceGuardColors.statusWarning;
      statusBadgeBg = LettuceGuardColors.statusWarning.withOpacity(0.12);
      statusTextColor = LettuceGuardColors.statusWarning;
      statusText = 'Out of Range';
    }

    return Card(
      elevation: isError || isWarning ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cardBorderColor, width: isError || isWarning ? 2 : 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon, Title, and Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isError ? LettuceGuardColors.statusError : themeColor).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 22,
                      color: isError ? LettuceGuardColors.statusError : themeColor,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: LettuceGuardColors.textMuted,
                ),
              ),

              const SizedBox(height: 4),

              // Primary Reading Value + Unit
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isError ? 'ERR' : value,
                      style: TextStyle(
                        fontSize: isError ? 22 : 24,
                        fontWeight: FontWeight.bold,
                        color: isError
                            ? LettuceGuardColors.statusError
                            : (isWarning ? LettuceGuardColors.statusWarning : LettuceGuardColors.textDark),
                      ),
                    ),

                    if (!isError && unit.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: LettuceGuardColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Target Range / Error Message footer
              if (isError && alertMessage != null)
                Text(
                  alertMessage!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: LettuceGuardColors.statusError,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (targetRange != null)
                Text(
                  'Optimal: $targetRange',
                  style: const TextStyle(
                    fontSize: 10,
                    color: LettuceGuardColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
