import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/interaction_models.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../utils/omnicast_logger.dart';

/// Top-level function for offloading heavy JSON parsing to a background Dart Isolate.
SignalingMessage? _parseJsonPayload(String raw) =>
    SignalingMessage.tryDeserialize(raw);

/// Manages WebSocket signaling connection, JSON framing, keep-alive heartbeats,
/// and incoming/outgoing event routing for the OmniCast SFU engine with Isolate parsing.
class SignalingClient {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;

  bool _isDisposed = false;
  ClientConnectionState _connectionState = ClientConnectionState.disconnected;

  // Configuration
  String? _wsUrl;
  String? _token;
  Duration heartbeatInterval;

  // Stream Controllers
  final _stateController = StreamController<ClientConnectionState>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();
  final _messageController = StreamController<SignalingMessage>.broadcast();
  final _offerController = StreamController<SignalingMessage>.broadcast();
  final _answerController = StreamController<SignalingMessage>.broadcast();
  final _iceController = StreamController<SignalingMessage>.broadcast();
  final _roomInfoController = StreamController<SignalingMessage>.broadcast();
  final _viewerUpdateController =
      StreamController<SignalingMessage>.broadcast();
  final _presenceUpdateController =
      StreamController<SignalingMessage>.broadcast();
  final _userJoinedController =
      StreamController<OmniCastParticipant>.broadcast();
  final _userLeftController = StreamController<String>.broadcast();
  final _chatController = StreamController<ChatMessage>.broadcast();
  final _giftController = StreamController<GiftEvent>.broadcast();
  final _seatRequestController = StreamController<SeatRequest>.broadcast();
  final _seatInviteController = StreamController<CoHostInvite>.broadcast();
  final _seatAcceptController = StreamController<SignalingMessage>.broadcast();
  final _seatRejectController = StreamController<SignalingMessage>.broadcast();
  final _seatLeaveController = StreamController<SignalingMessage>.broadcast();
  final _seatUpdatedController = StreamController<SignalingMessage>.broadcast();
  final _seatKickedController = StreamController<SignalingMessage>.broadcast();
  final _mediaStateController = StreamController<SignalingMessage>.broadcast();
  final _pkStartedController = StreamController<SignalingMessage>.broadcast();
  final _pkScoreController = StreamController<SignalingMessage>.broadcast();
  final _pkEndedController = StreamController<SignalingMessage>.broadcast();
  final _pkGiftOverlayController =
      StreamController<SignalingMessage>.broadcast();
  final _layerSwitchedController =
      StreamController<SignalingMessage>.broadcast();
  final _viewportUpdatedController =
      StreamController<SignalingMessage>.broadcast();
  final _leaveAcknowledgedController =
      StreamController<SignalingMessage>.broadcast();
  final _roomCreatedController = StreamController<RoomModel>.broadcast();
  final _roomClosedController = StreamController<String>.broadcast();
  final _roomListController = StreamController<List<RoomModel>>.broadcast();

  final _userSpeakingController =
      StreamController<SignalingMessage>.broadcast();

  // Reconnection state
  bool autoReconnect;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  SignalingClient({
    this.heartbeatInterval = const Duration(seconds: 5),
    this.autoReconnect = true,
  });

  // Getters
  ClientConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ClientConnectionState.connected;
  String? get wsUrl => _wsUrl;
  String? get token => _token;

  // Streams
  Stream<ClientConnectionState> get onConnectionStateChanged =>
      _stateController.stream;
  Stream<void> get onReconnected => _reconnectedController.stream;
  Stream<SignalingMessage> get onMessage => _messageController.stream;
  Stream<SignalingMessage> get onOffer => _offerController.stream;
  Stream<SignalingMessage> get onAnswer => _answerController.stream;
  Stream<SignalingMessage> get onIceCandidate => _iceController.stream;
  Stream<SignalingMessage> get onRoomInfoSync => _roomInfoController.stream;
  Stream<SignalingMessage> get onViewerUpdate => _viewerUpdateController.stream;
  Stream<SignalingMessage> get onPresenceUpdate =>
      _presenceUpdateController.stream;
  Stream<OmniCastParticipant> get onUserJoined => _userJoinedController.stream;
  Stream<String> get onUserLeft => _userLeftController.stream;
  Stream<ChatMessage> get onChat => _chatController.stream;
  Stream<GiftEvent> get onGift => _giftController.stream;
  Stream<SeatRequest> get onSeatRequest => _seatRequestController.stream;
  Stream<CoHostInvite> get onSeatInvite => _seatInviteController.stream;
  Stream<SignalingMessage> get onSeatAccept => _seatAcceptController.stream;
  Stream<SignalingMessage> get onSeatReject => _seatRejectController.stream;
  Stream<SignalingMessage> get onSeatLeave => _seatLeaveController.stream;
  Stream<SignalingMessage> get onSeatUpdated => _seatUpdatedController.stream;
  Stream<SignalingMessage> get onSeatKicked => _seatKickedController.stream;
  Stream<SignalingMessage> get onPKStarted => _pkStartedController.stream;
  Stream<SignalingMessage> get onPKScoreUpdate => _pkScoreController.stream;
  Stream<SignalingMessage> get onPKEnded => _pkEndedController.stream;
  Stream<SignalingMessage> get onPKGiftOverlay =>
      _pkGiftOverlayController.stream;
  Stream<SignalingMessage> get onLayerSwitched =>
      _layerSwitchedController.stream;
  Stream<SignalingMessage> get onViewportUpdated =>
      _viewportUpdatedController.stream;
  Stream<SignalingMessage> get onLeaveAcknowledged =>
      _leaveAcknowledgedController.stream;
  Stream<SignalingMessage> get onMediaStateChanged =>
      _mediaStateController.stream;
  Stream<SignalingMessage> get onUserSpeaking => _userSpeakingController.stream;
  Stream<RoomModel> get onRoomCreated => _roomCreatedController.stream;
  Stream<String> get onRoomClosed => _roomClosedController.stream;
  Stream<List<RoomModel>> get onRoomListReceived => _roomListController.stream;

  /// Connects to the OmniCast WebSocket signaling server.
  Future<void> connect({required String wsUrl, String? token}) async {
    if (_isDisposed) {
      throw StateError('Cannot connect a disposed SignalingClient');
    }

    _wsUrl = wsUrl;
    _token = token;
    _reconnectAttempts = 0;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    _updateState(ClientConnectionState.connecting);

    try {
      var uri = Uri.parse(_wsUrl!);
      if (uri.scheme == 'http') {
        uri = uri.replace(scheme: 'ws');
      } else if (uri.scheme == 'https') {
        uri = uri.replace(scheme: 'wss');
      }
      final queryParams = Map<String, String>.from(uri.queryParameters);

      if (_token != null && _token!.isNotEmpty) {
        queryParams['token'] = _token!;

        // Automatically extract userId, roomId, and role from JWT claims for SFU handshake
        try {
          final parts = _token!.split('.');
          if (parts.length >= 2) {
            final normalized = base64Url.normalize(parts[1]);
            final payloadJson = utf8.decode(base64Url.decode(normalized));
            final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
            final uId =
                payload['userId'] ?? payload['user_id'] ?? payload['sub'];
            final rId = payload['roomId'] ?? payload['room_id'];
            final role = payload['role'];
            if (uId != null && !queryParams.containsKey('userId')) {
              queryParams['userId'] = uId.toString();
              queryParams['user_id'] = uId.toString();
            }
            if (rId != null && !queryParams.containsKey('roomId')) {
              queryParams['roomId'] = rId.toString();
              queryParams['room_id'] = rId.toString();
            }
            if (role != null && !queryParams.containsKey('role')) {
              queryParams['role'] = role.toString();
            }
          }
        } catch (_) {}

        uri = uri.replace(queryParameters: queryParams);
      }

      OmniCastLogger.log('[SignalingClient] Connecting to WebSocket: $uri');

      await _cleanupActiveConnection();

      final channel = WebSocketChannel.connect(uri);
      await channel.ready.timeout(const Duration(seconds: 8));
      _channel = channel;

      _channelSubscription = channel.stream.listen(
        _onDataReceived,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateState(ClientConnectionState.connected);
      _startHeartbeat();
      OmniCastLogger.log('[SignalingClient] WebSocket successfully connected.');
    } catch (e) {
      OmniCastLogger.error('[SignalingClient] Connection error: $e');
      _updateState(ClientConnectionState.disconnected);
      rethrow;
    }
  }

  void _onDataReceived(dynamic rawData) async {
    if (rawData is! String) return;

    SignalingMessage? msg;
    // Performance optimization: offload large JSON payloads (>8KB) to background isolate
    if (rawData.length > 8192) {
      msg = await compute(_parseJsonPayload, rawData);
    } else {
      msg = SignalingMessage.tryDeserialize(rawData);
    }

    if (msg == null) {
      OmniCastLogger.error('[SignalingClient] Failed to deserialize message');
      return;
    }

    // Emit to generic stream
    _messageController.add(msg);

    // Route based on event type
    switch (msg.event) {
      case SignalingEvents.offer:
      case SignalingEvents.sdpOffer:
        _offerController.add(msg);
        break;

      case SignalingEvents.answer:
      case SignalingEvents.sdpAnswer:
        _answerController.add(msg);
        break;

      case SignalingEvents.ice:
      case SignalingEvents.candidate:
        _iceController.add(msg);
        break;

      case SignalingEvents.roomInfoSync:
      case SignalingEvents.roomInfo:
      case 'room_state':
      case 'sync_state':
        _roomInfoController.add(msg);
        break;

      case 'room_list':
      case 'rooms':
        if (msg.payload is List) {
          try {
            final list = (msg.payload as List)
                .map(
                  (e) =>
                      RoomModel.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
            _roomListController.add(list);
          } catch (e) {
            OmniCastLogger.error(
              '[SignalingClient] Failed to parse room_list: $e',
            );
          }
        }
        break;

      case SignalingEvents.viewerUpdate:
      case SignalingEvents.viewerCount:
        _viewerUpdateController.add(msg);
        break;

      case SignalingEvents.presenceUpdate:
        _presenceUpdateController.add(msg);
        _viewerUpdateController.add(msg);
        break;

      case SignalingEvents.userJoined:
      case 'participant_joined':
      case 'new_cohost':
      case 'host_reconnected':
        if (msg.payload is Map<String, dynamic>) {
          _userJoinedController.add(
            OmniCastParticipant.fromJson(msg.payload as Map<String, dynamic>),
          );
        } else {
          _userJoinedController.add(
            OmniCastParticipant(userId: msg.userId, joinedAt: DateTime.now()),
          );
        }
        break;

      case SignalingEvents.userLeft:
      case 'participant_left':
      case 'participant_removed':
      case 'cohost_left':
        final leftId = msg.payload is Map && msg.payload['user_id'] != null
            ? msg.payload['user_id'].toString()
            : msg.userId;
        if (leftId.isNotEmpty) {
          _userLeftController.add(leftId);
        }
        break;

      case SignalingEvents.chat:
      case SignalingEvents.chatMessage:
        if (msg.payload is Map<String, dynamic>) {
          _chatController.add(
            ChatMessage.fromJson(msg.payload as Map<String, dynamic>),
          );
        } else if (msg.payload is String) {
          _chatController.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              senderId: msg.userId,
              senderName: msg.userId,
              text: msg.payload as String,
              timestamp: DateTime.now(),
            ),
          );
        }
        break;

      case SignalingEvents.gift:
      case SignalingEvents.giftProcessed:
        if (msg.payload is Map<String, dynamic>) {
          _giftController.add(
            GiftEvent.fromJson(msg.payload as Map<String, dynamic>),
          );
        }
        break;

      case SignalingEvents.pkGiftOverlay:
        _pkGiftOverlayController.add(msg);
        if (msg.payload is Map<String, dynamic>) {
          _giftController.add(
            GiftEvent.fromJson(msg.payload as Map<String, dynamic>),
          );
        }
        break;

      case SignalingEvents.seatRequest:
        if (msg.payload is Map<String, dynamic>) {
          _seatRequestController.add(
            SeatRequest.fromJson(msg.payload as Map<String, dynamic>),
          );
        } else {
          _seatRequestController.add(
            SeatRequest(
              requesterId: msg.userId,
              requesterName: msg.userId,
              requestedAt: DateTime.now(),
            ),
          );
        }
        break;

      case SignalingEvents.seatInvite:
        if (msg.payload is Map<String, dynamic>) {
          _seatInviteController.add(
            CoHostInvite.fromJson(msg.payload as Map<String, dynamic>),
          );
        }
        break;

      case SignalingEvents.seatAccept:
        _seatAcceptController.add(msg);
        break;

      case SignalingEvents.seatReject:
        _seatRejectController.add(msg);
        break;

      case SignalingEvents.seatLeave:
      case SignalingEvents.seatLeft:
        _seatLeaveController.add(msg);
        break;

      case SignalingEvents.seatUpdated:
        _seatUpdatedController.add(msg);
        break;

      case SignalingEvents.seatKick:
      case 'seat_kicked':
        _seatKickedController.add(msg);
        break;

      case SignalingEvents.pkStart:
      case SignalingEvents.pkStarted:
        _pkStartedController.add(msg);
        break;

      case SignalingEvents.pkScoreUpdate:
        _pkScoreController.add(msg);
        break;

      case SignalingEvents.pkStop:
      case SignalingEvents.pkEnd:
      case SignalingEvents.pkEnded:
        _pkEndedController.add(msg);
        break;

      case SignalingEvents.layerSwitched:
        _layerSwitchedController.add(msg);
        break;

      case SignalingEvents.viewportUpdated:
        _viewportUpdatedController.add(msg);
        break;

      case SignalingEvents.leaveAcknowledged:
        _leaveAcknowledgedController.add(msg);
        break;

      case SignalingEvents.mediaStateChanged:
      case SignalingEvents.trackMuted:
      case SignalingEvents.trackUnmuted:
        _mediaStateController.add(msg);
        break;

      case 'user_speaking':
      case 'speaking':
      case 'speaking_state_changed':
        _userSpeakingController.add(msg);
        break;

      case SignalingEvents.roomCreated:
        if (msg.payload is Map<String, dynamic>) {
          _roomCreatedController.add(
            RoomModel.fromJson(msg.payload as Map<String, dynamic>),
          );
        }
        break;

      case SignalingEvents.roomClosed:
      case 'room_ended':
      case 'end_room':
      case 'host_left':
      case 'room_terminated':
        final closedRoomId = msg.roomId.isNotEmpty
            ? msg.roomId
            : (msg.payload is Map<String, dynamic>
                  ? (msg.payload['room_id'] as String? ??
                        msg.payload['roomId'] as String? ??
                        '')
                  : (msg.payload is String ? msg.payload as String : ''));
        if (closedRoomId.isNotEmpty) {
          _roomClosedController.add(closedRoomId);
        }
        break;

      case SignalingEvents.ping:
        // Automatically reply with pong
        send(
          SignalingMessage(
            event: SignalingEvents.pong,
            roomId: msg.roomId,
            userId: msg.userId,
            payload: {'timestamp': DateTime.now().millisecondsSinceEpoch},
          ),
        );
        break;

      case SignalingEvents.pong:
        // Keep-alive acknowledgement
        break;

      default:
        OmniCastLogger.log('[SignalingClient] Event received: ${msg.event}');
        break;
    }
  }

  /// Injects a raw JSON or message payload directly (useful for tests and synthetic messages).
  @visibleForTesting
  Future<void> handleRawMessage(dynamic rawData) async {
    _onDataReceived(rawData);
  }

  /// Requests the active room list from the server over WebSocket signaling.
  void requestRoomList() {
    send(
      SignalingMessage(event: 'get_rooms', roomId: '', userId: _token ?? ''),
    );
  }

  void _scheduleReconnect() {
    if (_isDisposed || !autoReconnect || _wsUrl == null) return;
    if (_reconnectTimer != null && _reconnectTimer!.isActive) return;

    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts <= 1)
        ? 1
        : (_reconnectAttempts == 2 ? 2 : (_reconnectAttempts == 3 ? 3 : 5));
    final delay = Duration(seconds: delaySeconds);

    OmniCastLogger.log(
      '[SignalingClient] Network lost -> Scheduling auto-reconnect attempt #$_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () async {
      if (_isDisposed || isConnected || _wsUrl == null) return;
      try {
        OmniCastLogger.log('[SignalingClient] Reconnecting WebSocket...');
        await _establishConnection();
        _reconnectAttempts = 0;
        _reconnectedController.add(null);
        OmniCastLogger.log(
          '[SignalingClient] WebSocket successfully reconnected!',
        );
      } catch (e) {
        OmniCastLogger.error(
          '[SignalingClient] Auto-reconnect retry failed ($e), retrying...',
        );
        _scheduleReconnect();
      }
    });
  }

  void _onError(dynamic error) {
    OmniCastLogger.error('[SignalingClient] Stream error: $error');
    _updateState(ClientConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    OmniCastLogger.log('[SignalingClient] Connection closed');
    _updateState(ClientConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _updateState(ClientConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    _stateController.add(state);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (heartbeatInterval <= Duration.zero) return;

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (isConnected) {
        send(
          SignalingMessage(
            event: SignalingEvents.ping,
            roomId: '',
            userId: '',
            payload: {'timestamp': DateTime.now().millisecondsSinceEpoch},
          ),
        );
      }
    });
  }

  /// Sends a strongly-typed signaling message over the WebSocket channel.
  bool send(SignalingMessage message) {
    if (_channel == null || !isConnected) {
      OmniCastLogger.log(
        '[SignalingClient] Cannot send, client is not connected.',
      );
      return false;
    }

    try {
      final jsonPayload = message.serialize();
      _channel!.sink.add(jsonPayload);
      return true;
    } catch (e) {
      OmniCastLogger.error('[SignalingClient] Send error: $e');
      return false;
    }
  }

  Future<void> _cleanupActiveConnection() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }
  }

  /// Disconnects the signaling client without destroying stream controllers.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    await _cleanupActiveConnection();
    _updateState(ClientConnectionState.disconnected);
  }

  /// Broadcasts the local participant's speaking status to the room.
  bool sendSpeakingState({
    required String roomId,
    required String userId,
    required bool isSpeaking,
    double level = 0.0,
  }) {
    return send(
      SignalingMessage(
        event: 'user_speaking',
        roomId: roomId,
        userId: userId,
        payload: {
          'user_id': userId,
          'is_speaking': isSpeaking,
          'speaking': isSpeaking,
          'audio_level': level,
        },
      ),
    );
  }

  /// Requests an immediate unthrottled Keyframe (PLI) from the media server.
  bool requestKeyframe({required String roomId, String? userId}) {
    return send(
      SignalingMessage(
        event: 'request_keyframe',
        roomId: roomId,
        userId: userId ?? '',
      ),
    );
  }

  /// Requests a refreshed list of active broadcast rooms from the server.
  void fetchRoomList() {
    requestRoomList();
  }

  /// Permanently disposes the signaling client and closes all broadcast streams.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await disconnect();

    await _stateController.close();
    await _reconnectedController.close();
    await _messageController.close();
    await _offerController.close();
    await _answerController.close();
    await _iceController.close();
    await _roomInfoController.close();
    await _viewerUpdateController.close();
    await _presenceUpdateController.close();
    await _userJoinedController.close();
    await _userLeftController.close();
    await _chatController.close();
    await _giftController.close();
    await _seatRequestController.close();
    await _seatInviteController.close();
    await _seatAcceptController.close();
    await _seatRejectController.close();
    await _seatLeaveController.close();
    await _seatUpdatedController.close();
    await _seatKickedController.close();
    await _mediaStateController.close();
    await _userSpeakingController.close();
    await _pkStartedController.close();
    await _pkScoreController.close();
    await _pkEndedController.close();
    await _pkGiftOverlayController.close();
    await _layerSwitchedController.close();
    await _viewportUpdatedController.close();
    await _leaveAcknowledgedController.close();
    await _roomCreatedController.close();
    await _roomClosedController.close();
    await _roomListController.close();
  }
}
