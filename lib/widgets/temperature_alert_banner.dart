import 'package:flutter/material.dart';
import '../models/temperature_level.dart';
import '../providers/sensor_provider.dart';
import '../utils/colors.dart';
import '../models/chart_parameter.dart' show historyTimestamp;

Color temperatureAlertColor(TemperatureLevel level) => switch (level) {
  TemperatureLevel.normal => LettuceGuardColors.statusOk,
  TemperatureLevel.low => const Color(0xFF0284C7),
  TemperatureLevel.high => const Color(0xFFD97706),
  TemperatureLevel.critical => const Color(0xFFEA580C),
  TemperatureLevel.extreme => LettuceGuardColors.statusError,
};

class TemperatureAlertBanner extends StatelessWidget {
  const TemperatureAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final event = provider.activeTemperatureAlert;
        final problem = provider.temperatureDataProblem;
        final rawLevel = problem == null
            ? provider.temperatureConfig.classify(
                provider.currentData.airTemperature,
              )
            : TemperatureLevel.normal;
        final confirming = event == null && rawLevel != TemperatureLevel.normal;
        final recovered = provider.alerts
            .where((a) => a.isTemperatureAlert && a.isResolved)
            .firstOrNull;
        if (event == null &&
            problem == null &&
            recovered == null &&
            !confirming &&
            provider.temperatureSyncError == null) {
          return const SizedBox.shrink();
        }
        final isDark = LettuceGuardColors.isDark(context);
        final textPrimary = LettuceGuardColors.textPrimary(context);
        final textSecondary = LettuceGuardColors.textSecondary(context);
        final level = event?.temperatureLevel ?? rawLevel;
        final color = problem != null && event == null
            ? textSecondary
            : temperatureAlertColor(level);
        final value = problem == null
            ? provider.currentData.airTemperature.toStringAsFixed(1)
            : null;
        return Semantics(
          liveRegion: true,
          child: Container(
            key: const ValueKey('temperature-alert-banner'),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.16 : 0.09),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.55 : 0.45),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.24 : 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    problem != null && event == null
                        ? Icons.sensors_off_rounded
                        : (level == TemperatureLevel.normal
                              ? Icons.check_circle_outline_rounded
                              : Icons.thermostat_rounded),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.isDemoMode ? 'DEMO • ' : ''}${event?.title ?? (problem == null ? level.title : 'AIR TEMPERATURE UNAVAILABLE')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        value == null
                            ? 'Current Air Temperature: Unavailable'
                            : 'Current Air Temperature: $value°C',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      if (confirming)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Confirming consecutive sensor readings before opening an event.',
                            style: TextStyle(fontSize: 12, color: textPrimary),
                          ),
                        ),
                      if (event != null || confirming)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            level.action,
                            style: TextStyle(
                              fontSize: 12,
                              color: textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      if (problem != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            '$problem ${event == null ? '' : 'The active condition remains unresolved.'}',
                            style: TextStyle(fontSize: 12, color: textPrimary),
                          ),
                        ),
                      if (event?.isAcknowledged == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Acknowledged • Condition remains active until confirmed recovery.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      if (event == null &&
                          problem == null &&
                          !confirming &&
                          recovered?.resolvedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Confirmed recovery: ${historyTimestamp(recovered!.resolvedAt!)}',
                            style: TextStyle(fontSize: 12, color: textPrimary),
                          ),
                        ),
                      if (provider.temperatureSyncError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            provider.temperatureSyncError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: LettuceGuardColors.statusError,
                            ),
                          ),
                        ),
                      if (provider.hasPendingTemperatureSync &&
                          provider.temperatureSyncError == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            'Saving alert changes…',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
