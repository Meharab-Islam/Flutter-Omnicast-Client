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

  /// Initializes the [OmniCastClient] SDK using server credentials, SFU host URL, and media configuration.
  static Future<OmniCastClient> init({
    required String hostUrl,
    String? apiUrl,
    String? apiKey,
    String? apiSecret,
    String? jwtSecret,
    GlobalMediaConfig? mediaConfig,
    String? token,
    bool autoConnect = true,
    List<Map<String, dynamic>>? iceServers,
    Duration heartbeatInterval = const Duration(seconds: 15),
  }) async {
    final config = OmniCastConfig(
      hostUrl: hostUrl,
      apiUrl: apiUrl,
      apiKey: apiKey,
      apiSecret: apiSecret,
      jwtSecret: jwtSecret,
      iceServers: iceServers ??
          const [
            {'urls': 'stun:stun.l.google.com:19302'},
            {'urls': 'stun:stun1.l.google.com:19302'},
          ],
      heartbeatInterval: heartbeatInterval,
    );

    final client = OmniCastClient._(
      config: config,
      mediaConfig: mediaConfig ?? const GlobalMediaConfig(),
    );
    instance = client;
    if (autoConnect) {
      try {
        await client._signalingClient.connect(wsUrl: hostUrl, token: token);
      } catch (e) {
        debugPrint('[OmniCastClient] Initial connection deferred or offline: $e');
      }
    }
    return client;
  }

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
      if (_roomState.isInRoom && _signalingClient.isConnected) {
        debugPrint('[OmniCastClient] Requesting seamless ICE Restart from SFU...');
        try {
          final restartOffer = await _webRTCManager.createIceRestartOffer();
          _signalingClient.send(SignalingMessage(
            event: 'ice_restart_offer',
            roomId: _roomState.roomId!,
            userId: _roomState.userId!,
            payload: {
              'sdp': restartOffer.sdp,
              'type': restartOffer.type,
              'ice_restart': true,
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
      }
    };

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
      await sub.cancel();
    }
    _subscriptions.clear();

    await _interactionManager.dispose();
    await _dataChannelManager.dispose();
    await _pkManager.dispose();
    _mediaController.dispose();
    await _roomManager.leaveRoom();
    _roomManager.dispose();
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
