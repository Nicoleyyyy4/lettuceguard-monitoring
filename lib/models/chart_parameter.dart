import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sensor_model.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

/// Shared metadata for the selector, graph, and parameter-specific activity log.
enum ChartParameter {
  ph(
    'pH Level',
    'pH Level',
    'pH',
    '',
    Icons.science,
    LettuceGuardColors.phColor,
    LettuceGuardConstants.minPh,
    LettuceGuardConstants.maxPh,
    2,
  ),
  waterTemp(
    'Water Temp',
    'Water Temperature',
    'Water Temperature',
    '°C',
    Icons.device_thermostat,
    LettuceGuardColors.waterTempColor,
    LettuceGuardConstants.minWaterTemp,
    LettuceGuardConstants.maxWaterTemp,
    1,
  ),
  airTemp(
    'Air Temp',
    'Air Temperature',
    'Air Temperature',
    '°C',
    Icons.thermostat,
    LettuceGuardColors.airTempColor,
    LettuceGuardConstants.minAirTemp,
    LettuceGuardConstants.maxAirTemp,
    1,
  ),
  humidity(
    'Humidity',
    'Air Humidity',
    'Humidity',
    '%',
    Icons.water_drop,
    LettuceGuardColors.humidityColor,
    LettuceGuardConstants.minAirHumidity,
    LettuceGuardConstants.maxAirHumidity,
    0,
  ),
  waterLevel(
    'Water Level',
    'Reservoir Water Level',
    'Water Level',
    '%',
    Icons.waves,
    LettuceGuardColors.waterLevelColor,
    LettuceGuardConstants.minWaterLevelPct,
    100,
    0,
  ),
  tds(
    'TDS (Nutrients)',
    'TDS (Nutrients)',
    'TDS',
    'ppm',
    Icons.bolt,
    LettuceGuardColors.tdsColor,
    LettuceGuardConstants.minTds,
    LettuceGuardConstants.maxTds,
    0,
  );

  const ChartParameter(
    this.chipLabel,
    this.title,
    this.readingLabel,
    this.unit,
    this.icon,
    this.color,
    this.minOptimal,
    this.maxOptimal,
    this.decimals,
  );
  final String chipLabel, title, readingLabel, unit;
  final IconData icon;
  final Color color;
  final double minOptimal, maxOptimal;
  final int decimals;
  String get chartTitle => '$title History';
  String get axisUnit => this == ph ? 'pH' : unit;

  double? valueOf(SensorData data) {
    final (value, invalid) = switch (this) {
      ph => (
        data.ph,
        data.phError || data.phUncalibrated || data.adcSaturation,
      ),
      waterTemp => (data.waterTemperature, data.ds18b20Error),
      airTemp => (data.airTemperature, data.dht22Error),
      humidity => (data.airHumidity, data.dht22Error),
      waterLevel => (data.waterLevelPct, data.ultrasonicError),
      tds => (data.tds, !data.hasValidTds),
    };
    // Reserve numeric headroom for range subtraction and chart padding.
    if (invalid || !value.isFinite || value.abs() > double.maxFinite / 4) {
      return null;
    }
    if ((this == humidity || this == waterLevel) &&
        (value < 0 || value > 100)) {
      return null;
    }
    if (this == ph && (value < 0 || value > 14)) return null;
    if (this == waterTemp && (value == -127 || value == 85)) return null;
    if ((this == waterTemp || this == airTemp) && value < -273.15) return null;
    return value;
  }

  String formatValue(double? value) {
    if (value == null || !value.isFinite) return 'Unavailable';
    final suffix = unit == 'ppm' ? ' ppm' : unit;
    return '${value.toStringAsFixed(decimals)}$suffix';
  }

  String reading(SensorData data) =>
      '$readingLabel: ${formatValue(valueOf(data))}';
}

String historyTimestamp(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

/// Immutable chart projection. Null values break lines rather than bridge errors.
class HistoryChartData {
  HistoryChartData(List<SensorData> data, this.parameter)
    : records = List.unmodifiable(
        data.where((d) => d.hasValidTimestamp).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
      ) {
    values = List.unmodifiable(records.map(parameter.valueOf));
    final valid = values.whereType<double>();
    var low = parameter.minOptimal;
    var high = parameter.maxOptimal;
    for (final value in valid) {
      low = math.min(low, value);
      high = math.max(high, value);
    }
    final padding = math.max((high - low) * .08, .1);
    minY = low - padding;
    maxY = high + padding;
  }
  final ChartParameter parameter;
  final List<SensorData> records;
  late final List<double?> values;
  late final double minY, maxY;
  int get validCount => values.whereType<double>().length;
  double xFraction(int index) {
    final span =
        records.last.timestamp.millisecondsSinceEpoch -
        records.first.timestamp.millisecondsSinceEpoch;
    if (span == 0) return .5;
    return (records[index].timestamp.millisecondsSinceEpoch -
            records.first.timestamp.millisecondsSinceEpoch) /
        span;
  }

  double yFraction(double value) =>
      ((maxY - value) / (maxY - minY)).clamp(0, 1);
}
