import 'package:flutter/foundation.dart';
import '../models/interaction_models.dart';
import '../models/pk_models.dart';
import '../models/room_models.dart';
import '../models/seat_models.dart';

/// Global reactive state container (ChangeNotifier) holding room metadata,
/// viewers count, chat history, gifts, active seats, stage layout, and PK battle state.
class RoomState extends ChangeNotifier {
  String? _roomId;
  String? _hostId;
  String? _userId;
  UserRole _role = UserRole.viewer;
  RoomType _roomType = RoomType.video;
  RoomMode _roomMode = RoomMode.solo;
  ClientConnectionState _connectionState = ClientConnectionState.disconnected;

  int _viewersCount = 0;
  int _hostCoinBalance = 0;
  int _userCoinBalance = 0;
  String? _pinnedStageUserId;

  final List<Participant> _viewers = [];
  final List<StageSeat> _activeSeats = [];
  final Set<String> _activeRemoteUserIds = {};
  final List<ChatMessage> _chatHistory = [];
  final List<GiftEvent> _recentGifts = [];
  final List<SeatRequest> _pendingSeatRequests = [];
  final List<CoHostInvite> _pendingInvites = [];
  final Map<String, bool> _userAudioMuteStates = {};
  final Map<String, bool> _userCameraOffStates = {};

  PKBattleInfo? _activePK;

  // Native Reactive ValueNotifiers for headless UI canvas binding
  final ValueNotifier<RoomMode> roomModeNotifier = ValueNotifier<RoomMode>(
    RoomMode.solo,
  );
  final ValueNotifier<PkScore> pkScoreNotifier = ValueNotifier<PkScore>(
    const PkScore(),
  );
  final ValueNotifier<bool> showJoinMessagesNotifier = ValueNotifier<bool>(
    true,
  );
  final ValueNotifier<List<StageSeat>> activeSeatsNotifier =
      ValueNotifier<List<StageSeat>>(const []);
  final ValueNotifier<int> occupiedSeatsCountNotifier = ValueNotifier<int>(0);

  bool _isDisposed = false;

  /// Returns whether this state container has been disposed.
  bool get isDisposed => _isDisposed;

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  // Getters
  bool get showJoinMessages => showJoinMessagesNotifier.value;
  set showJoinMessages(bool val) {
    if (_isDisposed) return;
    showJoinMessagesNotifier.value = val;
  }

  String? get roomId => _roomId;
  String? get hostId => _hostId;
  String? get userId => _userId;
  UserRole get role => _role;
  RoomType get roomType => _roomType;
  RoomMode get roomMode => _roomMode;
  bool get isAudioOnly => _roomType == RoomType.audio;
  ClientConnectionState get connectionState => _connectionState;

  int get viewersCount => _viewersCount;
  int get hostCoinBalance => _hostCoinBalance;
  int get userCoinBalance => _userCoinBalance;
  String? get pinnedStageUserId => _pinnedStageUserId;

  /// Returns the user ID of the participant occupying the Main Seat.
  /// Defaults to [_hostId] if no specific co-host is pinned.
  String? get mainSeatUserId =>
      (_pinnedStageUserId != null && _pinnedStageUserId!.isNotEmpty)
      ? _pinnedStageUserId
      : _hostId;

  /// Returns whether the Host is currently occupying the Main Seat.
  bool get isHostInMainSeat =>
      _pinnedStageUserId == null ||
      _pinnedStageUserId!.isEmpty ||
      _pinnedStageUserId == _hostId;

  List<Participant> get viewers => List.unmodifiable(_viewers);
  List<StageSeat> get activeSeats => List.unmodifiable(_activeSeats);
  List<StageSeat> get occupiedSeats =>
      _activeSeats.where((s) => s.isOccupied).toList();
  int get occupiedSeatsCount => _activeSeats.where((s) => s.isOccupied).length;
  Set<String> get activeRemoteUserIds => Set.unmodifiable(_activeRemoteUserIds);
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  List<GiftEvent> get recentGifts => List.unmodifiable(_recentGifts);
  List<SeatRequest> get pendingSeatRequests =>
      List.unmodifiable(_pendingSeatRequests);
  List<SeatRequest> get waitingList => List.unmodifiable(_pendingSeatRequests);
  List<CoHostInvite> get pendingInvites => List.unmodifiable(_pendingInvites);
  Map<String, bool> get userAudioMuteStates =>
      Map.unmodifiable(_userAudioMuteStates);
  Map<String, bool> get userCameraOffStates =>
      Map.unmodifiable(_userCameraOffStates);

  /// Returns the [StageSeat] at [seatIndex] (1-indexed or 0-indexed as provided), or null if not found.
  StageSeat? getSeat(int seatIndex) {
    try {
      return _activeSeats.firstWhere((s) => s.seatIndex == seatIndex);
    } catch (_) {
      return null;
    }
  }

  /// Returns the [StageSeat] assigned to [userId], or null if user is not in a seat.
  StageSeat? getSeatOfUser(String userId) {
    try {
      return _activeSeats.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  /// Checks if [userId] is currently muted (audio).
  bool isUserMuted(String userId) => isUserAudioMuted(userId);
  bool isUserAudioMuted(String userId) => _userAudioMuteStates[userId] ?? false;

  /// Checks if [userId] currently has camera disabled/off.
  bool isUserCameraOff(String userId) => _userCameraOffStates[userId] ?? false;

  PKBattleInfo? get activePK => _activePK;
  PKState get pkState => _activePK != null
      ? PKState.fromBattleInfo(_activePK!, currentUserId: _userId)
      : PKState.idle;

  bool get isInPKBattle =>
      _activePK != null &&
      (_activePK!.status == PKStatus.inProgress ||
          _activePK!.status == PKStatus.punishment);

  bool get isHost => _role == UserRole.host;
  bool get isCoHost => _role == UserRole.coHost;
  bool get isViewer => _role == UserRole.viewer;
  bool get isInRoom => _roomId != null && _roomId!.isNotEmpty;

  /// Sets up room session identity, role, and modality.
  void setSession({
    required String roomId,
    required String userId,
    required UserRole role,
    RoomType roomType = RoomType.video,
    String? hostId,
  }) {
    _roomId = roomId;
    _userId = userId;
    _role = role;
    _roomType = roomType;
    _hostId = hostId ?? (role == UserRole.host ? userId : null);
    _pinnedStageUserId = null;
    notifyListeners();
  }

  /// Updates connection state.
  void updateConnectionState(ClientConnectionState state) {
    if (_connectionState == state) return;
    _connectionState = state;
    notifyListeners();
  }

  /// Updates user role.
  void updateRole(UserRole newRole) {
    if (_role == newRole) return;
    _role = newRole;
    notifyListeners();
  }

  /// Updates room type (audio-only vs video).
  void updateRoomType(RoomType type) {
    if (_roomType == type) return;
    _roomType = type;
    notifyListeners();
  }

  /// Synchronizes full room info on join or late-join (`room_info_sync`).
  void syncRoomInfo(Map<String, dynamic> data) {
    _roomId = data['room_id'] as String? ?? _roomId;
    final host = data['host_id'] as String?;
    if (host != null && host.isNotEmpty) {
      _hostId = host;
    }
    final typeStr = data['room_type'] as String?;
    if (typeStr != null) {
      _roomType = typeStr.toLowerCase() == 'audio'
          ? RoomType.audio
          : RoomType.video;
    }
    _viewersCount =
        (data['viewers_count'] as num?)?.toInt() ??
        (data['viewer_count'] as num?)?.toInt() ??
        (data['total_viewers'] as num?)?.toInt() ??
        (data['count'] as num?)?.toInt() ??
        _viewersCount;
    _hostCoinBalance =
        (data['host_coin_balance'] as num?)?.toInt() ??
        (data['host_coins'] as num?)?.toInt() ??
        (data['host_score'] as num?)?.toInt() ??
        _hostCoinBalance;
    final mainSeat = data['main_seat_id'] as String?;
    final pinned = data['pinned_user_id'] as String?;
    if (pinned != null && pinned.isNotEmpty && pinned != _hostId) {
      _pinnedStageUserId = pinned;
    } else if (mainSeat != null && mainSeat.isNotEmpty && mainSeat != _hostId) {
      _pinnedStageUserId = mainSeat;
    } else {
      _pinnedStageUserId = null;
    }

    // Populate active users/viewers from viewers, viewers_list, or participants
    final viewersData =
        data['viewers'] ?? data['viewers_list'] ?? data['participants'];
    if (viewersData is List) {
      _viewers.clear();
      for (final item in viewersData) {
        if (item is Map<String, dynamic>) {
          _viewers.add(Participant.fromJson(item));
        } else if (item is Map) {
          _viewers.add(Participant.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String && item.isNotEmpty) {
          _viewers.add(
            Participant(
              userId: item,
              displayName: item,
              role: item == _hostId ? UserRole.host : UserRole.viewer,
              joinedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    // 1. Populate media states map first so seats get initialized with correct audio/video states
    if (data['media_states'] is Map<String, dynamic>) {
      final states = data['media_states'] as Map<String, dynamic>;
      states.forEach((uId, stateMap) {
        if (stateMap is Map) {
          final isMuted =
              (stateMap['muted_audio'] as bool?) ??
              (stateMap['muted'] as bool?) ??
              (stateMap['is_muted'] as bool?) ??
              (stateMap['audio_muted'] as bool?);
          if (isMuted != null) {
            _userAudioMuteStates[uId] = isMuted;
          }

          final isCamOff =
              (stateMap['muted_video'] as bool?) ??
              (stateMap['camera_off'] as bool?) ??
              (stateMap['is_camera_off'] as bool?) ??
              (stateMap['is_video_muted'] as bool?) ??
              (stateMap['video_muted'] as bool?);
          if (isCamOff != null) {
            _userCameraOffStates[uId] = isCamOff;
          }
        }
      });
    }

    // 2. Populate active seats
    if (data['active_seats'] != null) {
      updateActiveSeats(data['active_seats']);
    }

    // 3. Populate waiting list / pending seat requests for late-join users
    if (data['waiting_list'] is List ||
        data['pending_requests'] is List ||
        data['seat_requests'] is List) {
      final list =
          (data['waiting_list'] ??
                  data['pending_requests'] ??
                  data['seat_requests'])
              as List;
      _pendingSeatRequests.clear();
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _pendingSeatRequests.add(SeatRequest.fromJson(item));
        }
      }
    }

    // Populate chat history
    if (data['chat_history'] is List) {
      _chatHistory.clear();
      for (final item in data['chat_history'] as List) {
        if (item is Map<String, dynamic>) {
          _chatHistory.add(ChatMessage.fromJson(item));
        }
      }
    }

    // Populate current gifts
    if (data['recent_gifts'] is List) {
      _recentGifts.clear();
      for (final item in data['recent_gifts'] as List) {
        if (item is Map<String, dynamic>) {
          _recentGifts.add(GiftEvent.fromJson(item));
        }
      }
    }

    // Populate active PK
    if (data['active_pk'] is Map<String, dynamic>) {
      _activePK = PKBattleInfo.fromJson(
        data['active_pk'] as Map<String, dynamic>,
      );
      if (_activePK != null && _activePK!.opponentUserId.isNotEmpty) {
        _activeRemoteUserIds.add(_activePK!.opponentUserId);
      }
    } else if (data['active_pk'] == null && _activePK != null) {
      _activePK = null;
    }

    _syncSeatNotifiers();
    notifyListeners();
  }

  void _syncSeatNotifiers() {
    if (_isDisposed) return;
    try {
      activeSeatsNotifier.value = List.unmodifiable(_activeSeats);
      occupiedSeatsCountNotifier.value = _activeSeats
          .where((s) => s.isOccupied)
          .length;
    } catch (_) {}
  }

  /// Updates the viewer count and list of active viewers.
  void updateViewers({required int count, List<Participant>? viewersList}) {
    _viewersCount = count;
    if (viewersList != null) {
      _viewers.clear();
      _viewers.addAll(viewersList.take(200));
    }
    notifyListeners();
  }

  /// Updates active co-host seats from either a List or Map representation.
  void updateActiveSeats(dynamic activeSeatsData) {
    if (activeSeatsData == null) return;
    _activeSeats.clear();

    if (activeSeatsData is List) {
      for (int i = 0; i < activeSeatsData.length; i++) {
        final item = activeSeatsData[i];
        if (item is Map<String, dynamic>) {
          final seat = StageSeat.fromJson(item);
          final uId = seat.userId ?? '';
          Participant? userProfile = seat.user;
          if (userProfile == null && uId.isNotEmpty) {
            try {
              userProfile = _viewers.firstWhere((p) => p.userId == uId);
            } catch (_) {}
          }
          final resolvedSeat = seat.copyWith(
            user: userProfile,
            isMuted: _userAudioMuteStates[uId] ?? seat.isMuted,
            isCameraOff: _userCameraOffStates[uId] ?? seat.isCameraOff,
          );
          _activeSeats.add(resolvedSeat);
          if (uId.isNotEmpty) {
            if (uId != _userId) _activeRemoteUserIds.add(uId);
            _userAudioMuteStates[uId] = resolvedSeat.isMuted;
            _userCameraOffStates[uId] = resolvedSeat.isCameraOff;
          }
        } else if (item is Map) {
          final seat = StageSeat.fromJson(Map<String, dynamic>.from(item));
          final uId = seat.userId ?? '';
          Participant? userProfile = seat.user;
          if (userProfile == null && uId.isNotEmpty) {
            try {
              userProfile = _viewers.firstWhere((p) => p.userId == uId);
            } catch (_) {}
          }
          final resolvedSeat = seat.copyWith(
            user: userProfile,
            isMuted: _userAudioMuteStates[uId] ?? seat.isMuted,
            isCameraOff: _userCameraOffStates[uId] ?? seat.isCameraOff,
          );
          _activeSeats.add(resolvedSeat);
          if (uId.isNotEmpty) {
            if (uId != _userId) _activeRemoteUserIds.add(uId);
            _userAudioMuteStates[uId] = resolvedSeat.isMuted;
            _userCameraOffStates[uId] = resolvedSeat.isCameraOff;
          }
        } else if (item is String && item.isNotEmpty) {
          Participant? userProfile;
          try {
            userProfile = _viewers.firstWhere((p) => p.userId == item);
          } catch (_) {}
          final seat = StageSeat(
            seatIndex: i + 1,
            userId: item,
            user: userProfile,
            isMuted: _userAudioMuteStates[item] ?? false,
            isCameraOff: _userCameraOffStates[item] ?? false,
          );
          _activeSeats.add(seat);
          if (item != _userId) {
            _activeRemoteUserIds.add(item);
          }
        }
      }
    } else if (activeSeatsData is Map) {
      activeSeatsData.forEach((k, v) {
        final seatIndex = int.tryParse(k.toString()) ?? 0;
        final uId =
            (v is Map ? (v['user_id'] ?? v['userId']) : v)?.toString() ?? '';
        if (uId.isNotEmpty) {
          Participant? userProfile;
          try {
            userProfile = _viewers.firstWhere((p) => p.userId == uId);
          } catch (_) {}
          final seat = StageSeat(
            seatIndex: seatIndex,
            userId: uId,
            user: userProfile,
            isMuted: _userAudioMuteStates[uId] ?? false,
            isCameraOff: _userCameraOffStates[uId] ?? false,
          );
          _activeSeats.add(seat);
          if (uId != _userId) {
            _activeRemoteUserIds.add(uId);
          }
        }
      });
    }

    _syncSeatNotifiers();
    notifyListeners();
  }

  /// Atomically adds a new participant (e.g. user_joined) and increments viewer count.
  void addParticipant(OmniCastParticipant participant) {
    final idx = _viewers.indexWhere((p) => p.userId == participant.userId);
    if (idx >= 0) {
      _viewers[idx] = participant;
    } else {
      _viewers.insert(0, participant);
      if (_viewers.length > 200) {
        _viewers.removeLast();
      }
      _viewersCount++;
    }
    notifyListeners();
  }

  /// Atomically removes a participant (e.g. user_left) and decrements viewer count.
  void removeParticipant(String userId) {
    _viewers.removeWhere((p) => p.userId == userId);
    if (_viewersCount > 0) {
      _viewersCount--;
    }
    notifyListeners();
  }

  /// Adds a new chat message to history (capped to last 200 items).
  void addChatMessage(ChatMessage message) {
    _chatHistory.add(message);
    if (_chatHistory.length > 200) {
      _chatHistory.removeRange(0, _chatHistory.length - 200);
    }
    notifyListeners();
  }

  /// Processes a gift event, updates host coin balance, and atomically bumps active PK scores.
  void processGift(GiftEvent event) {
    _recentGifts.add(event);
    if (_recentGifts.length > 50) {
      _recentGifts.removeRange(0, _recentGifts.length - 50);
    }
    _hostCoinBalance = event.hostTotalCoins;

    // Atomically bump PK battle points if a PK is active
    if (_activePK != null && isInPKBattle) {
      final points = event.coinValue > 0
          ? (event.coinValue * event.amount)
          : event.amount;
      int newHostScore = _activePK!.hostScore;
      int newOpponentScore = _activePK!.opponentScore;

      if (event.targetUserId == _activePK!.hostUserId ||
          event.targetUserId == _hostId) {
        newHostScore += points;
      } else if (event.targetUserId == _activePK!.opponentUserId) {
        newOpponentScore += points;
      } else {
        // Default to host if no target explicitly specified
        newHostScore += points;
      }

      _activePK = PKBattleInfo(
        battleId: _activePK!.battleId,
        hostRoomId: _activePK!.hostRoomId,
        hostUserId: _activePK!.hostUserId,
        opponentRoomId: _activePK!.opponentRoomId,
        opponentUserId: _activePK!.opponentUserId,
        opponentDisplayName: _activePK!.opponentDisplayName,
        opponentAvatarUrl: _activePK!.opponentAvatarUrl,
        status: _activePK!.status,
        hostScore: newHostScore,
        opponentScore: newOpponentScore,
        durationSeconds: _activePK!.durationSeconds,
        remainingSeconds: _activePK!.remainingSeconds,
        startedAt: _activePK!.startedAt,
      );
    }

    notifyListeners();
  }

  /// Updates personal or host balance.
  void updateBalance(BalanceUpdate update) {
    if (update.userId == _userId) {
      _userCoinBalance = update.newBalance;
    }
    if (update.userId == _hostId) {
      _hostCoinBalance = update.newBalance;
    }
    notifyListeners();
  }

  /// Sets or clears the pinned stage user ID.
  void setPinnedStageUser(String? userId) {
    _pinnedStageUserId = userId;
    notifyListeners();
  }

  /// Updates real-time audio mute and camera on/off states per user.
  void updateUserMediaState(String userId, {bool? isMuted, bool? isCameraOff}) {
    if (userId.isEmpty) return;

    if (isMuted != null) {
      _userAudioMuteStates[userId] = isMuted;
    }
    if (isCameraOff != null) {
      _userCameraOffStates[userId] = isCameraOff;
    }

    // Also update any matching StageSeat
    final seatIndex = _activeSeats.indexWhere((s) => s.userId == userId);
    if (seatIndex >= 0) {
      final oldSeat = _activeSeats[seatIndex];
      _activeSeats[seatIndex] = oldSeat.copyWith(
        isMuted: isMuted ?? oldSeat.isMuted,
        isCameraOff: isCameraOff ?? oldSeat.isCameraOff,
      );
    }

    _syncSeatNotifiers();
    notifyListeners();
  }

  /// Adds or updates a stage seat.
  void updateStageSeat(StageSeat seat) {
    final idx = _activeSeats.indexWhere((s) => s.seatIndex == seat.seatIndex);
    if (idx >= 0) {
      _activeSeats[idx] = seat;
    } else {
      _activeSeats.add(seat);
    }
    if (seat.userId != null && seat.userId!.isNotEmpty) {
      if (seat.userId != _userId) {
        _activeRemoteUserIds.add(seat.userId!);
      }
      _userAudioMuteStates[seat.userId!] = seat.isMuted;
      _userCameraOffStates[seat.userId!] = seat.isCameraOff;
    }
    if (!isInPKBattle) {
      _roomMode = _activeSeats.isNotEmpty ? RoomMode.coHost : RoomMode.solo;
      roomModeNotifier.value = _roomMode;
    }
    _syncSeatNotifiers();
    notifyListeners();
  }

  /// Removes a user from a stage seat.
  void removeStageSeat(int seatIndex) {
    final idx = _activeSeats.indexWhere((s) => s.seatIndex == seatIndex);
    if (idx >= 0) {
      final removed = _activeSeats.removeAt(idx);
      if (removed.userId != null) {
        _activeRemoteUserIds.remove(removed.userId);
        _userAudioMuteStates.remove(removed.userId);
        _userCameraOffStates.remove(removed.userId);
      }
      if (!isInPKBattle) {
        _roomMode = _activeSeats.isNotEmpty ? RoomMode.coHost : RoomMode.solo;
        roomModeNotifier.value = _roomMode;
      }
      _syncSeatNotifiers();
      notifyListeners();
    }
  }

  /// Adds a pending seat request from a viewer.
  void addSeatRequest(SeatRequest request) {
    _pendingSeatRequests.removeWhere(
      (r) => r.requesterId == request.requesterId,
    );
    _pendingSeatRequests.add(request);
    notifyListeners();
  }

  /// Removes a handled seat request.
  void removeSeatRequest(String requesterId) {
    _pendingSeatRequests.removeWhere((r) => r.requesterId == requesterId);
    notifyListeners();
  }

  /// Adds a co-host invite from host.
  void addInvite(CoHostInvite invite) {
    _pendingInvites.removeWhere((i) => i.inviteId == invite.inviteId);
    _pendingInvites.add(invite);
    notifyListeners();
  }

  /// Removes a handled invite.
  void removeInvite(String inviteId) {
    _pendingInvites.removeWhere((i) => i.inviteId == inviteId);
    notifyListeners();
  }

  /// Starts or updates a PK battle.
  void updatePKBattle(PKBattleInfo pkInfo) {
    _activePK = pkInfo;
    if (pkInfo.opponentUserId.isNotEmpty) {
      _activeRemoteUserIds.add(pkInfo.opponentUserId);
    }
    _roomMode = RoomMode.pk;
    roomModeNotifier.value = RoomMode.pk;
    pkScoreNotifier.value = PkScore(
      hostScore: pkInfo.hostScore,
      opponentScore: pkInfo.opponentScore,
    );
    notifyListeners();
  }

  /// Updates PK scores in real-time.
  void updatePKScore(PKScoreUpdate scoreUpdate) {
    if (_activePK == null) return;
    _activePK = PKBattleInfo(
      battleId: _activePK!.battleId,
      hostRoomId: _activePK!.hostRoomId,
      hostUserId: _activePK!.hostUserId,
      opponentRoomId: _activePK!.opponentRoomId,
      opponentUserId: _activePK!.opponentUserId,
      opponentDisplayName: _activePK!.opponentDisplayName,
      opponentAvatarUrl: _activePK!.opponentAvatarUrl,
      status: _activePK!.status,
      hostScore: scoreUpdate.hostScore,
      opponentScore: scoreUpdate.opponentScore,
      durationSeconds: _activePK!.durationSeconds,
      remainingSeconds: _activePK!.remainingSeconds,
      startedAt: _activePK!.startedAt,
    );
    pkScoreNotifier.value = PkScore(
      hostScore: scoreUpdate.hostScore,
      opponentScore: scoreUpdate.opponentScore,
    );
    notifyListeners();
  }

  /// Updates PK remaining seconds timer tick.
  void updatePKTimer(PKTimerTick tick) {
    if (_activePK == null) return;
    _activePK = PKBattleInfo(
      battleId: _activePK!.battleId,
      hostRoomId: _activePK!.hostRoomId,
      hostUserId: _activePK!.hostUserId,
      opponentRoomId: _activePK!.opponentRoomId,
      opponentUserId: _activePK!.opponentUserId,
      opponentDisplayName: _activePK!.opponentDisplayName,
      opponentAvatarUrl: _activePK!.opponentAvatarUrl,
      status: tick.isPunishmentPhase ? PKStatus.punishment : _activePK!.status,
      hostScore: _activePK!.hostScore,
      opponentScore: _activePK!.opponentScore,
      durationSeconds: _activePK!.durationSeconds,
      remainingSeconds: tick.remainingSeconds,
      startedAt: _activePK!.startedAt,
    );
    notifyListeners();
  }

  /// Ends the active PK battle.
  void endPKBattle() {
    if (_activePK != null) {
      _activeRemoteUserIds.remove(_activePK!.opponentUserId);
      _activePK = null;
      _roomMode = _activeSeats.isNotEmpty ? RoomMode.coHost : RoomMode.solo;
      roomModeNotifier.value = _roomMode;
      pkScoreNotifier.value = const PkScore();
      notifyListeners();
    }
  }

  /// Registers an active remote user track.
  void addActiveRemoteUser(String userId) {
    _activeRemoteUserIds.add(userId);
    notifyListeners();
  }

  /// Unregisters an active remote user track.
  void removeActiveRemoteUser(String userId) {
    if (_activeRemoteUserIds.remove(userId)) {
      notifyListeners();
    }
  }

  /// Resets state when disconnecting or leaving room.
  void reset() {
    if (_isDisposed) return;
    _roomId = null;
    _hostId = null;
    _userId = null;
    _role = UserRole.viewer;
    _roomMode = RoomMode.solo;
    if (!_isDisposed) {
      try {
        roomModeNotifier.value = RoomMode.solo;
      } catch (_) {}
      try {
        pkScoreNotifier.value = const PkScore();
      } catch (_) {}
      try {
        activeSeatsNotifier.value = const [];
      } catch (_) {}
      try {
        occupiedSeatsCountNotifier.value = 0;
      } catch (_) {}
    }
    _viewersCount = 0;
    _hostCoinBalance = 0;
    _userCoinBalance = 0;
    _pinnedStageUserId = null;
    _viewers.clear();
    _activeSeats.clear();
    _activeRemoteUserIds.clear();
    _chatHistory.clear();
    _recentGifts.clear();
    _pendingSeatRequests.clear();
    _pendingInvites.clear();
    _activePK = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    try {
      roomModeNotifier.dispose();
    } catch (_) {}
    try {
      pkScoreNotifier.dispose();
    } catch (_) {}
    try {
      showJoinMessagesNotifier.dispose();
    } catch (_) {}
    try {
      activeSeatsNotifier.dispose();
    } catch (_) {}
    try {
      occupiedSeatsCountNotifier.dispose();
    } catch (_) {}
    super.dispose();
  }
}
