import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../config.dart';
import '../rps_game.dart';

class Wall extends RectangleComponent with CollisionCallbacks {
  Wall({required super.position, required super.size})
      : super(
          paint: Paint()..color = wallColor,
          children: [RectangleHitbox()],
        );
}

class Arena extends RectangleComponent
    with DragCallbacks, HasGameReference<RpsGame> {
  int? _joystickPointerId;
  Vector2? _joystickStartPos;
  Vector2 _joystickDelta = Vector2.zero();

  Arena()
      : super(
          position: Vector2.zero(),
          size: Vector2(gameWidth, gameHeight),
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  Future<void> onLoad() async {
    // Top wall
    add(Wall(
      position: Vector2.zero(),
      size: Vector2(gameWidth, wallThickness),
    ));
    // Bottom wall
    add(Wall(
      position: Vector2(0, gameHeight - wallThickness),
      size: Vector2(gameWidth, wallThickness),
    ));
    // Left wall
    add(Wall(
      position: Vector2.zero(),
      size: Vector2(wallThickness, gameHeight),
    ));
    // Right wall
    add(Wall(
      position: Vector2(gameWidth - wallThickness, 0),
      size: Vector2(wallThickness, gameHeight),
    ));

    // Arena background decoration - subtle grid lines
    add(_ArenaDecor());
  }

  @override
  void render(Canvas canvas) {
    // Draw arena background
    final bgPaint = Paint()..color = const Color(0xFF0D1117);
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

class _ArenaDecor extends PositionComponent {
  @override
  void render(Canvas canvas) {
    final linePaint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 1.0;

    // Vertical grid lines
    for (double x = wallThickness + 100;
        x < gameWidth - wallThickness;
        x += 100) {
      canvas.drawLine(
        Offset(x, wallThickness),
        Offset(x, gameHeight - wallThickness),
        linePaint,
      );
    }

    // Horizontal grid lines
    for (double y = wallThickness + 100;
        y < gameHeight - wallThickness;
        y += 100) {
      canvas.drawLine(
        Offset(wallThickness, y),
        Offset(gameWidth - wallThickness, y),
        linePaint,
      );
    }

    // Center circle
    final centerPaint = Paint()
      ..color = const Color(0x15FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      Offset(gameWidth / 2, gameHeight / 2),
      80,
      centerPaint,
    );
  }
}
