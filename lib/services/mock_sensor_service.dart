import 'dart:async';
import 'dart:math';
import '../models/sensor_model.dart';

/// Service simulating live hardware sensor streams and fault conditions
class MockSensorService {
  StreamController<SensorData>? _controller;
  Timer? _timer;
  final Random _random = Random();
  int _ticks = 0;

  // Toggleable hardware error flags for diagnostic UI testing
  bool forceDht22Error = false;
  bool forceDs18b20Error = false;
  bool forcePhError = false;
  bool forceUltrasonicError = false;
  bool forceAdcSaturation = false;
  bool forcePhUncalibrated = false;

  // Base parameters
  double baseAirTemp = 23.5;
  double baseHumidity = 62.0;
  double baseWaterTemp = 20.2;
  double basePh = 6.1;
  double baseTds = 720.0;
  double baseWaterLevelPct = 85.0;

  Stream<SensorData> getSensorStream({Duration interval = const Duration(seconds: 2)}) {
    _controller?.close();
    _controller = StreamController<SensorData>.broadcast();

    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      _ticks++;

      // Create natural oscillating ambient variations
      final airTempNoise = sin(_ticks * 0.1) * 0.8 + (_random.nextDouble() * 0.2 - 0.1);
      final humidityNoise = cos(_ticks * 0.08) * 2.0 + (_random.nextDouble() * 0.5 - 0.25);
      final waterTempNoise = sin(_ticks * 0.05) * 0.4 + (_random.nextDouble() * 0.1 - 0.05);
      final phNoise = sin(_ticks * 0.12) * 0.15 + (_random.nextDouble() * 0.04 - 0.02);
      final tdsNoise = cos(_ticks * 0.05) * 15.0 + (_random.nextDouble() * 5.0 - 2.5);
      final waterLevelNoise = -(_ticks * 0.05) % 30.0; // gradual slow evaporation cycle

      final currentAirTemp = double.parse((baseAirTemp + airTempNoise).toStringAsFixed(1));
      final currentHumidity = double.parse((baseHumidity + humidityNoise).toStringAsFixed(1));
      final currentWaterTemp = double.parse((baseWaterTemp + waterTempNoise).toStringAsFixed(1));
      final currentPh = double.parse((basePh + phNoise).toStringAsFixed(2));
      final currentTds = double.parse((baseTds + tdsNoise).toStringAsFixed(0));
      final currentLevelPct = double.parse((baseWaterLevelPct + waterLevelNoise).clamp(10.0, 100.0).toStringAsFixed(1));

      // Calculate distance in cm (30 cm reservoir depth)
      final currentLevelCm = double.parse(((100.0 - currentLevelPct) * 0.3).toStringAsFixed(1));

      final data = SensorData(
        airTemperature: forceDht22Error ? -999.0 : currentAirTemp,
        airHumidity: forceDht22Error ? -999.0 : currentHumidity,
        waterTemperature: forceDs18b20Error ? -127.0 : currentWaterTemp,
        ph: forcePhError ? 0.0 : (forcePhUncalibrated ? 13.8 : currentPh),
        tds: currentTds,
        waterLevelPct: forceUltrasonicError ? 0.0 : currentLevelPct,
        waterLevelCm: forceUltrasonicError ? 999.0 : currentLevelCm,
        reservoirDepthCm: 30.0,
        timestamp: DateTime.now(),
        dht22Error: forceDht22Error,
        ds18b20Error: forceDs18b20Error,
        phError: forcePhError,
        ultrasonicError: forceUltrasonicError,
        adcSaturation: forceAdcSaturation,
        phUncalibrated: forcePhUncalibrated,
      );

      if (!(_controller?.isClosed ?? true)) {
        _controller!.add(data);
      }
    });

    return _controller!.stream;
  }

  /// Generate mock history entries for charts
  List<SensorData> generateMockHistory({int count = 24}) {
    final List<SensorData> history = [];
    final now = DateTime.now();

    for (int i = count; i >= 0; i--) {
      final time = now.subtract(Duration(minutes: i * 30));
      final airTemp = 22.0 + sin(i * 0.3) * 2.5 + (_random.nextDouble() - 0.5);
      final humidity = 60.0 + cos(i * 0.3) * 5.0 + (_random.nextDouble() * 2 - 1);
      final waterTemp = 19.5 + sin(i * 0.2) * 1.2 + (_random.nextDouble() - 0.5);
      final ph = 6.0 + sin(i * 0.4) * 0.3 + (_random.nextDouble() * 0.1 - 0.05);
      final tds = 700.0 + cos(i * 0.2) * 40.0;
      final levelPct = (88.0 - (i * 0.5)).clamp(30.0, 95.0);

      history.add(
        SensorData(
          airTemperature: double.parse(airTemp.toStringAsFixed(1)),
          airHumidity: double.parse(humidity.toStringAsFixed(1)),
          waterTemperature: double.parse(waterTemp.toStringAsFixed(1)),
          ph: double.parse(ph.toStringAsFixed(2)),
          tds: double.parse(tds.toStringAsFixed(0)),
          waterLevelPct: double.parse(levelPct.toStringAsFixed(1)),
          waterLevelCm: double.parse(((100.0 - levelPct) * 0.3).toStringAsFixed(1)),
          reservoirDepthCm: 30.0,
          timestamp: time,
        ),
      );
    }
    return history;
  }

  void dispose() {
    _timer?.cancel();
    _controller?.close();
  }
}
