import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';

/// Turnkey, high-performance real-time chat & interaction overlay widget.
///
/// Automatically handles:
/// - Real-time in-room text chat
/// - Animated user join & leave badges
/// - Gift sent event announcements
/// - Reaction emoji broadcasts
/// - Automatic scroll-to-bottom with smooth animations
/// - Modern dark-mode glassmorphism aesthetics
class OmniCastLiveChat extends StatefulWidget {
  final OmniCastClient client;
  final double maxHeight;
  final double width;
  final EdgeInsetsGeometry padding;
  final bool showJoinLeaveEvents;
  final bool showGiftEvents;
  final Widget Function(BuildContext context, dynamic event)? customEventBuilder;

  const OmniCastLiveChat({
    super.key,
    required this.client,
    this.maxHeight = 220,
    this.width = 280,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.showJoinLeaveEvents = true,
    this.showGiftEvents = true,
    this.customEventBuilder,
  });

  @override
  State<OmniCastLiveChat> createState() => _OmniCastLiveChatState();
}

class _OmniCastLiveChatState extends State<OmniCastLiveChat> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _bindChatListeners();
  }

  void _bindChatListeners() {
    // 1. Text Chat
    widget.client.interaction.onChat.listen((chat) {
      if (!mounted) return;
      _addMessage({
        'type': 'chat',
        'user': chat.senderName.isNotEmpty ? chat.senderName : chat.senderId,
        'userId': chat.senderId,
        'text': chat.text,
        'time': chat.timestamp,
      });
    });

    // 2. Gifts
    if (widget.showGiftEvents) {
      widget.client.interaction.onGift.listen((gift) {
        if (!mounted) return;
        _addMessage({
          'type': 'gift',
          'user': gift.senderName.isNotEmpty ? gift.senderName : gift.senderId,
          'giftName': gift.giftName,
          'giftImage': gift.giftIconUrl,
          'count': gift.amount,
          'time': DateTime.now(),
        });
      });
    }

    // 3. User Join
    if (widget.showJoinLeaveEvents) {
      widget.client.room.onParticipantJoined.listen((p) {
        if (!mounted) return;
        final name = (p.displayName != null && p.displayName!.isNotEmpty)
            ? p.displayName!
            : p.userId;
        _addMessage({
          'type': 'join',
          'user': name,
          'userId': p.userId,
          'avatar': p.avatarUrl,
          'text': 'joined the live',
          'time': DateTime.now(),
        });
      });

      // 4. User Left
      widget.client.room.onParticipantLeft.listen((userId) {
        if (!mounted) return;
        _addMessage({
          'type': 'leave',
          'user': userId,
          'userId': userId,
          'text': 'left the live',
          'time': DateTime.now(),
        });
      });
    }
  }

  void _addMessage(Map<String, dynamic> msg) {
    setState(() {
      _messages.add(msg);
      if (_messages.length > 100) {
        _messages.removeAt(0);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.maxHeight,
        maxWidth: widget.width,
      ),
      padding: widget.padding,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white, Colors.white],
            stops: [0.0, 0.15, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _messages.length,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final item = _messages[index];
            if (widget.customEventBuilder != null) {
              final custom = widget.customEventBuilder!(context, item);
              if (custom != const SizedBox.shrink()) return custom;
            }

            final type = item['type'];
            if (type == 'join') return _buildJoinItem(item);
            if (type == 'leave') return _buildLeaveItem(item);
            if (type == 'gift') return _buildGiftItem(item);
            return _buildChatItem(item);
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${item['user'] ?? 'User'}: ',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: item['text'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withOpacity(0.55),
                const Color(0xFFA855F7).withOpacity(0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
              const SizedBox(width: 5),
              Text(
                '${item['user']} ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'joined the live',
                style: TextStyle(
                  color: Color(0xFFE0E7FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${item['user']} left',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF007F).withOpacity(0.6),
                const Color(0xFFFF758C).withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF80AB).withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁 ', style: TextStyle(fontSize: 14)),
              Text(
                '${item['user']} ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'sent ${item['giftName']} x${item['count'] ?? 1}',
                style: const TextStyle(
                  color: Color(0xFFFFEB3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
