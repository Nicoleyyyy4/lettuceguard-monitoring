import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/sensor_model.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';

/// Firebase Realtime Database service handling real-time sensor streams and REST sync.
class FirebaseService {
  final String firebaseDbUrl;
  final String deviceId;

  StreamController<SensorData>? _sensorStreamController;
  Timer? _pollingTimer;

  FirebaseService({
    this.firebaseDbUrl = LettuceGuardConstants.defaultFirebaseUrl,
    this.deviceId = LettuceGuardConstants.defaultDeviceId,
  });

  /// Stream of real-time sensor updates from Firebase Realtime Database
  Stream<SensorData> getSensorStream({Duration pollInterval = const Duration(seconds: 3)}) {
    _sensorStreamController?.close();
    _sensorStreamController = StreamController<SensorData>.broadcast();

    // Start polling loop
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollInterval, (_) async {
      final data = await fetchCurrentReadings();
      if (data != null && !_sensorStreamController!.isClosed) {
        _sensorStreamController!.add(data);
      }
    });

    // Immediate initial fetch
    fetchCurrentReadings().then((data) {
      if (data != null && !(_sensorStreamController?.isClosed ?? true)) {
        _sensorStreamController!.add(data);
      }
    });

    return _sensorStreamController!.stream;
  }

  /// Fetch single current snapshot from Firebase RTDB `/devices/{deviceId}/current.json`
  Future<SensorData?> fetchCurrentReadings() async {
    try {
      final sanitizedUrl = firebaseDbUrl.endsWith('/')
          ? firebaseDbUrl.substring(0, firebaseDbUrl.length - 1)
          : firebaseDbUrl;
      final uri = Uri.parse('$sanitizedUrl/devices/$deviceId/current.json');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        httpClient.close();

        if (responseBody.isEmpty || responseBody == 'null') {
          return null;
        }

        final Map<String, dynamic> json = jsonDecode(responseBody);
        return SensorData.fromJson(json);
      }
      httpClient.close();
    } catch (e) {
      // Return null or handle offline fallback silently
    }
    return null;
  }

  /// Fetch historical readings from Firebase RTDB `/devices/{deviceId}/history.json`
  Future<List<SensorData>> fetchHistoryLogs({int limit = 50}) async {
    final List<SensorData> history = [];
    try {
      final sanitizedUrl = firebaseDbUrl.endsWith('/')
          ? firebaseDbUrl.substring(0, firebaseDbUrl.length - 1)
          : firebaseDbUrl;
      final uri = Uri.parse(
          '$sanitizedUrl/devices/$deviceId/history.json?orderBy="\$key"&limitToLast=$limit');

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);
      final request = await httpClient.getUrl(uri);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        httpClient.close();

        if (responseBody.isNotEmpty && responseBody != 'null') {
          final Map<String, dynamic> jsonMap = jsonDecode(responseBody);
          jsonMap.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              history.add(SensorData.fromJson(value));
            }
          });

          // Sort chronologically
          history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
      } else {
        httpClient.close();
      }
    } catch (e) {
      // Fallback or empty log
    }
    return history;
  }

  /// Push an alert event to Firebase RTDB `/devices/{deviceId}/alerts.json`
  Future<bool> pushAlert(AlertModel alert) async {
    try {
      final sanitizedUrl = firebaseDbUrl.endsWith('/')
          ? firebaseDbUrl.substring(0, firebaseDbUrl.length - 1)
          : firebaseDbUrl;
      final uri = Uri.parse('$sanitizedUrl/devices/$deviceId/alerts.json');

      final httpClient = HttpClient();
      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(alert.toJson()));
      final response = await request.close();
      httpClient.close();

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Dispose timers and stream controllers
  void dispose() {
    _pollingTimer?.cancel();
    _sensorStreamController?.close();
  }
}
