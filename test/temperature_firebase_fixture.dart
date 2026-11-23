import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lettuceguard/services/firebase_service.dart';

/// RTDB-shaped in-memory fixture with per-location ETags, never a live database.
class TemperatureFirebaseFixture {
  final nodes = <String, Object?>{};
  final versions = <String, int>{};
  final requests = <http.Request>[];
  bool offline = false,
      denyWrites = false,
      conflictOnce = false,
      failArchiveOnce = false;
  String root = '/devices/lettuceguard_node_01/alerts/air_temperature';
  FirebaseService service({String? token = 'test-token'}) => FirebaseService(
    firebaseDbUrl: 'https://example.invalid',
    tokenProvider: () async => token,
    client: MockClient((request) async {
      requests.add(request);
      if (offline) throw http.ClientException('Offline fixture');
      final path = request.url.path.replaceFirst(RegExp(r'\.json$'), '');
      final headers = {'etag': '"${versions[path] ?? 0}"'};
      if (request.method == 'GET') {
        if (path.endsWith('/events')) {
          final events = <String, Object?>{};
          for (final key in nodes.keys.where((k) => k.startsWith('$path/'))) {
            events[key.substring(path.length + 1)] = nodes[key];
          }
          return http.Response(
            jsonEncode(events.isEmpty ? null : events),
            200,
            headers: headers,
          );
        }
        return http.Response(jsonEncode(nodes[path]), 200, headers: headers);
      }
      if (denyWrites) return http.Response('Permission denied', 403);
      if (failArchiveOnce && path.contains('/events/')) {
        failArchiveOnce = false;
        return http.Response('Unavailable', 503);
      }
      if (request.headers['if-match'] != headers['etag'] || conflictOnce) {
        conflictOnce = false;
        return http.Response(jsonEncode(nodes[path]), 412, headers: headers);
      }
      nodes[path] = jsonDecode(request.body);
      versions[path] = (versions[path] ?? 0) + 1;
      return http.Response(request.body, 200);
    }),
  );
  List<Object?> get events => nodes.entries
      .where((e) => e.key.contains('/events/'))
      .map((e) => e.value)
      .toList();
}
