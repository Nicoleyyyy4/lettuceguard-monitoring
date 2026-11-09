import '../utils/constants.dart';

/// Data model representing sensor readings from LettuceGuard IoT Node
class SensorData {
  final double airTemperature; // °C
  final double airHumidity; // %
  final double waterTemperature; // °C
  final double ph; // pH scale 0-14
  final double tds; // ppm (Total Dissolved Solids)
  final double waterLevelPct; // %
  final double waterLevelCm; // cm (distance from full or depth)
  final double reservoirDepthCm; // cm total height of tank
  final DateTime timestamp;
  final String systemStatus; // OK, WARNING, ERROR

  // Hardware sensor error flags
  final bool dht22Error;
  final bool ds18b20Error;
  final bool phError;
  final bool ultrasonicError;
  final bool tdsError;
  final bool adcSaturation;
  final bool phUncalibrated;

  const SensorData({
    required this.airTemperature,
    required this.airHumidity,
    required this.waterTemperature,
    required this.ph,
    required this.tds,
    required this.waterLevelPct,
    required this.waterLevelCm,
    this.reservoirDepthCm = LettuceGuardConstants.defaultReservoirDepthCm,
    required this.timestamp,
    this.systemStatus = 'OK',
    this.dht22Error = false,
    this.ds18b20Error = false,
    this.phError = false,
    this.ultrasonicError = false,
    this.tdsError = false,
    this.adcSaturation = false,
    this.phUncalibrated = false,
  });

  /// Factory constructor to parse JSON payload received from Firebase Realtime DB
  factory SensorData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> errors = {};
    if (json['sensorErrors'] is Map) {
      errors = Map<String, dynamic>.from(json['sensorErrors']);
    }

    // Parse water level structure if nested or flat
    double levelPct = 0.0;
    double levelCm = 0.0;
    double depthCm = LettuceGuardConstants.defaultReservoirDepthCm;

    if (json['waterLevel'] is Map) {
      final wl = Map<String, dynamic>.from(json['waterLevel']);
      levelPct = (wl['percentage'] as num?)?.toDouble() ?? 0.0;
      levelCm = (wl['distanceCm'] as num?)?.toDouble() ?? 0.0;
      depthCm = (wl['reservoirDepthCm'] as num?)?.toDouble() ?? depthCm;
    } else {
      levelPct = (json['waterLevelPct'] as num?)?.toDouble() ?? 0.0;
      levelCm = (json['waterLevelCm'] as num?)?.toDouble() ?? 0.0;
      depthCm = (json['reservoirDepthCm'] as num?)?.toDouble() ?? depthCm;
    }

    DateTime ts;
    if (json['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else if (json['timestamp'] is String) {
      ts = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    } else {
      ts = DateTime.now();
    }

    return SensorData(
      airTemperature: (json['airTemperature'] as num?)?.toDouble() ?? 0.0,
      airHumidity: (json['airHumidity'] as num?)?.toDouble() ?? 0.0,
      waterTemperature: (json['waterTemperature'] as num?)?.toDouble() ?? 0.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
      tds: (json['tds'] as num?)?.toDouble() ?? 0.0,
      waterLevelPct: levelPct,
      waterLevelCm: levelCm,
      reservoirDepthCm: depthCm,
      timestamp: ts,
      systemStatus: (json['systemStatus'] as String?) ?? 'OK',
      dht22Error: (errors['dht22Error'] as bool?) ?? false,
      ds18b20Error: (errors['ds18b20Error'] as bool?) ?? false,
      phError: (errors['phError'] as bool?) ?? false,
      ultrasonicError: (errors['ultrasonicError'] as bool?) ?? false,
      tdsError: (errors['tdsError'] as bool?) ?? false,
      adcSaturation: (errors['adcSaturation'] as bool?) ?? false,
      phUncalibrated: (errors['phUncalibrated'] as bool?) ?? false,
    );
  }

  /// Convert SensorData to JSON payload for Firebase Realtime DB
  Map<String, dynamic> toJson() {
    return {
      'airTemperature': airTemperature,
      'airHumidity': airHumidity,
      'waterTemperature': waterTemperature,
      'ph': ph,
      'tds': tds,
      'waterLevel': {
        'percentage': waterLevelPct,
        'distanceCm': waterLevelCm,
        'reservoirDepthCm': reservoirDepthCm,
      },
      'systemStatus': calculatedStatus,
      'sensorErrors': {
        'dht22Error': dht22Error,
        'ds18b20Error': ds18b20Error,
        'phError': phError,
        'ultrasonicError': ultrasonicError,
        'tdsError': tdsError,
        'adcSaturation': adcSaturation,
        'phUncalibrated': phUncalibrated,
      },
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Default mock sensor readings for demonstration and offline testing
  factory SensorData.mock({
    double airTemp = 23.5,
    double humidity = 62.0,
    double waterTemp = 20.2,
    double phValue = 6.1,
    double tdsValue = 720.0,
    double levelPct = 85.0,
    double levelCm = 4.5,
    bool dht22Err = false,
    bool ds18b20Err = false,
    bool phErr = false,
    bool ultrasonicErr = false,
    bool adcSat = false,
  }) {
    return SensorData(
      airTemperature: airTemp,
      airHumidity: humidity,
      waterTemperature: waterTemp,
      ph: phValue,
      tds: tdsValue,
      waterLevelPct: levelPct,
      waterLevelCm: levelCm,
      timestamp: DateTime.now(),
      dht22Error: dht22Err,
      ds18b20Error: ds18b20Err,
      phError: phErr,
      ultrasonicError: ultrasonicErr,
      adcSaturation: adcSat,
    );
  }

  // --- Parameter Health Checks & Computed Properties ---

  bool get hasSensorError =>
      dht22Error ||
      ds18b20Error ||
      phError ||
      ultrasonicError ||
      tdsError ||
      adcSaturation ||
      phUncalibrated;

  bool get isAirTempOutOfRange =>
      !dht22Error &&
      (airTemperature < LettuceGuardConstants.minAirTemp ||
          airTemperature > LettuceGuardConstants.maxAirTemp);

  bool get isAirHumidityOutOfRange =>
      !dht22Error &&
      (airHumidity < LettuceGuardConstants.minAirHumidity ||
          airHumidity > LettuceGuardConstants.maxAirHumidity);

  bool get isWaterTempOutOfRange =>
      !ds18b20Error &&
      (waterTemperature < LettuceGuardConstants.minWaterTemp ||
          waterTemperature > LettuceGuardConstants.maxWaterTemp);

  bool get isPhOutOfRange =>
      !phError &&
      !phUncalibrated &&
      (ph < LettuceGuardConstants.minPh || ph > LettuceGuardConstants.maxPh);

  bool get isTdsOutOfRange =>
      !tdsError &&
      (tds < LettuceGuardConstants.minTds ||
          tds > LettuceGuardConstants.maxTds);

  bool get isWaterLevelLow =>
      !ultrasonicError &&
      waterLevelPct < LettuceGuardConstants.minWaterLevelPct;

  bool get hasParameterWarning =>
      isAirTempOutOfRange ||
      isAirHumidityOutOfRange ||
      isWaterTempOutOfRange ||
      isPhOutOfRange ||
      isTdsOutOfRange ||
      isWaterLevelLow;

  String get calculatedStatus {
    if (hasSensorError) return 'ERROR';
    if (hasParameterWarning) return 'WARNING';
    return 'OK';
  }

  int get activeErrorCount {
    int count = 0;
    if (dht22Error) count++;
    if (ds18b20Error) count++;
    if (phError) count++;
    if (ultrasonicError) count++;
    if (tdsError) count++;
    if (adcSaturation) count++;
    if (phUncalibrated) count++;
    return count;
  }
}
