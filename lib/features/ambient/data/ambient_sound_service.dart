import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// أصوات طبيعة (مطر خفيف / حفيف شجر ورياح) بتتشغّل هادية في الخلفية ورا
/// التلاوة - كل الأصوات دي مُولَّدة بحتة من ضوضاء طبيعية مفلترة (مفيش فيها
/// أي موسيقى أو آلات ولا لحن خالص، بس نسيج صوتي هادي زي مطر حقيقي أو
/// هبوب رياح خفيفة على الشجر).
enum AmbientSound { none, rain, windLeaves }

class AmbientSoundOption {
  final AmbientSound sound;
  final String label;
  final String assetPath;

  const AmbientSoundOption({required this.sound, required this.label, this.assetPath = ''});
}

class AmbientSoundCatalog {
  AmbientSoundCatalog._();

  static const List<AmbientSoundOption> options = [
    AmbientSoundOption(sound: AmbientSound.none, label: 'من غير صوت طبيعة'),
    AmbientSoundOption(
      sound: AmbientSound.rain,
      label: 'صوت مطر خفيف',
      assetPath: 'assets/ambient/rain.mp3',
    ),
    AmbientSoundOption(
      sound: AmbientSound.windLeaves,
      label: 'حفيف شجر ورياح خفيفة',
      assetPath: 'assets/ambient/wind_leaves.mp3',
    ),
  ];
}

class AmbientSoundService {
  AmbientSoundService._internal();
  static final AmbientSoundService instance = AmbientSoundService._internal();

  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<AmbientSound> selected = ValueNotifier<AmbientSound>(AmbientSound.none);
  final ValueNotifier<double> volume = ValueNotifier<double>(0.35);

  bool _sourceLoaded = false;

  void load() {
    final raw = LocalStorage.instance.getString(StorageKeys.ambientSound);
    selected.value = AmbientSound.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => AmbientSound.none,
    );
    volume.value = LocalStorage.instance.getDouble(StorageKeys.ambientVolume) ?? 0.35;
    _player.setLoopMode(LoopMode.one);
    _player.setVolume(volume.value);
  }

  Future<void> setSound(AmbientSound sound) async {
    selected.value = sound;
    _sourceLoaded = false;
    await LocalStorage.instance.setString(StorageKeys.ambientSound, sound.name);
  }

  Future<void> setVolume(double value) async {
    volume.value = value;
    await _player.setVolume(value);
    await LocalStorage.instance.setDouble(StorageKeys.ambientVolume, value);
  }

  /// بيتنادى مع كل مرة السورة تشتغل، عشان صوت الطبيعة يلف مع التلاوة.
  Future<void> syncWithPlayback(bool mainIsPlaying) async {
    if (selected.value == AmbientSound.none) {
      await _player.pause();
      return;
    }

    if (!_sourceLoaded) {
      final option = AmbientSoundCatalog.options.firstWhere((o) => o.sound == selected.value);
      try {
        await _player.setAsset(option.assetPath);
        _sourceLoaded = true;
      } catch (_) {
        return;
      }
    }

    if (mainIsPlaying) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _sourceLoaded = false;
  }

  Future<void> dispose() => _player.dispose();
}
