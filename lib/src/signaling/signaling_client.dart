import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/interaction_models.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';

/// Manages WebSocket signaling connection, JSON framing, keep-alive heartbeats,
/// and incoming/outgoing event routing for the OmniCast SFU engine.
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
  final _messageController = StreamController<SignalingMessage>.broadcast();
  final _offerController = StreamController<SignalingMessage>.broadcast();
  final _answerController = StreamController<SignalingMessage>.broadcast();
  final _iceController = StreamController<SignalingMessage>.broadcast();
  final _roomInfoController = StreamController<SignalingMessage>.broadcast();
  final _viewerUpdateController = StreamController<SignalingMessage>.broadcast();
  final _chatController = StreamController<ChatMessage>.broadcast();
  final _giftController = StreamController<GiftEvent>.broadcast();
  final _seatRequestController = StreamController<SeatRequest>.broadcast();
  final _seatAcceptController = StreamController<SignalingMessage>.broadcast();
  final _seatRejectController = StreamController<SignalingMessage>.broadcast();
  final _seatLeaveController = StreamController<SignalingMessage>.broadcast();

  SignalingClient({
    this.heartbeatInterval = const Duration(seconds: 15),
  });

  // Getters
  ClientConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == ClientConnectionState.connected;

  // Streams
  Stream<ClientConnectionState> get onConnectionStateChanged =>
      _stateController.stream;
  Stream<SignalingMessage> get onMessage => _messageController.stream;
  Stream<SignalingMessage> get onOffer => _offerController.stream;
  Stream<SignalingMessage> get onAnswer => _answerController.stream;
  Stream<SignalingMessage> get onIceCandidate => _iceController.stream;
  Stream<SignalingMessage> get onRoomInfoSync => _roomInfoController.stream;
  Stream<SignalingMessage> get onViewerUpdate => _viewerUpdateController.stream;
  Stream<ChatMessage> get onChat => _chatController.stream;
  Stream<GiftEvent> get onGift => _giftController.stream;
  Stream<SeatRequest> get onSeatRequest => _seatRequestController.stream;
  Stream<SignalingMessage> get onSeatAccept => _seatAcceptController.stream;
  Stream<SignalingMessage> get onSeatReject => _seatRejectController.stream;
  Stream<SignalingMessage> get onSeatLeave => _seatLeaveController.stream;

  /// Connects to the OmniCast WebSocket signaling server.
  Future<void> connect({required String wsUrl, String? token}) async {
    if (_isDisposed) {
      throw StateError('Cannot connect a disposed SignalingClient');
    }

    _wsUrl = wsUrl;
    _token = token;

    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    _updateState(ClientConnectionState.connecting);

    try {
      var uri = Uri.parse(_wsUrl!);
      if (_token != null && _token!.isNotEmpty) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['token'] = _token!;
        uri = uri.replace(queryParameters: queryParams);
      }

      await _cleanupActiveConnection();

      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      _channel = channel;

      _channelSubscription = channel.stream.listen(
        _onDataReceived,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateState(ClientConnectionState.connected);
      _startHeartbeat();
    } catch (e) {
      debugPrint('[SignalingClient] Connection error: $e');
      _updateState(ClientConnectionState.disconnected);
      rethrow;
    }
  }

  void _onDataReceived(dynamic rawData) {
    if (rawData is! String) return;

    final msg = SignalingMessage.tryDeserialize(rawData);
    if (msg == null) {
      debugPrint('[SignalingClient] Failed to deserialize message: $rawData');
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
        _roomInfoController.add(msg);
        break;

      case SignalingEvents.viewerUpdate:
        _viewerUpdateController.add(msg);
        break;

      case SignalingEvents.chat:
        if (msg.payload is Map<String, dynamic>) {
          _chatController.add(ChatMessage.fromJson(msg.payload as Map<String, dynamic>));
        } else if (msg.payload is String) {
          _chatController.add(ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: msg.userId,
            senderName: msg.userId,
            text: msg.payload as String,
            timestamp: DateTime.now(),
          ));
        }
        break;

      case SignalingEvents.giftProcessed:
        if (msg.payload is Map<String, dynamic>) {
          _giftController.add(GiftEvent.fromJson(msg.payload as Map<String, dynamic>));
        }
        break;

      case SignalingEvents.seatRequest:
        if (msg.payload is Map<String, dynamic>) {
          _seatRequestController.add(SeatRequest.fromJson(msg.payload as Map<String, dynamic>));
        } else {
          _seatRequestController.add(SeatRequest(
            requesterId: msg.userId,
            requesterName: msg.userId,
            requestedAt: DateTime.now(),
          ));
        }
        break;

      case SignalingEvents.seatAccept:
        _seatAcceptController.add(msg);
        break;

      case SignalingEvents.seatReject:
        _seatRejectController.add(msg);
        break;

      case SignalingEvents.seatLeave:
        _seatLeaveController.add(msg);
        break;

      case SignalingEvents.ping:
        // Automatically reply with pong
        send(SignalingMessage(
          event: SignalingEvents.pong,
          roomId: msg.roomId,
          userId: msg.userId,
          payload: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        ));
        break;

      case SignalingEvents.pong:
        // Keep-alive acknowledgement
        break;

      default:
        debugPrint('[SignalingClient] Event received: ${msg.event}');
        break;
    }
  }

  void _onError(dynamic error) {
    debugPrint('[SignalingClient] Stream error: $error');
    _updateState(ClientConnectionState.disconnected);
  }

  void _onDone() {
    debugPrint('[SignalingClient] Connection closed');
    _updateState(ClientConnectionState.disconnected);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (isConnected) {
        send(SignalingMessage(
          event: SignalingEvents.ping,
          roomId: '',
          userId: '',
          payload: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        ));
      }
    });
  }

  /// Sends a strongly-typed signaling message over the WebSocket channel.
  bool send(SignalingMessage message) {
    if (_channel == null || !isConnected) {
      debugPrint('[SignalingClient] Cannot send, client is not connected.');
      return false;
    }

    try {
      final jsonPayload = message.serialize();
      _channel!.sink.add(jsonPayload);
      return true;
    } catch (e) {
      debugPrint('[SignalingClient] Send error: $e');
      return false;
    }
  }

  void _updateState(ClientConnectionState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  Future<void> _cleanupActiveConnection() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    await _channelSubscription?.cancel();
    _channelSubscription = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }
  }

  /// Disconnects the signaling client without destroying stream controllers.
  Future<void> disconnect() async {
    await _cleanupActiveConnection();
    _updateState(ClientConnectionState.disconnected);
  }

  /// Permanently disposes the signaling client and closes all broadcast streams.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    await disconnect();

    await _stateController.close();
    await _messageController.close();
    await _offerController.close();
    await _answerController.close();
    await _iceController.close();
    await _roomInfoController.close();
    await _viewerUpdateController.close();
    await _chatController.close();
    await _giftController.close();
    await _seatRequestController.close();
    await _seatAcceptController.close();
    await _seatRejectController.close();
    await _seatLeaveController.close();
  }
}
