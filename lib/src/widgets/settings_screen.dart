import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config.dart';
import '../game_settings.dart';
import '../game_state.dart';
import '../localization.dart';
import '../rps_game.dart';

class SettingsScreen extends StatefulWidget {
  final RpsGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
          width: 340,
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
                L.settingsTitle,
                style: GoogleFonts.orbitron(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 32),

              // Language
              Text(
                L.languageLabel,
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _langChip(
                    label: 'TR',
                    isSelected: s.language == AppLanguage.tr,
                    onTap: () {
                      s.language = AppLanguage.tr;
                      setLanguage(AppLanguage.tr);
                    },
                  ),
                  const SizedBox(width: 12),
                  _langChip(
                    label: 'EN',
                    isSelected: s.language == AppLanguage.en,
                    onTap: () {
                      s.language = AppLanguage.en;
                      setLanguage(AppLanguage.en);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withAlpha(25)),
              const SizedBox(height: 16),

              // Sound toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L.sound,
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      color: Colors.white54,
                      letterSpacing: 2,
                    ),
                  ),
                  Switch(
                    value: s.soundEnabled,
                    onChanged: (v) => s.soundEnabled = v,
                    activeThumbColor: accentColor,
                    inactiveThumbColor: Colors.white24,
                    inactiveTrackColor: Colors.white10,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Volume slider
              Row(
                children: [
                  Icon(
                    s.effectsVolume > 0
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: s.soundEnabled ? accentColor : Colors.white24,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor:
                            s.soundEnabled ? accentColor : Colors.white24,
                        inactiveTrackColor: Colors.white10,
                        thumbColor:
                            s.soundEnabled ? accentColor : Colors.white38,
                        overlayColor: accentColor.withAlpha(50),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                      ),
                      child: Slider(
                        value: s.effectsVolume,
                        onChanged:
                            s.soundEnabled ? (v) => s.effectsVolume = v : null,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${(s.effectsVolume * 100).round()}',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color:
                            s.soundEnabled ? Colors.white54 : Colors.white24,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withAlpha(25)),
              const SizedBox(height: 16),

              // Power-ups toggle (coming soon)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.powerUps,
                        style: GoogleFonts.orbitron(
                          fontSize: 13,
                          color: Colors.white24,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        L.comingSoon,
                        style: GoogleFonts.orbitron(
                          fontSize: 9,
                          color: Colors.white12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: false,
                    onChanged: null,
                    activeThumbColor: accentColor,
                    inactiveThumbColor: Colors.white12,
                    inactiveTrackColor: Colors.white.withAlpha(8),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Back
              TextButton(
                onPressed: () {
                  widget.game.playState = PlayState.mainMenu;
                },
                child: Text(
                  L.back,
                  style: GoogleFonts.orbitron(
                    fontSize: 16,
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

  Widget _langChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 40,
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
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isSelected ? accentColor : Colors.white54,
          ),
        ),
      ),
    );
  }
}
