import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../services/firebase_service.dart';
import '../services/mock_sensor_service.dart';
import '../utils/constants.dart';
import '../models/temperature_level.dart';
import '../services/temperature_alert_service.dart';

enum LiveSensorSource { firebase, esp32 }

/// Core provider managing real-time sensor streams, alerts, history, theme mode, and mock hardware diagnostics.
class SensorProvider extends ChangeNotifier {
  FirebaseService _firebaseService;
  final MockSensorService _mockService = MockSensorService();
  final TemperatureAlertConfig temperatureConfig;
  final DateTime Function() _clock;
  final Stream<SensorData>? _sensorStreamOverride;
  late TemperatureAlertService _temperature;
  late LiveSensorSource _liveSource;
  final List<TemperatureOperation> _temperaturePending = [];
  final Set<String> _persistedTemperatureIds = {};
  bool _temperatureRestored = false, _temperatureFlushing = false;
  String? _temperatureSyncError;
  Timer? _temperatureWatchdog;
  String? _lastTemperatureProblem;

  StreamSubscription<SensorData>? _subscription;
  Timer? _wifiPollTimer; // Timer for ESP32 Wi-Fi HTTP polling
  Timer? _historyPollTimer;
  int _sourceGeneration = 0;
  bool _disposed = false;
  int? _historyRequestGeneration;
  bool _isHistoryLoading = false;
  String? _historyError;
  int _skippedHistoryRecords = 0;
  int _duplicateHistoryRecords = 0;
  static const int historyLimit = 100;

  bool _isDemoMode = true;
  bool _isConnected = false;
  ThemeMode _themeMode = ThemeMode.light;

  String _firebaseUrl = LettuceGuardConstants.defaultFirebaseUrl;
  String _esp32Url = 'http://192.168.1.13/sensors';

  SensorData _currentData = SensorData.mock();
  List<SensorData> _history = [];
  final List<AlertModel> _alerts = [];

  SensorProvider({
    String? initialFirebaseUrl,
    String? initialEsp32Url,
    FirebaseService? firebaseService,
    bool initialDemoMode = true,
    LiveSensorSource? initialLiveSource,
    this.temperatureConfig = const TemperatureAlertConfig(),
    DateTime Function()? clock,
    Stream<SensorData>? sensorStreamOverride,
  }) : _clock = clock ?? DateTime.now,
       _sensorStreamOverride = sensorStreamOverride,
       _firebaseUrl =
           initialFirebaseUrl ?? LettuceGuardConstants.defaultFirebaseUrl,
       _esp32Url = initialEsp32Url ?? 'http://192.168.1.13/sensors',
       _firebaseService =
           firebaseService ??
           FirebaseService(
             firebaseDbUrl:
                 initialFirebaseUrl ?? LettuceGuardConstants.defaultFirebaseUrl,
           ) {
    _isDemoMode = initialDemoMode;
    _liveSource =
        initialLiveSource ??
        (initialEsp32Url == null
            ? LiveSensorSource.firebase
            : LiveSensorSource.esp32);
    _resetTemperatureState();
    _init();
    _temperatureWatchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      final problem = temperatureDataProblem;
      if (_lastTemperatureProblem != problem) {
        _lastTemperatureProblem = problem;
        if (problem != null) {
          _applyTemperature(
            TemperatureOperation.action('unavailable', null, null, _clock()),
          );
        }
        notifyListeners();
      }
    });
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
  bool get isHistoryLoading => _isHistoryLoading;
  String? get historyError => _historyError;
  int get skippedHistoryRecords => _skippedHistoryRecords;
  int get duplicateHistoryRecords => _duplicateHistoryRecords;

  LiveSensorSource get liveSource => _liveSource;
  TemperatureLevel get temperatureLevel => _temperature.level;
  AlertModel? get activeTemperatureAlert =>
      _temperature.latestEvent?.isResolved == false
      ? _temperature.latestEvent
      : null;
  String? get temperatureSyncError => _temperatureSyncError;
  bool get temperatureReadyForPopup =>
      _isDemoMode || _temperatureRestored || _temperatureSyncError != null;
  String? get temperatureDataProblem => !_isConnected
      ? 'Sensor connection unavailable; recovery cannot be confirmed.'
      : _temperature.validationProblem(_currentData, _clock());
  bool get hasPendingTemperatureSync =>
      !_isDemoMode && _temperaturePending.isNotEmpty;

  void _resetTemperatureState() {
    _temperature = TemperatureAlertService(
      config: temperatureConfig,
      deviceId: _firebaseService.deviceId,
      isDemo: _isDemoMode,
    );
    _temperaturePending.clear();
    _persistedTemperatureIds.clear();
    _temperatureRestored = false;
    _temperatureFlushing = false;
    _temperatureSyncError = null;
    _lastTemperatureProblem = null;
  }

  void _upsertTemperature(AlertModel? event) {
    if (event == null) return;
    final index = _alerts.indexWhere((a) => a.id == event.id);
    if (index == -1) {
      _alerts.insert(0, event);
    } else {
      _alerts[index] = event;
    }
  }

  void _applyTemperature(TemperatureOperation operation) {
    final before = _temperature.version;
    _upsertTemperature(_temperature.apply(operation));
    if (!_isDemoMode && _temperature.version != before) {
      _temperaturePending.add(operation);
      unawaited(syncTemperatureAlerts());
    }
  }

  void acknowledgeTemperatureAlert(String id, {int? priority}) {
    _applyTemperature(
      TemperatureOperation.action('acknowledge', id, priority, _clock()),
    );
    notifyListeners();
  }

  void markTemperaturePopupPresented(String id, int priority) {
    _applyTemperature(
      TemperatureOperation.action('presented', id, priority, _clock()),
    );
    notifyListeners();
  }

  void _adoptTemperatureState(Map<String, dynamic> state) {
    _temperature = TemperatureAlertService.fromJson(
      state,
      config: temperatureConfig,
      deviceId: _firebaseService.deviceId,
    );
    _alerts.removeWhere(
      (a) => a.isTemperatureAlert && !_persistedTemperatureIds.contains(a.id),
    );
    _upsertTemperature(_temperature.latestEvent);
    // Rebase unsent operations onto the latest server state after a concurrent write.
    for (final pending in _temperaturePending) {
      _upsertTemperature(_temperature.apply(pending));
    }
  }

  Future<void> syncTemperatureAlerts() async {
    if (_disposed || _isDemoMode || _temperatureFlushing) return;
    final generation = _sourceGeneration;
    final service = _firebaseService;
    _temperatureFlushing = true;
    try {
      if (!_temperatureRestored) {
        final state = await service.loadTemperatureState();
        final events = await service.fetchTemperatureAlerts();
        if (_disposed || generation != _sourceGeneration) return;
        for (final event in events.where(
          (a) => a.isTemperatureAlert && !a.isDemo,
        )) {
          _persistedTemperatureIds.add(event.id);
          _upsertTemperature(event);
        }
        _adoptTemperatureState(state);
        _temperatureRestored = true;
        if (temperatureDataProblem != null) {
          _applyTemperature(
            TemperatureOperation.action('unavailable', null, null, _clock()),
          );
        }
      }
      while (_temperaturePending.isNotEmpty) {
        final operation = _temperaturePending.first;
        final state = await service.applyTemperatureOperation(
          operation,
          config: temperatureConfig,
        );
        if (_disposed || generation != _sourceGeneration) return;
        _temperaturePending.removeAt(0);
        final raw = state['latestEvent'];
        if (raw is Map) _persistedTemperatureIds.add(raw['id'] as String);
        _adoptTemperatureState(state);
      }
      _temperatureSyncError = null;
    } catch (_) {
      if (_disposed || generation != _sourceGeneration) return;
      _temperatureSyncError =
          'Temperature alerts are not synchronized. Check sign-in, Firebase URL, connection, and device permissions. Pending changes will retry while the app stays open.';
    } finally {
      if (!_disposed && generation == _sourceGeneration) {
        _temperatureFlushing = false;
        notifyListeners();
      }
    }
  }

  void updateLiveSource(LiveSensorSource source) {
    if (_liveSource == source) return;
    _liveSource = source;
    if (!_isDemoMode) {
      _currentData = SensorData.fromJson({});
      _isConnected = false;
      _temperature.invalidate();
      _startDataStream();
    }
    notifyListeners();
  }

  int get unresolvedAlertsCount => _alerts.where((a) => !a.isResolved).length;

  void _init() {
    _history = _isDemoMode
        ? List.unmodifiable(_mockService.generateMockHistory(count: 24))
        : [];
    if (!_isDemoMode) _currentData = SensorData.fromJson({});
    _startDataStream();
  }

  // --- Theme Mode Toggle ---
  void toggleThemeMode() {
    _themeMode = (_themeMode == ThemeMode.light)
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void _startDataStream() {
    final generation = ++_sourceGeneration;
    _subscription?.cancel();
    _mockService.stop();
    _wifiPollTimer?.cancel();
    _historyPollTimer?.cancel();
    _isHistoryLoading = false;

    if (_sensorStreamOverride != null) {
      _subscription = _sensorStreamOverride.listen(
        (data) {
          if (!_disposed && generation == _sourceGeneration) {
            _isConnected = true;
            _onNewSensorData(data);
          }
        },
        onError: (_) {
          if (!_disposed && generation == _sourceGeneration) {
            _sensorUnavailable();
          }
        },
      );
    } else if (_isDemoMode) {
      _isConnected = true;
      _subscription = _mockService.getSensorStream().listen((data) {
        if (!_disposed && generation == _sourceGeneration) {
          _onNewSensorData(data);
        }
      });
    } else if (_liveSource == LiveSensorSource.firebase) {
      _isConnected = false;
      _subscription = _firebaseService.getSensorStream().listen(
        (data) {
          if (!_disposed && generation == _sourceGeneration) {
            _isConnected = true;
            _onNewSensorData(data);
          }
        },
        onError: (_) {
          if (!_disposed && generation == _sourceGeneration) {
            _sensorUnavailable();
          }
        },
      );
    } else {
      _startWifiPolling();
    }
    if (!_isDemoMode) {
      refreshHistory();
      unawaited(syncTemperatureAlerts());
      _historyPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        refreshHistory();
        // Also refresh acknowledgments made by another foreground client.
        if (!_temperatureFlushing && _temperaturePending.isEmpty) {
          _temperatureRestored = false;
        }
        unawaited(syncTemperatureAlerts());
      });
    }
  }

  void _sensorUnavailable() {
    _isConnected = false;
    _applyTemperature(
      TemperatureOperation.action('unavailable', null, null, _clock()),
    );
    notifyListeners();
  }

  // --- ESP32 Wi-Fi HTTP Polling ---
  void _startWifiPolling() {
    fetchEsp32Data();

    _wifiPollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await fetchEsp32Data();
    });
  }

  Future<void> fetchEsp32Data() async {
    if (_isDemoMode || _disposed) return;
    final generation = _sourceGeneration;
    try {
      final uri = Uri.tryParse(_esp32Url);
      if (uri == null || !uri.hasScheme) {
        _sensorUnavailable();
        return;
      }

      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (_disposed || generation != _sourceGeneration) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final rawLevel = jsonData['waterLevel'];
        final waterLevelCm = SensorData.parseReading(
          rawLevel is Map
              ? rawLevel['distanceCm']
              : rawLevel ?? jsonData['waterLevelCm'],
        );

        const double maxReservoirDepth = 30.0;
        double calculatedPct =
            ((maxReservoirDepth - waterLevelCm) / maxReservoirDepth) * 100;
        calculatedPct = calculatedPct.clamp(0.0, 100.0);

        final newData = SensorData.fromJson({
          ...jsonData,
          // Keep the actual sensor timestamp; arrival time is not a sample ID.
          'timestamp': jsonData['timestamp'],
          'airTemperature': jsonData['airTemperature'] ?? jsonData['airTemp'],
          'waterTemperature':
              jsonData['waterTemperature'] ?? jsonData['waterTemp'],
          'waterLevelCm': waterLevelCm,
          'waterLevelPct': calculatedPct,
          'ph': jsonData['ph'] ?? jsonData['phValue'],
          'tds': jsonData['tds'] ?? jsonData['tdsValue'],
        });

        _isConnected = true;
        _onNewSensorData(newData);
      } else {
        _sensorUnavailable();
      }
    } catch (e) {
      if (_disposed || generation != _sourceGeneration) return;
      _sensorUnavailable();
    }
  }

  /// Only persisted Firebase snapshots populate production history.
  Future<void> refreshHistory() async {
    if (_disposed ||
        _isDemoMode ||
        _historyRequestGeneration == _sourceGeneration) {
      return;
    }
    final generation = _sourceGeneration;
    final service = _firebaseService;
    _historyRequestGeneration = generation;
    _isHistoryLoading = true;
    notifyListeners();
    try {
      final records = await service.fetchHistoryLogs(limit: historyLimit);
      if (_disposed || generation != _sourceGeneration) return;
      _history = List.unmodifiable(
        records.where((d) => d.hasValidTimestamp).toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
      );
      _skippedHistoryRecords = service.skippedHistoryRecords;
      _duplicateHistoryRecords = service.duplicateHistoryRecords;
      _historyError = null;
    } catch (_) {
      if (_disposed || generation != _sourceGeneration) return;
      _historyError =
          'Unable to load Firebase history. Check connection, sign-in, and database read permissions.';
    } finally {
      if (!_disposed && generation == _sourceGeneration) {
        _isHistoryLoading = false;
        _historyRequestGeneration = null;
        notifyListeners();
      }
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

    if (_isDemoMode &&
        (_history.isEmpty ||
            data.timestamp.difference(_history.last.timestamp).inSeconds >
                15)) {
      final updated = [..._history, data];
      _history = List.unmodifiable(
        updated.skip(
          updated.length > historyLimit ? updated.length - historyLimit : 0,
        ),
      );
    }

    _applyTemperature(TemperatureOperation.reading(data, _clock()));
    _evaluateSystemAlerts(data);
    notifyListeners();
  }

  void _evaluateSystemAlerts(SensorData data) {
    if (data.dht22Error) {
      _addAlertIfNotExist(
        id: 'err_dht22',
        title: 'DHT22 Sensor Error',
        message:
            'Air Temperature & Humidity sensor failed to read or disconnected.',
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
        message:
            'Water Temperature probe disconnected or returned invalid value (-127°C / 85°C).',
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
        message:
            'Ultrasonic sensor pulse timeout or reservoir distance out of bounds.',
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
        message:
            'ESP32 analog input saturated (reading > 4090 or < 10 mV). Check wire connections.',
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
        message:
            'Current pH (${data.ph}) is outside optimal 5.5 - 6.5 range for lettuce.',
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
        message:
            'Nutrient water temperature (${data.waterTemperature}°C) outside optimal 18-22°C range.',
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
        message:
            'Reservoir water level is low (${data.waterLevelPct}%). Refill nutrient solution.',
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
    if (_isDemoMode == value) return;
    _isDemoMode = value;
    _isConnected = false;
    _historyError = null;
    _skippedHistoryRecords = 0;
    _duplicateHistoryRecords = 0;
    _alerts.clear();
    _history = value
        ? List.unmodifiable(_mockService.generateMockHistory(count: 24))
        : [];
    _currentData = value ? SensorData.mock() : SensorData.fromJson({});
    _resetTemperatureState();
    _startDataStream();
    notifyListeners();
  }

  void updateFirebaseUrl(String url) {
    _firebaseUrl = url;
    _firebaseService.dispose();
    _firebaseService = FirebaseService(firebaseDbUrl: url);
    if (!_isDemoMode) {
      _alerts.clear();
      _resetTemperatureState();
      _history = [];
      _historyError = null;
      _skippedHistoryRecords = 0;
      _duplicateHistoryRecords = 0;
      _startDataStream();
    }
    notifyListeners();
  }

  void setDemoAirTemperature(double value) {
    if (!_isDemoMode) {
      throw StateError(
        'Temperature simulation is available only in demo mode.',
      );
    }
    if (!value.isFinite || value < -40 || value > 80) {
      throw ArgumentError.value(value);
    }
    _mockService.baseAirTemp = value;
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
    _disposed = true;
    _sourceGeneration++;
    _subscription?.cancel();
    _wifiPollTimer?.cancel();
    _historyPollTimer?.cancel();
    _temperatureWatchdog?.cancel();
    _firebaseService.dispose();
    _mockService.dispose();
    super.dispose();
  }
}

class SensorProviderScope extends InheritedNotifier<SensorProvider> {
  SensorProvider get provider => notifier!;

  const SensorProviderScope({
    super.key,
    required SensorProvider provider,
    required super.child,
  }) : super(notifier: provider);

  static SensorProvider of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SensorProviderScope>();
    assert(scope != null, 'No SensorProviderScope found in context');
    return scope!.provider;
  }
}
