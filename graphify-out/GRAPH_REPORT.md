# Graph Report - omnicast_client  (2026-08-29)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 895 nodes · 1092 edges · 36 communities (31 shown, 5 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1801c8d1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- room_state.dart
- signaling_client.dart
- signaling_message.dart
- core/omnicast_client.dart
- media_controller.dart
- room_manager.dart
- webrtc_manager.dart
- pk_models.dart
- media_stream_manager.dart
- omnicast_flying_hearts_overlay.dart
- pk_manager.dart
- seat_manager.dart
- package:flutter_test/flutter_test.dart
- lib/omnicast_client.dart
- data_channel_manager.dart
- room_models.dart
- seat_models.dart
- gift_overlay_manager.dart
- interaction_models.dart
- interaction_manager.dart
- omnicast_pk_battle_view.dart
- omnicast_video_view.dart
- omnicast_media_control_bar.dart
- video_parameters.dart
- omnicast_speaking_video_tile.dart
- audio_level_detector.dart
- omnicast_config.dart
- pk_score_progress_bar.dart
- omnicast_native_viewport_tracker.dart
- StatelessWidget
- omnicast_token_generator.dart
- RoomState
- ../models/room_event_models.dart
- package:crypto/crypto.dart
- src/models/room_event_models.dart
- VideoParameters

## God Nodes (most connected - your core abstractions)
1. `SignalingClient` - 4 edges
2. `MediaController` - 4 edges
3. `WebRTCManager` - 4 edges
4. `_OmniCastFlyingHeartsOverlayState` - 4 edges
5. `Participant` - 3 edges
6. `AudioLevelDetector` - 3 edges
7. `PKState` - 3 edges
8. `VideoParameters` - 3 edges
9. `GiftOverlayManager` - 3 edges
10. `_GiftOverlayManagerState` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (36 total, 5 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.04
Nodes (54): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+46 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (52): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+44 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (50): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+42 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.04
Nodes (48): DataChannelManager, DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager, InteractionManager get, _bindInternalEventListeners, config, dataChannel (+40 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.04
Nodes (46): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector (+38 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.05
Nodes (37): ClientConnectionState, ../core/omnicast_config.dart, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, _config (+29 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.05
Nodes (37): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, createIceRestartOffer, dispose, enableOpusDtx (+29 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (36): double get, Duration get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo, fromJson (+28 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (34): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+26 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.07
Nodes (32): AnimationController, dart:math, ../datachannel/data_channel_manager.dart, Key, GiftOverlayManager, _GiftOverlayManagerState, build, controller (+24 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (32): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+24 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.06
Nodes (32): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, demoteToViewer, dispose (+24 more)

### Community 12 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.09
Nodes (19): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+11 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.07
Nodes (29): src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart, src/media/global_media_config.dart, src/media/media_controller.dart (+21 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.07
Nodes (29): attachIncomingChannel, _bindDataChannel, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction, dispose (+21 more)

### Community 15 - "room_models.dart"
Cohesion: 0.07
Nodes (28): int get, avatarUrl, ClientConnectionState, copyWith, displayName, enableAudio, enableDynacast, enableSimulcast (+20 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.07
Nodes (26): bool get, interaction_models.dart, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked (+18 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.08
Nodes (24): Alignment, GiftEvent, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo (+16 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+16 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (24): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+16 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (20): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+12 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.11
Nodes (18): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+10 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.12
Nodes (16): Color, EdgeInsetsGeometry, IconData, MediaController, activeColor, build, icon, inactiveColor (+8 more)

### Community 23 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

### Community 24 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.12
Nodes (16): AudioLevelDetector, audioDetector, avatarUrl, build, _buildAvatarPlaceholder, isCameraEnabled, isMicMuted, level (+8 more)

### Community 25 - "audio_level_detector.dart"
Cohesion: 0.12
Nodes (15): activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer, start (+7 more)

### Community 26 - "omnicast_config.dart"
Cohesion: 0.13
Nodes (14): ../auth/omnicast_token_generator.dart, Duration, apiKey, apiSecret, apiUrl, generateToken, heartbeatInterval, hostUrl (+6 more)

### Community 27 - "pk_score_progress_bar.dart"
Cohesion: 0.13
Nodes (14): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+6 more)

### Community 28 - "omnicast_native_viewport_tracker.dart"
Cohesion: 0.17
Nodes (11): build, child, crossAxisCount, _evaluateVisibility, itemHeight, mediaController, trackIds, List (+3 more)

### Community 29 - "StatelessWidget"
Cohesion: 0.22
Nodes (9): _GiftBannerWidget, _CircleControlButton, OmniCastMediaControlBar, OmniCastNativeViewportTracker, OmniCastPKBattleView, OmniCastSpeakingVideoTile, _SpeakingWaveformIcon, PKScoreProgressBar (+1 more)

### Community 30 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

## Knowledge Gaps
- **662 isolated node(s):** `_activePK`, `_activeRemoteUserIds`, `_activeSeats`, `addActiveRemoteUser`, `addChatMessage` (+657 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `VideoParameters` connect `media_stream_manager.dart` to `video_parameters.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **Why does `MediaController` connect `omnicast_media_control_bar.dart` to `media_controller.dart`, `omnicast_video_view.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `PKState` connect `pk_score_progress_bar.dart` to `omnicast_pk_battle_view.dart`, `pk_models.dart`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `_activePK`, `_activeRemoteUserIds`, `_activeSeats` to the rest of the system?**
  _662 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._