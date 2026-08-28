# 🚀 OmniCast Client SDK for Flutter

[![pub package](https://img.shields.io/badge/pub-v0.0.1-blue.svg)](https://pub.dev/packages/omnicast_client)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![WebRTC](https://img.shields.io/badge/WebRTC-SFU-FF3E00?logo=webrtc)](https://webrtc.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A production-grade, enterprise Flutter client SDK built for high-scale interactive live-streaming platforms like **TikTok Live**, **Bigo Live**, and **Twitch**. Powered by the custom Go-based **OmniCast SFU Engine** (`pion/webrtc`).

---

## 🌟 Key Features

- ⚡ **Ultra-Low Latency (<200ms)**: Sub-second global WebRTC streaming powered by unified-plan SFU routing.
- 📱 **Modular Facade Architecture**: Dedicated sub-controllers for room lifecycle, media hardware, stage co-hosts, interactions, and PK battles.
- 🎛️ **Simulcast & Dynacast**: Dynamic multi-layer video resolution switching (`'f'`, `'h'`, `'q'`) and automatic viewport-based bandwidth throttling.
- 🔄 **Seamless Co-Host Upgrade**: Transition from Viewer to Co-Host with zero stream interruption via seamless in-place SDP renegotiation.
- ⚔️ **Host PK Battle System**: Out-of-the-box cross-room host battles, side-by-side video rendering, real-time score updates, and battle timers.
- 🎁 **Interactive Social Engine**: Built-in real-time chat, virtual gift animations, coin balance synchronization, and stage seat management.
- 🖼️ **Zero-Boilerplate Video Views**: Plug-and-play `OmniCastVideoView` widget that automatically manages `RTCVideoRenderer` lifecycle and track binding.

---

## 📦 Installation

Add `omnicast_client` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  omnicast_client: ^0.0.1
```

Then install dependencies:

```bash
flutter pub get
```

### Platform Permissions

#### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for live streaming video.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for live audio broadcasting.</string>
```

#### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

---

## 🔑 Initialization

Initialize the SDK instance globally or within your service locator (`GetIt`, `Provider`, `Riverpod`):

```dart
import 'package:omnicast_client/omnicast_client.dart';

final client = await OmniCastClient.init(
  apiKey: 'YOUR_OMNICAST_API_KEY',
  apiSecret: 'YOUR_OMNICAST_API_SECRET',
  hostUrl: 'wss://sfu.omnicast.live/ws',
);
```

---

## 🚀 Quick Start

### 1. Join a Live Stream as a Viewer

```dart
// Connects with recvonly audio/video transceivers and subscribes to host stream
await client.room.joinRoom(
  roomId: 'room_101',
  userId: 'viewer_user_88',
);
```

### 2. Start a Broadcast as a Host

```dart
// Captures camera & microphone, adds tracks, and publishes stream
await client.room.createRoom(
  roomId: 'room_101',
  userId: 'host_user_42',
  options: const RoomOptions(
    title: 'Late Night Music & Chat 🎸',
    enableAudio: true,
    enableVideo: true,
    enableSimulcast: true,
    maxCoHosts: 4,
  ),
);
```

---

## 🎥 Rendering Video (`OmniCastVideoView`)

Render live video feeds effortlessly. The widget automatically handles renderer initialization, stream binding, and leak-free disposal:

```dart
// Render Local Camera Preview (Host / Co-Host)
OmniCastVideoView(
  mediaStreamManager: client.streamManager,
  userId: 'local', // or null
  mirror: true,
  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
)

// Render Remote Host or Co-Host Stream
OmniCastVideoView(
  mediaStreamManager: client.streamManager,
  userId: hostUserId, // ID of the host or peer
  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
  placeholder: const Center(
    child: CircularProgressIndicator(),
  ),
)
```

---

## 🎛️ Advanced Modular Architecture

`OmniCastClient` organizes all live streaming features into specialized sub-modules:

### 1. Media Controls (`client.media`)

Fine-tune local hardware capture, simulcast layers, and adaptive streaming:

```dart
// Hardware Mute Toggles
client.media.setMicrophoneMuted(true);
client.media.setCameraEnabled(false);
await client.media.switchCamera();

// Simulcast Layer Selection: 'f' (full/1080p), 'h' (half/720p), 'q' (quarter/360p)
client.media.setSimulcastLayer('h');

// Dynacast & Adaptive Bandwidth Optimization
client.media.enableDynacast(true);
client.media.enableAdaptiveStreaming(true);

// Dynamically pause/resume offscreen remote video tracks to save bandwidth
client.media.setRemoteTrackVisibility(remotePeerId, false);
```

---

### 2. Stage & Co-Hosting (`client.seats`)

Seamlessly invite viewers onto the stage without breaking the WebRTC connection:

```dart
// Host: Invite viewer to stage
client.seats.inviteToCoHost('viewer_user_88', seatIndex: 1);

// Viewer: Accept invite & seamlessly upgrade to Co-Host
await client.seats.acceptCoHostInvite(video: true, audio: true);

// Host: Demote co-host back to viewer (keeps them in room)
client.seats.demoteToViewer('cohost_user_88');

// Host: Pin a specific co-host to the main spotlight stage
client.seats.pinToMainStage('cohost_user_88');
```

---

### 3. Interactions & Virtual Gifts (`client.interaction`)

Power your live chat and monetization loop:

```dart
// Send a live chat message
client.interaction.sendChat('Hello everyone! Welcome to the stream 🎉');

// Send virtual gifts
client.interaction.sendGift(
  giftId: 'super_rocket_99',
  amount: 5,
  giftName: 'Super Rocket 🚀',
  coinValue: 100,
);

// Listen to incoming gifts
client.interaction.onGiftReceived.listen((giftEvent) {
  print('🎁 Gift received from ${giftEvent.senderName}: ${giftEvent.giftName} x${giftEvent.amount}');
});

// Listen to user coin balance updates
client.interaction.onBalanceUpdated.listen((balanceUpdate) {
  print('💰 New Coin Balance: ${balanceUpdate.newBalance}');
});
```

---

### 4. PK Host Battles (`client.pk`)

Challenge another live room host to a real-time split-screen battle:

```dart
// Host: Challenge an opponent host in another room
client.pk.sendPKRequest(
  targetRoomId: 'opponent_room_505',
  targetHostId: 'opponent_host_99',
  durationSeconds: 300, // 5 minute battle
);

// Opponent: Accept PK challenge
client.pk.acceptPKRequest('pk_battle_id');

// Listen to real-time score updates
client.pk.onPKScoreUpdated.listen((scoreUpdate) {
  print('⚔️ Host: ${scoreUpdate.hostScore} vs Opponent: ${scoreUpdate.opponentScore}');
});

// Listen to battle timer countdown ticks
client.pk.onPKTimerTick.listen((timerTick) {
  print('⏳ Remaining Time: ${timerTick.remainingSeconds}s (Punishment: ${timerTick.isPunishmentPhase})');
});

// End PK battle
client.pk.endPK('pk_battle_id');
```

---

## 📊 Reactive State Management (`client.state`)

`client.state` is a reactive `ChangeNotifier` (`RoomState`) that provides instant UI updates without manual stream boilerplate:

```dart
ListenableBuilder(
  listenable: client.state,
  builder: (context, _) {
    final state = client.state;

    return Column(
      children: [
        // Live Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Room: ${state.roomId ?? "Offline"}'),
            Text('👁️ ${state.viewersCount} Viewers'),
            Text('🪙 ${state.hostCoinBalance} Coins'),
          ],
        ),

        // PK Battle Banner (Visible during active PK)
        if (state.isInPKBattle)
          Container(
            color: Colors.redAccent,
            padding: const EdgeInsets.all(8),
            child: Text(
              '⚔️ PK BATTLE: ${state.activePK!.hostScore} - ${state.activePK!.opponentScore} | ${state.activePK!.remainingSeconds}s remaining',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),

        // Chat List
        Expanded(
          child: ListView.builder(
            itemCount: state.chatHistory.length,
            itemBuilder: (context, index) {
              final chat = state.chatHistory[index];
              return ListTile(
                title: Text(chat.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(chat.text),
              );
            },
          ),
        ),
      ],
    );
  },
)
```

---

## 🧹 Resource Cleanup

Always call `dispose()` when terminating the live streaming session:

```dart
@override
void dispose() {
  client.dispose();
  super.dispose();
}
```

---

## 📄 License

This SDK is distributed under the MIT License. See [LICENSE](LICENSE) for details.
