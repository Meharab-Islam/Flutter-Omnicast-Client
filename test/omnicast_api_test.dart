import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  group('OmniCastApi Unit Tests', () {
    test('defaultHeaders includes API Key and Secret when configured', () {
      const config = OmniCastConfig(
        hostUrl: 'wss://omnilive.lolipoplive.top/ws',
        apiUrl: 'https://omnilive.lolipoplive.top/api',
        apiKey: 'test_api_key_123',
        apiSecret: 'test_api_secret_456',
      );

      final api = OmniCastApi(config: config);
      final headers = api.defaultHeaders;

      expect(headers['X-API-KEY'], 'test_api_key_123');
      expect(headers['X-API-SECRET'], 'test_api_secret_456');
      expect(headers['Authorization'], 'Bearer test_api_key_123');
      expect(headers['Content-Type'], 'application/json');

      api.dispose();
    });

    test('getLiveRooms parses JSON list into RoomModel list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/rooms');
        expect(request.headers['X-API-KEY'], 'test_api_key_123');
        expect(request.headers['X-API-SECRET'], 'test_api_secret_456');

        final sampleJson = [
          {
            'room_id': 'room_101',
            'title': 'Gaming Live 🔥',
            'host_id': 'host_alice',
            'host_name': 'Alice Streamer',
            'room_type': 'video',
            'viewer_count': 42,
            'created_at': '2026-08-30T10:00:00Z',
            'metadata': {'game': 'Cyberpunk'},
          },
          {
            'room_id': 'room_102',
            'title': 'Chill Music 🎧',
            'host_id': 'host_bob',
            'host_name': 'Bob DJ',
            'room_type': 'audio',
            'viewer_count': 18,
            'created_at': '2026-08-30T10:30:00Z',
          }
        ];

        return http.Response(jsonEncode(sampleJson), 200, headers: {'content-type': 'application/json'});
      });

      const config = OmniCastConfig(
        hostUrl: 'wss://omnilive.lolipoplive.top/ws',
        apiKey: 'test_api_key_123',
        apiSecret: 'test_api_secret_456',
      );

      final api = OmniCastApi(config: config, client: mockClient);
      final rooms = await api.getLiveRooms();

      expect(rooms.length, 2);
      expect(rooms[0].roomId, 'room_101');
      expect(rooms[0].title, 'Gaming Live 🔥');
      expect(rooms[0].hostName, 'Alice Streamer');
      expect(rooms[0].roomType, RoomType.video);
      expect(rooms[0].viewerCount, 42);
      expect(rooms[0].metadata['game'], 'Cyberpunk');

      expect(rooms[1].roomId, 'room_102');
      expect(rooms[1].title, 'Chill Music 🎧');
      expect(rooms[1].roomType, RoomType.audio);
      expect(rooms[1].viewerCount, 18);

      api.dispose();
    });

    test('OmniCastClient exposes api getter and static instance', () async {
      final client = OmniCastClient.custom(
        config: const OmniCastConfig(
          hostUrl: 'ws://localhost',
          apiKey: 'key_1',
          apiSecret: 'sec_1',
          heartbeatInterval: Duration.zero,
        ),
      );

      expect(client.api, isNotNull);
      expect(OmniCastClient.instance, equals(client));
      expect(client.api.defaultHeaders['X-API-KEY'], 'key_1');

      await client.dispose();
      expect(OmniCastClient.instance, isNull);
    });
  });
}
