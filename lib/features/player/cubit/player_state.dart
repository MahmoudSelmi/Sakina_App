import 'package:equatable/equatable.dart';
import '../data/queue_item.dart';

enum PlayerStatus { idle, loading, playing, paused, error }

enum RepeatMode { off, one, all }

class PlayerState extends Equatable {
  final PlayerStatus status;
  final List<QueueItem> queue;
  final int currentIndex;
  final Duration position;
  final Duration duration;
  final bool shuffle;
  final RepeatMode repeatMode;
  final double speed;
  final Duration? sleepTimerRemaining;
  final String? errorMessage;
  final bool isBuffering;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.queue = const [],
    this.currentIndex = -1,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.shuffle = false,
    this.repeatMode = RepeatMode.off,
    this.speed = 1.0,
    this.sleepTimerRemaining,
    this.errorMessage,
    this.isBuffering = false,
  });

  QueueItem? get currentItem =>
      (currentIndex >= 0 && currentIndex < queue.length) ? queue[currentIndex] : null;

  bool get hasNext => currentIndex >= 0 && currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
  bool get isPlaying => status == PlayerStatus.playing;

  PlayerState copyWith({
    PlayerStatus? status,
    List<QueueItem>? queue,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? shuffle,
    RepeatMode? repeatMode,
    double? speed,
    Duration? sleepTimerRemaining,
    bool clearSleepTimer = false,
    String? errorMessage,
    bool isBuffering = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      shuffle: shuffle ?? this.shuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      speed: speed ?? this.speed,
      sleepTimerRemaining:
          clearSleepTimer ? null : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      errorMessage: errorMessage,
      isBuffering: isBuffering,
    );
  }

  @override
  List<Object?> get props => [
        status,
        queue,
        currentIndex,
        position,
        duration,
        shuffle,
        repeatMode,
        speed,
        sleepTimerRemaining,
        errorMessage,
        isBuffering,
      ];
}
