import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../config.dart';
import '../game_state.dart';
import '../rps_game.dart';
import 'arena_obstacle.dart';

class Wall extends RectangleComponent with CollisionCallbacks {
  Wall({required super.position, required super.size, required Color color})
      : super(
          paint: Paint()..color = color,
          children: [RectangleHitbox()],
        );
}

class Arena extends RectangleComponent
    with DragCallbacks, HasGameReference<RpsGame> {
  int? _joystickPointerId;
  Vector2? _joystickStartPos;
  Vector2 _joystickDelta = Vector2.zero();

  late Color _bgColor;
  late Color _wallColor;

  final List<InnerWall> innerWalls = [];
  final List<MudZone> mudZones = [];
  final List<TeleportZone> teleportZones = [];
  final List<BushZone> bushZones = [];

  Arena()
      : super(
          position: Vector2.zero(),
          size: Vector2(gameWidth, gameHeight),
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  Future<void> onLoad() async {
    _bgColor = game.settings.customBgColor;
    _wallColor = game.settings.customWallColor;

    // Boundary walls
    add(Wall(
      position: Vector2.zero(),
      size: Vector2(gameWidth, wallThickness),
      color: _wallColor,
    ));
    add(Wall(
      position: Vector2(0, gameHeight - wallThickness),
      size: Vector2(gameWidth, wallThickness),
      color: _wallColor,
    ));
    add(Wall(
      position: Vector2.zero(),
      size: Vector2(wallThickness, gameHeight),
      color: _wallColor,
    ));
    add(Wall(
      position: Vector2(gameWidth - wallThickness, 0),
      size: Vector2(wallThickness, gameHeight),
      color: _wallColor,
    ));

    // Spawn arena obstacles based on settings
    final seed = DateTime.now().millisecondsSinceEpoch;
    final rng = Random(seed);

    _spawnInnerWalls(rng);
    _spawnMudZones(rng);
    _spawnTeleportZones(rng);
    _spawnBushZones(rng);
  }

  void _spawnInnerWalls(Random rng) {
    final amount = game.settings.wallAmount;
    if (amount == ObstacleAmount.none) return;

    final count = switch (amount) {
      ObstacleAmount.low => 3 + rng.nextInt(2),
      ObstacleAmount.medium => 6 + rng.nextInt(3),
      ObstacleAmount.high => 10 + rng.nextInt(5),
      ObstacleAmount.none => 0,
    };

    final margin = wallThickness + 80;
    for (int i = 0; i < count; i++) {
      final length = innerWallMinLength +
          rng.nextDouble() * (innerWallMaxLength - innerWallMinLength);
      final rotation = rng.nextDouble() * pi;
      final pos = Vector2(
        margin + rng.nextDouble() * (gameWidth - margin * 2),
        margin + rng.nextDouble() * (gameHeight - margin * 2),
      );

      final wall = InnerWall(
        position: pos,
        size: Vector2(length, innerWallWidth),
        color: _wallColor.withAlpha(200),
        rotation: rotation,
      );
      innerWalls.add(wall);
      add(wall);
    }
  }

  void _spawnMudZones(Random rng) {
    final amount = game.settings.mudAmount;
    if (amount == ObstacleAmount.none) return;

    final count = switch (amount) {
      ObstacleAmount.low => 2 + rng.nextInt(2),
      ObstacleAmount.medium => 4 + rng.nextInt(3),
      ObstacleAmount.high => 8 + rng.nextInt(3),
      ObstacleAmount.none => 0,
    };

    final margin = wallThickness + mudZoneMaxRadius;
    for (int i = 0; i < count; i++) {
      final radius = mudZoneMinRadius +
          rng.nextDouble() * (mudZoneMaxRadius - mudZoneMinRadius);
      final pos = Vector2(
        margin + rng.nextDouble() * (gameWidth - margin * 2),
        margin + rng.nextDouble() * (gameHeight - margin * 2),
      );

      final zone = MudZone(position: pos, zoneRadius: radius);
      mudZones.add(zone);
      add(zone);
    }
  }

  void _spawnTeleportZones(Random rng) {
    if (!game.settings.teleportEnabled) return;

    final pairCount = 2 + rng.nextInt(2); // 2-3 pairs
    final margin = wallThickness + teleportZoneRadius * 2;

    for (int i = 0; i < pairCount; i++) {
      final pos1 = Vector2(
        margin + rng.nextDouble() * (gameWidth - margin * 2),
        margin + rng.nextDouble() * (gameHeight - margin * 2),
      );
      final pos2 = Vector2(
        margin + rng.nextDouble() * (gameWidth - margin * 2),
        margin + rng.nextDouble() * (gameHeight - margin * 2),
      );

      final entrance = TeleportZone(position: pos1, isEntrance: true);
      final exit = TeleportZone(position: pos2, isEntrance: false);
      entrance.linkedPortal = exit;
      exit.linkedPortal = entrance;

      teleportZones.add(entrance);
      teleportZones.add(exit);
      add(entrance);
      add(exit);
    }
  }

  void _spawnBushZones(Random rng) {
    final amount = game.settings.bushAmount;
    if (amount == ObstacleAmount.none) return;

    final count = switch (amount) {
      ObstacleAmount.low => 2 + rng.nextInt(2),
      ObstacleAmount.medium => 4 + rng.nextInt(2),
      ObstacleAmount.high => 6 + rng.nextInt(3),
      ObstacleAmount.none => 0,
    };

    final margin = wallThickness + bushZoneMaxRadius;
    for (int i = 0; i < count; i++) {
      final radius = bushZoneMinRadius +
          rng.nextDouble() * (bushZoneMaxRadius - bushZoneMinRadius);
      final pos = Vector2(
        margin + rng.nextDouble() * (gameWidth - margin * 2),
        margin + rng.nextDouble() * (gameHeight - margin * 2),
      );

      final zone = BushZone(position: pos, zoneRadius: radius);
      bushZones.add(zone);
      add(zone);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw arena background (plain color, no pattern)
    final bgPaint = Paint()..color = _bgColor;
    canvas.drawRect(
      Rect.fromLTWH(
        wallThickness,
        wallThickness,
        gameWidth - wallThickness * 2,
        gameHeight - wallThickness * 2,
      ),
      bgPaint,
    );
    super.render(canvas);
  }

  // --- Touch input for mobile joystick ---
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_joystickPointerId == null) {
      _joystickPointerId = event.pointerId;
      _joystickStartPos = event.localPosition.clone();
      _joystickDelta = Vector2.zero();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (event.pointerId == _joystickPointerId && _joystickStartPos != null) {
      _joystickDelta = event.localEndPosition - _joystickStartPos!;
      if (_joystickDelta.length > 50) {
        _joystickDelta = _joystickDelta.normalized() * 50;
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (event.pointerId == _joystickPointerId) {
      _joystickPointerId = null;
      _joystickStartPos = null;
      _joystickDelta = Vector2.zero();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_joystickDelta.length > 5 && game.playerEntity != null) {
      game.playerEntity!.velocity =
          _joystickDelta.normalized() * game.currentSpeed;
    }
  }

  Vector2 get joystickDelta => _joystickDelta;
  Vector2? get joystickStartPos => _joystickStartPos;
}
