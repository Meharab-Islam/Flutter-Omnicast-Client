import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omnicast_client/omnicast_client.dart';
import '../models/demo_user_model.dart';
import '../widgets/gift_modal.dart';
import '../widgets/live_chat_view.dart';
import '../widgets/media_control_bar.dart';
import '../widgets/pk_score_bar.dart';

class LiveRoomScreen extends StatefulWidget {
  final DemoSession session;

  const LiveRoomScreen({super.key, required this.session});

  @override
  State<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends State<LiveRoomScreen> {
  late final OmniCastClient _client;
  bool _isConnecting = true;
  String? _errorMessage;

  // Local state for UI updates
  final List<ChatMessage> _chatMessages = [];
  final List<StreamSubscription> _subscriptions = [];

  // PK State
  bool _isPKActive = false;
  String? _pkBattleId;
  String? _pkOpponentRoomId;
  String? _pkOpponentHostId;
  int _hostPKScore = 0;
  int _opponentPKScore = 0;
  int _pkRemainingSeconds = 0;

  // Media Controls
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isCoHost = false;

  // Active Gift Banner
  String? _activeGiftNotification;
  Timer? _giftBannerTimer;

  @override
  void initState() {
    super.initState();
    _initOmniCastSession();
  }

  Future<void> _initOmniCastSession() async {
    try {
      final isLocal = widget.session.serverUrl.contains('localhost') ||
          widget.session.serverUrl.contains('127.0.0.1') ||
          widget.session.serverUrl.contains(':8080') ||
          RegExp(r'^\d+\.\d+\.\d+\.\d+').hasMatch(widget.session.serverUrl);
      _client = await OmniCastClient.init(
        serverUrl: widget.session.serverUrl,
        apiKey: 'dev_api_key_123',
        apiSecret: 'dev_api_secret_456',
        jwtSecret: 'super_secret_jwt_key_789',
        isSecure: isLocal ? false : null,
        enableLogging: true,
      );

      _bindEventStreams();

      if (widget.session.isHost) {
        await _client.createRoom(
          roomId: widget.session.roomId,
          userId: widget.session.userId,
          metadata: {'display_name': widget.session.userName},
        );
      } else {
        await _client.joinRoom(
          roomId: widget.session.roomId,
          userId: widget.session.userId,
          metadata: {'display_name': widget.session.userName},
        );
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _bindEventStreams() {
    // 1. Chat stream
    _subscriptions.add(
      _client.onChat.listen((msg) {
        if (mounted) {
          setState(() {
            _chatMessages.add(msg);
          });
        }
      }),
    );

    // 2. User Joined / Left announcements
    _subscriptions.add(
      _client.onUserJoined.listen((participant) {
        if (mounted) {
          final name = participant.displayName ?? participant.userId;
          setState(() {
            _chatMessages.add(
              ChatMessage(
                id: 'sys-${DateTime.now().millisecondsSinceEpoch}',
                senderId: 'system',
                senderName: 'System',
                text: '$name joined the stream 👋',
                timestamp: DateTime.now(),
              ),
            );
          });
        }
      }),
    );

    // 3. Gift stream
    _subscriptions.add(
      _client.onGift.listen((event) {
        if (mounted) {
          setState(() {
            _activeGiftNotification = '${event.senderName} sent ${event.giftId} 🎁';
            _chatMessages.add(
              ChatMessage(
                id: 'gift-${DateTime.now().millisecondsSinceEpoch}',
                senderId: 'gift',
                senderName: 'Gift Alert',
                text: '${event.senderName} sent ${event.giftId} (🪙 ${event.coinValue})',
                timestamp: DateTime.now(),
              ),
            );
          });
          _giftBannerTimer?.cancel();
          _giftBannerTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) setState(() => _activeGiftNotification = null);
          });
        }
      }),
    );

    // 4. PK Battle streams
    _subscriptions.add(
      _client.onPKStarted.listen((info) {
        if (mounted) {
          setState(() {
            _isPKActive = true;
            _pkBattleId = info.battleId;
            _pkOpponentRoomId = info.opponentRoomId;
            _pkOpponentHostId = info.opponentUserId;
            _hostPKScore = info.hostScore;
            _opponentPKScore = info.opponentScore;
            _pkRemainingSeconds = info.durationSeconds;
          });
        }
      }),
    );

    _subscriptions.add(
      _client.onPKScoreUpdated.listen((update) {
        if (mounted) {
          setState(() {
            _hostPKScore = update.hostScore;
            _opponentPKScore = update.opponentScore;
          });
        }
      }),
    );

    _subscriptions.add(
      _client.onPKTimerTick.listen((tick) {
        if (mounted) {
          setState(() {
            _pkRemainingSeconds = tick.remainingSeconds;
          });
        }
      }),
    );

    _subscriptions.add(
      _client.onPKEnded.listen((_) {
        if (mounted) {
          setState(() {
            _isPKActive = false;
            _pkBattleId = null;
            _pkOpponentRoomId = null;
            _pkOpponentHostId = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PK Battle has ended!'), backgroundColor: Colors.indigo),
          );
        }
      }),
    );

    // 5. Co-Host Seat streams
    _subscriptions.add(
      _client.onSeatUpdated.listen((_) {
        if (mounted) {
          final amICoHost = _client.state.activeSeats.any((s) => s.userId == widget.session.userId);
          setState(() {
            _isCoHost = amICoHost;
          });
        }
      }),
    );

    _subscriptions.add(
      _client.onSeatKicked.listen((msg) {
        final targetUser = msg.targetUser ?? (msg.payload is Map ? msg.payload['target_user'] : null);
        if ((targetUser == widget.session.userId || msg.userId == widget.session.userId) && mounted) {
          setState(() => _isCoHost = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You were stepped down from the co-host seat.'), backgroundColor: Colors.orange),
          );
        }
      }),
    );

    // 6. Media Notifiers
    _client.media.isMicrophoneMutedNotifier.addListener(() {
      if (mounted) setState(() => _isMicMuted = _client.media.isMicrophoneMutedNotifier.value);
    });

    _client.media.isCameraEnabledNotifier.addListener(() {
      if (mounted) setState(() => _isCameraOff = !_client.media.isCameraEnabledNotifier.value);
    });
  }

  @override
  void dispose() {
    _giftBannerTimer?.cancel();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _client.dispose();
    super.dispose();
  }

  void _sendChat(String text) {
    _client.sendChat(text);
  }

  void _openGifts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftModal(
        isPKActive: _isPKActive,
        hostId: widget.session.roomId,
        opponentId: _pkOpponentHostId ?? _pkOpponentRoomId,
        onSendGift: (gift, targetHostId) {
          _client.sendGift(
            giftId: gift.id,
            amount: 1,
            targetUserId: targetHostId,
            giftName: gift.name,
            coinValue: gift.coins,
          );
        },
      ),
    );
  }

  void _toggleMic() {
    _client.setMicrophoneMuted(!_isMicMuted);
  }

  void _toggleCamera() {
    _client.setCameraEnabled(_isCameraOff);
  }

  void _switchCamera() {
    _client.switchCamera();
  }

  void _handleSeatAction() {
    if (widget.session.isHost) {
      if (_client.seats.pendingSeatRequests.isNotEmpty) {
        OmniCastSeatRequestsBottomSheet.show(context, client: _client);
      } else {
        _showHostSeatManagementDialog();
      }
    } else {
      if (_isCoHost) {
        _client.seats.leaveSeat();
      } else {
        _client.seats.requestSeat(seatIndex: 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seat request sent to Host!'), backgroundColor: Colors.indigo),
        );
      }
    }
  }

  void _showHostSeatManagementDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2132),
        title: const Text('Co-Host Seats', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListenableBuilder(
            listenable: _client.state,
            builder: (context, _) {
              final seats = _client.state.activeSeats;
              if (seats.isEmpty) {
                return const Text('No active co-hosts currently.', style: TextStyle(color: Colors.white60));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: seats.length,
                itemBuilder: (context, index) {
                  final s = seats[index];
                  final displayName = s.user?.displayName ?? s.userId ?? 'Seat ${s.seatIndex}';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(displayName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Seat ${s.seatIndex}', style: const TextStyle(color: Colors.white54)),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                      tooltip: 'Kick from seat',
                      onPressed: () {
                        if (s.userId != null) {
                          _client.kickSeat(s.seatIndex, targetUserId: s.userId);
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          if (_client.seats.pendingSeatRequests.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                OmniCastSeatRequestsBottomSheet.show(context, client: _client);
              },
              icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFF6C5CE7)),
              label: Text(
                'Requests (${_client.seats.pendingSeatRequests.length})',
                style: const TextStyle(color: Color(0xFF6C5CE7)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00CEC9))),
          ),
        ],
      ),
    );
  }

  void _handlePKAction() {
    if (_isPKActive) {
      _client.endPK(_pkBattleId ?? 'pk_${widget.session.roomId}');
    } else {
      final textController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2132),
          title: const Text('Challenge Host to PK Battle', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter Opponent Room ID (e.g. room-202)',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final targetRoom = textController.text.trim();
                if (targetRoom.isNotEmpty) {
                  _client.sendPKRequest(
                    targetRoomId: targetRoom,
                    targetHostId: targetRoom,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PK Battle challenge sent to $targetRoom!'), backgroundColor: Colors.indigo),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Challenge', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _selectLayer(String layer) {
    _client.setSimulcastLayer(layer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video layer switched to: $layer'), backgroundColor: Colors.indigo),
    );
  }

  void _triggerICERestart() {
    _client.requestICERestart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ICE Restart renegotiation triggered!'), backgroundColor: Colors.teal),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              const SizedBox(height: 16),
              Text(
                widget.session.isHost ? 'Starting Live Broadcast SFU...' : 'Connecting to Live Media Server...',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F111A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                const Text('Connection Failed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                  child: const Text('Back to Lobby'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Fullscreen Main Video Canvas
          Positioned.fill(
            child: _buildVideoCanvas(),
          ),

          // 2. Top Header Overlay (Room info, Viewers count, Host coins, Close button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeaderOverlay(),
          ),

          // 3. PK Score Bar (if PK is active)
          if (_isPKActive)
            Positioned(
              top: 85,
              left: 0,
              right: 0,
              child: PKScoreBar(
                hostScore: _hostPKScore,
                opponentScore: _opponentPKScore,
                hostName: 'Host (${widget.session.roomId})',
                opponentName: _pkOpponentRoomId ?? 'Opponent',
                remainingSeconds: _pkRemainingSeconds,
              ),
            ),

          // 4. Floating Gift Toast Banner
          if (_activeGiftNotification != null)
            Positioned(
              top: _isPKActive ? 175 : 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF7675), Color(0xFFE84393)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  _activeGiftNotification!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),

          // 4.1 Guest Stage Overlay (Multi-Seat Stage)
          Positioned(
            right: 12,
            top: _isPKActive ? 180 : 95,
            width: 140,
            child: OmniCastStageBuilder(
              client: _client,
              builder: (context, seats, count) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Stage ($count/4)',
                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      OmniCastStageGrid(
                        client: _client,
                        maxSeats: 4,
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 5. Floating Live Chat Feed
          Positioned(
            left: 0,
            bottom: 110,
            width: MediaQuery.of(context).size.width * 0.75,
            height: 180,
            child: LiveChatView(messages: _chatMessages),
          ),

          // 6. Bottom Media & Action Control Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MediaControlBar(
              isHost: widget.session.isHost,
              isCoHost: _isCoHost,
              isMicMuted: _isMicMuted,
              isCameraOff: _isCameraOff,
              isPKActive: _isPKActive,
              onSendChat: _sendChat,
              onOpenGifts: _openGifts,
              onToggleMic: _toggleMic,
              onToggleCamera: _toggleCamera,
              onSwitchCamera: _switchCamera,
              onSeatAction: _handleSeatAction,
              onPKAction: _handlePKAction,
              onSelectLayer: _selectLayer,
              onICERestart: _triggerICERestart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCanvas() {
    if (widget.session.isHost) {
      final renderer = _client.media.localRenderer;
      if (renderer != null) {
        return ListenableBuilder(
          listenable: renderer,
          builder: (context, _) {
            if (renderer.srcObject != null || renderer.renderVideo) {
              return RTCVideoView(
                renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: true,
              );
            }
            return Container(
              color: const Color(0xFF1E2132),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
              ),
            );
          },
        );
      }
      return Container(
        color: const Color(0xFF1E2132),
        child: const Center(
          child: Icon(Icons.videocam_rounded, size: 64, color: Colors.white24),
        ),
      );
    } else {
      // Viewer Mode: Subscribed Host Stream
      return ListenableBuilder(
        listenable: _client.state,
        builder: (context, _) {
          final renderer = _client.media.getRenderer(widget.session.roomId) ??
              _client.media.getRenderer('host');
          if (renderer != null) {
            return ListenableBuilder(
              listenable: renderer,
              builder: (context, _) {
                if (renderer.srcObject != null || renderer.renderVideo) {
                  return RTCVideoView(
                    renderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  );
                }
                return Container(
                  color: const Color(0xFF141724),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF00CEC9)),
                        SizedBox(height: 12),
                        Text('Receiving live video stream...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return Container(
            color: const Color(0xFF141724),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00CEC9)),
                  SizedBox(height: 12),
                  Text('Connecting to host broadcast...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildHeaderOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // LIVE badge & Room ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 8),
                  const SizedBox(width: 4),
                  Text(
                    widget.session.roomId,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Reactive Viewer count from RoomState
            ListenableBuilder(
              listenable: _client.state,
              builder: (context, _) {
                final count = _client.state.viewersCount;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text('$count', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Reactive Host Coin Balance from RoomState
            ListenableBuilder(
              listenable: _client.state,
              builder: (context, _) {
                final coins = _client.state.hostCoinBalance;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text('$coins', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),

            // Host Pending Seat Requests Badge
            if (widget.session.isHost) ...[
              const SizedBox(width: 8),
              OmniCastSeatRequestsBuilder(
                client: _client,
                builder: (context, requests) {
                  if (requests.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () => OmniCastSeatRequestsBottomSheet.show(context, client: _client),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, color: Colors.black87, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${requests.length}',
                            style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const Spacer(),

            // Exit / Leave Button
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
