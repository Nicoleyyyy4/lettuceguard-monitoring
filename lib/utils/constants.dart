/// Optimal hydroponic threshold constants for Lettuce cultivation
class LettuceGuardConstants {
  // Application Info
  static const String appName = 'LettuceGuard';
  static const String appSubtitle = 'Smart Hydroponics Monitoring System';
  static const String appVersion = '1.0.0';

  // Optimal Hydroponic Parameters for Lettuce (Butterhead/Romaine)
  static const double minAirTemp = 18.0; // °C
  static const double maxAirTemp = 26.0; // °C

  // LettuceGuard application configuration, not universal biological limits.
  static const double criticalAirTemp = 30.0;
  static const double extremeAirTemp = 35.0;
  static const int temperatureConfirmationCount = 3;
  static const int temperatureRecoveryCount = 3;
  static const double temperatureRecoveryHysteresis = 1.0;
  static const Duration temperatureMaxAge = Duration(seconds: 30);
  static const Duration temperatureMaxSampleGap = Duration(seconds: 12);

  static const double minAirHumidity = 50.0; // %
  static const double maxAirHumidity = 70.0; // %

  static const double minWaterTemp = 18.0; // °C
  static const double maxWaterTemp = 22.0; // °C
  static const double waterPumpStartTemp = 23.0; // °C
  static const double waterPumpStopTemp = 22.0; // °C
  static const double waterPumpMinimumLevelPct = 25.0; // %

  static const double minPh = 5.5;
  static const double maxPh = 6.5;

  static const double minTds = 560.0; // ppm (approx 0.8 mS/cm)
  static const double maxTds = 840.0; // ppm (approx 1.2 mS/cm)

  static const double minWaterLevelPct = 25.0; // %
  static const double defaultReservoirDepthCm = 30.0; // cm

  // Error Code & Sensor Alert Message Constants
  static const String errDht22 = 'DHT22 SENSOR ERROR';
  static const String errDs18b20 = 'DS18B20 SENSOR ERROR';
  static const String errPhSensor = 'pH SENSOR UNCALIBRATED / DISCONNECTED';
  static const String errUltrasonic = 'HC-SR04 ULTRASONIC SENSOR ERROR';
  static const String errAdcSaturation =
      'ADC SATURATION DETECTED (Out of Range)';
  static const String errTdsSensor = 'TDS / EC METER SENSOR ERROR';

  // Firebase Realtime DB defaults for the active LettuceGuard project.
  static const String defaultDeviceId = 'lettuceguard_node_01';
  static const String defaultFirebaseUrl =
      'https://lettuceguard-bd1f4-default-rtdb.firebaseio.com';
}
