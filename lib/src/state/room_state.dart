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
  bool _isDisposed = false;

  final List<Participant> _viewers = [];
  final List<StageSeat> _activeSeats = [];
  final Set<String> _activeRemoteUserIds = {};
  final List<ChatMessage> _chatHistory = [];
  final List<GiftEvent> _recentGifts = [];
  final List<SeatRequest> _pendingSeatRequests = [];
  final List<CoHostInvite> _pendingInvites = [];
  final Map<String, bool> _userAudioMuteStates = {};
  final Map<String, bool> _userCameraOffStates = {};
  final Map<String, bool> _speakingUsers = {};

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
  final ValueNotifier<Map<String, bool>> speakingUsersNotifier =
      ValueNotifier<Map<String, bool>>({});

  // Getters
  bool get isDisposed => _isDisposed;
  bool get showJoinMessages => showJoinMessagesNotifier.value;
  set showJoinMessages(bool val) => showJoinMessagesNotifier.value = val;

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
  bool get isHostInMainSeat =>
      _pinnedStageUserId == null || _pinnedStageUserId == _hostId;
  String? get mainSeatUserId => _pinnedStageUserId ?? _hostId;

  List<Participant> get viewers => List.unmodifiable(_viewers);
  List<StageSeat> get activeSeats => List.unmodifiable(_activeSeats);
  int get occupiedSeatsCount => _activeSeats
      .where((s) => s.userId != null && s.userId!.isNotEmpty)
      .length;
  List<StageSeat> get occupiedSeats => _activeSeats
      .where((s) => s.userId != null && s.userId!.isNotEmpty)
      .toList();
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

  bool isUserAudioMuted(String userId) => _userAudioMuteStates[userId] ?? false;
  bool isUserMuted(String userId) => isUserAudioMuted(userId);
  bool isUserCameraOff(String userId) => _userCameraOffStates[userId] ?? false;
  bool isUserSpeaking(String userId) => _speakingUsers[userId] ?? false;

  StageSeat? getSeat(int seatIndex) {
    return _activeSeats.cast<StageSeat?>().firstWhere(
      (s) => s?.seatIndex == seatIndex,
      orElse: () => null,
    );
  }

  StageSeat? getSeatOfUser(String userId) {
    return _activeSeats.cast<StageSeat?>().firstWhere(
      (s) => s?.userId == userId,
      orElse: () => null,
    );
  }

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
    if (_isDisposed) return;
    _roomId = roomId;
    _userId = userId;
    _role = role;
    _roomType = roomType;
    _hostId = hostId ?? (role == UserRole.host ? userId : null);
    notifyListeners();
  }

  /// Updates connection state.
  void updateConnectionState(ClientConnectionState state) {
    if (_isDisposed || _connectionState == state) return;
    _connectionState = state;
    notifyListeners();
  }

  /// Updates user role.
  void updateRole(UserRole newRole) {
    if (_isDisposed || _role == newRole) return;
    _role = newRole;
    notifyListeners();
  }

  /// Updates room type (audio-only vs video).
  void updateRoomType(RoomType type) {
    if (_isDisposed || _roomType == type) return;
    _roomType = type;
    notifyListeners();
  }

  /// Synchronizes full room info on join or late-join (`room_info_sync`).
  void syncRoomInfo(Map<String, dynamic> data) {
    if (_isDisposed) return;
    _roomId = data['room_id'] as String? ?? _roomId;
    _hostId = data['host_id'] as String? ?? _hostId;
    final typeStr = data['room_type'] as String?;
    if (typeStr != null) {
      _roomType = typeStr.toLowerCase() == 'audio'
          ? RoomType.audio
          : RoomType.video;
    }
    _viewersCount =
        (data['viewers_count'] as num?)?.toInt() ??
        (data['viewer_count'] as num?)?.toInt() ??
        _viewersCount;
    _hostCoinBalance =
        (data['host_coin_balance'] as num?)?.toInt() ??
        (data['host_coins'] as num?)?.toInt() ??
        (data['host_score'] as num?)?.toInt() ??
        _hostCoinBalance;

    final mainSeatId = data['main_seat_id'] as String?;
    if (mainSeatId != null) {
      _pinnedStageUserId = mainSeatId == _hostId ? null : mainSeatId;
    } else if (data['pinned_user_id'] != null) {
      _pinnedStageUserId = data['pinned_user_id'] as String?;
    }

    // Populate media states map if provided first
    if (data['media_states'] is Map<String, dynamic>) {
      final states = data['media_states'] as Map<String, dynamic>;
      states.forEach((uId, stateMap) {
        if (stateMap is Map) {
          if (stateMap['muted'] != null ||
              stateMap['is_muted'] != null ||
              stateMap['muted_audio'] != null) {
            _userAudioMuteStates[uId] =
                (stateMap['muted'] ??
                        stateMap['is_muted'] ??
                        stateMap['muted_audio'])
                    as bool;
          }
          if (stateMap['camera_off'] != null ||
              stateMap['is_camera_off'] != null ||
              stateMap['is_video_muted'] != null ||
              stateMap['muted_video'] != null) {
            _userCameraOffStates[uId] =
                (stateMap['camera_off'] ??
                        stateMap['is_camera_off'] ??
                        stateMap['is_video_muted'] ??
                        stateMap['muted_video'])
                    as bool;
          }
        }
      });
    }

    // Populate active users/viewers
    if (data['viewers'] is List) {
      _viewers.clear();
      for (final item in data['viewers'] as List) {
        if (item is Map<String, dynamic>) {
          _viewers.add(Participant.fromJson(item));
        }
      }
    }

    // Populate active seats & media states
    if (data['active_seats'] is List) {
      _activeSeats.clear();
      for (final item in data['active_seats'] as List) {
        if (item is Map<String, dynamic>) {
          final seat = StageSeat.fromJson(item);
          _activeSeats.add(seat);
          if (seat.userId != null && seat.userId!.isNotEmpty) {
            if (seat.userId != _userId) {
              _activeRemoteUserIds.add(seat.userId!);
            }
            _userAudioMuteStates[seat.userId!] = seat.isMuted;
            _userCameraOffStates[seat.userId!] = seat.isCameraOff;
          }
        }
      }
    } else if (data['active_seats'] is Map) {
      final map = data['active_seats'] as Map;
      _activeSeats.clear();
      map.forEach((k, v) {
        final sIndex = int.tryParse(k.toString()) ?? 0;
        final uId = v is String
            ? v
            : (v is Map ? v['user_id']?.toString() : null);
        if (uId != null && uId.isNotEmpty) {
          if (uId != _userId) {
            _activeRemoteUserIds.add(uId);
          }
          final isMuted =
              _userAudioMuteStates[uId] ??
              (v is Map
                  ? (v['is_muted'] ?? v['muted'] ?? v['muted_audio'])
                            as bool? ??
                        false
                  : false);
          final isCamOff =
              _userCameraOffStates[uId] ??
              (v is Map
                  ? (v['is_camera_off'] ?? v['camera_off'] ?? v['muted_video'])
                            as bool? ??
                        false
                  : false);
          _activeSeats.add(
            StageSeat(
              seatIndex: sIndex,
              userId: uId,
              isMuted: isMuted,
              isCameraOff: isCamOff,
            ),
          );
        }
      });
    }

    // Populate waiting list / pending seat requests for late-join users
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

    notifyListeners();
  }

  /// Updates the viewer count and list of active viewers.
  void updateViewers({required int count, List<Participant>? viewersList}) {
    if (_isDisposed) return;
    _viewersCount = count;
    if (viewersList != null) {
      _viewers.clear();
      _viewers.addAll(viewersList.take(200));
    }
    notifyListeners();
  }

  /// Atomically adds a new participant (e.g. user_joined) and increments viewer count.
  void addParticipant(OmniCastParticipant participant) {
    if (_isDisposed) return;
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
    if (_isDisposed) return;
    _viewers.removeWhere((p) => p.userId == userId);
    if (_viewersCount > 0) {
      _viewersCount--;
    }
    notifyListeners();
  }

  /// Adds a new chat message to history (capped to last 200 items).
  void addChatMessage(ChatMessage message) {
    if (_isDisposed) return;
    _chatHistory.add(message);
    if (_chatHistory.length > 200) {
      _chatHistory.removeRange(0, _chatHistory.length - 200);
    }
    notifyListeners();
  }

  /// Processes a gift event, updates host coin balance, and atomically bumps active PK scores.
  void processGift(GiftEvent event) {
    if (_isDisposed) return;
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
    if (_isDisposed) return;
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
    if (_isDisposed) return;
    _pinnedStageUserId = userId;
    notifyListeners();
  }

  /// Updates real-time audio mute and camera on/off states per user.
  void updateUserMediaState(String userId, {bool? isMuted, bool? isCameraOff}) {
    if (_isDisposed || userId.isEmpty) return;

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

    notifyListeners();
  }

  /// Updates speaking status of a user.
  void updateUserSpeaking(String userId, bool isSpeaking) {
    if (_isDisposed || userId.isEmpty) return;
    _speakingUsers[userId] = isSpeaking;
    speakingUsersNotifier.value = Map<String, bool>.from(_speakingUsers);
    notifyListeners();
  }

  /// Updates active seats from map or list.
  void updateActiveSeats(dynamic seats) {
    if (_isDisposed) return;
    _activeSeats.clear();
    if (seats is Map) {
      seats.forEach((key, val) {
        final seatIndex = int.tryParse(key.toString()) ?? 0;
        if (val is StageSeat) {
          _activeSeats.add(val);
        } else if (val is String) {
          _activeSeats.add(
            StageSeat(
              seatIndex: seatIndex,
              userId: val,
              isMuted: _userAudioMuteStates[val] ?? false,
              isCameraOff: _userCameraOffStates[val] ?? false,
            ),
          );
        } else if (val is Map<String, dynamic>) {
          _activeSeats.add(StageSeat.fromJson(val));
        }
      });
    } else if (seats is List) {
      for (final item in seats) {
        if (item is StageSeat) {
          _activeSeats.add(item);
        } else if (item is Map<String, dynamic>) {
          _activeSeats.add(StageSeat.fromJson(item));
        }
      }
    }
    for (final seat in _activeSeats) {
      if (seat.userId != null && seat.userId!.isNotEmpty) {
        if (seat.userId != _userId) {
          _activeRemoteUserIds.add(seat.userId!);
        }
        _userAudioMuteStates[seat.userId!] = seat.isMuted;
        _userCameraOffStates[seat.userId!] = seat.isCameraOff;
      }
    }
    if (!isInPKBattle) {
      _roomMode = _activeSeats.isNotEmpty ? RoomMode.coHost : RoomMode.solo;
      roomModeNotifier.value = _roomMode;
    }
    notifyListeners();
  }

  /// Adds or updates a stage seat.
  void updateStageSeat(StageSeat seat) {
    if (_isDisposed) return;
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
    notifyListeners();
  }

  /// Removes a user from a stage seat.
  void removeStageSeat(int seatIndex) {
    if (_isDisposed) return;
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
      notifyListeners();
    }
  }

  /// Adds a pending seat request from a viewer.
  void addSeatRequest(SeatRequest request) {
    if (_isDisposed) return;
    _pendingSeatRequests.removeWhere(
      (r) => r.requesterId == request.requesterId,
    );
    _pendingSeatRequests.add(request);
    notifyListeners();
  }

  /// Removes a handled seat request.
  void removeSeatRequest(String requesterId) {
    if (_isDisposed) return;
    _pendingSeatRequests.removeWhere((r) => r.requesterId == requesterId);
    notifyListeners();
  }

  /// Adds a co-host invite from host.
  void addInvite(CoHostInvite invite) {
    if (_isDisposed) return;
    _pendingInvites.removeWhere((i) => i.inviteId == invite.inviteId);
    _pendingInvites.add(invite);
    notifyListeners();
  }

  /// Removes a handled invite.
  void removeInvite(String inviteId) {
    if (_isDisposed) return;
    _pendingInvites.removeWhere((i) => i.inviteId == inviteId);
    notifyListeners();
  }

  /// Starts or updates a PK battle.
  void updatePKBattle(PKBattleInfo pkInfo) {
    if (_isDisposed) return;
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
    if (_isDisposed || _activePK == null) return;
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
    if (_isDisposed || _activePK == null) return;
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
    if (_isDisposed) return;
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
    if (_isDisposed) return;
    if (_activeRemoteUserIds.add(userId)) {
      notifyListeners();
    }
  }

  /// Unregisters an active remote user track.
  void removeActiveRemoteUser(String userId) {
    if (_isDisposed) return;
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
    roomModeNotifier.value = RoomMode.solo;
    pkScoreNotifier.value = const PkScore();
    speakingUsersNotifier.value = {};
    _speakingUsers.clear();
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
    _userAudioMuteStates.clear();
    _userCameraOffStates.clear();
    _activePK = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    roomModeNotifier.dispose();
    pkScoreNotifier.dispose();
    speakingUsersNotifier.dispose();
    super.dispose();
  }
}
