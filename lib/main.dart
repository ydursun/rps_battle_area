import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'src/rps_game.dart';
import 'src/game_state.dart';
import 'src/widgets/main_menu.dart';
import 'src/widgets/lobby_screen.dart';
import 'src/widgets/settings_screen.dart';
import 'src/widgets/pause_overlay.dart';
import 'src/widgets/hud_overlay.dart';
import 'src/widgets/game_over_screen.dart';
import 'src/widgets/room_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Firebase if configured
  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const RpsApp());
}

class RpsApp extends StatelessWidget {
  const RpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = RpsGame();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget<RpsGame>(
          game: game,
          overlayBuilderMap: {
            PlayState.mainMenu.name: (context, game) =>
                MainMenu(game: game),
            PlayState.lobby.name: (context, game) =>
                LobbyScreen(game: game),
            PlayState.settings.name: (context, game) =>
                SettingsScreen(game: game),
            'room': (context, game) =>
                RoomScreen(game: game),
            'pauseButton': (context, game) =>
                PauseButton(game: game),
            PlayState.paused.name: (context, game) =>
                PauseOverlay(game: game),
            'hud': (context, game) =>
                HudOverlay(game: game),
            PlayState.gameOver.name: (context, game) =>
                GameOverScreen(game: game),
          },
        ),
      ),
    );
  }
}
