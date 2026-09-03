# 🚀 OmniCast SDK: Complete Developer & Media Rendering Guide

A complete, end-to-end integration manual showing how to render **Video & Audio**, perform **Media Controls (Mute / Camera Toggle / Camera Flip)**, send **Virtual Gifts**, track **PK Countdown Timers**, and manage **Audio Stages**—**without ever having to import or interact with `flutter_webrtc` directly!**

---

## 📑 Table of Contents
1. [Core Philosophy: Zero Direct WebRTC Knowledge Required](#1-core-philosophy-zero-direct-webrtc-knowledge-required)
2. [Video & Audio Rendering Widgets](#2-video--audio-rendering-widgets)
   - [A. All-In-One Adaptive Video Canvas (`OmniCastVideoCanvas`)](#a-all-in-one-adaptive-video-canvas-omnicastvideocanvas)
   - [B. Individual Video Tile (`OmniCastVideoView`)](#b-individual-video-tile-omnicastvideoview)
   - [C. Speaking Video Tile with Audio Wave (`OmniCastSpeakingVideoTile`)](#c-speaking-video-tile-with-audio-wave)
   - [D. Audio-Only Live Stage (`OmniCastAudioStageWidget`)](#d-audio-only-live-stage)
3. [Media Controls (Mute, Camera Off, Switch Camera)](#3-media-controls)
4. [Virtual Gifting System](#4-virtual-gifting-system)
5. [PK Battle Timer & Red vs Blue Score Engine](#5-pk-battle-timer--red-vs-blue-score-engine)
6. [Complete Sample Live Screen Implementation](#6-complete-sample-live-screen-implementation)

---

## 1. Core Philosophy: Zero Direct WebRTC Knowledge Required

The **OmniCast SDK** abstracts away 100% of WebRTC complexities:
- ❌ No managing `RTCPeerConnection` or `MediaStream`.
- ❌ No dealing with SDP Offer/Answer negotiation or ICE candidates.
- ❌ No manual `RTCVideoRenderer.initialize()` or `.dispose()`.
- ❌ No manual canvas coordinate math for grids or split-screens.

---

## 2. Video & Audio Rendering Widgets

### A. All-In-One Adaptive Video Canvas (`OmniCastVideoCanvas`)

The ultimate pre-built canvas. It automatically handles layout transitions:
- **Solo Mode:** Fullscreen host video (with mirror for local front camera).
- **Co-Host Mode:** Multi-seat grid (2, 4, 6, or 9 co-hosts) with camera-off avatar placeholders and mic mute badges.
- **PK Battle Mode:** TikTok-style 50/50 split-screen with animated Red vs Blue score progress bar and countdown timer.

```dart
OmniCastVideoCanvas(
  client: client,
  hostName: 'Alice Streamer',
  hostAvatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=alice',
  mirrorLocal: true,    // Mirror host's front camera preview
  mirrorRemote: false,  // Remote videos are NEVER mirrored!
)
```

---

### B. Individual Video Tile (`OmniCastVideoView`)

If you want to build custom video grids, use `OmniCastVideoView`. It manages rendering safely without any renderer initialization code:

```dart
// Render Host or any specific participant
OmniCastVideoView(
  client: client,
  userId: 'user_123', // Pass null or host ID for local preview
  mirror: false,
  fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  placeholder: Center(
    child: CircleAvatar(
      radius: 40,
      backgroundImage: NetworkImage('https://...'),
    ),
  ),
)
```

---

### C. Speaking Video Tile with Audio Wave (`OmniCastSpeakingVideoTile`)

Automatically pulsates with a green animated border when the user speaks:

```dart
OmniCastSpeakingVideoTile(
  client: client,
  userId: participant.userId,
  displayName: participant.displayName,
  avatarUrl: participant.avatarUrl,
  isMuted: client.state.isUserAudioMuted(participant.userId),
  isCameraOff: client.state.isUserCameraOff(participant.userId),
)
```

---

### D. Audio-Only Live Stage (`OmniCastAudioStageWidget`)

For Clubhouse / Twitter Spaces / Voice Chat rooms:

```dart
OmniCastAudioStageWidget(
  client: client,
  maxSeats: 8,
  onSeatTap: (seatIndex, occupiedUserId) {
    if (occupiedUserId == null) {
      // Empty seat -> request to take seat
      client.seats.requestSeat(seatIndex: seatIndex);
    } else if (client.state.isHost) {
      // Occupied seat -> show moderation options
      client.seats.muteCoHost(occupiedUserId);
    }
  },
)
```

---

## 3. Media Controls

Control local hardware tracks and listen to state changes via `client.media`:

### A. Microphone Controls
```dart
// 1. Toggle or set microphone
client.media.setMicrophoneMuted(true);  // Mute mic
client.media.setMicrophoneMuted(false); // Unmute mic
client.media.toggleMicrophone();        // Invert state

// 2. Reactive Mute State Builder
ValueListenableBuilder<bool>(
  valueListenable: client.media.isMicrophoneMutedNotifier,
  builder: (context, isMuted, _) {
    return IconButton(
      icon: Icon(isMuted ? Icons.mic_off : Icons.mic, color: isMuted ? Colors.red : Colors.white),
      onPressed: () => client.media.toggleMicrophone(),
    );
  },
);
```

### B. Camera Controls
```dart
// 1. Toggle or set camera
client.media.setCameraEnabled(false); // Turn off camera (Shows avatar placeholder)
client.media.setCameraEnabled(true);  // Turn on camera
client.media.toggleCamera();          // Invert state

// 2. Flip between Front and Back cameras
await client.media.switchCamera();

// 3. Reactive Camera State Builder
ValueListenableBuilder<bool>(
  valueListenable: client.media.isCameraEnabledNotifier,
  builder: (context, isEnabled, _) {
    return IconButton(
      icon: Icon(isEnabled ? Icons.videocam : Icons.videocam_off, color: isEnabled ? Colors.white : Colors.red),
      onPressed: () => client.media.toggleCamera(),
    );
  },
);
```

---

## 4. Virtual Gifting System

### A. Pre-Built Gifting Bottom Sheet
Open the bottom sheet with preset gifts and PK target selector:

```dart
// Opens bottom sheet with 1 line of code
OmniCastGiftingBottomSheet.show(context, client: client);
```

### B. Custom Gift Sending
```dart
client.interaction.sendGift(
  giftId: 'dragon_500',
  giftName: 'Golden Dragon',
  coinValue: 500,
  amount: 1,
  targetUserId: hostUserId, // In PK: Host A or Host B ID
);
```

### C. Listening for Incoming Gifts & Triggering Animations
```dart
client.interaction.onGiftReceived.listen((giftMsg) {
  // Show flying banner, Lottie animation, or SVGA animation
  debugPrint('Gift received: ${giftMsg.giftName} from ${giftMsg.senderName}');
});
```

---

## 5. PK Battle Timer & Red vs Blue Score Engine

### A. Setting Battle Duration & Starting PK
```dart
client.pk.sendPKRequest(
  targetRoomId: 'room_202',
  targetHostId: 'host_bob',
  durationSeconds: 300, // 5 minutes battle timer
);
```

### B. Reactive Countdown Timer Display
```dart
ValueListenableBuilder<int>(
  valueListenable: client.pk.timerNotifier,
  builder: (context, secondsRemaining, _) {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return Text(
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
    );
  },
);
```

### C. Red vs Blue Score Progress Bar
```dart
ValueListenableBuilder<PkScore>(
  valueListenable: client.state.pkScoreNotifier,
  builder: (context, score, _) {
    return Row(
      children: [
        Text('${score.hostScore}', style: const TextStyle(color: Colors.blueAccent)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Flexible(
                  flex: (score.hostRatio * 100).toInt(),
                  child: Container(height: 10, color: Colors.blueAccent),
                ),
                Flexible(
                  flex: (score.opponentRatio * 100).toInt(),
                  child: Container(height: 10, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${score.opponentScore}', style: const TextStyle(color: Colors.redAccent)),
      ],
    );
  },
);
```

---

## 6. Complete Sample Live Screen Implementation

```dart
import 'package:flutter/material.dart';
import 'package:omnicast_client/omnicast_client.dart';

class MyLiveRoomScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final String token;
  final bool isHost;

  const MyLiveRoomScreen({
    super.key,
    required this.roomId,
    required this.userId,
    required this.token,
    required this.isHost,
  });

  @override
  State<MyLiveRoomScreen> createState() => _MyLiveRoomScreenState();
}

class _MyLiveRoomScreenState extends State<MyLiveRoomScreen> {
  late final OmniCastClient _client;

  @override
  void initState() {
    super.initState();
    _client = OmniCastClient.instance ?? OmniCastClient();

    // 1. Initialize & Connect
    _client.connectWithToken(
      wsUrl: 'wss://your-sfu.com/ws',
      token: widget.token,
    );
  }

  @override
  void dispose() {
    _client.leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. All-In-One Adaptive Video Layer (Solo / Co-Host / PK)
          Positioned.fill(
            child: OmniCastVideoCanvas(
              client: _client,
              hostName: 'Live Broadcaster',
            ),
          ),

          // 2. Top Bar (Viewers list & Leave Button)
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Live Viewers counter
                ValueListenableBuilder<int>(
                  valueListenable: _client.room.totalViewerCount,
                  builder: (ctx, count, _) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('👥 $count', style: const TextStyle(color: Colors.white)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // 3. Bottom Controls (Mic, Camera, Gift)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                if (widget.isHost) ...[
                  // Mic Toggle
                  IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: () => _client.media.toggleMicrophone(),
                  ),
                  // Camera Flip
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: () => _client.media.switchCamera(),
                  ),
                ],
                const Spacer(),
                // Virtual Gift Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.card_giftcard, color: Colors.amber),
                  label: const Text('Gift'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                  onPressed: () => OmniCastGiftingBottomSheet.show(context, client: _client),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```
