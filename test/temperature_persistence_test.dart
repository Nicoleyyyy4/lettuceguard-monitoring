import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/services/temperature_alert_service.dart';
import 'package:lettuceguard/providers/sensor_provider.dart';
import 'temperature_firebase_fixture.dart';
import 'history_test_helpers.dart';

void main() {
  final start = DateTime.utc(2026, 11, 23, 1);
  TemperatureOperation reading(int i, double t) {
    final time = start.add(Duration(seconds: i * 3));
    return TemperatureOperation.reading(
      SensorData.fromJson({...readingJson(time: time), 'airTemperature': t}),
      time,
    );
  }

  test(
    'conditional writes archive one event with escalating severity, ack and recovery',
    () async {
      final fixture = TemperatureFirebaseFixture();
      final service = fixture.service();
      addTearDown(service.dispose);
      for (var i = 1; i <= 3; i++) {
        await service.applyTemperatureOperation(reading(i, 28));
      }
      expect(fixture.events, hasLength(1));
      final id = (fixture.events.single as Map)['id'];
      for (var i = 4; i <= 6; i++) {
        await service.applyTemperatureOperation(reading(i, 32));
      }
      await service.applyTemperatureOperation(reading(7, 36));
      var state = await service.loadTemperatureState();
      expect((state['latestEvent'] as Map)['id'], id);
      expect((state['latestEvent'] as Map)['severity'], 'emergency');
      await service.applyTemperatureOperation(
        TemperatureOperation.action(
          'acknowledge',
          id,
          4,
          start.add(const Duration(seconds: 22)),
        ),
      );
      state = await service.loadTemperatureState();
      expect((state['latestEvent'] as Map)['isResolved'], isFalse);
      for (var i = 8; i <= 10; i++) {
        await service.applyTemperatureOperation(reading(i, 24));
      }
      expect(fixture.events, hasLength(1));
      expect((fixture.events.single as Map)['isResolved'], isTrue);
      expect(
        (fixture.events.single as Map)['resolvedAt'],
        start.add(const Duration(seconds: 30)).millisecondsSinceEpoch,
      );
      expect(
        fixture.requests
            .where((r) => r.method == 'PUT')
            .every(
              (r) =>
                  r.headers['if-match'] != null &&
                  r.url.queryParameters['auth'] == 'test-token',
            ),
        isTrue,
      );
      expect(
        fixture.requests.every(
          (r) => r.url.path.contains('/alerts/air_temperature/'),
        ),
        isTrue,
      );
    },
  );
  test(
    'two clients cannot count one snapshot twice or create two events',
    () async {
      final fixture = TemperatureFirebaseFixture();
      final a = fixture.service(), b = fixture.service();
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      await Future.wait([
        a.applyTemperatureOperation(reading(1, 32)),
        b.applyTemperatureOperation(reading(1, 32)),
      ]);
      expect((await a.loadTemperatureState())['criticalCount'], 1);
      for (var i = 2; i <= 3; i++) {
        await Future.wait([
          a.applyTemperatureOperation(reading(i, 32)),
          b.applyTemperatureOperation(reading(i, 32)),
        ]);
      }
      expect(fixture.events, hasLength(1));
    },
  );
  test(
    'restart restores an acknowledged active event without duplicate records',
    () async {
      final fixture = TemperatureFirebaseFixture();
      final service = fixture.service();
      await service.applyTemperatureOperation(reading(1, 36));
      var state = await service.loadTemperatureState();
      final id = (state['latestEvent'] as Map)['id'];
      await service.applyTemperatureOperation(
        TemperatureOperation.action('acknowledge', id, 4, start),
      );
      service.dispose();
      final restarted = fixture.service();
      addTearDown(restarted.dispose);
      state = await restarted.applyTemperatureOperation(reading(2, 36));
      expect((state['latestEvent'] as Map)['id'], id);
      expect((state['latestEvent'] as Map)['isAcknowledged'], isTrue);
      expect(fixture.events, hasLength(1));
    },
  );
  test(
    'archive failure is repaired on retry, preserving the event audit',
    () async {
      final fixture = TemperatureFirebaseFixture()..failArchiveOnce = true;
      final service = fixture.service();
      addTearDown(service.dispose);
      await expectLater(
        service.applyTemperatureOperation(reading(1, 36)),
        throwsStateError,
      );
      expect((await service.loadTemperatureState())['latestEvent'], isNotNull);
      await service.applyTemperatureOperation(reading(1, 36));
      expect(fixture.events, hasLength(1));
      fixture.conflictOnce = true;
      await service.applyTemperatureOperation(reading(2, 36));
      expect(fixture.events, hasLength(1));
    },
  );
  test(
    'signed-out and denied writes fail without weakening authorization',
    () async {
      final fixture = TemperatureFirebaseFixture();
      final signedOut = fixture.service(token: null);
      addTearDown(signedOut.dispose);
      await expectLater(
        signedOut.applyTemperatureOperation(reading(1, 36)),
        throwsStateError,
      );
      expect(fixture.requests.where((r) => r.method == 'PUT'), isEmpty);
      fixture.denyWrites = true;
      final denied = fixture.service();
      addTearDown(denied.dispose);
      await expectLater(
        denied.applyTemperatureOperation(reading(1, 36)),
        throwsStateError,
      );
      expect(fixture.events, isEmpty);
    },
  );
  test(
    'a second incident gets a new ID without erasing the recovered event',
    () async {
      final fixture = TemperatureFirebaseFixture();
      final service = fixture.service();
      addTearDown(service.dispose);
      await service.applyTemperatureOperation(reading(1, 36));
      for (var i = 2; i <= 4; i++) {
        await service.applyTemperatureOperation(reading(i, 24));
      }
      await service.applyTemperatureOperation(reading(5, 36));
      expect(fixture.events, hasLength(2));
      expect(
        fixture.events.where((e) => (e as Map)['isResolved'] == true),
        hasLength(1),
      );
    },
  );
  test('provider restores an existing active event on startup', () async {
    final fixture = TemperatureFirebaseFixture();
    final first = fixture.service();
    await first.applyTemperatureOperation(reading(1, 36));
    final existingId = (fixture.events.single as Map)['id'];
    first.dispose();
    final provider = SensorProvider(
      firebaseService: fixture.service(),
      initialDemoMode: false,
      initialEsp32Url: '',
      clock: () => start.add(const Duration(seconds: 6)),
    );
    addTearDown(provider.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await provider.syncTemperatureAlerts();
    expect(provider.activeTemperatureAlert!.id, existingId);
    expect(provider.temperatureSyncError, isNull);
    expect(provider.temperatureDataProblem, isNotNull);
    expect(fixture.events, hasLength(1));
  });
}
