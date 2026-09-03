import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/omnicast_api.dart';
import '../datachannel/data_channel_manager.dart';
import '../interaction/interaction_manager.dart';
import '../media/media_controller.dart';
import '../media/media_stream_manager.dart';
import '../media/global_media_config.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';
import '../models/signaling_message.dart';
import '../pk/pk_manager.dart';
import '../room/room_manager.dart';
import '../seats/seat_manager.dart';
import '../signaling/signaling_client.dart';
import '../state/room_state.dart';
import '../webrtc/webrtc_manager.dart';
import '../utils/omnicast_logger.dart';
import 'omnicast_config.dart';

/// The central production SDK Facade for OmniCast Live & WebRTC SFU engine.
///
/// Exposes modular sub-managers:
/// - [api]: [OmniCastApi] (getLiveRooms, REST endpoints)
/// - [room]: [RoomManager] (createRoom, joinRoom, leaveRoom, kickUser)
/// - [media]: [MediaController] (mute/camera toggles, simulcast layer, dynacast)
/// - [seats]: [SeatManager] (co-host invite/accept/upgrade, stage pinning, demotion)
/// - [interaction]: [InteractionManager] (chats, gifts, balance streams)
/// - [pk]: [PKManager] (host PK battles, timer ticks, score updates)
/// - [dataChannel]: [DataChannelManager] (zero-latency in-room events)
/// - [state]: [RoomState] (reactive global state container)
class OmniCastClient {
  /// Global singleton accessor for the initialized [OmniCastClient] instance.
  static OmniCastClient? instance;

  final OmniCastConfig config;
  final GlobalMediaConfig mediaConfig;
  final SignalingClient _signalingClient;
  final MediaStreamManager _mediaStreamManager;
  final WebRTCManager _webRTCManager;
  final RoomState _roomState;

  // Sub-module managers
  late final OmniCastApi _api;
  late final RoomManager _roomManager;
  late final MediaController _mediaController;
  late final SeatManager _seatManager;
  late final InteractionManager _interactionManager;
  late final PKManager _pkManager;
  late final DataChannelManager _dataChannelManager;

  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  OmniCastClient.custom({
    required this.config,
    this.mediaConfig = const GlobalMediaConfig(),
    SignalingClient? signalingClient,
    MediaStreamManager? mediaStreamManager,
    WebRTCManager? webRTCManager,
    RoomState? roomState,
  })  : _mediaStreamManager = mediaStreamManager ?? MediaStreamManager(),
        _signalingClient = signalingClient ??
            SignalingClient(
              heartbeatInterval: config.heartbeatInterval,
            ),
        _roomState = roomState ?? RoomState(),
        _webRTCManager = webRTCManager ??
            WebRTCManager(
              mediaStreamManager: mediaStreamManager ?? MediaStreamManager(),
              configuration: {
                'iceServers': config.iceServers,
                'sdpSemantics': 'unified-plan',
              },
            ) {
    instance = this;
    _initSubManagers();
    _bindInternalEventListeners();
  }

  OmniCastClient._({
    required OmniCastConfig config,
    GlobalMediaConfig mediaConfig = const GlobalMediaConfig(),
    SignalingClient? signalingClient,
    MediaStreamManager? mediaStreamManager,
    WebRTCManager? webRTCManager,
    RoomState? roomState,
  }) : this.custom(
          config: config,
          mediaConfig: mediaConfig,
          signalingClient: signalingClient,
          mediaStreamManager: mediaStreamManager,
          webRTCManager: webRTCManager,
          roomState: roomState,
        );

  /// Master toggle for console logs across the SDK (WebRTC, signaling, media).
  static bool get enableLogging => OmniCastLogger.enableLogging;
  static set enableLogging(bool value) => OmniCastLogger.enableLogging = value;

  /// Initializes the [OmniCastClient] SDK using server credentials, SFU host URL, and media configuration.
  ///
  /// Developers can simply provide their server domain (e.g. `testlive.lolipoplive.top`) and credentials:
  /// ```dart
  /// await OmniCastClient.init(
  ///   serverUrl: 'testlive.lolipoplive.top',
  ///   apiKey: 'dev_api_key_123',
  ///   apiSecret: 'my_secret_key_456',
  ///   enableLogging: false, // Turn on/off console logs
  /// );
  /// ```
  static Future<OmniCastClient> init({
    String? serverUrl,
    String? hostUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    String? jwtSecret,
    GlobalMediaConfig? mediaConfig,
    String? token,
    bool autoConnect = true,
    bool enableLogging = false,
    List<Map<String, dynamic>>? iceServers,
    Duration heartbeatInterval = const Duration(seconds: 15),
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
    bool? isSecure,
    String wsPath = '/ws',
    String apiPath = '/api',
  }) async {
    OmniCastLogger.enableLogging = enableLogging;

    final config = OmniCastConfig.fromServer(
      serverUrl: serverUrl,
      hostUrl: hostUrl,
      apiUrl: apiUrl,
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret,
      enableLogging: enableLogging,
      iceServers: iceServers ??
          const [
            {'urls': 'stun:stun.l.google.com:19302'},
            {'urls': 'stun:stun1.l.google.com:19302'},
          ],
      heartbeatInterval: heartbeatInterval,
      reconnectDelay: reconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts,
      isSecure: isSecure,
      wsPath: wsPath,
      apiPath: apiPath,
    );

    final client = OmniCastClient._(
      config: config,
      mediaConfig: mediaConfig ?? const GlobalMediaConfig(),
    );
    instance = client;
    if (autoConnect) {
      try {
        await client._signalingClient.connect(wsUrl: config.hostUrl, token: token);
      } catch (e) {
        debugPrint('[OmniCastClient] Initial connection deferred or offline: $e');
      }
    }
    return client;
  }

  /// Creates and starts a new live broadcasting room as Host.
  /// Automatically generates JWT auth token from credentials configured at SDK initialization.
  Future<void> createRoom({
    required String roomId,
    required String userId,
    String? token,
    RoomOptions options = const RoomOptions(),
    Map<String, dynamic>? metadata,
  }) =>
      _roomManager.createRoom(
        roomId: roomId,
        userId: userId,
        token: token,
        options: options,
        metadata: metadata,
      );

  /// Joins an existing broadcasting room as a Viewer.
  /// Automatically generates JWT auth token from credentials configured at SDK initialization.
  Future<void> joinRoom({
    required String roomId,
    required String userId,
    String? token,
    Map<String, dynamic>? metadata,
  }) =>
      _roomManager.joinRoom(
        roomId: roomId,
        userId: userId,
        token: token,
        metadata: metadata,
      );

  /// Leaves the current room session, tears down peer connections, and stops local media tracks.
  Future<void> leaveRoom() => _roomManager.leaveRoom();

  /// Host action: Explicitly ends and terminates the live broadcast room, notifying all viewers.
  Future<void> closeRoom() => _roomManager.closeRoom();

  void _initSubManagers() {
    _api = OmniCastApi(config: config);

    _roomManager = RoomManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
      config: config,
    );

    _mediaController = MediaController(
      mediaStreamManager: _mediaStreamManager,
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
      globalConfig: mediaConfig,
      config: config,
    );

    _seatManager = SeatManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );

    _interactionManager = InteractionManager(
      signalingClient: _signalingClient,
      roomState: _roomState,
    );

    _pkManager = PKManager(
      signalingClient: _signalingClient,
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );

    _dataChannelManager = DataChannelManager(
      webRTCManager: _webRTCManager,
      roomState: _roomState,
    );
  }

  // Sub-module Getters
  OmniCastApi get api => _api;
  RoomManager get room => _roomManager;
  MediaController get media => _mediaController;
  SeatManager get seats => _seatManager;
  InteractionManager get interaction => _interactionManager;
  PKManager get pk => _pkManager;
  DataChannelManager get dataChannel => _dataChannelManager;
  RoomState get state => _roomState;
  MediaStreamManager get streamManager => _mediaStreamManager;
  SignalingClient get signaling => _signalingClient;
  WebRTCManager get webrtc => _webRTCManager;

  // Real-time Global Room & Media Event Streams
  Stream<RoomModel> get onRoomCreated => _signalingClient.onRoomCreated;
  Stream<String> get onRoomClosed => _signalingClient.onRoomClosed;
  Stream<String> get onRoomClosedByHost => _roomManager.onRoomClosedByHost;
  Stream<KickedEvent> get onKickedFromRoom => _roomManager.onKickedFromRoom;
  Stream<String> get onUserKicked => _roomManager.onUserKicked;
  Stream<OmniCastParticipant> get onParticipantJoined => _roomManager.onParticipantJoined;
  Stream<String> get onParticipantLeft => _roomManager.onParticipantLeft;
  Stream<OmniCastParticipant> get onUserJoined => _roomManager.onUserJoined;
  Stream<String> get onUserLeft => _roomManager.onUserLeft;
  Stream<SignalingMessage> get onMediaStateChanged => _signalingClient.onMediaStateChanged;

  // Real-time Reactive ValueListenable Notifiers for UI Composition
  ValueNotifier<List<OmniCastParticipant>> get viewersNotifier => _roomManager.activeViewersList;
  ValueNotifier<List<OmniCastParticipant>> get activeViewersList => _roomManager.activeViewersList;
  ValueNotifier<int> get viewerCountNotifier => _roomManager.totalViewerCount;
  ValueNotifier<int> get totalViewerCount => _roomManager.totalViewerCount;
  ValueNotifier<bool> get showJoinMessagesNotifier => _roomState.showJoinMessagesNotifier;
  bool get showJoinMessages => _roomState.showJoinMessages;
  set showJoinMessages(bool value) => _roomState.showJoinMessages = value;

  /// Host action: Kicks/ejects a participant out of the live room.
  void kickUser(String targetUserId, {String? reason}) =>
      _roomManager.kickUser(targetUserId, reason: reason);

  /// Host action alias: Kicks/ejects a participant out of the live room.
  void kickParticipant(String targetUserId, {String? reason}) =>
      _roomManager.kickUser(targetUserId, reason: reason);

  // Co-Host & Stage Seat Action Facades
  /// Viewer action: Requests to join the broadcast stage as a Co-Host.
  void requestCoHost({int? seatIndex}) => _seatManager.requestSeat(seatIndex: seatIndex);

  /// Viewer action: Cancels their own pending co-host seat request.
  void cancelCoHostRequest() => _seatManager.cancelSeatRequest();

  /// Host action: Accepts a viewer's co-host request and brings them onto the live stage.
  void acceptCoHostRequest(String userId, {int? seatIndex}) =>
      _seatManager.acceptSeatRequest(userId, seatIndex: seatIndex);

  /// Host action: Rejects a viewer's co-host request.
  void rejectCoHostRequest(String userId) => _seatManager.rejectSeatRequest(userId);

  /// Host action: Invites a specific viewer to take a co-host seat on stage.
  void inviteToCoHost(String targetUserId, {int? seatIndex}) =>
      _seatManager.inviteToCoHost(targetUserId, seatIndex: seatIndex);

  /// Viewer action: Accepts a co-host invitation from the host.
  Future<void> acceptCoHostInvite({String? inviteId, bool video = true, bool audio = true}) =>
      _seatManager.acceptCoHostInvite(inviteId: inviteId, video: video, audio: audio);

  /// Viewer action: Rejects a co-host invitation from the host.
  void rejectCoHostInvite({String? inviteId}) =>
      _seatManager.rejectCoHostInvite(inviteId: inviteId);

  /// Co-Host action: Leaves the stage seat and returns to viewer mode.
  Future<void> leaveCoHostSeat() => _seatManager.leaveSeat();

  /// Host action: Demotes a co-host back to a viewer seat without kicking them.
  void demoteCoHost(String userId) => _seatManager.demoteToViewer(userId);

  // Co-Host Streams
  /// Stream emitting when a viewer requests to become a co-host (Host listens to this).
  Stream<SeatRequest> get onCoHostRequested => _seatManager.onSeatRequestReceived;

  /// Stream emitting when the host invites the viewer to co-host (Viewer listens to this).
  Stream<CoHostInvite> get onCoHostInviteReceived => _seatManager.onSeatInviteReceived;

  /// Stream emitting when the viewer's co-host request is accepted.
  Stream<SignalingMessage> get onCoHostAccepted => _seatManager.onSeatAccepted;

  /// Stream emitting when the viewer's co-host request is rejected.
  Stream<SignalingMessage> get onCoHostRejected => _seatManager.onSeatRejected;

  /// Built-in hardware permission requester for Camera and Microphone.
  ///
  /// Prompts Android and iOS to grant microphone/camera permissions without external plugins.
  Future<bool> requestPermissions({bool camera = true, bool microphone = true}) =>
      _mediaController.requestPermissions(camera: camera, microphone: microphone);

  /// Binds internal signaling and WebRTC event subscriptions.
  void _bindInternalEventListeners() {
    // 1. WebRTC Local ICE Candidates -> Signaling Server
    _webRTCManager.onLocalIceCandidate = (candidate) {
      if (_roomState.isInRoom) {
        _signalingClient.send(SignalingMessage(
          event: SignalingEvents.ice,
          roomId: _roomState.roomId!,
          userId: _roomState.userId!,
          payload: {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ));
      }
    };

    // 1.1 WebRTC ICE Disconnection Auto-Recovery & Seamless Network Handoff (1-2s trigger)
    _webRTCManager.onIceRestartNeeded = () async {
      if (_roomState.isInRoom) {
        if (_signalingClient.isConnected) {
          debugPrint('[OmniCastClient] Requesting seamless ICE Restart from SFU...');
          try {
            final restartOffer = await _webRTCManager.createIceRestartOffer();
            final eventName = _roomState.isHost ? SignalingEvents.createRoom : SignalingEvents.joinRoom;
            _signalingClient.send(SignalingMessage(
              event: eventName,
              roomId: _roomState.roomId!,
              userId: _roomState.userId!,
              payload: {
                'token': _signalingClient.token,
                'sdp': restartOffer.sdp,
                'type': restartOffer.type,
                'ice_restart': true,
                'reconnect': true,
              },
            ));
          } catch (e) {
            debugPrint('[OmniCastClient] Fallback to ice_restart_request: $e');
            _signalingClient.send(SignalingMessage(
              event: 'ice_restart_request',
              roomId: _roomState.roomId!,
              userId: _roomState.userId!,
            ));
          }
        } else {
          debugPrint('[OmniCastClient] ICE Restart needed but signaling is disconnected; auto-reconnect will recover session upon reconnection.');
        }
      }
    };

    // 1.2 Network Restoration & Signaling Auto-Reconnect Session Recovery
    _subscriptions.add(
      _signalingClient.onReconnected.listen((_) async {
        if (_roomState.isInRoom) {
          debugPrint(
              '[OmniCastClient] Network restored & Signaling reconnected! Restoring session & triggering ICE restart for room: ${_roomState.roomId}');
          try {
            final restartOffer = await _webRTCManager.createIceRestartOffer();
            final eventName = _roomState.isHost ? SignalingEvents.createRoom : SignalingEvents.joinRoom;
            _signalingClient.send(SignalingMessage(
              event: eventName,
              roomId: _roomState.roomId!,
              userId: _roomState.userId!,
              payload: {
                'token': _signalingClient.token,
                'sdp': restartOffer.sdp,
                'type': restartOffer.type,
                'reconnect': true,
                'ice_restart': true,
              },
            ));
          } catch (e) {
            debugPrint('[OmniCastClient] Auto-reconnect session recovery error: $e');
          }
        }
      }),
    );

    // 2. WebRTC Remote Track -> MediaStreamManager & RoomState
    _webRTCManager.onRemoteTrack = (track, stream) async {
      final streamId = stream.id;
      final peerId = streamId.isNotEmpty ? streamId : (_roomState.hostId ?? 'remote_peer');
      await _mediaStreamManager.attachRemoteStream(peerId, stream);
      _roomState.addActiveRemoteUser(peerId);
    };

    // 3. Signaling State -> RoomState
    _subscriptions.add(
      _signalingClient.onConnectionStateChanged.listen((connState) {
        _roomState.updateConnectionState(connState);
      }),
    );

    // 4. Signaling Answer -> WebRTC Manager
    _subscriptions.add(
      _signalingClient.onAnswer.listen((msg) async {
        final payload = msg.payload;
        String? sdp;
        if (payload is Map<String, dynamic>) {
          sdp = payload['sdp'] as String?;
        } else if (payload is String) {
          sdp = payload;
        }

        if (sdp != null && sdp.isNotEmpty) {
          await _webRTCManager.handleRemoteAnswer(sdp);
        }
      }),
    );

    // 5. Server-Initiated SDP Offer -> WebRTC Answer -> Reply via Signaling
    _subscriptions.add(
      _signalingClient.onOffer.listen((msg) async {
        final payload = msg.payload;
        String? sdp;
        if (payload is Map<String, dynamic>) {
          sdp = payload['sdp'] as String?;
        } else if (payload is String) {
          sdp = payload;
        }

        if (sdp != null && sdp.isNotEmpty && _roomState.isInRoom) {
          final answer = await _webRTCManager.handleRemoteOfferAndCreateAnswer(sdp);
          _signalingClient.send(SignalingMessage(
            event: SignalingEvents.sdpAnswer,
            roomId: _roomState.roomId!,
            userId: _roomState.userId!,
            payload: {
              'sdp': answer.sdp,
              'type': answer.type,
            },
          ));
        }
      }),
    );

    // 6. Incoming ICE Candidates -> WebRTC Manager
    _subscriptions.add(
      _signalingClient.onIceCandidate.listen((msg) async {
        if (msg.payload is Map<String, dynamic>) {
          await _webRTCManager.addRemoteCandidate(msg.payload as Map<String, dynamic>);
        }
      }),
    );

    // 7. Room Info Sync (Late-join hydration)
    _subscriptions.add(
      _signalingClient.onRoomInfoSync.listen((msg) {
        if (msg.payload is Map<String, dynamic>) {
          _roomState.syncRoomInfo(msg.payload as Map<String, dynamic>);
        }
      }),
    );

    // 8. Viewer Updates
    _subscriptions.add(
      _signalingClient.onViewerUpdate.listen((msg) {
        if (msg.payload is Map<String, dynamic>) {
          final payload = msg.payload as Map<String, dynamic>;
          final count = (payload['viewers_count'] as num?)?.toInt() ??
              (payload['viewer_count'] as num?)?.toInt() ??
              0;
          List<Participant>? viewersList;
          if (payload['viewers'] is List) {
            viewersList = (payload['viewers'] as List)
                .map((e) => Participant.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          _roomState.updateViewers(count: count, viewersList: viewersList);
        }
      }),
    );

    // 9. Real-Time Chat
    _subscriptions.add(
      _signalingClient.onChat.listen((chatMsg) {
        _roomState.addChatMessage(chatMsg);
      }),
    );

    // 10. Seat Invites & Requests
    _subscriptions.add(
      _signalingClient.onMessage.listen((msg) {
        if (msg.event == SignalingEvents.seatInvite && msg.payload is Map<String, dynamic>) {
          _roomState.addInvite(CoHostInvite.fromJson(msg.payload as Map<String, dynamic>));
        } else if (msg.event == SignalingEvents.pinStage && msg.payload is Map<String, dynamic>) {
          _roomState.setPinnedStageUser(msg.payload['pinned_user_id'] as String?);
        }
      }),
    );
  }

  /// Permanently disposes the client, closing sub-managers, streams, peer connections, and WebSockets.
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();

    _roomManager.dispose();
    _mediaController.dispose();
    _seatManager.dispose();
    await _pkManager.dispose();
    await _dataChannelManager.dispose();
    await _interactionManager.dispose();

    await _webRTCManager.dispose();
    await _mediaStreamManager.dispose();
    await _signalingClient.dispose();
    _api.dispose();
    _roomState.dispose();
    if (instance == this) {
      instance = null;
    }
  }
}
