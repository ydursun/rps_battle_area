import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../game_state.dart';

class RoomPlayer {
  final String odaId;
  final String odaAdi;
  final String odaSahibi;
  RpsType? chosenType;
  bool ready;

  RoomPlayer({
    required this.odaId,
    required this.odaAdi,
    required this.odaSahibi,
    this.chosenType,
    this.ready = false,
  });
}

class PlayerInfo {
  final String uid;
  final String displayName;
  RpsType? chosenType;
  bool ready;

  PlayerInfo({
    required this.uid,
    required this.displayName,
    this.chosenType,
    this.ready = false,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'chosenType': chosenType?.name,
        'ready': ready,
      };

  factory PlayerInfo.fromMap(Map<dynamic, dynamic> map) {
    return PlayerInfo(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Player',
      chosenType: map['chosenType'] != null
          ? RpsType.values.firstWhere(
              (t) => t.name == map['chosenType'],
              orElse: () => RpsType.rock,
            )
          : null,
      ready: map['ready'] as bool? ?? false,
    );
  }
}

class RoomData {
  final String roomCode;
  final String hostUid;
  final int maxPlayers;
  final int playerCount;
  final GameMode gameMode;
  final int timerDuration;
  final int entityCount;
  final String status; // waiting, countdown, playing, finished
  final int seed;
  final Map<String, PlayerInfo> players;

  RoomData({
    required this.roomCode,
    required this.hostUid,
    required this.maxPlayers,
    required this.playerCount,
    required this.gameMode,
    required this.timerDuration,
    required this.entityCount,
    required this.status,
    required this.seed,
    required this.players,
  });

  factory RoomData.fromMap(String code, Map<dynamic, dynamic> map) {
    final playersMap = <String, PlayerInfo>{};
    if (map['players'] != null) {
      (map['players'] as Map<dynamic, dynamic>).forEach((key, value) {
        playersMap[key as String] =
            PlayerInfo.fromMap(value as Map<dynamic, dynamic>);
      });
    }

    return RoomData(
      roomCode: code,
      hostUid: map['hostUid'] as String? ?? '',
      maxPlayers: map['maxPlayers'] as int? ?? 8,
      playerCount: map['playerCount'] as int? ?? 15,
      gameMode: map['gameMode'] == 'timed' ? GameMode.timed : GameMode.elimination,
      timerDuration: map['timerDuration'] as int? ?? 60,
      entityCount: map['entityCount'] as int? ?? 15,
      status: map['status'] as String? ?? 'waiting',
      seed: map['seed'] as int? ?? 0,
      players: playersMap,
    );
  }
}

class RoomManager {
  FirebaseDatabase get _db => FirebaseDatabase.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  String? _currentRoomCode;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _gameStateSubscription;

  String? get currentRoomCode => _currentRoomCode;
  String get currentUid => _auth.currentUser?.uid ?? '';
  String get displayName =>
      _auth.currentUser?.displayName ?? 'Oyuncu ${currentUid.substring(0, 4)}';

  // Callbacks
  void Function(RoomData)? onRoomUpdated;
  void Function(Map<String, dynamic>)? onGameStateUpdated;
  void Function(String)? onError;

  Future<void> signInAnonymously() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String> createRoom({
    required int entityCount,
    required GameMode gameMode,
    required int timerDuration,
    int maxPlayers = 8,
  }) async {
    await signInAnonymously();

    String code;
    bool exists = true;

    // Generate unique code
    do {
      code = _generateRoomCode();
      final snapshot = await _db.ref('rooms/$code').get();
      exists = snapshot.exists;
    } while (exists);

    final roomData = {
      'hostUid': currentUid,
      'maxPlayers': maxPlayers,
      'playerCount': entityCount,
      'entityCount': entityCount,
      'gameMode': gameMode == GameMode.timed ? 'timed' : 'elimination',
      'timerDuration': timerDuration,
      'status': 'waiting',
      'createdAt': ServerValue.timestamp,
      'players': {
        currentUid: PlayerInfo(
          uid: currentUid,
          displayName: displayName,
        ).toMap(),
      },
    };

    await _db.ref('rooms/$code').set(roomData);
    _currentRoomCode = code;
    _listenToRoom(code);

    return code;
  }

  Future<bool> joinRoom(String code) async {
    await signInAnonymously();

    code = code.toUpperCase().trim();
    final snapshot = await _db.ref('rooms/$code').get();

    if (!snapshot.exists) {
      onError?.call('Oda bulunamadı / Room not found');
      return false;
    }

    final data = snapshot.value as Map<dynamic, dynamic>;
    final status = data['status'] as String? ?? '';
    if (status != 'waiting') {
      onError?.call('Oyun zaten başladı / Game already started');
      return false;
    }

    final players = data['players'] as Map<dynamic, dynamic>? ?? {};
    final maxPlayers = data['maxPlayers'] as int? ?? 8;

    if (players.length >= maxPlayers) {
      onError?.call('Oda dolu / Room is full');
      return false;
    }

    // Add player to room
    await _db.ref('rooms/$code/players/$currentUid').set(
      PlayerInfo(
        uid: currentUid,
        displayName: displayName,
      ).toMap(),
    );

    _currentRoomCode = code;
    _listenToRoom(code);

    return true;
  }

  Future<void> leaveRoom() async {
    if (_currentRoomCode == null) return;

    final code = _currentRoomCode!;
    _roomSubscription?.cancel();
    _gameStateSubscription?.cancel();

    // Check if we're the host
    final snapshot = await _db.ref('rooms/$code/hostUid').get();
    final hostUid = snapshot.value as String?;

    if (hostUid == currentUid) {
      // Host leaving: delete the entire room
      await _db.ref('rooms/$code').remove();
    } else {
      // Non-host: just remove self
      await _db.ref('rooms/$code/players/$currentUid').remove();
    }

    _currentRoomCode = null;
  }

  Future<void> setPlayerReady(bool ready, {RpsType? chosenType}) async {
    if (_currentRoomCode == null) return;
    await _db.ref('rooms/$_currentRoomCode/players/$currentUid').update({
      'ready': ready,
      'chosenType': chosenType?.name,
    });
  }

  Future<void> startGame() async {
    if (_currentRoomCode == null) return;

    // Generate a shared seed and player-entity assignments
    final seed = Random().nextInt(1 << 30);
    await _db.ref('rooms/$_currentRoomCode').update({
      'status': 'countdown',
      'seed': seed,
    });

    // After 3 seconds, set to playing
    Future.delayed(const Duration(seconds: 3), () async {
      if (_currentRoomCode != null) {
        await _db.ref('rooms/$_currentRoomCode/status').set('playing');
      }
    });
  }

  Future<void> updatePlayerInput(double dx, double dy) async {
    if (_currentRoomCode == null) return;
    await _db.ref('rooms/$_currentRoomCode/inputs/$currentUid').set({
      'dx': dx,
      'dy': dy,
      'ts': ServerValue.timestamp,
    });
  }

  /// Host broadcasts compact entity states: list of [x, y, vx, vy, typeIndex]
  Future<void> broadcastEntityStates(List<List<double>> states) async {
    if (_currentRoomCode == null) return;
    await _db.ref('rooms/$_currentRoomCode/entityStates').set(states);
  }

  /// Host broadcasts game info (timer, counts, winner)
  Future<void> broadcastGameInfo(Map<String, dynamic> info) async {
    if (_currentRoomCode == null) return;
    await _db.ref('rooms/$_currentRoomCode/gameInfo').set(info);
  }

  void listenToEntityStates(void Function(List<dynamic>) callback) {
    if (_currentRoomCode == null) return;
    _gameStateSubscription?.cancel();
    _gameStateSubscription =
        _db.ref('rooms/$_currentRoomCode/entityStates').onValue.listen((event) {
      if (event.snapshot.value != null) {
        callback(event.snapshot.value as List<dynamic>);
      }
    });
  }

  StreamSubscription? _gameInfoSubscription;

  void listenToGameInfo(void Function(Map<String, dynamic>) callback) {
    if (_currentRoomCode == null) return;
    _gameInfoSubscription?.cancel();
    _gameInfoSubscription =
        _db.ref('rooms/$_currentRoomCode/gameInfo').onValue.listen((event) {
      if (event.snapshot.value != null) {
        callback(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    });
  }

  /// Host listens to all player inputs
  void listenToInputs(void Function(Map<String, dynamic>) callback) {
    if (_currentRoomCode == null) return;
    _db.ref('rooms/$_currentRoomCode/inputs').onValue.listen((event) {
      if (event.snapshot.value != null) {
        callback(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    });
  }

  Future<void> broadcastGameState(Map<String, dynamic> state) async {
    if (_currentRoomCode == null) return;
    await _db.ref('rooms/$_currentRoomCode/gameState').set(state);
  }

  void listenToGameState() {
    if (_currentRoomCode == null) return;
    _gameStateSubscription?.cancel();
    _gameStateSubscription =
        _db.ref('rooms/$_currentRoomCode/gameState').onValue.listen((event) {
      if (event.snapshot.value != null) {
        onGameStateUpdated
            ?.call(Map<String, dynamic>.from(event.snapshot.value as Map));
      }
    });
  }

  Stream<DatabaseEvent>? getInputsStream() {
    if (_currentRoomCode == null) return null;
    return _db.ref('rooms/$_currentRoomCode/inputs').onValue;
  }

  void _listenToRoom(String code) {
    _roomSubscription?.cancel();
    _roomSubscription = _db.ref('rooms/$code').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = RoomData.fromMap(
          code,
          event.snapshot.value as Map<dynamic, dynamic>,
        );
        onRoomUpdated?.call(data);
      }
    });
  }

  bool isHost(RoomData room) => room.hostUid == currentUid;

  String getRoomLink(String code) {
    // Deep link format - can be customized later
    return 'https://rpsbattle.app/room/$code';
  }

  void dispose() {
    _roomSubscription?.cancel();
    _gameStateSubscription?.cancel();
    _gameInfoSubscription?.cancel();
  }
}
