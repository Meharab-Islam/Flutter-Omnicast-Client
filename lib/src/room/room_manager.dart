import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/omnicast_api.dart';
import '../core/omnicast_config.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../utils/omnicast_logger.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages room lifecycle, participant tracking, and provides granular [ValueNotifier]
/// state providers with event batch throttling for high-scale rooms (10,000+ viewers).
class RoomManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;
  final OmniCastConfig? _config;
  late final OmniCastApi _api;

  // Maximum active viewer avatar objects kept in UI memory
  static const int maxViewersInMemory = 200;

  // Granular Notifiers for Headless UI Integration
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
  Timer? _roomSyncTimer;
  StreamSubscription? _signalingSubscription;

  RoomManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
    OmniCastConfig? config,
    OmniCastApi? api,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState,
        _config = config,
        _api = api ?? OmniCastApi(config: config ?? const OmniCastConfig(hostUrl: '')) {
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
  final _participantJoinedController = StreamController<OmniCastParticipant>.broadcast();
  final _participantLeftController = StreamController<String>.broadcast();

  /// Stream emitting when the room is terminated/closed by the host.
  Stream<String> get onRoomClosedByHost => _roomClosedByHostController.stream;

  /// Stream emitting when the local user has been kicked out of the room by host.
  Stream<KickedEvent> get onKickedFromRoom => _kickedFromRoomController.stream;

  /// Stream emitting the userId whenever any user in the room is kicked.
  Stream<String> get onUserKicked => _userKickedController.stream;

  /// Stream emitting whenever a new participant joins the live broadcast room.
  Stream<OmniCastParticipant> get onParticipantJoined => _participantJoinedController.stream;

  /// Stream emitting the userId whenever a participant leaves the live broadcast room.
  Stream<String> get onParticipantLeft => _participantLeftController.stream;

  /// Stream aliases for seamless developer experience
  Stream<OmniCastParticipant> get onUserJoined => _participantJoinedController.stream;
  Stream<String> get onUserLeft => _participantLeftController.stream;

  /// Listens to real-time participant signaling events with high-performance debouncing.
  void _bindSignalingEvents() {
    _signalingSubscription = _signalingClient.onMessage.listen((msg) {
      switch (msg.event) {
        // 1. Initial Snapshot on Join
        case SignalingEvents.roomInfoSync:
        case 'room_info':
        case 'roomInfoSync':
        case 'sync_room_info':
        case 'room_sync':
          if (msg.payload is Map<String, dynamic>) {
            _handleRoomInfoSync(msg.payload as Map<String, dynamic>);
          }
          break;

        // 2. Real-time User Joined Event
        case SignalingEvents.userJoined:
        case 'user_join':
        case 'userJoined':
        case 'participant_joined':
        case 'participantJoined':
        case 'viewer_joined':
        case 'viewerJoined':
        case 'room_user_joined':
        case 'member_joined':
        case 'join_room':
        case 'join':
          final payloadMap = msg.payload is Map<String, dynamic>
              ? msg.payload as Map<String, dynamic>
              : (msg.payload is Map ? Map<String, dynamic>.from(msg.payload as Map) : <String, dynamic>{});
          final effectivePayload = {
            'user_id': msg.userId,
            ...payloadMap,
          };
          final participant = OmniCastParticipant.fromJson(effectivePayload);
          if (participant.userId.isNotEmpty) {
            _queueUserJoined(participant);
          }
          break;

        // 3. Real-time User Left Event
        case SignalingEvents.userLeft:
        case 'user_leave':
        case 'userLeft':
        case 'participant_left':
        case 'participantLeft':
        case 'viewer_left':
        case 'viewerLeft':
        case 'room_user_left':
        case 'member_left':
        case 'leave_room':
        case 'leave':
          final leftUserId = msg.payload is Map && msg.payload['user_id'] != null
              ? msg.payload['user_id'].toString()
              : (msg.payload is Map && msg.payload['userId'] != null
                  ? msg.payload['userId'].toString()
                  : msg.userId);
          if (leftUserId.isNotEmpty) {
            _queueUserLeft(leftUserId);
          }
          break;

        // 4. Batch Viewer Count Sync
        case SignalingEvents.viewerUpdate:
        case 'viewers_update':
        case 'viewerUpdate':
        case 'viewersUpdate':
        case 'viewer_count':
        case 'viewers_count':
        case 'room_viewers':
        case 'viewers':
          if (msg.payload is Map<String, dynamic>) {
            final payload = msg.payload as Map<String, dynamic>;
            final count = (payload['viewers_count'] as num?)?.toInt() ??
                (payload['viewer_count'] as num?)?.toInt() ??
                (payload['count'] as num?)?.toInt() ??
                totalViewerCount.value;
            totalViewerCount.value = count;
            if (payload['viewers'] is List) {
              final viewers = (payload['viewers'] as List)
                  .whereType<Map>()
                  .map((e) => OmniCastParticipant.fromJson(Map<String, dynamic>.from(e)))
                  .take(maxViewersInMemory)
                  .toList();
              activeViewersList.value = viewers;
            }
          } else if (msg.payload is num) {
            totalViewerCount.value = (msg.payload as num).toInt();
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
          .whereType<Map>()
          .map((e) => OmniCastParticipant.fromJson(Map<String, dynamic>.from(e)))
          .take(maxViewersInMemory)
          .toList();
      activeViewersList.value = list;
    }
  }

  /// Queues user joined event with immediate in-memory reactivity and micro-batch throttle.
  void _queueUserJoined(OmniCastParticipant participant) {
    _roomState.addParticipant(participant);

    _pendingLeaves.remove(participant.userId);
    _pendingJoins.add(participant);

    totalViewerCount.value++;
    _participantJoinedController.add(participant);
    _flushParticipantBatch();
  }

  /// Queues user left event with immediate in-memory reactivity.
  void _queueUserLeft(String userId) {
    _roomState.removeParticipant(userId);

    _pendingJoins.removeWhere((p) => p.userId == userId);
    _pendingLeaves.add(userId);

    if (totalViewerCount.value > 0) {
      totalViewerCount.value--;
    }
    _participantLeftController.add(userId);
    _flushParticipantBatch();
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

    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.host,
      roomType: options.roomType,
    );

    // Initial Host Participant in Viewers List
    final hostParticipant = OmniCastParticipant(
      userId: userId,
      displayName: mergedMetadata['displayName'] as String? ??
          mergedMetadata['user_name'] as String? ??
          mergedMetadata['name'] as String? ??
          userId,
      avatarUrl: mergedMetadata['avatarUrl'] as String? ??
          mergedMetadata['avatar'] as String?,
      role: UserRole.host,
      joinedAt: DateTime.now(),
      metadata: mergedMetadata,
    );
    _roomState.addParticipant(hostParticipant);
    activeViewersList.value = [hostParticipant];
    totalViewerCount.value = 1;

    _startRoomStateSync();

    // 1. Open media hardware & add tracks immediately so local camera preview starts without waiting for network!
    try {
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
    } catch (e) {
      OmniCastLogger.error('[RoomManager] Media open deferred or headless: $e');
    }

    // 2. Connect signaling WebSocket and publish room session
    final wsUrl = _config?.hostUrl ?? _signalingClient.wsUrl;
    if (wsUrl != null) {
      if (!_signalingClient.isConnected || _signalingClient.token != effectiveToken) {
        try {
          await _signalingClient.connect(wsUrl: wsUrl, token: effectiveToken);
        } catch (e) {
          OmniCastLogger.error('[RoomManager] WebSocket connection deferred or offline: $e');
        }
      }
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
        'metadata': mergedMetadata.isEmpty ? null : mergedMetadata,
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

    // Initial Joining Viewer in Viewers List
    final joinParticipant = OmniCastParticipant(
      userId: userId,
      displayName: metadata?['displayName'] as String? ??
          metadata?['user_name'] as String? ??
          metadata?['name'] as String? ??
          userId,
      avatarUrl: metadata?['avatarUrl'] as String? ??
          metadata?['avatar'] as String?,
      role: UserRole.viewer,
      joinedAt: DateTime.now(),
      metadata: metadata ?? const {},
    );
    _roomState.addParticipant(joinParticipant);
    final currentList = List<OmniCastParticipant>.from(activeViewersList.value);
    if (!currentList.any((p) => p.userId == userId)) {
      currentList.insert(0, joinParticipant);
      activeViewersList.value = currentList;
      totalViewerCount.value = currentList.length;
    }

    _startRoomStateSync();

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
        'metadata': metadata,
      },
    ));
  }

  /// Periodically synchronizes room state, active seats, and viewers from backend.
  void _startRoomStateSync() {
    _roomSyncTimer?.cancel();
    _roomSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_roomState.isInRoom) {
        _syncRoomStateFromApi();
      }
    });
    // Fast initial sync after 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_roomState.isInRoom) {
        _syncRoomStateFromApi();
      }
    });
  }

  Future<void> _syncRoomStateFromApi() async {
    final rId = _roomState.roomId;
    if (rId == null || rId.isEmpty) return;

    try {
      // 1. Send WebSocket sync request
      if (_signalingClient.isConnected) {
        _signalingClient.send(SignalingMessage(
          event: 'get_room_info',
          roomId: rId,
          userId: _roomState.userId ?? '',
          payload: {'roomId': rId, 'room_id': rId},
        ));
      }

      // 2. Query REST API snapshot
      final roomData = await _api.getRoom(rId);
      if (roomData != null) {
        _handleRoomInfoSync(roomData);
      }
    } catch (_) {}
  }

  /// Leaves the current room session and resets resources.
  Future<void> leaveRoom() async {
    _roomSyncTimer?.cancel();
    _roomSyncTimer = null;

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
    _participantJoinedController.close();
    _participantLeftController.close();

    totalViewerCount.dispose();
    activeViewersList.dispose();
    connectionStateNotifier.dispose();
    roleNotifier.dispose();
    activeSeatsNotifier.dispose();
    pinnedUserNotifier.dispose();
  }
}
