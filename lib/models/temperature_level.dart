import '../utils/constants.dart';

enum TemperatureLevel { normal, low, high, critical, extreme }

extension TemperatureLevelDetails on TemperatureLevel {
  bool get isHeat =>
      this == TemperatureLevel.high ||
      this == TemperatureLevel.critical ||
      this == TemperatureLevel.extreme;
  int get priority => switch (this) {
    TemperatureLevel.normal => 0,
    TemperatureLevel.low => 1,
    TemperatureLevel.high => 2,
    TemperatureLevel.critical => 3,
    TemperatureLevel.extreme => 4,
  };
  String get title => switch (this) {
    TemperatureLevel.normal => 'TEMPERATURE RETURNED TO NORMAL',
    TemperatureLevel.low => 'LOW AIR TEMPERATURE',
    TemperatureLevel.high => 'HIGH AIR TEMPERATURE',
    TemperatureLevel.critical => 'CRITICAL HEAT ALERT',
    TemperatureLevel.extreme => 'EXTREME HEAT DETECTED',
  };
  String get action => switch (this) {
    TemperatureLevel.normal =>
      'The environment has returned to the configured normal air-temperature range.',
    TemperatureLevel.low =>
      'The environment is below the configured range. Inspect the growing environment and temperature control.',
    TemperatureLevel.high => 'Check ventilation, airflow, and shading.',
    TemperatureLevel.critical =>
      'Prolonged exposure may cause lettuce heat stress. Inspect ventilation, improve airflow, check shading, and monitor the environment. Check water temperature separately.',
    TemperatureLevel.extreme =>
      'Immediate environmental inspection is recommended. Inspect ventilation, airflow, and shading. Check water temperature separately.',
  };
}

class TemperatureAlertConfig {
  const TemperatureAlertConfig({
    this.min = LettuceGuardConstants.minAirTemp,
    this.max = LettuceGuardConstants.maxAirTemp,
    this.critical = LettuceGuardConstants.criticalAirTemp,
    this.extreme = LettuceGuardConstants.extremeAirTemp,
    this.confirmations = LettuceGuardConstants.temperatureConfirmationCount,
    this.recoveryCount = LettuceGuardConstants.temperatureRecoveryCount,
    this.hysteresis = LettuceGuardConstants.temperatureRecoveryHysteresis,
    this.maxAge = LettuceGuardConstants.temperatureMaxAge,
    this.maxSampleGap = LettuceGuardConstants.temperatureMaxSampleGap,
    this.futureTolerance = const Duration(seconds: 5),
  }) : assert(min < max && max < critical && critical < extreme),
       assert(confirmations > 0 && recoveryCount > 0 && hysteresis >= 0);
  final double min, max, critical, extreme, hysteresis;
  final int confirmations, recoveryCount;
  final Duration maxAge, maxSampleGap, futureTolerance;
  TemperatureLevel classify(double temperature) {
    if (temperature < min) return TemperatureLevel.low;
    if (temperature <= max) return TemperatureLevel.normal;
    if (temperature < critical) return TemperatureLevel.high;
    if (temperature < extreme) return TemperatureLevel.critical;
    return TemperatureLevel.extreme;
  }

  double threshold(TemperatureLevel level) => switch (level) {
    TemperatureLevel.normal => max,
    TemperatureLevel.low => min,
    TemperatureLevel.high => max,
    TemperatureLevel.critical => critical,
    TemperatureLevel.extreme => extreme,
  };
}
