import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../media/media_controller.dart';
import '../media/media_stream_manager.dart';

/// A production Flutter UI widget that binds and renders live WebRTC video
/// from [MediaStreamManager] for a local user or remote peer [userId], with
/// built-in Adaptive Streaming support based on rendered widget dimensions.
class OmniCastVideoView extends StatefulWidget {
  /// The [MediaStreamManager] holding local and remote video renderers.
  final MediaStreamManager mediaStreamManager;

  /// Optional [MediaController] for sending adaptive streaming layer requests.
  final MediaController? mediaController;

  /// The user ID to render. If null or `'local'`, renders the local camera feed.
  final String? userId;

  /// Whether to mirror the video rendering (typically true for local front camera).
  final bool mirror;

  /// The object fit strategy for rendering the video within its layout constraints.
  final RTCVideoViewObjectFit objectFit;

  /// Whether to automatically adjust simulcast subscription layer based on widget dimensions.
  final bool enableAdaptiveStreaming;

  /// Optional custom placeholder widget shown when the video track is loading or not available.
  final Widget? placeholder;

  const OmniCastVideoView({
    super.key,
    required this.mediaStreamManager,
    this.mediaController,
    this.userId,
    this.mirror = false,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.enableAdaptiveStreaming = true,
    this.placeholder,
  });

  @override
  State<OmniCastVideoView> createState() => _OmniCastVideoViewState();
}

class _OmniCastVideoViewState extends State<OmniCastVideoView> {
  RTCVideoRenderer? _renderer;
  bool _isLoading = true;
  String? _currentRequestedLayer;

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

  void _checkAdaptiveStreaming(BoxConstraints constraints) {
    if (!widget.enableAdaptiveStreaming ||
        widget.mediaController == null ||
        widget.userId == null ||
        widget.userId == 'local') {
      return;
    }

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;

    // Skip unconstrained or zero dimensions
    if (width.isInfinite || height.isInfinite || width <= 0 || height <= 0) return;

    final maxDimension = width > height ? width : height;
    String targetLayer;

    if (maxDimension <= 360) {
      targetLayer = 'q'; // Low resolution for grid/mini view
    } else if (maxDimension <= 720) {
      targetLayer = 'h'; // Medium resolution for split-screen / co-hosts
    } else {
      targetLayer = 'f'; // Full resolution for focused / fullscreen
    }

    if (_currentRequestedLayer != targetLayer) {
      _currentRequestedLayer = targetLayer;
      widget.mediaController!.requestLayerForUser(
        targetUserId: widget.userId!,
        layer: targetLayer,
      );
      debugPrint(
          '[OmniCastVideoView Adaptive] Requested layer $targetLayer for ${widget.userId} (${width.toInt()}x${height.toInt()})');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _renderer == null || _renderer!.srcObject == null) {
      return widget.placeholder ?? _defaultPlaceholder();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _checkAdaptiveStreaming(constraints);

        return ClipRRect(
          child: RTCVideoView(
            _renderer!,
            mirror: widget.mirror,
            objectFit: widget.objectFit,
          ),
        );
      },
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
