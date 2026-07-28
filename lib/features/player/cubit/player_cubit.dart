import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../../core/storage/local_storage.dart';
import '../data/queue_item.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final LocalStorage _storage = LocalStorage.instance;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<dynamic>? _playerStateSub;
  Timer? _persistTimer;
  Timer? _sleepTimer;

  PlayerCubit() : super(PlayerState()) {
    _init();
  }

  Future<void> _init() async {
    _positionSub = _audioPlayer.positionStream.listen((pos) {
      emit(state.copyWith(position: pos));
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      emit(state.copyWith(duration: dur ?? Duration.zero));
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((s) {
      final buffering = s.processingState == ProcessingState.buffering ||
          s.processingState == ProcessingState.loading;
      if (s.processingState == ProcessingState.completed) {
        _onTrackCompleted();
        return;
      }
      emit(state.copyWith(
        status: s.playing ? PlayerStatus.playing : PlayerStatus.paused,
        isBuffering: buffering,
      ));
    });

    _persistTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _persistProgress());

    await _restoreSession();
  }

  Future<void> _restoreSession() async {
    final queueRaw = _storage.getStringList(StorageKeys.playQueue);
    if (queueRaw.isEmpty) return;

    final lastReciterId = _storage.getInt(StorageKeys.lastReciterId);
    final lastSurah = _storage.getInt(StorageKeys.lastSurahNumber);
    final lastPositionMs = _storage.getInt(StorageKeys.lastPositionMs) ?? 0;

    if (lastReciterId == null || lastSurah == null) return;

    try {
      final queue = queueRaw
          .map((e) => QueueItem.fromJson(
              Map<String, dynamic>.from((e.isNotEmpty) ? _decode(e) : {})))
          .toList();

      final index = queue.indexWhere(
        (q) => q.reciterId == lastReciterId && q.surahNumber == lastSurah,
      );

      if (index == -1 || queue.isEmpty) return;

      emit(state.copyWith(queue: queue, currentIndex: index));
      await _loadCurrent(
          autoPlay: false, seekTo: Duration(milliseconds: lastPositionMs));
    } catch (_) {
      // جلسة تالفة، بنتجاهلها ونبدأ عادي
    }
  }

  Map<String, dynamic> _decode(String raw) {
    final parts = raw.split('|');
    return {
      'reciterId': int.parse(parts[0]),
      'reciterName': parts[1],
      'moshafId': int.parse(parts[2]),
      'moshafServer': parts[3],
      'surahNumber': int.parse(parts[4]),
    };
  }

  String _encode(QueueItem item) =>
      '${item.reciterId}|${item.reciterName}|${item.moshafId}|${item.moshafServer}|${item.surahNumber}';

  Future<void> playQueue(List<QueueItem> queue,
      {required int startIndex}) async {
    emit(state.copyWith(
      queue: queue,
      currentIndex: startIndex,
      status: PlayerStatus.loading,
    ));
    await _saveQueue();
    await _loadCurrent(autoPlay: true);
  }

  Future<void> playSingle(QueueItem item) => playQueue([item], startIndex: 0);

  Future<void> _loadCurrent({required bool autoPlay, Duration? seekTo}) async {
    final item = state.currentItem;
    if (item == null) return;

    emit(state.copyWith(status: PlayerStatus.loading, isBuffering: true));

    try {
      await _audioPlayer.setUrl(item.audioUrl);
      if (seekTo != null && seekTo > Duration.zero) {
        await _audioPlayer.seek(seekTo);
      }
      await _audioPlayer.setSpeed(state.speed);
      if (autoPlay) {
        await _audioPlayer.play();
      }
      _storage.setInt(StorageKeys.lastReciterId, item.reciterId);
      _storage.setInt(StorageKeys.lastMoshafId, item.moshafId);
      _storage.setInt(StorageKeys.lastSurahNumber, item.surahNumber);
      _addToRecentlyPlayed(item);
    } catch (e) {
      emit(state.copyWith(
          status: PlayerStatus.error, errorMessage: 'تعذر تشغيل السورة'));
    }
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      await _persistProgress();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> playNext() async {
    if (!state.hasNext) return;
    final nextIndex = state.shuffle ? _randomIndex() : state.currentIndex + 1;
    emit(state.copyWith(currentIndex: nextIndex));
    await _loadCurrent(autoPlay: true);
  }

  Future<void> playPrevious() async {
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (!state.hasPrevious) return;
    emit(state.copyWith(currentIndex: state.currentIndex - 1));
    await _loadCurrent(autoPlay: true);
  }

  int _randomIndex() {
    final rand = Random();
    if (state.queue.length <= 1) return state.currentIndex;
    int next;
    do {
      next = rand.nextInt(state.queue.length);
    } while (next == state.currentIndex);
    return next;
  }

  void _onTrackCompleted() {
    if (state.repeatMode == RepeatMode.one) {
      _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
      return;
    }
    if (state.hasNext || state.shuffle) {
      playNext();
      return;
    }
    if (state.repeatMode == RepeatMode.all && state.queue.isNotEmpty) {
      emit(state.copyWith(currentIndex: 0));
      _loadCurrent(autoPlay: true);
      return;
    }
    emit(state.copyWith(status: PlayerStatus.paused));
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    emit(state.copyWith(speed: speed));
  }

  void toggleShuffle() => emit(state.copyWith(shuffle: !state.shuffle));

  void cycleRepeatMode() {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    emit(state.copyWith(repeatMode: next));
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    emit(state.copyWith(sleepTimerRemaining: duration));
    _sleepTimer = Timer(duration, () async {
      await _audioPlayer.pause();
      emit(state.copyWith(clearSleepTimer: true));
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    emit(state.copyWith(clearSleepTimer: true));
  }

  Future<void> _saveQueue() async {
    final encoded = state.queue.map(_encode).toList();
    await _storage.setStringList(StorageKeys.playQueue, encoded);
  }

  Future<void> _persistProgress() async {
    if (state.currentItem == null) return;
    await _storage.setInt(
        StorageKeys.lastPositionMs, state.position.inMilliseconds);
  }

  Future<void> _addToRecentlyPlayed(QueueItem item) async {
    final recent = _storage.getStringList(StorageKeys.recentlyPlayed);
    final encoded = _encode(item);
    recent.removeWhere((e) => e.startsWith('${item.reciterId}|'));
    recent.insert(0, encoded);
    final trimmed = recent.take(30).toList();
    await _storage.setStringList(StorageKeys.recentlyPlayed, trimmed);
  }

  @override
  Future<void> close() async {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _persistTimer?.cancel();
    _sleepTimer?.cancel();
    await _audioPlayer.dispose();
    return super.close();
  }
}
