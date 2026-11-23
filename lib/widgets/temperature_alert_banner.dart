import 'package:flutter/material.dart';
import '../models/temperature_level.dart';
import '../providers/sensor_provider.dart';
import '../utils/colors.dart';
import '../models/chart_parameter.dart' show historyTimestamp;

Color temperatureAlertColor(TemperatureLevel level) => switch (level) {
  TemperatureLevel.normal => LettuceGuardColors.statusOk,
  TemperatureLevel.low => const Color(0xFF1565C0),
  TemperatureLevel.high => const Color(0xFFAD5000),
  TemperatureLevel.critical => const Color(0xFFC43E00),
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
        final level = event?.temperatureLevel ?? rawLevel;
        final color = problem != null && event == null
            ? LettuceGuardColors.textMuted
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
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.isDemoMode ? 'DEMO • ' : ''}${event?.title ?? (problem == null ? level.title : 'AIR TEMPERATURE UNAVAILABLE')}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  value == null
                      ? 'Current Air Temperature: Unavailable'
                      : 'Current Air Temperature: $value°C',
                  style: const TextStyle(color: LettuceGuardColors.textDark),
                ),
                if (confirming)
                  const Text(
                    'Confirming consecutive sensor readings before opening an event.',
                    style: TextStyle(color: LettuceGuardColors.textDark),
                  ),
                if (event != null || confirming)
                  Text(
                    level.action,
                    style: const TextStyle(color: LettuceGuardColors.textDark),
                  ),
                if (problem != null)
                  Text(
                    '$problem ${event == null ? '' : 'The active condition remains unresolved.'}',
                    style: const TextStyle(color: LettuceGuardColors.textDark),
                  ),
                if (event?.isAcknowledged == true)
                  const Text(
                    'Acknowledged • Condition remains active until confirmed recovery.',
                    style: TextStyle(color: LettuceGuardColors.textDark),
                  ),
                if (event == null &&
                    problem == null &&
                    !confirming &&
                    recovered?.resolvedAt != null)
                  Text(
                    'Confirmed recovery: ${historyTimestamp(recovered!.resolvedAt!)}',
                    style: const TextStyle(color: LettuceGuardColors.textDark),
                  ),
                if (provider.temperatureSyncError != null)
                  Text(
                    provider.temperatureSyncError!,
                    style: const TextStyle(
                      color: LettuceGuardColors.statusError,
                    ),
                  ),
                if (provider.hasPendingTemperatureSync &&
                    provider.temperatureSyncError == null)
                  const Text(
                    'Saving alert changes…',
                    style: TextStyle(color: LettuceGuardColors.textMuted),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
