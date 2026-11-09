import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../services/firebase_service.dart';
import '../services/mock_sensor_service.dart';
import '../utils/constants.dart';

/// Core provider managing real-time sensor streams, alerts, history, theme mode, and mock hardware diagnostics.
class SensorProvider extends ChangeNotifier {
  FirebaseService _firebaseService;
  final MockSensorService _mockService = MockSensorService();

  StreamSubscription<SensorData>? _subscription;
  Timer? _wifiPollTimer; // Timer for ESP32 Wi-Fi HTTP polling

  bool _isDemoMode = true;
  bool _isConnected = false;
  ThemeMode _themeMode = ThemeMode.light;

  String _firebaseUrl = LettuceGuardConstants.defaultFirebaseUrl;
  String _esp32Url = 'http://192.168.1.13/sensors';

  SensorData _currentData = SensorData.mock();
  List<SensorData> _history = [];
  final List<AlertModel> _alerts = [];

  SensorProvider({String? initialFirebaseUrl, String? initialEsp32Url})
      : _firebaseUrl = initialFirebaseUrl ?? LettuceGuardConstants.defaultFirebaseUrl,
        _esp32Url = initialEsp32Url ?? 'http://192.168.1.13/sensors',
        _firebaseService = FirebaseService(
          firebaseDbUrl: initialFirebaseUrl ?? LettuceGuardConstants.defaultFirebaseUrl,
        ) {
    _init();
  }

  // --- Getters ---
  SensorData get currentData => _currentData;
  List<SensorData> get history => _history;
  List<AlertModel> get alerts => _alerts;
  bool get isDemoMode => _isDemoMode;
  bool get isConnected => _isConnected;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get firebaseUrl => _firebaseUrl;
  String get esp32Url => _esp32Url;
  MockSensorService get mockService => _mockService;

  int get unresolvedAlertsCount =>
      _alerts.where((a) => !a.isResolved).length;

  void _init() {
    _history = _mockService.generateMockHistory(count: 24);
    _startDataStream();
  }

  // --- Theme Mode Toggle ---
  void toggleThemeMode() {
    _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _startDataStream() {
    _subscription?.cancel();
    _wifiPollTimer?.cancel();

    if (_isDemoMode) {
      _isConnected = true;
      _subscription = _mockService.getSensorStream().listen((data) {
        _onNewSensorData(data);
      });
    } else {
      _startWifiPolling();
    }
  }

  // --- ESP32 Wi-Fi HTTP Polling ---
  void _startWifiPolling() {
    fetchEsp32Data();

    _wifiPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await fetchEsp32Data();
    });
  }

  Future<void> fetchEsp32Data() async {
    try {
      final uri = Uri.tryParse(_esp32Url);
      if (uri == null || !uri.hasScheme) {
        _isConnected = false;
        notifyListeners();
        return;
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final double waterLevelCm = (jsonData['waterLevel'] as num).toDouble();

        const double maxReservoirDepth = 30.0;
        double calculatedPct = ((maxReservoirDepth - waterLevelCm) / maxReservoirDepth) * 100;
        calculatedPct = calculatedPct.clamp(0.0, 100.0);

        final newData = SensorData(
          timestamp: DateTime.now(),
          airTemperature: (jsonData['airTemp'] as num).toDouble(),
          airHumidity: (jsonData['airHumidity'] as num).toDouble(),
          waterTemperature: (jsonData['waterTemp'] as num).toDouble(),
          waterLevelCm: waterLevelCm,
          waterLevelPct: calculatedPct,
          ph: (jsonData['phValue'] as num).toDouble(),
          tds: (jsonData['tdsValue'] as num).toDouble(),
        );

        _isConnected = true;
        _onNewSensorData(newData);
      }
    } catch (e) {
      _isConnected = false;
      notifyListeners();
    }
  }

  void updateEsp32Url(String url) {
    _esp32Url = url;
    if (!_isDemoMode) {
      _startDataStream();
    }
    notifyListeners();
  }

  void _onNewSensorData(SensorData data) {
    _currentData = data;

    if (_history.isEmpty ||
        data.timestamp.difference(_history.last.timestamp).inSeconds > 15) {
      _history.add(data);
      if (_history.length > 100) {
        _history.removeAt(0);
      }
    }

    _evaluateSystemAlerts(data);
    notifyListeners();
  }

  void _evaluateSystemAlerts(SensorData data) {
    if (data.dht22Error) {
      _addAlertIfNotExist(
        id: 'err_dht22',
        title: 'DHT22 Sensor Error',
        message: 'Air Temperature & Humidity sensor failed to read or disconnected.',
        source: 'DHT22',
        severity: AlertSeverity.error,
      );
    } else {
      _resolveAlert('err_dht22');
    }

    if (data.ds18b20Error) {
      _addAlertIfNotExist(
        id: 'err_ds18b20',
        title: 'DS18B20 Sensor Error',
        message: 'Water Temperature probe disconnected or returned invalid value (-127°C / 85°C).',
        source: 'DS18B20',
        severity: AlertSeverity.error,
      );
    } else {
      _resolveAlert('err_ds18b20');
    }

    if (data.phError || data.phUncalibrated) {
      _addAlertIfNotExist(
        id: 'err_ph',
        title: 'pH Sensor Warning',
        message: data.phUncalibrated
            ? 'pH electrode reading uncalibrated voltage out of expected bounds.'
            : 'pH probe disconnected or ADC signal lost.',
        source: 'pH Sensor',
        severity: AlertSeverity.error,
      );
    } else {
      _resolveAlert('err_ph');
    }

    if (data.ultrasonicError) {
      _addAlertIfNotExist(
        id: 'err_ultrasonic',
        title: 'HC-SR04 Level Sensor Error',
        message: 'Ultrasonic sensor pulse timeout or reservoir distance out of bounds.',
        source: 'HC-SR04',
        severity: AlertSeverity.error,
      );
    } else {
      _resolveAlert('err_ultrasonic');
    }

    if (data.adcSaturation) {
      _addAlertIfNotExist(
        id: 'err_adc',
        title: 'ADC Saturation Alert',
        message: 'ESP32 analog input saturated (reading > 4090 or < 10 mV). Check wire connections.',
        source: 'ESP32 ADC',
        severity: AlertSeverity.warning,
      );
    } else {
      _resolveAlert('err_adc');
    }

    if (data.isPhOutOfRange) {
      _addAlertIfNotExist(
        id: 'warn_ph_range',
        title: 'pH Out of Optimal Range',
        message: 'Current pH (${data.ph}) is outside optimal 5.5 - 6.5 range for lettuce.',
        source: 'pH Level',
        severity: AlertSeverity.warning,
      );
    } else {
      _resolveAlert('warn_ph_range');
    }

    if (data.isWaterTempOutOfRange) {
      _addAlertIfNotExist(
        id: 'warn_wtemp_range',
        title: 'Water Temp Warning',
        message: 'Nutrient water temperature (${data.waterTemperature}°C) outside optimal 18-22°C range.',
        source: 'Water Temp',
        severity: AlertSeverity.warning,
      );
    } else {
      _resolveAlert('warn_wtemp_range');
    }

    if (data.isWaterLevelLow) {
      _addAlertIfNotExist(
        id: 'warn_water_low',
        title: 'Low Water Level',
        message: 'Reservoir water level is low (${data.waterLevelPct}%). Refill nutrient solution.',
        source: 'Water Level',
        severity: AlertSeverity.warning,
      );
    } else {
      _resolveAlert('warn_water_low');
    }
  }

  void _addAlertIfNotExist({
    required String id,
    required String title,
    required String message,
    required String source,
    required AlertSeverity severity,
  }) {
    final existingIndex = _alerts.indexWhere((a) => a.id == id);
    if (existingIndex == -1) {
      _alerts.insert(
        0,
        AlertModel(
          id: id,
          title: title,
          message: message,
          sensorSource: source,
          severity: severity,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _resolveAlert(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index != -1 && !_alerts[index].isResolved) {
      _alerts[index] = AlertModel(
        id: _alerts[index].id,
        title: _alerts[index].title,
        message: _alerts[index].message,
        sensorSource: _alerts[index].sensorSource,
        severity: _alerts[index].severity,
        timestamp: _alerts[index].timestamp,
        isResolved: true,
      );
    }
  }

  void clearResolvedAlerts() {
    _alerts.removeWhere((a) => a.isResolved);
    notifyListeners();
  }

  void toggleDemoMode(bool value) {
    _isDemoMode = value;
    _startDataStream();
    notifyListeners();
  }

  void updateFirebaseUrl(String url) {
    _firebaseUrl = url;
    _firebaseService = FirebaseService(firebaseDbUrl: url);
    notifyListeners();
  }

  void setDht22Error(bool err) {
    _mockService.forceDht22Error = err;
    notifyListeners();
  }

  void setDs18b20Error(bool err) {
    _mockService.forceDs18b20Error = err;
    notifyListeners();
  }

  void setPhError(bool err) {
    _mockService.forcePhError = err;
    notifyListeners();
  }

  void setUltrasonicError(bool err) {
    _mockService.forceUltrasonicError = err;
    notifyListeners();
  }

  void setAdcSaturation(bool err) {
    _mockService.forceAdcSaturation = err;
    notifyListeners();
  }

  void setPhUncalibrated(bool err) {
    _mockService.forcePhUncalibrated = err;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _wifiPollTimer?.cancel();
    _firebaseService.dispose();
    _mockService.dispose();
    super.dispose();
  }
}

class SensorProviderScope extends InheritedWidget {
  final SensorProvider provider;

  const SensorProviderScope({
    super.key,
    required this.provider,
    required super.child,
  });

  static SensorProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SensorProviderScope>();
    assert(scope != null, 'No SensorProviderScope found in context');
    return scope!.provider;
  }

  @override
  bool updateShouldNotify(SensorProviderScope oldWidget) {
    return provider != oldWidget.provider;
  }
}
