import 'package:flutter/material.dart';
import '../providers/sensor_provider.dart';
import '../utils/colors.dart';
import '../widgets/chart_widget.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ChartParameter _selectedParam = ChartParameter.ph;

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);
    final history = provider.history;

    return Scaffold(
      backgroundColor: LettuceGuardColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historical Parameter Trends',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: LettuceGuardColors.textDark,
              ),
            ),
            const Text(
              'Real-time data logs recorded from Firebase Realtime Database.',
              style: TextStyle(
                fontSize: 12,
                color: LettuceGuardColors.textMuted,
              ),
            ),

            const SizedBox(height: 16),

            // Parameter Selector Horizontal Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildParamChip('pH Level', ChartParameter.ph, Icons.science, LettuceGuardColors.phColor),
                  _buildParamChip('Water Temp', ChartParameter.waterTemp, Icons.device_thermostat, LettuceGuardColors.waterTempColor),
                  _buildParamChip('Air Temp', ChartParameter.airTemp, Icons.thermostat, LettuceGuardColors.airTempColor),
                  _buildParamChip('Humidity', ChartParameter.humidity, Icons.water_drop, LettuceGuardColors.humidityColor),
                  _buildParamChip('Water Level', ChartParameter.waterLevel, Icons.waves, LettuceGuardColors.waterLevelColor),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Time-series Chart Widget
            ChartWidget(
              dataPoints: history,
              selectedParameter: _selectedParam,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity Log',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LettuceGuardColors.textDark,
                  ),
                ),
                Text(
                  '${history.length} Entries',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LettuceGuardColors.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Historical Data Table / List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 15 ? 15 : history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                // Reverse to show most recent at top
                final log = history[history.length - 1 - index];
                final timeStr =
                    '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: LettuceGuardColors.primaryGreen.withOpacity(0.12),
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: LettuceGuardColors.primaryGreen,
                        ),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('pH: ${log.ph.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Water: ${log.waterTemperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 12)),
                        Text('Air: ${log.airTemperature.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Humidity: ${log.airHumidity.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, color: LettuceGuardColors.textMuted)),
                        Text('Level: ${log.waterLevelPct.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, color: LettuceGuardColors.textMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParamChip(
    String label,
    ChartParameter param,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedParam == param;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : LettuceGuardColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        selectedColor: color,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? color : LettuceGuardColors.borderLight,
        ),
        onSelected: (_) {
          setState(() {
            _selectedParam = param;
          });
        },
      ),
    );
  }
}
