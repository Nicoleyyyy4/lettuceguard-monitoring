import 'package:flutter/material.dart';
import '../providers/sensor_provider.dart';
import '../models/alert_model.dart';
import '../utils/colors.dart';
import '../widgets/temperature_alert_banner.dart';
import '../models/chart_parameter.dart' show historyTimestamp;
import '../models/temperature_level.dart';

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
                    Expanded(
                      child: Column(
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

                if (provider.temperatureSyncError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      provider.temperatureSyncError!,
                      style: const TextStyle(
                        color: LettuceGuardColors.statusError,
                      ),
                    ),
                  ),
                if (provider.temperatureDataProblem != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      provider.temperatureDataProblem!,
                      style: const TextStyle(
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),
                  ),
                if (provider.isDemoMode)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'DEMO \u2022 Simulated alerts; never saved to production.',
                    ),
                  ),
                if (alerts.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 70,
                            color: LettuceGuardColors.primaryGreen.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            provider.temperatureDataProblem == null
                                ? 'All Hardware Sensors Operational'
                                : 'Waiting for valid sensor data',
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
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
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
    } else if (alert.isTemperatureAlert) {
      cardBorder = temperatureAlertColor(alert.temperatureLevel!);
      iconBg = cardBorder.withValues(alpha: .12);
      icon = Icons.thermostat;
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

    return DefaultTextStyle.merge(
      style: const TextStyle(color: LettuceGuardColors.textDark),
      child: Card(
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
                  color: alert.isResolved ? Colors.grey : cardBorder,
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
                            '${alert.isDemo ? 'DEMO \u2022 ' : ''}${alert.title}',
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                              color: alert.isResolved
                                  ? Colors.grey
                                  : cardBorder,
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

                    if (alert.isTemperatureAlert) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${alert.isResolved ? 'Resolved' : 'Active'} \u2022 ${alert.isAcknowledged ? 'Acknowledged' : 'Not acknowledged'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cardBorder,
                        ),
                      ),
                      Text(
                        'Configured threshold: ${alert.configuredThreshold?.toStringAsFixed(1)}\u00b0C',
                      ),
                      if (alert.readingTimestamp != null)
                        Text(
                          'Sensor reading: ${historyTimestamp(alert.readingTimestamp!)}',
                        ),
                      if (alert.acknowledgedAt != null)
                        Text(
                          'Acknowledged: ${historyTimestamp(alert.acknowledgedAt!)}',
                        ),
                      if (alert.resolvedAt != null)
                        Text(
                          'Recovered: ${historyTimestamp(alert.resolvedAt!)}',
                        ),
                      Text(
                        'Peak severity: ${TemperatureLevel.values.where((level) => level.priority == alert.peakPriority).firstOrNull?.name ?? 'unknown'}',
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text(
                          'Temperature event history',
                          style: TextStyle(fontSize: 12),
                        ),
                        children: alert.transitions
                            .where((entry) => entry['temperature'] is num)
                            .map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(
                                  '${entry['level']}: ${(entry['temperature'] as num).toStringAsFixed(1)}°C',
                                ),
                                subtitle: Text(
                                  historyTimestamp(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      (entry['readingTimestamp'] as num)
                                          .toInt(),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (!alert.isResolved && !alert.isAcknowledged)
                        TextButton(
                          onPressed: () => SensorProviderScope.of(context)
                              .acknowledgeTemperatureAlert(
                                alert.id,
                                priority: alert.peakPriority,
                              ),
                          child: const Text('Acknowledge'),
                        ),
                    ],
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
      ),
    );
  }
}
