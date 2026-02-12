import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static bool get isConfigured => _isConfigured;
  static const bool _isConfigured = true;

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return _macos;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.android:
        return _android;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions _macos = FirebaseOptions(
    apiKey: 'AIzaSyB2rd2s9k1ivHkzAsfBKIk5H-mFo7O_RCo',
    appId: '1:995809866318:ios:480984315255a2369b091f',
    messagingSenderId: '995809866318',
    projectId: 'rps-battle-arena-d7527',
    storageBucket: 'rps-battle-arena-d7527.firebasestorage.app',
    databaseURL: 'https://rps-battle-arena-d7527-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.rpsBattleArena.macos',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyB2rd2s9k1ivHkzAsfBKIk5H-mFo7O_RCo',
    appId: '1:995809866318:ios:8b126ef3ae3b8c4d9b091f',
    messagingSenderId: '995809866318',
    projectId: 'rps-battle-arena-d7527',
    storageBucket: 'rps-battle-arena-d7527.firebasestorage.app',
    databaseURL: 'https://rps-battle-arena-d7527-default-rtdb.firebaseio.com',
    iosBundleId: 'com.example.rpsBattleArena',
  );

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyAd-btp90ejX06U1U2YDcZ14A2zBfQncX8',
    appId: '1:995809866318:android:af0317a74606a3049b091f',
    messagingSenderId: '995809866318',
    projectId: 'rps-battle-arena-d7527',
    storageBucket: 'rps-battle-arena-d7527.firebasestorage.app',
    databaseURL: 'https://rps-battle-arena-d7527-default-rtdb.firebaseio.com',
  );
}
