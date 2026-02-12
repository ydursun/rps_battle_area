import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show TextPainter, TextSpan, TextStyle, PaintingStyle;

import '../config.dart';
import '../game_state.dart';
import '../rps_game.dart';
import 'arena_obstacle.dart';

class RpsEntity extends CircleComponent
    with CollisionCallbacks, HasGameReference<RpsGame> {
  RpsType rpsType;
  final bool isHuman;
  final int entityId;
  String? ownerUid;
  Vector2 velocity = Vector2.zero();
  double conversionImmunity = 0;

  double _aiDecisionTimer = 0;
  final Random _rng = Random();

  TextPainter? _emojiPainter;
  RpsType? _cachedEmojiType;

  double _trianglePhase = 0;

  late final double _radius;
  late final double _emojiFontSize;

  // Zone states
  bool isInMud = false;
  bool isInBush = false;
  double _teleportCooldown = 0;

  // Power-up state
  PowerUpType? activePowerUp;
  double powerUpTimer = 0;

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
          paint: Paint()..color = const Color(0x00000000),
        );

  static String _emojiForType(RpsType type) {
    switch (type) {
      case RpsType.rock:
        return '\u{1FAA8}';
      case RpsType.paper:
        return '\u{1F4C4}';
      case RpsType.scissors:
        return '\u{2702}\u{FE0F}';
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
    // Opacity for bush hiding
    final alpha = isInBush && !_isLocalPlayer ? 0.3 : 1.0;

    if (alpha < 1.0) {
      canvas.saveLayer(null, Paint()..color = Color.fromARGB((alpha * 255).toInt(), 255, 255, 255));
    }

    // Shield effect
    if (activePowerUp == PowerUpType.shield) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF4488FF).withAlpha(60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(Offset.zero, _radius + 6, shieldPaint);
      final shieldFill = Paint()..color = const Color(0xFF4488FF).withAlpha(20);
      canvas.drawCircle(Offset.zero, _radius + 6, shieldFill);
    }

    // Speed boost effect
    if (activePowerUp == PowerUpType.speedBoost) {
      final boostPaint = Paint()
        ..color = const Color(0xFFFFCC00).withAlpha(40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset.zero, _radius + 4, boostPaint);
    }

    // Player glow ring
    if (isHuman) {
      final glowPaint = Paint()
        ..color = playerGlowColor.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(Offset.zero, _radius + 2, glowPaint);
    }

    // Emoji
    if (_emojiPainter != null) {
      _emojiPainter!.paint(
        canvas,
        Offset(-_emojiPainter!.width / 2, -_emojiPainter!.height / 2),
      );
    }

    // Player triangle
    if (isHuman) {
      _drawPlayerTriangle(canvas);
    }

    if (alpha < 1.0) {
      canvas.restore();
    }
  }

  bool get _isLocalPlayer {
    if (!game.isMultiplayer) return isHuman;
    return ownerUid == game.roomManager.currentUid;
  }

  void _drawPlayerTriangle(Canvas canvas) {
    final bobOffset = sin(_trianglePhase) * 3.0;
    final triangleY = -_radius - 14 + bobOffset;

    final path = Path();
    const halfWidth = 7.0;
    const height = 10.0;
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

    if (isHuman) {
      _trianglePhase += dt * 4.0;
    }

    // Non-host multiplayer clients: skip local physics
    if (game.isMultiplayer && !game.isMultiplayerHost) {
      return;
    }

    // Decrement cooldowns
    if (conversionImmunity > 0) {
      conversionImmunity -= dt;
    }
    if (_teleportCooldown > 0) {
      _teleportCooldown -= dt;
    }

    // Power-up timer
    if (activePowerUp != null) {
      powerUpTimer -= dt;
      if (activePowerUp == PowerUpType.shield) {
        conversionImmunity = 0.5; // Keep immune while shield active
      }
      if (powerUpTimer <= 0) {
        activePowerUp = null;
        powerUpTimer = 0;
      }
    }

    // AI behavior
    if (!isHuman) {
      _updateAI(dt);
    }

    // Apply velocity
    position += velocity * dt;

    // Check zone interactions
    _checkZones();

    // Clamp to arena bounds with bounce
    _clampToArena();
  }

  void _checkZones() {
    final arena = game.arena;

    // Mud zones
    isInMud = false;
    for (final mud in arena.mudZones) {
      if (mud.containsPoint(position)) {
        isInMud = true;
        // Slow down
        if (velocity.length > game.currentSpeed * mudSpeedMultiplier) {
          velocity = velocity.normalized() * game.currentSpeed * mudSpeedMultiplier;
        }
        // Random angle deviation
        final angle = atan2(velocity.y, velocity.x);
        final deviation = (_rng.nextDouble() - 0.5) * mudAngleDeviation;
        final newAngle = angle + deviation;
        final speed = velocity.length;
        velocity = Vector2(cos(newAngle), sin(newAngle)) * speed;
        break;
      }
    }

    // Bush zones
    isInBush = false;
    for (final bush in arena.bushZones) {
      if (bush.containsPoint(position)) {
        isInBush = true;
        break;
      }
    }

    // Teleport zones
    if (_teleportCooldown <= 0) {
      for (final portal in arena.teleportZones) {
        if (portal.containsPoint(position) &&
            portal.isReady &&
            portal.linkedPortal != null) {
          final target = portal.linkedPortal!;
          position.setFrom(target.position);
          _teleportCooldown = teleportCooldown;
          target.cooldownTimer = teleportCooldown;
          portal.cooldownTimer = teleportCooldown;
          break;
        }
      }
    }
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

    // Bounce off inner walls
    for (final wall in game.arena.innerWalls) {
      _bounceOffInnerWall(wall);
    }
  }

  void _bounceOffInnerWall(InnerWall wall) {
    // Simple AABB check against the rotated wall
    final wallCenter = wall.position;
    final halfW = wall.size.x / 2;
    final halfH = wall.size.y / 2;
    final cosA = cos(-wall.angle);
    final sinA = sin(-wall.angle);

    // Transform entity position to wall's local space
    final dx = position.x - wallCenter.x;
    final dy = position.y - wallCenter.y;
    final localX = dx * cosA - dy * sinA;
    final localY = dx * sinA + dy * cosA;

    // Check if entity overlaps the wall rect in local space
    final closestX = localX.clamp(-halfW, halfW);
    final closestY = localY.clamp(-halfH, halfH);
    final distX = localX - closestX;
    final distY = localY - closestY;
    final dist = sqrt(distX * distX + distY * distY);

    if (dist < _radius && dist > 0.01) {
      // Push entity out and reflect velocity
      final normalLocalX = distX / dist;
      final normalLocalY = distY / dist;

      // Transform normal back to world space
      final cosB = cos(wall.angle);
      final sinB = sin(wall.angle);
      final worldNX = normalLocalX * cosB - normalLocalY * sinB;
      final worldNY = normalLocalX * sinB + normalLocalY * cosB;

      // Push out
      final overlap = _radius - dist;
      position.x += worldNX * overlap;
      position.y += worldNY * overlap;

      // Reflect velocity
      final dot = velocity.x * worldNX + velocity.y * worldNY;
      velocity.x -= 2 * dot * worldNX;
      velocity.y -= 2 * dot * worldNY;
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

    final detectionRadius = aiDetectionRadius;

    for (final other in game.entities) {
      if (other == this) continue;

      // Hidden entities in bush are only visible within close range
      if (other.isInBush) {
        final dist = position.distanceTo(other.position);
        if (dist > bushHiddenDetectionRadius) continue;
      }

      final dist = position.distanceTo(other.position);
      if (dist > detectionRadius) continue;

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

    final speedMult = activePowerUp == PowerUpType.speedBoost
        ? speedBoostMultiplier
        : 1.0;

    if (nearestThreat != null &&
        nearestThreatDist < detectionRadius * 0.6) {
      final dir = (position - nearestThreat.position).normalized();
      velocity = dir * game.currentSpeed * aiFleeMultiplier * speedMult;
    } else if (nearestPrey != null) {
      final dir = (nearestPrey.position - position).normalized();
      velocity = dir * game.currentSpeed * aiChaseMultiplier * speedMult;
    } else {
      final wanderAngle =
          (_rng.nextDouble() - 0.5) * pi * aiRandomWanderStrength;
      final currentAngle = atan2(velocity.y, velocity.x);
      final newAngle = currentAngle + wanderAngle;
      velocity =
          Vector2(cos(newAngle), sin(newAngle)) * game.currentSpeed * speedMult;
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
    if (game.isMultiplayer && !game.isMultiplayerHost) return;

    if (conversionImmunity > 0 || other.conversionImmunity > 0) return;

    // Shield protects from conversion
    if (other.activePowerUp == PowerUpType.shield) return;

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
      final mult = activePowerUp == PowerUpType.speedBoost
          ? speedBoostMultiplier
          : 1.0;
      velocity = velocity.normalized() * speed * mult;
    }
  }

  void applyPowerUp(PowerUpType type) {
    activePowerUp = type;
    powerUpTimer = type.duration;
  }

  void applyNetworkState(double x, double y, double vx, double vy, int typeIdx) {
    final newType = RpsType.values[typeIdx];
    if (newType != rpsType) {
      convertTo(newType);
    }
    position.setValues(x, y);
    velocity.setValues(vx, vy);
  }

  List<double> getNetworkState() {
    return [position.x, position.y, velocity.x, velocity.y, rpsType.index.toDouble()];
  }
}
