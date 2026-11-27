import 'package:flutter/material.dart';
import '../utils/colors.dart';

class StatusCard extends StatelessWidget {
  final String status; // OK, WARNING, ERROR
  final int errorCount;
  final bool isConnected;
  final DateTime lastUpdated;
  final VoidCallback? onAlertTap;

  const StatusCard({
    super.key,
    required this.status,
    required this.errorCount,
    required this.isConnected,
    required this.lastUpdated,
    this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = LettuceGuardColors.isDark(context);

    late final Color accentColor;
    late final Color bgStart;
    late final Color bgEnd;
    late final IconData statusIcon;
    late final String statusTitle;
    late final String statusDesc;

    if (status == 'ERROR') {
      accentColor = LettuceGuardColors.statusError;
      bgStart = isDark ? const Color(0xFF2B1416) : const Color(0xFFFEF2F2);
      bgEnd = isDark ? const Color(0xFF3A181B) : const Color(0xFFFEE2E2);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'SENSOR ERROR DETECTED';
      statusDesc = '$errorCount hardware sensor fault(s) need attention.';
    } else if (status == 'WARNING') {
      accentColor = LettuceGuardColors.statusWarning;
      bgStart = isDark ? const Color(0xFF2C1D10) : const Color(0xFFFFF7ED);
      bgEnd = isDark ? const Color(0xFF3A2412) : const Color(0xFFFFEDD5);
      statusIcon = Icons.error_outline_rounded;
      statusTitle = 'PARAMETER WARNING';
      statusDesc = 'Hydroponic parameters outside optimal range.';
    } else {
      accentColor = LettuceGuardColors.statusOk;
      bgStart = isDark ? const Color(0xFF12281D) : const Color(0xFFECFDF5);
      bgEnd = isDark ? const Color(0xFF173626) : const Color(0xFFD1FAE5);
      statusIcon = Icons.eco_rounded;
      statusTitle = 'SYSTEM NORMAL';
      statusDesc = 'Hydroponic environment fully optimized.';
    }

    final formattedTime =
        '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}:${lastUpdated.second.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onAlertTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgStart, bgEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.14 : 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: isDark
                          ? accentColor.withValues(alpha: 0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.14),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Icon(statusIcon, color: accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              statusTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                letterSpacing: 0.3,
                                color: accentColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? LettuceGuardColors.primaryGreenDark
                                    : LettuceGuardColors.statusError,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? LettuceGuardColors.accentLightGreen
                                          : const Color(0xFFFCA5A5),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isConnected ? 'ONLINE' : 'OFFLINE',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusDesc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: LettuceGuardColors.textPrimary(context),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: accentColor.withValues(alpha: isDark ? 0.2 : 0.14),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: LettuceGuardColors.textSecondary(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Last updated: $formattedTime',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  if (errorCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: LettuceGuardColors.statusError,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$errorCount Alert(s)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
