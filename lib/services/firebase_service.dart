import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../models/temperature_level.dart';
import 'temperature_alert_service.dart';
import '../utils/constants.dart';

/// Cross-platform RTDB REST access. History reads never write sensor records.
class FirebaseService {
  final String firebaseDbUrl;
  final String deviceId;
  final http.Client _client;
  final Future<String?> Function()? _tokenProvider;
  StreamController<SensorData>? _sensorStreamController;
  Timer? _pollingTimer;
  bool _disposed = false;
  bool _pollingCurrent = false;
  int skippedHistoryRecords = 0;
  int duplicateHistoryRecords = 0;

  FirebaseService({
    this.firebaseDbUrl = LettuceGuardConstants.defaultFirebaseUrl,
    this.deviceId = LettuceGuardConstants.defaultDeviceId,
    http.Client? client,
    Future<String?> Function()? tokenProvider,
  }) : _client = client ?? http.Client(),
       _tokenProvider = tokenProvider;

  Future<Uri> _uri(String node, [Map<String, String> query = const {}]) async {
    final base = Uri.parse(firebaseDbUrl.replaceFirst(RegExp(r'/+$'), ''));
    final token = _tokenProvider != null
        ? await _tokenProvider()
        : Firebase.apps.isEmpty
        ? null
        : await FirebaseAuth.instance.currentUser?.getIdToken();
    return base.replace(
      path:
          '${base.path.replaceFirst(RegExp(r'/+$'), '')}/devices/$deviceId/$node.json',
      queryParameters: {...base.queryParameters, ...query, 'auth': ?token},
    );
  }

  Future<Object?> _get(
    String node, [
    Map<String, String> query = const {},
  ]) async {
    final response = await _client
        .get(await _uri(node, query))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError(
        'Firebase request failed (HTTP ${response.statusCode}).',
      );
    }
    return jsonDecode(response.body);
  }

  Stream<SensorData> getSensorStream({
    Duration pollInterval = const Duration(seconds: 3),
  }) {
    _pollingTimer?.cancel();
    _sensorStreamController?.close();
    final controller = StreamController<SensorData>.broadcast();
    _sensorStreamController = controller;
    Future<void> poll() async {
      if (_disposed || _pollingCurrent) return;
      _pollingCurrent = true;
      try {
        final data = await fetchCurrentReadings();
        if (!controller.isClosed) {
          if (data != null) {
            controller.add(data);
          } else {
            controller.addError(
              StateError('No current Firebase sensor snapshot.'),
            );
          }
        }
      } catch (error) {
        if (!controller.isClosed) controller.addError(error);
      } finally {
        _pollingCurrent = false;
      }
    }

    _pollingTimer = Timer.periodic(pollInterval, (_) => poll());
    poll();
    return controller.stream;
  }

  Future<SensorData?> fetchCurrentReadings() async {
    final payload = await _get('current');
    if (payload == null) return null;
    if (payload is! Map) {
      throw const FormatException('Invalid Firebase current snapshot.');
    }
    return SensorData.fromJson(Map<String, dynamic>.from(payload));
  }

  /// Latest records by Firebase key, subsequently sorted by their recorded time.
  Future<List<SensorData>> fetchHistoryLogs({int limit = 100}) async {
    if (limit <= 0) throw ArgumentError.value(limit, 'limit');
    final payload = await _get('history', {
      'orderBy': '"\$key"',
      'limitToLast': '$limit',
    });
    skippedHistoryRecords = 0;
    duplicateHistoryRecords = 0;
    if (payload == null) return [];
    if (payload is! Map) {
      throw const FormatException('Invalid Firebase history snapshot.');
    }
    final records = <SensorData>[];
    final seen = <String>{};
    // Stable key order makes ties deterministic without dropping distinct samples.
    final keys = payload.keys.map((key) => key.toString()).toList()..sort();
    for (final key in keys) {
      final raw = payload[key];
      if (raw is! Map) {
        skippedHistoryRecords++;
        continue;
      }
      try {
        final data = Map<String, dynamic>.from(raw);
        final pushTime = historyKeyTimestamp(key);
        final parsed = SensorData.parseTimestamp(data['timestamp']);
        // Old firmware sent millis() (uptime), occasionally ambiguous with Unix
        // seconds. A push time far from such a number is the trustworthy fallback.
        final numeric = num.tryParse('${data['timestamp']}');
        if (pushTime != null && numeric != null) {
          if (numeric < 100000000000 &&
              (parsed == null ||
                  parsed.difference(pushTime).abs() >
                      const Duration(days: 1))) {
            data['timestamp'] = null;
          }
        }
        final record = SensorData.fromJson(data, historyKeyTime: pushTime);
        if (!record.hasValidTimestamp) {
          skippedHistoryRecords++;
          continue;
        }
        final identity = jsonEncode(record.toJson());
        if (!seen.add(identity)) {
          duplicateHistoryRecords++;
          continue;
        }
        records.add(record);
      } on FormatException {
        skippedHistoryRecords++;
      } on TypeError {
        skippedHistoryRecords++;
      }
    }
    records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return List.unmodifiable(records);
  }

  /// Firebase push IDs encode creation time in their first eight base-64 chars.
  static DateTime? historyKeyTimestamp(String key) {
    const alphabet =
        '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    if (key.length != 20 || key.split('').any((c) => !alphabet.contains(c))) {
      return null;
    }
    var ms = 0;
    for (final code in key.substring(0, 8).split('')) {
      ms = ms * 64 + alphabet.indexOf(code);
    }
    if (ms < 946684800000 || ms >= 4102444800000) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  // Temperature state is small; audit events are stored separately and retained.
  static const temperatureRoot = 'alerts/air_temperature';
  final Map<String, int> _mirroredEventVersions = {};

  Future<Map<String, dynamic>> loadTemperatureState() async {
    final raw = await _get('$temperatureRoot/state');
    if (raw == null) return {};
    if (raw is! Map) {
      throw const FormatException('Invalid temperature alert state.');
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<List<AlertModel>> fetchTemperatureAlerts({int limit = 50}) async {
    final raw = await _get('$temperatureRoot/events', {
      'orderBy': '"\$key"',
      'limitToLast': '$limit',
    });
    if (raw == null) return [];
    if (raw is! Map) {
      throw const FormatException('Invalid temperature alert history.');
    }
    return raw.entries
        .where((e) => e.value is Map)
        .map(
          (e) => AlertModel.fromJson(
            Map<String, dynamic>.from(e.value),
            e.key.toString(),
          ),
        )
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<Uri> _authorizedAlertUri(String path) async {
    final uri = await _uri(path);
    if ((uri.queryParameters['auth'] ?? '').isEmpty) {
      throw StateError('Sign in is required to persist temperature alerts.');
    }
    return uri;
  }

  /// Conditional writes prevent two foreground clients from opening two events
  /// for the same condition or counting one snapshot more than once.
  Future<Map<String, dynamic>> applyTemperatureOperation(
    TemperatureOperation operation, {
    TemperatureAlertConfig config = const TemperatureAlertConfig(),
  }) async {
    final uri = await _authorizedAlertUri('$temperatureRoot/state');
    for (var attempt = 0; attempt < 5; attempt++) {
      final response = await _client
          .get(uri, headers: {'X-Firebase-ETag': 'true'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.headers['etag'] == null) {
        throw StateError(
          'Unable to read temperature state with ETag (HTTP ${response.statusCode}).',
        );
      }
      final raw = jsonDecode(response.body);
      if (raw != null && raw is! Map) {
        throw const FormatException('Invalid temperature alert state.');
      }
      final engine = TemperatureAlertService.fromJson(
        raw == null ? {} : Map<String, dynamic>.from(raw),
        config: config,
        deviceId: deviceId,
      );
      // Repair a partial archive write before replacing the previous event.
      if (engine.latestEvent != null) {
        await _mirrorTemperatureEvent(engine.latestEvent!);
      }
      final before = engine.version;
      engine.apply(operation);
      if (engine.version == before) return engine.toJson();
      final saved = await _client
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'if-match': response.headers['etag']!,
            },
            body: jsonEncode(engine.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (saved.statusCode == 412) continue;
      if (saved.statusCode != 200) {
        throw StateError(
          'Temperature state save failed (HTTP ${saved.statusCode}).',
        );
      }
      if (engine.latestEvent != null) {
        await _mirrorTemperatureEvent(engine.latestEvent!);
      }
      return engine.toJson();
    }
    throw StateError(
      'Temperature alert synchronization conflicted; retry pending.',
    );
  }

  Future<void> _mirrorTemperatureEvent(AlertModel event) async {
    if (event.isDemo) {
      throw StateError('Demo alerts cannot be written to Firebase.');
    }
    if ((_mirroredEventVersions[event.id] ?? -1) >= event.revision) return;
    final uri = await _authorizedAlertUri(
      '$temperatureRoot/events/${event.id}',
    );
    for (var attempt = 0; attempt < 5; attempt++) {
      final response = await _client
          .get(uri, headers: {'X-Firebase-ETag': 'true'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.headers['etag'] == null) {
        throw StateError('Unable to read temperature event.');
      }
      final raw = jsonDecode(response.body);
      if (raw != null && raw is! Map) {
        throw const FormatException('Invalid temperature event.');
      }
      if (raw is Map && (raw['revision'] as num? ?? 0) >= event.revision) {
        _mirroredEventVersions[event.id] = (raw['revision'] as num).toInt();
        return;
      }
      final saved = await _client
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'if-match': response.headers['etag']!,
            },
            body: jsonEncode(event.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      if (saved.statusCode == 412) continue;
      if (saved.statusCode != 200) {
        throw StateError(
          'Temperature audit save failed (HTTP ${saved.statusCode}).',
        );
      }
      _mirroredEventVersions[event.id] = event.revision;
      return;
    }
    throw StateError('Temperature audit synchronization conflicted.');
  }

  Future<bool> pushAlert(AlertModel alert) async {
    try {
      final response = await _client
          .post(
            await _uri('alerts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(alert.toJson()),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _disposed = true;
    _pollingTimer?.cancel();
    _sensorStreamController?.close();
    _client.close();
  }
}
