# 🚀 OmniCast Flutter SDK — Plug-and-Play Quickstart Guide

The **OmniCast Client SDK** is an enterprise WebRTC SFU client library designed for ultra-low latency interactive live streaming, multi-guest co-host stages, real-time PK battles, dynamic gifting, and chat in Flutter.

---

## ⚡ 3-Line Ultra Quickstart (Turnkey Live Room)

Build and launch a complete live stream screen with the all-in-one `OmniCastLiveRoom` widget:

```dart
import 'package:flutter/material.dart';
import 'package:omnicast_client/omnicast_client.dart';

class LiveScreen extends StatefulWidget {
  final String roomId;
  final String userId;
  final bool isHost;

  const LiveScreen({super.key, required this.roomId, required this.userId, required this.isHost});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  OmniCastClient? _client;

  @override
  void initState() {
    super.initState();
    _initOmniCast();
  }

  Future<void> _initOmniCast() async {
    // 1. Initialize Client SDK
    final client = await OmniCastClient.init(
      serverUrl: 'omnilive.yourdomain.com',
      apiKey: 'your_api_key',
      apiSecret: 'your_api_secret',
    );

    // 2. Start or Join Live
    if (widget.isHost) {
      await client.createRoom(roomId: widget.roomId, userId: widget.userId);
    } else {
      await client.joinRoom(roomId: widget.roomId, userId: widget.userId);
    }

    setState(() => _client = client);
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    // 3. Drop in the Turnkey Plug-and-Play Live Room Widget
    return OmniCastLiveRoom(
      client: _client!,
      hostDisplayName: 'Alex Streamer',
      onClosePressed: () {
        _client?.room.leaveRoom();
        Navigator.pop(context);
      },
    );
  }
}
```

---

## 🧩 Building a Custom Live Layout

If you prefer to assemble your own custom layout, you can use any of OmniCast's atomic widgets:

### 1. Video Stage (`OmniCastDynamicStage` or `OmniCastVideoView`)

```dart
// Atomic single video view (Host or any Co-Host)
OmniCastVideoView(
  mediaStreamManager: client.mediaStreamManager,
  userId: 'host', // or specific co-host userId
  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
)

// Dynamic multi-person stage (automatically switches 1-person solo & 2x2 multi-guest grid)
OmniCastDynamicStage(
  client: client,
)
```

### 2. Real-Time Chat & Join/Leave Overlay (`OmniCastLiveChat`)

```dart
OmniCastLiveChat(
  client: client,
  maxHeight: 220,
  showJoinLeaveEvents: true,
  showGiftEvents: true,
)
```

### 3. Header Bar with Viewers Counter (`OmniCastLiveHeader`)

```dart
OmniCastLiveHeader(
  client: client,
  hostDisplayName: 'Alex Rivera',
  onClosePressed: () => Navigator.pop(context),
)
```

### 4. Interactive Bottom Action Bar (`OmniCastLiveBottomBar`)

```dart
OmniCastLiveBottomBar(
  client: client,
  onLikePressed: () => client.interaction.sendLike(),
)
```

---

## 🥊 Real-Time PK Battle Mode

Launch or accept a 1v1 PK battle split-screen with animated score bars and countdown timer:

```dart
OmniCastPKBattleView(
  client: client,
  stageHeight: 380,
  onBattleFinished: () => print('PK Ended!'),
)
```

---

## 🎙️ Co-Host & Multi-Guest Stage Management

```dart
// Viewer requests to take a seat on stage
client.seats.requestSeat(seatIndex: 1);

// Host accepts a viewer's request
client.seats.acceptSeatRequest(viewerUserId, seatIndex: 1);

// Host invites a viewer to take a seat
client.seats.inviteToCoHost(targetUserId);

// Co-Host leaves the stage
client.seats.leaveSeat();
```

---

## 📊 Reactive State & Event Streams

| Stream / Notifier | Description |
| :--- | :--- |
| `client.room.totalViewerCount` | Real-time viewer count `ValueNotifier<int>` |
| `client.room.onParticipantJoined` | Stream emitting when a user enters the live room |
| `client.room.onParticipantLeft` | Stream emitting when a user exits the live room |
| `client.interaction.onChat` | Stream of incoming chat messages |
| `client.interaction.onGift` | Stream of incoming animated gifts |
| `client.seats.onSeatUpdated` | Stream emitting when stage seats change |
| `client.media.isAudioMuted` | Local microphone mute status |
| `client.media.isVideoMuted` | Local camera toggle status |

---

## 🛡️ Built-in Zero-Config Features

1. **Auto Permission Requesting**: Camera and mic permissions are handled automatically on connect.
2. **Auto Network Recovery & ICE Restart**: If network drops (WiFi to LTE handoff), OmniCast automatically reconnects within 1-2 seconds with zero stream interruptions.
3. **Auto User ID & Stream Resolution**: Handles numeric IDs (`3319`), prefixed IDs (`user_3319`), and full names (`3319_Alex`) automatically without manual string manipulation.
4. **Dynacast Adaptive Bitrate**: Automatically selects VP8/H264 hardware codecs and dynamically scales bitrates between 600 kbps and 1200 kbps to prevent buffering.
