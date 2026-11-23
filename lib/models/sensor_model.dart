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
  final bool hasValidTimestamp;

  /// Legacy records can use the Firebase push key's creation time.
  final bool timestampFromHistoryKey;
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
    this.hasValidTimestamp = true,
    this.timestampFromHistoryKey = false,
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
  factory SensorData.fromJson(
    Map<String, dynamic> json, {
    DateTime? historyKeyTime,
  }) {
    Map<String, dynamic> errors = {};
    if (json['sensorErrors'] is Map) {
      errors = Map<String, dynamic>.from(json['sensorErrors']);
    }

    // Parse water level structure if nested or flat
    double levelPct = double.nan;
    double levelCm = double.nan;
    double depthCm = LettuceGuardConstants.defaultReservoirDepthCm;

    if (json['waterLevel'] is Map) {
      final wl = Map<String, dynamic>.from(json['waterLevel']);
      levelPct = parseReading(wl['percentage']);
      levelCm = parseReading(wl['distanceCm']);
      depthCm = (wl['reservoirDepthCm'] is num)
          ? (wl['reservoirDepthCm'] as num).toDouble()
          : depthCm;
    } else {
      levelPct = parseReading(json['waterLevelPct']);
      levelCm = parseReading(json['waterLevelCm']);
      depthCm = (json['reservoirDepthCm'] is num)
          ? (json['reservoirDepthCm'] as num).toDouble()
          : depthCm;
    }

    final parsedTime = parseTimestamp(json['timestamp']);
    final ts = parsedTime ?? historyKeyTime;
    if (!depthCm.isFinite || depthCm <= 0) {
      depthCm = LettuceGuardConstants.defaultReservoirDepthCm;
    }

    return SensorData(
      airTemperature: parseReading(json['airTemperature']),
      airHumidity: parseReading(json['airHumidity']),
      waterTemperature: parseReading(json['waterTemperature']),
      ph: parseReading(json['ph']),
      tds: parseReading(json['tds']),
      waterLevelPct: levelPct,
      waterLevelCm: levelCm,
      reservoirDepthCm: depthCm,
      timestamp: ts ?? DateTime.fromMillisecondsSinceEpoch(0),
      hasValidTimestamp: ts != null,
      timestampFromHistoryKey: parsedTime == null && historyKeyTime != null,
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

  /// Read finite numbers without inventing defaults for absent measurements.
  static double parseReading(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite ? number : double.nan;
  }

  /// Accept Unix milliseconds, Unix seconds, and ISO dates; reject MCU uptime.
  static DateTime? parseTimestamp(Object? value) {
    final numeric = value is num ? value : num.tryParse('$value');
    DateTime? result;
    if (numeric != null && numeric.isFinite) {
      final ms = numeric < 100000000000 ? numeric * 1000 : numeric;
      if (ms < 946684800000 || ms >= 4102444800000) return null;
      result = DateTime.fromMillisecondsSinceEpoch(ms.round());
    } else if (value is String) {
      result = DateTime.tryParse(value);
    }
    if (result == null || result.year < 2000 || result.year >= 2100) {
      return null;
    }
    return result.toLocal();
  }

  /// Keep double fields compatible with existing consumers; missing is not zero.
  bool get hasValidTds => !tdsError && tds.isFinite && tds >= 0;
  bool get hasValidAirTemperature =>
      !dht22Error &&
      airTemperature.isFinite &&
      airTemperature >= -40 &&
      airTemperature <= 80;

  /// Convert readings to the existing Firebase payload; missing numbers are null.
  Map<String, dynamic> toJson() {
    return {
      'airTemperature': airTemperature.isFinite ? airTemperature : null,
      'airHumidity': airHumidity.isFinite ? airHumidity : null,
      'waterTemperature': waterTemperature.isFinite ? waterTemperature : null,
      'ph': ph.isFinite ? ph : null,
      'tds': tds.isFinite ? tds : null,
      'waterLevel': {
        'percentage': waterLevelPct.isFinite ? waterLevelPct : null,
        'distanceCm': waterLevelCm.isFinite ? waterLevelCm : null,
        'reservoirDepthCm': reservoirDepthCm.isFinite ? reservoirDepthCm : null,
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
      'timestamp': hasValidTimestamp ? timestamp.millisecondsSinceEpoch : null,
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
      hasValidAirTemperature &&
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
      hasValidTds &&
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
