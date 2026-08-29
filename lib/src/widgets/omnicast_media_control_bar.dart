import 'package:flutter/material.dart';
import '../media/media_controller.dart';

/// Floating live broadcast control bar with Camera On/Off, Mic Mute/Unmute, and Camera Flip buttons.
class OmniCastMediaControlBar extends StatelessWidget {
  final MediaController mediaController;
  final EdgeInsetsGeometry padding;

  const OmniCastMediaControlBar({
    super.key,
    required this.mediaController,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Mic Mute / Unmute Button
          ValueListenableBuilder<bool>(
            valueListenable: mediaController.isMicrophoneMutedNotifier,
            builder: (context, isMuted, _) {
              return _CircleControlButton(
                icon: isMuted ? Icons.mic_off : Icons.mic,
                isActive: !isMuted,
                activeColor: const Color(0xFF10B981),
                inactiveColor: const Color(0xFFEF4444),
                tooltip: isMuted ? 'Unmute Microphone' : 'Mute Microphone',
                onTap: () => mediaController.setMicrophoneMuted(!isMuted),
              );
            },
          ),
          const SizedBox(width: 12),

          // 2. Camera On / Off Button
          ValueListenableBuilder<bool>(
            valueListenable: mediaController.isCameraEnabledNotifier,
            builder: (context, isEnabled, _) {
              return _CircleControlButton(
                icon: isEnabled ? Icons.videocam : Icons.videocam_off,
                isActive: isEnabled,
                activeColor: const Color(0xFF3B82F6),
                inactiveColor: const Color(0xFF64748B),
                tooltip: isEnabled ? 'Turn Off Camera' : 'Turn On Camera',
                onTap: () => mediaController.setCameraEnabled(!isEnabled),
              );
            },
          ),
          const SizedBox(width: 12),

          // 3. Flip Camera Button
          _CircleControlButton(
            icon: Icons.flip_camera_ios,
            isActive: true,
            activeColor: const Color(0xFF8B5CF6),
            tooltip: 'Switch Camera',
            onTap: () => mediaController.switchCamera(),
          ),
        ],
      ),
    );
  }
}

class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleControlButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF64748B),
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? activeColor : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
