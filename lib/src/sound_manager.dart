import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'game_settings.dart';

// Conditional import for dart:io (unavailable on web)
import 'sound_manager_io.dart' if (dart.library.html) 'sound_manager_web.dart'
    as platform;

class SoundManager {
  final GameSettings settings;

  final AudioPlayer _conversionPlayer = AudioPlayer();
  final AudioPlayer _wallHitPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _losePlayer = AudioPlayer();
  final AudioPlayer _countdownPlayer = AudioPlayer();
  final AudioPlayer _gameStartPlayer = AudioPlayer();

  late final Source _conversionSource;
  late final Source _wallHitSource;
  late final Source _winSource;
  late final Source _loseSource;
  late final Source _countdownSource;
  late final Source _gameStartSource;

  bool _ready = false;

  SoundManager({required this.settings});

  Future<void> init() async {
    _conversionSource = await _createSource(
      'conversion.wav',
      _generateTone(frequency: 520, durationMs: 80, fadeOut: true),
    );
    _wallHitSource = await _createSource(
      'wall_hit.wav',
      _generateTone(frequency: 330, durationMs: 40, fadeOut: true),
    );
    _winSource = await _createSource(
      'win.wav',
      _generateMelody([
        (freq: 523, ms: 120),
        (freq: 659, ms: 120),
        (freq: 784, ms: 120),
        (freq: 1047, ms: 250),
      ]),
    );
    _loseSource = await _createSource(
      'lose.wav',
      _generateMelody([
        (freq: 400, ms: 150),
        (freq: 350, ms: 150),
        (freq: 300, ms: 150),
        (freq: 200, ms: 300),
      ]),
    );
    _countdownSource = await _createSource(
      'countdown.wav',
      _generateTone(frequency: 880, durationMs: 50, fadeOut: true),
    );
    _gameStartSource = await _createSource(
      'game_start.wav',
      _generateMelody([
        (freq: 440, ms: 100),
        (freq: 660, ms: 100),
        (freq: 880, ms: 200),
      ]),
    );

    _ready = true;
  }

  Future<Source> _createSource(String name, Uint8List data) async {
    if (kIsWeb) {
      return BytesSource(data);
    } else {
      return await platform.writeDeviceFileSource(name, data);
    }
  }

  void playConversion() => _play(_conversionPlayer, _conversionSource);
  void playWallHit() => _play(_wallHitPlayer, _wallHitSource);
  void playWin() => _play(_winPlayer, _winSource);
  void playLose() => _play(_losePlayer, _loseSource);
  void playCountdownBeep() => _play(_countdownPlayer, _countdownSource);
  void playGameStart() => _play(_gameStartPlayer, _gameStartSource);

  void _play(AudioPlayer player, Source source) {
    if (!_ready || !settings.soundEnabled) return;
    player.setVolume(settings.effectsVolume);
    player.stop();
    player.play(source);
  }

  void dispose() {
    _conversionPlayer.dispose();
    _wallHitPlayer.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _countdownPlayer.dispose();
    _gameStartPlayer.dispose();
  }

  // --- WAV generation ---

  static const int _sampleRate = 44100;

  Uint8List _generateTone({
    required double frequency,
    required int durationMs,
    bool fadeOut = false,
  }) {
    final numSamples = (_sampleRate * durationMs / 1000).round();
    final samples = Float64List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      double t = i / _sampleRate;
      double sample = sin(2 * pi * frequency * t);

      final attackSamples = min(numSamples ~/ 10, 200);
      if (i < attackSamples) {
        sample *= i / attackSamples;
      }
      if (fadeOut) {
        final fadeStart = numSamples * 0.3;
        if (i > fadeStart) {
          sample *= 1.0 - ((i - fadeStart) / (numSamples - fadeStart));
        }
      }

      samples[i] = sample * 0.4;
    }

    return _samplesToWav(samples);
  }

  Uint8List _generateMelody(List<({double freq, int ms})> notes) {
    final allSamples = <double>[];

    for (final note in notes) {
      final numSamples = (_sampleRate * note.ms / 1000).round();
      for (int i = 0; i < numSamples; i++) {
        double t = i / _sampleRate;
        double sample = sin(2 * pi * note.freq * t);

        final attackSamples = min(numSamples ~/ 8, 150);
        final releaseSamples = min(numSamples ~/ 4, 300);
        if (i < attackSamples) {
          sample *= i / attackSamples;
        } else if (i > numSamples - releaseSamples) {
          sample *= (numSamples - i) / releaseSamples;
        }

        allSamples.add(sample * 0.35);
      }
    }

    return _samplesToWav(Float64List.fromList(allSamples));
  }

  Uint8List _samplesToWav(Float64List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final fileSize = 44 + dataSize;

    final buffer = ByteData(fileSize);
    int offset = 0;

    void writeString(String s) {
      for (int i = 0; i < s.length; i++) {
        buffer.setUint8(offset++, s.codeUnitAt(i));
      }
    }

    writeString('RIFF');
    buffer.setUint32(offset, fileSize - 8, Endian.little);
    offset += 4;
    writeString('WAVE');

    writeString('fmt ');
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2;
    buffer.setUint32(offset, _sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, _sampleRate * 2, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little);
    offset += 2;
    buffer.setUint16(offset, 16, Endian.little);
    offset += 2;

    writeString('data');
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    for (int i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final intSample = (clamped * 32767).round().clamp(-32768, 32767);
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }
}
