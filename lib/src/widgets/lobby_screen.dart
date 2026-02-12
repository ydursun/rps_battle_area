import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

// Color palette for background and wall color selection
const List<Color> _bgColorPalette = [
  Color(0xFF0D1117), Color(0xFF0B0E2D), Color(0xFF0A1A0A), Color(0xFF071825),
  Color(0xFF1A0808), Color(0xFF1A1A2E), Color(0xFF111122), Color(0xFF0F0F0F),
  Color(0xFF1B2838), Color(0xFF1C1C3A), Color(0xFF0D1B2A), Color(0xFF13151A),
  Color(0xFF2D1B2E), Color(0xFF1A2E1A), Color(0xFF2E2E1A), Color(0xFF0A0A1E),
  Color(0xFFD4C5A0), Color(0xFFCCDDEE), Color(0xFFE8E0F0), Color(0xFFF0E6D4),
  Color(0xFFE0E0E0), Color(0xFFFFF8E7), Color(0xFFE6F0E6), Color(0xFFE0F0FF),
  Color(0xFF2C3E50), Color(0xFF34495E), Color(0xFF1ABC9C), Color(0xFF16A085),
  Color(0xFF2ECC71), Color(0xFF3498DB), Color(0xFF9B59B6), Color(0xFFE74C3C),
  Color(0xFFF39C12), Color(0xFFE67E22), Color(0xFF1F1F1F), Color(0xFF2B2B2B),
];

const List<Color> _wallColorPalette = [
  Color(0xFF2A3A5C), Color(0xFF1A1A5C), Color(0xFF1A4A2A), Color(0xFF1A3A5C),
  Color(0xFF5C2A1A), Color(0xFF8B7355), Color(0xFF7799BB), Color(0xFF9988BB),
  Color(0xFF2A5C4A), Color(0xFF3A2A5C), Color(0xFF4A4A4A), Color(0xFF5C5C2A),
  Color(0xFF2A5C5C), Color(0xFF5C2A5C), Color(0xFF3A5C2A), Color(0xFF5C3A2A),
  Color(0xFF6C63FF), Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D),
  Color(0xFF95E1D3), Color(0xFFF38181), Color(0xFFAA96DA), Color(0xFFFCBF49),
  Color(0xFF00B4D8), Color(0xFFE63946), Color(0xFF457B9D), Color(0xFF2A9D8F),
  Color(0xFFE9C46A), Color(0xFFF4A261), Color(0xFF264653), Color(0xFF606C38),
];

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

  void _showColorPicker(
      List<Color> palette, Color current, ValueChanged<Color> onSelect) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: panelColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 320,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: palette.map((color) {
                final isSelected = color == current;
                return GestureDetector(
                  onTap: () {
                    onSelect(color);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.greenAccent
                            : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.greenAccent, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.game.settings;

    return Container(
      color: menuBgColor,
      child: Center(
        child: Container(
          width: 400,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(20),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),

                // Player count
                _sectionLabel(L.playerCount),
                const SizedBox(height: 4),
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

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Game mode
                _sectionLabel(L.gameMode),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _chip(
                      label: L.elimination,
                      isSelected: s.gameMode == GameMode.elimination,
                      onTap: () => s.gameMode = GameMode.elimination,
                      width: 110,
                    ),
                    _chip(
                      label: L.timed,
                      isSelected: s.gameMode == GameMode.timed,
                      onTap: () => s.gameMode = GameMode.timed,
                      width: 80,
                    ),
                  ],
                ),

                if (s.gameMode == GameMode.timed) ...[
                  const SizedBox(height: 6),
                  _sectionLabel(L.duration),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: timerDurationOptions.map((dur) {
                      return _chip(
                        label: L.seconds(dur),
                        isSelected: s.timerDuration == dur,
                        onTap: () => s.timerDuration = dur,
                        width: 50,
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Speed level
                _sectionLabel(L.speed),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: SpeedLevel.values.map((level) {
                    return _chip(
                      label: '${level.emoji} ${level.label}',
                      isSelected: s.speedLevel == level,
                      onTap: () => s.speedLevel = level,
                      width: 72,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Entity size + type on same row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _sectionLabel(L.entitySize),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: EntitySize.values.map((size) {
                              return _chip(
                                label: size.label,
                                isSelected: s.entitySize == size,
                                onTap: () => s.entitySize = size,
                                width: 38,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          _sectionLabel(L.yourType),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _typeChip(
                                emoji: '\u{1FAA8}',
                                isSelected: s.chosenType == RpsType.rock,
                                onTap: () => s.chosenType = RpsType.rock,
                              ),
                              _typeChip(
                                emoji: '\u{1F4C4}',
                                isSelected: s.chosenType == RpsType.paper,
                                onTap: () => s.chosenType = RpsType.paper,
                              ),
                              _typeChip(
                                emoji: '\u{2702}\u{FE0F}',
                                isSelected: s.chosenType == RpsType.scissors,
                                onTap: () => s.chosenType = RpsType.scissors,
                              ),
                              _typeChip(
                                emoji: '\u{1F3B2}',
                                isSelected: s.chosenType == null,
                                onTap: () => s.chosenType = null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Arena colors
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // BG color
                    Column(
                      children: [
                        _sectionLabel(L.bgColorLabel),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showColorPicker(
                            _bgColorPalette,
                            s.customBgColor,
                            (c) => s.customBgColor = c,
                          ),
                          child: Container(
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: s.customBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.greenAccent, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    // Wall color
                    Column(
                      children: [
                        _sectionLabel(L.wallColorLabel),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _showColorPicker(
                            _wallColorPalette,
                            s.customWallColor,
                            (c) => s.customWallColor = c,
                          ),
                          child: Container(
                            width: 56,
                            height: 32,
                            decoration: BoxDecoration(
                              color: s.customWallColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.greenAccent, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Arena difficulty
                _sectionLabel(L.arenaObstacles),
                const SizedBox(height: 6),

                // Walls
                _obstacleRow(
                  label: L.innerWalls,
                  current: s.wallAmount,
                  onChanged: (v) => s.wallAmount = v,
                ),
                const SizedBox(height: 4),

                // Mud
                _obstacleRow(
                  label: L.mudZones,
                  current: s.mudAmount,
                  onChanged: (v) => s.mudAmount = v,
                ),
                const SizedBox(height: 4),

                // Bush
                _obstacleRow(
                  label: L.bushZones,
                  current: s.bushAmount,
                  onChanged: (v) => s.bushAmount = v,
                ),
                const SizedBox(height: 4),

                // Teleport toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        L.teleport,
                        style: GoogleFonts.orbitron(
                          fontSize: 8,
                          color: Colors.white38,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _chip(
                      label: 'OFF',
                      isSelected: !s.teleportEnabled,
                      onTap: () => s.teleportEnabled = false,
                      width: 42,
                    ),
                    _chip(
                      label: 'ON',
                      isSelected: s.teleportEnabled,
                      onTap: () => s.teleportEnabled = true,
                      width: 42,
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                _divider(),
                const SizedBox(height: 8),

                // Power-ups toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      L.powerUps,
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _chip(
                      label: 'OFF',
                      isSelected: !s.powerUpsEnabled,
                      onTap: () => s.powerUpsEnabled = false,
                      width: 42,
                    ),
                    _chip(
                      label: 'ON',
                      isSelected: s.powerUpsEnabled,
                      onTap: () => s.powerUpsEnabled = true,
                      width: 42,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Start button
                GestureDetector(
                  onTap: () => widget.game.startGame(),
                  child: Container(
                    width: 170,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(60),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      L.startGame,
                      style: GoogleFonts.orbitron(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Multiplayer button
                GestureDetector(
                  onTap: () => widget.game.showRoomScreen(),
                  child: Container(
                    width: 170,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.deepPurpleAccent.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      L.multiplayer,
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Back
                TextButton(
                  onPressed: () =>
                      widget.game.playState = PlayState.mainMenu,
                  child: Text(
                    L.back,
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
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

  Widget _obstacleRow({
    required String label,
    required ObstacleAmount current,
    required ValueChanged<ObstacleAmount> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 8,
              color: Colors.white38,
              letterSpacing: 1,
            ),
          ),
        ),
        ...ObstacleAmount.values.map((amount) {
          return _chip(
            label: amount.label,
            isSelected: current == amount,
            onTap: () => onChanged(amount),
            width: 42,
          );
        }),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.orbitron(
        fontSize: 9,
        color: Colors.white54,
        letterSpacing: 2,
      ),
    );
  }

  Widget _divider() {
    return Divider(color: Colors.white.withAlpha(20), height: 1);
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    double width = 48,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withAlpha(70)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : Colors.white24,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isSelected ? accentColor : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeChip({
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent.withAlpha(30)
                : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.greenAccent : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
