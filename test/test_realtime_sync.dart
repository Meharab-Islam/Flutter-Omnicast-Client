import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:omnicast_client/omnicast_client.dart';

void main() {
  test('Realtime sync integration test', () async {
  final jwtSecret = 'super_secret_jwt_key_789';
  final apiKey = 'dev_api_key_123';
  final apiSecret = 'dev_api_secret_456';

  String makeToken(String userId, String roomId, String role) {
    return OmniCastTokenGenerator.generate(
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret,
      userId: userId,
      roomId: roomId,
      role: role,
    );
  }

  final roomId = 'test_realtime_${DateTime.now().millisecondsSinceEpoch}';
  final hostId = 'host_alice';
  final viewerId = 'viewer_bob';

  final hostToken = makeToken(hostId, roomId, 'host');
  final viewerToken = makeToken(viewerId, roomId, 'viewer');

  print('=== STEP 1: Connect Host WebSocket ===');
  final hostWs = await WebSocket.connect(
    'ws://127.0.0.1:8080/ws?token=$hostToken&userId=$hostId&roomId=$roomId&role=host',
  );

  final hostReceivedEvents = <String>[];
  hostWs.listen((data) {
    try {
      final msg = jsonDecode(data);
      final evt = msg['event'] ?? msg['type'];
      hostReceivedEvents.add(evt.toString());
      print('📥 [HOST EVENT]: $evt -> $data');
    } catch (_) {
      print('📥 [HOST RAW]: $data');
    }
  });

  print('=== STEP 2: Host sends publish ===');
  final fakeSdpOffer = 'v=0\r\no=- 123456 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\nc=IN IP4 0.0.0.0\r\na=sendonly\r\na=rtpmap:96 VP8/90000\r\n';
  hostWs.add(jsonEncode({
    'event': 'publish',
    'room_id': roomId,
    'user_id': hostId,
    'role': 'host',
    'display_name': 'Host Alice',
    'payload': {
      'sdp': fakeSdpOffer,
      'type': 'offer',
      'room_type': 'video',
      'token': hostToken,
    }
  }));

  await Future.delayed(const Duration(milliseconds: 500));

  print('=== STEP 3: Connect Late-Join Viewer WebSocket ===');
  final viewerWs = await WebSocket.connect(
    'ws://127.0.0.1:8080/ws?token=$viewerToken&userId=$viewerId&roomId=$roomId&role=viewer',
  );

  final viewerReceivedEvents = <String>[];
  Map<String, dynamic>? viewerRoomInfoSync;

  viewerWs.listen((data) {
    try {
      final msg = jsonDecode(data);
      final evt = msg['event'] ?? msg['type'];
      viewerReceivedEvents.add(evt.toString());
      if (evt == 'room_info_sync') {
        viewerRoomInfoSync = msg['payload'] is Map ? Map<String, dynamic>.from(msg['payload']) : msg;
      }
      print('📥 [VIEWER EVENT]: $evt -> $data');
    } catch (_) {
      print('📥 [VIEWER RAW]: $data');
    }
  });

  print('=== STEP 4: Viewer joins room ===');
  final fakeViewerSdp = 'v=0\r\no=- 789101 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\nc=IN IP4 0.0.0.0\r\na=recvonly\r\na=rtpmap:96 VP8/90000\r\n';
  viewerWs.add(jsonEncode({
    'event': 'join_room',
    'room_id': roomId,
    'user_id': viewerId,
    'role': 'viewer',
    'display_name': 'Viewer Bob',
    'payload': {
      'sdp': fakeViewerSdp,
      'type': 'offer',
      'token': viewerToken,
      'display_name': 'Viewer Bob',
    }
  }));

  await Future.delayed(const Duration(milliseconds: 600));

  print('=== STEP 5: Viewer sends seat request ===');
  viewerWs.add(jsonEncode({
    'event': 'seat_request',
    'room_id': roomId,
    'user_id': viewerId,
    'payload': {
      'identity': viewerId,
      'user_id': viewerId,
    }
  }));

  await Future.delayed(const Duration(milliseconds: 600));

  print('=== STEP 6: Viewer sends reaction ===');
  viewerWs.add(jsonEncode({
    'event': 'reaction',
    'room_id': roomId,
    'user_id': viewerId,
    'payload': {
      'emoji': '❤️',
      'reactionType': 'love',
      'user': viewerId,
    }
  }));

  await Future.delayed(const Duration(milliseconds: 600));

  print('=== STEP 7: Host approves join request ===');
  hostWs.add(jsonEncode({
    'event': 'approve_join',
    'room_id': roomId,
    'user_id': hostId,
    'payload': {
      'targetIdentity': viewerId,
      'seatIndex': 1,
    }
  }));

  await Future.delayed(const Duration(milliseconds: 600));

  print('=== STEP 8: Viewer leaves seat ===');
  viewerWs.add(jsonEncode({
    'event': 'leave_seat',
    'room_id': roomId,
    'user_id': viewerId,
    'payload': {
      'identity': viewerId,
      'seatIndex': 1,
    }
  }));

  await Future.delayed(const Duration(milliseconds: 600));

  print('=== STEP 9: Viewer disconnects ===');
  await viewerWs.close();

  await Future.delayed(const Duration(milliseconds: 600));

  print('\n=== VERIFICATION RESULTS ===');
  print('Host received events count: ${hostReceivedEvents.length} -> $hostReceivedEvents');
  print('Viewer received events count: ${viewerReceivedEvents.length} -> $viewerReceivedEvents');
  print('Viewer received room_info_sync: ${viewerRoomInfoSync != null}');
  if (viewerRoomInfoSync != null) {
    print('  - active_seats: ${viewerRoomInfoSync!['active_seats']}');
    print('  - waiting_list: ${viewerRoomInfoSync!['waiting_list']}');
    print('  - viewers: ${viewerRoomInfoSync!['viewers']}');
    print('  - host_id: ${viewerRoomInfoSync!['host_id']}');
    print('  - created_at: ${viewerRoomInfoSync!['created_at']}');
  }

  final seatRequestReceived = hostReceivedEvents.contains('seat_request') || hostReceivedEvents.contains('request_seat');
  final reactionReceived = hostReceivedEvents.contains('reaction') || hostReceivedEvents.contains('send_reaction');
  final approveJoinReceived = viewerReceivedEvents.contains('approve_join') || viewerReceivedEvents.contains('seat_accept');
  final leaveSeatReceived = hostReceivedEvents.contains('leave_seat');

  print('Seat request delivered: $seatRequestReceived');
  print('Reaction delivered: $reactionReceived');
  print('Approve join delivered: $approveJoinReceived');
  print('Leave seat delivered: $leaveSeatReceived');

  expect(viewerRoomInfoSync, isNotNull);
  expect(seatRequestReceived, isTrue);
  expect(reactionReceived, isTrue);
  expect(approveJoinReceived, isTrue);

  await hostWs.close();
  print('Test finished successfully!');
  });
}
