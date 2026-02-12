import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../firebase_options.dart';
import '../config.dart';
import '../game_state.dart';
import '../localization.dart';
import '../multiplayer/room_manager.dart';
import '../rps_game.dart';

class RoomScreen extends StatefulWidget {
  final RpsGame game;
  const RoomScreen({super.key, required this.game});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  RoomData? _roomData;
  bool _inRoom = false;

  RoomManager get _rm => widget.game.roomManager;

  @override
  void initState() {
    super.initState();
    _rm.onRoomUpdated = _onRoomUpdated;
    _rm.onError = _onError;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _rm.onRoomUpdated = null;
    _rm.onError = null;
    super.dispose();
  }

  void _onRoomUpdated(RoomData data) {
    if (!mounted) return;
    setState(() {
      _roomData = data;
      _inRoom = true;
    });

    // If status changed to countdown or playing, start the game
    if (data.status == 'countdown' || data.status == 'playing') {
      widget.game.startMultiplayerGame(data);
    }
  }

  void _onError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final s = widget.game.settings;
      await _rm.createRoom(
        entityCount: s.playerCount,
        gameMode: s.gameMode,
        timerDuration: s.timerDuration,
      );
    } catch (e) {
      _onError('Oda oluşturulamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _onError('6 haneli oda kodu girin / Enter 6-digit room code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _rm.joinRoom(code);
    } catch (e) {
      _onError('Odaya katılınamadı: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveRoom() async {
    await _rm.leaveRoom();
    setState(() {
      _roomData = null;
      _inRoom = false;
    });
  }

  void _shareRoom() {
    if (_roomData == null) return;
    final code = _roomData!.roomCode;
    final link = _rm.getRoomLink(code);
    final text = 'RPS Battle Arena - Oda Kodu: $code\n$link';
    Share.share(text);
  }

  void _copyCode() {
    if (_roomData == null) return;
    Clipboard.setData(ClipboardData(text: _roomData!.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kod kopyalandı! / Code copied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: menuBgColor,
      child: Center(
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withAlpha(80), width: 1.5),
          ),
          child: !DefaultFirebaseOptions.isConfigured
              ? _buildFirebaseNotConfigured()
              : _inRoom
                  ? _buildRoomLobby()
                  : _buildJoinCreate(),
        ),
      ),
    );
  }

  Widget _buildFirebaseNotConfigured() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MULTIPLAYER',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 24),
        Icon(Icons.cloud_off_rounded, color: Colors.white24, size: 48),
        const SizedBox(height: 16),
        Text(
          'Firebase yapılandırılmamış\nFirebase not configured',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: Colors.white38,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '1) ~/bin/firebase login\n2) cd ~/rps_battle_arena\n3) flutterfire configure',
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              color: Colors.white54,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => widget.game.playState = PlayState.mainMenu,
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
    );
  }

  Widget _buildJoinCreate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MULTIPLAYER',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 28),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.orbitron(
                fontSize: 11,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // Create room button
        _ActionButton(
          label: 'ODA OLUŞTUR / CREATE ROOM',
          color: accentColor,
          isLoading: _isLoading,
          onTap: _isLoading ? null : _createRoom,
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'VEYA / OR',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  color: Colors.white24,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Colors.white12)),
          ],
        ),
        const SizedBox(height: 20),

        // Join room
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: 'ODA KODU',
                    hintStyle: GoogleFonts.orbitron(
                      fontSize: 13,
                      color: Colors.white24,
                      letterSpacing: 4,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _ActionButton(
              label: 'KATIL / JOIN',
              color: Colors.green,
              isLoading: _isLoading,
              onTap: _isLoading ? null : _joinRoom,
              width: 130,
            ),
          ],
        ),

        const SizedBox(height: 28),
        TextButton(
          onPressed: () => widget.game.playState = PlayState.lobby,
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
    );
  }

  Widget _buildRoomLobby() {
    final room = _roomData!;
    final isHost = _rm.isHost(room);
    final allReady = room.players.values.every((p) => p.ready);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ODA / ROOM',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),

          // Room code display
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withAlpha(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.roomCode,
                    style: GoogleFonts.orbitron(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.copy_rounded,
                      color: accentColor.withAlpha(150), size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _shareRoom,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.share_rounded,
                    color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Paylaş / Share',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: Colors.white.withAlpha(25)),
          const SizedBox(height: 12),

          // Room info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoChip('${room.entityCount} entity'),
              _infoChip(room.gameMode == GameMode.timed
                  ? '${room.timerDuration}s'
                  : L.elimination),
              _infoChip(
                  '${room.players.length}/${room.maxPlayers} oyuncu'),
            ],
          ),

          const SizedBox(height: 16),

          // Players list
          ...room.players.entries.map((entry) {
            final player = entry.value;
            final isMe = entry.key == _rm.currentUid;
            final isPlayerHost = entry.key == room.hostUid;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? accentColor.withAlpha(20)
                      : Colors.white.withAlpha(8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMe ? accentColor.withAlpha(60) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    if (isPlayerHost)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child:
                            Icon(Icons.star, color: Colors.amber, size: 16),
                      ),
                    Expanded(
                      child: Text(
                        '${player.displayName}${isMe ? " (sen)" : ""}',
                        style: GoogleFonts.orbitron(
                          fontSize: 12,
                          color: isMe ? accentColor : Colors.white54,
                        ),
                      ),
                    ),
                    if (player.chosenType != null)
                      Text(
                        _emojiForType(player.chosenType!),
                        style: const TextStyle(fontSize: 16),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      player.ready
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          player.ready ? Colors.greenAccent : Colors.white24,
                      size: 18,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Type selection for current player
          Text(
            L.yourType,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              color: Colors.white38,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: RpsType.values.map((type) {
              final myInfo = room.players[_rm.currentUid];
              final isSelected = myInfo?.chosenType == type;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => _rm.setPlayerReady(
                    myInfo?.ready ?? false,
                    chosenType: type,
                  ),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _colorForType(type).withAlpha(60)
                          : Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _colorForType(type)
                            : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _emojiForType(type),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Ready button
          _ActionButton(
            label: _isPlayerReady() ? 'HAZIR ✓' : 'HAZIR OL / READY',
            color: _isPlayerReady() ? Colors.green : Colors.orange,
            onTap: () {
              final myInfo = room.players[_rm.currentUid];
              _rm.setPlayerReady(
                !(myInfo?.ready ?? false),
                chosenType: myInfo?.chosenType,
              );
            },
          ),

          const SizedBox(height: 12),

          // Start game (host only)
          if (isHost)
            _ActionButton(
              label: 'OYUNU BAŞLAT / START',
              color: allReady && room.players.length >= 2
                  ? accentColor
                  : Colors.white24,
              onTap: allReady && room.players.length >= 2
                  ? () => _rm.startGame()
                  : null,
            ),

          const SizedBox(height: 12),
          TextButton(
            onPressed: _leaveRoom,
            child: Text(
              'ODADAN AYRIL / LEAVE',
              style: GoogleFonts.orbitron(
                fontSize: 12,
                color: Colors.redAccent.withAlpha(180),
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPlayerReady() {
    if (_roomData == null) return false;
    final myInfo = _roomData!.players[_rm.currentUid];
    return myInfo?.ready ?? false;
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.orbitron(fontSize: 10, color: Colors.white38),
      ),
    );
  }

  String _emojiForType(RpsType type) {
    switch (type) {
      case RpsType.rock:
        return '🪨';
      case RpsType.paper:
        return '📄';
      case RpsType.scissors:
        return '✂️';
    }
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;

  const _ActionButton({
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 46,
        decoration: BoxDecoration(
          color: color.withAlpha(onTap != null ? 50 : 20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withAlpha(onTap != null ? 150 : 40),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: onTap != null ? Colors.white : Colors.white24,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }
}
