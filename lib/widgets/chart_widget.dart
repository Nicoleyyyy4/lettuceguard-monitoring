import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../utils/colors.dart';

enum ChartParameter { airTemp, humidity, waterTemp, ph, waterLevel }

class ChartWidget extends StatelessWidget {
  final List<SensorData> dataPoints;
  final ChartParameter selectedParameter;

  const ChartWidget({
    super.key,
    required this.dataPoints,
    required this.selectedParameter,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text(
          'No historical records available.',
          style: TextStyle(color: LettuceGuardColors.textMuted),
        ),
      );
    }

    String title;
    String unit;
    Color lineColor;
    double minOptimal;
    double maxOptimal;

    switch (selectedParameter) {
      case ChartParameter.airTemp:
        title = 'Air Temperature History';
        unit = '°C';
        lineColor = LettuceGuardColors.airTempColor;
        minOptimal = 18.0;
        maxOptimal = 26.0;
        break;
      case ChartParameter.humidity:
        title = 'Air Humidity History';
        unit = '%';
        lineColor = LettuceGuardColors.humidityColor;
        minOptimal = 50.0;
        maxOptimal = 70.0;
        break;
      case ChartParameter.waterTemp:
        title = 'Water Temperature History';
        unit = '°C';
        lineColor = LettuceGuardColors.waterTempColor;
        minOptimal = 18.0;
        maxOptimal = 22.0;
        break;
      case ChartParameter.ph:
        title = 'pH Level History';
        unit = 'pH';
        lineColor = LettuceGuardColors.phColor;
        minOptimal = 5.5;
        maxOptimal = 6.5;
        break;
      case ChartParameter.waterLevel:
        title = 'Reservoir Water Level History';
        unit = '%';
        lineColor = LettuceGuardColors.waterLevelColor;
        minOptimal = 25.0;
        maxOptimal = 100.0;
        break;
    }

    final values = dataPoints.map((d) {
      switch (selectedParameter) {
        case ChartParameter.airTemp:
          return d.airTemperature;
        case ChartParameter.humidity:
          return d.airHumidity;
        case ChartParameter.waterTemp:
          return d.waterTemperature;
        case ChartParameter.ph:
          return d.ph;
        case ChartParameter.waterLevel:
          return d.waterLevelPct;
      }
    }).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: LettuceGuardColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lineColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Optimal Zone: $minOptimal - $maxOptimal $unit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: lineColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: values,
                  lineColor: lineColor,
                  minOptimal: minOptimal,
                  maxOptimal: maxOptimal,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Past 12 Hours',
                    style: TextStyle(fontSize: 10, color: LettuceGuardColors.textMuted)),
                Text('Now',
                    style: TextStyle(fontSize: 10, color: LettuceGuardColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final double minOptimal;
  final double maxOptimal;

  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.minOptimal,
    required this.maxOptimal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);

    minY = (minY < minOptimal ? minY : minOptimal) - 1.0;
    maxY = (maxY > maxOptimal ? maxY : maxOptimal) + 1.0;

    final double rangeY = (maxY - minY) == 0 ? 1.0 : (maxY - minY);

    // Draw Grid & Optimal Zone
    final Paint gridPaint = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double optimalTopY = size.height - ((maxOptimal - minY) / rangeY * size.height);
    final double optimalBottomY = size.height - ((minOptimal - minY) / rangeY * size.height);

    final Paint fillOptimalPaint = Paint()
      ..color = LettuceGuardColors.primaryGreen.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTRB(0, optimalTopY.clamp(0.0, size.height), size.width, optimalBottomY.clamp(0.0, size.height)),
      fillOptimalPaint,
    );

    // Grid lines
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    // Draw Line Graph
    final Path path = Path();
    final Path fillPath = Path();

    final double dx = size.width / (values.length - 1 > 0 ? values.length - 1 : 1);

    for (int i = 0; i < values.length; i++) {
      final double x = i * dx;
      final double y = size.height - ((values[i] - minY) / rangeY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        colors: [lineColor.withOpacity(0.3), lineColor.withOpacity(0.01)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, areaPaint);
    canvas.drawPath(path, linePaint);

    // Draw data points
    final Paint pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final double x = i * dx;
      final double y = size.height - ((values[i] - minY) / rangeY * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.minOptimal != minOptimal ||
        oldDelegate.maxOptimal != maxOptimal;
  }
}
