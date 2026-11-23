import 'package:flutter/material.dart';
import '../models/chart_parameter.dart';
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
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final history = provider.history;
        final visible = history.reversed.take(15).toList();
        final param = _selectedParam;
        final validCount = history
            .where((d) => param.valueOf(d) != null)
            .length;
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
                Text(
                  provider.isDemoMode
                      ? 'Demo history • Simulated readings for testing.'
                      : 'Firebase history • Latest ${SensorProvider.historyLimit} stored snapshots by key. Live source: ${provider.liveSource.name}.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LettuceGuardColors.textMuted,
                  ),
                ),
                if (!provider.isDemoMode)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: provider.isHistoryLoading
                          ? null
                          : provider.refreshHistory,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh history'),
                    ),
                  ),
                if (provider.isHistoryLoading) const LinearProgressIndicator(),
                if (provider.historyError != null)
                  Text(
                    '${provider.historyError} ${history.isEmpty ? '' : 'Showing previously loaded Firebase records.'}',
                    style: const TextStyle(
                      color: LettuceGuardColors.statusError,
                    ),
                  ),
                if (provider.skippedHistoryRecords > 0 ||
                    provider.duplicateHistoryRecords > 0)
                  Text(
                    '${provider.skippedHistoryRecords} malformed or undated records excluded; '
                    '${provider.duplicateHistoryRecords} exact duplicates omitted.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: LettuceGuardColors.textMuted,
                    ),
                  ),
                if (history.any((d) => d.timestampFromHistoryKey))
                  const Text(
                    'Legacy uptime records use Firebase key creation time (stored time).',
                    style: TextStyle(
                      fontSize: 11,
                      color: LettuceGuardColors.textMuted,
                    ),
                  ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ChartParameter.values
                        .map(_buildParamChip)
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ChartWidget(dataPoints: history, selectedParameter: param),
                const SizedBox(height: 20),
                Text(
                  'Recent Activity Log • ${param.title}',
                  key: const ValueKey('activity-log-title'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: LettuceGuardColors.textDark,
                  ),
                ),
                Text(
                  'Showing ${visible.length} of ${history.length} loaded entries • $validCount valid ${param.chipLabel} readings',
                  style: const TextStyle(
                    fontSize: 12,
                    color: LettuceGuardColors.textMuted,
                  ),
                ),
                const Text(
                  'Chart covers all loaded entries; log shows the newest 15.',
                  style: TextStyle(
                    fontSize: 11,
                    color: LettuceGuardColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                if (history.isEmpty && !provider.isHistoryLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No activity yet. Historical readings will appear here.',
                    ),
                  ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = visible[index];
                    final time = log.timestamp.toLocal();
                    final timeStr =
                        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: LettuceGuardColors.borderLight,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: param.color.withValues(alpha: .12),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: param.color,
                            ),
                          ),
                        ),
                        title: Text(
                          param.reading(log),
                          key: ValueKey('activity-reading-$index'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: LettuceGuardColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${log.timestampFromHistoryKey ? 'Stored' : 'Recorded'}: ${historyTimestamp(time)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: LettuceGuardColors.textMuted,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParamChip(ChartParameter param) {
    final selected = _selectedParam == param;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: ValueKey('parameter-${param.name}'),
        selected: selected,
        showCheckmark: false,
        avatar: Icon(
          param.icon,
          size: 16,
          color: selected ? Colors.white : param.color,
        ),
        label: Text(param.chipLabel),
        labelStyle: TextStyle(
          color: selected ? Colors.white : LettuceGuardColors.textDark,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        selectedColor: param.color,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? param.color : LettuceGuardColors.borderLight,
        ),
        onSelected: (_) => setState(() => _selectedParam = param),
      ),
    );
  }
}
