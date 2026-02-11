import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

class MainMenu extends StatelessWidget {
  final RpsGame game;
  const MainMenu({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: menuBgColor,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              L.title,
              style: GoogleFonts.orbitron(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 12,
                shadows: [
                  Shadow(
                    color: accentColor.withAlpha(150),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L.subtitle,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                color: Colors.white38,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            // Type icons row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _typeCircle(rockColor, '🪨'),
                const SizedBox(width: 16),
                _typeCircle(paperColor, '📄'),
                const SizedBox(width: 16),
                _typeCircle(scissorsColor, '✂️'),
              ],
            ),
            const SizedBox(height: 48),
            // Play button
            _MenuButton(
              label: L.play,
              color: accentColor,
              onTap: () {
                game.playState = PlayState.lobby;
              },
            ),
            const SizedBox(height: 16),
            // Multiplayer button
            _MenuButton(
              label: L.multiplayer,
              color: Colors.deepPurpleAccent,
              onTap: () {
                if (game.isFirebaseReady) {
                  game.showRoomScreen();
                } else {
                  // Firebase not configured - show info
                  game.showRoomScreen();
                }
              },
            ),
            const SizedBox(height: 16),
            // Settings button
            _MenuButton(
              label: L.settingsTitle,
              color: Colors.white24,
              onTap: () {
                game.playState = PlayState.settings;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCircle(Color color, String emoji) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withAlpha(60),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(120), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        height: 52,
        decoration: BoxDecoration(
          color: color.withAlpha(40),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(120), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}
