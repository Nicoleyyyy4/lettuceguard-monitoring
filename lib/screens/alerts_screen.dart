import 'package:flutter/material.dart';
import '../providers/sensor_provider.dart';
import '../models/alert_model.dart';
import '../utils/colors.dart';
import '../utils/responsive.dart';
import '../widgets/temperature_alert_banner.dart';
import '../models/chart_parameter.dart' show historyTimestamp;
import '../models/temperature_level.dart';
import '../models/sensor_model.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        final alerts = provider.alerts;
        final activeCount = alerts.where((a) => !a.isResolved).length;
        final resolvedCount = alerts.where((a) => a.isResolved).length;
        final isExpanded = LettuceGuardResponsive.isExpanded(context);

        return Scaffold(
          backgroundColor: LettuceGuardColors.canvas(context),
          body: SingleChildScrollView(
            child: ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Diagnostics & Alerts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: LettuceGuardColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$activeCount Active Alert(s)',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: LettuceGuardColors.textSecondary(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (alerts.any((a) => a.isResolved))
                        OutlinedButton.icon(
                          onPressed: provider.clearResolvedAlerts,
                          icon: const Icon(
                            Icons.cleaning_services_rounded,
                            size: 16,
                          ),
                          label: const Text('Clear Resolved'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (isExpanded)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 370,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TemperatureOverviewCard(
                                data: provider.currentData,
                                isConnected: provider.isConnected,
                                isDemoMode: provider.isDemoMode,
                              ),
                              const SizedBox(height: 14),
                              _AlertSummaryRow(
                                activeCount: activeCount,
                                resolvedCount: resolvedCount,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: _buildAlertsFeed(context, provider, alerts),
                        ),
                      ],
                    )
                  else ...[
                    _TemperatureOverviewCard(
                      data: provider.currentData,
                      isConnected: provider.isConnected,
                      isDemoMode: provider.isDemoMode,
                    ),
                    const SizedBox(height: 14),
                    _buildAlertsFeed(context, provider, alerts),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsFeed(
    BuildContext context,
    SensorProvider provider,
    List<AlertModel> alerts,
  ) {
    final isDark = LettuceGuardColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.temperatureSyncError != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LettuceGuardColors.statusError.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: LettuceGuardColors.statusError.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              provider.temperatureSyncError!,
              style: const TextStyle(
                color: LettuceGuardColors.statusError,
                fontSize: 12.5,
              ),
            ),
          ),
        if (provider.temperatureDataProblem != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surfaceElevated(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Text(
              provider.temperatureDataProblem!,
              style: TextStyle(
                color: LettuceGuardColors.textSecondary(context),
                fontSize: 12.5,
              ),
            ),
          ),
        if (provider.isDemoMode)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: LettuceGuardColors.tdsColor.withValues(
                alpha: isDark ? 0.14 : 0.10,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LettuceGuardColors.tdsColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: LettuceGuardColors.tdsColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DEMO \u2022 Simulated alerts; never saved to production.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LettuceGuardColors.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (alerts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: LettuceGuardColors.statusOk.withValues(
                      alpha: isDark ? 0.16 : 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 46,
                    color: LettuceGuardColors.statusOk,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  provider.temperatureDataProblem == null
                      ? 'All Hardware Sensors Operational'
                      : 'Waiting for valid sensor data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No hardware error flags or range violations reported.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildAlertCard(context, alerts[index]),
          ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertModel alert) {
    final isDark = LettuceGuardColors.isDark(context);
    final textPrimary = LettuceGuardColors.textPrimary(context);
    final textSecondary = LettuceGuardColors.textSecondary(context);

    Color cardBorder;
    Color iconBg;
    IconData icon;

    if (alert.isResolved) {
      cardBorder = LettuceGuardColors.border(context);
      iconBg = LettuceGuardColors.surfaceElevated(context);
      icon = Icons.check_circle_rounded;
    } else if (alert.isTemperatureAlert) {
      cardBorder = temperatureAlertColor(alert.temperatureLevel!);
      iconBg = cardBorder.withValues(alpha: isDark ? 0.22 : 0.12);
      icon = Icons.thermostat_rounded;
    } else if (alert.severity == AlertSeverity.error) {
      cardBorder = LettuceGuardColors.statusError;
      iconBg = LettuceGuardColors.statusError.withValues(
        alpha: isDark ? 0.22 : 0.12,
      );
      icon = Icons.warning_amber_rounded;
    } else {
      cardBorder = LettuceGuardColors.statusWarning;
      iconBg = LettuceGuardColors.statusWarning.withValues(
        alpha: isDark ? 0.22 : 0.12,
      );
      icon = Icons.info_outline_rounded;
    }

    final timeFormatted =
        '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}:${alert.timestamp.second.toString().padLeft(2, '0')}';

    return DefaultTextStyle.merge(
      style: TextStyle(color: textPrimary),
      child: Container(
        decoration: BoxDecoration(
          color: alert.isResolved
              ? LettuceGuardColors.surfaceElevated(
                  context,
                ).withValues(alpha: isDark ? 0.55 : 0.7)
              : LettuceGuardColors.surface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: cardBorder,
            width: alert.isResolved ? 1 : 1.5,
          ),
          boxShadow: alert.isResolved
              ? null
              : [
                  BoxShadow(
                    color: cardBorder.withValues(alpha: isDark ? 0.16 : 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: alert.isResolved ? textSecondary : cardBorder,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${alert.isDemo ? 'DEMO \u2022 ' : ''}${alert.title}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: alert.isResolved
                                  ? textSecondary
                                  : textPrimary,
                              decoration: alert.isResolved
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: alert.isResolved
                                ? LettuceGuardColors.surfaceElevated(context)
                                : cardBorder.withValues(
                                    alpha: isDark ? 0.22 : 0.12,
                                  ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            alert.isResolved ? 'RESOLVED' : alert.sensorSource,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: alert.isResolved
                                  ? textSecondary
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
                        fontSize: 12.5,
                        height: 1.4,
                        color: alert.isResolved ? textSecondary : textPrimary,
                      ),
                    ),
                    if (alert.isTemperatureAlert) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Status: ${alert.isResolved ? 'Resolved' : 'Active'} \u2022 ${alert.isAcknowledged ? 'Acknowledged' : 'Not acknowledged'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: alert.isResolved ? textSecondary : cardBorder,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configured threshold: ${alert.configuredThreshold?.toStringAsFixed(1)}\u00b0C',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      if (alert.readingTimestamp != null)
                        Text(
                          'Sensor reading: ${historyTimestamp(alert.readingTimestamp!)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      if (alert.acknowledgedAt != null)
                        Text(
                          'Acknowledged: ${historyTimestamp(alert.acknowledgedAt!)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      if (alert.resolvedAt != null)
                        Text(
                          'Recovered: ${historyTimestamp(alert.resolvedAt!)}',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      Text(
                        'Peak severity: ${TemperatureLevel.values.where((level) => level.priority == alert.peakPriority).firstOrNull?.name ?? 'unknown'}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Temperature event history',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          children: alert.transitions
                              .where((entry) => entry['temperature'] is num)
                              .map(
                                (entry) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    '${entry['level']}: ${(entry['temperature'] as num).toStringAsFixed(1)}°C',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    historyTimestamp(
                                      DateTime.fromMillisecondsSinceEpoch(
                                        (entry['readingTimestamp'] as num)
                                            .toInt(),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
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
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _AlertSummaryRow extends StatelessWidget {
  final int activeCount;
  final int resolvedCount;

  const _AlertSummaryRow({
    required this.activeCount,
    required this.resolvedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeCount.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: activeCount > 0
                        ? LettuceGuardColors.statusError
                        : LettuceGuardColors.statusOk,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESOLVED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  resolvedCount.toString(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TemperatureOverviewCard extends StatelessWidget {
  const _TemperatureOverviewCard({
    required this.data,
    required this.isConnected,
    required this.isDemoMode,
  });

  final SensorData data;
  final bool isConnected;
  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    final pumpStatus = data.waterPumpActive
        ? 'PUMP CIRCULATING'
        : data.waterPumpReason == 'low_or_unavailable_water_level'
        ? 'PUMP PAUSED · LOW WATER'
        : data.waterPumpReason == 'status_unavailable' && !isDemoMode
        ? 'UPDATE ESP32 FIRMWARE'
        : 'PUMP ON STANDBY';
    final pumpColor = data.waterPumpActive
        ? LettuceGuardColors.accentLightGreen
        : data.waterPumpReason == 'low_or_unavailable_water_level'
        ? const Color(0xFFFDE68A)
        : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LettuceGuardColors.heroGradient(context),
        boxShadow: [
          BoxShadow(
            color: LettuceGuardColors.primaryGreenDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.device_thermostat_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CLIMATE CONTROL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (isDemoMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TemperatureReadout(
                  icon: Icons.air_rounded,
                  label: 'AIR · DHT22',
                  value: data.hasValidAirTemperature
                      ? data.airTemperature
                      : null,
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white24),
              Expanded(
                child: _TemperatureReadout(
                  icon: Icons.water_drop_outlined,
                  label: 'NUTRIENT · DS18B20',
                  value: !data.ds18b20Error && data.waterTemperature.isFinite
                      ? data.waterTemperature
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.waterPumpActive
                          ? Icons.sync_rounded
                          : Icons.water_drop_outlined,
                      color: pumpColor,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pumpStatus,
                      style: TextStyle(
                        color: pumpColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'AUTO 23°C ON · 22°C OFF',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureReadout extends StatelessWidget {
  const _TemperatureReadout({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value == null ? '—' : '${value!.toStringAsFixed(1)}°C',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );
}
