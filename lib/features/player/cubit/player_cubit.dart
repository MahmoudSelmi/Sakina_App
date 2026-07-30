import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/notification_artwork_generator.dart';
import '../../downloads/data/download_service.dart';
import '../../recently_played/data/recently_played_service.dart';
import '../../settings/data/settings_service.dart';
import '../../settings/data/volume_boost_service.dart';
import '../data/audio_player_handler.dart';
import '../data/queue_item.dart';
import 'player_state.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final AudioPlayerHandler _handler;
  AudioPlayer get _audioPlayer => _handler.player;
  final LocalStorage _storage = LocalStorage.instance;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<dynamic>? _playerStateSub;
  Timer? _persistTimer;
  Timer? _sleepTimer;

  PlayerCubit(this._handler)
      : super(PlayerState(speed: SettingsService.instance.defaultSpeed.value)) {
    _init();
  }

  Future<void> _init() async {
    // بربط أزرار "التالي/السابق" على شاشة القفل والإشعار بنفس منطق الـ
    // queue الموجود هنا (بما فيه الشفل والتكرار).
    _handler.onSkipNext = playNext;
    _handler.onSkipPrevious = playPrevious;

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      emit(state.copyWith(position: pos));
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      emit(state.copyWith(duration: dur ?? Duration.zero));
      if (dur != null) _handler.updateMediaItemDuration(dur);
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
      final queue = queueRaw.map((e) => QueueItem.decode(e)).toList();

      final index = queue.indexWhere(
        (q) => q.reciterId == lastReciterId && q.surahNumber == lastSurah,
      );

      if (index == -1 || queue.isEmpty) return;

      emit(state.copyWith(queue: queue, currentIndex: index));
      await _loadCurrent(
          autoPlay: false, seekTo: Duration(milliseconds: lastPositionMs));
      _broadcastQueue();
    } catch (_) {
      // جلسة تالفة، بنتجاهلها ونبدأ عادي
    }
  }

  Future<void> playQueue(List<QueueItem> queue,
      {required int startIndex}) async {
    emit(state.copyWith(
      queue: queue,
      currentIndex: startIndex,
      status: PlayerStatus.loading,
    ));
    await _saveQueue();
    await _loadCurrent(autoPlay: true);
    _broadcastQueue();
  }

  Future<void> playSingle(QueueItem item) => playQueue([item], startIndex: 0);

  /// بينقل التشغيل لعنصر معين جوه نفس قائمة الانتظار الحالية (بيتستخدم من
  /// شاشة "قائمة الانتظار" لما المستخدم يدوس على سورة تانية في القائمة).
  Future<void> jumpToQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    emit(state.copyWith(currentIndex: index));
    await _loadCurrent(autoPlay: true);
  }

  Future<void> _loadCurrent({required bool autoPlay, Duration? seekTo}) async {
    final item = state.currentItem;
    if (item == null) return;

    emit(state.copyWith(status: PlayerStatus.loading, isBuffering: true));

    try {
      final localPath = DownloadService.instance.localPath(item.key);
      if (localPath != null && await File(localPath).exists()) {
        await _audioPlayer.setFilePath(localPath);
      } else {
        await _audioPlayer.setUrl(item.audioUrl);
      }
      if (seekTo != null && seekTo > Duration.zero) {
        await _audioPlayer.seek(seekTo);
      }
      await _audioPlayer.setSpeed(state.speed);
      await _audioPlayer
          .setVolume(VolumeBoostService.instance.getBoost(item.reciterId));
      if (autoPlay) {
        await _audioPlayer.play();
      }
      _handler.setCurrentMediaItem(await _toMediaItem(item));
      _storage.setInt(StorageKeys.lastReciterId, item.reciterId);
      _storage.setInt(StorageKeys.lastMoshafId, item.moshafId);
      _storage.setInt(StorageKeys.lastSurahNumber, item.surahNumber);
      _addToRecentlyPlayed(item);
    } catch (e) {
      emit(state.copyWith(
          status: PlayerStatus.error, errorMessage: 'تعذر تشغيل السورة'));
    }
  }

  Future<MediaItem> _toMediaItem(QueueItem item) async {
    final artUri = await NotificationArtworkGenerator.generate(
          reciterId: item.reciterId,
          letter: item.reciterName.isNotEmpty ? item.reciterName[0] : '؟',
        ) ??
        Uri.parse('asset:///assets/branding/app_notification_art.png');

    return MediaItem(
      id: item.key,
      album: 'جَنَّتَكَ',
      title: item.surahArabicName,
      artist: item.reciterName,
      artUri: artUri,
    );
  }

  Future<void> _broadcastQueue() async {
    final items = await Future.wait(state.queue.map(_toMediaItem));
    _handler.queue.add(items);
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

  /// بيظبط مستوى صوت القارئ الحالي (لمعادلة الفرق بين تسجيلات القراء
  /// المختلفة) وبيطبّقه فورًا وبيفتكره للمرات الجاية.
  Future<void> setVolumeBoostForCurrentReciter(double value) async {
    final item = state.currentItem;
    if (item == null) return;
    await VolumeBoostService.instance.setBoost(item.reciterId, value);
    await _audioPlayer.setVolume(value);
  }

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
    final encoded = state.queue.map(QueueItem.encode).toList();
    await _storage.setStringList(StorageKeys.playQueue, encoded);
  }

  Future<void> _persistProgress() async {
    if (state.currentItem == null) return;
    await _storage.setInt(
        StorageKeys.lastPositionMs, state.position.inMilliseconds);
  }

  Future<void> _addToRecentlyPlayed(QueueItem item) async {
    await RecentlyPlayedService.instance.add(item);
  }

  @override
  Future<void> close() async {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    _persistTimer?.cancel();
    _sleepTimer?.cancel();
    await _handler.dispose();
    return super.close();
  }
}
