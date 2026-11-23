import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/providers/sensor_provider.dart';
import 'package:lettuceguard/services/firebase_service.dart';
import 'history_test_helpers.dart';

void main() {
  test(
    'Firebase loads correct path, query, auth, sorts and deduplicates exact records',
    () async {
      final first = readingJson(time: DateTime(2026, 11, 23, 8));
      final last = readingJson(time: DateTime(2026, 11, 23, 9), tds: 810);
      final service = FirebaseService(
        firebaseDbUrl: 'https://example.invalid/',
        deviceId: 'test-node',
        tokenProvider: () async => 'test-token',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/devices/test-node/history.json');
          expect(request.url.queryParameters['orderBy'], '"\$key"');
          expect(request.url.queryParameters['limitToLast'], '100');
          expect(request.url.queryParameters['auth'], 'test-token');
          return http.Response(
            jsonEncode({
              'z': last,
              'a': first,
              'duplicate': first,
              'same-time-distinct': {...first, 'tds': 724},
              'undated': {'tds': 700},
              'bad': 42,
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      final history = await service.fetchHistoryLogs();
      expect(history.length, 3);
      expect(history.first.timestamp, DateTime(2026, 11, 23, 8));
      expect(history.last.tds, 810);
      expect(service.skippedHistoryRecords, 2);
      expect(service.duplicateHistoryRecords, 1);
    },
  );

  test(
    'legacy uptime is recovered from push key and identified as stored time',
    () async {
      final time = DateTime(2026, 11, 23, 8, 10);
      final key = pushKey(time);
      expect(FirebaseService.historyKeyTimestamp(key), time);
      final service = fixtureService({
        key: readingJson()..['timestamp'] = 300000,
      });
      addTearDown(service.dispose);
      final records = await service.fetchHistoryLogs();
      expect(records.single.timestamp, time);
      expect(records.single.timestampFromHistoryKey, isTrue);
    },
  );

  test(
    'Firebase empty is different from network, permissions and corrupt response failures',
    () async {
      final empty = fixtureService(null);
      addTearDown(empty.dispose);
      expect(await empty.fetchHistoryLogs(), isEmpty);
      for (final service in [
        fixtureService({'error': 'denied'}, status: 401),
        fixtureService('invalid shape'),
      ]) {
        addTearDown(service.dispose);
        await expectLater(service.fetchHistoryLogs(), throwsA(anything));
      }
    },
  );

  test(
    'demo and Firebase histories stay separate across switches and stale requests',
    () async {
      final service = PendingHistoryService();
      final provider = SensorProvider(
        firebaseService: service,
        initialEsp32Url: '',
      );
      addTearDown(provider.dispose);
      expect(provider.isDemoMode, isTrue);
      expect(provider.history, isNotEmpty);
      provider.toggleDemoMode(false);
      expect(provider.history, isEmpty);
      expect(provider.currentData.hasValidTds, isFalse);
      expect(provider.isHistoryLoading, isTrue);
      provider.toggleDemoMode(true);
      final demo = provider.history;
      service.pending.first.complete([SensorData.fromJson(readingJson())]);
      await Future<void>.delayed(Duration.zero);
      expect(identical(provider.history, demo), isTrue);
      provider.toggleDemoMode(false);
      final production = SensorData.fromJson(readingJson(tds: 812));
      service.pending.last.complete([production]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.history, [production]);
      expect(provider.historyError, isNull);
      expect(provider.isHistoryLoading, isFalse);
      await provider.fetchEsp32Data();
      expect(provider.history, [production]);
    },
  );

  test(
    'history refresh failure retains only prior Firebase records and reports error',
    () async {
      var requests = 0;
      final service = FirebaseService(
        tokenProvider: () async => null,
        client: MockClient((_) async {
          requests++;
          if (requests > 1) return http.Response('denied', 403);
          return http.Response(jsonEncode({'a': readingJson(tds: 813)}), 200);
        }),
      );
      final provider = SensorProvider(
        firebaseService: service,
        initialDemoMode: false,
        initialEsp32Url: '',
      );
      addTearDown(provider.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(provider.history.single.tds, 813);
      await provider.refreshHistory();
      expect(provider.history.single.tds, 813);
      expect(
        provider.historyError,
        contains('Unable to load Firebase history'),
      );
    },
  );

  test('empty production history has no mock fallback', () async {
    final provider = SensorProvider(
      firebaseService: fixtureService(null),
      initialDemoMode: false,
      initialEsp32Url: '',
    );
    addTearDown(provider.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(provider.history, isEmpty);
    expect(provider.historyError, isNull);
  });

  test(
    'changing Firebase URL discards old database records and ignores old response',
    () async {
      final service = PendingHistoryService();
      final provider = SensorProvider(
        firebaseService: service,
        initialDemoMode: false,
        initialEsp32Url: '',
      );
      addTearDown(provider.dispose);
      provider.updateFirebaseUrl('invalid-url');
      service.pending.single.complete([SensorData.fromJson(readingJson())]);
      await Future<void>.delayed(Duration.zero);
      expect(provider.history, isEmpty);
      expect(provider.firebaseUrl, 'invalid-url');
    },
  );
}
