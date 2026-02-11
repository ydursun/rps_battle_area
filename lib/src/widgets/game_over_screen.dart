import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

class GameOverScreen extends StatelessWidget {
  final RpsGame game;
  const GameOverScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final winner = game.winnerType ?? RpsType.rock;
    final won = game.playerWon ?? false;

    final winnerColor = _colorForType(winner);
    final winnerLabel = winner.name;

    return Container(
      color: const Color(0xDD000000),
      child: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: winnerColor.withAlpha(120),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy / icon
              Icon(
                won ? Icons.emoji_events_rounded : Icons.close_rounded,
                color: won ? Colors.amber : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),

              // Winner type
              Text(
                L.wins(winnerLabel),
                style: GoogleFonts.orbitron(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: winnerColor,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),

              // Player result
              Text(
                won ? L.youWin : L.youLose,
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: won ? Colors.greenAccent : Colors.redAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),

              // Final counts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _countDisplay(L.rock, game.rockCount, rockColor),
                  _countDisplay(L.paper, game.paperCount, paperColor),
                  _countDisplay(L.scissors, game.scissorsCount, scissorsColor),
                ],
              ),
              const SizedBox(height: 32),

              // Play again
              GestureDetector(
                onTap: () {
                  game.playState = PlayState.lobby;
                },
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
                    L.playAgain,
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Main menu
              TextButton(
                onPressed: () {
                  game.playState = PlayState.mainMenu;
                },
                child: Text(
                  L.mainMenu,
                  style: GoogleFonts.orbitron(
                    fontSize: 13,
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

  Widget _countDisplay(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withAlpha(100),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 9,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Color _colorForType(RpsType type) {
    switch (type) {
      case RpsType.rock:
        return rockColor;
      case RpsType.paper:
        return paperColor;
      case RpsType.scissors:
        return scissorsColor;
    }
  }
}
