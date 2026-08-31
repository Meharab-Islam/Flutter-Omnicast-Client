# Graph Report - omnicast_client  (2026-08-30)

## Corpus Check
- 54 files · ~27,938 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1046 nodes · 1305 edges · 41 communities (37 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `fc50e6c9`
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
- webrtc_stats_monitor.dart
- omnicast_speaking_video_tile.dart
- audio_level_detector.dart
- omnicast_video_canvas.dart
- 🚀 OmniCast Client Flutter SDK
- omnicast_native_viewport_tracker.dart
- StatelessWidget
- omnicast_token_generator.dart
- RoomState
- CHANGELOG.md
- package:flutter/foundation.dart
- _OmniCastFlyingHeartsOverlayState
- pk_score_progress_bar.dart
- omnicast_config.dart
- package:flutter/material.dart
- omnicast_api_test.dart
- headless_and_performance_test.dart
- handleRawMessage

## God Nodes (most connected - your core abstractions)
1. `🚀 OmniCast Client Flutter SDK` - 16 edges
2. `RoomState` - 9 edges
3. `WebRTCManager` - 8 edges
4. `SignalingClient` - 7 edges
5. `MediaController` - 6 edges
6. `MediaStreamManager` - 6 edges
7. `OmniCastConfig` - 5 edges
8. `PKState` - 4 edges
9. `ClientConnectionState` - 4 edges
10. `_OmniCastFlyingHeartsOverlayState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `OmniCastGiftingBottomSheet` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/src/widgets/omnicast_gifting_bottom_sheet.dart → None  _Bridges community 34 → community 26_

## Import Cycles
- None detected.

## Communities (41 total, 4 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.03
Nodes (58): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+50 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.03
Nodes (58): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+50 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (54): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+46 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.04
Nodes (50): ../api/omnicast_api.dart, DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager get, _api, _bindInternalEventListeners, config, dataChannel (+42 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.04
Nodes (50): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+42 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.06
Nodes (34): UserRole, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, _config, connectionStateNotifier (+26 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.05
Nodes (40): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, createIceRestartOffer, dispose, enableOpusDtx (+32 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (37): double get, Duration get, int get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo (+29 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (33): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+25 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.08
Nodes (23): AnimationController, dart:math, ../datachannel/data_channel_manager.dart, Key, build, controller, createState, dispose (+15 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.06
Nodes (30): acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK, isPKActive, isPKActiveNotifier (+22 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.06
Nodes (31): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, demoteToViewer, dispose (+23 more)

### Community 12 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.13
Nodes (12): dart:typed_data, package:flutter_test/flutter_test.dart, package:omnicast_client/omnicast_client.dart, main, main, main, main, main (+4 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.06
Nodes (33): src/api/omnicast_api.dart, src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart, src/media/global_media_config.dart (+25 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.07
Nodes (29): attachIncomingChannel, _bindDataChannel, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction, dispose (+21 more)

### Community 15 - "room_models.dart"
Cohesion: 0.05
Nodes (38): ActiveLiveRoom, avatarUrl, ClientConnectionState, copyWith, createdAt, displayName, enableAudio, enableDynacast (+30 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.04
Nodes (42): bool get, int?, interaction_models.dart, copyWith, custom, facingMode, frameRate, height (+34 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.08
Nodes (23): Alignment, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo, createState (+15 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.08
Nodes (24): DateTime, amount, BalanceUpdate, ChatMessage, coinValue, delta, fromJson, GiftEvent (+16 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (24): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+16 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.11
Nodes (17): Axis, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager, objectFit (+9 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.09
Nodes (21): MediaStreamManager, build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming (+13 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.14
Nodes (13): Color, EdgeInsetsGeometry, IconData, activeColor, build, icon, inactiveColor, isActive (+5 more)

### Community 23 - "webrtc_stats_monitor.dart"
Cohesion: 0.06
Nodes (30): bitrateKbps, currentStats, dispose, initial, interval, _isDisposed, jitterMs, _lastBytesReceived (+22 more)

### Community 24 - "omnicast_speaking_video_tile.dart"
Cohesion: 0.12
Nodes (16): AudioLevelDetector, audioDetector, avatarUrl, build, _buildAvatarPlaceholder, isCameraEnabled, isMicMuted, level (+8 more)

### Community 25 - "audio_level_detector.dart"
Cohesion: 0.13
Nodes (14): activeSpeakerNotifier, audioLevelsNotifier, dispose, _isDisposed, pollInterval, pollStats, _pollTimer, start (+6 more)

### Community 26 - "omnicast_video_canvas.dart"
Cohesion: 0.06
Nodes (33): ../core/omnicast_client.dart, OmniCastClient, PkScore, RoomMode, build, client, coinPrice, createState (+25 more)

### Community 27 - "🚀 OmniCast Client Flutter SDK"
Cohesion: 0.06
Nodes (34): 1. Add dependency to `pubspec.yaml`, 1. Challenge & Accept PK, 1. Join a Live Room as a Viewer, 1. Send Chat & Virtual Gifts, 1. Send Metadata When Joining as a Viewer, 1. Video Resolution Presets (`VideoParameters`), 2. Configure Native Permissions, 2. Gift Banner Overlay Widget (`GiftOverlayManager`) (+26 more)

### Community 28 - "omnicast_native_viewport_tracker.dart"
Cohesion: 0.14
Nodes (13): MediaController, build, child, crossAxisCount, _evaluateVisibility, itemHeight, mediaController, trackIds (+5 more)

### Community 29 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _GiftBannerWidget, _CircleControlButton, OmniCastMediaControlBar, OmniCastNativeViewportTracker, OmniCastPKBattleView, OmniCastSpeakingVideoTile, _SpeakingWaveformIcon, AnimatedFlexible (+3 more)

### Community 30 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

### Community 33 - "package:flutter/foundation.dart"
Cohesion: 0.20
Nodes (9): Client, ../core/omnicast_config.dart, _client, config, dispose, getLiveRooms, OmniCastApi, OmniCastConfig (+1 more)

### Community 34 - "_OmniCastFlyingHeartsOverlayState"
Cohesion: 0.28
Nodes (9): GiftOverlayManager, _GiftOverlayManagerState, OmniCastFlyingHeartsOverlay, _OmniCastFlyingHeartsOverlayState, OmniCastVideoView, _OmniCastVideoViewState, State, StatefulWidget (+1 more)

### Community 35 - "pk_score_progress_bar.dart"
Cohesion: 0.13
Nodes (14): Gradient?, PKState, borderRadius, build, _formatTimer, height, hostGradient, opponentGradient (+6 more)

### Community 36 - "omnicast_config.dart"
Cohesion: 0.14
Nodes (13): ../auth/omnicast_token_generator.dart, Duration, apiKey, apiSecret, apiUrl, generateToken, heartbeatInterval, hostUrl (+5 more)

### Community 37 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (7): dart:async, package:flutter/material.dart, main, main, main, main, main

### Community 38 - "omnicast_api_test.dart"
Cohesion: 0.29
Nodes (5): dart:convert, package:http/http.dart, package:http/testing.dart, main, main

## Knowledge Gaps
- **776 isolated node(s):** `config`, `_client`, `getLiveRooms`, `dispose`, `OmniCastTokenGenerator` (+771 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaController` connect `omnicast_native_viewport_tracker.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `omnicast_video_view.dart`, `omnicast_media_control_bar.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `MediaStreamManager` connect `omnicast_video_view.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `webrtc_manager.dart`, `media_stream_manager.dart`, `omnicast_pk_battle_view.dart`?**
  _High betweenness centrality (0.021) - this node is a cross-community bridge._
- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `interaction_manager.dart`?**
  _High betweenness centrality (0.020) - this node is a cross-community bridge._
- **What connects `config`, `_client`, `getLiveRooms` to the rest of the system?**
  _776 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03636363636363636 - nodes in this community are weakly interconnected._