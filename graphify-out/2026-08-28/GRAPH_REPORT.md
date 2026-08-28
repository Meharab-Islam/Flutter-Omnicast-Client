# Graph Report - omnicast_client  (2026-08-28)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 670 nodes · 794 edges · 28 communities (20 shown, 8 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3c7f3811`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- interaction_models.dart
- gift_overlay_manager.dart
- omnicast_video_view.dart
- core/omnicast_client.dart
- pk_models.dart
- media_controller.dart
- webrtc_manager.dart
- pk_manager.dart
- seat_models.dart
- media_stream_manager.dart
- interaction_manager.dart
- room_manager.dart
- lib/omnicast_client.dart
- dart:async
- pk_score_progress_bar.dart
- video_parameters.dart
- seat_manager.dart
- RoomState
- Color
- InteractionManager
- ../models/room_event_models.dart
- PKManager
- RoomManager
- SignalingClient
- src/models/room_event_models.dart

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 7 edges
2. `MediaController` - 4 edges
3. `PKState` - 3 edges
4. `RoomState` - 3 edges
5. `GiftOverlayManager` - 3 edges
6. `_GiftOverlayManagerState` - 3 edges
7. `OmniCastVideoView` - 3 edges
8. `_OmniCastVideoViewState` - 3 edges
9. `PKManager` - 2 edges
10. `MediaStreamManager` - 2 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (28 total, 8 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (49): ClientConnectionState get, _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addSeatRequest (+41 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (49): _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState, disconnect (+41 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (48): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+40 more)

### Community 3 - "interaction_models.dart"
Cohesion: 0.04
Nodes (46): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+38 more)

### Community 4 - "gift_overlay_manager.dart"
Cohesion: 0.05
Nodes (43): Alignment, Duration, GiftEvent, apiKey, apiSecret, generateAuthToken, heartbeatInterval, hostUrl (+35 more)

### Community 5 - "omnicast_video_view.dart"
Cohesion: 0.05
Nodes (42): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+34 more)

### Community 6 - "core/omnicast_client.dart"
Cohesion: 0.05
Nodes (40): ../interaction/interaction_manager.dart, InteractionManager get, _bindInternalEventListeners, config, dispose, init, _initSubManagers, interaction (+32 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (37): double get, Duration get, int get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo (+29 more)

### Community 8 - "media_controller.dart"
Cohesion: 0.06
Nodes (33): _adaptiveStreamingEnabled, _autoPauseOnBackground, _bindDynacastSignaling, currentParameters, currentSimulcastLayer, didChangeAppLifecycleState, dispose, _dynacastEnabled (+25 more)

### Community 9 - "webrtc_manager.dart"
Cohesion: 0.06
Nodes (33): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, dispose, handleRemoteAnswer, handleRemoteOfferAndCreateAnswer (+25 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (31): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+23 more)

### Community 11 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 12 - "media_stream_manager.dart"
Cohesion: 0.07
Nodes (26): attachRemoteStream, _currentParameters, dispose, getOrCreateRemoteRenderer, getRenderer, hasLocalStream, initLocalRenderer, _isAudioMuted (+18 more)

### Community 13 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (23): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+15 more)

### Community 14 - "room_manager.dart"
Cohesion: 0.09
Nodes (21): ClientConnectionState, activeSeatsNotifier, _bindStateNotifiers, connectionStateNotifier, createRoom, dispose, joinRoom, kickUser (+13 more)

### Community 15 - "lib/omnicast_client.dart"
Cohesion: 0.09
Nodes (21): src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/interaction/interaction_manager.dart, src/media/media_controller.dart, src/media/media_stream_manager.dart, src/media/video_parameters.dart, src/models/interaction_models.dart, src/models/pk_models.dart (+13 more)

### Community 16 - "dart:async"
Cohesion: 0.14
Nodes (13): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+5 more)

### Community 17 - "pk_score_progress_bar.dart"
Cohesion: 0.11
Nodes (18): Gradient?, PKState, _GiftBannerWidget, OmniCastPKBattleView, borderRadius, build, _formatTimer, height (+10 more)

### Community 18 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 19 - "seat_manager.dart"
Cohesion: 0.12
Nodes (16): acceptCoHostInvite, demoteToViewer, inviteToCoHost, pinToMainStage, _roomState, SeatManager, _signalingClient, upgradeToCoHost (+8 more)

## Knowledge Gaps
- **496 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+491 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SignalingClient` connect `seat_manager.dart` to `signaling_client.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `pk_manager.dart`, `interaction_manager.dart`, `room_manager.dart`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `PKState` connect `pk_score_progress_bar.dart` to `omnicast_video_view.dart`, `pk_models.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `VideoParameters` connect `video_parameters.dart` to `media_stream_manager.dart`?**
  _High betweenness centrality (0.017) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _496 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04081632653061224 - nodes in this community are weakly interconnected._