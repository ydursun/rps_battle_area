import 'dart:ui' show Color;

enum SpeedLevel {
  slow,
  normal,
  fast,
  veryFast;

  double get initialSpeed {
    switch (this) {
      case SpeedLevel.slow:
        return 80.0;
      case SpeedLevel.normal:
        return 120.0;
      case SpeedLevel.fast:
        return 180.0;
      case SpeedLevel.veryFast:
        return 250.0;
    }
  }

  double get maxSpeed {
    switch (this) {
      case SpeedLevel.slow:
        return 180.0;
      case SpeedLevel.normal:
        return 280.0;
      case SpeedLevel.fast:
        return 380.0;
      case SpeedLevel.veryFast:
        return 450.0;
    }
  }

  String get label {
    switch (this) {
      case SpeedLevel.slow:
        return 'SLOW';
      case SpeedLevel.normal:
        return 'NORMAL';
      case SpeedLevel.fast:
        return 'FAST';
      case SpeedLevel.veryFast:
        return 'V.FAST';
    }
  }

  String get emoji {
    switch (this) {
      case SpeedLevel.slow:
        return '\u{1F422}';
      case SpeedLevel.normal:
        return '\u{25B6}';
      case SpeedLevel.fast:
        return '\u{1F407}';
      case SpeedLevel.veryFast:
        return '\u{26A1}';
    }
  }
}

enum ObstacleAmount {
  none,
  low,
  medium,
  high;

  String get label {
    switch (this) {
      case ObstacleAmount.none:
        return 'OFF';
      case ObstacleAmount.low:
        return 'LOW';
      case ObstacleAmount.medium:
        return 'MID';
      case ObstacleAmount.high:
        return 'HIGH';
    }
  }
}

enum PowerUpType {
  shield,
  speedBoost;

  String get emoji {
    switch (this) {
      case PowerUpType.shield:
        return '\u{1F6E1}';
      case PowerUpType.speedBoost:
        return '\u{26A1}';
    }
  }

  double get duration => 5.0;
}

enum EntitySize {
  small,
  mid,
  large,
  xl;

  double get radius {
    switch (this) {
      case EntitySize.small:
        return 14.0;
      case EntitySize.mid:
        return 20.0;
      case EntitySize.large:
        return 28.0;
      case EntitySize.xl:
        return 38.0;
    }
  }

  double get fontSize {
    switch (this) {
      case EntitySize.small:
        return 16.0;
      case EntitySize.mid:
        return 24.0;
      case EntitySize.large:
        return 32.0;
      case EntitySize.xl:
        return 44.0;
    }
  }

  String get label {
    switch (this) {
      case EntitySize.small:
        return 'S';
      case EntitySize.mid:
        return 'M';
      case EntitySize.large:
        return 'L';
      case EntitySize.xl:
        return 'XL';
    }
  }
}

enum ArenaTheme {
  dark,
  midnight,
  forest,
  ocean,
  lava,
  sand,
  ice,
  cloud,
  grid,
  dots;

  String get label {
    switch (this) {
      case ArenaTheme.dark:
        return 'Koyu';
      case ArenaTheme.midnight:
        return 'Gece';
      case ArenaTheme.forest:
        return 'Orman';
      case ArenaTheme.ocean:
        return 'Okyanus';
      case ArenaTheme.lava:
        return 'Lav';
      case ArenaTheme.sand:
        return 'Kum';
      case ArenaTheme.ice:
        return 'Buz';
      case ArenaTheme.cloud:
        return 'Bulut';
      case ArenaTheme.grid:
        return 'Izgara';
      case ArenaTheme.dots:
        return 'Nokta';
    }
  }

  Color get bgColor {
    switch (this) {
      case ArenaTheme.dark:
        return const Color(0xFF0D1117);
      case ArenaTheme.midnight:
        return const Color(0xFF0B0E2D);
      case ArenaTheme.forest:
        return const Color(0xFF0A1A0A);
      case ArenaTheme.ocean:
        return const Color(0xFF071825);
      case ArenaTheme.lava:
        return const Color(0xFF1A0808);
      case ArenaTheme.sand:
        return const Color(0xFFD4C5A0);
      case ArenaTheme.ice:
        return const Color(0xFFCCDDEE);
      case ArenaTheme.cloud:
        return const Color(0xFFE8E0F0);
      case ArenaTheme.grid:
        return const Color(0xFF0D1117);
      case ArenaTheme.dots:
        return const Color(0xFF111122);
    }
  }

  Color get wallColor {
    switch (this) {
      case ArenaTheme.dark:
        return const Color(0xFF2A3A5C);
      case ArenaTheme.midnight:
        return const Color(0xFF1A1A5C);
      case ArenaTheme.forest:
        return const Color(0xFF1A4A2A);
      case ArenaTheme.ocean:
        return const Color(0xFF1A3A5C);
      case ArenaTheme.lava:
        return const Color(0xFF5C2A1A);
      case ArenaTheme.sand:
        return const Color(0xFF8B7355);
      case ArenaTheme.ice:
        return const Color(0xFF7799BB);
      case ArenaTheme.cloud:
        return const Color(0xFF9988BB);
      case ArenaTheme.grid:
        return const Color(0xFF2A5C4A);
      case ArenaTheme.dots:
        return const Color(0xFF3A2A5C);
    }
  }

  Color get decorColor {
    switch (this) {
      case ArenaTheme.dark:
        return const Color(0x0AFFFFFF);
      case ArenaTheme.midnight:
        return const Color(0x0C4466FF);
      case ArenaTheme.forest:
        return const Color(0x0C44FF66);
      case ArenaTheme.ocean:
        return const Color(0x0C44CCFF);
      case ArenaTheme.lava:
        return const Color(0x0CFF6644);
      case ArenaTheme.sand:
        return const Color(0x18886644);
      case ArenaTheme.ice:
        return const Color(0x184488AA);
      case ArenaTheme.cloud:
        return const Color(0x15886699);
      case ArenaTheme.grid:
        return const Color(0x1244FFAA);
      case ArenaTheme.dots:
        return const Color(0x10AA88FF);
    }
  }

  /// 'grid', 'dots', or 'none'
  String get pattern {
    switch (this) {
      case ArenaTheme.dots:
        return 'dots';
      case ArenaTheme.grid:
        return 'grid';
      default:
        return 'grid'; // subtle default grid
    }
  }
}

enum PlayState {
  mainMenu,
  lobby,
  settings,
  playing,
  paused,
  gameOver,
}

enum GameMode {
  elimination,
  timed,
}

enum RpsType {
  rock,
  paper,
  scissors;

  RpsType get beats {
    switch (this) {
      case RpsType.rock:
        return RpsType.scissors;
      case RpsType.paper:
        return RpsType.rock;
      case RpsType.scissors:
        return RpsType.paper;
    }
  }

  RpsType get beatenBy {
    switch (this) {
      case RpsType.rock:
        return RpsType.paper;
      case RpsType.paper:
        return RpsType.scissors;
      case RpsType.scissors:
        return RpsType.rock;
    }
  }

  bool winsAgainst(RpsType other) => beats == other;
}
