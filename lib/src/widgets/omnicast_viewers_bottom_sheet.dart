import 'package:flutter/material.dart';
import '../core/omnicast_client.dart';
import '../models/room_models.dart';

/// Pre-built Interactive Viewers List & Host Ejection Bottom Sheet Modal.
///
/// Can be opened effortlessly with 1 single line of code:
/// ```dart
/// OmniCastViewersBottomSheet.show(context, client: client);
/// ```
class OmniCastViewersBottomSheet extends StatelessWidget {
  final OmniCastClient client;
  final String title;
  final bool enableHostKick;
  final void Function(OmniCastParticipant participant, String reason)? onUserKicked;

  const OmniCastViewersBottomSheet({
    super.key,
    required this.client,
    this.title = 'Live Room Viewers',
    this.enableHostKick = true,
    this.onUserKicked,
  });

  /// Displays the interactive viewers bottom sheet modal.
  static Future<void> show(
    BuildContext context, {
    required OmniCastClient client,
    String title = 'Live Room Viewers',
    bool enableHostKick = true,
    void Function(OmniCastParticipant participant, String reason)? onUserKicked,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.70,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: OmniCastViewersBottomSheet(
              client: client,
              title: title,
              enableHostKick: enableHostKick,
              onUserKicked: onUserKicked,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHost = client.state.isHost;
    final currentUserId = client.state.userId ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle indicator
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Header Title & Online Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: client.totalViewerCount,
              builder: (context, count, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count Online',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Viewers List Builder
        Expanded(
          child: ValueListenableBuilder<List<OmniCastParticipant>>(
            valueListenable: client.activeViewersList,
            builder: (context, viewers, _) {
              if (viewers.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, color: Colors.white30, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'No other viewers yet',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: viewers.length,
                separatorBuilder: (context, index) => const Divider(
                  color: Colors.white10,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final viewer = viewers[index];
                  final isSelf = viewer.userId == currentUserId;
                  final isVip = viewer.metadata['is_vip'] == true || viewer.metadata['isVip'] == true;
                  final level = viewer.metadata['level'] ?? 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        // Avatar with VIP Border
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF334155),
                              backgroundImage: NetworkImage(
                                viewer.avatarUrl ??
                                    'https://api.dicebear.com/7.x/bottts/png?seed=${viewer.userId}',
                              ),
                            ),
                            if (isVip)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        // Name & Level Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      viewer.displayName ?? viewer.userId,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isSelf) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'You',
                                        style: TextStyle(
                                          color: Color(0xFF818CF8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Level Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Lv.$level',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ID: ${viewer.userId}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Host Moderation: Kick Button
                        if (isHost && !isSelf && enableHostKick)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                            tooltip: 'Kick Participant',
                            onPressed: () => _showKickConfirmationDialog(
                              context,
                              viewer,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showKickConfirmationDialog(BuildContext context, OmniCastParticipant participant) {
    String selectedReason = 'Violated community guidelines';
    final reasons = [
      'Violated community guidelines',
      'Inappropriate language or behavior',
      'Spamming comments / chat',
      'Disruptive audio or video',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white12),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Kick Participant',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to eject "${participant.displayName ?? participant.userId}" from the live room?',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Reason:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: reasons.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text(r, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => selectedReason = val);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close confirmation dialog
                    Navigator.pop(context); // Close viewers bottom sheet

                    // Execute kick on SDK client
                    client.kickUser(participant.userId, reason: selectedReason);
                    onUserKicked?.call(participant, selectedReason);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ejected "${participant.displayName ?? participant.userId}" from the room'),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Text(
                    'Kick User',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Backward compatibility aliases
typedef OmniCastViewersDialog = OmniCastViewersBottomSheet;
typedef LiveRoomViewersDialog = OmniCastViewersBottomSheet;
