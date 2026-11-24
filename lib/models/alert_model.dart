import 'temperature_level.dart';

enum AlertSeverity { info, warning, error, critical, emergency }

/// Existing alert representation, extended with optional temperature audit data.
class AlertModel {
  final String id, title, message, sensorSource;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;
  final String? deviceId, alertType;
  final TemperatureLevel? temperatureLevel;
  final double? measuredTemperature, configuredThreshold;
  final DateTime? readingTimestamp, acknowledgedAt, resolvedAt;
  final bool isAcknowledged, isDemo;
  final int revision, peakPriority, presentedPriority;
  final List<Map<String, dynamic>> transitions;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.sensorSource,
    required this.severity,
    required this.timestamp,
    this.isResolved = false,
    this.deviceId,
    this.alertType,
    this.temperatureLevel,
    this.measuredTemperature,
    this.configuredThreshold,
    this.readingTimestamp,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.resolvedAt,
    this.isDemo = false,
    this.revision = 0,
    this.peakPriority = 0,
    this.presentedPriority = 0,
    this.transitions = const [],
  });
  bool get isTemperatureAlert =>
      alertType == 'air_temperature' || alertType == 'water_temperature';
  bool get isWaterTemperatureAlert => alertType == 'water_temperature';
  bool get needsPopup =>
      !isResolved &&
      !isAcknowledged &&
      (temperatureLevel?.priority ?? 0) >= TemperatureLevel.critical.priority &&
      presentedPriority < peakPriority;
  String get popupToken => '$id:$peakPriority';

  factory AlertModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime? date(Object? value) => value is num
        ? DateTime.fromMillisecondsSinceEpoch(value.toInt())
        : DateTime.tryParse('$value');
    final name = json['severity'] == 'extreme' ? 'emergency' : json['severity'];
    return AlertModel(
      id: id,
      title: json['title'] ?? 'System Alert',
      message: json['message'] ?? '',
      sensorSource: json['sensorSource'] ?? 'General',
      severity:
          AlertSeverity.values.where((s) => s.name == name).firstOrNull ??
          AlertSeverity.info,
      timestamp:
          date(json['timestamp']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isResolved: json['isResolved'] == true || json['status'] == 'resolved',
      deviceId: json['deviceId'],
      alertType: json['alertType'],
      temperatureLevel: TemperatureLevel.values
          .where((s) => s.name == json['temperatureLevel'])
          .firstOrNull,
      measuredTemperature: (json['measuredTemperature'] as num?)?.toDouble(),
      configuredThreshold: (json['configuredThreshold'] as num?)?.toDouble(),
      readingTimestamp: date(json['readingTimestamp']),
      isAcknowledged: json['isAcknowledged'] == true,
      acknowledgedAt: date(json['acknowledgedAt']),
      resolvedAt: date(json['resolvedAt']),
      isDemo: json['isDemo'] == true,
      revision: (json['revision'] as num?)?.toInt() ?? 0,
      peakPriority: (json['peakPriority'] as num?)?.toInt() ?? 0,
      presentedPriority: (json['presentedPriority'] as num?)?.toInt() ?? 0,
      transitions:
          (json['transitions'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'sensorSource': sensorSource,
    'severity': severity.name,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'isResolved': isResolved,
    if (isTemperatureAlert) ...{
      'deviceId': deviceId,
      'alertType': alertType,
      'temperatureLevel': temperatureLevel?.name,
      'measuredTemperature': measuredTemperature,
      'configuredThreshold': configuredThreshold,
      'readingTimestamp': readingTimestamp?.millisecondsSinceEpoch,
      'status': isResolved ? 'resolved' : 'active',
      'isAcknowledged': isAcknowledged,
      'acknowledgedAt': acknowledgedAt?.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'isDemo': isDemo,
      'revision': revision,
      'peakPriority': peakPriority,
      'presentedPriority': presentedPriority,
      'transitions': transitions,
    },
  };
  AlertModel copyWith({
    bool? isResolved,
    bool? isAcknowledged,
    DateTime? acknowledgedAt,
    int? presentedPriority,
    List<Map<String, dynamic>>? transitions,
    int? revision,
  }) => AlertModel.fromJson({
    ...toJson(),
    'isResolved': ?isResolved,
    if (isResolved != null) 'status': isResolved ? 'resolved' : 'active',
    'isAcknowledged': ?isAcknowledged,
    if (acknowledgedAt != null)
      'acknowledgedAt': acknowledgedAt.millisecondsSinceEpoch,
    'presentedPriority': ?presentedPriority,
    'transitions': ?transitions,
    'revision': ?revision,
  }, id);
}
