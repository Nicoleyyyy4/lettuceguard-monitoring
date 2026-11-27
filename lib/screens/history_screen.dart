import 'package:flutter/material.dart';
import '../models/chart_parameter.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../utils/colors.dart';
import '../utils/responsive.dart';
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historical Parameter Trends',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: LettuceGuardColors.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.isDemoMode
                                  ? 'Demo history • Simulated readings for testing.'
                                  : 'Firebase history • Latest ${SensorProvider.historyLimit} stored snapshots by key. Live source: ${provider.liveSource.name}.',
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
                      if (!provider.isDemoMode) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: provider.isHistoryLoading
                              ? null
                              : provider.refreshHistory,
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          label: const Text('Refresh history'),
                        ),
                      ],
                    ],
                  ),

                  if (provider.isHistoryLoading) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(minHeight: 4),
                    ),
                  ],

                  if (provider.historyError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LettuceGuardColors.statusError.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: LettuceGuardColors.statusError.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      child: Text(
                        '${provider.historyError} ${history.isEmpty ? '' : 'Showing previously loaded Firebase records.'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: LettuceGuardColors.statusError,
                        ),
                      ),
                    ),
                  ],

                  if (provider.skippedHistoryRecords > 0 ||
                      provider.duplicateHistoryRecords > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${provider.skippedHistoryRecords} malformed or undated records excluded; '
                      '${provider.duplicateHistoryRecords} exact duplicates omitted.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: LettuceGuardColors.textSecondary(context),
                      ),
                    ),
                  ],

                  if (history.any((d) => d.timestampFromHistoryKey)) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Legacy uptime records use Firebase key creation time (stored time).',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: LettuceGuardColors.textSecondary(context),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Parameter Selector Chips (Wrap on wide screens, horizontal scroll on compact)
                  if (isExpanded)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ChartParameter.values
                          .map((p) => _buildParamChip(context, p))
                          .toList(),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ChartParameter.values
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildParamChip(context, p),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 18),

                  // Split layout on desktop web, stacked on mobile/tablet
                  if (isExpanded)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: ChartWidget(
                            dataPoints: history,
                            selectedParameter: param,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: _buildActivityLogPanel(
                            context,
                            param: param,
                            history: history,
                            visible: visible,
                            validCount: validCount,
                            isLoading: provider.isHistoryLoading,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ChartWidget(dataPoints: history, selectedParameter: param),
                    const SizedBox(height: 20),
                    _buildActivityLogPanel(
                      context,
                      param: param,
                      history: history,
                      visible: visible,
                      validCount: validCount,
                      isLoading: provider.isHistoryLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityLogPanel(
    BuildContext context, {
    required ChartParameter param,
    required List<SensorData> history,
    required List<SensorData> visible,
    required int validCount,
    required bool isLoading,
  }) {
    final isDark = LettuceGuardColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity Log • ${param.title}',
          key: const ValueKey('activity-log-title'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: LettuceGuardColors.textPrimary(context),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Showing ${visible.length} of ${history.length} loaded entries • $validCount valid ${param.chipLabel} readings',
          style: TextStyle(
            fontSize: 12,
            color: LettuceGuardColors.textSecondary(context),
          ),
        ),
        Text(
          'Chart covers all loaded entries; log shows the newest 15.',
          style: TextStyle(
            fontSize: 11,
            color: LettuceGuardColors.textSecondary(context),
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty && !isLoading)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surface(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  size: 32,
                  color: LettuceGuardColors.textSecondary(
                    context,
                  ).withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'No activity yet. Historical readings will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
              ],
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
            final val = param.valueOf(log);
            final inOptimal =
                val != null &&
                val >= param.minOptimal &&
                val <= param.maxOptimal;

            return Container(
              decoration: BoxDecoration(
                color: LettuceGuardColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LettuceGuardColors.border(context)),
              ),
              child: Material(
                type: MaterialType.transparency,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: Container(
                  width: 42,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: param.color.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: param.color,
                    ),
                  ),
                ),
                title: Text(
                  param.reading(log),
                  key: ValueKey('activity-reading-$index'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
                subtitle: Text(
                  '${log.timestampFromHistoryKey ? 'Stored' : 'Recorded'}: ${historyTimestamp(time)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
                trailing: val == null
                    ? const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: LettuceGuardColors.statusError,
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: inOptimal
                              ? LettuceGuardColors.statusOk
                              : LettuceGuardColors.statusWarning,
                        ),
                      ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildParamChip(BuildContext context, ChartParameter param) {
    final selected = _selectedParam == param;
    final surface = LettuceGuardColors.surface(context);
    final border = LettuceGuardColors.border(context);

    return FilterChip(
      key: ValueKey('parameter-${param.name}'),
      selected: selected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: Icon(
        param.icon,
        size: 16,
        color: selected ? Colors.white : param.color,
      ),
      label: Text(param.chipLabel),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : LettuceGuardColors.textPrimary(context),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
      selectedColor: param.color,
      backgroundColor: surface,
      side: BorderSide(color: selected ? param.color : border),
      onSelected: (_) => setState(() => _selectedParam = param),
    );
  }
}
