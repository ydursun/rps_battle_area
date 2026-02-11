import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../config.dart';

class _SmokeParticle {
  Vector2 offset;
  Vector2 velocity;
  double radius;
  _SmokeParticle({
    required this.offset,
    required this.velocity,
    required this.radius,
  });
}

class SmokeEffect extends PositionComponent {
  final Color color;
  double _elapsed = 0;
  final List<_SmokeParticle> _particles = [];

  SmokeEffect({
    required Vector2 position,
    required this.color,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    final rng = Random();
    for (int i = 0; i < smokeParticleCount; i++) {
      _particles.add(_SmokeParticle(
        offset: Vector2.zero(),
        velocity: Vector2(
          (rng.nextDouble() - 0.5) * 120,
          (rng.nextDouble() - 0.5) * 120,
        ),
        radius: 4 + rng.nextDouble() * 8,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= smokeEffectDuration) {
      removeFromParent();
      return;
    }
    for (final p in _particles) {
      p.offset += p.velocity * dt;
      p.velocity *= 0.95;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = _elapsed / smokeEffectDuration;
    final alpha = ((1.0 - progress) * 150).toInt().clamp(0, 255);
    final paint = Paint()..color = color.withAlpha(alpha);

    for (final p in _particles) {
      final scale = 1.0 + progress * 1.5;
      canvas.drawCircle(
        Offset(p.offset.x, p.offset.y),
        p.radius * scale,
        paint,
      );
    }
  }
}
