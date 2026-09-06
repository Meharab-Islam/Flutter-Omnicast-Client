import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';
import '../utils/omnicast_logger.dart';

/// Manages stage seats, viewer seat requests, host invitations, seamless WebRTC upgrades
/// without connection teardown, stage demotions, and main stage pinning.
class SeatManager {
  final SignalingClient _signalingClient;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  // Granular ValueNotifiers for headless UI composition
  final ValueNotifier<List<StageSeat>> activeCoHostsList =
      ValueNotifier<List<StageSeat>>(const []);
  final ValueNotifier<List<SeatRequest>> pendingSeatRequestsNotifier =
      ValueNotifier<List<SeatRequest>>(const []);
  final ValueNotifier<List<CoHostInvite>> pendingInvitesNotifier =
      ValueNotifier<List<CoHostInvite>>(const []);
  final ValueNotifier<int> occupiedSeatsCountNotifier = ValueNotifier<int>(0);

  // Backward compatibility alias
  ValueNotifier<List<StageSeat>> get activeSeatsNotifier => activeCoHostsList;

  // Waiting list alias notifier
  ValueNotifier<List<SeatRequest>> get waitingListNotifier =>
      pendingSeatRequestsNotifier;

  /// Returns currently pending co-host seat requests.
  List<SeatRequest> get pendingSeatRequests =>
      pendingSeatRequestsNotifier.value;

  /// Returns list of all stage seats.
  List<StageSeat> get activeSeats => activeCoHostsList.value;

  /// Returns list of occupied stage seats.
  List<StageSeat> get occupiedSeats => _roomState.occupiedSeats;

  /// Returns the number of currently occupied stage seats.
  int get occupiedSeatsCount => _roomState.occupiedSeatsCount;

  /// Returns the [StageSeat] at [seatIndex], or null.
  StageSeat? getSeat(int seatIndex) => _roomState.getSeat(seatIndex);

  /// Returns the [StageSeat] occupied by [userId], or null.
  StageSeat? getSeatOfUser(String userId) => _roomState.getSeatOfUser(userId);

  /// Returns whether [userId] is audio muted.
  bool isUserMuted(String userId) => _roomState.isUserMuted(userId);

  /// Returns whether [userId] has camera off.
  bool isUserCameraOff(String userId) => _roomState.isUserCameraOff(userId);

  // Pure Streams
  final _seatRequestController = StreamController<SeatRequest>.broadcast();
  final _seatInviteController = StreamController<CoHostInvite>.broadcast();
  final _seatAcceptController = StreamController<SignalingMessage>.broadcast();
  final _seatRejectController = StreamController<SignalingMessage>.broadcast();

  final List<StreamSubscription> _subscriptions = [];

  SeatManager({
    required SignalingClient signalingClient,
    required WebRTCManager webRTCManager,
    required RoomState roomState,
  }) : _signalingClient = signalingClient,
       _webRTCManager = webRTCManager,
       _roomState = roomState {
    _bindSignalingListeners();
    _bindStateNotifiers();
  }

  // Stream Getters
  Stream<SeatRequest> get onSeatRequestReceived =>
      _seatRequestController.stream;
  Stream<CoHostInvite> get onSeatInviteReceived => _seatInviteController.stream;
  Stream<SignalingMessage> get onSeatAccepted => _seatAcceptController.stream;
  Stream<SignalingMessage> get onSeatRejected => _seatRejectController.stream;

  void _bindStateNotifiers() {
    _roomState.addListener(_syncSeatNotifiers);
  }

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  void _syncSeatNotifiers() {
    if (_isDisposed) return;
    try {
      activeCoHostsList.value = _roomState.activeSeats;
      pendingSeatRequestsNotifier.value = _roomState.pendingSeatRequests;
      pendingInvitesNotifier.value = _roomState.pendingInvites;
      occupiedSeatsCountNotifier.value = _roomState.occupiedSeatsCount;
    } catch (_) {}
  }

  void _bindSignalingListeners() {
    // 1. Incoming seat requests (viewer -> host)
    _subscriptions.add(
      _signalingClient.onSeatRequest.listen((req) {
        _roomState.addSeatRequest(req);
        _seatRequestController.add(req);
      }),
    );

    // 2. Incoming co-host invitations (host -> viewer)
    _subscriptions.add(
      _signalingClient.onSeatInvite.listen((invite) {
        _roomState.addInvite(invite);
        _seatInviteController.add(invite);
      }),
    );

    // 3. Seat accepted response
    _subscriptions.add(
      _signalingClient.onSeatAccept.listen((msg) async {
        _seatAcceptController.add(msg);

        // If this current user was the viewer whose request was accepted by host
        if (msg.targetUser == _roomState.userId && _roomState.isViewer) {
          OmniCastLogger.log(
            '[SeatManager] Seat request accepted by host -> Triggering seamless WebRTC upgrade',
          );
          await upgradeToCoHost();
        }
      }),
    );

    // 4. Seat rejected response
    _subscriptions.add(
      _signalingClient.onSeatReject.listen((msg) {
        _seatRejectController.add(msg);
      }),
    );

    // 5. Seat kick / demote response (host demotes co-host to viewer)
    _subscriptions.add(
      _signalingClient.onMessage.listen((msg) async {
        if (msg.event == SignalingEvents.seatKick ||
            msg.event == 'seat_demote' ||
            msg.event == 'seat_kicked') {
          final targetUser =
              msg.targetUser ??
              (msg.payload is Map ? msg.payload['target_user'] : null);
          if (targetUser == _roomState.userId && _roomState.isCoHost) {
            OmniCastLogger.log(
              '[SeatManager] Co-host demoted to viewer -> Teardown local publishing tracks seamlessly',
            );
            await _webRTCManager.downgradeCoHostToViewer();
            _roomState.updateRole(UserRole.viewer);
          }
        }
      }),
    );

    // 6. Real-time seat updates across room (9-seat sync)
    _subscriptions.add(
      _signalingClient.onSeatUpdated.listen((msg) {
        if (msg.payload is Map) {
          final payload = Map<String, dynamic>.from(msg.payload as Map);
          final seats = payload['active_seats'] ?? payload['seats'];
          if (seats != null) {
            _roomState.updateActiveSeats(seats);
          }
        }
      }),
    );

    // 7. Remote Co-Host Left or Demoted
    _subscriptions.add(
      _signalingClient.onMessage.listen((msg) {
        if (msg.event == 'cohost_left' || msg.event == 'seat_left') {
          final leftId = msg.payload is Map
              ? (msg.payload['user_id'] ?? msg.payload['userId'] ?? '')
                    .toString()
              : msg.userId;
          if (leftId.isNotEmpty) {
            final updatedSeats = _roomState.activeSeats
                .where((s) => s.userId != leftId)
                .toList();
            _roomState.updateActiveSeats(updatedSeats);

            // Clean up remote renderer for the departed co-host, NEVER touching the host stream
            if (leftId != _roomState.hostId &&
                leftId != 'host' &&
                leftId != _roomState.roomId) {
              _webRTCManager.mediaStreamManager.removeRemoteRenderer(leftId);
              _roomState.removeActiveRemoteUser(leftId);
            }
          }
        }
      }),
    );
  }

  /// Viewer action: Requests to join the broadcast stage as a Co-Host.
  void requestSeat({int? seatIndex}) {
    if (!_roomState.isInRoom || !_roomState.isViewer) return;

    final req = SeatRequest(
      requesterId: _roomState.userId!,
      requesterName: _roomState.userId!,
      preferredSeatIndex: seatIndex,
      requestedAt: DateTime.now(),
    );

    _roomState.addSeatRequest(req);

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatRequest,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        payload: req.toJson(),
      ),
    );
  }

  /// Viewer action: Cancels their own pending seat request from the waiting list.
  void cancelSeatRequest() {
    if (!_roomState.isInRoom || _roomState.userId == null) return;

    _roomState.removeSeatRequest(_roomState.userId!);

    _signalingClient.send(
      SignalingMessage(
        event: 'cancel_seat_request',
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
      ),
    );
  }

  /// Host action: Accepts a viewer's seat request and triggers their upgrade.
  void acceptSeatRequest(String userId, {int? seatIndex}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _roomState.removeSeatRequest(userId);

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatAccept,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: userId,
        payload: {'seat_index': ?seatIndex},
      ),
    );
  }

  /// Host action: Rejects a viewer's seat request.
  void rejectSeatRequest(String userId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _roomState.removeSeatRequest(userId);

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatReject,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: userId,
      ),
    );
  }

  /// Host action: Invites a specific viewer to take a co-host seat on stage.
  void inviteToCoHost(String targetUserId, {int? seatIndex}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    final invite = CoHostInvite(
      inviteId: DateTime.now().millisecondsSinceEpoch.toString(),
      hostId: _roomState.userId!,
      targetUserId: targetUserId,
      seatIndex: seatIndex,
      createdAt: DateTime.now(),
    );

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatInvite,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
        payload: invite.toJson(),
      ),
    );
  }

  /// Viewer action: Accepts a co-host invitation and triggers seamless in-place WebRTC upgrade.
  Future<void> acceptCoHostInvite({
    String? inviteId,
    bool video = true,
    bool audio = true,
  }) async {
    if (!_roomState.isInRoom) return;

    if (inviteId != null) {
      _roomState.removeInvite(inviteId);
    }

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatAccept,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        payload: {'invite_id': ?inviteId},
      ),
    );

    await upgradeToCoHost(video: video, audio: audio);
  }

  /// Viewer action: Rejects an incoming co-host invitation.
  void rejectCoHostInvite({String? inviteId}) {
    if (!_roomState.isInRoom) return;

    if (inviteId != null) {
      _roomState.removeInvite(inviteId);
    }

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatReject,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        payload: {'invite_id': ?inviteId},
      ),
    );
  }

  /// Seamlessly upgrades the active user to a Co-Host without destroying [RTCPeerConnection].
  Future<void> upgradeToCoHost({bool video = true, bool audio = true}) async {
    if (!_roomState.isInRoom) {
      throw StateError('Cannot upgrade to co-host when not in a room');
    }

    final offer = await _webRTCManager.upgradeViewerToCoHost(
      video: video,
      audio: audio,
    );

    _roomState.updateRole(UserRole.coHost);
    if (_roomState.userId != null) {
      _roomState.updateUserMediaState(
        _roomState.userId!,
        isCameraOff: !video,
        isMuted: !audio,
      );
    }

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.publish,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        payload: {'sdp': offer.sdp, 'type': offer.type},
      ),
    );

    // Broadcast initial active media states for the newly upgraded co-host
    if (_roomState.isInRoom && _signalingClient.isConnected) {
      _signalingClient.send(
        SignalingMessage(
          event: 'media_state_changed',
          roomId: _roomState.roomId!,
          userId: _roomState.userId!,
          payload: {
            'type': 'video',
            'kind': 'video',
            'muted': !video,
            'camera_off': !video,
            'is_camera_off': !video,
            'enabled': video,
          },
        ),
      );
      _signalingClient.send(
        SignalingMessage(
          event: 'media_state_changed',
          roomId: _roomState.roomId!,
          userId: _roomState.userId!,
          payload: {
            'type': 'audio',
            'kind': 'audio',
            'muted': !audio,
            'is_muted': !audio,
          },
        ),
      );
    }
  }

  /// Co-Host action: Voluntarily leaves the stage seat and returns to viewer mode.
  Future<void> leaveSeat() async {
    if (!_roomState.isInRoom || !_roomState.isCoHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatLeave,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
      ),
    );

    OmniCastLogger.log(
      '[SeatManager] Stepping down from co-host seat -> Teardown local publishing tracks seamlessly',
    );
    await _webRTCManager.downgradeCoHostToViewer();
    _roomState.updateRole(UserRole.viewer);
  }

  /// Host action: Demotes a co-host back to a viewer seat without kicking them from the room.
  void demoteToViewer(String targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatKick,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
      ),
    );
  }

  /// Host action alias: Demotes a co-host back to a viewer seat without kicking them from the room.
  void kickFromStage(String targetUserId) => demoteToViewer(targetUserId);

  /// Host action: Remotely mutes or unmutes a co-host's microphone track.
  void muteCoHost(String targetUserId, {bool mute = true}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.mediaStateChanged,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
        payload: {
          'target_user': targetUserId,
          'type': 'audio',
          'kind': 'audio',
          'muted': mute,
          'is_muted': mute,
          'forced_by_host': true,
        },
      ),
    );
  }

  /// Host action: Remotely disables a co-host's camera track.
  void disableCoHostCamera(String targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.mediaStateChanged,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
        payload: {
          'target_user': targetUserId,
          'type': 'video',
          'kind': 'video',
          'muted': true,
          'camera_off': true,
          'is_camera_off': true,
          'forced_by_host': true,
        },
      ),
    );
  }

  /// Host action: Pins a specific user to the main stage layout for all viewers.
  void pinToMainStage(String? targetUserId) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.pinStage,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
        payload: {
          'pinned_user_id': targetUserId,
          'target_id': targetUserId,
          'main_seat_id': targetUserId,
        },
      ),
    );

    _roomState.setPinnedStageUser(targetUserId);
  }

  /// Host action: Promotes/sets any co-host to the Main Seat (Slot 0).
  void setMainSeat(String? targetUserId) {
    pinToMainStage(targetUserId);
  }

  /// Host action: Removes co-host from Main Seat and restores Host to Main Seat (Slot 0).
  void restoreHostMainSeat() {
    pinToMainStage(null);
  }

  /// Host action: Kicks a co-host from their assigned stage seat.
  void kickSeat(int seatIndex, {String? targetUserId}) {
    if (!_roomState.isInRoom || !_roomState.isHost) return;

    _signalingClient.send(
      SignalingMessage(
        event: SignalingEvents.seatKick,
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: targetUserId,
        payload: {
          'seat_index': seatIndex,
          'seat_id': seatIndex.toString(),
          'target_user': targetUserId,
          'user_id': targetUserId,
        },
      ),
    );
  }

  /// Viewer action: Explicitly requests to subscribe to a co-host's media tracks.
  void subscribeCoHost(String coHostUserId) {
    if (!_roomState.isInRoom) return;

    _signalingClient.send(
      SignalingMessage(
        event: 'subscribe_cohost',
        roomId: _roomState.roomId!,
        userId: _roomState.userId!,
        targetUser: coHostUserId,
        payload: {'target_user': coHostUserId, 'cohost_id': coHostUserId},
      ),
    );
  }

  /// Disposes streams, listeners, and notifiers.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _roomState.removeListener(_syncSeatNotifiers);
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();

    try {
      activeCoHostsList.dispose();
    } catch (_) {}
    try {
      pendingSeatRequestsNotifier.dispose();
    } catch (_) {}
    try {
      pendingInvitesNotifier.dispose();
    } catch (_) {}

    await _seatRequestController.close();
    await _seatInviteController.close();
    await _seatAcceptController.close();
    await _seatRejectController.close();
  }
}
