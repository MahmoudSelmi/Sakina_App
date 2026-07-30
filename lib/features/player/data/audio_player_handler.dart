import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// بيغلف مشغّل just_audio ويبعت حالة التشغيل لنظام التشغيل (نظام أندرويد/iOS)
/// عشان يظهر تحكم حقيقي في إشعار التشغيل وعلى شاشة القفل (تشغيل/إيقاف/
/// التالي/السابق)، بدل ما يفضل التحكم جوه التطبيق بس.
///
/// وبيتعامل صح مع مقاطعات الصوت زي المكالمات، تطبيقات تانية بتشغل صوت،
/// وسحب السماعة - عشان الاستماع يبقى سلس ومحترف زي أي تطبيق موسيقى حقيقي.
///
/// الكلاس ده مسؤول بس عن "الإذاعة" لنظام التشغيل - منطق الـ queue والتكرار
/// والعشوائية لسه في [PlayerCubit] زي ما هو، وده بيوصل بيه عن طريق
/// [onSkipNext] و[onSkipPrevious].
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;

  /// بنسجل هل إحنا اللي وقّفنا التشغيل بسبب مقاطعة (مكالمة مثلًا) عشان
  /// نكمل تلقائي بعدها، ومنكملش لو المستخدم هو اللي وقّف بنفسه قبل كده.
  bool _resumeAfterInterruption = false;

  AudioPlayerHandler() {
    _broadcastPlaybackState();
    _configureAudioSession();
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            // صوت ثانوي (زي تنبيه ملاحة) - بنخفّض الصوت بدل ما نوقفه.
            player.setVolume(0.3);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // مكالمة جاية أو تطبيق تاني محتاج الصوت - نوقف مؤقتًا ونفتكر
            // إننا كنا شغالين عشان نكمل تلقائي بعد ما تخلص المقاطعة.
            if (player.playing) {
              _resumeAfterInterruption = true;
              player.pause();
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            if (_resumeAfterInterruption) {
              _resumeAfterInterruption = false;
              player.play();
            }
            break;
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = false;
            break;
        }
      }
    });

    // لو المستخدم شال السماعة أو فصل البلوتوث، الصوت يوقف تلقائي بدل ما
    // يطلع فجأة من سماعة الموبايل قدام الناس.
    session.becomingNoisyEventStream.listen((_) {
      if (player.playing) player.pause();
    });
  }

  void _broadcastPlaybackState() {
    player.playbackEventStream.listen((event) {
      final playing = player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[player.processingState]!,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ));
    });
  }

  /// بيحدّث اسم السورة/القارئ الظاهر في إشعار النظام وشاشة القفل.
  void setCurrentMediaItem(MediaItem item) => mediaItem.add(item);

  /// بيحدّث مدة السورة على شاشة القفل أول ما تبقى معروفة، عشان شريط
  /// التقدّم يبان صح بدل ما يفضل من غير حدّ نهائي.
  void updateMediaItemDuration(Duration duration) {
    final current = mediaItem.value;
    if (current == null) return;
    mediaItem.add(current.copyWith(duration: duration));
  }

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> setSpeed(double speed) => player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  @override
  Future<void> skipToNext() async => onSkipNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPrevious?.call();

  Future<void> dispose() => player.dispose();
}
