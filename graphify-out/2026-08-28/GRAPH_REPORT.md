# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 493 nodes · 578 edges · 20 communities (17 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- signaling_client.dart
- room_state.dart
- signaling_message.dart
- media_stream_manager.dart
- core/omnicast_client.dart
- seat_models.dart
- webrtc_manager.dart
- omnicast_config.dart
- pk_models.dart
- interaction_models.dart
- media_controller.dart
- room_models.dart
- lib/omnicast_client.dart
- pk_manager.dart
- interaction_manager.dart
- room_manager.dart
- seat_manager.dart
- RoomState
- ../models/room_event_models.dart
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 7 edges
2. `RoomState` - 7 edges
3. `ClientConnectionState` - 3 edges
4. `MediaStreamManager` - 3 edges
5. `OmniCastVideoView` - 3 edges
6. `_OmniCastVideoViewState` - 3 edges
7. `MediaController` - 2 edges
8. `Participant` - 2 edges
9. `UserRole` - 2 edges
10. `PKManager` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (20 total, 3 thin omitted)

### Community 0 - "signaling_client.dart"
Cohesion: 0.04
Nodes (50): _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState, disconnect (+42 more)

### Community 1 - "room_state.dart"
Cohesion: 0.04
Nodes (49): ClientConnectionState get, int get, _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite (+41 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (48): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+40 more)

### Community 3 - "media_stream_manager.dart"
Cohesion: 0.04
Nodes (46): Color, attachRemoteStream, dispose, getOrCreateRemoteRenderer, getRenderer, hasLocalStream, initLocalRenderer, _isAudioMuted (+38 more)

### Community 4 - "core/omnicast_client.dart"
Cohesion: 0.05
Nodes (40): ../interaction/interaction_manager.dart, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers, interaction (+32 more)

### Community 5 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.07
Nodes (26): addLocalMediaTracks, addRemoteCandidate, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer, hasPeerConnection (+18 more)

### Community 7 - "omnicast_config.dart"
Cohesion: 0.09
Nodes (20): dart:convert, Duration, apiKey, apiSecret, generateAuthToken, heartbeatInterval, hostUrl, iceServers (+12 more)

### Community 8 - "pk_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, int?, battleId, deltaPoints, durationSeconds, fromJson, hostRoomId, hostScore (+16 more)

### Community 9 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent, giftIconUrl (+16 more)

### Community 10 - "media_controller.dart"
Cohesion: 0.09
Nodes (21): _adaptiveStreamingEnabled, _currentSimulcastLayer, _dynacastEnabled, enableAdaptiveStreaming, enableDynacast, isCameraEnabled, isMicrophoneMuted, MediaController (+13 more)

### Community 11 - "room_models.dart"
Cohesion: 0.09
Nodes (21): avatarUrl, ClientConnectionState, displayName, enableAudio, enableDynacast, enableSimulcast, enableVideo, fromJson (+13 more)

### Community 12 - "lib/omnicast_client.dart"
Cohesion: 0.11
Nodes (17): src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/models/interaction_models.dart, src/models/pk_models.dart, src/models/room_models.dart (+9 more)

### Community 13 - "pk_manager.dart"
Cohesion: 0.12
Nodes (16): acceptPKRequest, _bindStreams, dispose, endPK, onPKScoreUpdated, onPKTimerTick, PKManager, _pkScoreController (+8 more)

### Community 14 - "interaction_manager.dart"
Cohesion: 0.13
Nodes (14): _balanceUpdatedController, _bindStreams, dispose, _giftReceivedController, InteractionManager, onBalanceUpdated, onGiftReceived, _roomState (+6 more)

### Community 15 - "room_manager.dart"
Cohesion: 0.15
Nodes (12): createRoom, joinRoom, kickUser, leaveRoom, RoomManager, _roomState, _signalingClient, _webRTCManager (+4 more)

### Community 16 - "seat_manager.dart"
Cohesion: 0.15
Nodes (12): dart:async, acceptCoHostInvite, demoteToViewer, inviteToCoHost, pinToMainStage, _roomState, SeatManager, _signalingClient (+4 more)

## Knowledge Gaps
- **364 isolated node(s):** `_answerController`, `_channel`, `_channelSubscription`, `_chatController`, `_cleanupActiveConnection` (+359 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `core/omnicast_client.dart`, `pk_manager.dart`, `interaction_manager.dart`, `room_manager.dart`, `seat_manager.dart`?**
  _High betweenness centrality (0.040) - this node is a cross-community bridge._
- **Why does `SignalingClient` connect `room_manager.dart` to `signaling_client.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `pk_manager.dart`, `interaction_manager.dart`, `seat_manager.dart`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `ClientConnectionState` connect `room_models.dart` to `signaling_client.dart`, `room_state.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `_answerController`, `_channel`, `_channelSubscription` to the rest of the system?**
  _364 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._