import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

class LobbyScreen extends StatefulWidget {
  final RpsGame game;
  const LobbyScreen({super.key, required this.game});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    widget.game.settings.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.game.settings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.game.settings;

    return Container(
      color: menuBgColor,
      child: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  L.lobby,
                  style: GoogleFonts.orbitron(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 28),

                // Player count
                _sectionLabel(L.playerCount),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: playerCountOptions.map((count) {
                    return _chip(
                      label: '$count',
                      isSelected: s.playerCount == count,
                      onTap: () => s.playerCount = count,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                _divider(),
                const SizedBox(height: 16),

                // Game mode
                _sectionLabel(L.gameMode),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip(
                      label: L.elimination,
                      isSelected: s.gameMode == GameMode.elimination,
                      onTap: () => s.gameMode = GameMode.elimination,
                      width: 130,
                    ),
                    _chip(
                      label: L.timed,
                      isSelected: s.gameMode == GameMode.timed,
                      onTap: () => s.gameMode = GameMode.timed,
                      width: 100,
                    ),
                  ],
                ),

                // Duration (only for timed)
                if (s.gameMode == GameMode.timed) ...[
                  const SizedBox(height: 16),
                  _sectionLabel(L.duration),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: timerDurationOptions.map((dur) {
                      return _chip(
                        label: L.seconds(dur),
                        isSelected: s.timerDuration == dur,
                        onTap: () => s.timerDuration = dur,
                        width: 60,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),
                _divider(),
                const SizedBox(height: 16),

                // Entity size
                _sectionLabel(L.entitySize),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: EntitySize.values.map((size) {
                    return _chip(
                      label: size.label,
                      isSelected: s.entitySize == size,
                      onTap: () => s.entitySize = size,
                      width: 52,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                _divider(),
                const SizedBox(height: 16),

                // Type selection
                _sectionLabel(L.yourType),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _typeChip(
                      label: L.rock,
                      color: rockColor,
                      isSelected: s.chosenType == RpsType.rock,
                      onTap: () => s.chosenType = RpsType.rock,
                    ),
                    _typeChip(
                      label: L.paper,
                      color: paperColor,
                      isSelected: s.chosenType == RpsType.paper,
                      onTap: () => s.chosenType = RpsType.paper,
                    ),
                    _typeChip(
                      label: L.scissors,
                      color: scissorsColor,
                      isSelected: s.chosenType == RpsType.scissors,
                      onTap: () => s.chosenType = RpsType.scissors,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _chip(
                  label: L.random,
                  isSelected: s.chosenType == null,
                  onTap: () => s.chosenType = null,
                  width: 110,
                ),

                const SizedBox(height: 32),

                // Start button
                GestureDetector(
                  onTap: () {
                    widget.game.startGame();
                  },
                  child: Container(
                    width: 200,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      L.startGame,
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Multiplayer button
                GestureDetector(
                  onTap: () {
                    widget.game.showRoomScreen();
                  },
                  child: Container(
                    width: 200,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.deepPurpleAccent.withAlpha(120),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      L.multiplayer,
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back
                TextButton(
                  onPressed: () {
                    widget.game.playState = PlayState.mainMenu;
                  },
                  child: Text(
                    L.back,
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
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 12,
        color: Colors.white54,
        letterSpacing: 2,
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white.withAlpha(25));
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    double width = 56,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withAlpha(80)
                : Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? accentColor : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 80,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected
                ? color.withAlpha(60)
                : Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
