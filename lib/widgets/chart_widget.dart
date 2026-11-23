import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../models/chart_parameter.dart';
import '../utils/colors.dart';
export '../models/chart_parameter.dart' show ChartParameter;

class ChartWidget extends StatefulWidget {
  final List<SensorData> dataPoints;
  final ChartParameter selectedParameter;
  const ChartWidget({
    super.key,
    required this.dataPoints,
    required this.selectedParameter,
  });
  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  late HistoryChartData _series;
  int? _selected;
  @override
  void initState() {
    super.initState();
    _project();
  }

  void _project() {
    _series = HistoryChartData(widget.dataPoints, widget.selectedParameter);
    _selected = null;
  }

  @override
  void didUpdateWidget(ChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints != widget.dataPoints ||
        oldWidget.selectedParameter != widget.selectedParameter) {
      _project();
    }
  }

  void _inspect(double x, double width) {
    int? nearest;
    var distance = double.infinity;
    for (var i = 0; i < _series.records.length; i++) {
      final delta = (_series.xFraction(i) * width - x).abs();
      if (delta < distance) {
        distance = delta;
        nearest = i;
      }
    }
    if (nearest != _selected) setState(() => _selected = nearest);
  }

  @override
  Widget build(BuildContext context) {
    final param = widget.selectedParameter;
    final records = _series.records;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              param.chartTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: LettuceGuardColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Configured optimal zone: ${param.formatValue(param.minOptimal)} – ${param.formatValue(param.maxOptimal)}',
              style: const TextStyle(
                fontSize: 11,
                color: LettuceGuardColors.textMuted,
              ),
            ),
            Text(
              'Y: ${param.axisUnit} • X: local time • ${_series.validCount} valid readings',
              style: const TextStyle(
                fontSize: 11,
                color: LettuceGuardColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            if (_series.validCount == 0)
              SizedBox(
                height: 180,
                child: Center(
                  child: Text(
                    records.isEmpty
                        ? 'No historical records available.'
                        : 'No valid ${param.chipLabel} measurements available.',
                  ),
                ),
              )
            else
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _series.maxY.toStringAsFixed(param.decimals),
                            style: const TextStyle(
                              fontSize: 10,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),
                          Text(
                            ((_series.maxY + _series.minY) / 2).toStringAsFixed(
                              param.decimals,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),
                          Text(
                            _series.minY.toStringAsFixed(param.decimals),
                            style: const TextStyle(
                              fontSize: 10,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return MouseRegion(
                            onHover: (event) => _inspect(
                              event.localPosition.dx,
                              constraints.maxWidth,
                            ),
                            child: GestureDetector(
                              key: const ValueKey('history-chart-plot'),
                              onTapDown: (event) => _inspect(
                                event.localPosition.dx,
                                constraints.maxWidth,
                              ),
                              onHorizontalDragUpdate: (event) => _inspect(
                                event.localPosition.dx,
                                constraints.maxWidth,
                              ),
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, 180),
                                painter: _LineChartPainter(_series, _selected),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      historyTimestamp(records.first.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      historyTimestamp(records.last.timestamp),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 10,
                        color: LettuceGuardColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _selected == null
                  ? 'Tap or hover to inspect a reading.'
                  : '${historyTimestamp(records[_selected!].timestamp)} • ${param.reading(records[_selected!])}',
              key: const ValueKey('chart-inspection'),
              style: TextStyle(fontSize: 12, color: param.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.series, this.selected);
  final HistoryChartData series;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final param = series.parameter;
    double y(double value) => series.yFraction(value) * size.height;
    final zone = Paint()
      ..color = LettuceGuardColors.primaryGreen.withValues(alpha: .08);
    canvas.drawRect(
      Rect.fromLTRB(0, y(param.maxOptimal), size.width, y(param.minOptimal)),
      zone,
    );
    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (final fraction in [.25, .5, .75]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        grid,
      );
    }
    final line = Paint()
      ..color = param.color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final points = Paint()..color = param.color;
    Offset? previous;
    for (var i = 0; i < series.values.length; i++) {
      final value = series.values[i];
      if (value == null) {
        previous = null;
        continue;
      }
      final point = Offset(series.xFraction(i) * size.width, y(value));
      if (previous != null) canvas.drawLine(previous, point, line);
      canvas.drawCircle(point, selected == i ? 6 : 3.5, points);
      previous = point;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.selected != selected;
}
