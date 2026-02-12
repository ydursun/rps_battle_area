import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';
// PowerUpType accessed via game_state.dart

class HudOverlay extends StatefulWidget {
  final RpsGame game;
  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.game;

    // Countdown overlay
    if (g.isCountingDown) {
      return Center(
        child: Text(
          g.countdownTimer.ceil().toString(),
          style: GoogleFonts.orbitron(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white.withAlpha(200),
            shadows: [
              Shadow(
                color: accentColor.withAlpha(150),
                blurRadius: 30,
              ),
            ],
          ),
        ),
      );
    }

    // Sort counts descending
    final counts = [
      (L.rock, g.rockCount, rockColor),
      (L.paper, g.paperCount, paperColor),
      (L.scissors, g.scissorsCount, scissorsColor),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    final timerSec = g.gameTimer.ceil();
    final isTimerWarning = g.gameMode == GameMode.timed && timerSec <= 10;

    return Stack(
      children: [
        // Top-left: entity counts
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: counts.map((c) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: c.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 60,
                        child: Text(
                          c.$1,
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            color: c.$3,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      Text(
                        '${c.$2}',
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom-left: active power-up indicator
        if (g.playerEntity?.activePowerUp != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: g.playerEntity!.activePowerUp == PowerUpType.shield
                    ? Colors.blue.withAlpha(60)
                    : Colors.amber.withAlpha(60),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: g.playerEntity!.activePowerUp == PowerUpType.shield
                      ? Colors.blue.withAlpha(150)
                      : Colors.amber.withAlpha(150),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    g.playerEntity!.activePowerUp!.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    g.playerEntity!.activePowerUp == PowerUpType.shield
                        ? L.shieldActive
                        : L.speedBoostActive,
                    style: GoogleFonts.orbitron(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${g.playerEntity!.powerUpTimer.ceil()}s',
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Top-right: timer (timed mode only)
        if (g.gameMode == GameMode.timed)
          Positioned(
            top: 16,
            right: 60,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isTimerWarning
                    ? Colors.red.withAlpha(60)
                    : Colors.black.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
                border: isTimerWarning
                    ? Border.all(color: Colors.red.withAlpha(150))
                    : null,
              ),
              child: Text(
                _formatTime(timerSec),
                style: GoogleFonts.orbitron(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isTimerWarning ? Colors.red : Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
