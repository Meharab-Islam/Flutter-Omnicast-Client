import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_stream_manager.dart';

/// A production Flutter UI widget that binds and renders live WebRTC video
/// from [MediaStreamManager] for a local user or remote peer [userId].
class OmniCastVideoView extends StatefulWidget {
  /// The [MediaStreamManager] holding local and remote video renderers.
  final MediaStreamManager mediaStreamManager;

  /// The user ID to render. If null or `'local'`, renders the local camera feed.
  final String? userId;

  /// Whether to mirror the video rendering (typically true for local front camera).
  final bool mirror;

  /// The object fit strategy for rendering the video within its layout constraints.
  final RTCVideoViewObjectFit objectFit;

  /// Optional custom placeholder widget shown when the video track is loading or not available.
  final Widget? placeholder;

  const OmniCastVideoView({
    super.key,
    required this.mediaStreamManager,
    this.userId,
    this.mirror = false,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.placeholder,
  });

  @override
  State<OmniCastVideoView> createState() => _OmniCastVideoViewState();
}

class _OmniCastVideoViewState extends State<OmniCastVideoView> {
  RTCVideoRenderer? _renderer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bindRenderer();
  }

  @override
  void didUpdateWidget(covariant OmniCastVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.mediaStreamManager != widget.mediaStreamManager) {
      _bindRenderer();
    }
  }

  Future<void> _bindRenderer() async {
    setState(() => _isLoading = true);

    try {
      final isLocal = widget.userId == null || widget.userId == 'local';
      if (isLocal) {
        _renderer = await widget.mediaStreamManager.initLocalRenderer();
      } else {
        _renderer = await widget.mediaStreamManager.getOrCreateRemoteRenderer(
          widget.userId!,
        );
      }
    } catch (e) {
      debugPrint('[OmniCastVideoView] Error binding renderer: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _renderer == null || _renderer!.srcObject == null) {
      return widget.placeholder ?? _defaultPlaceholder();
    }

    return ClipRRect(
      child: RTCVideoView(
        _renderer!,
        mirror: widget.mirror,
        objectFit: widget.objectFit,
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      ),
    );
  }
}
