import 'package:flutter/foundation.dart';

import 'config.dart';
import 'game_state.dart';

enum AppLanguage { tr, en }

class GameSettings extends ChangeNotifier {
  // Player count
  int _playerCount = 15;
  int get playerCount => _playerCount;
  set playerCount(int v) {
    if (_playerCount != v) {
      _playerCount = v;
      notifyListeners();
    }
  }

  // Game mode
  GameMode _gameMode = GameMode.elimination;
  GameMode get gameMode => _gameMode;
  set gameMode(GameMode v) {
    if (_gameMode != v) {
      _gameMode = v;
      notifyListeners();
    }
  }

  // Timer duration (seconds, for timed mode)
  int _timerDuration = 60;
  int get timerDuration => _timerDuration;
  set timerDuration(int v) {
    if (_timerDuration != v) {
      _timerDuration = v;
      notifyListeners();
    }
  }

  // Sound
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool v) {
    if (_soundEnabled != v) {
      _soundEnabled = v;
      notifyListeners();
    }
  }

  // Effects volume
  double _effectsVolume = 0.7;
  double get effectsVolume => _effectsVolume;
  set effectsVolume(double v) {
    if (_effectsVolume != v) {
      _effectsVolume = v;
      notifyListeners();
    }
  }

  // Language
  AppLanguage _language = AppLanguage.tr;
  AppLanguage get language => _language;
  set language(AppLanguage v) {
    if (_language != v) {
      _language = v;
      notifyListeners();
    }
  }

  // Power-ups (future feature)
  bool _powerUpsEnabled = false;
  bool get powerUpsEnabled => _powerUpsEnabled;
  set powerUpsEnabled(bool v) {
    if (_powerUpsEnabled != v) {
      _powerUpsEnabled = v;
      notifyListeners();
    }
  }

  // Entity size
  EntitySize _entitySize = EntitySize.mid;
  EntitySize get entitySize => _entitySize;
  set entitySize(EntitySize v) {
    if (_entitySize != v) {
      _entitySize = v;
      notifyListeners();
    }
  }

  // Chosen type (null = random)
  RpsType? _chosenType;
  RpsType? get chosenType => _chosenType;
  set chosenType(RpsType? v) {
    if (_chosenType != v) {
      _chosenType = v;
      notifyListeners();
    }
  }

  static const List<int> playerCountOptionsList = playerCountOptions;
  static const List<int> timerDurationOptionsList = timerDurationOptions;
}
