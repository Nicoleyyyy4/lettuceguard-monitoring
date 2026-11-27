import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../models/chart_parameter.dart';
import '../utils/colors.dart';
import '../utils/responsive.dart';
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
    if (_series.records.isEmpty || width <= 0) return;
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
    final isDark = LettuceGuardColors.isDark(context);
    final isExpanded = LettuceGuardResponsive.isExpanded(context);
    final chartHeight = isExpanded ? 250.0 : 196.0;

    return Container(
      decoration: BoxDecoration(
        color: LettuceGuardColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LettuceGuardColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: LettuceGuardColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with parameter badge and optimal range pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: param.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(param.icon, color: param.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        param.chartTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LettuceGuardColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Configured optimal zone: ${param.formatValue(param.minOptimal)} – ${param.formatValue(param.maxOptimal)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Y: ${param.axisUnit} • X: local time • ${_series.validCount} valid readings',
                        style: TextStyle(
                          fontSize: 11,
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_series.validCount == 0)
              Container(
                height: chartHeight,
                decoration: BoxDecoration(
                  color: LettuceGuardColors.surfaceElevated(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 36,
                        color: LettuceGuardColors.textSecondary(
                          context,
                        ).withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          records.isEmpty
                              ? 'No historical records available.'
                              : 'No valid ${param.chipLabel} measurements available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: LettuceGuardColors.textSecondary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(8, 12, 12, 12),
                decoration: BoxDecoration(
                  color: LettuceGuardColors.surfaceElevated(
                    context,
                  ).withValues(alpha: isDark ? 0.55 : 0.65),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: LettuceGuardColors.border(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
                ),
                child: SizedBox(
                  height: chartHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _series.maxY.toStringAsFixed(param.decimals),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: LettuceGuardColors.textSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                ((_series.maxY + _series.minY) / 2)
                                    .toStringAsFixed(param.decimals),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: LettuceGuardColors.textSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                _series.minY.toStringAsFixed(param.decimals),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  color: LettuceGuardColors.textSecondary(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return MouseRegion(
                              cursor: SystemMouseCursors.precise,
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
                                  size: Size(constraints.maxWidth, chartHeight),
                                  painter: _LineChartPainter(
                                    _series,
                                    _selected,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (records.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      historyTimestamp(records.first.timestamp),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: LettuceGuardColors.textSecondary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      historyTimestamp(records.last.timestamp),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: LettuceGuardColors.textSecondary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Inspection Pill Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: param.color.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: param.color.withValues(alpha: isDark ? 0.3 : 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selected == null
                        ? Icons.touch_app_rounded
                        : Icons.analytics_rounded,
                    size: 15,
                    color: param.color,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selected == null
                          ? 'Tap or hover to inspect a reading.'
                          : '${historyTimestamp(records[_selected!].timestamp)} • ${param.reading(records[_selected!])}',
                      key: const ValueKey('chart-inspection'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: param.color,
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
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.series, this.selected, {required this.isDark});
  final HistoryChartData series;
  final int? selected;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final param = series.parameter;
    double y(double value) => series.yFraction(value) * size.height;

    // Optimal band fill + boundary lines
    final topOpt = y(param.maxOptimal);
    final botOpt = y(param.minOptimal);
    final zone = Paint()
      ..color = LettuceGuardColors.primaryGreen.withValues(
        alpha: isDark ? 0.16 : 0.09,
      );
    canvas.drawRect(Rect.fromLTRB(0, topOpt, size.width, botOpt), zone);

    final zoneEdge = Paint()
      ..color = LettuceGuardColors.primaryGreen.withValues(
        alpha: isDark ? 0.35 : 0.22,
      )
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, topOpt), Offset(size.width, topOpt), zoneEdge);
    canvas.drawLine(Offset(0, botOpt), Offset(size.width, botOpt), zoneEdge);

    // Subtle horizontal grid lines
    final grid = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (final fraction in [.25, .5, .75]) {
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        grid,
      );
    }

    // Build contiguous segments for area gradient fill + smooth line stroke
    final linePaint = Paint()
      ..color = param.color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          param.color.withValues(alpha: isDark ? 0.28 : 0.20),
          param.color.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pointsPaint = Paint()..color = param.color;
    final haloPaint = Paint()..color = param.color.withValues(alpha: 0.24);
    final innerDot = Paint()
      ..color = isDark ? LettuceGuardColors.darkCardSurface : Colors.white;

    // Draw crosshair for selected index
    if (selected != null && selected! < series.records.length) {
      final selX = series.xFraction(selected!) * size.width;
      final crossPaint = Paint()
        ..color = param.color.withValues(alpha: 0.35)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(selX, 0), Offset(selX, size.height), crossPaint);
    }

    final segment = <Offset>[];
    void flushSegment() {
      if (segment.length >= 2) {
        final fillPath = Path()..moveTo(segment.first.dx, size.height);
        final strokePath = Path()..moveTo(segment.first.dx, segment.first.dy);
        for (final pt in segment) {
          fillPath.lineTo(pt.dx, pt.dy);
        }
        for (var i = 1; i < segment.length; i++) {
          strokePath.lineTo(segment[i].dx, segment[i].dy);
        }
        fillPath
          ..lineTo(segment.last.dx, size.height)
          ..close();
        canvas.drawPath(fillPath, areaPaint);
        canvas.drawPath(strokePath, linePaint);
      }
      segment.clear();
    }

    final validPoints = <(int, Offset)>[];
    for (var i = 0; i < series.values.length; i++) {
      final value = series.values[i];
      if (value == null) {
        flushSegment();
        continue;
      }
      final point = Offset(series.xFraction(i) * size.width, y(value));
      segment.add(point);
      validPoints.add((i, point));
    }
    flushSegment();

    for (final (i, point) in validPoints) {
      if (selected == i) {
        canvas.drawCircle(point, 10, haloPaint);
        canvas.drawCircle(point, 5.5, pointsPaint);
        canvas.drawCircle(point, 2.5, innerDot);
      } else {
        canvas.drawCircle(point, 3.5, pointsPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.selected != selected ||
      oldDelegate.isDark != isDark;
}
