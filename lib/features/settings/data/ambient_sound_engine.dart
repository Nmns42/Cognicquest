import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_settings.dart';

/// Génération des ambiances sonores.
///
/// `assets/sounds/` est vide depuis l'origine du projet, et un bruit de pluie
/// ou de café ne se synthétise pas de façon convaincante. En revanche les
/// bruits colorés et une sinusoïde se génèrent exactement : on produit donc
/// un WAV en mémoire, joué en boucle. Ces ambiances fonctionnent sans qu'aucun
/// fichier n'ait à être fourni.
abstract final class NoiseGenerator {
  static const int sampleRate = 44100;

  /// Durée de la boucle. Assez longue pour que la répétition ne s'entende
  /// pas, assez courte pour rester sous le mégaoctet.
  static const int loopSeconds = 5;

  /// Construit un fichier WAV 16 bits mono pour l'ambiance demandée.
  static Uint8List? build(AmbientSound sound) {
    if (!sound.isSynthesised || sound.isSilent) return null;

    const sampleCount = sampleRate * loopSeconds;
    final samples = Float64List(sampleCount);
    final random = Random(42); // Graine fixe : même ambiance à chaque session.

    switch (sound) {
      case AmbientSound.whiteNoise:
        for (var i = 0; i < sampleCount; i++) {
          samples[i] = random.nextDouble() * 2 - 1;
        }

      case AmbientSound.pinkNoise:
        // Approximation de Voss-McCartney : le bruit rose décroît de 3 dB par
        // octave, ce qui le rend nettement moins agressif que le blanc.
        final rows = List<double>.filled(16, 0);
        var runningSum = 0.0;
        for (var i = 0; i < sampleCount; i++) {
          final index = i == 0 ? 0 : _lowestSetBit(i).clamp(0, rows.length - 1);
          runningSum -= rows[index];
          rows[index] = random.nextDouble() * 2 - 1;
          runningSum += rows[index];
          samples[i] = runningSum / rows.length;
        }

      case AmbientSound.brownNoise:
        // Intégration du bruit blanc, avec une fuite pour éviter la dérive
        // continue vers les extrêmes.
        var last = 0.0;
        for (var i = 0; i < sampleCount; i++) {
          last = (last + (random.nextDouble() * 2 - 1) * 0.02).clamp(-1.0, 1.0);
          last *= 0.998;
          samples[i] = last * 3.5;
        }

      case AmbientSound.tone440:
        // La boucle doit contenir un nombre entier de périodes, sinon un clic
        // se fait entendre à chaque rebouclage.
        const frequency = 440.0;
        final periods = (frequency * loopSeconds).round();
        final adjusted = periods / loopSeconds;
        for (var i = 0; i < sampleCount; i++) {
          samples[i] = sin(2 * pi * adjusted * i / sampleRate) * 0.25;
        }

      default:
        return null;
    }

    _applyFades(samples);
    return _encodeWav(samples);
  }

  /// Index du bit de poids faible, pour Voss-McCartney.
  static int _lowestSetBit(int value) {
    var index = 0;
    while (value & 1 == 0 && index < 31) {
      value >>= 1;
      index++;
    }
    return index;
  }

  /// Fondus d'entrée et de sortie — « effet de fondu audio progressif pour
  /// maintenir la concentration » (CdC). Ils suppriment aussi le clic de
  /// rebouclage.
  static void _applyFades(Float64List samples) {
    final fade = (sampleRate * 0.05).round();
    for (var i = 0; i < fade && i < samples.length; i++) {
      final gain = i / fade;
      samples[i] *= gain;
      samples[samples.length - 1 - i] *= gain;
    }
  }

  static Uint8List _encodeWav(Float64List samples) {
    const bitsPerSample = 16;
    const channels = 1;
    final dataSize = samples.length * 2;

    final bytes = BytesBuilder();
    void writeString(String value) => bytes.add(value.codeUnits);
    void writeUint32(int value) => bytes.add(
        Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little));
    void writeUint16(int value) => bytes.add(
        Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little));

    writeString('RIFF');
    writeUint32(36 + dataSize);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1); // PCM
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(sampleRate * channels * bitsPerSample ~/ 8);
    writeUint16(channels * bitsPerSample ~/ 8);
    writeUint16(bitsPerSample);
    writeString('data');
    writeUint32(dataSize);

    final pcm = Uint8List(dataSize);
    final view = pcm.buffer.asByteData();
    for (var i = 0; i < samples.length; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      view.setInt16(i * 2, (clamped * 32767).round(), Endian.little);
    }
    bytes.add(pcm);

    return bytes.toBytes();
  }
}

/// Lecture de l'ambiance sonore.
class AmbientSoundEngine {
  AmbientSoundEngine() {
    _player.setReleaseMode(ReleaseMode.loop);
  }

  final AudioPlayer _player = AudioPlayer();

  AmbientSound _current = AmbientSound.none;

  /// Mémorise les WAV déjà générés : la synthèse coûte quelques centaines de
  /// millisecondes, inutile de la refaire à chaque va-et-vient.
  final Map<AmbientSound, Uint8List> _cache = {};

  AmbientSound get current => _current;

  Future<void> play(AmbientSound sound, {required double volume}) async {
    if (sound.isSilent) {
      await stop();
      return;
    }

    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));

      if (sound == _current) return;
      _current = sound;

      if (sound.isSynthesised) {
        final data = _cache[sound] ??= NoiseGenerator.build(sound)!;
        await _player.play(BytesSource(data), volume: volume);
      } else {
        final asset = sound.assetPath;
        if (asset == null) return;
        // L'asset peut manquer : on échoue silencieusement plutôt que de
        // casser la session de travail en cours.
        await _player.play(AssetSource(asset), volume: volume);
      }
    } catch (error) {
      _current = AmbientSound.none;
      if (kDebugMode) debugPrint('Ambiance sonore indisponible : $error');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {
      // Sans importance : l'ambiance n'est pas critique.
    }
  }

  Future<void> stop() async {
    _current = AmbientSound.none;
    try {
      await _player.stop();
    } catch (_) {
      // Idem.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

final ambientSoundEngineProvider = Provider<AmbientSoundEngine>((ref) {
  final engine = AmbientSoundEngine();
  ref.onDispose(engine.dispose);
  return engine;
});
