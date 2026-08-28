# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 633 nodes · 749 edges · 23 communities (20 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e731f910`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- interaction_models.dart
- omnicast_video_view.dart
- core/omnicast_client.dart
- gift_overlay_manager.dart
- pk_models.dart
- webrtc_manager.dart
- seat_models.dart
- media_controller.dart
- media_stream_manager.dart
- pk_manager.dart
- lib/omnicast_client.dart
- pk_score_progress_bar.dart
- dart:async
- video_parameters.dart
- interaction_manager.dart
- seat_manager.dart
- room_manager.dart
- RoomState
- ../models/room_event_models.dart
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `RoomState` - 6 edges
2. `MediaStreamManager` - 5 edges
3. `SignalingClient` - 4 edges
4. `WebRTCManager` - 3 edges
5. `PKState` - 3 edges
6. `MediaController` - 3 edges
7. `OmniCastVideoView` - 3 edges
8. `_OmniCastVideoViewState` - 3 edges
9. `GiftOverlayManager` - 3 edges
10. `_GiftOverlayManagerState` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (23 total, 3 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (50): ClientConnectionState, _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addSeatRequest (+42 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (49): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+41 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (48): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+40 more)

### Community 3 - "interaction_models.dart"
Cohesion: 0.04
Nodes (46): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+38 more)

### Community 4 - "omnicast_video_view.dart"
Cohesion: 0.05
Nodes (44): Axis, Color, MediaController, MediaStreamManager, build, _buildVideoPane, hostDisplayName, hostPlaceholder (+36 more)

### Community 5 - "core/omnicast_client.dart"
Cohesion: 0.04
Nodes (45): ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers (+37 more)

### Community 6 - "gift_overlay_manager.dart"
Cohesion: 0.05
Nodes (42): Alignment, Duration, GiftEvent, apiKey, apiSecret, generateAuthToken, heartbeatInterval, hostUrl (+34 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (37): double get, Duration get, int get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo (+29 more)

### Community 8 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (32): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer (+24 more)

### Community 9 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 10 - "media_controller.dart"
Cohesion: 0.07
Nodes (26): _adaptiveStreamingEnabled, _bindDynacastSignaling, currentParameters, _currentSimulcastLayer, dispose, _dynacastEnabled, _dynacastSubscription, enableAdaptiveStreaming (+18 more)

### Community 11 - "media_stream_manager.dart"
Cohesion: 0.07
Nodes (26): attachRemoteStream, _currentParameters, dispose, getOrCreateRemoteRenderer, getRenderer, hasLocalStream, initLocalRenderer, _isAudioMuted (+18 more)

### Community 12 - "pk_manager.dart"
Cohesion: 0.07
Nodes (26): acceptPKRequest, _bindStreams, currentState, dispose, endPK, isPKActive, onPKEnded, onPKRequested (+18 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.09
Nodes (21): src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/media/video_parameters.dart, src/models/interaction_models.dart, src/models/pk_models.dart (+13 more)

### Community 14 - "pk_score_progress_bar.dart"
Cohesion: 0.11
Nodes (18): Gradient?, PKState, _GiftBannerWidget, OmniCastPKBattleView, borderRadius, build, _formatTimer, height (+10 more)

### Community 15 - "dart:async"
Cohesion: 0.16
Nodes (11): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:omnicast_client/omnicast_client.dart, main, main, main (+3 more)

### Community 16 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 17 - "interaction_manager.dart"
Cohesion: 0.13
Nodes (14): _balanceUpdatedController, _bindStreams, dispose, _giftReceivedController, InteractionManager, onBalanceUpdated, onGiftReceived, _roomState (+6 more)

### Community 18 - "seat_manager.dart"
Cohesion: 0.15
Nodes (12): acceptCoHostInvite, demoteToViewer, inviteToCoHost, pinToMainStage, _roomState, SeatManager, _signalingClient, upgradeToCoHost (+4 more)

### Community 19 - "room_manager.dart"
Cohesion: 0.17
Nodes (11): createRoom, joinRoom, kickUser, leaveRoom, RoomManager, _roomState, _signalingClient, _webRTCManager (+3 more)

## Knowledge Gaps
- **465 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+460 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaStreamManager` connect `omnicast_video_view.dart` to `webrtc_manager.dart`, `media_controller.dart`, `media_stream_manager.dart`, `core/omnicast_client.dart`?**
  _High betweenness centrality (0.033) - this node is a cross-community bridge._
- **Why does `PKState` connect `pk_score_progress_bar.dart` to `omnicast_video_view.dart`, `pk_models.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `video_parameters.dart` to `media_stream_manager.dart`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _465 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._