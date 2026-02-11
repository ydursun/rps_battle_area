import 'game_settings.dart';

AppLanguage _currentLanguage = AppLanguage.tr;

void setLanguage(AppLanguage lang) {
  _currentLanguage = lang;
}

class L {
  // Main menu
  static String get title =>
      _currentLanguage == AppLanguage.tr ? 'TKM ARENA' : 'RPS ARENA';
  static String get subtitle => _currentLanguage == AppLanguage.tr
      ? 'Taş Kağıt Makas Savaşı'
      : 'Rock Paper Scissors Battle';
  static String get play =>
      _currentLanguage == AppLanguage.tr ? 'OYNA' : 'PLAY';
  static String get settingsTitle =>
      _currentLanguage == AppLanguage.tr ? 'AYARLAR' : 'SETTINGS';

  // Lobby
  static String get lobby =>
      _currentLanguage == AppLanguage.tr ? 'LOBİ' : 'LOBBY';
  static String get playerCount =>
      _currentLanguage == AppLanguage.tr ? 'OYUNCU SAYISI' : 'PLAYER COUNT';
  static String get gameMode =>
      _currentLanguage == AppLanguage.tr ? 'OYUN MODU' : 'GAME MODE';
  static String get elimination =>
      _currentLanguage == AppLanguage.tr ? 'ELEMİNASYON' : 'ELIMINATION';
  static String get timed =>
      _currentLanguage == AppLanguage.tr ? 'SÜRELİ' : 'TIMED';
  static String get duration =>
      _currentLanguage == AppLanguage.tr ? 'SÜRE' : 'DURATION';
  static String get entitySize =>
      _currentLanguage == AppLanguage.tr ? 'BOYUT' : 'SIZE';
  static String get yourType =>
      _currentLanguage == AppLanguage.tr ? 'TİPİN' : 'YOUR TYPE';
  static String get random =>
      _currentLanguage == AppLanguage.tr ? 'RASTGELE' : 'RANDOM';
  static String get startGame =>
      _currentLanguage == AppLanguage.tr ? 'BAŞLA' : 'START';

  // Types
  static String get rock =>
      _currentLanguage == AppLanguage.tr ? 'TAŞ' : 'ROCK';
  static String get paper =>
      _currentLanguage == AppLanguage.tr ? 'KAĞIT' : 'PAPER';
  static String get scissors =>
      _currentLanguage == AppLanguage.tr ? 'MAKAS' : 'SCISSORS';

  static String typeLabel(String type) {
    switch (type) {
      case 'rock':
        return rock;
      case 'paper':
        return paper;
      case 'scissors':
        return scissors;
      default:
        return type;
    }
  }

  // Settings
  static String get sound =>
      _currentLanguage == AppLanguage.tr ? 'SES' : 'SOUND';
  static String get languageLabel =>
      _currentLanguage == AppLanguage.tr ? 'DİL' : 'LANGUAGE';
  static String get powerUps =>
      _currentLanguage == AppLanguage.tr ? 'GÜÇLER' : 'POWER-UPS';
  static String get comingSoon =>
      _currentLanguage == AppLanguage.tr ? 'Yakında' : 'Coming Soon';

  // Pause
  static String get paused =>
      _currentLanguage == AppLanguage.tr ? 'DURAKLATILDI' : 'PAUSED';
  static String get resume =>
      _currentLanguage == AppLanguage.tr ? 'DEVAM' : 'RESUME';
  static String get mainMenu =>
      _currentLanguage == AppLanguage.tr ? 'ANA MENÜ' : 'MAIN MENU';

  // HUD
  static String get countdown =>
      _currentLanguage == AppLanguage.tr ? 'HAZIR OL' : 'GET READY';

  // Game over
  static String wins(String type) => _currentLanguage == AppLanguage.tr
      ? '${typeLabel(type)} KAZANDI!'
      : '${typeLabel(type)} WINS!';
  static String get youWin =>
      _currentLanguage == AppLanguage.tr ? 'KAZANDIN!' : 'YOU WIN!';
  static String get youLose =>
      _currentLanguage == AppLanguage.tr ? 'KAYBETTİN!' : 'YOU LOSE!';
  static String get draw =>
      _currentLanguage == AppLanguage.tr ? 'BERABERE!' : 'DRAW!';
  static String get playAgain =>
      _currentLanguage == AppLanguage.tr ? 'TEKRAR OYNA' : 'PLAY AGAIN';

  // Multiplayer
  static String get multiplayer => 'MULTIPLAYER';

  // Back
  static String get back =>
      _currentLanguage == AppLanguage.tr ? 'GERİ' : 'BACK';

  // Seconds suffix
  static String seconds(int s) => '${s}s';
}
