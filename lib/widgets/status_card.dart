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
    Color bgGradientStart;
    Color bgGradientEnd;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    if (status == 'ERROR') {
      bgGradientStart = const Color(0xFFFFEBEE);
      bgGradientEnd = const Color(0xFFFFCDD2);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = 'SENSOR ERROR DETECTED';
      statusDesc = '$errorCount hardware sensor fault(s) need attention.';
    } else if (status == 'WARNING') {
      bgGradientStart = const Color(0xFFFFF3E0);
      bgGradientEnd = const Color(0xFFFFE0B2);
      statusIcon = Icons.error_outline_rounded;
      statusTitle = 'PARAMETER WARNING';
      statusDesc = 'Hydroponic parameters outside optimal range.';
    } else {
      bgGradientStart = const Color(0xFFE8F5E9);
      bgGradientEnd = const Color(0xFFC8E6C9);
      statusIcon = Icons.eco_rounded;
      statusTitle = 'SYSTEM NORMAL';
      statusDesc = 'Hydroponic environment fully optimized.';
    }

    final formattedTime =
        '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}:${lastUpdated.second.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onAlertTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgGradientStart, bgGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (status == 'ERROR'
                      ? LettuceGuardColors.statusError
                      : (status == 'WARNING'
                          ? LettuceGuardColors.statusWarning
                          : LettuceGuardColors.statusOk))
                  .withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
                    color: status == 'ERROR'
                        ? LettuceGuardColors.statusError
                        : (status == 'WARNING'
                            ? LettuceGuardColors.statusWarning
                            : LettuceGuardColors.statusOk),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              statusTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: status == 'ERROR'
                                    ? LettuceGuardColors.statusError
                                    : (status == 'WARNING'
                                        ? LettuceGuardColors.statusWarning
                                        : LettuceGuardColors.statusOk),
                              ),
                            ),
                          ),

                          // Online pulse status pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isConnected ? Colors.green.shade800 : Colors.red.shade800,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 3,
                                  backgroundColor: isConnected ? Colors.greenAccent : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isConnected ? 'ONLINE' : 'OFFLINE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: LettuceGuardColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: LettuceGuardColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Last updated: $formattedTime',
                      style: const TextStyle(
                        fontSize: 11,
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),
                  ],
                ),

                if (errorCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: LettuceGuardColors.statusError,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$errorCount Alert(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
