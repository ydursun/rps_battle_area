import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, PaintingStyle;

import '../config.dart';
import '../game_state.dart';
import '../rps_game.dart';

class RpsEntity extends CircleComponent
    with CollisionCallbacks, HasGameReference<RpsGame> {
  RpsType rpsType;
  final bool isHuman;
  final int entityId;
  String? ownerUid; // UID of controlling player (for multiplayer)
  Vector2 velocity = Vector2.zero();
  double conversionImmunity = 0;

  double _aiDecisionTimer = 0;
  final Random _rng = Random();

  // Cached text painters for emoji rendering
  TextPainter? _emojiPainter;
  RpsType? _cachedEmojiType;

  // Triangle bob animation
  double _trianglePhase = 0;

  late final double _radius;
  late final double _emojiFontSize;

  RpsEntity({
    required this.rpsType,
    required this.isHuman,
    required Vector2 position,
    this.entityId = 0,
    this.ownerUid,
    EntitySize entitySize = EntitySize.mid,
  })  : _radius = entitySize.radius,
        _emojiFontSize = entitySize.fontSize,
        super(
          radius: entitySize.radius,
          position: position,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0x00000000), // invisible fill
        );

  static String _emojiForType(RpsType type) {
    switch (type) {
      case RpsType.rock:
        return '🪨';
      case RpsType.paper:
        return '📄';
      case RpsType.scissors:
        return '✂️';
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox());
    final angle = _rng.nextDouble() * 2 * pi;
    velocity = Vector2(cos(angle), sin(angle)) * game.currentSpeed;
    _buildEmojiPainter();
  }

  void _buildEmojiPainter() {
    if (_cachedEmojiType == rpsType && _emojiPainter != null) return;
    _cachedEmojiType = rpsType;
    _emojiPainter = TextPainter(
      text: TextSpan(
        text: _emojiForType(rpsType),
        style: TextStyle(fontSize: _emojiFontSize),
      ),
      textDirection: TextDirection.ltr,
    );
    _emojiPainter!.layout();
  }

  void _updateVisual() {
    _buildEmojiPainter();
  }

  @override
  void render(Canvas canvas) {
    // Draw player glow ring (subtle, behind emoji)
    if (isHuman) {
      final glowPaint = Paint()
        ..color = playerGlowColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset.zero, _radius + 2, glowPaint);
    }

    // Draw emoji icon only (no circle background)
    if (_emojiPainter != null) {
      _emojiPainter!.paint(
        canvas,
        Offset(-_emojiPainter!.width / 2, -_emojiPainter!.height / 2),
      );
    }

    // Draw red triangle above player (FIFA style indicator)
    if (isHuman) {
      _drawPlayerTriangle(canvas);
    }
  }

  void _drawPlayerTriangle(Canvas canvas) {
    final bobOffset = sin(_trianglePhase) * 3.0;
    final triangleY = -_radius - 14 + bobOffset;

    final path = Path();
    const halfWidth = 7.0;
    const height = 10.0;
    // Triangle pointing down
    path.moveTo(-halfWidth, triangleY - height);
    path.lineTo(halfWidth, triangleY - height);
    path.lineTo(0, triangleY);
    path.close();

    final fillPaint = Paint()..color = const Color(0xFFFF0000);
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFCC0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    // Animate triangle bob
    if (isHuman) {
      _trianglePhase += dt * 4.0;
    }

    // Non-host multiplayer clients: skip local physics, state comes from network
    if (game.isMultiplayer && !game.isMultiplayerHost) {
      return;
    }

    // Decrement conversion immunity
    if (conversionImmunity > 0) {
      conversionImmunity -= dt;
    }

    // AI behavior (only for non-human entities)
    if (!isHuman) {
      _updateAI(dt);
    }

    // Apply velocity
    position += velocity * dt;

    // Clamp to arena bounds with bounce
    _clampToArena();
  }

  void _clampToArena() {
    final minX = wallThickness + _radius;
    final maxX = gameWidth - wallThickness - _radius;
    final minY = wallThickness + _radius;
    final maxY = gameHeight - wallThickness - _radius;

    if (position.x < minX) {
      position.x = minX;
      velocity.x = velocity.x.abs();
      game.soundManager.playWallHit();
    }
    if (position.x > maxX) {
      position.x = maxX;
      velocity.x = -velocity.x.abs();
      game.soundManager.playWallHit();
    }
    if (position.y < minY) {
      position.y = minY;
      velocity.y = velocity.y.abs();
      game.soundManager.playWallHit();
    }
    if (position.y > maxY) {
      position.y = maxY;
      velocity.y = -velocity.y.abs();
      game.soundManager.playWallHit();
    }
  }

  // --- AI Logic ---
  void _updateAI(double dt) {
    _aiDecisionTimer -= dt;
    if (_aiDecisionTimer > 0) return;
    _aiDecisionTimer = aiDecisionInterval + _rng.nextDouble() * 0.2;

    RpsEntity? nearestThreat;
    double nearestThreatDist = double.infinity;
    RpsEntity? nearestPrey;
    double nearestPreyDist = double.infinity;

    for (final other in game.entities) {
      if (other == this) continue;
      final dist = position.distanceTo(other.position);
      if (dist > aiDetectionRadius) continue;

      if (other.rpsType.winsAgainst(rpsType)) {
        if (dist < nearestThreatDist) {
          nearestThreat = other;
          nearestThreatDist = dist;
        }
      } else if (rpsType.winsAgainst(other.rpsType)) {
        if (dist < nearestPreyDist) {
          nearestPrey = other;
          nearestPreyDist = dist;
        }
      }
    }

    if (nearestThreat != null &&
        nearestThreatDist < aiDetectionRadius * 0.6) {
      // FLEE
      final dir = (position - nearestThreat.position).normalized();
      velocity = dir * game.currentSpeed * aiFleeMultiplier;
    } else if (nearestPrey != null) {
      // CHASE
      final dir = (nearestPrey.position - position).normalized();
      velocity = dir * game.currentSpeed * aiChaseMultiplier;
    } else {
      // WANDER
      final wanderAngle =
          (_rng.nextDouble() - 0.5) * pi * aiRandomWanderStrength;
      final currentAngle = atan2(velocity.y, velocity.x);
      final newAngle = currentAngle + wanderAngle;
      velocity = Vector2(cos(newAngle), sin(newAngle)) * game.currentSpeed;
    }
  }

  // --- Collision ---
  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is RpsEntity) {
      _handleEntityCollision(other);
    }
  }

  void _handleEntityCollision(RpsEntity other) {
    // Non-host clients don't process collisions (host is authoritative)
    if (game.isMultiplayer && !game.isMultiplayerHost) return;

    if (conversionImmunity > 0 || other.conversionImmunity > 0) return;

    if (rpsType == other.rpsType) {
      _nudgeApart(other);
      return;
    }

    if (rpsType.winsAgainst(other.rpsType)) {
      game.onConversion(this, other);
    }
  }

  void _nudgeApart(RpsEntity other) {
    final diff = position - other.position;
    if (diff.length < 0.01) {
      position.add(Vector2(1, 0));
    } else {
      final pushDir = diff.normalized() * 2.0;
      position.add(pushDir);
      other.position.sub(pushDir);
    }
  }

  void convertTo(RpsType newType) {
    rpsType = newType;
    conversionImmunity = conversionCooldown;
    _updateVisual();
  }

  void applySpeed(double speed) {
    if (velocity.length > 0) {
      velocity = velocity.normalized() * speed;
    }
  }

  /// Apply state received from the host (for non-host multiplayer clients)
  void applyNetworkState(double x, double y, double vx, double vy, int typeIdx) {
    final newType = RpsType.values[typeIdx];
    if (newType != rpsType) {
      convertTo(newType);
    }
    position.setValues(x, y);
    velocity.setValues(vx, vy);
  }

  /// Get compact state for network broadcast (host sends this)
  List<double> getNetworkState() {
    return [position.x, position.y, velocity.x, velocity.y, rpsType.index.toDouble()];
  }
}
