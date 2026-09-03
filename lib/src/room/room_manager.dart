import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/omnicast_config.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages room lifecycle, participant tracking, and provides granular [ValueNotifier]
/// state providers with event batch throttling for high-scale rooms (10,000+ viewers).
class RoomManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;
  final OmniCastConfig? _config;

  // Maximum active viewer avatar objects kept in UI memory
  static const int maxViewersInMemory = 200;

  // Granular atomic ValueNotifiers for headless UI composition
  final ValueNotifier<int> totalViewerCount = ValueNotifier<int>(0);
  final ValueNotifier<List<OmniCastParticipant>> activeViewersList =
      ValueNotifier<List<OmniCastParticipant>>(const []);

  final ValueNotifier<ClientConnectionState> connectionStateNotifier =
      ValueNotifier<ClientConnectionState>(ClientConnectionState.disconnected);
  final ValueNotifier<UserRole> roleNotifier =
      ValueNotifier<UserRole>(UserRole.viewer);
  final ValueNotifier<List<StageSeat>> activeSeatsNotifier =
      ValueNotifier<List<StageSeat>>(const []);
  final ValueNotifier<String?> pinnedUserNotifier = ValueNotifier<String?>(null);

  // Backward compatibility alias getters
  ValueNotifier<int> get viewerCountNotifier => totalViewerCount;
  ValueNotifier<List<OmniCastParticipant>> get viewersNotifier => activeViewersList;

  // Internal high-frequency event batching queue
  final List<OmniCastParticipant> _pendingJoins = [];
  final Set<String> _pendingLeaves = {};
  Timer? _batchDebounceTimer;
  StreamSubscription? _signalingSubscription;

  RoomManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
    OmniCastConfig? config,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState,
        _config = config {
    _bindSignalingEvents();
    _bindStateNotifiers();
  }

  void _bindStateNotifiers() {
    _roomState.addListener(_syncGranularNotifiers);
  }

  void _syncGranularNotifiers() {
    if (totalViewerCount.value != _roomState.viewersCount) {
      totalViewerCount.value = _roomState.viewersCount;
    }
    if (connectionStateNotifier.value != _roomState.connectionState) {
      connectionStateNotifier.value = _roomState.connectionState;
    }
    if (roleNotifier.value != _roomState.role) {
      roleNotifier.value = _roomState.role;
    }
    if (pinnedUserNotifier.value != _roomState.pinnedStageUserId) {
      pinnedUserNotifier.value = _roomState.pinnedStageUserId;
    }
    activeSeatsNotifier.value = _roomState.activeSeats;
    activeViewersList.value = _roomState.viewers;
  }

  final _roomClosedByHostController = StreamController<String>.broadcast();
  final _kickedFromRoomController = StreamController<KickedEvent>.broadcast();
  final _userKickedController = StreamController<String>.broadcast();

  /// Stream emitting when the room is terminated/closed by the host.
  Stream<String> get onRoomClosedByHost => _roomClosedByHostController.stream;

  /// Stream emitting when the local user has been kicked out of the room by host.
  Stream<KickedEvent> get onKickedFromRoom => _kickedFromRoomController.stream;

  /// Stream emitting the userId whenever any user in the room is kicked.
  Stream<String> get onUserKicked => _userKickedController.stream;

  /// Listens to real-time participant signaling events with high-performance debouncing.
  void _bindSignalingEvents() {
    _signalingSubscription = _signalingClient.onMessage.listen((msg) {
      switch (msg.event) {
        // 1. Initial Snapshot on Join
        case SignalingEvents.roomInfoSync:
          if (msg.payload is Map<String, dynamic>) {
            _handleRoomInfoSync(msg.payload as Map<String, dynamic>);
          }
          break;

        // 2. Real-time User Joined Event
        case SignalingEvents.userJoined:
          if (msg.payload is Map<String, dynamic>) {
            final participant = OmniCastParticipant.fromJson(
              msg.payload as Map<String, dynamic>,
            );
            _queueUserJoined(participant);
          } else {
            final participant = OmniCastParticipant(
              userId: msg.userId,
              joinedAt: DateTime.now(),
            );
            _queueUserJoined(participant);
          }
          break;

        // 3. Real-time User Left Event
        case SignalingEvents.userLeft:
          final leftUserId = msg.payload is Map && msg.payload['user_id'] != null
              ? msg.payload['user_id'].toString()
              : msg.userId;
          _queueUserLeft(leftUserId);
          break;

        // 4. Batch Viewer Count Sync
        case SignalingEvents.viewerUpdate:
          if (msg.payload is Map<String, dynamic>) {
            final payload = msg.payload as Map<String, dynamic>;
            final count = (payload['viewers_count'] as num?)?.toInt() ??
                (payload['viewer_count'] as num?)?.toInt() ??
                0;
            totalViewerCount.value = count;
            if (payload['viewers'] is List) {
              final viewers = (payload['viewers'] as List)
                  .map((e) => OmniCastParticipant.fromJson(e as Map<String, dynamic>))
                  .take(maxViewersInMemory)
                  .toList();
              activeViewersList.value = viewers;
            }
          }
          break;

        // 5. Host Terminated Room / Room Closed Event
        case SignalingEvents.roomClosed:
        case 'room_ended':
        case 'end_room':
        case 'host_left':
        case 'room_terminated':
          final closedRoomId = msg.roomId.isNotEmpty
              ? msg.roomId
              : (msg.payload is Map<String, dynamic>
                  ? (msg.payload['room_id'] as String? ?? msg.payload['roomId'] as String? ?? '')
                  : (msg.payload is String ? msg.payload as String : ''));
          if (_roomState.isInRoom && (closedRoomId.isEmpty || closedRoomId == _roomState.roomId)) {
            _handleHostClosedRoom(closedRoomId.isNotEmpty ? closedRoomId : (_roomState.roomId ?? ''));
          }
          break;

        // 6. User Kicked / Ejected Event
        case SignalingEvents.kickUser:
        case SignalingEvents.userKicked:
        case 'kicked':
        case 'user_ejected':
          final targetUser = msg.targetUser ??
              (msg.payload is Map<String, dynamic>
                  ? (msg.payload['target_user'] as String? ?? msg.payload['user_id'] as String?)
                  : msg.userId);
          if (targetUser != null && targetUser.isNotEmpty) {
            _handleUserKicked(targetUser, msg);
          }
          break;
      }
    });
  }

  Future<void> _handleUserKicked(String targetUserId, SignalingMessage msg) async {
    final payloadMap = msg.payload is Map<String, dynamic>
        ? msg.payload as Map<String, dynamic>
        : <String, dynamic>{};
    final event = KickedEvent.fromJson(
      payloadMap,
      defaultRoomId: _roomState.roomId,
      defaultUserId: targetUserId,
    );

    _userKickedController.add(targetUserId);

    // If the local user is the one who was kicked:
    if (_roomState.userId == targetUserId) {
      debugPrint(
          '[RoomManager] Local user $targetUserId was kicked from room ${_roomState.roomId} by host');
      _kickedFromRoomController.add(event);
      await _webRTCManager.closePeerConnection();
      await _webRTCManager.mediaStreamManager.stopLocalMedia();
      _roomState.reset();
    } else {
      // Remote participant was kicked: remove from local viewer and seat state
      debugPrint('[RoomManager] Participant $targetUserId was kicked from room ${_roomState.roomId}');
      _queueUserLeft(targetUserId);
    }
  }

  Future<void> _handleHostClosedRoom(String roomId) async {
    debugPrint(
        '[RoomManager] Host closed room $roomId -> Forcefully ejecting participants & clearing WebRTC resources');
    _roomClosedByHostController.add(roomId);
    await _webRTCManager.closePeerConnection();
    await _webRTCManager.mediaStreamManager.stopLocalMedia();
    _roomState.reset();
  }

  void _handleRoomInfoSync(Map<String, dynamic> data) {
    final count = (data['viewers_count'] as num?)?.toInt() ??
        (data['viewer_count'] as num?)?.toInt() ??
        0;
    totalViewerCount.value = count;

    if (data['viewers'] is List) {
      final list = (data['viewers'] as List)
          .map((e) => OmniCastParticipant.fromJson(e as Map<String, dynamic>))
          .take(maxViewersInMemory)
          .toList();
      activeViewersList.value = list;
    }
  }

  /// Queues user joined event with micro-batch throttle (50ms) to eliminate UI thread frame drops.
  void _queueUserJoined(OmniCastParticipant participant) {
    _roomState.addParticipant(participant);

    _pendingLeaves.remove(participant.userId);
    _pendingJoins.add(participant);

    totalViewerCount.value++;
    _scheduleBatchFlush();
  }

  /// Queues user left event with micro-batch throttle.
  void _queueUserLeft(String userId) {
    _roomState.removeParticipant(userId);

    _pendingJoins.removeWhere((p) => p.userId == userId);
    _pendingLeaves.add(userId);

    if (totalViewerCount.value > 0) {
      totalViewerCount.value--;
    }
    _scheduleBatchFlush();
  }

  void _scheduleBatchFlush() {
    _batchDebounceTimer?.cancel();
    _batchDebounceTimer = Timer(const Duration(milliseconds: 50), _flushParticipantBatch);
  }

  void _flushParticipantBatch() {
    if (_pendingJoins.isEmpty && _pendingLeaves.isEmpty) return;

    final currentList = List<OmniCastParticipant>.from(activeViewersList.value);

    // Apply leaves
    if (_pendingLeaves.isNotEmpty) {
      currentList.removeWhere((p) => _pendingLeaves.contains(p.userId));
      _pendingLeaves.clear();
    }

    // Apply joins (prepend latest)
    if (_pendingJoins.isNotEmpty) {
      for (final p in _pendingJoins.reversed) {
        currentList.removeWhere((existing) => existing.userId == p.userId);
        currentList.insert(0, p);
      }
      _pendingJoins.clear();
    }

    // Cap to maximum viewers in UI memory
    if (currentList.length > maxViewersInMemory) {
      currentList.removeRange(maxViewersInMemory, currentList.length);
    }

    activeViewersList.value = List.unmodifiable(currentList);
  }

  /// Creates and starts a new live broadcasting room as Host.
  ///
  /// If [token] is not provided, the SDK automatically generates one using the configured credentials.
  Future<void> createRoom({
    required String roomId,
    required String userId,
    String? token,
    RoomOptions options = const RoomOptions(),
    Map<String, dynamic>? metadata,
  }) async {
    final mergedMetadata = {
      ...?options.metadata,
      ...?metadata,
    };

    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : (_config?.generateToken(
              roomId: roomId,
              userId: userId,
              role: 'host',
              metadata: mergedMetadata,
            ) ??
            '');

    final wsUrl = _config?.hostUrl ?? _signalingClient.wsUrl;
    if (wsUrl != null) {
      if (!_signalingClient.isConnected || _signalingClient.token != effectiveToken) {
        await _signalingClient.connect(wsUrl: wsUrl, token: effectiveToken);
      }
    }

    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.host,
      roomType: options.roomType,
    );

    // Open media & add tracks (Strict 0% video bandwidth enforcement for Audio-Only rooms)
    if (options.isAudioOnly) {
      await _webRTCManager.mediaStreamManager.openUserMedia(
        audio: true,
        video: false,
      );
      await _webRTCManager.addLocalMediaTracks(
        enableSimulcast: false,
      );
    } else if (options.enableAudio || options.enableVideo) {
      await _webRTCManager.mediaStreamManager.openUserMedia(
        audio: options.enableAudio,
        video: options.enableVideo,
      );
      await _webRTCManager.addLocalMediaTracks(
        enableSimulcast: options.enableSimulcast,
      );
    }

    final offer = await _webRTCManager.createAndSetLocalOffer();

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.createRoom,
      roomId: roomId,
      userId: userId,
      payload: {
        'token': effectiveToken,
        'options': options.toJson(),
        'sdp': offer.sdp,
        'type': offer.type,
        'metadata': ?mergedMetadata.isEmpty ? null : mergedMetadata,
      },
    ));
  }

  /// Joins an existing live room as a Viewer.
  ///
  /// If [token] is not provided, the SDK automatically generates one using the configured credentials.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
    String? token,
    Map<String, dynamic>? metadata,
  }) async {
    final effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : (_config?.generateToken(
              roomId: roomId,
              userId: userId,
              role: 'viewer',
              metadata: metadata,
            ) ??
            '');

    final wsUrl = _config?.hostUrl ?? _signalingClient.wsUrl;
    if (wsUrl != null) {
      if (!_signalingClient.isConnected || _signalingClient.token != effectiveToken) {
        await _signalingClient.connect(wsUrl: wsUrl, token: effectiveToken);
      }
    }

    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.viewer,
    );

    await _webRTCManager.setupViewerTransceivers();
    final offer = await _webRTCManager.createAndSetLocalOffer();

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.joinRoom,
      roomId: roomId,
      userId: userId,
      payload: {
        'token': effectiveToken,
        'sdp': offer.sdp,
        'type': offer.type,
        'metadata': ?metadata,
      },
    ));
  }

  /// Leaves the current room session and resets resources.
  /// Leaves the current room session and resets resources.
  Future<void> leaveRoom() async {
    if (_roomState.isInRoom) {
      _signalingClient.send(SignalingMessage(
        event: SignalingEvents.leaveRoom,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
      ));
    }

    await _webRTCManager.closePeerConnection();
    await _webRTCManager.mediaStreamManager.stopLocalMedia();
    _roomState.reset();
  }

  /// Host action: Explicitly terminates the live stream and forcefully ejects all viewers.
  Future<void> closeRoom() async {
    if (_roomState.isInRoom) {
      _signalingClient.send(SignalingMessage(
        event: SignalingEvents.roomClosed,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        payload: {
          'room_id': _roomState.roomId!,
          'reason': 'host_closed',
        },
      ));
    }

    await leaveRoom();
  }

  /// Host action: Kicks a specific user out of the room with an optional reason message.
  void kickUser(String targetUserId, {String? reason}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.kickUser,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
      payload: {
        'room_id': _roomState.roomId!,
        'target_user': targetUserId,
        'user_id': targetUserId,
        'reason': reason ?? 'Kicked by host',
        'kicked_by': _roomState.userId,
      },
    ));
  }

  /// Disposes granular notifiers, timers, and subscriptions.
  void dispose() {
    _batchDebounceTimer?.cancel();
    _signalingSubscription?.cancel();
    _roomState.removeListener(_syncGranularNotifiers);
    _roomClosedByHostController.close();
    _kickedFromRoomController.close();
    _userKickedController.close();

    totalViewerCount.dispose();
    activeViewersList.dispose();
    connectionStateNotifier.dispose();
    roleNotifier.dispose();
    activeSeatsNotifier.dispose();
    pinnedUserNotifier.dispose();
  }
}
