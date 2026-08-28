import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';

/// Manages room lifecycle (create, join, leave, kick) and provides atomic [ValueNotifier]
/// state providers for headless, granular UI reactivity.
class RoomManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  // Granular atomic ValueNotifiers for headless UI composition
  final ValueNotifier<int> viewerCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<ClientConnectionState> connectionStateNotifier =
      ValueNotifier<ClientConnectionState>(ClientConnectionState.disconnected);
  final ValueNotifier<UserRole> roleNotifier =
      ValueNotifier<UserRole>(UserRole.viewer);
  final ValueNotifier<List<StageSeat>> activeSeatsNotifier =
      ValueNotifier<List<StageSeat>>(const []);
  final ValueNotifier<String?> pinnedUserNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<List<Participant>> viewersNotifier =
      ValueNotifier<List<Participant>>(const []);

  RoomManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  })  : _signalingClient = signalingClient,
        _webRTCManager = webRTCManager,
        _roomState = roomState {
    _bindStateNotifiers();
  }

  void _bindStateNotifiers() {
    _roomState.addListener(_syncGranularNotifiers);
  }

  void _syncGranularNotifiers() {
    if (viewerCountNotifier.value != _roomState.viewersCount) {
      viewerCountNotifier.value = _roomState.viewersCount;
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
    viewersNotifier.value = _roomState.viewers;
  }

  /// Creates and starts a new live broadcasting room as Host.
  Future<void> createRoom({
    required String roomId,
    required String userId,
    RoomOptions options = const RoomOptions(),
  }) async {
    _roomState.setSession(
      roomId: roomId,
      userId: userId,
      role: UserRole.host,
    );

    // Open media & add tracks
    if (options.enableAudio || options.enableVideo) {
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
        'options': options.toJson(),
        'sdp': offer.sdp,
        'type': offer.type,
      },
    ));
  }

  /// Joins an existing live room as a Viewer.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
  }) async {
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
        'sdp': offer.sdp,
        'type': offer.type,
      },
    ));
  }

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

  /// Host action: Kicks a specific user out of the room.
  void kickUser(String targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(SignalingMessage(
      event: SignalingEvents.kickUser,
      roomId: _roomState.roomId!,
      userId: _roomState.userId!,
      targetUser: targetUserId,
    ));
  }

  /// Disposes granular notifiers.
  void dispose() {
    _roomState.removeListener(_syncGranularNotifiers);
    viewerCountNotifier.dispose();
    connectionStateNotifier.dispose();
    roleNotifier.dispose();
    activeSeatsNotifier.dispose();
    pinnedUserNotifier.dispose();
    viewersNotifier.dispose();
  }
}
