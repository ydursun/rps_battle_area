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
