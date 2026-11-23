import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/providers/sensor_provider.dart';
import 'package:lettuceguard/services/firebase_service.dart';

Map<String, dynamic> readingJson({double tds = 723, DateTime? time}) => {
  'ph': 6.06,
  'waterTemperature': 20.6,
  'airTemperature': 23.6,
  'airHumidity': 64,
  'waterLevel': {'percentage': 90, 'distanceCm': 3},
  'tds': tds,
  'timestamp': (time ?? DateTime(2026, 11, 23, 8, 10)).millisecondsSinceEpoch,
};

FirebaseService fixtureService(Object? payload, {int status = 200}) =>
    FirebaseService(
      client: MockClient(
        (_) async => http.Response(jsonEncode(payload), status),
      ),
      tokenProvider: () async => null,
    );

class HistoryFixture extends SensorProvider {
  HistoryFixture(List<SensorData> records)
    : _records = List.unmodifiable(records);
  List<SensorData> _records;
  @override
  List<SensorData> get history => _records;
  void replace(List<SensorData> records) {
    _records = List.unmodifiable(records);
    notifyListeners();
  }
}

Widget historyHost(SensorProvider provider, Widget child) =>
    SensorProviderScope(
      provider: provider,
      child: _ProviderOwner(
        provider: provider,
        child: MaterialApp(home: child),
      ),
    );

Future<void> selectParameter(WidgetTester tester, String name) async {
  final chip = find.byKey(ValueKey('parameter-$name'));
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pumpAndSettle();
}

String pushKey(DateTime time) {
  const chars =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
  var ms = time.millisecondsSinceEpoch;
  var prefix = '';
  for (var i = 0; i < 8; i++) {
    prefix = chars[ms % 64] + prefix;
    ms ~/= 64;
  }
  return '$prefix------------';
}

class PendingHistoryService extends FirebaseService {
  final pending = <Completer<List<SensorData>>>[];
  @override
  Future<List<SensorData>> fetchHistoryLogs({int limit = 100}) {
    final request = Completer<List<SensorData>>();
    pending.add(request);
    return request.future;
  }
}

class _ProviderOwner extends StatefulWidget {
  const _ProviderOwner({required this.provider, required this.child});
  final SensorProvider provider;
  final Widget child;
  @override
  State<_ProviderOwner> createState() => _ProviderOwnerState();
}

class _ProviderOwnerState extends State<_ProviderOwner> {
  @override
  void dispose() {
    widget.provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
