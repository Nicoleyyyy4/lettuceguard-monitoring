import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/models/chart_parameter.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/utils/constants.dart';
import 'history_test_helpers.dart';

void main() {
  test(
    'TDS parser distinguishes absent, malformed, nonfinite, error, and real zero',
    () {
      for (final raw in [null, 'bad', double.nan, double.infinity, -1]) {
        final record = SensorData.fromJson(readingJson()..['tds'] = raw);
        expect(ChartParameter.tds.valueOf(record), isNull);
        expect(record.isTdsOutOfRange, isFalse);
        expect(() => jsonEncode(record.toJson()), returnsNormally);
      }
      final missing = SensorData.fromJson(readingJson()..remove('tds'));
      expect(missing.tds.isNaN, isTrue);
      expect(missing.toJson()['tds'], isNull);
      final zero = SensorData.fromJson(readingJson(tds: 0));
      expect(ChartParameter.tds.valueOf(zero), 0);
      final flagged = SensorData.fromJson(
        readingJson(tds: 720)..['sensorErrors'] = {'tdsError': true},
      );
      expect(ChartParameter.tds.valueOf(flagged), isNull);
      expect(ChartParameter.tds.minOptimal, LettuceGuardConstants.minTds);
      expect(ChartParameter.tds.maxOptimal, LettuceGuardConstants.maxTds);
    },
  );

  test(
    'timestamps support milliseconds, seconds, ISO, and reject undated uptime',
    () {
      final time = DateTime.utc(2026, 11, 23, 0, 10);
      for (final raw in [
        time.millisecondsSinceEpoch,
        time.millisecondsSinceEpoch ~/ 1000,
        '${time.millisecondsSinceEpoch}',
        time.toIso8601String(),
      ]) {
        expect(SensorData.parseTimestamp(raw), time.toLocal());
      }
      for (final raw in [null, 'bad', 300000, double.infinity]) {
        final record = SensorData.fromJson(readingJson()..['timestamp'] = raw);
        expect(record.hasValidTimestamp, isFalse);
      }
    },
  );

  test(
    'chart sorts and uses true spacing for irregular samples, retaining gaps',
    () {
      final start = DateTime(2026, 11, 23, 8);
      final a = SensorData.fromJson(readingJson(time: start));
      final b = SensorData.fromJson(
        readingJson(time: start.add(const Duration(minutes: 1)))..remove('tds'),
      );
      final c = SensorData.fromJson(
        readingJson(time: start.add(const Duration(minutes: 10)), tds: 900),
      );
      final series = HistoryChartData([c, a, b], ChartParameter.tds);
      expect(series.records, [a, b, c]);
      expect(series.xFraction(0), 0);
      expect(series.xFraction(1), .1);
      expect(series.xFraction(2), 1);
      expect(series.values, [723, null, 900]);
      expect(series.validCount, 2);
      expect(series.minY, lessThan(LettuceGuardConstants.minTds));
      expect(series.maxY, greaterThan(900));
      for (final value in series.values.whereType<double>()) {
        expect(series.yFraction(value), inInclusiveRange(0, 1));
      }
    },
  );

  test(
    'empty, constant, singleton and same-time series have finite geometry',
    () {
      final reading = SensorData.fromJson(readingJson());
      for (final records in <List<SensorData>>[
        [],
        [reading],
        [reading, reading],
      ]) {
        for (final param in ChartParameter.values) {
          final series = HistoryChartData(records, param);
          expect(series.minY.isFinite && series.maxY.isFinite, isTrue);
          expect(series.maxY, greaterThan(series.minY));
          if (records.isNotEmpty) expect(series.xFraction(0), .5);
        }
      }
    },
  );

  test('extreme finite payloads cannot overflow chart geometry', () {
    final record = SensorData.fromJson(
      readingJson()..['tds'] = double.maxFinite,
    );
    final series = HistoryChartData([record], ChartParameter.tds);
    expect(series.values.single, isNull);
    expect(series.minY.isFinite && series.maxY.isFinite, isTrue);
  });

  test('all history parameters suppress sensor faults and missing fields', () {
    final bad = SensorData.fromJson(
      readingJson()
        ..['sensorErrors'] = {
          'dht22Error': true,
          'ds18b20Error': true,
          'phError': true,
          'ultrasonicError': true,
          'tdsError': true,
        },
    );
    for (final param in ChartParameter.values) {
      expect(param.valueOf(bad), isNull);
      expect(param.valueOf(SensorData.fromJson({})), isNull);
    }
  });
}
