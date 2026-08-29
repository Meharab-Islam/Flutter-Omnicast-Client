import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/interaction_models.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Real-time emoji reaction model transmitted via WebRTC DataChannels.
class DataChannelReaction {
  final String userId;
  final String emoji;
  final double xOffset; // 0.0 to 1.0 (Horizontal spawn anchor)
  final int timestamp;

  const DataChannelReaction({
    required this.userId,
    required this.emoji,
    required this.xOffset,
    required this.timestamp,
  });

  factory DataChannelReaction.fromJson(Map<String, dynamic> json) => DataChannelReaction(
        userId: json['user_id'] as String? ?? 'unknown',
        emoji: json['emoji'] as String? ?? '❤️',
        xOffset: (json['x_offset'] as num?)?.toDouble() ?? 0.5,
        timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {
        'type': 'reaction',
        'user_id': userId,
        'emoji': emoji,
        'x_offset': xOffset,
        'timestamp': timestamp,
      };
}

/// Zero-latency in-room messaging and flying reactions manager powered by WebRTC DataChannels (UDP/SCTP).
class DataChannelManager {
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  RTCDataChannel? _dataChannel;
  bool _isDisposed = false;

  // Reactive Streams & ValueNotifiers
  final StreamController<ChatMessage> _chatController = StreamController<ChatMessage>.broadcast();
  final StreamController<DataChannelReaction> _reactionController =
      StreamController<DataChannelReaction>.broadcast();

  final ValueNotifier<bool> isChannelOpenNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<DataChannelReaction?> latestReactionNotifier =
      ValueNotifier<DataChannelReaction?>(null);

  DataChannelManager({
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _webRTCManager = webRTCManager,
        _roomState = roomState;

  Stream<ChatMessage> get onChatMessage => _chatController.stream;
  Stream<DataChannelReaction> get onReactionReceived => _reactionController.stream;
  bool get isChannelOpen => isChannelOpenNotifier.value;

  /// Initializes an outgoing DataChannel for a host/publisher.
  Future<void> createPublisherChannel({String label = 'room-events'}) async {
    final pc = await _webRTCManager.initializePeerConnection();
    final init = RTCDataChannelInit()
      ..ordered = false // Unordered UDP delivery for sub-millisecond reactions and chat
      ..maxRetransmits = 0;

    final channel = await pc.createDataChannel(label, init);
    _bindDataChannel(channel);
  }

  /// Binds incoming DataChannel from the SFU or remote peer for a viewer.
  void attachIncomingChannel(RTCPeerConnection pc) {
    pc.onDataChannel = (RTCDataChannel channel) {
      debugPrint('[DataChannel] Received remote DataChannel: ${channel.label}');
      _bindDataChannel(channel);
    };
  }

  void _bindDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;

    channel.onDataChannelState = (RTCDataChannelState state) {
      debugPrint('[DataChannel] State: $state');
      if (!_isDisposed) {
        isChannelOpenNotifier.value = (state == RTCDataChannelState.RTCDataChannelOpen);
      }
    };

    channel.onMessage = (RTCDataChannelMessage message) {
      if (_isDisposed) return;

      try {
        String decodedText;
        if (message.isBinary) {
          decodedText = utf8.decode(message.binary);
        } else {
          decodedText = message.text;
        }

        final Map<String, dynamic> json = jsonDecode(decodedText);
        final type = json['type'] as String?;

        if (type == 'chat') {
          final msg = ChatMessage(
            id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            senderId: json['user_id'] as String? ?? 'unknown',
            senderName: json['user_name'] as String? ?? 'Guest',
            text: json['text'] as String? ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
            ),
          );
          _chatController.add(msg);
          _roomState.addChatMessage(msg);
        } else if (type == 'reaction') {
          final reaction = DataChannelReaction.fromJson(json);
          latestReactionNotifier.value = reaction;
          _reactionController.add(reaction);
        }
      } catch (e) {
        debugPrint('[DataChannel] Error parsing message: $e');
      }
    };
  }

  /// Broadcasts a zero-latency chat message over the WebRTC DataChannel.
  void sendChat({required String text, String? senderName}) {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      debugPrint('[DataChannel] Cannot send chat: DataChannel is not open');
      return;
    }

    final userId = _roomState.userId ?? 'local_user';
    final name = senderName ?? userId;
    final now = DateTime.now();

    final msg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      senderId: userId,
      senderName: name,
      text: text,
      timestamp: now,
    );

    final payload = jsonEncode({
      'type': 'chat',
      'id': msg.id,
      'user_id': userId,
      'user_name': name,
      'text': text,
      'timestamp': now.millisecondsSinceEpoch,
    });

    _dataChannel!.send(RTCDataChannelMessage(payload));

    // Update local UI immediately
    _chatController.add(msg);
    _roomState.addChatMessage(msg);
  }

  /// Broadcasts a floating heart or emoji reaction over the WebRTC DataChannel.
  void sendReaction({String emoji = '❤️', double? xOffset}) {
    if (_dataChannel == null ||
        _dataChannel!.state != RTCDataChannelState.RTCDataChannelOpen) {
      return;
    }

    final userId = _roomState.userId ?? 'local_user';
    final offset = xOffset ?? (0.6 + (0.3 * (DateTime.now().millisecond % 10) / 10.0));

    final reaction = DataChannelReaction(
      userId: userId,
      emoji: emoji,
      xOffset: offset,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _dataChannel!.send(RTCDataChannelMessage(jsonEncode(reaction.toJson())));

    latestReactionNotifier.value = reaction;
    _reactionController.add(reaction);
  }

  /// Closes and disposes internal streams and notifiers.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    _dataChannel?.close();
    _dataChannel = null;

    isChannelOpenNotifier.dispose();
    latestReactionNotifier.dispose();

    await _chatController.close();
    await _reactionController.close();
  }
}
