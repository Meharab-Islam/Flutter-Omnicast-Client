# Graph Report - omnicast_client  (2026-08-29)

## Corpus Check
- 49 files · ~24,859 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 957 nodes · 1194 edges · 34 communities (31 shown, 3 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ba858401`
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
- package:flutter/material.dart
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
- omnicast_video_canvas.dart
- 🚀 OmniCast Client Flutter SDK
- room_event_models.dart
- StatelessWidget
- omnicast_token_generator.dart
- RoomState
- CHANGELOG.md
- Participant

## God Nodes (most connected - your core abstractions)
1. `🚀 OmniCast Client Flutter SDK` - 16 edges
2. `RoomState` - 9 edges
3. `WebRTCManager` - 8 edges
4. `SignalingClient` - 7 edges
5. `MediaController` - 6 edges
6. `MediaStreamManager` - 6 edges
7. `OmniCastConfig` - 4 edges
8. `PKState` - 4 edges
9. `ClientConnectionState` - 4 edges
10. `_OmniCastFlyingHeartsOverlayState` - 4 edges

## Surprising Connections (you probably didn't know these)
- `OmniCastGiftingBottomSheet` --inherits--> `StatefulWidget`  [EXTRACTED]
  lib/src/widgets/omnicast_gifting_bottom_sheet.dart → None  _Bridges community 9 → community 26_

## Import Cycles
- None detected.

## Communities (34 total, 3 thin omitted)

### Community 0 - "room_state.dart"
Cohesion: 0.03
Nodes (58): _activePK, _activeRemoteUserIds, _activeSeats, addActiveRemoteUser, addChatMessage, addInvite, addParticipant, addSeatRequest (+50 more)

### Community 1 - "signaling_client.dart"
Cohesion: 0.04
Nodes (52): ClientConnectionState get, _answerController, _channel, _channelSubscription, _chatController, _cleanupActiveConnection, connect, _connectionState (+44 more)

### Community 2 - "signaling_message.dart"
Cohesion: 0.04
Nodes (50): answer, balanceUpdate, candidate, chat, createRoom, event, fromJson, giftProcessed (+42 more)

### Community 3 - "core/omnicast_client.dart"
Cohesion: 0.05
Nodes (43): DataChannelManager get, ../interaction/interaction_manager.dart, InteractionManager get, _bindInternalEventListeners, config, dataChannel, _dataChannelManager, dispose (+35 more)

### Community 4 - "media_controller.dart"
Cohesion: 0.04
Nodes (44): audio_level_detector.dart, AudioLevelDetector get, global_media_config.dart, GlobalMediaConfig get, activeSpeakerNotifier, _adaptiveStreamingEnabled, audioDetector, _audioLevelDetector (+36 more)

### Community 5 - "room_manager.dart"
Cohesion: 0.06
Nodes (34): ../core/omnicast_config.dart, activeSeatsNotifier, activeViewersList, _batchDebounceTimer, _bindSignalingEvents, _bindStateNotifiers, _config, connectionStateNotifier (+26 more)

### Community 6 - "webrtc_manager.dart"
Cohesion: 0.05
Nodes (37): addLocalMediaTracks, addRemoteCandidate, _audioSender, closePeerConnection, createAndSetLocalOffer, createIceRestartOffer, dispose, enableOpusDtx (+29 more)

### Community 7 - "pk_models.dart"
Cohesion: 0.05
Nodes (36): double get, Duration get, battleId, copyWith, deltaPoints, durationSeconds, fromBattleInfo, fromJson (+28 more)

### Community 8 - "media_stream_manager.dart"
Cohesion: 0.06
Nodes (33): autoPauseOnBackground, defaultResolution, enableAdaptiveStreaming, enableDynacast, enableSimulcast, GlobalMediaConfig, attachRemoteStream, _currentParameters (+25 more)

### Community 9 - "omnicast_flying_hearts_overlay.dart"
Cohesion: 0.06
Nodes (33): AnimationController, dart:math, ../datachannel/data_channel_manager.dart, Key, GiftOverlayManager, _GiftOverlayManagerState, build, controller (+25 more)

### Community 10 - "pk_manager.dart"
Cohesion: 0.04
Nodes (44): Gradient?, PKState, acceptPKRequest, _bindStateNotifiers, _bindStreams, currentState, dispose, endPK (+36 more)

### Community 11 - "seat_manager.dart"
Cohesion: 0.06
Nodes (31): acceptCoHostInvite, acceptSeatRequest, activeCoHostsList, activeSeatsNotifier, _bindSignalingListeners, _bindStateNotifiers, demoteToViewer, dispose (+23 more)

### Community 12 - "package:flutter/material.dart"
Cohesion: 0.09
Nodes (20): dart:async, dart:convert, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:flutter/widgets.dart, package:omnicast_client/omnicast_client.dart, main, main (+12 more)

### Community 13 - "lib/omnicast_client.dart"
Cohesion: 0.06
Nodes (31): src/auth/omnicast_token_generator.dart, src/core/omnicast_client.dart, src/core/omnicast_config.dart, src/datachannel/data_channel_manager.dart, src/interaction/interaction_manager.dart, src/media/audio_level_detector.dart, src/media/global_media_config.dart, src/media/media_controller.dart (+23 more)

### Community 14 - "data_channel_manager.dart"
Cohesion: 0.07
Nodes (28): attachIncomingChannel, _bindDataChannel, _chatController, createPublisherChannel, _dataChannel, DataChannelManager, DataChannelReaction, dispose (+20 more)

### Community 15 - "room_models.dart"
Cohesion: 0.07
Nodes (28): int get, avatarUrl, ClientConnectionState, copyWith, displayName, enableAudio, enableDynacast, enableSimulcast (+20 more)

### Community 16 - "seat_models.dart"
Cohesion: 0.09
Nodes (21): bool get, CoHostInvite, createdAt, fromJson, hostId, inviteId, isLocked, isMuted (+13 more)

### Community 17 - "gift_overlay_manager.dart"
Cohesion: 0.06
Nodes (35): Alignment, MediaController, _ActiveGiftItem, _activeGifts, bannerAlignment, build, child, combo (+27 more)

### Community 18 - "interaction_models.dart"
Cohesion: 0.05
Nodes (38): ../auth/omnicast_token_generator.dart, DateTime, Duration, apiKey, apiSecret, apiUrl, generateToken, heartbeatInterval (+30 more)

### Community 19 - "interaction_manager.dart"
Cohesion: 0.08
Nodes (23): balanceStream, _balanceUpdatedController, _bindStateNotifiers, _bindStreams, _chatController, chatStream, dispose, _giftReceivedController (+15 more)

### Community 20 - "omnicast_pk_battle_view.dart"
Cohesion: 0.10
Nodes (19): Axis, MediaStreamManager, build, _buildVideoPane, hostDisplayName, hostPlaceholder, hostUserId, mediaStreamManager (+11 more)

### Community 21 - "omnicast_video_view.dart"
Cohesion: 0.10
Nodes (19): build, _checkAdaptiveStreaming, _cleanupRenderer, createState, didUpdateWidget, dispose, enableAdaptiveStreaming, _initializeLazyRenderer (+11 more)

### Community 22 - "omnicast_media_control_bar.dart"
Cohesion: 0.13
Nodes (14): Color, EdgeInsetsGeometry, IconData, activeColor, build, icon, inactiveColor, isActive (+6 more)

### Community 23 - "video_parameters.dart"
Cohesion: 0.12
Nodes (16): int?, copyWith, custom, facingMode, frameRate, height, maxBitrate, presetFHD1080p (+8 more)

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

### Community 28 - "room_event_models.dart"
Cohesion: 0.33
Nodes (5): interaction_models.dart, pk_models.dart, room_models.dart, seat_models.dart, signaling_message.dart

### Community 29 - "StatelessWidget"
Cohesion: 0.18
Nodes (11): _GiftBannerWidget, _CircleControlButton, OmniCastMediaControlBar, OmniCastNativeViewportTracker, OmniCastPKBattleView, OmniCastSpeakingVideoTile, _SpeakingWaveformIcon, AnimatedFlexible (+3 more)

### Community 30 - "omnicast_token_generator.dart"
Cohesion: 0.50
Nodes (3): generate, OmniCastTokenGenerator, package:dart_jsonwebtoken/dart_jsonwebtoken.dart

## Knowledge Gaps
- **710 isolated node(s):** `OmniCastTokenGenerator`, `generate`, `config`, `mediaConfig`, `_signalingClient` (+705 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaStreamManager` connect `omnicast_pk_battle_view.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `webrtc_manager.dart`, `media_stream_manager.dart`, `omnicast_video_view.dart`?**
  _High betweenness centrality (0.023) - this node is a cross-community bridge._
- **Why does `RoomState` connect `RoomState` to `room_state.dart`, `core/omnicast_client.dart`, `media_controller.dart`, `room_manager.dart`, `pk_manager.dart`, `seat_manager.dart`, `data_channel_manager.dart`, `interaction_manager.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `MediaController` connect `gift_overlay_manager.dart` to `core/omnicast_client.dart`, `media_controller.dart`, `omnicast_video_view.dart`, `omnicast_media_control_bar.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **What connects `OmniCastTokenGenerator`, `generate`, `config` to the rest of the system?**
  _710 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `room_state.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03389830508474576 - nodes in this community are weakly interconnected._
- **Should `signaling_client.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `signaling_message.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0392156862745098 - nodes in this community are weakly interconnected._