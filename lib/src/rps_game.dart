import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';
import 'components/arena.dart';
import 'components/power_up.dart';
import 'components/rps_entity.dart';
import 'components/smoke_effect.dart';
import 'config.dart';
import 'game_settings.dart';
import 'game_state.dart';
import 'localization.dart';
import 'multiplayer/room_manager.dart';
import 'sound_manager.dart';

class RpsGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  final GameSettings settings = GameSettings();
  late final SoundManager soundManager;
  late final RoomManager roomManager;

  bool get isFirebaseReady => DefaultFirebaseOptions.isConfigured;

  PlayState _playState = PlayState.mainMenu;
  late GameMode gameMode;

  final List<RpsEntity> entities = [];
  RpsEntity? playerEntity;
  RpsType? playerOriginalType;

  double currentSpeed = initialEntitySpeed;
  double _maxSpeed = maxEntitySpeed;
  double gameTimer = 0;
  double countdownTimer = 0;
  bool isCountingDown = false;

  int rockCount = 0;
  int paperCount = 0;
  int scissorsCount = 0;

  RpsType? winnerType;
  bool? playerWon;

  bool isMultiplayer = false;
  bool isMultiplayerHost = false;
  double _syncTimer = 0;
  static const double _syncInterval = 0.1;
  Map<String, List<double>> _remoteInputs = {};

  late Arena arena;

  final Set<LogicalKeyboardKey> _keysPressed = {};

  // Power-up system
  final List<PowerUp> activePowerUps = [];
  double _powerUpSpawnTimer = 0;
  final Random _powerUpRng = Random();

  RpsGame() {
    soundManager = SoundManager(settings: settings);
    roomManager = RoomManager();
  }

  PlayState get playState => _playState;
  set playState(PlayState state) {
    overlays.remove(_playState.name);
    overlays.remove('pauseButton');
    overlays.remove('hud');
    overlays.remove('room');

    _playState = state;

    if (state == PlayState.playing) {
      overlays.add('pauseButton');
      overlays.add('hud');
      resumeEngine();
    } else {
      overlays.add(state.name);
      if (state == PlayState.paused) {
        overlays.add('hud');
      }
      pauseEngine();
    }
  }

  void showRoomScreen() {
    overlays.remove(_playState.name);
    overlays.remove('pauseButton');
    overlays.remove('hud');
    overlays.remove('room');

    overlays.add('room');
    pauseEngine();
  }

  @override
  Future<void> onLoad() async {
    await soundManager.init();
    camera.viewfinder.visibleGameSize = Vector2(gameWidth, gameHeight);
    camera.viewfinder.position = Vector2(gameWidth / 2, gameHeight / 2);
    camera.viewfinder.anchor = Anchor.center;

    arena = Arena();
    world.add(arena);

    playState = PlayState.mainMenu;
  }

  void startGame() {
    isMultiplayer = false;
    isMultiplayerHost = false;
    _initGame(
      entityCount: settings.playerCount,
      mode: settings.gameMode,
      duration: settings.timerDuration,
      chosenType: settings.chosenType,
    );
  }

  void startMultiplayerGame(RoomData roomData) {
    isMultiplayer = true;
    isMultiplayerHost = roomData.hostUid == roomManager.currentUid;
    _syncTimer = 0;
    _remoteInputs = {};

    final myInfo = roomData.players[roomManager.currentUid];
    _initGame(
      entityCount: roomData.entityCount,
      mode: roomData.gameMode,
      duration: roomData.timerDuration,
      chosenType: myInfo?.chosenType,
      seed: roomData.seed,
      roomData: roomData,
    );

    if (isMultiplayerHost) {
      roomManager.listenToInputs((inputs) {
        _remoteInputs = {};
        inputs.forEach((uid, value) {
          if (uid != roomManager.currentUid && value is Map) {
            final m = Map<String, dynamic>.from(value);
            _remoteInputs[uid] = [
              (m['dx'] as num?)?.toDouble() ?? 0,
              (m['dy'] as num?)?.toDouble() ?? 0,
            ];
          }
        });
      });
    } else {
      roomManager.listenToEntityStates((states) {
        _applyNetworkEntityStates(states);
      });
      roomManager.listenToGameInfo((info) {
        _applyNetworkGameInfo(info);
      });
    }
  }

  void _initGame({
    required int entityCount,
    required GameMode mode,
    required int duration,
    RpsType? chosenType,
    int? seed,
    RoomData? roomData,
  }) {
    _stopGame();

    // Recreate arena
    world.remove(arena);
    arena = Arena();
    world.add(arena);

    setLanguage(settings.language);
    gameMode = mode;

    // Use speed level settings
    currentSpeed = settings.speedLevel.initialSpeed;
    _maxSpeed = settings.speedLevel.maxSpeed;

    gameTimer = gameMode == GameMode.timed ? duration.toDouble() : 0;
    winnerType = null;
    playerWon = null;

    final rng = Random(seed ?? Random().nextInt(1 << 30));

    final playerType =
        chosenType ?? RpsType.values[rng.nextInt(RpsType.values.length)];
    playerOriginalType = playerType;

    final totalCount = entityCount;
    final perType = totalCount ~/ 3;
    final remainder = totalCount % 3;

    final List<RpsType> typeList = [];
    for (int i = 0; i < perType; i++) {
      typeList.add(RpsType.rock);
    }
    for (int i = 0; i < perType; i++) {
      typeList.add(RpsType.paper);
    }
    for (int i = 0; i < perType; i++) {
      typeList.add(RpsType.scissors);
    }
    for (int i = 0; i < remainder; i++) {
      typeList.add(RpsType.values[i]);
    }
    typeList.shuffle(rng);

    final Map<String, int> playerEntityMap = {};
    if (isMultiplayer && roomData != null) {
      int assignIdx = 0;
      for (final entry in roomData.players.entries) {
        final uid = entry.key;
        final pInfo = entry.value;
        final pType = pInfo.chosenType ?? playerType;
        int foundIdx = -1;
        for (int i = assignIdx; i < typeList.length; i++) {
          if (typeList[i] == pType && !playerEntityMap.containsValue(i)) {
            foundIdx = i;
            break;
          }
        }
        if (foundIdx == -1) {
          for (int i = 0; i < typeList.length; i++) {
            if (!playerEntityMap.containsValue(i)) {
              foundIdx = i;
              typeList[i] = pType;
              break;
            }
          }
        }
        if (foundIdx != -1) {
          playerEntityMap[uid] = foundIdx;
        }
        assignIdx++;
      }
    } else {
      final playerIndex = typeList.indexWhere((t) => t == playerType);
      if (playerIndex == -1) {
        typeList[0] = playerType;
      }
    }

    final positions = _generateSpawnPositions(totalCount, rng);

    bool playerPlaced = false;
    final myUid = isMultiplayer ? roomManager.currentUid : null;

    for (int i = 0; i < totalCount; i++) {
      bool isPlayer;
      String? ownerUid;

      if (isMultiplayer) {
        final assignedUid = playerEntityMap.entries
            .where((e) => e.value == i)
            .map((e) => e.key)
            .firstOrNull;
        isPlayer = assignedUid == myUid;
        ownerUid = assignedUid;
      } else {
        isPlayer = !playerPlaced && typeList[i] == playerType;
        if (isPlayer) playerPlaced = true;
      }

      final entity = RpsEntity(
        rpsType: typeList[i],
        isHuman: isPlayer || (ownerUid != null),
        position: positions[i],
        entityId: i,
        ownerUid: ownerUid,
        entitySize: settings.entitySize,
      );

      entities.add(entity);
      world.add(entity);

      if (isPlayer) {
        playerEntity = entity;
      }
    }

    _updateCounts();

    // Speed increase timer
    if (!isMultiplayer || isMultiplayerHost) {
      world.add(TimerComponent(
        period: speedIncreaseInterval,
        repeat: true,
        onTick: _increaseSpeed,
      ));
    }

    // Power-up spawn timer
    if (settings.powerUpsEnabled && (!isMultiplayer || isMultiplayerHost)) {
      _powerUpSpawnTimer = powerUpSpawnMinInterval +
          _powerUpRng.nextDouble() *
              (powerUpSpawnMaxInterval - powerUpSpawnMinInterval);
    }

    isCountingDown = true;
    countdownTimer = 3.0;

    overlays.remove('room');

    playState = PlayState.playing;
    soundManager.playGameStart();
  }

  List<Vector2> _generateSpawnPositions(int count, Random rng) {
    final positions = <Vector2>[];
    final r = settings.entitySize.radius;
    final margin = wallThickness + r * 2;
    final minDist = r * 3;

    for (int i = 0; i < count; i++) {
      Vector2 pos;
      int attempts = 0;
      do {
        pos = Vector2(
          margin + rng.nextDouble() * (gameWidth - margin * 2),
          margin + rng.nextDouble() * (gameHeight - margin * 2),
        );
        attempts++;
      } while (
          attempts < 100 &&
          positions.any((p) => p.distanceTo(pos) < minDist));
      positions.add(pos);
    }
    return positions;
  }

  void _stopGame() {
    for (final entity in entities) {
      entity.removeFromParent();
    }
    entities.clear();
    playerEntity = null;

    // Remove power-ups
    for (final pu in activePowerUps) {
      pu.removeFromParent();
    }
    activePowerUps.clear();

    world.children
        .whereType<TimerComponent>()
        .toList()
        .forEach((t) => t.removeFromParent());

    world.children
        .whereType<SmokeEffect>()
        .toList()
        .forEach((s) => s.removeFromParent());
  }

  void _increaseSpeed() {
    if (currentSpeed < _maxSpeed) {
      currentSpeed =
          (currentSpeed + speedIncrement).clamp(0, _maxSpeed);
      for (final entity in entities) {
        entity.applySpeed(currentSpeed);
      }
    }
  }

  void onConversion(RpsEntity winner, RpsEntity loser) {
    loser.convertTo(winner.rpsType);

    world.add(SmokeEffect(
      position: loser.position.clone(),
      color: _colorForType(winner.rpsType),
    ));

    soundManager.playConversion();
    _updateCounts();
    _checkWinCondition();
  }

  Color _colorForType(RpsType type) {
    switch (type) {
      case RpsType.rock:
        return rockColor;
      case RpsType.paper:
        return paperColor;
      case RpsType.scissors:
        return scissorsColor;
    }
  }

  void _updateCounts() {
    rockCount = entities.where((e) => e.rpsType == RpsType.rock).length;
    paperCount = entities.where((e) => e.rpsType == RpsType.paper).length;
    scissorsCount =
        entities.where((e) => e.rpsType == RpsType.scissors).length;
  }

  void _checkWinCondition() {
    if (gameMode == GameMode.elimination) {
      final typesAlive = <RpsType>{};
      for (final e in entities) {
        typesAlive.add(e.rpsType);
      }
      if (typesAlive.length == 1) {
        _endGame(typesAlive.first);
      }
    }
  }

  void _endGame(RpsType winner) {
    winnerType = winner;
    playerWon = playerOriginalType == winner;

    if (playerWon!) {
      soundManager.playWin();
    } else {
      soundManager.playLose();
    }

    if (isMultiplayer && isMultiplayerHost && isFirebaseReady) {
      roomManager.broadcastGameInfo({
        'gameTimer': gameTimer,
        'rockCount': rockCount,
        'paperCount': paperCount,
        'scissorsCount': scissorsCount,
        'currentSpeed': currentSpeed,
        'winnerType': winner.index,
      });
    }

    playState = PlayState.gameOver;
  }

  void pauseGame() {
    if (_playState == PlayState.playing) {
      playState = PlayState.paused;
    }
  }

  void resumeGame() {
    if (_playState == PlayState.paused) {
      playState = PlayState.playing;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_playState != PlayState.playing) return;

    // Handle countdown
    if (isCountingDown) {
      countdownTimer -= dt;
      if (countdownTimer <= 0) {
        isCountingDown = false;
        countdownTimer = 0;
      }
      return;
    }

    _handleKeyboardInput(dt);

    if (isMultiplayer && isMultiplayerHost) {
      _applyRemoteInputs(dt);
    }

    // Timed mode
    if (!isMultiplayer || isMultiplayerHost) {
      if (gameMode == GameMode.timed) {
        gameTimer -= dt;

        if (gameTimer <= 10 && gameTimer > 0) {
          final prev = (gameTimer + dt).ceil();
          final curr = gameTimer.ceil();
          if (prev != curr) {
            soundManager.playCountdownBeep();
          }
        }

        if (gameTimer <= 0) {
          gameTimer = 0;
          _updateCounts();
          RpsType winner;
          if (rockCount >= paperCount && rockCount >= scissorsCount) {
            winner = RpsType.rock;
          } else if (paperCount >= scissorsCount) {
            winner = RpsType.paper;
          } else {
            winner = RpsType.scissors;
          }
          _endGame(winner);
        }
      }
    }

    // Power-up spawning
    if (settings.powerUpsEnabled && (!isMultiplayer || isMultiplayerHost)) {
      _updatePowerUpSpawning(dt);
    }

    // Check power-up collection by player
    if (settings.powerUpsEnabled && playerEntity != null) {
      _checkPowerUpCollection();
    }

    // Multiplayer sync
    if (isMultiplayer && isMultiplayerHost && isFirebaseReady) {
      _syncTimer += dt;
      if (_syncTimer >= _syncInterval) {
        _syncTimer = 0;
        _broadcastState();
      }
    }
  }

  void _updatePowerUpSpawning(double dt) {
    _powerUpSpawnTimer -= dt;
    if (_powerUpSpawnTimer <= 0 && activePowerUps.length < maxActivePowerUps) {
      _spawnPowerUp();
      _powerUpSpawnTimer = powerUpSpawnMinInterval +
          _powerUpRng.nextDouble() *
              (powerUpSpawnMaxInterval - powerUpSpawnMinInterval);
    }
  }

  void _spawnPowerUp() {
    final type = PowerUpType.values[_powerUpRng.nextInt(PowerUpType.values.length)];
    final margin = wallThickness + powerUpRadius * 2;
    final pos = Vector2(
      margin + _powerUpRng.nextDouble() * (gameWidth - margin * 2),
      margin + _powerUpRng.nextDouble() * (gameHeight - margin * 2),
    );

    final powerUp = PowerUp(type: type, position: pos);
    activePowerUps.add(powerUp);
    world.add(powerUp);
  }

  void _checkPowerUpCollection() {
    final player = playerEntity!;
    final collected = <PowerUp>[];

    for (final pu in activePowerUps) {
      if (pu.containsPoint(player.position)) {
        player.applyPowerUp(pu.type);
        collected.add(pu);
        soundManager.playConversion(); // Reuse conversion sound for pickup
      }
    }

    for (final pu in collected) {
      pu.removeFromParent();
      activePowerUps.remove(pu);
    }
  }

  void _applyRemoteInputs(double dt) {
    for (final entry in _remoteInputs.entries) {
      final uid = entry.key;
      final input = entry.value;
      final entity = entities.where((e) => e.ownerUid == uid).firstOrNull;
      if (entity == null) continue;

      final dx = input[0];
      final dy = input[1];
      if (dx != 0 || dy != 0) {
        final dir = Vector2(dx, dy).normalized();
        entity.velocity = dir * currentSpeed;
      } else {
        entity.velocity *= 0.92;
        if (entity.velocity.length < 5) {
          entity.velocity = Vector2.zero();
        }
      }
    }
  }

  void _broadcastState() {
    final states = <List<double>>[];
    for (final entity in entities) {
      states.add(entity.getNetworkState());
    }
    roomManager.broadcastEntityStates(states);

    roomManager.broadcastGameInfo({
      'gameTimer': gameTimer,
      'rockCount': rockCount,
      'paperCount': paperCount,
      'scissorsCount': scissorsCount,
      'currentSpeed': currentSpeed,
      if (winnerType != null) 'winnerType': winnerType!.index,
    });
  }

  void _applyNetworkEntityStates(List<dynamic> states) {
    for (int i = 0; i < states.length && i < entities.length; i++) {
      final s = states[i];
      if (s is List) {
        final x = (s[0] as num).toDouble();
        final y = (s[1] as num).toDouble();
        final vx = (s[2] as num).toDouble();
        final vy = (s[3] as num).toDouble();
        final typeIdx = (s[4] as num).toInt();
        entities[i].applyNetworkState(x, y, vx, vy, typeIdx);
      }
    }
    _updateCounts();
  }

  void _applyNetworkGameInfo(Map<String, dynamic> info) {
    if (info.containsKey('gameTimer')) {
      gameTimer = (info['gameTimer'] as num).toDouble();
    }
    if (info.containsKey('rockCount')) {
      rockCount = (info['rockCount'] as num).toInt();
    }
    if (info.containsKey('paperCount')) {
      paperCount = (info['paperCount'] as num).toInt();
    }
    if (info.containsKey('scissorsCount')) {
      scissorsCount = (info['scissorsCount'] as num).toInt();
    }
    if (info.containsKey('currentSpeed')) {
      currentSpeed = (info['currentSpeed'] as num).toDouble();
    }
    if (info.containsKey('winnerType') && winnerType == null) {
      final winner = RpsType.values[info['winnerType'] as int];
      _endGame(winner);
    }
  }

  void _handleKeyboardInput(double dt) {
    if (playerEntity == null) return;

    double dx = 0;
    double dy = 0;

    if (_keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        _keysPressed.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        _keysPressed.contains(LogicalKeyboardKey.keyS)) {
      dy += 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        _keysPressed.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        _keysPressed.contains(LogicalKeyboardKey.keyD)) {
      dx += 1;
    }

    final speedMult = playerEntity!.activePowerUp == PowerUpType.speedBoost
        ? speedBoostMultiplier
        : 1.0;

    if (dx != 0 || dy != 0) {
      final dir = Vector2(dx, dy).normalized();
      playerEntity!.velocity = dir * currentSpeed * speedMult;
    } else {
      playerEntity!.velocity *= 0.92;
      if (playerEntity!.velocity.length < 5) {
        playerEntity!.velocity = Vector2.zero();
      }
    }

    if (isMultiplayer && isFirebaseReady) {
      roomManager.updatePlayerInput(dx, dy);
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keysPressed.clear();
    _keysPressed.addAll(keysPressed);

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (_playState == PlayState.playing) {
        pauseGame();
        return KeyEventResult.handled;
      } else if (_playState == PlayState.paused) {
        resumeGame();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Color backgroundColor() => settings.customBgColor;
}
