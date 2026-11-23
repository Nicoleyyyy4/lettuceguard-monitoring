import 'dart:convert';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';
import '../models/temperature_level.dart';
import '../utils/constants.dart';

/// A sensor operation preserves its receipt time for ordered offline retries.
class TemperatureOperation {
  const TemperatureOperation.reading(this.reading, this.at)
    : eventId = null,
      priority = null,
      kind = 'reading';
  const TemperatureOperation.action(
    this.kind,
    this.eventId,
    this.priority,
    this.at,
  ) : reading = null;
  final SensorData? reading;
  final DateTime at;
  final String kind;
  final String? eventId;
  final int? priority;
}

/// Pure, serializable detector. It never depends on widget builds or networking.
class TemperatureAlertService {
  TemperatureAlertService({
    this.config = const TemperatureAlertConfig(),
    this.deviceId = LettuceGuardConstants.defaultDeviceId,
    this.isDemo = false,
  });
  final TemperatureAlertConfig config;
  final String deviceId;
  final bool isDemo;
  AlertModel? latestEvent;
  DateTime? lastReadingTime;
  int _high = 0, _critical = 0, _low = 0, _recoveries = 0;
  TemperatureLevel? _recoveryTarget;
  int version = 0;
  TemperatureLevel get level => latestEvent?.isResolved == false
      ? latestEvent!.temperatureLevel!
      : TemperatureLevel.normal;

  String? validationProblem(SensorData data, DateTime now) {
    if (data.dht22Error) {
      return 'DHT22 sensor error; air temperature unavailable.';
    }
    if (!data.airTemperature.isFinite) return 'Air temperature unavailable.';
    // DHT22/AM2302's supported measurement range.
    if (data.airTemperature < -40 || data.airTemperature > 80) {
      return 'Implausible DHT22 air temperature.';
    }
    if (!data.hasValidTimestamp || data.timestampFromHistoryKey) {
      return 'Sensor measurement timestamp unavailable.';
    }
    if (data.timestamp.difference(now) > config.futureTolerance) {
      return 'Sensor timestamp is in the future. Check device time.';
    }
    if (now.difference(data.timestamp) > config.maxAge) {
      return 'Air temperature data is stale.';
    }
    return null;
  }

  void _resetCounts() {
    _high = 0;
    _critical = 0;
    _low = 0;
    _recoveries = 0;
    _recoveryTarget = null;
  }

  void invalidate() => _resetCounts();

  /// Returns an event only for a confirmed lifecycle change, ack, or presentation.
  AlertModel? apply(TemperatureOperation op) {
    final before = jsonEncode(toJson());
    final oldRevision = latestEvent?.revision;
    if (op.kind == 'reading') {
      _observe(op.reading!, op.at);
    } else if (op.kind == 'unavailable') {
      invalidate();
    } else if (latestEvent?.id == op.eventId &&
        latestEvent?.isResolved == false) {
      final event = latestEvent!;
      if (op.kind == 'acknowledge' &&
          !event.isAcknowledged &&
          (op.priority == null || op.priority == event.peakPriority)) {
        latestEvent = event.copyWith(
          isAcknowledged: true,
          acknowledgedAt: op.at,
          revision: event.revision + 1,
          transitions: [
            ...event.transitions,
            {'kind': 'acknowledged', 'at': op.at.millisecondsSinceEpoch},
          ],
        );
      } else if (op.kind == 'presented' &&
          (op.priority ?? 0) > event.presentedPriority &&
          (op.priority ?? 0) <= event.peakPriority) {
        latestEvent = event.copyWith(
          presentedPriority: op.priority,
          revision: event.revision + 1,
          transitions: [
            ...event.transitions,
            {
              'kind': 'presented',
              'priority': op.priority,
              'at': op.at.millisecondsSinceEpoch,
            },
          ],
        );
      }
    }
    if (jsonEncode(toJson()) != before) version++;
    return latestEvent?.revision != oldRevision ? latestEvent : null;
  }

  void _observe(SensorData data, DateTime at) {
    if (validationProblem(data, at) != null) {
      invalidate();
      return;
    }
    if (lastReadingTime != null && !data.timestamp.isAfter(lastReadingTime!)) {
      return;
    }
    if (lastReadingTime != null &&
        data.timestamp.difference(lastReadingTime!) > config.maxSampleGap) {
      _resetCounts();
    }
    lastReadingTime = data.timestamp;
    final value = data.airTemperature;
    final raw = config.classify(value);
    _high = value > config.max ? _high + 1 : 0;
    _critical = value >= config.critical ? _critical + 1 : 0;
    _low = value < config.min ? _low + 1 : 0;
    final current = level;
    TemperatureLevel? escalation;
    if (raw == TemperatureLevel.extreme) {
      escalation = TemperatureLevel.extreme;
    } else if (_critical >= config.confirmations) {
      escalation = TemperatureLevel.critical;
    } else if (_high >= config.confirmations) {
      escalation = TemperatureLevel.high;
    } else if (_low >= config.confirmations &&
        current == TemperatureLevel.normal) {
      escalation = TemperatureLevel.low;
    }
    if (escalation != null && escalation.priority > current.priority) {
      _transition(escalation, data, at);
      _recoveries = 0;
      _recoveryTarget = null;
      return;
    }
    if (current == TemperatureLevel.normal) return;
    TemperatureLevel? target;
    if (current == TemperatureLevel.extreme &&
        value < config.extreme - config.hysteresis) {
      target = value >= config.critical - config.hysteresis
          ? TemperatureLevel.critical
          : raw;
    } else if (current == TemperatureLevel.critical &&
        value < config.critical - config.hysteresis) {
      target = raw;
    } else if (current == TemperatureLevel.high && value <= config.max) {
      target = raw;
    } else if (current == TemperatureLevel.low &&
        value >= config.min + config.hysteresis) {
      target = raw;
    }
    if (target == null || target == current) {
      _recoveries = 0;
      _recoveryTarget = null;
      return;
    }
    _recoveries = _recoveryTarget == target ? _recoveries + 1 : 1;
    _recoveryTarget = target;
    if (_recoveries >= config.recoveryCount) {
      _transition(target, data, at);
      _resetCounts();
    }
  }

  void _transition(TemperatureLevel target, SensorData data, DateTime at) {
    final previous = latestEvent?.isResolved == false ? latestEvent : null;
    final recovering = target == TemperatureLevel.normal;
    final peak = target.priority > (previous?.peakPriority ?? 0)
        ? target.priority
        : previous!.peakPriority;
    final newPeak = peak > (previous?.peakPriority ?? 0);
    latestEvent = AlertModel(
      id:
          previous?.id ??
          'air_temperature_${isDemo ? 'demo_' : ''}${data.timestamp.millisecondsSinceEpoch}',
      title: target.title,
      message:
          'Air Temperature: ${data.airTemperature.toStringAsFixed(1)}°C. ${target.action}',
      sensorSource: 'DHT22',
      severity: switch (target) {
        TemperatureLevel.normal => AlertSeverity.info,
        TemperatureLevel.low || TemperatureLevel.high => AlertSeverity.warning,
        TemperatureLevel.critical => AlertSeverity.critical,
        TemperatureLevel.extreme => AlertSeverity.emergency,
      },
      timestamp: previous?.timestamp ?? at,
      isResolved: recovering,
      deviceId: deviceId,
      alertType: 'air_temperature',
      temperatureLevel: target,
      measuredTemperature: data.airTemperature,
      configuredThreshold: config.threshold(target),
      readingTimestamp: data.timestamp,
      resolvedAt: recovering ? data.timestamp : null,
      isAcknowledged: newPeak ? false : previous?.isAcknowledged ?? false,
      acknowledgedAt: newPeak ? null : previous?.acknowledgedAt,
      isDemo: isDemo,
      revision: (previous?.revision ?? 0) + 1,
      peakPriority: peak,
      presentedPriority: previous?.presentedPriority ?? 0,
      transitions: [
        ...?previous?.transitions,
        {
          'kind': recovering
              ? 'resolved'
              : previous == null
              ? 'started'
              : 'severity_changed',
          'level': target.name,
          'temperature': data.airTemperature,
          'threshold': config.threshold(target),
          'readingTimestamp': data.timestamp.millisecondsSinceEpoch,
          'at': at.millisecondsSinceEpoch,
        },
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'lastReadingTime': lastReadingTime?.millisecondsSinceEpoch,
    'highCount': _high,
    'criticalCount': _critical,
    'lowCount': _low,
    'recoveryCount': _recoveries,
    'recoveryTarget': _recoveryTarget?.name,
    'latestEvent': latestEvent?.toJson(),
  };
  factory TemperatureAlertService.fromJson(
    Map<String, dynamic> json, {
    TemperatureAlertConfig config = const TemperatureAlertConfig(),
    String deviceId = LettuceGuardConstants.defaultDeviceId,
    bool isDemo = false,
  }) {
    final service = TemperatureAlertService(
      config: config,
      deviceId: deviceId,
      isDemo: isDemo,
    );
    service.version = (json['version'] as num?)?.toInt() ?? 0;
    service.lastReadingTime = SensorData.parseTimestamp(
      json['lastReadingTime'],
    );
    service._high = (json['highCount'] as num?)?.toInt() ?? 0;
    service._critical = (json['criticalCount'] as num?)?.toInt() ?? 0;
    service._low = (json['lowCount'] as num?)?.toInt() ?? 0;
    service._recoveries = (json['recoveryCount'] as num?)?.toInt() ?? 0;
    service._recoveryTarget = TemperatureLevel.values
        .where((l) => l.name == json['recoveryTarget'])
        .firstOrNull;
    final event = json['latestEvent'];
    if (event is Map) {
      service.latestEvent = AlertModel.fromJson(
        Map<String, dynamic>.from(event),
        event['id'],
      );
    }
    return service;
  }
}
