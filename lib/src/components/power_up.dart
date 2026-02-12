import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show TextPainter, TextSpan, TextStyle, TextDirection, PaintingStyle;

import '../config.dart';
import '../game_state.dart';
import '../rps_game.dart';

class PowerUp extends CircleComponent with HasGameReference<RpsGame> {
  final PowerUpType type;
  double _animPhase = 0;
  late final TextPainter _emojiPainter;

  PowerUp({
    required this.type,
    required Vector2 position,
  }) : super(
          position: position,
          radius: powerUpRadius,
          anchor: Anchor.center,
          paint: Paint()..color = const Color(0x00000000),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _emojiPainter = TextPainter(
      text: TextSpan(
        text: type.emoji,
        style: const TextStyle(fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    );
    _emojiPainter.layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animPhase += dt * 3.0;
  }

  @override
  void render(Canvas canvas) {
    // Float offset
    final floatY = sin(_animPhase) * 4.0;

    // Glow ring based on type
    final Color glowColor;
    switch (type) {
      case PowerUpType.shield:
        glowColor = const Color(0xFF4488FF);
      case PowerUpType.speedBoost:
        glowColor = const Color(0xFFFFCC00);
    }

    final pulseAlpha = (50 + (sin(_animPhase * 1.5) * 30)).toInt().clamp(20, 80);

    // Outer glow
    final glowPaint = Paint()..color = glowColor.withAlpha(pulseAlpha);
    canvas.drawCircle(Offset(0, floatY), powerUpRadius, glowPaint);

    // Inner circle
    final innerPaint = Paint()..color = glowColor.withAlpha(40);
    canvas.drawCircle(Offset(0, floatY), powerUpRadius * 0.7, innerPaint);

    // Ring
    final ringPaint = Paint()
      ..color = glowColor.withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(0, floatY), powerUpRadius * 0.7, ringPaint);

    // Emoji
    _emojiPainter.paint(
      canvas,
      Offset(-_emojiPainter.width / 2, floatY - _emojiPainter.height / 2),
    );
  }

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= powerUpRadius;
  }
}
