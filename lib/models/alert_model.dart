enum AlertSeverity { info, warning, error }

/// Represents an alert event logged or flagged in the LettuceGuard system
class AlertModel {
  final String id;
  final String title;
  final String message;
  final String sensorSource; // e.g. DHT22, DS18B20, pH, HC-SR04, ADC
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isResolved;

  const AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.sensorSource,
    required this.severity,
    required this.timestamp,
    this.isResolved = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json, String id) {
    AlertSeverity sev = AlertSeverity.info;
    final sevStr = (json['severity'] as String?)?.toLowerCase();
    if (sevStr == 'error' || sevStr == 'critical') {
      sev = AlertSeverity.error;
    } else if (sevStr == 'warning') {
      sev = AlertSeverity.warning;
    }

    DateTime ts;
    if (json['timestamp'] is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(json['timestamp']);
    } else {
      ts = DateTime.now();
    }

    return AlertModel(
      id: id,
      title: json['title'] ?? 'System Alert',
      message: json['message'] ?? '',
      sensorSource: json['sensorSource'] ?? 'General',
      severity: sev,
      timestamp: ts,
      isResolved: json['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'sensorSource': sensorSource,
      'severity': severity.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isResolved': isResolved,
    };
  }
}
