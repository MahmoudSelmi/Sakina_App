import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// بيغلف مشغّل just_audio ويبعت حالة التشغيل لنظام التشغيل (نظام أندرويد/iOS)
/// عشان يظهر تحكم حقيقي في إشعار التشغيل وعلى شاشة القفل (تشغيل/إيقاف/
/// التالي/السابق)، بدل ما يفضل التحكم جوه التطبيق بس.
///
/// الكلاس ده مسؤول بس عن "الإذاعة" لنظام التشغيل - منطق الـ queue والتكرار
/// والعشوائية لسه في [PlayerCubit] زي ما هو، وده بيوصل بيه عن طريق
/// [onSkipNext] و[onSkipPrevious].
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer player = AudioPlayer();

  Future<void> Function()? onSkipNext;
  Future<void> Function()? onSkipPrevious;

  AudioPlayerHandler() {
    _broadcastPlaybackState();
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
