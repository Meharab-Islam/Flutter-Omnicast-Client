import 'dart:math';
import 'package:flutter/material.dart';
import 'package:omnicast_client/omnicast_client.dart';
import '../config/app_constants.dart';
import '../models/demo_user_model.dart';
import 'live_room_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _serverController = TextEditingController(text: AppConstants.defaultLocalhost);
  final _roomController = TextEditingController(text: 'room-101');
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();

  String _selectedRole = 'host'; // 'host' or 'viewer'
  OmniCastClient? _lobbyClient;

  @override
  void initState() {
    super.initState();
    final randomId = Random().nextInt(9000) + 1000;
    _userIdController.text = 'user-$randomId';
    _nameController.text = 'User $randomId';
    _initLobbyClient();
  }

  Future<void> _initLobbyClient() async {
    _lobbyClient?.dispose();
    final server = _serverController.text.trim().isNotEmpty
        ? _serverController.text.trim()
        : AppConstants.defaultLocalhost;
    final client = await OmniCastClient.init(
      serverUrl: server,
      autoConnect: false,
      autoWatchRooms: true,
      watchRoomsInterval: const Duration(seconds: 4),
    );
    if (mounted) {
      setState(() {
        _lobbyClient = client;
      });
    }
  }

  @override
  void dispose() {
    _lobbyClient?.dispose();
    _serverController.dispose();
    _roomController.dispose();
    _nameController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  void _refreshRooms() {
    _lobbyClient?.refreshLiveRooms();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking live rooms on media server...'),
        backgroundColor: Colors.indigo,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _enterLiveRoom() {
    final server = _serverController.text.trim();
    final roomId = _roomController.text.trim();
    final userId = _userIdController.text.trim();
    final userName = _nameController.text.trim();

    if (server.isEmpty || roomId.isEmpty || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter server address, room ID, and user details.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final session = DemoSession(
      serverUrl: server,
      roomId: roomId,
      userId: userId,
      userName: userName.isNotEmpty ? userName : userId,
      role: _selectedRole,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveRoomScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F111A),
              Color(0xFF191B28),
              Color(0xFF0F111A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  color: const Color(0xFF1E2132).withValues(alpha: 0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Title & Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.podcasts_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'OmniCast Live',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'WebRTC SFU Live Streaming & PK Engine',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                        ),
                        const SizedBox(height: 24),

                        // Server Address Input & Presets
                        Text(
                          'Media Server Address',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _serverController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. 127.0.0.1:8080 or 192.168.1.x:8080',
                            prefixIcon: const Icon(Icons.dns_rounded, color: Color(0xFF6C5CE7)),
                            filled: true,
                            fillColor: const Color(0xFF141724),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('Localhost', style: TextStyle(fontSize: 11)),
                              onPressed: () => _serverController.text = AppConstants.defaultLocalhost,
                              backgroundColor: const Color(0xFF141724),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            ActionChip(
                              label: const Text('Android Emulator', style: TextStyle(fontSize: 11)),
                              onPressed: () => _serverController.text = AppConstants.defaultAndroidEmulator,
                              backgroundColor: const Color(0xFF141724),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            ActionChip(
                              label: const Text('Real Phone (Wi-Fi)', style: TextStyle(fontSize: 11)),
                              onPressed: () => _serverController.text = AppConstants.defaultLanIP,
                              backgroundColor: const Color(0xFF141724),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Room ID Input
                        Text(
                          'Room Identifier',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _roomController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'e.g. room-101',
                            prefixIcon: const Icon(Icons.meeting_room_rounded, color: Color(0xFF00CEC9)),
                            filled: true,
                            fillColor: const Color(0xFF141724),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // User Name Input
                        Text(
                          'Display Name',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFFFF7675)),
                            filled: true,
                            fillColor: const Color(0xFF141724),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Role Selection Segmented Toggle
                        Text(
                          'Join Role',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF141724),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'host'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'host'
                                          ? const Color(0xFF6C5CE7)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.videocam_rounded,
                                          size: 18,
                                          color: _selectedRole == 'host' ? Colors.white : Colors.white60,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Host (Broadcast)',
                                              style: TextStyle(
                                                color: _selectedRole == 'host' ? Colors.white : Colors.white60,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedRole = 'viewer'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'viewer'
                                          ? const Color(0xFF00CEC9)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.visibility_rounded,
                                          size: 18,
                                          color: _selectedRole == 'viewer' ? Colors.black87 : Colors.white60,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Viewer (Watch)',
                                              style: TextStyle(
                                                color: _selectedRole == 'viewer' ? Colors.black87 : Colors.white60,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Button: Enter Room
                        ElevatedButton(
                          onPressed: _enterLiveRoom,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: _selectedRole == 'host'
                                ? const Color(0xFF6C5CE7)
                                : const Color(0xFF00CEC9),
                            foregroundColor: _selectedRole == 'host' ? Colors.white : Colors.black87,
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_selectedRole == 'host' ? Icons.play_arrow_rounded : Icons.login_rounded),
                              const SizedBox(width: 8),
                              Text(
                                _selectedRole == 'host' ? 'Start Broadcasting' : 'Join Live Stream',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Real-time Live Rooms Discovery (Zero manual REST API calls needed!)
                        if (_lobbyClient != null) ...[
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.sensors_rounded, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Active Live Rooms',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white54),
                                tooltip: 'Refresh Rooms',
                                onPressed: _refreshRooms,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          OmniCastLiveRoomsBuilder(
                            client: _lobbyClient!,
                            builder: (context, rooms) {
                              if (rooms.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141724),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No active live streams on server.\nStart broadcasting to create one!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ),
                                );
                              }

                              return ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 180),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: rooms.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final room = rooms[index];
                                    final isSelected = _roomController.text == room.roomId;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF6C5CE7).withValues(alpha: 0.25)
                                            : const Color(0xFF141724),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF6C5CE7)
                                              : Colors.white.withValues(alpha: 0.06),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.live_tv_rounded, color: Colors.redAccent, size: 16),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  room.roomId,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  'Host: ${room.hostId}',
                                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.visibility_rounded, color: Colors.white70, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${room.totalViewers}',
                                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF00CEC9),
                                              foregroundColor: Colors.black87,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              minimumSize: Size.zero,
                                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _roomController.text = room.roomId;
                                                _selectedRole = 'viewer';
                                              });
                                            },
                                            child: const Text('Join'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
