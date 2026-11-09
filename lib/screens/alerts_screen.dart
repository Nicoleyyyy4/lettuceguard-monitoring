import 'package:flutter/material.dart';
import '../providers/sensor_provider.dart';
import '../models/alert_model.dart';
import '../utils/colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);

    // I-wrap ang buong screen sa ListenableBuilder para mag-rebuild kapag may bagong alerto o nagbago ang state
    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        final alerts = provider.alerts;

        return Scaffold(
          backgroundColor: LettuceGuardColors.background,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'System Diagnostics & Alerts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: LettuceGuardColors.textDark,
                          ),
                        ),
                        Text(
                          '${alerts.where((a) => !a.isResolved).length} Active Alert(s)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: LettuceGuardColors.textMuted,
                          ),
                        ),
                      ],
                    ),

                    if (alerts.any((a) => a.isResolved))
                      TextButton.icon(
                        onPressed: () {
                          provider.clearResolvedAlerts();
                        },
                        icon: const Icon(Icons.cleaning_services, size: 16),
                        label: const Text('Clear Resolved'),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                if (alerts.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 70,
                            color: LettuceGuardColors.primaryGreen.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All Hardware Sensors Operational',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: LettuceGuardColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No hardware error flags or range violations reported.',
                            style: TextStyle(
                              fontSize: 12,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildAlertCard(context, alert);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertModel alert) {
    Color cardBorder;
    Color iconBg;
    IconData icon;

    if (alert.isResolved) {
      cardBorder = LettuceGuardColors.borderLight;
      iconBg = Colors.grey.shade300;
      icon = Icons.check_circle;
    } else if (alert.severity == AlertSeverity.error) {
      cardBorder = LettuceGuardColors.statusError;
      iconBg = LettuceGuardColors.statusError.withValues(alpha: 0.12);
      icon = Icons.warning_amber_rounded;
    } else {
      cardBorder = LettuceGuardColors.statusWarning;
      iconBg = LettuceGuardColors.statusWarning.withValues(alpha: 0.12);
      icon = Icons.info_outline_rounded;
    }

    final timeFormatted =
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}:${alert.timestamp.second.toString().padLeft(2, '0')}';

    return Card(
      elevation: alert.isResolved ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cardBorder,
          width: alert.isResolved ? 1 : 1.5,
        ),
      ),
      color: alert.isResolved ? Colors.grey.shade50 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: alert.isResolved
                    ? Colors.grey
                    : (alert.severity == AlertSeverity.error
                    ? LettuceGuardColors.statusError
                    : LettuceGuardColors.statusWarning),
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: alert.isResolved
                                ? Colors.grey
                                : LettuceGuardColors.textDark,
                            decoration: alert.isResolved
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: alert.isResolved
                              ? Colors.grey.shade200
                              : cardBorder.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          alert.isResolved ? 'RESOLVED' : alert.sensorSource,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: alert.isResolved ? Colors.grey : cardBorder,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: alert.isResolved
                          ? Colors.grey
                          : LettuceGuardColors.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Logged at $timeFormatted',
                    style: const TextStyle(
                      fontSize: 10,
                      color: LettuceGuardColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}