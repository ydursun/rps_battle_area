import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
// PaintingStyle is from dart:ui

import '../config.dart';
import '../rps_game.dart';

/// Inner wall obstacle that entities bounce off of
class InnerWall extends RectangleComponent with CollisionCallbacks {
  InnerWall({
    required super.position,
    required super.size,
    required Color color,
    double rotation = 0,
  }) : super(
          paint: Paint()..color = color,
          angle: rotation,
          anchor: Anchor.center,
          children: [RectangleHitbox()],
        );
}

/// Mud zone - slows entities and adds random angle deviation
class MudZone extends CircleComponent with HasGameReference<RpsGame> {
  final double zoneRadius;

  MudZone({
    required Vector2 position,
    required this.zoneRadius,
  }) : super(
          position: position,
          radius: zoneRadius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  void render(Canvas canvas) {
    // Brown muddy circle
    final mudPaint = Paint()..color = const Color(0x40664422);
    canvas.drawCircle(Offset.zero, zoneRadius, mudPaint);

    // Darker border
    final borderPaint = Paint()
      ..color = const Color(0x30553311)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, zoneRadius, borderPaint);

    // Small mud spots inside
    final spotPaint = Paint()..color = const Color(0x25553311);
    final rng = Random(position.x.toInt() ^ position.y.toInt());
    for (int i = 0; i < 5; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * zoneRadius * 0.6;
      final r = 4.0 + rng.nextDouble() * 8;
      canvas.drawCircle(
        Offset(cos(angle) * dist, sin(angle) * dist),
        r,
        spotPaint,
      );
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= zoneRadius;
  }
}

/// Teleport zone - comes in pairs, entities entering one exit the other
class TeleportZone extends CircleComponent with HasGameReference<RpsGame> {
  TeleportZone? linkedPortal;
  final bool isEntrance; // true = blue, false = orange
  double cooldownTimer = 0;
  double _animPhase = 0;

  TeleportZone({
    required Vector2 position,
    required this.isEntrance,
  }) : super(
          position: position,
          radius: teleportZoneRadius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (cooldownTimer > 0) cooldownTimer -= dt;
    _animPhase += dt * 3.0;
  }

  @override
  void render(Canvas canvas) {
    final baseColor =
        isEntrance ? const Color(0xFF4488FF) : const Color(0xFFFF8844);
    final pulseAlpha = (40 + (sin(_animPhase) * 20)).toInt().clamp(20, 60);

    // Outer glow
    final glowPaint = Paint()..color = baseColor.withAlpha(pulseAlpha);
    canvas.drawCircle(Offset.zero, teleportZoneRadius, glowPaint);

    // Inner ring
    final ringPaint = Paint()
      ..color = baseColor.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(Offset.zero, teleportZoneRadius * 0.7, ringPaint);

    // Center dot
    final centerPaint = Paint()..color = baseColor.withAlpha(180);
    canvas.drawCircle(Offset.zero, 6.0, centerPaint);

    // Rotating particles
    for (int i = 0; i < 4; i++) {
      final angle = _animPhase + i * pi / 2;
      final px = cos(angle) * teleportZoneRadius * 0.5;
      final py = sin(angle) * teleportZoneRadius * 0.5;
      canvas.drawCircle(Offset(px, py), 3.0, centerPaint);
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= teleportZoneRadius;
  }

  bool get isReady => cooldownTimer <= 0;
}

/// Bush zone - entities inside become hidden from AI detection
class BushZone extends CircleComponent with HasGameReference<RpsGame> {
  final double zoneRadius;

  BushZone({
    required Vector2 position,
    required this.zoneRadius,
  }) : super(
          position: position,
          radius: zoneRadius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  void render(Canvas canvas) {
    // Green bush background
    final bushPaint = Paint()..color = const Color(0x30228B22);
    canvas.drawCircle(Offset.zero, zoneRadius, bushPaint);

    // Bush border
    final borderPaint = Paint()
      ..color = const Color(0x40006400)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, zoneRadius, borderPaint);

    // Leaf-like spots
    final leafPaint = Paint()..color = const Color(0x35228B22);
    final rng = Random(position.x.toInt() * 31 + position.y.toInt());
    for (int i = 0; i < 8; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final dist = rng.nextDouble() * zoneRadius * 0.7;
      final r = 6.0 + rng.nextDouble() * 10;
      canvas.drawCircle(
        Offset(cos(angle) * dist, sin(angle) * dist),
        r,
        leafPaint,
      );
    }
  }

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= zoneRadius;
  }
}
