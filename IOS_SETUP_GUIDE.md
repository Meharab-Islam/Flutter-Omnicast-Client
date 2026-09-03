# 🍎 iOS Setup & Permissions Configuration Guide for OmniCast SDK

This guide covers everything required to run live broadcasting and WebRTC media on **iOS** (iPhone & iPad).

---

## 1. 📝 `ios/Runner/Info.plist` Configuration

Open your iOS project's `ios/Runner/Info.plist` file and add the following keys inside `<dict> ... </dict>`:

```xml
<!-- 📷 Camera Permission for Live Video & PK Battles -->
<key>NSCameraUsageDescription</key>
<string>$(PRODUCT_NAME) requires camera access for live video broadcasting and co-host video streaming.</string>

<!-- 🎙️ Microphone Permission for Live Audio & Co-Host Voice -->
<key>NSMicrophoneUsageDescription</key>
<string>$(PRODUCT_NAME) requires microphone access for live broadcasting and interactive audio.</string>

<!-- 🌐 Local Network Access for Local WebRTC Discovery (Optional but Recommended) -->
<key>NSLocalNetworkUsageDescription</key>
<string>$(PRODUCT_NAME) uses local network to discover and connect with streaming peers.</string>

<!-- 🔄 Background Audio Mode (Optional: If you want audio to continue in background) -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## 2. 📦 `ios/Podfile` Permission Handler Macros

`permission_handler` on iOS requires enabling permission macros in your `ios/Podfile`.

Open `ios/Podfile` and add the `PERMISSION_CAMERA=1` and `PERMISSION_MICROPHONE=1` macros inside the `post_install` block:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # 🌟 Enable Camera and Microphone permission flags for iOS
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

---

## 3. 🛠️ CocoaPods Installation

In your Flutter app terminal, navigate to the `ios` directory and run pod install:

```bash
cd ios
pod install --repo-update
cd ..
flutter run
```

---

## 4. 📱 Requesting Permissions in Dart

You can use the SDK's built-in 1-liner or `permission_handler` directly on iOS:

```dart
// 🌟 1-Line SDK Built-in Method
final isGranted = await client.requestPermissions(
  camera: true,
  microphone: true,
);

if (isGranted) {
  print('✅ iOS Camera & Mic permissions granted!');
}
```

Or using standard `permission_handler` syntax (automatically re-exported by `omnicast_client`):

```dart
final statuses = await [
  Permission.camera,
  Permission.microphone,
].request();

if (statuses[Permission.camera]?.isGranted == true &&
    statuses[Permission.microphone]?.isGranted == true) {
  print('✅ Granted!');
}
```

---

## 5. 💡 iOS Simulator vs Real Device Notice
- **iOS Simulator**: Simulators do not have a real hardware camera or audio driver. WebRTC will simulate an empty track or show avatar.
- **Physical iOS Device**: Camera, microphone, hardware encoding (H.264/VP8), and low-latency audio work with 100% full hardware acceleration on physical iPhones/iPads.
