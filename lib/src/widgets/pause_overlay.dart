import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

class PauseButton extends StatelessWidget {
  final RpsGame game;
  const PauseButton({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => game.pauseGame(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: Colors.white54,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  final RpsGame game;
  const PauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L.paused,
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 36),

              // Resume
              GestureDetector(
                onTap: () => game.resumeGame(),
                child: Container(
                  width: 200,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    L.resume,
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Main menu
              TextButton(
                onPressed: () {
                  game.playState = PlayState.mainMenu;
                },
                child: Text(
                  L.mainMenu,
                  style: GoogleFonts.orbitron(
                    fontSize: 14,
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
