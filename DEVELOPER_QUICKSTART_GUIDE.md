# 🚀 OmniCast SDK Developer Quickstart Guide

This guide explains how developers can integrate and build interactive live streaming applications using the **OmniCast Client SDK** for Flutter with minimal lines of code.

---

## 1. 📦 Installation

Add the SDK dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  omnicast_client:
    git:
      url: https://github.com/Meharab-Islam/Flutter-Omnicast-Client.git
      ref: main
```

Run `flutter pub get`.

---

## 2. ⚡ SDK Initialization (Single Domain & Credentials)

Initialize the SDK once at app startup or before entering live streaming screens. The SDK **automatically derives** WebSocket (`wss://.../ws`) and REST API (`https://.../api`) endpoints:

```dart
import 'package:omnicast_client/omnicast_client.dart';

final client = await OmniCastClient.init(
  serverUrl: 'testlive.lolipoplive.top', // Single server domain
  apiKey: 'YOUR_API_KEY',
  apiSecret: 'YOUR_API_SECRET',
  enableLogging: false, // Set to true if you want to inspect WebRTC/signaling logs
);
```

---

## 3. 🎥 Create a Live Room (Host)

Creating a live room automatically initializes the camera/microphone, generates JWT tokens, establishes the WebRTC SFU connection, and adds the host to the viewers list:

```dart
await client.createRoom(
  roomId: 'room_101',
  userId: 'host_user_42',
  metadata: {
    'displayName': 'John Doe (Host)',
    'avatarUrl': 'https://example.com/host_avatar.png',
    'title': 'My Epic Live Stream',
  },
  options: const RoomOptions(
    enableAudio: true,
    enableVideo: true,
    isAudioOnly: false,
    showJoinMessages: true, // Show entrance banners when viewers enter
  ),
);
```

---

## 4. 👁️ Join a Live Room (Viewer)

Joining a room as a viewer automatically subscribes to the host's video/audio stream and syncs the real-time viewers list:

```dart
await client.joinRoom(
  roomId: 'room_101',
  userId: 'viewer_user_99',
  metadata: {
    'displayName': 'Rahim Ahmed',
    'avatarUrl': 'https://example.com/viewer_avatar.png',
    'level': 5,
    'is_vip': true,
  },
);
```

---

## 5. 📺 Displaying Video Screen

Use the built-in responsive **`OmniCastVideoCanvas`** widget to automatically handle Solo broadcasts, Multi-guest grids, and TikTok-style PK Battles:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        // 1. Fullscreen Live Video Stream
        OmniCastVideoCanvas(
          client: client,
          hostName: 'John Doe',
          hostAvatarUrl: 'https://example.com/host_avatar.png',
        ),

        // 2. Room Controls & Overlays
        // ... (Chat, Gifts, Viewers Counter)
      ],
    ),
  );
}
```

---

## 6. 👥 Real-Time Viewers List & Moderation

### Option A: Built-in 1-Line Bottom Sheet Modal
Open the complete viewers bottom sheet with user avatars, VIP badges, level indicators, and host kick moderation with **1 single line of code**:

```dart
// 🌟 1-Line Viewers Bottom Sheet
OmniCastViewersBottomSheet.show(context, client: client);
```

### Option B: Custom Headless UI Reactive Listeners
If you want to build your own custom viewers counter or custom list:

```dart
// 1. Online Viewers Counter Badge:
ValueListenableBuilder<int>(
  valueListenable: client.totalViewerCount,
  builder: (context, count, _) {
    return Text('$count Viewers Online');
  },
);

// 2. Active Viewers Avatars Row:
ValueListenableBuilder<List<OmniCastParticipant>>(
  valueListenable: client.activeViewersList,
  builder: (context, viewers, _) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: viewers.length,
      itemBuilder: (context, i) {
        final viewer = viewers[i];
        return CircleAvatar(
          backgroundImage: NetworkImage(viewer.avatarUrl ?? ''),
        );
      },
    );
  },
);
```

---

## 7. 🎤 Co-Host & Multi-Guest Stage Management

### A. Viewer Requests to Become Co-Host:
```dart
// 1. Viewer sends request to join the stage:
client.requestCoHost();

// Or cancel pending request:
client.cancelCoHostRequest();

// 2. Viewer listens if host accepts or rejects:
client.onCoHostAccepted.listen((_) {
  print('🎉 Host accepted your request! Upgraded to Co-Host!');
});

client.onCoHostRejected.listen((_) {
  print('❌ Host rejected your co-host request.');
});
```

### B. Host Manages Co-Host Requests & Stage:
```dart
// 1. Host listens to incoming viewer co-host requests:
client.onCoHostRequested.listen((req) {
  print('👋 ${req.requesterName} wants to join the stage!');
  
  // Show dialog to Accept or Reject
  // To accept:
  client.acceptCoHostRequest(req.requesterId);
  
  // To reject:
  client.rejectCoHostRequest(req.requesterId);
});

// 2. Host invites a specific viewer to stage:
client.inviteToCoHost('viewer_user_99');

// 3. Host demotes a co-host back to viewer (without kicking):
client.demoteCoHost('cohost_user_99');
```

### C. Viewer Listens to Host Invitation:
```dart
client.onCoHostInviteReceived.listen((invite) async {
  // Viewer accepts host invitation
  await client.acceptCoHostInvite(inviteId: invite.inviteId);
  
  // Or reject:
  // client.rejectCoHostInvite(inviteId: invite.inviteId);
});
```

### D. Co-Host Voluntarily Leaves the Stage:
```dart
// Co-host leaves seat and returns to viewer mode:
await client.leaveCoHostSeat();
```

---

## 8. 🔔 Listening to Real-time Join/Leave Events

Listen to live user arrivals and departures to show floating banners or chat notifications:

```dart
// User Entered Room
client.onUserJoined.listen((participant) {
  print('🎉 ${participant.displayName ?? participant.userId} joined the room!');
});

// User Left Room
client.onUserLeft.listen((userId) {
  print('🏃 User $userId left the room');
});
```

---

## 9. 🛡️ Room Termination & Ejection Moderation

### Host Closes/Deletes the Room:
```dart
// Host ends the broadcast and ejects all viewers
await client.closeRoom();
```

### Viewer Listens to Room Closure:
```dart
client.onRoomClosedByHost.listen((roomId) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Host has ended the live stream.')),
  );
  Navigator.pop(context); // Exit room screen
});
```

### Host Kicks Disruptive User:
```dart
client.kickUser('bad_user_123', reason: 'Violated community guidelines');
```

### Viewer Listens If They Were Kicked:
```dart
client.onKickedFromRoom.listen((event) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You were kicked: ${event.reason}')),
  );
  Navigator.pop(context); // Exit room screen
});
```

---

## 9. ⚙️ Settings & Dynamic Toggles

### Toggle Room Entrance Notifications at Runtime:
```dart
// Turn ON/OFF join messages dynamically
client.showJoinMessages = false;
```

### Toggle SDK Debug Logs:
```dart
// Enable or disable WebRTC/Signaling console logs
OmniCastClient.enableLogging = false;
```

---

## 10. 🚪 Leaving Room
When the user leaves the screen, clean up media and signaling sessions:

```dart
@override
void dispose() {
  client.leaveRoom();
  super.dispose();
}
```
