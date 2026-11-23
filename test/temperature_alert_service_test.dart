import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/models/temperature_level.dart';
import 'package:lettuceguard/services/temperature_alert_service.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'history_test_helpers.dart';

class DetectorHarness {
  DetectorHarness({
    TemperatureAlertConfig config = const TemperatureAlertConfig(),
  }) : detector = TemperatureAlertService(config: config, isDemo: true);
  TemperatureAlertService detector;
  DateTime now = DateTime.utc(2026, 11, 23, 1);
  SensorData sample(double temperature, {bool error = false}) =>
      SensorData.fromJson({
        ...readingJson(time: now),
        'airTemperature': temperature,
        'sensorErrors': {'dht22Error': error},
      });
  void read(double value, {bool error = false}) {
    now = now.add(const Duration(seconds: 3));
    detector.apply(
      TemperatureOperation.reading(sample(value, error: error), now),
    );
  }

  void confirm(double value) {
    for (var i = 0; i < 3; i++) {
      read(value);
    }
  }
}

void main() {
  const config = TemperatureAlertConfig();
  final cases = <double, TemperatureLevel>{
    17: TemperatureLevel.low,
    18: TemperatureLevel.normal,
    23.6: TemperatureLevel.normal,
    24: TemperatureLevel.normal,
    26: TemperatureLevel.normal,
    26.1: TemperatureLevel.high,
    28: TemperatureLevel.high,
    29.9: TemperatureLevel.high,
    30: TemperatureLevel.critical,
    32: TemperatureLevel.critical,
    34.9: TemperatureLevel.critical,
    35: TemperatureLevel.extreme,
    38: TemperatureLevel.extreme,
  };
  for (final entry in cases.entries) {
    test(
      '${entry.key} degrees classifies and confirms ${entry.value.name}',
      () {
        expect(config.classify(entry.key), entry.value);
        final h = DetectorHarness()..confirm(entry.key);
        expect(h.detector.level, entry.value);
        if (entry.value == TemperatureLevel.normal) {
          expect(h.detector.latestEvent, isNull);
        } else {
          expect(h.detector.latestEvent!.temperatureLevel, entry.value);
        }
      },
    );
  }
  test(
    'three distinct valid readings confirm high and critical; extreme is immediate',
    () {
      for (final value in [28.0, 32.0]) {
        final h = DetectorHarness();
        h.read(value);
        h.read(value);
        expect(h.detector.latestEvent, isNull);
        h.read(value);
        expect(h.detector.latestEvent, isNotNull);
      }
      final h = DetectorHarness()..read(35);
      expect(h.detector.level, TemperatureLevel.extreme);
    },
  );
  test(
    'identical snapshots never count as new samples or produce repeated events',
    () {
      final h = DetectorHarness();
      final sample = h.sample(32);
      for (var i = 0; i < 20; i++) {
        h.detector.apply(TemperatureOperation.reading(sample, h.now));
      }
      expect(h.detector.latestEvent, isNull);
      h.read(32);
      h.read(32);
      final event = h.detector.latestEvent!;
      for (var i = 0; i < 30; i++) {
        h.read(32);
      }
      expect(h.detector.latestEvent!.id, event.id);
      expect(h.detector.latestEvent!.transitions, hasLength(1));
    },
  );
  test(
    'escalation keeps one event, records transitions, and reopens popup only at new peak',
    () {
      final h = DetectorHarness()..confirm(28);
      final id = h.detector.latestEvent!.id;
      h.confirm(32);
      expect(h.detector.latestEvent!.id, id);
      expect(h.detector.latestEvent!.needsPopup, isTrue);
      h.detector.apply(TemperatureOperation.action('presented', id, 3, h.now));
      h.detector.apply(
        TemperatureOperation.action('acknowledge', id, 3, h.now),
      );
      expect(h.detector.latestEvent!.isResolved, isFalse);
      expect(h.detector.latestEvent!.isAcknowledged, isTrue);
      expect(h.detector.latestEvent!.needsPopup, isFalse);
      h.read(35);
      expect(h.detector.latestEvent!.id, id);
      expect(h.detector.latestEvent!.needsPopup, isTrue);
      expect(h.detector.latestEvent!.isAcknowledged, isFalse);
    },
  );
  test(
    'sustained normal readings resolve with actual recovery time and preserve audit',
    () {
      final h = DetectorHarness()..confirm(32);
      h.read(24);
      h.read(24);
      expect(h.detector.latestEvent!.isResolved, isFalse);
      h.read(24);
      expect(h.detector.latestEvent!.isResolved, isTrue);
      expect(
        h.detector.latestEvent!.resolvedAt!.isAtSameMomentAs(h.now),
        isTrue,
      );
      expect(h.detector.latestEvent!.title, 'TEMPERATURE RETURNED TO NORMAL');
      expect(h.detector.latestEvent!.transitions.last['kind'], 'resolved');
    },
  );
  test(
    'hysteresis holds critical until below 29 and extreme until below 34',
    () {
      final h = DetectorHarness()..confirm(32);
      h.confirm(29.5);
      expect(h.detector.level, TemperatureLevel.critical);
      h.confirm(28.9);
      expect(h.detector.level, TemperatureLevel.high);
      expect(h.detector.latestEvent!.isResolved, isFalse);
      h.read(36);
      h.confirm(34.5);
      expect(h.detector.level, TemperatureLevel.extreme);
      h.confirm(33.9);
      expect(h.detector.level, TemperatureLevel.critical);
    },
  );
  test(
    'fluctuation and invalid samples break confirmation without false recovery',
    () {
      final h = DetectorHarness();
      for (var i = 0; i < 12; i++) {
        h.read(i.isEven ? 28 : 26);
      }
      expect(h.detector.latestEvent, isNull);
      h.read(32);
      h.read(32);
      h.read(0, error: true);
      h.read(32);
      expect(h.detector.latestEvent, isNull);
      h.read(32);
      h.read(32);
      h.read(24);
      h.read(0, error: true);
      h.read(24);
      h.read(24);
      expect(h.detector.latestEvent!.isResolved, isFalse);
    },
  );
  test(
    'missing, nonfinite, implausible, stale, future and undated readings never alert',
    () {
      final h = DetectorHarness();
      for (final value in [null, double.nan, double.infinity, -41, 81, 'bad']) {
        final sample = SensorData.fromJson({
          ...readingJson(time: h.now),
          'airTemperature': value,
        });
        for (var i = 0; i < 3; i++) {
          h.detector.apply(TemperatureOperation.reading(sample, h.now));
        }
        expect(h.detector.latestEvent, isNull);
      }
      for (final timestamp in [
        null,
        h.now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
        h.now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      ]) {
        final sample = SensorData.fromJson({
          ...readingJson(),
          'airTemperature': 38,
          'timestamp': timestamp,
        });
        h.detector.apply(TemperatureOperation.reading(sample, h.now));
        expect(h.detector.latestEvent, isNull);
      }
    },
  );
  test('large sampling gaps reset pending confirmation and recovery', () {
    final h = DetectorHarness();
    h.read(32);
    h.read(32);
    h.now = h.now.add(const Duration(seconds: 20));
    h.read(32);
    expect(h.detector.latestEvent, isNull);
    h.read(32);
    h.read(32);
    h.read(24);
    h.read(24);
    h.now = h.now.add(const Duration(seconds: 20));
    h.read(24);
    expect(h.detector.latestEvent!.isResolved, isFalse);
  });
  test(
    'serialized state survives restart, preserving counts, event, and acknowledgment',
    () {
      final h = DetectorHarness()
        ..read(32)
        ..read(32);
      h.detector = TemperatureAlertService.fromJson(
        h.detector.toJson(),
        isDemo: true,
      );
      h.read(32);
      final id = h.detector.latestEvent!.id;
      h.detector.apply(
        TemperatureOperation.action('acknowledge', id, 3, h.now),
      );
      h.detector = TemperatureAlertService.fromJson(
        h.detector.toJson(),
        isDemo: true,
      );
      h.read(32);
      expect(h.detector.latestEvent!.id, id);
      expect(h.detector.latestEvent!.isAcknowledged, isTrue);
      expect(h.detector.latestEvent!.needsPopup, isFalse);
    },
  );
  test('configurable confirmation and recovery counts apply', () {
    final h = DetectorHarness(
      config: const TemperatureAlertConfig(confirmations: 2, recoveryCount: 2),
    );
    h.read(32);
    expect(h.detector.latestEvent, isNull);
    h.read(32);
    expect(h.detector.level, TemperatureLevel.critical);
    h.read(24);
    expect(h.detector.latestEvent!.isResolved, isFalse);
    h.read(24);
    expect(h.detector.latestEvent!.isResolved, isTrue);
  });
}
